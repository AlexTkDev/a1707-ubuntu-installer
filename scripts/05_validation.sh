#!/usr/bin/env bash
# scripts/05_validation.sh
# Final phase validation before cleanup.

log_info "Preparing for final validation..."
# Actual doctor validation is run by the orchestrator at the very end to set exit status.
# This phase can be used to compile module dependencies or do pre-flight checks.

run_cmd depmod -a
log_success "Kernel module dependencies updated."
