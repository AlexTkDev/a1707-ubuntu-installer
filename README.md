# MacBook Pro 15" (A1707, 2016-2017) Ubuntu Installer

A **production-ready**, idempotent, and secure automated installer designed to configure all hardware components of the MacBook Pro A1707 (MacBookPro14,3 / MacBookPro13,3) running Ubuntu LTS releases.

---

## 🚀 Features & Key Highlights

- **Idempotent & Safe Rollback**: Transactional rollback mechanism powered by `trap ERR INT TERM`. Automatically restores original system configuration backups if any failure occurs during installation.
- **Manifest Tracking**: Keeps track of all installed files in `/var/lib/macbook-installer/manifest.txt`, ensuring safe and precise uninstallation without collateral damage to distro packages.
- **Offline & SHA256 Verification**: Verifies SHA256 checksums for all Wi-Fi, Bluetooth, and FaceTime HD firmware binary blobs.
- **Dynamic DKMS & Versioning**: Parses module versions directly from `dkms.conf`, pins upstream Git commits, and verifies kernel module loading post-install via `modinfo`.
- **EFI & Secure Boot Awareness**: Detects Secure Boot status via `mokutil` and alerts users if MOK key signing is required.
- **Touch Bar & SPI**: Automatically validates kernel modules and configures auto-loading for `applespi`, `apple_ib_tb`, and `intel_lpss_pci`.
- **Audio & Camera**: Automatically compiles and installs the Cirrus Logic CS8409 audio driver (`snd_hda_macbookpro`) and FaceTime HD camera driver (`facetimehd`).
- **Power Management**: Disables unreliable hibernation modes via `systemd` to prevent sleep wake-up issues.

---

## 🛠️ System Requirements

1. **Hardware**: MacBook Pro 15" with Touch Bar (A1707 — MacBookPro14,3 or MacBookPro13,3).
2. **Operating System**: Ubuntu LTS (22.04 / 24.04 / 26.04) or compatible Debian/Ubuntu derivatives.
3. **Privileges**: Root access (`sudo`).
4. **Disk Space**: At least 1000 MB free space in `/`.

---

## 📖 Usage Guide

### 1. Dry Run (Simulation Mode)

Verify hardware compatibility and preview execution steps without modifying your system:

```bash
sudo ./install.sh --dry-run
```

### 2. Full Installation

Run the automated production installation:

```bash
sudo ./install.sh
```

### 3. Command-Line Options

- `--verbose` (`-v`) — Print detailed output from background processes (e.g., `make`, `apt-get`, `dkms`).
- `--quiet` (`-q`) — Suppress standard output; only output errors to console.
- `--dry-run` — Simulate installation without modifying any files.

**Example with verbose logging:**
```bash
sudo ./install.sh --verbose
```

---

## 📋 Logs & Reporting

- **Execution Log**: `/var/log/macbook-installer.log`
- **Installation Report**: `/var/lib/macbook-installer/report.txt`
- **Resource Manifest**: `/var/lib/macbook-installer/manifest.txt`

---

## 🗑️ Uninstallation

To safely remove all installed drivers, firmware files, and configurations while restoring original backups:

```bash
sudo ./uninstall.sh
```

---

## 👥 Credits & Acknowledgments

This project utilizes community-maintained drivers:
- Audio Driver: [davidjo/snd_hda_macbookpro](https://github.com/davidjo/snd_hda_macbookpro)
- Camera Driver: [patjak/bcwc_pcie](https://github.com/patjak/bcwc_pcie)
- Camera Firmware: [patjak/facetimehd-firmware](https://github.com/patjak/facetimehd-firmware)
- Touch Bar / SPI Driver: [roadrunner2/macbook12-spi-driver](https://github.com/roadrunner2/macbook12-spi-driver)
