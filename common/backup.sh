#!/usr/bin/env bash
# common/backup.sh
# Non-destructive backup framework

export BACKUP_DIR="/var/backups/macbookpro14-linux-support"
export STATE_DIR="/var/lib/macbookpro14-installer"
export BACKUP_MANIFEST="${STATE_DIR}/backups.manifest"

safe_backup() {
    local target_file="$1"
    
    if [[ -z "${target_file}" ]]; then
        echo "Error: target file not specified for backup." >&2
        return 1
    fi

    # Nothing to backup if the file doesn't exist
    if [[ ! -f "${target_file}" && ! -L "${target_file}" ]]; then
        return 0
    fi

    local backup_path="${BACKUP_DIR}${target_file}"

    if [[ ! -e "${backup_path}" ]]; then
        mkdir -p "${BACKUP_DIR}$(dirname "${target_file}")" "${STATE_DIR}"
        cp -a "${target_file}" "${backup_path}"
        
        # Record in manifest if not already present
        if ! grep -Fxq "${target_file}" "${BACKUP_MANIFEST}" 2>/dev/null; then
            echo "${target_file}" >> "${BACKUP_MANIFEST}"
        fi
        
        echo "Created backup: ${target_file} -> ${backup_path}"
    else
        echo "Backup already exists for ${target_file}, skipping."
    fi
}

restore_backups() {
    if [[ ! -f "${BACKUP_MANIFEST}" ]]; then
        echo "No backup manifest found at ${BACKUP_MANIFEST}." >&2
        return 0
    fi

    local target_file
    while IFS= read -r target_file; do
        [[ -z "${target_file}" ]] && continue
        
        local backup_path="${BACKUP_DIR}${target_file}"
        if [[ -e "${backup_path}" ]]; then
            echo "Restoring ${target_file} from backup..."
            cp -a "${backup_path}" "${target_file}"
        else
            echo "Warning: Backup missing for ${target_file}" >&2
        fi
    done < "${BACKUP_MANIFEST}"
}
