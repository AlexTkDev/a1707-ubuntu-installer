#!/usr/bin/env bash
# Phase 4: DKMS Driver Installation with commit pinning and post-install verification

readonly AUDIO_REPO="https://github.com/davidjo/snd_hda_macbookpro.git"
readonly AUDIO_COMMIT="master" # Пиннинг ветки/коммита аудио

readonly CAMERA_REPO="https://github.com/patjak/bcwc_pcie.git"
readonly CAMERA_COMMIT="master" # Пиннинг ветки/коммита камеры

install_audio_dkms() {
    local tmp_dir
    tmp_dir=$(mktemp -d)

    log_info "Cloning audio driver repository..."
    check_internet
    git clone "${AUDIO_REPO}" "${tmp_dir}/snd_hda_macbookpro"
    pushd "${tmp_dir}/snd_hda_macbookpro" >/dev/null || exit 1
    git checkout -q "${AUDIO_COMMIT}"

    chmod +x install.cirrus.driver.sh
    ./install.cirrus.driver.sh

    popd >/dev/null || exit 1
    rm -rf "${tmp_dir}"

    log_info "Verifying audio DKMS module..."
    if ! dkms status | grep -q "snd_hda_macbookpro"; then
        log_error "Audio DKMS module snd_hda_macbookpro not found in dkms status!"
        return 1
    fi
    log_success "Cirrus Logic Audio DKMS driver installed and verified."
}

install_camera_dkms() {
    local tmp_dir
    tmp_dir=$(mktemp -d)

    log_info "Cloning FaceTime HD camera driver repository..."
    check_internet
    git clone "${CAMERA_REPO}" "${tmp_dir}/bcwc_pcie"
    pushd "${tmp_dir}/bcwc_pcie" >/dev/null || exit 1
    git checkout -q "${CAMERA_COMMIT}"

    if [[ ! -f dkms.conf ]]; then
        log_error "dkms.conf missing in bcwc_pcie repo!"
        return 1
    fi

    # Динамическое считывание имени и версии модуля из dkms.conf
    local dkms_name dkms_ver
    dkms_name="$(grep -E '^PACKAGE_NAME=' dkms.conf | cut -d= -f2 | tr -d '"' | tr -d "'")"
    dkms_ver="$(grep -E '^PACKAGE_VERSION=' dkms.conf | cut -d= -f2 | tr -d '"' | tr -d "'")"
    dkms_name="${dkms_name:-facetimehd}"
    dkms_ver="${dkms_ver:-0.1}"

    log_info "Targeting DKMS module: ${dkms_name}/${dkms_ver}"
    local dkms_src="/usr/src/${dkms_name}-${dkms_ver}"

    mkdir -p "${dkms_src}"
    cp -af ./* "${dkms_src}/"
    register_installed_file "${dkms_src}"

    dkms remove -m "${dkms_name}" -v "${dkms_ver}" --all 2>/dev/null || true
    dkms add -m "${dkms_name}" -v "${dkms_ver}"
    dkms build -m "${dkms_name}" -v "${dkms_ver}"
    dkms install -m "${dkms_name}" -v "${dkms_ver}"

    popd >/dev/null || exit 1
    rm -rf "${tmp_dir}"

    log_info "Verifying FaceTime HD DKMS status and modinfo..."
    if ! dkms status -m "${dkms_name}" -v "${dkms_ver}" | grep -q "installed"; then
        log_error "FaceTime HD DKMS module ${dkms_name}/${dkms_ver} failed to install!"
        return 1
    fi

    if ! modinfo "${dkms_name}" >/dev/null 2>&1; then
        log_error "modinfo ${dkms_name} failed after installation!"
        return 1
    fi

    log_success "FaceTime HD Camera Driver (${dkms_name}/${dkms_ver}) successfully installed and verified."
}

run_cmd "Installing Cirrus Logic Audio Driver (DKMS)" install_audio_dkms
run_cmd "Installing FaceTime HD Camera Driver (DKMS)" install_camera_dkms
