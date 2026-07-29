#!/usr/bin/env bash
# shellcheck shell=bash
# extractors/common.sh
# Common utilities for macOS firmware extraction.

source "${INSTALL_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/common/context.sh"
source "${COMMON_DIR}/logging.sh"

export MACOS_MOUNT_POINT="/mnt/macos_temp"

mount_macos() {
    log_info "Detecting macOS APFS partition..."
    
    # We look for an APFS partition. Often Apple_APFS or type 'apfs'
    local apfs_partition
    apfs_partition="$(lsblk -r -n -o NAME,FSTYPE | grep -i apfs | head -n1 | awk '{print $1}')"

    if [[ -z "${apfs_partition}" ]]; then
        log_error "No macOS APFS partition found."
        return 1
    fi

    local dev_path="/dev/${apfs_partition}"
    log_info "Found APFS partition at ${dev_path}."

    mkdir -p "${MACOS_MOUNT_POINT}"
    
    # Attempt to mount
    if ! mountpoint -q "${MACOS_MOUNT_POINT}"; then
        log_info "Mounting ${dev_path} read-only..."
        # Note: Linux needs apfs-fuse or kernel support for APFS.
        # Fallback to standard mount, which might require specific drivers.
        if ! run_cmd mount -t apfs -o ro "${dev_path}" "${MACOS_MOUNT_POINT}"; then
            # Try apfs-fuse if available
            if command -v apfs-fuse >/dev/null 2>&1; then
                run_cmd apfs-fuse "${dev_path}" "${MACOS_MOUNT_POINT}"
            else
                log_error "Failed to mount APFS."
                log_error "Please run: sudo apt-get install apfs-dkms"
                log_error "Then try again."
                return 1
            fi
        fi
    fi

    return 0
}

unmount_macos() {
    if mountpoint -q "${MACOS_MOUNT_POINT}"; then
        log_info "Unmounting macOS partition..."
        run_cmd umount "${MACOS_MOUNT_POINT}"
        rmdir "${MACOS_MOUNT_POINT}" || true
    fi
}
