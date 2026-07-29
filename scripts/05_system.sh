#!/usr/bin/env bash
# Phase 5: System Configuration with module verification and report generation

configure_wifi() {
    local conf_dest="/etc/modprobe.d/brcmfmac.conf"
    local conf_src="${SCRIPT_DIR}/config/brcmfmac.conf"
    
    if [[ -f "${conf_src}" ]]; then
        safe_backup "${conf_dest}"
        cp -af "${conf_src}" "${conf_dest}"
        register_installed_file "${conf_dest}"
        _log_to_file "Applied WiFi configuration for brcmfmac"
    fi
}

configure_modules() {
    local conf_dest="/etc/modules-load.d/macbook.conf"
    local conf_src="${SCRIPT_DIR}/config/modules-load.conf"
    
    if [[ -f "${conf_src}" ]]; then
        safe_backup "${conf_dest}"
        
        local valid_modules=()
        while read -r mod; do
            [[ -z "${mod}" || "${mod}" =~ ^# ]] && continue
            if modinfo "${mod}" >/dev/null 2>&1; then
                valid_modules+=("${mod}")
            else
                log_warn "Module '${mod}' not available in kernel $(uname -r); skipping autoload."
            fi
        done < "${conf_src}"

        printf "%s\n" "${valid_modules[@]}" > "${conf_dest}"
        register_installed_file "${conf_dest}"
        _log_to_file "Applied modules-load configuration with validated kernel modules."
    fi
}

configure_suspend() {
    local systemd_sleep_conf="/etc/systemd/sleep.conf.d/macbook.conf"
    mkdir -p "/etc/systemd/sleep.conf.d"
    safe_backup "${systemd_sleep_conf}"

    cat <<EOF > "${systemd_sleep_conf}"
[Sleep]
AllowHibernation=no
AllowSuspendThenHibernate=no
EOF
    register_installed_file "${systemd_sleep_conf}"
    _log_to_file "Applied systemd sleep configuration (disabled hibernation)"
}

update_initramfs_image() {
    update-initramfs -u -k all
}

generate_final_report() {
    cat > "${REPORT_FILE}" <<EOF
=== Installation Summary Report ===
Date: $(date -R)
Kernel: $(uname -r)
OS: $(# shellcheck disable=SC1091
    . /etc/os-release 2>/dev/null && echo "${PRETTY_NAME:-Unknown}")
Model: $(cat /sys/class/dmi/id/product_name 2>/dev/null || echo "Unknown")

DKMS Status:
$(dkms status 2>/dev/null || echo "N/A")

Installed Files (Manifest):
$(cat "${MANIFEST_FILE}" 2>/dev/null || echo "None")
EOF
    log_success "Installation summary report saved to ${REPORT_FILE}"
}

run_cmd "Configuring WiFi workarounds" configure_wifi
run_cmd "Configuring auto-loading modules" configure_modules
run_cmd "Configuring power management (Suspend/Wake)" configure_suspend
run_cmd "Updating initramfs" update_initramfs_image
run_cmd "Generating installation report" generate_final_report
