# shellcheck shell=bash
# shellcheck disable=SC2034,SC2154
# checks/06_camera.sh

check_id="camera"
check_title="Camera (FaceTime HD)"
check_description="Verifies the FaceTime HD DKMS package, firmware, and module status."

run_check() {
    if [[ "${CAMERA_SUPPORTED:-0}" -eq 0 ]]; then
        RESULT_MESSAGE="Camera not supported on this platform."
        return 0
    fi

    local firmware_dest="/usr/lib/firmware/facetimehd/firmware.bin"
    
    if [[ ! -f "${firmware_dest}" ]]; then
        RESULT_MESSAGE="FaceTime HD firmware is missing."
        RESULT_RECOMMENDATION="Run extractors/facetimehd.sh from macOS or supply firmware.bin manually, then run repair.sh --camera"
        RESULT_REPAIR_ID="camera"
        return 2
    fi

    local dkms_status
    dkms_status="$(run_cmd dkms status | grep "${CAMERA_PKG_NAME}" || true)"
    
    if [[ -z "${dkms_status}" ]]; then
        RESULT_MESSAGE="facetimehd DKMS package is not installed."
        RESULT_RECOMMENDATION="Run repair.sh --camera"
        RESULT_REPAIR_ID="camera"
        return 2
    fi

    if ! echo "${dkms_status}" | grep -q "installed"; then
        RESULT_MESSAGE="facetimehd DKMS package is added but not built for current kernel."
        RESULT_RECOMMENDATION="Run sudo dkms autoinstall"
        RESULT_REPAIR_ID="camera"
        return 2
    fi

    if ! lsmod | grep -q "^${CAMERA_DRIVER} "; then
        RESULT_MESSAGE="DKMS and firmware installed, but ${CAMERA_DRIVER} module is not loaded."
        RESULT_RECOMMENDATION="Run: sudo modprobe ${CAMERA_DRIVER}"
        RESULT_REPAIR_ID="camera"
        return 1
    fi

    RESULT_MESSAGE="Camera module and firmware are installed and loaded."
    return 0
}
