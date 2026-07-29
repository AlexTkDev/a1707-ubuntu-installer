#!/usr/bin/env bash
# Phase 2: Dependency installation

install_dependencies() {
    log_info "Verifying network connectivity before dependency installation..."
    check_internet || log_warn "Internet check failed; apt-get may fail if offline."

    log_info "Updating package lists..."
    apt-get update -qq

    log_info "Installing core build dependencies..."
    apt-get install -y --no-install-recommends \
        build-essential \
        dkms \
        git \
        curl \
        wget \
        linux-headers-"$(uname -r)" \
        bc \
        pkg-config \
        rsync \
        mokutil \
        xz-utils
}

run_cmd "Installing required build dependencies" install_dependencies
