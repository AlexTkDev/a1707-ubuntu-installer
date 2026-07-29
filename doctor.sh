#!/usr/bin/env bash
# doctor.sh - Modular validation framework (Thin Orchestrator)
# All diagnostics are read-only.

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common/logging.sh"

OUTPUT_FORMAT="text"

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --json) OUTPUT_FORMAT="json" ;;
        --text) OUTPUT_FORMAT="text" ;;
        --compact) OUTPUT_FORMAT="compact" ;;
        *)
            log_error "Unknown argument: $arg"
            echo "Usage: $0 [--text | --json | --compact]"
            exit 1
            ;;
    esac
done

# We operate entirely read-only. Disable any logging that might write side-effects if we want
# strict read-only, but logging to /var/log/macbookpro14-installer.log is fine.
# We'll suppress normal log outputs if we are generating JSON to avoid breaking it.
if [[ "${OUTPUT_FORMAT}" == "json" ]]; then
    LOG_QUIET=1
fi

detect_platform() {
    # Read board ID from sysfs
    local current_board=""
    if [[ -f /sys/class/dmi/id/board_name ]]; then
        current_board="$(cat /sys/class/dmi/id/board_name)"
    fi

    # Find matching platform
    for plat_file in "${SCRIPT_DIR}/platforms/"*.sh; do
        [[ ! -f "${plat_file}" ]] && continue
        
        # Source in a subshell to check BOARD_ID without polluting current env
        local plat_board
        plat_board="$(bash -c "source \"${plat_file}\" && echo \"\${BOARD_ID}\"")"
        
        if [[ "${plat_board}" == "${current_board}" || -z "${current_board}" ]]; then
            # We found a match, or if empty fallback to the first one for testing
            source "${plat_file}"
            return 0
        fi
    done
    
    # Fallback to macbookpro14-3 if not detected properly (e.g. testing VM)
    source "${SCRIPT_DIR}/platforms/macbookpro14-3.sh"
}

# Load Platform
detect_platform

# Results aggregation
declare -i TOTAL_PASS=0
declare -i TOTAL_WARN=0
declare -i TOTAL_FAIL=0

declare -a RESULTS_JSON=()

print_text_result() {
    local status="$1" title="$2" msg="$3" rec="$4"
    local color=""
    case "$status" in
        PASS) color="${C_GREEN}" ;;
        WARN) color="${C_YELLOW}" ;;
        FAIL) color="${C_RED}" ;;
    esac

    echo -e "${color}${status}${C_RESET}"
    echo -e "${title}"
    echo -e "${msg}"
    if [[ -n "${rec}" ]]; then
        echo -e "\nRecommended fix:\n${rec}"
    fi
    echo -e "---"
}

print_compact_result() {
    local status="$1" title="$2" msg="$3"
    local color=""
    case "$status" in
        PASS) color="${C_GREEN}" ;;
        WARN) color="${C_YELLOW}" ;;
        FAIL) color="${C_RED}" ;;
    esac
    echo -e "[${color}${status}${C_RESET}] ${title}: ${msg}"
}

add_json_result() {
    local status="$1" title="$2" msg="$3" rec="$4" rid="$5"
    # Basic JSON escaping
    msg="${msg//\"/\\\"}"
    rec="${rec//\"/\\\"}"
    title="${title//\"/\\\"}"
    
    local json_block="{\"status\": \"${status}\", \"title\": \"${title}\", \"message\": \"${msg}\", \"recommended_fix\": \"${rec}\", \"repair_id\": \"${rid}\"}"
    RESULTS_JSON+=("${json_block}")
}

run_all_checks() {
    # If using text output, print header
    if [[ "${OUTPUT_FORMAT}" == "text" ]]; then
        echo -e "=== Doctor Diagnostics (${PLATFORM_NAME}) ==="
        echo -e "---\n"
    fi

    for check_file in "${SCRIPT_DIR}/checks/"*.sh; do
        [[ ! -f "${check_file}" ]] && continue

        # Reset global result variables for the check
        RESULT_MESSAGE=""
        RESULT_RECOMMENDATION=""
        RESULT_REPAIR_ID=""
        
        # Source the check definitions
        # shellcheck source=/dev/null
        source "${check_file}"
        
        # Execute the check
        local ret_code=0
        run_check || ret_code=$?
        
        local status="PASS"
        if [[ ${ret_code} -eq 1 ]]; then
            status="WARN"
            ((TOTAL_WARN++))
        elif [[ ${ret_code} -ge 2 ]]; then
            status="FAIL"
            ((TOTAL_FAIL++))
        else
            ((TOTAL_PASS++))
        fi
        
        # Display based on format
        case "${OUTPUT_FORMAT}" in
            text) print_text_result "${status}" "${check_title}" "${RESULT_MESSAGE}" "${RESULT_RECOMMENDATION}" ;;
            compact) print_compact_result "${status}" "${check_title}" "${RESULT_MESSAGE}" ;;
            json) add_json_result "${status}" "${check_title}" "${RESULT_MESSAGE}" "${RESULT_RECOMMENDATION}" "${RESULT_REPAIR_ID}" ;;
        esac
    done
}

print_summary() {
    local overall="Healthy"
    local exit_code=0
    
    if [[ ${TOTAL_FAIL} -gt 0 ]]; then
        overall="Broken"
        exit_code=2
    elif [[ ${TOTAL_WARN} -gt 0 ]]; then
        overall="Needs Attention"
        exit_code=1
    fi

    if [[ "${OUTPUT_FORMAT}" == "json" ]]; then
        # Join JSON array elements with commas
        local joined_results
        joined_results=$(IFS=,; echo "${RESULTS_JSON[*]}")
        cat <<EOF
{
  "platform": "${PLATFORM_NAME}",
  "summary": {
    "pass": ${TOTAL_PASS},
    "warn": ${TOTAL_WARN},
    "fail": ${TOTAL_FAIL},
    "overall_health": "${overall}"
  },
  "results": [
    ${joined_results}
  ]
}
EOF
    else
        echo -e "\nPASS: ${TOTAL_PASS}"
        echo -e "WARN: ${TOTAL_WARN}"
        echo -e "FAIL: ${TOTAL_FAIL}"
        echo -e "\nOverall Health:\n${overall}"
    fi
    
    return "${exit_code}"
}

run_all_checks
print_summary
exit $?
