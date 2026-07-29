#!/usr/bin/env bash
# scripts/04_touchbar.sh
# Platform-driven, offline-first Touch Bar deployment module

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/common/logging.sh"
source "${SCRIPT_DIR}/common/backup.sh"
source "${SCRIPT_DIR}/common/state.sh"
source "${SCRIPT_DIR}/common/system.sh"
source "${SCRIPT_DIR}/common/package.sh"
source "${SCRIPT_DIR}/checks/05_touchbar.sh"

init_logging_session

if [[ -z "${PLATFORM_NAME:-}" ]]; then
    source "${SCRIPT_DIR}/platforms/macbookpro14-3.sh"
fi

log_info "Starting Touch Bar deployment module for ${PLATFORM_NAME}..."

if [[ "${TOUCHBAR_SUPPORTED:-0}" -eq 0 ]]; then
    log_info "Touch Bar is not supported on this platform. Skipping."
    close_logging_session
fi

# 1. Idempotency Check
if run_check; then
    if [[ "${RESULT_MESSAGE}" == *"operational"* ]]; then
        log_success "Touch Bar package is already installed and verified. Skipping."
        close_logging_session
    fi
fi

log_info "Proceeding with Touch Bar package installation..."

if ! install_dkms_package "${TOUCHBAR_PKG_NAME}" "${TOUCHBAR_PKG_FILE}"; then
    log_fatal "Touch Bar deployment failed during package installation."
fi

# 2. Final Validation
log_info "Running post-installation validation..."
if run_check; then
    log_success "Touch Bar deployment completed successfully."
else
    if [[ "${RESULT_MESSAGE}" == *"module inactive"* ]]; then
        log_warn "Installation succeeded, but kernel module is not loaded."
        log_warn "Please reload manually or reboot."
    else
        log_fatal "Validation failed post-installation: ${RESULT_MESSAGE}"
    fi
fi

close_logging_session
