#!/usr/bin/env bash
# common/package.sh
# Shared logic for validating and installing DKMS deb packages.
source "${INSTALL_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/common/system.sh"

verify_checksum() {
    local target_file="$1"
    local filename
    filename="$(basename "${target_file}")"
    local checksums_file="${ASSETS_DIR}/packages/SHA256SUMS"
    
    if [[ ! -f "${checksums_file}" ]]; then
        log_error "Checksums file missing at ${checksums_file}"
        return 1
    fi
    
    local expected_hash
    expected_hash="$(grep "[[:space:]]${filename}$" "${checksums_file}" | awk '{print $1}')"
    
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

install_dkms_package() {
    local pkg_name="$1"
    local pkg_file="$2"
    local deb_path="${ASSETS_DIR}/packages/${pkg_file}"
    
    # 1. File and Checksum Verification
    if [[ ! -f "${deb_path}" ]]; then
        log_error "Package not found: ${deb_path}"
        return 1
    fi

    if ! verify_checksum "${deb_path}"; then
        log_error "Checksum verification failed for ${deb_path}"
        return 1
    fi

    # 2. Integrity Verification via dpkg-deb
    log_info "Verifying package integrity..."
    if ! run_cmd dpkg-deb --info "${deb_path}" >/dev/null; then
        log_error "Package integrity check failed for ${deb_path}"
        return 1
    fi

    # 3. Kernel compatibility validation
    validate_kernel_compatibility "${pkg_name}"

    # 4. Installation
    log_info "Installing ${pkg_name}..."
    if run_cmd apt-get install -y "${deb_path}"; then
        log_success "Package ${pkg_name} installed via apt."
    else
        log_warn "apt-get install failed, attempting fallback with dpkg..."
        if ! run_cmd dpkg -i "${deb_path}"; then
            log_error "Fallback installation via dpkg failed. Dependencies might be missing."
            return 1
        fi
    fi

    record_install "package" "${pkg_name}" ""
    
    # 5. Check DKMS kernel mismatch
    local current_kernel
    current_kernel="$(uname -r)"
    if dkms status "${pkg_name}" | grep -q "installed" && ! dkms status "${pkg_name}" | grep -q "${current_kernel}"; then
        log_warn "Installed DKMS build does not match current kernel (${current_kernel})."
        log_warn "Recommendation: run 'sudo dkms autoinstall' or reboot."
    fi
    return 0
}
