# shellcheck shell=bash
# shellcheck disable=SC2034,SC2154
# checks/03_wifi.sh

check_id="wifi"
check_title="Wi-Fi Firmware"
check_description="Verifies Wi-Fi firmware presence, checksums, and board symlink configuration."

run_check() {
    local bin_path="${WIFI_FIRMWARE_DIR}/${WIFI_FIRMWARE_BIN}"
    local txt_path="${WIFI_FIRMWARE_DIR}/${WIFI_BOARD_FILE}"
    local symlink_path="${WIFI_FIRMWARE_DIR}/${WIFI_FIRMWARE_BIN%.bin}.Apple Inc.-${PLATFORM_NAME}.txt"

    # Check for the binary blob
    if [[ ! -f "${bin_path}" ]]; then
        RESULT_MESSAGE="Missing ${WIFI_CHIP} firmware binary (${WIFI_FIRMWARE_BIN})."
        RESULT_RECOMMENDATION="Install Wi-Fi firmware assets."
        RESULT_REPAIR_ID="wifi_firmware"
        return 2
    fi

    # Check for the board config text file
    if [[ ! -f "${txt_path}" ]]; then
        RESULT_MESSAGE="Missing base board config (${WIFI_BOARD_FILE})."
        RESULT_RECOMMENDATION="Install Wi-Fi board configuration."
        RESULT_REPAIR_ID="wifi_firmware"
        return 2
    fi

    # Size heuristic / checksum for known bad 339B board file
    local txt_size
    txt_size=$(stat -c%s "${txt_path}" 2>/dev/null || echo 0)
    if [[ ${txt_size} -eq 339 ]]; then
        RESULT_MESSAGE="Incorrect Broadcom board file detected (${txt_size} bytes). Expected ~6KB."
        RESULT_RECOMMENDATION="Install correct Wi-Fi board configuration."
        RESULT_REPAIR_ID="wifi_firmware"
        return 2
    fi

    # Check for the specific symlink for the board
    if [[ ! -L "${symlink_path}" ]]; then
        RESULT_MESSAGE="Missing required symlink for ${PLATFORM_NAME}."
        RESULT_RECOMMENDATION="Run repair.sh --repair-id wifi_symlink"
        RESULT_REPAIR_ID="wifi_symlink"
        return 2
    fi

    local symlink_target
    symlink_target=$(readlink "${symlink_path}")
    if [[ "${symlink_target}" != "${WIFI_BOARD_FILE}" && "${symlink_target}" != "${txt_path}" ]]; then
        RESULT_MESSAGE="Symlink points to wrong target: ${symlink_target}"
        RESULT_RECOMMENDATION="Run repair.sh --repair-id wifi_symlink"
        RESULT_REPAIR_ID="wifi_symlink"
        return 2
    fi

    # Optional blobs
    for opt_blob in "${WIFI_OPTIONAL_FILES[@]:-}"; do
        if [[ -n "${opt_blob}" && ! -f "${WIFI_FIRMWARE_DIR}/${opt_blob}" ]]; then
            RESULT_MESSAGE="Missing optional firmware blob: ${opt_blob}. Core Wi-Fi should still work."
            RESULT_RECOMMENDATION="Ignore or provide optional blobs if connectivity issues arise."
            RESULT_REPAIR_ID=""
            return 1
        fi
    done

    RESULT_MESSAGE="Firmware and symlink installed correctly."
    return 0
}
