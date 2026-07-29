#!/usr/bin/env bash
# scripts/07_camera.sh
# Installs the FaceTime HD driver (facetimehd) and firmware.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common/context.sh"
source "${COMMON_DIR}/logging.sh"
source "${COMMON_DIR}/state.sh"
source "${COMMON_DIR}/package.sh"

log_info "Installing Camera (FaceTime HD) framework..."

# 1. Platform validation
if [[ "${CAMERA_SUPPORTED:-0}" -eq 0 ]]; then
    log_info "Camera not supported on this platform. Skipping."
    exit 0
fi

# 2. Firmware deployment
FIRMWARE_SOURCE="${ASSETS_DIR}/firmware/facetimehd/${CAMERA_FIRMWARE}"
FIRMWARE_DEST_DIR="/usr/lib/firmware/facetimehd"
FIRMWARE_DEST="${FIRMWARE_DEST_DIR}/firmware.bin"

if [[ ! -f "${FIRMWARE_SOURCE}" ]]; then
    log_warn "FaceTime HD firmware not found at ${FIRMWARE_SOURCE}."
    log_warn "Please run 'sudo ./extractors/facetimehd.sh' (requires macOS partition) to generate it."
else
    log_info "Deploying FaceTime HD firmware..."
    run_cmd mkdir -p "${FIRMWARE_DEST_DIR}"
    
    if [[ ! -f "${FIRMWARE_DEST}" || "$(sha256sum "${FIRMWARE_DEST}" | awk '{print $1}')" != "$(sha256sum "${FIRMWARE_SOURCE}" | awk '{print $1}')" ]]; then
        safe_backup "${FIRMWARE_DEST}"
        run_cmd cp "${FIRMWARE_SOURCE}" "${FIRMWARE_DEST}"
        run_cmd chmod 644 "${FIRMWARE_DEST}"
        record_install "file" "${FIRMWARE_DEST}"
        log_success "Camera firmware installed."
    else
        log_debug "Camera firmware is already up-to-date."
    fi
fi

# 3. DKMS Package installation
install_dkms_package "${CAMERA_PKG_NAME}" "${CAMERA_PKG_FILE}" "${CAMERA_DRIVER}"

# 4. Modprobe recommendation
if ! lsmod | grep -q "^${CAMERA_DRIVER} "; then
    log_warn "The ${CAMERA_DRIVER} module is not loaded."
    log_warn "To enable the camera immediately, run:"
    log_warn "  sudo modprobe ${CAMERA_DRIVER}"
fi

log_success "Camera module installation phase complete."
