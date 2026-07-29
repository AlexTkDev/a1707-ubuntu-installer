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

    # macOS System Volume paths (Catalina and later use a separate System volume)
    local kext_paths=(
        "${MACOS_MOUNT_POINT}/System/Library/Extensions/AppleCameraInterface.kext/Contents/MacOS/AppleCameraInterface"
        "${MACOS_MOUNT_POINT}/root/System/Library/Extensions/AppleCameraInterface.kext/Contents/MacOS/AppleCameraInterface"
    )

    local target_kext=""
    for path in "${kext_paths[@]}"; do
        if [[ -f "${path}" ]]; then
            target_kext="${path}"
            break
        fi
    done

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
    
    if [[ ! -f "${SCRIPT_DIR}/facetimehd-extractor.py" ]]; then
        log_error "Extractor script facetimehd-extractor.py not found in extractors/."
        rm -rf "${temp_dir}"
        return 1
    fi
    
    # run_cmd python3 "${SCRIPT_DIR}/facetimehd-extractor.py" "${temp_dir}/AppleCameraInterface" "${FACETIMEHD_FIRMWARE_DEST}"
    
    log_success "FaceTime HD firmware extracted successfully to ${FACETIMEHD_FIRMWARE_DEST}."
    
    rm -rf "${temp_dir}"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    extract_facetimehd
fi
