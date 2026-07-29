#!/usr/bin/env bash
# common/context.sh
# Centralized execution context.

if [[ -z "${INSTALL_ROOT:-}" ]]; then
    export INSTALL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

export ASSETS_DIR="${INSTALL_ROOT}/assets"
export PLATFORM_DIR="${INSTALL_ROOT}/platforms"
export SCRIPTS_DIR="${INSTALL_ROOT}/scripts"
export CHECKS_DIR="${INSTALL_ROOT}/checks"
export REPAIRS_DIR="${INSTALL_ROOT}/repairs"
export MIGRATIONS_DIR="${INSTALL_ROOT}/migrations"
export COMMON_DIR="${INSTALL_ROOT}/common"

export STATE_DIR="/var/lib/macbookpro14-installer"
export STATE_FILE="${STATE_DIR}/state.env"
export BACKUP_MANIFEST="${STATE_DIR}/backups.manifest"
export INSTALLER_MANIFEST="${STATE_DIR}/installer.manifest"
export BACKUP_DIR="/var/backups/macbookpro14-linux-support"
export LOG_FILE="/var/log/macbookpro14-installer.log"

export INSTALLER_VERSION="2.0.0"
