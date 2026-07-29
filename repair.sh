#!/usr/bin/env bash
# repair.sh - Plugin-based Repair Orchestrator

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common/context.sh"
source "${COMMON_DIR}/logging.sh"
source "${COMMON_DIR}/backup.sh"

# State
TARGET_REPAIRS=()
REPAIR_ALL=0
declare -i APPLIED_COUNT=0
declare -i SKIPPED_COUNT=0
declare -i FAILED_COUNT=0
declare -i HEALTHY_COUNT=0

# Arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --all) REPAIR_ALL=1; shift ;;
        --dry-run) DRY_RUN_ENABLED=1; LOG_INFO="[DRY-RUN] "; shift ;;
        --repair-id) TARGET_REPAIRS+=("$2"); shift 2 ;;
        --wifi) TARGET_REPAIRS+=("wifi_symlink" "wifi_firmware"); shift ;;
        --audio) TARGET_REPAIRS+=("audio"); shift ;;
        --touchbar) TARGET_REPAIRS+=("touchbar"); shift ;;
        *)
            log_error "Unknown argument: $1"
            echo "Usage: $0 [--all | --dry-run | --repair-id ID | --wifi | --audio | --touchbar]"
            exit 1
            ;;
    esac
done

if [[ ${REPAIR_ALL} -eq 0 && ${#TARGET_REPAIRS[@]} -eq 0 ]]; then
    log_error "No repair targets specified. Use --all, --repair-id, or a specific module (e.g., --wifi)."
    exit 1
fi

init_logging_session

log_info "Running Doctor to determine system health..."
# Get failed repair IDs by reading doctor's JSON output line by line.
# Assuming basic manual JSON generation in doctor.sh.
FAILED_IDS=()
# Simple regex extraction to avoid jq dependency
while read -r line; do
    if [[ "${line}" =~ \"repair_id\":[[:space:]]*\"([^\"]+)\" ]]; then
        repair_id="${BASH_REMATCH[1]}"
        if [[ -n "${repair_id}" ]]; then
            FAILED_IDS+=("${repair_id}")
        fi
    fi
done < <("${SCRIPT_DIR}/doctor.sh" --json | grep -B 1 '"status": "FAIL"' | grep '"repair_id"' || true)

if [[ ${#FAILED_IDS[@]} -eq 0 ]]; then
    log_success "System is completely healthy. No repairs needed."
    HEALTHY_COUNT=1
    close_logging_session
fi

is_target_repair() {
    local rid="$1"
    if [[ ${REPAIR_ALL} -eq 1 ]]; then
        return 0
    fi
    for t in "${TARGET_REPAIRS[@]}"; do
        if [[ "${t}" == "${rid}" ]]; then
            return 0
        fi
    done
    return 1
}

# Ensure uniqueness of failed IDs
declare -A UNIQUE_FAILS
for fid in "${FAILED_IDS[@]}"; do
    UNIQUE_FAILS["$fid"]=1
done

for rid in "${!UNIQUE_FAILS[@]}"; do
    if ! is_target_repair "${rid}"; then
        ((SKIPPED_COUNT++))
        log_warn "Skipping failed repair ${rid} (not targeted)."
        continue
    fi

    repair_module="${SCRIPT_DIR}/repairs/${rid}.sh"
    if [[ ! -f "${repair_module}" ]]; then
        log_error "No repair module found for ID: ${rid}"
        ((FAILED_COUNT++))
        continue
    fi

    # Reset globals
    REPAIR_ID=""
    REPAIR_DESCRIPTION=""
    
    # Source the module
    # shellcheck source=/dev/null
    source "${repair_module}"
    
    log_info "----------------------------------------"
    log_info "Executing Repair: ${REPAIR_ID} - ${REPAIR_DESCRIPTION}"
    
    if [[ "${DRY_RUN_ENABLED}" -eq 1 ]]; then
        log_info "[DRY-RUN] Would execute repair() for ${REPAIR_ID}"
        ((APPLIED_COUNT++))
        continue
    fi
    
    # Transaction Start
    local repair_success=0
    
    log_debug "Running repair implementation..."
    if repair; then
        log_debug "Running repair validation..."
        if repair_validate; then
            log_success "Repair ${REPAIR_ID} completed and validated successfully."
            repair_success=1
            ((APPLIED_COUNT++))
        else
            log_error "Validation failed for ${REPAIR_ID} after repair applied."
        fi
    else
        log_error "Repair implementation failed for ${REPAIR_ID}."
    fi
    
    if [[ ${repair_success} -eq 0 ]]; then
        log_warn "Rolling back changes for ${REPAIR_ID}..."
        # We rely on safe_backup and the module restoring its own state, 
        # or we could call a rollback function if defined.
        if type repair_rollback >/dev/null 2>&1; then
            repair_rollback
        else
            log_warn "No custom rollback defined for ${REPAIR_ID}."
        fi
        ((FAILED_COUNT++))
    fi
done

log_info "----------------------------------------"
log_info "Repair Summary:"
log_info "Applied repairs : ${APPLIED_COUNT}"
log_info "Skipped repairs : ${SKIPPED_COUNT}"
log_info "Failed repairs  : ${FAILED_COUNT}"

if [[ ${FAILED_COUNT} -gt 0 ]]; then
    exit 2
elif [[ ${SKIPPED_COUNT} -gt 0 ]]; then
    exit 1
else
    exit 0
fi
