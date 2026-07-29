#!/usr/bin/env bash

# MacBookPro14,3 Installer Utilities
# Provides logging, error handling, rollback management, and safe execution wrappers.

set -Eeuo pipefail
IFS=$'\n\t'

readonly LOG_FILE="/var/log/macbook-installer.log"
readonly STATE_DIR="/var/lib/macbook-installer"
readonly MANIFEST_FILE="${STATE_DIR}/manifest.txt"
readonly BACKUP_DIR="${STATE_DIR}/backups"

export REPORT_FILE="${STATE_DIR}/report.txt"

readonly COLOR_RESET="\033[0m"
readonly COLOR_RED="\033[31m"
readonly COLOR_GREEN="\033[32m"
readonly COLOR_YELLOW="\033[33m"
readonly COLOR_BLUE="\033[34m"
readonly COLOR_CYAN="\033[36m"

VERBOSE_MODE=0
QUIET_MODE=0
DRY_RUN=0
INSTALL_SUCCESSFUL=0

REGISTERED_FILES=()
REGISTERED_BACKUPS=()

trap_error() {
    local exit_code="$1"
    local line_no="$2"
    local command="$3"
    
    log_error "Error in command '${command}' at line ${line_no} (Exit code: ${exit_code})"
    rollback
    exit "${exit_code}"
}

trap 'trap_error $? $LINENO "$BASH_COMMAND"' ERR

parse_args() {
    for arg in "$@"; do
        case "${arg}" in
            --verbose|-v) VERBOSE_MODE=1 ;;
            --quiet|-q) QUIET_MODE=1 ;;
            --dry-run) DRY_RUN=1 ;;
            *) log_error "Unknown argument: ${arg}"; exit 1 ;;
        esac
    done
}

setup_logging() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${COLOR_RED}Error: This installer must be run as root (sudo).${COLOR_RESET}" >&2
        exit 1
    fi
    
    mkdir -p "$(dirname "${LOG_FILE}")" "${STATE_DIR}" "${BACKUP_DIR}"
    touch "${LOG_FILE}" || {
        echo -e "${COLOR_RED}Failed to create log file ${LOG_FILE}${COLOR_RESET}" >&2
        exit 1
    }
}

_log_to_file() {
    local message="$1"
    if [[ -w "${LOG_FILE}" ]]; then
        echo -e "${message}" | sed -E 's/\x1B\[[0-9;]*[mK]//g' >> "${LOG_FILE}"
    fi
}

_log() {
    local level="$1"
    local color="$2"
    local message="$3"
    local timestamp
    timestamp="$(date +'%Y-%m-%d %H:%M:%S')"
    local formatted="[${timestamp}] [${level}] ${message}"
    
    _log_to_file "${formatted}"
    
    if [[ "${QUIET_MODE}" -eq 1 && "${level}" != "ERROR" ]]; then
        return
    fi
    
    if [[ "${level}" == "DEBUG" && "${VERBOSE_MODE}" -eq 0 ]]; then
        return
    fi

    if [[ "${level}" == "ERROR" ]]; then
        echo -e "${color}${formatted}${COLOR_RESET}" >&2
    else
        echo -e "${color}${formatted}${COLOR_RESET}"
    fi
}

log_info() { _log "INFO" "${COLOR_BLUE}" "$1"; }
log_success() { _log "SUCCESS" "${COLOR_GREEN}" "$1"; }
log_warn() { _log "WARN" "${COLOR_YELLOW}" "$1"; }
log_error() { _log "ERROR" "${COLOR_RED}" "$1"; }
log_debug() { _log "DEBUG" "${COLOR_CYAN}" "$1"; }

run_cmd() {
    local cmd_desc="$1"
    shift
    
    log_info "${cmd_desc}..."
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_info "[DRY-RUN] Would execute: $*"
        return 0
    fi
    
    if [[ "${VERBOSE_MODE}" -eq 1 ]]; then
        "$@" 2>&1 | tee -a "${LOG_FILE}"
    else
        local output
        if ! output=$("$@" 2>&1); then
            log_error "Command failed: ${cmd_desc}"
            echo "${output}" | tee -a "${LOG_FILE}" >&2
            return 1
        fi
        echo "${output}" >> "${LOG_FILE}"
    fi
}

register_installed_file() {
    local file_path="$1"
    REGISTERED_FILES+=("${file_path}")
    if [[ -w "${MANIFEST_FILE}" || -w "${STATE_DIR}" ]]; then
        echo "${file_path}" >> "${MANIFEST_FILE}"
    fi
}

safe_backup() {
    local file_path="$1"
    if [[ -f "${file_path}" ]]; then
        local target_backup
        target_backup="${BACKUP_DIR}$(dirname "${file_path}")"
        mkdir -p "${target_backup}"
        local backup_file
        backup_file="${target_backup}/$(basename "${file_path}").bak"
        log_info "Backing up ${file_path} to ${backup_file}"
        cp -a "${file_path}" "${backup_file}"
        REGISTERED_BACKUPS+=("${file_path}")
        _log_to_file "Backup created: ${backup_file}"
    fi
}

rollback() {
    if [[ "${INSTALL_SUCCESSFUL}" -eq 1 ]]; then
        return 0
    fi

    log_warn "Initiating transactional rollback procedure..."

    for file in "${REGISTERED_BACKUPS[@]:-}"; do
        local backup_file="${BACKUP_DIR}${file}.bak"
        if [[ -f "${backup_file}" ]]; then
            log_info "Restoring original backup for ${file}"
            cp -a "${backup_file}" "${file}"
        fi
    done

    for file in "${REGISTERED_FILES[@]:-}"; do
        if [[ -f "${file}" || -L "${file}" ]]; then
            log_info "Removing created file: ${file}"
            rm -f "${file}"
        elif [[ -d "${file}" ]]; then
            log_info "Removing created directory: ${file}"
            rm -rf "${file}"
        fi
    done

    if command -v dkms >/dev/null 2>&1; then
        for mod in facetimehd snd_hda_macbookpro applespi; do
            if dkms status 2>/dev/null | grep -q "${mod}"; then
                log_info "Removing unverified DKMS module ${mod}..."
                dkms remove -m "${mod}" --all 2>/dev/null || true
            fi
        done
    fi

    log_info "Rollback procedure completed."
}

verify_sha256() {
    local file_path="$1"
    local expected_hash="$2"

    if [[ ! -f "${file_path}" ]]; then
        log_error "File does not exist for SHA256 check: ${file_path}"
        return 1
    fi

    local actual_hash
    actual_hash="$(sha256sum "${file_path}" | awk '{print $1}')"

    if [[ "${actual_hash}" != "${expected_hash}" ]]; then
        log_error "SHA256 mismatch for ${file_path}: got ${actual_hash}, expected ${expected_hash}"
        return 1
    fi

    log_debug "SHA256 verified for ${file_path}"
    return 0
}

check_internet() {
    log_info "Checking internet connection..."
    if ! curl -s --connect-timeout 5 https://archive.ubuntu.com >/dev/null && \
       ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_error "No active internet connection detected."
        return 1
    fi
    log_success "Internet connection verified."
    return 0
}
