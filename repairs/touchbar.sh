# repairs/touchbar.sh

REPAIR_ID="touchbar"
REPAIR_DESCRIPTION="Installs offline Touch Bar DKMS package."

repair() {
    local deb_pkg="${SCRIPT_DIR}/assets/packages/mbp-t1-touchbar-dkms_1.0-2_all.deb"
    
    if [[ ! -f "${deb_pkg}" ]]; then
        log_error "Touch Bar package not found: ${deb_pkg}"
        return 1
    fi

    run_cmd apt-get install -y --reinstall "${deb_pkg}"
    return $?
}

repair_validate() {
    # Check if module is installed (status might show applespi or appletb depending on package)
    # The package name usually maps to the primary module or we can just check dpkg
    if dpkg -l | grep -q "mbp-t1-touchbar-dkms"; then
        return 0
    fi
    return 1
}

repair_rollback() {
    log_warn "Removing failed touchbar dkms."
    run_cmd apt-get remove -y mbp-t1-touchbar-dkms || true
}
