#!/usr/bin/env bash
# scripts/04_touchbar.sh
# Platform-driven, offline-first Touch Bar deployment module

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/common/logging.sh"
source "${SCRIPT_DIR}/common/backup.sh"
source "${SCRIPT_DIR}/common/state.sh"
source "${SCRIPT_DIR}/common/system.sh"
source "${SCRIPT_DIR}/common/package.sh"
source "${SCRIPT_DIR}/checks/05_touchbar.sh"


if [[ -z "${PLATFORM_NAME:-}" ]]; then
    source "${SCRIPT_DIR}/platforms/macbookpro14-3.sh"
fi

log_info "Starting Touch Bar deployment module for ${PLATFORM_NAME}..."

if [[ "${TOUCHBAR_SUPPORTED:-0}" -eq 0 ]]; then
    log_info "Touch Bar is not supported on this platform. Skipping."
    return 0
fi

# 1. Idempotency Check
if run_check; then
    if [[ "${RESULT_MESSAGE}" == *"operational"* ]]; then
        log_success "Touch Bar package is already installed and verified. Skipping."
        return 0
    fi
fi

log_info "Proceeding with Touch Bar and Touchpad driver installation..."

# Install X11/libinput touchpad driver if missing
if ! dpkg-query -W -f='${Status}\n' xserver-xorg-input-libinput 2>/dev/null | grep -q "installed"; then
    log_info "Installing xserver-xorg-input-libinput for optimal touchpad behavior..."
    libinput_deb="$(find "${ASSETS_DIR}/packages" -maxdepth 1 -name "xserver-xorg-input-libinput_*.deb" -print -quit 2>/dev/null || true)"
    if [[ -n "${libinput_deb}" && -f "${libinput_deb}" ]]; then
        run_cmd dpkg -i "${ASSETS_DIR}/packages/xserver-xorg"* "${ASSETS_DIR}/packages/xcvt"* 2>/dev/null || run_cmd apt-get install -y "${libinput_deb}" || true
    else
        run_cmd apt-get install -y xserver-xorg-input-libinput || log_warn "Could not install xserver-xorg-input-libinput."
    fi
fi

if ! install_dkms_package "${TOUCHBAR_PKG_NAME}" "${TOUCHBAR_PKG_FILE}"; then
    log_fatal "Touch Bar deployment failed during package installation."
fi

# 2. Final Validation
log_info "Running post-installation validation..."
if run_check; then
    log_success "Touch Bar deployment completed successfully."
else
    if [[ "${RESULT_MESSAGE}" == *"module inactive"* ]]; then
        log_warn "Installation succeeded, but kernel module is not loaded."
        log_warn "Please reload manually or reboot."
    else
        log_fatal "Validation failed post-installation: ${RESULT_MESSAGE}"
    fi
fi

return 0
