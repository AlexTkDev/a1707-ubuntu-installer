#!/usr/bin/env bash
# scripts/01_prerequisites.sh
# Verifies system requirements before installation.

log_info "Verifying prerequisites..."

if [[ $EUID -ne 0 ]]; then
    log_fatal "Installer must be run as root."
fi

# Ensure basic directories
run_cmd mkdir -p "${STATE_DIR}" "${BACKUP_DIR}"

# Check for apt and dpkg
if ! command -v apt-get >/dev/null 2>&1; then
    log_fatal "apt-get is required but not found."
fi

log_success "Prerequisites met."
