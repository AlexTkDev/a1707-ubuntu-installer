# checks/01_platform.sh

check_id="platform"
check_title="Platform Compatibility"
check_description="Verifies the current hardware matches the supported platform."

run_check() {
    local current_board=""
    if [[ -f /sys/class/dmi/id/board_name ]]; then
        current_board="$(cat /sys/class/dmi/id/board_name)"
    fi

    if [[ -z "${current_board}" ]]; then
        RESULT_MESSAGE="Could not read board ID from sysfs. Are you running in a VM?"
        RESULT_RECOMMENDATION="Run on physical Apple hardware."
        RESULT_REPAIR_ID=""
        return 1
    fi

    if [[ "${current_board}" != "${BOARD_ID}" ]]; then
        RESULT_MESSAGE="Detected board ${current_board}, expected ${BOARD_ID}."
        RESULT_RECOMMENDATION="Check platform definition configuration."
        RESULT_REPAIR_ID=""
        return 2
    fi

    RESULT_MESSAGE="Hardware matches platform ${PLATFORM_NAME}."
    return 0
}
