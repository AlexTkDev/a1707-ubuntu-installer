#!/usr/bin/env bash
# common/system.sh
# System validation and helper utilities.

# Compare two version strings. 
# Returns 0 if V1 >= V2, otherwise 1.
# Usage: version_ge "6.12.0" "6.8"
version_ge() {
    local v1="$1"
    local v2="$2"
    # sort -V sorts versions. If v2 is the first line, then v1 is greater or equal.
    if [[ "$(printf "%s\n%s" "${v1}" "${v2}" | sort -V | head -n1)" == "${v2}" ]]; then
        return 0
    fi
    return 1
}

# Compare two version strings.
# Returns 0 if V1 <= V2, otherwise 1.
version_le() {
    local v1="$1"
    local v2="$2"
    if [[ "$(printf "%s\n%s" "${v1}" "${v2}" | sort -V | head -n1)" == "${v1}" ]]; then
        return 0
    fi
    return 1
}

validate_kernel_compatibility() {
    local pkg_name="$1"
    local current_kernel
    current_kernel="$(uname -r | grep -Eo '^[0-9]+\.[0-9]+')"
    
    if [[ -n "${SUPPORTED_KERNEL_MIN:-}" ]]; then
        if ! version_ge "${current_kernel}" "${SUPPORTED_KERNEL_MIN}"; then
            log_warn "Current kernel: $(uname -r)"
            log_warn "This package (${pkg_name}) has only been validated on kernels >= ${SUPPORTED_KERNEL_MIN}."
            log_warn "Installation will continue, but compatibility is not guaranteed."
        fi
    fi

    if [[ -n "${SUPPORTED_KERNEL_MAX:-}" ]]; then
        if ! version_le "${current_kernel}" "${SUPPORTED_KERNEL_MAX}"; then
            log_warn "Current kernel: $(uname -r)"
            log_warn "This package (${pkg_name}) has only been validated on kernels <= ${SUPPORTED_KERNEL_MAX}."
            log_warn "Installation will continue, but compatibility is not guaranteed."
        fi
    fi
}
