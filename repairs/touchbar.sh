# repairs/touchbar.sh

REPAIR_ID="touchbar"
REPAIR_DESCRIPTION="Reinstalls offline Touch Bar DKMS package."

source "${SCRIPT_DIR}/platforms/macbookpro14-3.sh"
source "${SCRIPT_DIR}/checks/05_touchbar.sh"

repair() {
    if [[ "${TOUCHBAR_SUPPORTED:-0}" -eq 0 ]]; then
        log_info "Touch Bar unsupported. Nothing to repair."
        return 0
    fi

    local deb_pkg="${SCRIPT_DIR}/assets/packages/${TOUCHBAR_PKG_FILE}"
    
    if [[ ! -f "${deb_pkg}" ]]; then
        log_error "Touch Bar package not found: ${deb_pkg}"
        return 1
    fi

    run_cmd apt-get install -y --reinstall "${deb_pkg}"
    return $?
}

repair_validate() {
    # Reuse check logic
    if run_check; then
        return 0
    fi
    # If package installed but module inactive, consider it a WARN (1), which is acceptable
    if [[ $? -eq 1 ]]; then
        return 0
    fi
    return 1
}

repair_rollback() {
    log_warn "Removing failed touchbar dkms."
    run_cmd apt-get remove -y "${TOUCHBAR_PKG_NAME}" || true
}
