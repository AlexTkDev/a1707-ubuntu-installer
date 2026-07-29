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

# Pre-seed offline HDA source cache if available
local kernel_ver
kernel_ver="$(uname -r | cut -d'-' -f1)"
local cache_dir="/var/cache/mbp-cirrus-audio-dkms/hda-src"
local cache_file="${cache_dir}/hda-${kernel_ver}.tar.gz"
local asset_cache="${ASSETS_DIR}/audio/hda-${kernel_ver}.tar.gz"

if [[ -f "${asset_cache}" && ! -f "${cache_file}" ]]; then
    log_info "Pre-seeding offline Cirrus HDA source cache (${kernel_ver})..."
    run_cmd mkdir -p "${cache_dir}"
    run_cmd cp "${asset_cache}" "${cache_file}"
fi

# Fix upstream popd stack bug when cached sources are used
if [[ -f /usr/src/snd_hda_macbookpro-1.0/install.cirrus.driver.sh ]]; then
    run_cmd sed -i 's/popd > \/dev\/null/popd > \/dev\/null 2>\&1 || true/' /usr/src/snd_hda_macbookpro-1.0/install.cirrus.driver.sh
fi
if [[ -f /var/lib/dkms/snd_hda_macbookpro/1.0/build/install.cirrus.driver.sh ]]; then
    run_cmd sed -i 's/popd > \/dev\/null/popd > \/dev\/null 2>\&1 || true/' /var/lib/dkms/snd_hda_macbookpro/1.0/build/install.cirrus.driver.sh
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
