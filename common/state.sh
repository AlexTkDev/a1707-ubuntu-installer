#!/usr/bin/env bash
# common/state.sh
# Manages installer state, manifests, and versioning.

export STATE_DIR="/var/lib/macbookpro14-installer"
export STATE_FILE="${STATE_DIR}/state.env"
export BACKUP_MANIFEST="${STATE_DIR}/backups.manifest"
export INSTALLER_MANIFEST="${STATE_DIR}/installer.manifest"

record_install() {
    local item_type="$1"
    local item_id="$2"
    local extra="$3"
    
    # Do not track during dry runs
    if [[ "${DRY_RUN_ENABLED:-0}" -eq 1 ]]; then
        return 0
    fi
    
    mkdir -p "${STATE_DIR}"
    
    # Avoid duplicate lines in manifest
    local entry=""
    case "${item_type}" in
        file|symlink|directory)
            entry="TYPE=${item_type} PATH=${item_id} TARGET=${extra}"
            ;;
        package|service|module)
            entry="TYPE=${item_type} NAME=${item_id}"
            ;;
        *)
            log_error "Unknown type for manifest: ${item_type}"
            return 1
            ;;
    esac

    if ! grep -Fxq "${entry}" "${INSTALLER_MANIFEST}" 2>/dev/null; then
        echo "${entry}" >> "${INSTALLER_MANIFEST}"
    fi
}
