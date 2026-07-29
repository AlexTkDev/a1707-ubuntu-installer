#!/usr/bin/env bash
# scripts/06_cleanup.sh
# Removes temporary artifacts.

log_info "Running cleanup..."

# Remove temporary files in firmware dir if any
run_cmd find /lib/firmware/brcm/ -name "*.tmp.*" -type f -delete 2>/dev/null || true

log_success "Cleanup complete."
