#!/usr/bin/env bash
# collect.sh
# Gathers diagnostic information for bug reports and support requests.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common/context.sh"

if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root to collect full system diagnostics."
    exit 1
fi

ARCHIVE_NAME="support-$(date +%Y-%m-%d).tar.gz"
TEMP_DIR="$(mktemp -d)"

echo "Collecting diagnostics..."

# System info
uname -a > "${TEMP_DIR}/uname.txt"
lsmod > "${TEMP_DIR}/lsmod.txt"
lspci -nn > "${TEMP_DIR}/lspci.txt"
lsusb > "${TEMP_DIR}/lsusb.txt" 2>/dev/null || true

# Logs
dmesg > "${TEMP_DIR}/dmesg.txt" 2>/dev/null || true
journalctl -k -n 1000 --no-pager > "${TEMP_DIR}/journalctl-k.txt" 2>/dev/null || true

# Packages and Network
dkms status > "${TEMP_DIR}/dkms-status.txt" 2>/dev/null || true
iw list > "${TEMP_DIR}/iw-list.txt" 2>/dev/null || true
iw reg get > "${TEMP_DIR}/iw-reg-get.txt" 2>/dev/null || true
nmcli > "${TEMP_DIR}/nmcli.txt" 2>/dev/null || true
rfkill > "${TEMP_DIR}/rfkill.txt" 2>/dev/null || true

# Installer State
if [[ -d "${STATE_DIR}" ]]; then
    cp -r "${STATE_DIR}" "${TEMP_DIR}/installer-state"
fi

# Version info
echo "INSTALLER_VERSION=${INSTALLER_VERSION}" > "${TEMP_DIR}/installer-version.txt"
if [[ -f /sys/class/dmi/id/board_name ]]; then
    cp /sys/class/dmi/id/board_name "${TEMP_DIR}/board_name.txt"
fi

# Archive
tar -czf "${ARCHIVE_NAME}" -C "${TEMP_DIR}" .

rm -rf "${TEMP_DIR}"

echo "Diagnostics collected successfully."
echo "Please attach this file to your GitHub Issue: ${ARCHIVE_NAME}"
