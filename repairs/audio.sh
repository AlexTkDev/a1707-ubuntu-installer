# shellcheck shell=bash
# shellcheck disable=SC2034,SC2154
# repairs/audio.sh

REPAIR_ID="audio"
REPAIR_DESCRIPTION="Reinstalls offline Cirrus Logic audio DKMS package."

source "${SCRIPT_DIR}/platforms/macbookpro14-3.sh"
source "${SCRIPT_DIR}/checks/04_audio.sh"

repair() {
    local deb_pkg="${SCRIPT_DIR}/assets/packages/${AUDIO_PKG_FILE}"
    
    if [[ ! -f "${deb_pkg}" ]]; then
        log_error "Audio package not found: ${deb_pkg}"
        return 1
    fi

    # Using standard apt reinstall strategy with local deb
    run_cmd apt-get install -y --reinstall "${deb_pkg}"
    return $?
}

repair_validate() {
    # Reuse check logic
    if run_check; then
        return 0
    fi
    # If package installed but module not loaded, it's considered WARN (1) which is acceptable for repair success
    if [[ $? -eq 1 ]]; then
        return 0
    fi
    return 1
}

repair_rollback() {
    log_warn "Removing failed audio dkms."
    run_cmd apt-get remove -y "${AUDIO_PKG_NAME}" || true
}
