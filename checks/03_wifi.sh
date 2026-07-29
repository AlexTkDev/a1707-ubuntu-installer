# checks/03_wifi.sh

check_id="wifi"
check_title="Wi-Fi Firmware"
check_description="Verifies Wi-Fi firmware presence and board symlink configuration."

run_check() {
    # Check for the binary blob
    if [[ ! -f "/lib/firmware/brcm/brcmfmac43602-pcie.bin" ]]; then
        RESULT_MESSAGE="Missing ${WIFI_CHIP} firmware binary."
        RESULT_RECOMMENDATION="Install Wi-Fi firmware assets."
        RESULT_REPAIR_ID="wifi_firmware"
        return 2
    fi

    # Check for the bugzilla board config text file
    if [[ ! -f "/lib/firmware/brcm/brcmfmac43602-pcie.txt" ]]; then
        RESULT_MESSAGE="Missing base board config (brcmfmac43602-pcie.txt)."
        RESULT_RECOMMENDATION="Install Wi-Fi board configuration."
        RESULT_REPAIR_ID="wifi_board_config"
        return 2
    fi

    # Check for the specific symlink for the board
    local symlink_path="/lib/firmware/brcm/brcmfmac43602-pcie.Apple Inc.-${PLATFORM_NAME}.txt"
    if [[ ! -L "${symlink_path}" ]]; then
        RESULT_MESSAGE="Missing required symlink for ${PLATFORM_NAME}."
        RESULT_RECOMMENDATION="Run repair.sh --wifi-symlink"
        RESULT_REPAIR_ID="wifi_symlink"
        return 2
    fi

    # Optional: check if the symlink actually points to the correct file
    local symlink_target
    symlink_target=$(readlink "${symlink_path}")
    if [[ "${symlink_target}" != "brcmfmac43602-pcie.txt" && "${symlink_target}" != "/lib/firmware/brcm/brcmfmac43602-pcie.txt" ]]; then
        RESULT_MESSAGE="Symlink points to wrong target: ${symlink_target}"
        RESULT_RECOMMENDATION="Run repair.sh --wifi-symlink"
        RESULT_REPAIR_ID="wifi_symlink"
        return 2
    fi

    RESULT_MESSAGE="Firmware and symlink installed correctly."
    return 0
}
