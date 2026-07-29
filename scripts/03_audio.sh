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

source "${SCRIPT_DIR}/checks/04_audio.sh"

init_logging_session

if [[ -z "${PLATFORM_NAME:-}" ]]; then
    source "${SCRIPT_DIR}/platforms/macbookpro14-3.sh"
fi

log_info "Starting Audio deployment module for ${PLATFORM_NAME}..."

# 1. Idempotency Check
if run_check; then
    if [[ "${RESULT_MESSAGE}" == *"operational"* ]]; then
        log_success "Audio package is already installed and verified. Skipping."
        close_logging_session
    fi
fi

log_info "Proceeding with Audio package installation..."

ASSET_DIR="${SCRIPT_DIR}/assets/packages"
CHECKSUMS_FILE="${ASSET_DIR}/SHA256SUMS"
DEB_FILE="${ASSET_DIR}/${AUDIO_PKG_FILE}"

# 2. Kernel compatibility validation
validate_kernel_compatibility "${AUDIO_PKG_NAME}"

# 3. File and Checksum Verification
if [[ ! -f "${DEB_FILE}" ]]; then
    log_fatal "Audio package not found: ${DEB_FILE}"
fi

verify_checksum() {
    local target_file="$1"
    local filename
    filename="$(basename "${target_file}")"
    
    if [[ ! -f "${CHECKSUMS_FILE}" ]]; then
        log_error "Checksums file missing at ${CHECKSUMS_FILE}"
        return 1
    fi
    
    local expected_hash
    expected_hash="$(grep "[[:space:]]${filename}$" "${CHECKSUMS_FILE}" | awk '{print $1}')"
    
    if [[ -z "${expected_hash}" ]]; then
        log_error "No checksum found for ${filename} in SHA256SUMS"
        return 1
    fi
    
    local actual_hash
    actual_hash="$(sha256sum "${target_file}" | awk '{print $1}')"
    
    if [[ "${actual_hash}" != "${expected_hash}" ]]; then
        log_error "Checksum mismatch for ${filename}. Expected: ${expected_hash}, Got: ${actual_hash}"
        return 1
    fi
    return 0
}

if ! verify_checksum "${DEB_FILE}"; then
    log_fatal "Checksum verification failed for ${DEB_FILE}"
fi

# 4. Integrity Verification via dpkg-deb
log_info "Verifying package integrity..."
if ! run_cmd dpkg-deb --info "${DEB_FILE}"; then
    log_fatal "Package integrity check failed for ${DEB_FILE}"
fi

# 5. Installation
log_info "Installing ${AUDIO_PKG_NAME}..."
if run_cmd apt-get install -y "${DEB_FILE}"; then
    log_success "Package ${AUDIO_PKG_NAME} installed via apt."
else
    log_warn "apt-get install failed, attempting fallback with dpkg..."
    if ! run_cmd dpkg -i "${DEB_FILE}"; then
        log_fatal "Fallback installation via dpkg failed. Dependencies might be missing."
    fi
fi

record_install "package" "${AUDIO_PKG_NAME}" ""

# 6. Final Validation
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

# Check DKMS kernel mismatch
current_kernel="$(uname -r)"
if dkms status "${AUDIO_PKG_NAME}" | grep -q "installed" && ! dkms status "${AUDIO_PKG_NAME}" | grep -q "${current_kernel}"; then
    log_warn "Installed DKMS build does not match current kernel (${current_kernel})."
    log_warn "Recommendation: run 'sudo dkms autoinstall' or reboot."
fi

close_logging_session
