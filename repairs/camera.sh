# shellcheck shell=bash
# shellcheck disable=SC2034,SC2154
# repairs/camera.sh

REPAIR_ID="camera"
REPAIR_DESCRIPTION="Reinstalls offline FaceTime HD firmware and DKMS package."

repair() {
    log_info "Executing camera repair..."
    if ! bash "${INSTALL_ROOT}/scripts/07_camera.sh"; then
        log_error "Camera reinstallation failed."
        return 1
    fi
    return 0
}

repair_validate() {
    source "${INSTALL_ROOT}/checks/06_camera.sh"
    run_check
    local ret=$?
    if [[ $ret -eq 2 ]]; then
        return 1
    fi
    return 0
}
