#!/usr/bin/env bash

# MacBookPro14,3 Ubuntu LTS Installer
# Entry point

set -Eeuo pipefail
IFS=$'\n\t'

# Determine script directory reliably
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# Source utilities
# shellcheck source=scripts/00_utils.sh
source "${SCRIPT_DIR}/scripts/00_utils.sh"

run_phase() {
    local phase_name="$1"
    local phase_script="${SCRIPT_DIR}/scripts/${phase_name}.sh"
    
    if [[ ! -f "${phase_script}" ]]; then
        log_error "Phase script not found: ${phase_script}"
        exit 1
    fi
    
    log_info "----------------------------------------"
    log_info "Executing phase: ${phase_name}"
    log_info "----------------------------------------"
    
    # shellcheck source=/dev/null
    source "${phase_script}"
    
    log_success "Phase ${phase_name} completed successfully."
}

main() {
    parse_args "$@"
    setup_logging
    
    log_info "Starting MacBookPro14,3 Production Installer"
    
    run_phase "00_detect"
    
    if [[ "${DRY_RUN}" -eq 1 ]]; then
        log_success "Dry run complete. No changes were made to the system."
        exit 0
    fi
    
    run_phase "02_deps"
    run_phase "03_firmware"
    run_phase "04_dkms"
    run_phase "05_system"
    
    INSTALL_SUCCESSFUL=1
    log_success "Installation completed successfully! Summary report is located at ${REPORT_FILE}. Please reboot your system."
}

main "$@"
