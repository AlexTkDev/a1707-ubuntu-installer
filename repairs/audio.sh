# repairs/audio.sh

REPAIR_ID="audio"
REPAIR_DESCRIPTION="Installs offline Cirrus Logic audio DKMS package."

repair() {
    local deb_pkg="${SCRIPT_DIR}/assets/packages/mbp-cirrus-audio-dkms_1.0-1_all.deb"
    
    if [[ ! -f "${deb_pkg}" ]]; then
        log_error "Audio package not found: ${deb_pkg}"
        return 1
    fi

    # DKMS uninstalls automatically upgrade cleanly via dpkg/apt in most cases,
    # but we force install it via apt-get to resolve any local dependencies if needed.
    # --allow-downgrades just in case
    run_cmd apt-get install -y --reinstall "${deb_pkg}"
    return $?
}

repair_validate() {
    if dkms status | grep -q "snd_hda_macbookpro"; then
        return 0
    fi
    return 1
}

repair_rollback() {
    log_warn "Removing failed audio dkms."
    run_cmd apt-get remove -y mbp-cirrus-audio-dkms || true
}
