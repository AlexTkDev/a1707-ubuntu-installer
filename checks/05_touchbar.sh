# checks/05_touchbar.sh

check_id="touchbar"
check_title="Touch Bar / SPI Drivers"
check_description="Verifies the Touch Bar DKMS package and required SPI modules."

run_check() {
    if [[ "${TOUCHBAR_SUPPORTED:-0}" -eq 0 ]]; then
        RESULT_MESSAGE="Touch Bar is not supported on this platform."
        return 0
    fi

    local pkg_installed=0
    local dkms_registered=0
    local modules_loaded=0

    # 1. Check if package is installed
    if dpkg -l | grep -q "^ii[[:space:]]*${TOUCHBAR_PKG_NAME}[[:space:]]"; then
        pkg_installed=1
    fi

    # 2. Check if DKMS module is registered
    if dkms status | grep -q "${TOUCHBAR_PKG_NAME}"; then
        dkms_registered=1
    fi

    # 3. Check if any relevant modules are loaded
    local loaded_count=0
    for mod in "${TOUCHBAR_MODULES[@]}"; do
        if lsmod | grep -q "${mod}"; then
            ((loaded_count++))
        fi
    done
    
    if [[ ${loaded_count} -gt 0 ]]; then
        modules_loaded=1
    fi

    if [[ ${pkg_installed} -eq 1 && ${dkms_registered} -eq 1 ]]; then
        if [[ ${modules_loaded} -eq 1 ]]; then
            RESULT_MESSAGE="Package installed and module operational."
            return 0
        else
            RESULT_MESSAGE="Package installed but module inactive. A reboot or manual load may be required."
            RESULT_RECOMMENDATION="Run: sudo modprobe ${TOUCHBAR_MODULES[*]}"
            RESULT_REPAIR_ID="touchbar"
            return 1
        fi
    fi

    RESULT_MESSAGE="Package missing, DKMS failed, or device unavailable."
    RESULT_RECOMMENDATION="Run repair.sh --touchbar"
    RESULT_REPAIR_ID="touchbar"
    return 2
}
