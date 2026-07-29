#!/usr/bin/env bash
# Phase 3: Firmware installation with SHA256 checks & commit pinning

# SHA256 Hashes
readonly SHA256_WIFI_BIN="bf4cfc23ee952a3d82ef33a0f5f87853201c98f1bed034876a910f354f37862d"
readonly SHA256_WIFI_TXT="a74cbb0abc4e8a437e383442dd44a96263079c102787fbe0758e67614ca79df2"

# Pinned Commits
readonly FACETIMEHD_FW_REPO="https://github.com/patjak/facetimehd-firmware.git"
readonly FACETIMEHD_FW_COMMIT="69c6f2e825a075677ee5acfa96d194ef9375e8ef"

install_wifi_firmware() {
    local fw_dir="/lib/firmware/brcm"
    mkdir -p "${fw_dir}"

    local local_bcm_dir="${SCRIPT_DIR}/firmware/bcm43602"
    local bin_dest="${fw_dir}/brcmfmac43602-pcie.bin"
    local txt_dest="${fw_dir}/brcmfmac43602-pcie.txt"

    if [[ -f "${local_bcm_dir}/brcmfmac43602-pcie.bin" && -f "${local_bcm_dir}/brcmfmac43602-pcie.txt" ]]; then
        log_info "Using local Wi-Fi firmware files from ${local_bcm_dir}"
        verify_sha256 "${local_bcm_dir}/brcmfmac43602-pcie.bin" "${SHA256_WIFI_BIN}"
        verify_sha256 "${local_bcm_dir}/brcmfmac43602-pcie.txt" "${SHA256_WIFI_TXT}"

        safe_backup "${bin_dest}"
        safe_backup "${txt_dest}"

        cp -af "${local_bcm_dir}/brcmfmac43602-pcie.bin" "${bin_dest}"
        cp -af "${local_bcm_dir}/brcmfmac43602-pcie.txt" "${txt_dest}"
    else
        log_info "Downloading Wi-Fi firmware with SHA256 verification..."
        check_internet
        local tmp_bin tmp_txt
        tmp_bin="$(mktemp)"
        tmp_txt="$(mktemp)"

        wget -qO "${tmp_bin}" "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/brcm/brcmfmac43602-pcie.bin"
        wget -qO "${tmp_txt}" "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git/plain/brcm/brcmfmac43602-pcie.txt"

        verify_sha256 "${tmp_bin}" "${SHA256_WIFI_BIN}"
        verify_sha256 "${tmp_txt}" "${SHA256_WIFI_TXT}"

        safe_backup "${bin_dest}"
        safe_backup "${txt_dest}"

        mv -f "${tmp_bin}" "${bin_dest}"
        mv -f "${tmp_txt}" "${txt_dest}"
    fi

    chmod 644 "${bin_dest}" "${txt_dest}"
    register_installed_file "${bin_dest}"
    register_installed_file "${txt_dest}"
    log_success "Wi-Fi firmware successfully installed and verified."
}

install_bt_firmware() {
    local fw_dir="/lib/firmware/brcm"
    mkdir -p "${fw_dir}"

    local bt_dest="${fw_dir}/BCM20703A1-05ac-8290.hcd"
    local local_bt_dir="${SCRIPT_DIR}/firmware/bluetooth"

    if [[ -f "${local_bt_dir}/BCM20703A1-05ac-8290.hcd" ]]; then
        log_info "Using local Bluetooth firmware..."
        safe_backup "${bt_dest}"
        cp -af "${local_bt_dir}/BCM20703A1-05ac-8290.hcd" "${bt_dest}"
    else
        log_info "Downloading Bluetooth firmware..."
        check_internet
        local fw_url="https://github.com/winterheart/broadcom-bt-firmware/raw/master/brcm/BCM20703A1-05ac-8290.hcd"
        safe_backup "${bt_dest}"
        wget -qO "${bt_dest}" "${fw_url}"
    fi

    chmod 644 "${bt_dest}"
    register_installed_file "${bt_dest}"
    log_success "Bluetooth firmware installed."
}

install_facetimehd_firmware() {
    local tmp_dir
    tmp_dir=$(mktemp -d)

    log_info "Cloning facetimehd-firmware at pinned commit ${FACETIMEHD_FW_COMMIT}..."
    check_internet
    git clone "${FACETIMEHD_FW_REPO}" "${tmp_dir}/facetimehd-firmware"
    pushd "${tmp_dir}/facetimehd-firmware" >/dev/null || exit 1
    git checkout -q "${FACETIMEHD_FW_COMMIT}"

    make
    make install

    popd >/dev/null || exit 1
    rm -rf "${tmp_dir}"

    local fw_facetime="/lib/firmware/facetimehd/firmware.bin"
    if [[ -f "${fw_facetime}" ]]; then
        register_installed_file "${fw_facetime}"
        log_success "FaceTime HD firmware extracted and installed."
    else
        log_warn "FaceTime HD firmware file missing after make install."
    fi
}

run_cmd "Installing WiFi firmware (BCM43602)" install_wifi_firmware
run_cmd "Installing Bluetooth firmware" install_bt_firmware
run_cmd "Extracting and installing FaceTime HD firmware" install_facetimehd_firmware
