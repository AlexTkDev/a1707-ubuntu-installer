# MacBook Pro 15" (A1707, 2016-2017) Ubuntu Installer

A **production-ready**, idempotent, and secure automated installer designed to configure all hardware components of the MacBook Pro A1707 running Ubuntu LTS releases.

---

## 📱 Targeted Hardware & Personal Note

This repository was specifically crafted and tuned for my personal **MacBook Pro 15" (2017)** setup:

- **Model Identifier**: `MacBookPro14,3` (Model A1707)
- **Board ID**: `Mac-551B86E5744E2388`
- **Processor**: Quad-Core Intel Core i7
- **Wi-Fi**: Broadcom BCM43602 802.11ac (`0x14E4:0x43BA`)
- **Bluetooth**: Broadcom BCM20703A1
- **Camera**: Broadcom 1570 FaceTime HD (`0x14E4:0x1570`)
- **Audio**: Cirrus Logic CS8409 (`snd_hda_macbookpro`)
- **Touch Bar & SPI**: Apple T1 chip (`applespi`, `apple_ib_tb`)

If your device is an exact match for **MacBookPro14,3**, this installer works out of the box!

---

## 🔧 How to Adapt This Installer for Other MacBook Models

If you own a different MacBook Pro (e.g., `MacBookPro13,3`, `MacBookPro14,1`, `MacBookPro15,1`, `A1706`, `A1708`), you can easily adapt this installer by tweaking the following configuration points:

### 1. Update Hardware Detection (`scripts/00_detect.sh`)
- **Board ID**: Find your board ID via `cat /sys/class/dmi/id/board_name` and update `TARGET_BOARD_ID="Mac-YOUR-BOARD-ID"`.
- **Model Check**: Update the model string check (`MacBookPro14,3`) to match your system (`cat /sys/class/dmi/id/product_name`).
- **PCI Vendor & Device IDs**: Check your Wi-Fi and Camera IDs via `lspci -nn` and adjust the grep patterns:
  - Wi-Fi: `lspci -nn | grep -qiE "14e4:43ba|BCM43602"`
  - Camera: `lspci -nn | grep -qiE "14e4:1570"`

### 2. Update Firmware Blobs & SHA256 Hashes (`scripts/03_firmware.sh`)
- **Wi-Fi Firmware**: If your Wi-Fi module differs (e.g., BCM4350 or BCM4360), update the filenames in `scripts/03_firmware.sh` and provide updated SHA256 checksums in `SHA256_WIFI_BIN` and `SHA256_WIFI_TXT`.
- **Bluetooth Firmware**: Find your Bluetooth `.hcd` file name in `/lib/firmware/brcm/` or [broadcom-bt-firmware](https://github.com/winterheart/broadcom-bt-firmware) and update `bt_dest` in `install_bt_firmware()`.

### 3. Adjust DKMS Drivers & Pinned Commits (`scripts/04_dkms.sh`)
- **Audio Driver**: If your MacBook uses a different audio codec, change `AUDIO_REPO` or DKMS parameters.
- **Camera Driver**: If your camera uses a different driver branch, update `CAMERA_REPO` and `CAMERA_COMMIT`.

### 4. Kernel Options & Auto-loading Modules (`config/`)
- **Wi-Fi Options**: Edit `config/brcmfmac.conf` if your Wi-Fi card requires different `feature_disable` flags.
- **Modules Load**: Edit `config/modules-load.conf` to list the specific kernel modules your hardware requires (e.g., `applespi`, `snd_hda_macbookpro`, `facetimehd`).

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
