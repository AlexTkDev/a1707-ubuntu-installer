# shellcheck shell=bash
# shellcheck disable=SC2034,SC2154
# checks/04_audio.sh

check_id="audio"
check_title="Audio Driver (Cirrus Logic)"
check_description="Verifies the Cirrus Logic audio package and DKMS module are installed and loaded."

run_check() {
    local pkg_installed=0
    local dkms_registered=0
    local module_loaded=0

    # 1. Check if package is installed
    if dpkg -l | grep -q "^i[iUF][[:space:]]*${AUDIO_PKG_NAME}[[:space:]]"; then
        pkg_installed=1
    fi

    # 2. Check if DKMS module is registered & built
    if dkms status | grep -q "${AUDIO_DRIVER}"; then
        dkms_registered=1
    fi

    # 3. Check if module is loaded
    if lsmod | grep -q "${AUDIO_DRIVER}"; then
        module_loaded=1
    fi

    if [[ ${pkg_installed} -eq 1 && ${dkms_registered} -eq 1 ]]; then
        if [[ ${module_loaded} -eq 1 ]]; then
            RESULT_MESSAGE="Package installed and module operational."
            return 0
        else
            RESULT_MESSAGE="Package installed but module not loaded. A reboot or manual load may be required."
            RESULT_RECOMMENDATION="Run: sudo modprobe ${AUDIO_DRIVER}"
            RESULT_REPAIR_ID="audio"
            return 1
        fi
    fi

    RESULT_MESSAGE="Package missing, DKMS failed, or codec unavailable."
    RESULT_RECOMMENDATION="Run repair.sh --audio"
    RESULT_REPAIR_ID="audio"
    return 2
}
