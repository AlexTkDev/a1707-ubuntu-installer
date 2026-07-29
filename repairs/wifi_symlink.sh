# shellcheck shell=bash
# shellcheck disable=SC2034,SC2154
# repairs/wifi_symlink.sh

REPAIR_ID="wifi_symlink"
REPAIR_DESCRIPTION="Creates the correct board configuration symlink for Wi-Fi."

# Uses globals from doctor context (PLATFORM_NAME) but we should ideally detect or rely on it
source "${SCRIPT_DIR}/platforms/macbookpro14-3.sh" # simplified for now

repair() {
    local target_file="/lib/firmware/brcm/brcmfmac43602-pcie.txt"
    local symlink_path="/lib/firmware/brcm/brcmfmac43602-pcie.Apple Inc.-${PLATFORM_NAME}.txt"
    
    log_info "Creating symlink for ${PLATFORM_NAME} Wi-Fi."
    
    # Backup existing if it's not a symlink but a real file
    if [[ -f "${symlink_path}" && ! -L "${symlink_path}" ]]; then
        safe_backup "${symlink_path}"
    fi

    run_cmd rm -f "${symlink_path}"
    run_cmd ln -s "brcmfmac43602-pcie.txt" "${symlink_path}"
    return $?
}

repair_validate() {
    local symlink_path="/lib/firmware/brcm/brcmfmac43602-pcie.Apple Inc.-${PLATFORM_NAME}.txt"
    if [[ -L "${symlink_path}" ]]; then
        return 0
    fi
    return 1
}

repair_rollback() {
    local symlink_path="/lib/firmware/brcm/brcmfmac43602-pcie.Apple Inc.-${PLATFORM_NAME}.txt"
    log_warn "Removing failed symlink."
    run_cmd rm -f "${symlink_path}"
    # The common rollback/restore_backups would handle restoring if we replaced a real file
}
