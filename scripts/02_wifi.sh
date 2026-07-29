#!/usr/bin/env bash
# scripts/02_wifi.sh
# Platform-driven, offline-first Wi-Fi deployment module

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/common/logging.sh"
source "${SCRIPT_DIR}/common/backup.sh"
source "${SCRIPT_DIR}/common/state.sh"

# Source doctor checks to reuse validation logic
source "${SCRIPT_DIR}/checks/03_wifi.sh"

init_logging_session

log_info "Starting Wi-Fi deployment module..."

# Dynamically load platform (using doctor's detect logic or default)
# For simplicity in module, we try to source the active platform or fallback.
# In a real orchestration run, the main script sets this.
if [[ -z "${PLATFORM_NAME:-}" ]]; then
    source "${SCRIPT_DIR}/platforms/macbookpro14-3.sh"
fi

log_info "Target Platform: ${PLATFORM_NAME} (v${PLATFORM_VERSION:-1})"

# 1. Idempotency Check
if run_check; then
    log_success "Wi-Fi firmware is already installed and verified. Skipping."
    close_logging_session
fi

log_info "Proceeding with Wi-Fi firmware installation..."

ASSET_DIR="${SCRIPT_DIR}/assets/firmware"
CHECKSUMS_FILE="${ASSET_DIR}/SHA256SUMS"

verify_checksum() {
    local target_file="$1"
    local expected_filename="${2:-}"
    local filename
    if [[ -n "${expected_filename}" ]]; then
        filename="${expected_filename}"
    else
        filename="$(basename "${target_file}")"
    fi
    
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

install_firmware_file() {
    local filename="$1"
    local src_file="${ASSET_DIR}/${filename}"
    local dest_file="${WIFI_FIRMWARE_DIR}/${filename}"
    local tmp_file="${dest_file}.tmp.$$"
    
    if [[ ! -f "${src_file}" ]]; then
        log_error "Offline asset not found: ${src_file}"
        return 1
    fi
    
    log_info "Installing ${filename}..."
    
    # Backup
    safe_backup "${dest_file}"
    
    # Copy to temporary
    run_cmd cp -a "${src_file}" "${tmp_file}"
    
    # Verify checksum
    if ! verify_checksum "${tmp_file}" "${filename}"; then
        log_error "Verification failed for ${tmp_file}. Aborting."
        run_cmd rm -f "${tmp_file}"
        return 1
    fi
    
    # Atomic rename
    run_cmd mv -f "${tmp_file}" "${dest_file}"
    
    # Set permissions
    run_cmd chmod 644 "${dest_file}"
    
    # Record manifest
    record_install "file" "${dest_file}" ""
}

# 2. Install binaries
run_cmd mkdir -p "${WIFI_FIRMWARE_DIR}"
install_firmware_file "${WIFI_FIRMWARE_BIN}" || log_fatal "Failed to install ${WIFI_FIRMWARE_BIN}"
install_firmware_file "${WIFI_BOARD_FILE}" || log_fatal "Failed to install ${WIFI_BOARD_FILE}"

# 3. Create Symlinks
symlink_path="${WIFI_FIRMWARE_DIR}/${WIFI_FIRMWARE_BIN%.bin}.Apple Inc.-${PLATFORM_NAME}.txt"
symlink_target="${WIFI_BOARD_FILE}"

if [[ -L "${symlink_path}" ]]; then
    current_target="$(readlink "${symlink_path}")"
    if [[ "${current_target}" == "${symlink_target}" || "$(readlink -f "${symlink_path}")" == "$(readlink -f "${WIFI_FIRMWARE_DIR}/${symlink_target}")" ]]; then
        log_info "Symlink already correctly points to ${symlink_target}"
    else
        log_warn "Symlink incorrect. Recreating..."
        run_cmd rm -f "${symlink_path}"
        run_cmd ln -s "${symlink_target}" "${symlink_path}"
        record_install "symlink" "${symlink_path}" "${symlink_target}"
    fi
elif [[ -e "${symlink_path}" ]]; then
    log_warn "Target exists but is not a symlink. Backing up and replacing..."
    safe_backup "${symlink_path}"
    run_cmd rm -f "${symlink_path}"
    run_cmd ln -s "${symlink_target}" "${symlink_path}"
    record_install "symlink" "${symlink_path}" "${symlink_target}"
else
    log_info "Creating symlink for board configuration..."
    run_cmd ln -s "${symlink_target}" "${symlink_path}"
    record_install "symlink" "${symlink_path}" "${symlink_target}"
fi

# 4. Final Validation
log_info "Running post-installation validation..."
if run_check; then
    log_success "Wi-Fi firmware installed successfully."
    log_info "A module reload or reboot is recommended to apply changes."
    log_info "You may reload manually via: sudo modprobe -r brcmfmac_wcc brcmfmac brcmutil && sudo modprobe brcmfmac"
else
    log_fatal "Validation failed post-installation: ${RESULT_MESSAGE}"
fi

close_logging_session
