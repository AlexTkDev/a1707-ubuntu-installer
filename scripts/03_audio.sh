#!/usr/bin/env bash
# scripts/03_audio.sh
# Platform-driven, offline-first Audio deployment module

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/common/logging.sh"
source "${SCRIPT_DIR}/common/backup.sh"
source "${SCRIPT_DIR}/common/state.sh"
source "${SCRIPT_DIR}/common/system.sh"
source "${SCRIPT_DIR}/common/package.sh"
source "${SCRIPT_DIR}/checks/04_audio.sh"


if [[ -z "${PLATFORM_NAME:-}" ]]; then
    source "${SCRIPT_DIR}/platforms/macbookpro14-3.sh"
fi

log_info "Starting Audio deployment module for ${PLATFORM_NAME}..."

# 1. Idempotency Check
if run_check; then
    if [[ "${RESULT_MESSAGE}" == *"operational"* ]]; then
        log_success "Audio package is already installed and verified. Skipping."
        return 0
    fi
fi

log_info "Proceeding with Audio package installation..."

# Install linux-source dependency if required by Cirrus audio DKMS
local kernel_ver
kernel_ver="$(uname -r | cut -d'-' -f1)"
if ! ls /usr/src/linux-source-*.tar.bz2 >/dev/null 2>&1; then
    log_info "Installing linux-source dependency for Cirrus Audio..."
    run_cmd apt-get install -y "linux-source-${kernel_ver}" || run_cmd apt-get install -y linux-source || true
fi

if ! install_dkms_package "${AUDIO_PKG_NAME}" "${AUDIO_PKG_FILE}"; then
    log_fatal "Audio deployment failed during package installation."
fi

# 2. Final Validation
log_info "Running post-installation validation..."
if run_check; then
    log_success "Audio deployment completed successfully."
else
    if [[ "${RESULT_MESSAGE}" == *"module not loaded"* ]]; then
        log_warn "Installation succeeded, but kernel module is not loaded."
        log_warn "Please reload manually or reboot: sudo modprobe ${AUDIO_DRIVER}"
    else
        log_fatal "Validation failed post-installation: ${RESULT_MESSAGE}"
    fi
fi

return 0
