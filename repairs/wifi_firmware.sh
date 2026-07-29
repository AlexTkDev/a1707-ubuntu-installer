# shellcheck shell=bash
# shellcheck disable=SC2034,SC2154
# repairs/wifi_firmware.sh

REPAIR_ID="wifi_firmware"
REPAIR_DESCRIPTION="Installs offline Wi-Fi firmware assets."

source "${SCRIPT_DIR}/platforms/macbookpro14-3.sh"

repair() {
    local fw_dir="/lib/firmware/brcm"
    local bin_src="${SCRIPT_DIR}/assets/firmware/brcmfmac43602-pcie.bin"
    local txt_src="${SCRIPT_DIR}/assets/firmware/brcmfmac43602-pcie.txt"
    
    run_cmd mkdir -p "${fw_dir}"
    
    if [[ ! -f "${bin_src}" || ! -f "${txt_src}" ]]; then
        log_error "Offline Wi-Fi assets not found in ${SCRIPT_DIR}/assets/firmware/"
        return 1
    fi

    safe_backup "${fw_dir}/brcmfmac43602-pcie.bin"
    safe_backup "${fw_dir}/brcmfmac43602-pcie.txt"

    run_cmd cp -af "${bin_src}" "${fw_dir}/brcmfmac43602-pcie.bin"
    run_cmd cp -af "${txt_src}" "${fw_dir}/brcmfmac43602-pcie.txt"
    
    run_cmd chmod 644 "${fw_dir}/brcmfmac43602-pcie.bin" "${fw_dir}/brcmfmac43602-pcie.txt"
    
    return 0
}

repair_validate() {
    if [[ -f "/lib/firmware/brcm/brcmfmac43602-pcie.bin" && -f "/lib/firmware/brcm/brcmfmac43602-pcie.txt" ]]; then
        return 0
    fi
    return 1
}

repair_rollback() {
    log_info "No custom rollback required. Use rollback.sh to restore backups."
}
