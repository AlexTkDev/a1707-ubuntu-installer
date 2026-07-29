#!/usr/bin/env bash
# common/logging.sh
# Standalone logging framework for MacBook Pro Installer

# Configuration
export MAX_LOG_SIZE=$((10 * 1024 * 1024)) # 10 MB

# State
export LOG_QUIET=0
export LOG_VERBOSE=0
export LOG_DEBUG=0
export DRY_RUN_ENABLED=0
export SESSION_WARNINGS=0
export SESSION_ERRORS=0
export SESSION_START_TIME="${SECONDS}"

# ANSI Colors
export C_RESET="\e[0m"
export C_RED="\e[31m"
export C_GREEN="\e[32m"
export C_YELLOW="\e[33m"
export C_BLUE="\e[34m"
export C_CYAN="\e[36m"
export C_PURPLE="\e[35m"

_rotate_logs() {
    # Ensure log directory exists
    mkdir -p "$(dirname "${LOG_FILE}")"
    
    if [[ -f "${LOG_FILE}" ]]; then
        local file_size
        file_size=$(stat -c%s "${LOG_FILE}" 2>/dev/null || echo 0)
        
        if (( file_size > MAX_LOG_SIZE )); then
            # Keep last 5 logs (1 to 5)
            for i in {4..1}; do
                if [[ -f "${LOG_FILE}.${i}" ]]; then
                    mv -f "${LOG_FILE}.${i}" "${LOG_FILE}.$((i + 1))"
                fi
            done
            mv -f "${LOG_FILE}" "${LOG_FILE}.1"
        fi
    fi
}

_log() {
    local level="$1"
    local color="$2"
    shift 2
    local message="$*"
    
    # Verbosity filters
    if [[ "${LOG_QUIET}" -eq 1 ]]; then
        [[ "${level}" == "INFO" || "${level}" == "SUCCESS" || "${level}" == "DEBUG" ]] && return 0
    fi
    
    if [[ "${LOG_DEBUG}" -eq 0 && "${level}" == "DEBUG" ]]; then
        return 0
    fi

    # Tracking
    [[ "${level}" == "WARN" ]] && ((SESSION_WARNINGS++))
    [[ "${level}" == "ERROR" || "${level}" == "FATAL" ]] && ((SESSION_ERRORS++))

    local timestamp
    timestamp=$(date -Iseconds)
    local prefix="[${timestamp}] [${level}]"
    local raw_output="${prefix} ${message}"
    local colored_output="${color}${prefix}${C_RESET} ${message}"

    # Print to stdout/stderr (Errors to stderr)
    if [[ "${level}" == "ERROR" || "${level}" == "FATAL" || "${level}" == "WARN" ]]; then
        echo -e "${colored_output}" >&2
    else
        echo -e "${colored_output}"
    fi

    # Print to log file without ANSI sequences
    # We rotate only on initial startup or when explicitly requested,
    # but for safety let's just append. Rotation is handled at session start.
    if [[ -w "$(dirname "${LOG_FILE}")" ]]; then
        echo -e "${raw_output}" >> "${LOG_FILE}" 2>/dev/null || true
    fi
}

# Public API
log_debug()   { _log "DEBUG"   "${C_CYAN}"   "$*"; }
log_info()    { _log "INFO"    "${C_BLUE}"   "$*"; }
log_success() { _log "SUCCESS" "${C_GREEN}"  "$*"; }
log_warn()    { _log "WARN"    "${C_YELLOW}" "$*"; }
log_error()   { _log "ERROR"   "${C_RED}"    "$*"; }

log_fatal() {
    log_error "FATAL: $*"
    log_error "Stack context:"
    local i=1
    while [[ $i -lt ${#FUNCNAME[@]} ]]; do
        log_error "  at ${FUNCNAME[$i]} (${BASH_SOURCE[$i]}:${BASH_LINENO[$i-1]})"
        ((i++))
    done
    exit 1
}

run_cmd() {
    if [[ $# -eq 0 ]]; then
        log_error "run_cmd requires arguments."
        return 1
    fi
    
    local cmd=("$@")
    local cmd_str="${cmd[*]}"

    if [[ "${DRY_RUN_ENABLED}" -eq 1 ]]; then
        log_info "[DRY-RUN] ${cmd_str}"
        return 0
    fi

    if [[ "${LOG_VERBOSE}" -eq 1 || "${LOG_DEBUG}" -eq 1 ]]; then
        log_info "Executing: ${cmd_str}"
    else
        log_debug "Executing: ${cmd_str}"
    fi

    local output exit_code
    if [[ "${LOG_DEBUG}" -eq 1 ]]; then
        # Direct stream for maximum visibility during debug
        "${cmd[@]}" 2>&1 | tee -a "${LOG_FILE}"
        exit_code=${PIPESTATUS[0]}
    else
        # Captured execution
        output=$("${cmd[@]}" 2>&1)
        exit_code=$?
        
        # Always log the output to file
        if [[ -w "$(dirname "${LOG_FILE}")" ]]; then
            echo "[${cmd_str}] output:" >> "${LOG_FILE}" 2>/dev/null || true
            echo "${output}" >> "${LOG_FILE}" 2>/dev/null || true
        fi
        
        if [[ ${exit_code} -ne 0 ]]; then
            log_error "Command failed (exit code ${exit_code}): ${cmd_str}"
            # Print readable failure
            if [[ -n "${output}" ]]; then
                echo -e "${C_PURPLE}--- command output ---${C_RESET}" >&2
                echo "${output}" >&2
                echo -e "${C_PURPLE}----------------------${C_RESET}" >&2
            fi
        fi
    fi

    return "${exit_code}"
}

init_logging_session() {
    _rotate_logs
    
    # Gather session info
    local kernel_ver os_name model
    kernel_ver="$(uname -r 2>/dev/null || echo 'Unknown')"
    # shellcheck disable=SC1091
    os_name="$(source /etc/os-release 2>/dev/null && echo "${PRETTY_NAME}" || echo 'Unknown OS')"
    model="$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo 'Unknown Model')"
    
    log_info "=================================================="
    log_info "Installer Session Started"
    log_info "Timestamp     : $(date -Iseconds)"
    log_info "Repository    : v2.0 (Redesign)"
    log_info "OS            : ${os_name}"
    log_info "Kernel        : ${kernel_ver}"
    log_info "Hostname      : $(hostname 2>/dev/null || echo 'Unknown')"
    log_info "Board Model   : ${model}"
    log_info "=================================================="
    
    # Initialize trap for session footer
    trap close_logging_session EXIT
}

close_logging_session() {
    # Only run once
    trap - EXIT
    
    local exit_code=$?
    local elapsed=$(( SECONDS - SESSION_START_TIME ))
    
    log_info "=================================================="
    log_info "Installer Session Completed"
    log_info "Elapsed Time  : ${elapsed} seconds"
    log_info "Exit Code     : ${exit_code}"
    
    if [[ "${SESSION_WARNINGS}" -gt 0 ]]; then
        log_warn "Total Warnings: ${SESSION_WARNINGS}"
    else
        log_info "Total Warnings: 0"
    fi
    
    if [[ "${SESSION_ERRORS}" -gt 0 ]]; then
        log_error "Total Errors  : ${SESSION_ERRORS}"
    else
        log_info "Total Errors  : 0"
    fi
    log_info "=================================================="
    
    exit "${exit_code}"
}
