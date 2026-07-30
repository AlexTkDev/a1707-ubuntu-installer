# shellcheck shell=bash
# shellcheck disable=SC2034,SC2154
# checks/08_power.sh

check_id="power"
check_title="Power & Thermal Management"
check_description="Verifies TLP, mbpfan, and Touch Bar T1 USB reset sleep hook."

run_check() {
    local tlp_installed=0
    local mbpfan_installed=0
    local hook_installed=0

    if dpkg-query -W -f='${Status}\n' tlp 2>/dev/null | grep -q "installed"; then
        tlp_installed=1
    fi

    if dpkg-query -W -f='${Status}\n' mbpfan 2>/dev/null | grep -q "installed"; then
        mbpfan_installed=1
    fi

    if [[ -f "/lib/systemd/system-sleep/t1-touchbar-reset" && -x "/lib/systemd/system-sleep/t1-touchbar-reset" ]]; then
        hook_installed=1
    fi

    if [[ ${tlp_installed} -eq 1 && ${mbpfan_installed} -eq 1 && ${hook_installed} -eq 1 ]]; then
        RESULT_MESSAGE="Power & thermal management (TLP, mbpfan, T1 reset hook) configured."
        return 0
    fi

    RESULT_MESSAGE="Power management partially missing (tlp=${tlp_installed}, mbpfan=${mbpfan_installed}, t1_hook=${hook_installed})."
    RESULT_RECOMMENDATION="Run install.sh --phase power"
    RESULT_REPAIR_ID="power"
    return 1
}
