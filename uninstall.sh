#!/usr/bin/env bash
# MacBookPro14,3 Safe Uninstaller

set -Eeuo pipefail
IFS=$'\n\t'

readonly STATE_DIR="/var/lib/macbook-installer"
readonly MANIFEST_FILE="${STATE_DIR}/manifest.txt"
readonly BACKUP_DIR="${STATE_DIR}/backups"

if [[ $EUID -ne 0 ]]; then
    echo "Error: This uninstaller must be run as root." >&2
    exit 1
fi

echo "=== MacBookPro14,3 Uninstaller ==="

echo "Removing DKMS modules..."
if command -v dkms >/dev/null 2>&1; then
    for mod in facetimehd snd_hda_macbookpro applespi; do
        if dkms status 2>/dev/null | grep -q "${mod}"; then
            echo "Removing DKMS module ${mod}..."
            dkms remove -m "${mod}" --all 2>/dev/null || true
        fi
    done
fi

echo "Restoring original configuration backups..."
if [[ -d "${BACKUP_DIR}" ]]; then
    find "${BACKUP_DIR}" -type f | while read -r backup_file; do
        rel_path="${backup_file#"$BACKUP_DIR"}"
        target_path="${rel_path%.bak}"
        if [[ -n "${target_path}" ]]; then
            echo "Restoring ${target_path}..."
            mkdir -p "$(dirname "${target_path}")"
            cp -af "${backup_file}" "${target_path}"
        fi
    done
fi

echo "Removing installer-created files from manifest..."
if [[ -f "${MANIFEST_FILE}" ]]; then
    while read -r file; do
        [[ -z "${file}" ]] && continue
        if [[ -f "${file}" || -L "${file}" ]]; then
            echo "Removing file: ${file}"
            rm -f "${file}"
        elif [[ -d "${file}" ]]; then
            echo "Removing directory: ${file}"
            rm -rf "${file}"
        fi
    done < "${MANIFEST_FILE}"
else
    echo "Manifest file not found (${MANIFEST_FILE}). Manual cleanup may be required."
fi

echo "Updating initramfs..."
update-initramfs -u -k all

echo "Cleaning up state data..."
rm -rf "${STATE_DIR}"

echo "Uninstallation complete. Please reboot your system."
