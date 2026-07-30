#!/usr/bin/env bash
# scripts/08_power.sh
# Power & Thermal Management module for MacBook Pro A1707 (TLP, mbpfan, T1 USB sleep reset)

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/common/logging.sh"
source "${SCRIPT_DIR}/common/backup.sh"
source "${SCRIPT_DIR}/common/state.sh"
source "${SCRIPT_DIR}/common/system.sh"

log_info "Starting Power & Thermal Management deployment phase..."

# 1. Install TLP for power optimization (Intel Skylake/Kaby Lake)
log_info "Ensuring TLP power management packages are installed..."
if ! dpkg-query -W -f='${Status}\n' tlp 2>/dev/null | grep -q "installed"; then
    tlp_deb="$(find "${ASSETS_DIR}/packages" -maxdepth 1 -name "tlp_*.deb" -print -quit 2>/dev/null || true)"
    if [[ -n "${tlp_deb}" && -f "${tlp_deb}" ]]; then
        run_cmd dpkg -i "${ASSETS_DIR}/packages/tlp"*.deb 2>/dev/null || run_cmd apt-get install -y "${tlp_deb}" || true
    else
        run_cmd apt-get install -y tlp tlp-rdw || log_warn "Could not install tlp / tlp-rdw packages."
    fi
fi

if command -v tlp >/dev/null 2>&1; then
    log_info "Enabling and starting TLP service..."
    run_cmd systemctl enable tlp 2>/dev/null || true
    run_cmd systemctl start tlp 2>/dev/null || true
    log_success "TLP power management configured."
fi

# 2. Install mbpfan for optimal fan control
log_info "Ensuring mbpfan fan controller is installed..."
if ! dpkg-query -W -f='${Status}\n' mbpfan 2>/dev/null | grep -q "installed"; then
    mbpfan_deb="$(find "${ASSETS_DIR}/packages" -maxdepth 1 -name "mbpfan_*.deb" -print -quit 2>/dev/null || true)"
    if [[ -n "${mbpfan_deb}" && -f "${mbpfan_deb}" ]]; then
        run_cmd dpkg -i "${mbpfan_deb}" 2>/dev/null || run_cmd apt-get install -y "${mbpfan_deb}" || true
    else
        run_cmd apt-get install -y mbpfan || log_warn "Could not install mbpfan package."
    fi
fi

if command -v mbpfan >/dev/null 2>&1; then
    log_info "Enabling and starting mbpfan service..."
    run_cmd systemctl enable mbpfan 2>/dev/null || true
    run_cmd systemctl restart mbpfan 2>/dev/null || true
    log_success "mbpfan fan controller configured."
fi

# 3. Create T1 USB reset sleep hook for Touch Bar recovery on resume
log_info "Deploying Touch Bar T1 USB sleep reset hook..."
SLEEP_HOOK_DIR="/lib/systemd/system-sleep"
SLEEP_HOOK_FILE="${SLEEP_HOOK_DIR}/t1-touchbar-reset"

if [[ -d "${SLEEP_HOOK_DIR}" ]]; then
    cat <<'EOF' > /tmp/t1-touchbar-reset.tmp
#!/bin/sh
# /lib/systemd/system-sleep/t1-touchbar-reset
# Re-initializes Apple T1 USB controller after resume to restore Touch Bar

if [ "$1" = "post" ]; then
    if [ -d "/sys/bus/usb/drivers/usb/1-3" ]; then
        echo '1-3' > /sys/bus/usb/drivers/usb/unbind 2>/dev/null || true
        echo '1-3' > /sys/bus/usb/drivers/usb/bind 2>/dev/null || true
    fi
fi
EOF

    run_cmd chmod +x /tmp/t1-touchbar-reset.tmp
    run_cmd mv /tmp/t1-touchbar-reset.tmp "${SLEEP_HOOK_FILE}"
    record_install "file" "${SLEEP_HOOK_FILE}" ""
    log_success "Touch Bar T1 USB sleep reset hook deployed to ${SLEEP_HOOK_FILE}."
fi

# 4. Restore custom user GNOME settings & keyboard shortcuts if enabled
if [[ "${APPLY_GNOME_SETTINGS:-1}" -eq 1 ]]; then
    GNOME_SETTINGS_FILE="${ASSETS_DIR}/user_gnome_settings.dconf"
    if [[ -f "${GNOME_SETTINGS_FILE}" ]]; then
        log_info "Applying custom GNOME keybindings & user settings..."
        TARGET_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "${USER}")}"
        TARGET_UID="$(id -u "${TARGET_USER}" 2>/dev/null || echo "")"
        
        if [[ -n "${TARGET_USER}" && "${TARGET_USER}" != "root" && -n "${TARGET_UID}" ]]; then
            DBUS_BUS="/run/user/${TARGET_UID}/bus"
            # shellcheck disable=SC2024
            if [[ -S "${DBUS_BUS}" ]]; then
                sudo -u "${TARGET_USER}" DBUS_SESSION_BUS_ADDRESS="unix:path=${DBUS_BUS}" dconf load /org/gnome/ < "${GNOME_SETTINGS_FILE}" 2>/dev/null || true
            else
                sudo -u "${TARGET_USER}" dconf load /org/gnome/ < "${GNOME_SETTINGS_FILE}" 2>/dev/null || true
            fi
            log_success "Custom GNOME keybindings & user settings restored for user '${TARGET_USER}'."
        fi
    fi
else
    log_info "Skipping custom GNOME user settings restoration (--without-gnome-settings specified)."
fi

log_success "Power & Thermal Management phase completed."
return 0
