#!/usr/bin/env bash
# Phase 0: System and Hardware Detection

detect_hardware() {
    local compatible=1
    
    log_info "--- Hardware & System Detection ---"
    
    # OS & Distribution Check
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        if [[ "${ID:-}" == "ubuntu" || "${ID_LIKE:-}" == *"ubuntu"* ]]; then
            log_success "[✔] OS: ${PRETTY_NAME:-Ubuntu}"
        else
            log_warn "[!] OS: ${PRETTY_NAME:-Unknown} (Installer designed for Ubuntu/Debian family)"
        fi
    else
        log_error "[X] OS: /etc/os-release missing"
        compatible=0
    fi

    # Disk Space Check
    local free_mb
    free_mb="$(df -m / | awk 'NR==2 {print $4}')"
    if [[ "${free_mb:-0}" -ge 1000 ]]; then
        log_success "[✔] Available Disk Space: ${free_mb} MB"
    else
        log_error "[X] Insufficient Disk Space: ${free_mb:-0} MB (Required >= 1000 MB)"
        compatible=0
    fi
    
    # Kernel Check
    local kernel_ver
    kernel_ver=$(uname -r)
    log_success "[✔] Kernel: ${kernel_ver}"
    
    # Boot Mode (EFI)
    if [[ -d /sys/firmware/efi ]]; then
        log_success "[✔] Boot Mode: UEFI"
    else
        log_error "[X] Boot Mode: Legacy BIOS (EFI required)"
        compatible=0
    fi
    
    # Secure Boot Check
    local sb_enabled=0
    if command -v mokutil >/dev/null 2>&1; then
        if mokutil --sb-state 2>/dev/null | grep -qi "SecureBoot enabled"; then
            sb_enabled=1
        fi
    elif [[ -d /sys/firmware/efi/efivars ]]; then
        if grep -qs "SecureBoot" /sys/firmware/efi/efivars/SecureBoot-* 2>/dev/null; then
            sb_enabled=1
        fi
    fi

    if [[ "${sb_enabled}" -eq 1 ]]; then
        log_warn "[!] Secure Boot: ENABLED. Custom DKMS modules (facetimehd, snd_hda_macbookpro) will require MOK signing to load."
    else
        log_success "[✔] Secure Boot: Disabled or Not Enforced"
    fi
    
    # Hardware Model & Board ID (Multi-source verification)
    local sysfs_product="" sysfs_board="" dmi_product="" dmi_board=""
    if [[ -f /sys/class/dmi/id/product_name ]]; then
        sysfs_product="$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)"
    fi
    if [[ -f /sys/class/dmi/id/board_name ]]; then
        sysfs_board="$(cat /sys/class/dmi/id/board_name 2>/dev/null || true)"
    fi
    if command -v dmidecode >/dev/null 2>&1; then
        dmi_product="$(dmidecode -s system-product-name 2>/dev/null || true)"
        dmi_board="$(dmidecode -s baseboard-product-name 2>/dev/null || true)"
    fi

    local model="${sysfs_product:-$dmi_product}"
    local board="${sysfs_board:-$dmi_board}"

    # Target Board ID for MacBookPro14,3: Mac-551B86E5744E2388
    readonly TARGET_BOARD_ID="Mac-551B86E5744E2388"
    
    if [[ "${model}" == *"MacBookPro14,3"* || "${model}" == *"MacBookPro13,3"* ]]; then
        log_success "[✔] Model: ${model}"
    else
        log_warn "[!] Model: ${model:-Unknown} (Target: MacBookPro14,3 / MacBookPro13,3)"
    fi

    if [[ "${board}" == "${TARGET_BOARD_ID}" ]]; then
        log_success "    Board ID: ${board} (Exact MacBookPro14,3 match)"
    else
        log_success "    Board ID: ${board:-Unknown}"
    fi
    
    # WiFi Check (Vendor: 0x14E4, Device: 0x43BA / Subsystem: 0x0173)
    if lspci -nn | grep -qiE "14e4:43ba|BCM43602"; then
        log_success "[✔] WiFi: Broadcom BCM43602 (0x14E4:0x43BA) detected"
    else
        log_warn "[!] WiFi: BCM43602 not detected on PCI bus"
    fi
    
    # Camera Check
    if lspci -nn | grep -qiE "14e4:1570|1570"; then
        log_success "[✔] Camera: Broadcom 1570 (FaceTime HD) detected"
    else
        log_warn "[!] Camera: FaceTime HD 1570 not detected on PCI bus"
    fi
    
    # Audio Check
    if lspci | grep -qi "Audio"; then
        log_success "[✔] Audio: High Definition Audio Controller detected"
    else
        log_warn "[!] Audio: Controller not found"
    fi
    
    # Touch Bar Check
    if lsusb | grep -qi "Apple Inc. Touch Bar" || lsusb -v 2>/dev/null | grep -qi "Apple T1"; then
        log_success "[✔] Touch Bar: Apple T1 detected"
    else
        log_warn "[!] Touch Bar: Apple T1 not explicitly found on USB"
    fi
    
    log_info "-----------------------------------"
    
    if [[ "${compatible}" -eq 0 && "${DRY_RUN}" -eq 0 ]]; then
        log_error "Incompatible system requirements detected. Aborting installation."
        exit 1
    fi
    
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        echo ""
        log_info "--- Dry Run: Execution overview ---"
        log_info "1. Install dependencies: git, dkms, build-essential, linux-headers, etc."
        log_info "2. Verify SHA256 & install WiFi/Bluetooth/Camera firmware"
        log_info "3. Build and install DKMS drivers with commit pinning"
        log_info "4. Validate modinfo/modprobe loading for compiled drivers"
        log_info "5. Configure /etc/modules-load.d/ & systemd sleep settings"
        log_info "6. Update initramfs and generate installation report"
        echo ""
    fi
}

detect_hardware
