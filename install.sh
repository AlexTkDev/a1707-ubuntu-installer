#!/usr/bin/env bash
# install.sh
# Lightweight Orchestrator for MacBook Pro Installer

set -Eeuo pipefail
IFS=$'\n\t'

INSTALL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${INSTALL_ROOT}/common/context.sh"
source "${COMMON_DIR}/logging.sh"
source "${COMMON_DIR}/state.sh"
source "${COMMON_DIR}/backup.sh"

# CLI Parsing
EXEC_PHASES=()
DRY_RUN_ENABLED=0
SKIP_PHASES=()
START_PHASE=""
LIST_PHASES=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN_ENABLED=1; LOG_INFO="[DRY-RUN] "; shift ;;
        --verbose|-v) LOG_VERBOSE=1; shift ;;
        --debug) LOG_DEBUG=1; shift ;;
        --quiet|-q) LOG_QUIET=1; shift ;;
        --phase) EXEC_PHASES+=("$2"); shift 2 ;;
        --from-phase) START_PHASE="$2"; shift 2 ;;
        --skip) SKIP_PHASES+=("$2"); shift 2 ;;
        --list-phases) LIST_PHASES=1; shift ;;
        *)
            log_error "Unknown argument: $1"
            echo "Usage: $0 [--dry-run | --verbose | --debug | --quiet | --phase NAME | --from-phase NAME | --skip NAME | --list-phases]"
            exit 1
            ;;
    esac
done

# Phase Registry
PHASES=(
    "01_prerequisites"
    "02_wifi"
    "03_audio"
    "04_touchbar"
    "07_camera"
    "05_validation"
    "06_cleanup"
)

if [[ ${LIST_PHASES} -eq 1 ]]; then
    echo "Available phases:"
    for p in "${PHASES[@]}"; do echo "  - ${p#*_}"; done
    exit 0
fi

init_logging_session

# Detect Platform
detect_platform() {
    local current_board=""
    if [[ -f /sys/class/dmi/id/board_name ]]; then
        current_board="$(cat /sys/class/dmi/id/board_name)"
    fi
    for plat_file in "${PLATFORM_DIR}/"*.sh; do
        [[ ! -f "${plat_file}" ]] && continue
        local plat_board
        plat_board="$(bash -c "source \"${plat_file}\" && echo \"\${BOARD_ID}\"")"
        if [[ "${plat_board}" == "${current_board}" || -z "${current_board}" ]]; then
            source "${plat_file}"
            return 0
        fi
    done
    source "${PLATFORM_DIR}/macbookpro14-3.sh"
}
detect_platform

log_info "Detected Platform: ${PLATFORM_NAME} (v${PLATFORM_VERSION})"

# Init State
if [[ "${DRY_RUN_ENABLED}" -eq 0 ]]; then
    mkdir -p "${STATE_DIR}"
    if [[ ! -f "${STATE_FILE}" ]]; then
        cat <<EOF > "${STATE_FILE}"
INSTALLER_VERSION="${INSTALLER_VERSION}"
PLATFORM_ID="${PLATFORM_ID}"
PLATFORM_VERSION="${PLATFORM_VERSION}"
INSTALL_DATE="$(date -Iseconds)"
INSTALL_STATUS="IN_PROGRESS"
LAST_PHASE="init"
LAST_SUCCESSFUL_PHASE="none"
EOF
    else
        # Reload state
        # shellcheck source=/dev/null
        source "${STATE_FILE}"
    fi
fi

update_state() {
    local key="$1"
    local val="$2"
    if [[ "${DRY_RUN_ENABLED}" -eq 0 && -f "${STATE_FILE}" ]]; then
        if grep -q "^${key}=" "${STATE_FILE}"; then
            sed -i "s|^${key}=.*|${key}=\"${val}\"|" "${STATE_FILE}"
        else
            echo "${key}=\"${val}\"" >> "${STATE_FILE}"
        fi
    fi
}

# Migrations Workflow
run_migrations() {
    if [[ ! -d "${MIGRATIONS_DIR}" ]]; then return 0; fi
    # Simplified migrations logic
    for mig in "${MIGRATIONS_DIR}/"*.sh; do
        [[ ! -f "${mig}" ]] && continue
        local mig_name
        mig_name="$(basename "${mig}")"
        if grep -q "MIGRATION_${mig_name}=DONE" "${STATE_FILE}" 2>/dev/null; then
            continue
        fi
        log_info "Executing migration: ${mig_name}"
        if [[ "${DRY_RUN_ENABLED}" -eq 0 ]]; then
            # shellcheck source=/dev/null
            source "${mig}"
            echo "MIGRATION_${mig_name}=DONE" >> "${STATE_FILE}"
        fi
    done
}
run_migrations

# Phase Execution
execute_phase() {
    local phase_file="$1"
    local phase_name
    phase_name="$(basename "${phase_file}" .sh)"
    local short_name="${phase_name#*_}"

    # Filters
    if [[ ${#EXEC_PHASES[@]} -gt 0 ]]; then
        local run=0
        for p in "${EXEC_PHASES[@]}"; do
            if [[ "${p}" == "${short_name}" || "${p}" == "${phase_name}" ]]; then run=1; break; fi
        done
        [[ ${run} -eq 0 ]] && return 0
    fi
    for p in "${SKIP_PHASES[@]}"; do
        if [[ "${p}" == "${short_name}" || "${p}" == "${phase_name}" ]]; then
            log_warn "Skipping phase: ${short_name} (--skip)"
            return 0
        fi
    done

    log_info "========================================"
    log_info "Phase: ${short_name}"
    log_info "========================================"

    update_state "LAST_PHASE" "${short_name}"
    
    if [[ -f "${SCRIPTS_DIR}/${phase_file}" ]]; then
        # Subshell execution to protect orchestrator state, or source if we want them to share env.
        # Modules should share context.
        # shellcheck source=/dev/null
        source "${SCRIPTS_DIR}/${phase_file}" || {
            local ec=$?
            update_state "INSTALL_STATUS" "FAILED"
            log_fatal "Phase ${short_name} failed with exit code ${ec}. Run repair.sh to troubleshoot."
        }
    else
        log_warn "Phase script ${phase_file} not found."
    fi

    update_state "LAST_SUCCESSFUL_PHASE" "${short_name}"
}

# Apply --from-phase logic
started=0
if [[ -z "${START_PHASE}" ]]; then started=1; fi

for phase in "${PHASES[@]}"; do
    short="${phase#*_}"
    if [[ ${started} -eq 0 ]]; then
        if [[ "${START_PHASE}" == "${short}" || "${START_PHASE}" == "${phase}" ]]; then
            started=1
        else
            continue
        fi
    fi
    execute_phase "${phase}.sh"
done

update_state "INSTALL_STATUS" "COMPLETED"

# Final Validation (05_validation phase essentially runs doctor)
# We can explicitly run doctor here as per requirement
log_info "Executing final validation via doctor.sh..."
if [[ "${DRY_RUN_ENABLED}" -eq 0 ]]; then
    set +e
    "${INSTALL_ROOT}/doctor.sh"
    doc_ret=$?
    set -e
    
    if [[ ${doc_ret} -eq 2 ]]; then
        update_state "INSTALL_STATUS" "FAILED"
        log_error "Doctor reported critical failures."
        close_logging_session
    elif [[ ${doc_ret} -eq 1 ]]; then
        update_state "INSTALL_STATUS" "COMPLETED_WITH_WARNINGS"
        log_warn "Doctor reported warnings."
        # Not exiting here so footer runs
    else
        update_state "INSTALL_STATUS" "COMPLETED"
    fi
fi

close_logging_session
