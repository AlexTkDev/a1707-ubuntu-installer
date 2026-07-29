#!/usr/bin/env bash
# rollback.sh - Safety-first recovery framework
# Restores only what the installer changed.

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common/context.sh"
source "${COMMON_DIR}/logging.sh"
source "${COMMON_DIR}/backup.sh"
source "${COMMON_DIR}/state.sh"

declare -i RESTORED_COUNT=0
declare -i SKIPPED_COUNT=0
declare -i PKG_REMOVED_COUNT=0
declare -i SVC_REMOVED_COUNT=0
declare -i WARNINGS_COUNT=0
declare -i ERRORS_COUNT=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN_ENABLED=1; LOG_INFO="[DRY-RUN] "; shift ;;
        *)
            log_error "Unknown argument: $1"
            echo "Usage: $0 [--dry-run]"
            exit 1
            ;;
    esac
done

init_logging_session
log_info "Initiating safe rollback procedure..."

# 1. Restore Backups (Files)
if [[ -f "${BACKUP_MANIFEST}" ]]; then
    log_info "Processing backup manifest..."
    while IFS= read -r target_file; do
        [[ -z "${target_file}" ]] && continue
        
        backup_path="${BACKUP_DIR}${target_file}"
        if [[ ! -e "${backup_path}" ]]; then
            log_warn "Backup does not exist for ${target_file}. Skipping."
            ((WARNINGS_COUNT++))
            ((SKIPPED_COUNT++))
            continue
        fi

        log_info "Restoring ${target_file} from backup."
        if [[ "${DRY_RUN_ENABLED}" -eq 0 ]]; then
            # Transactional validation: ensure destination is accessible
            if cp -a "${backup_path}" "${target_file}"; then
                ((RESTORED_COUNT++))
            else
                log_error "Failed to restore ${target_file}"
                ((ERRORS_COUNT++))
            fi
        else
            log_info "[DRY-RUN] Would restore ${target_file} from ${backup_path}"
            ((RESTORED_COUNT++))
        fi
    done < "${BACKUP_MANIFEST}"
else
    log_info "No backup manifest found. Skipping backup restoration."
fi

# 2. Process Installer Manifest (Symlinks, Packages, Services, Directories, Created Files)
if [[ -f "${INSTALLER_MANIFEST}" ]]; then
    log_info "Processing installer manifest..."
    while IFS= read -r line; do
        [[ -z "${line}" ]] && continue
        
        # Parse TYPE, PATH/NAME, TARGET
        # Using simple bash regex for safe parsing
        if [[ "${line}" =~ TYPE=([a-z]+)[[:space:]]+(PATH|NAME)=([^[:space:]]+)[[:space:]]*(TARGET=(.*))? ]]; then
            itype="${BASH_REMATCH[1]}"
            ikey="${BASH_REMATCH[2]}" # PATH or NAME
            ival="${BASH_REMATCH[3]}"
            itarget="${BASH_REMATCH[5]:-}"
            
            case "${itype}" in
                file)
                    # For files created by the installer (not backed up)
                    if [[ -f "${ival}" ]]; then
                        log_info "Removing installer-created file: ${ival}"
                        if [[ "${DRY_RUN_ENABLED}" -eq 0 ]]; then
                            rm -f "${ival}" || { log_error "Failed to remove ${ival}"; ((ERRORS_COUNT++)); }
                        fi
                    else
                        log_warn "File already missing: ${ival}"
                        ((WARNINGS_COUNT++))
                    fi
                    ;;
                symlink)
                    if [[ -L "${ival}" ]]; then
                        current_target="$(readlink "${ival}")"
                        if [[ "${current_target}" == "${itarget}" || "$(readlink -f "${ival}")" == "$(readlink -f "${itarget}")" ]]; then
                            log_info "Removing symlink: ${ival}"
                            if [[ "${DRY_RUN_ENABLED}" -eq 0 ]]; then
                                rm -f "${ival}" || { log_error "Failed to remove symlink ${ival}"; ((ERRORS_COUNT++)); }
                            fi
                        else
                            log_warn "Symlink ${ival} points to ${current_target}, expected ${itarget}. Skipping removal!"
                            ((WARNINGS_COUNT++))
                            ((SKIPPED_COUNT++))
                        fi
                    else
                        log_warn "Symlink missing or not a symlink: ${ival}"
                        ((WARNINGS_COUNT++))
                    fi
                    ;;
                package)
                    # Only remove specific packages safely
                    if dpkg -l | grep -q "^ii[[:space:]]*${ival}[[:space:]]"; then
                        log_info "Removing installer-managed package: ${ival}"
                        if [[ "${DRY_RUN_ENABLED}" -eq 0 ]]; then
                            apt-get remove -y "${ival}" || { log_error "Failed to remove package ${ival}"; ((ERRORS_COUNT++)); }
                        fi
                        ((PKG_REMOVED_COUNT++))
                    else
                        log_info "Package ${ival} is not installed."
                        ((SKIPPED_COUNT++))
                    fi
                    ;;
                service)
                    if systemctl is-active --quiet "${ival}" || systemctl is-enabled --quiet "${ival}"; then
                        log_info "Stopping and disabling service: ${ival}"
                        if [[ "${DRY_RUN_ENABLED}" -eq 0 ]]; then
                            systemctl stop "${ival}" || true
                            systemctl disable "${ival}" || true
                        fi
                        ((SVC_REMOVED_COUNT++))
                    fi
                    ;;
                directory)
                    if [[ -d "${ival}" ]]; then
                        # Only remove if empty
                        if [[ -z "$(ls -A "${ival}" 2>/dev/null)" ]]; then
                            log_info "Removing empty directory: ${ival}"
                            if [[ "${DRY_RUN_ENABLED}" -eq 0 ]]; then
                                rmdir "${ival}" || { log_error "Failed to remove directory ${ival}"; ((ERRORS_COUNT++)); }
                            fi
                        else
                            log_warn "Directory not empty, skipping removal: ${ival}"
                            ((WARNINGS_COUNT++))
                            ((SKIPPED_COUNT++))
                        fi
                    fi
                    ;;
                module)
                    log_info "Module un-registration for ${ival} is handled by package removal."
                    ;;
                *)
                    log_warn "Unknown manifest entry type: ${itype}"
                    ((WARNINGS_COUNT++))
                    ;;
            esac
        else
            log_warn "Failed to parse manifest line: ${line}"
            ((WARNINGS_COUNT++))
        fi
    done < "${INSTALLER_MANIFEST}"
else
    log_info "No installer manifest found. Skipping manifest-based cleanup."
fi

log_info "----------------------------------------"
log_info "Rollback Summary:"
log_info "Files restored   : ${RESTORED_COUNT}"
log_info "Items skipped    : ${SKIPPED_COUNT}"
log_info "Packages removed : ${PKG_REMOVED_COUNT}"
log_info "Services removed : ${SVC_REMOVED_COUNT}"
log_info "Warnings         : ${WARNINGS_COUNT}"
log_info "Errors           : ${ERRORS_COUNT}"

if [[ "${DRY_RUN_ENABLED}" -eq 0 && ${ERRORS_COUNT} -eq 0 ]]; then
    # Clear manifests after successful rollback
    rm -f "${BACKUP_MANIFEST}" "${INSTALLER_MANIFEST}" 2>/dev/null || true
fi

close_logging_session

if [[ ${ERRORS_COUNT} -gt 0 ]]; then
    exit 2
elif [[ ${WARNINGS_COUNT} -gt 0 ]]; then
    exit 1
else
    exit 0
fi
