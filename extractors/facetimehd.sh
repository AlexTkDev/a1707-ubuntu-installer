#!/usr/bin/env bash
# shellcheck shell=bash
# extractors/facetimehd.sh
# Extracts the FaceTime HD firmware from the local macOS partition.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

export FACETIMEHD_FIRMWARE_DEST="${ASSETS_DIR}/firmware/facetimehd/firmware.bin"

extract_facetimehd() {
    log_info "Starting FaceTime HD firmware extraction..."
    
    mkdir -p "$(dirname "${FACETIMEHD_FIRMWARE_DEST}")"

    if [[ -f "${FACETIMEHD_FIRMWARE_DEST}" ]]; then
        log_info "Firmware already exists at ${FACETIMEHD_FIRMWARE_DEST}. Skipping."
        return 0
    fi

    if ! mount_macos; then
        log_error "Cannot extract FaceTime HD firmware without macOS partition."
        return 1
    fi

    log_info "Searching for AppleCameraInterface..."
    local target_kext=""
    
    # We use find to locate the binary. We limit depth to avoid excessively long searches.
    # On newer macOS, it might be in System/Library/Extensions or similar paths.
    local found_path
    found_path="$(find "${MACOS_MOUNT_POINT}" -maxdepth 6 -type f -path "*/AppleCameraInterface.kext/Contents/MacOS/AppleCameraInterface" | head -n 1)"
    
    if [[ -n "${found_path}" && -f "${found_path}" ]]; then
        target_kext="${found_path}"
    fi

    if [[ -z "${target_kext}" ]]; then
        log_error "AppleCameraInterface.kext not found in macOS partition."
        unmount_macos
        return 1
    fi

    log_info "Found AppleCameraInterface at ${target_kext}"
    
    # We copy it locally to extract
    local temp_dir
    temp_dir="$(mktemp -d)"
    cp "${target_kext}" "${temp_dir}/AppleCameraInterface"
    
    unmount_macos

    log_info "Extracting firmware.bin..."
    
    # Here we would call the community facetimehd firmware extractor script.
    # E.g. curl -sL https://raw.githubusercontent.com/patjak/facetimehd-firmware/master/extract-firmware.sh | bash
    # Since we are offline-first, the project should bundle the python extraction script or logic.
    # For now, this is a stub for the actual extraction logic:
    
    if [[ ! -f "${SCRIPT_DIR}/extract-facetimehd.sh" ]]; then
        log_error "Extractor script extract-facetimehd.sh not found in extractors/."
        rm -rf "${temp_dir}"
        return 1
    fi
    
    # The script outputs firmware.bin to the current directory
    (
        cd "${temp_dir}" || exit 1
        run_cmd bash "${SCRIPT_DIR}/extract-facetimehd.sh" -x "AppleCameraInterface"
        if [[ -f "firmware.bin" ]]; then
            cp "firmware.bin" "${FACETIMEHD_FIRMWARE_DEST}"
        fi
    )
    
    if [[ ! -f "${FACETIMEHD_FIRMWARE_DEST}" ]]; then
        log_error "Extraction failed. firmware.bin was not created."
        rm -rf "${temp_dir}"
        return 1
    fi
    
    log_success "FaceTime HD firmware extracted successfully to ${FACETIMEHD_FIRMWARE_DEST}."
    
    rm -rf "${temp_dir}"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    extract_facetimehd
fi
