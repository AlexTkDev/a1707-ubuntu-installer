# Ubuntu Installer for MacBook Pro 15" 2017 (A1707)

![Ubuntu](https://img.shields.io/badge/Ubuntu-26.04-orange?logo=ubuntu)
![Bash](https://img.shields.io/badge/Bash-5+-4EAA25?logo=gnu-bash)

This is a simple set of scripts I made to restore full hardware functionality on my MacBook Pro A1707 after installing Ubuntu. I am sharing it with the community in hopes that it helps someone else struggling with missing drivers for Wi-Fi, Audio, Touch Bar, or the Camera.

> **Note:** This project installs third-party DKMS modules and firmware. Please back up your data and use at your own risk.

---

## Supported Hardware

This installer is specifically designed and tested for the **MacBook Pro 15" 2017 (A1707 / MacBookPro14,3)**.

| Component      | Status | Notes                       |
| -------------- | ------ | --------------------------- |
| Wi-Fi BCM43602 | ✅      | Installs correct firmware   |
| Audio CS8409   | ✅      | Installs DKMS driver        |
| Touch Bar & Touchpad | ✅      | Installs DKMS driver & libinput input driver |
| Camera         | ✅      | FaceTime HD DKMS & firmware |
| Bluetooth      | ✅      | Native kernel support       |

---

## How to Install

1. Clone or download this repository.
2. Run the main installation script:

```bash
sudo ./install.sh
```

3. Once the script finishes, **reboot your laptop**.

### Useful Options
- `--phase NAME` : Run only a specific part (e.g., `sudo ./install.sh --phase audio`).
- `--skip NAME` : Skip a specific part.
- `--verbose` or `--debug` : Get more detailed output if something goes wrong.

<details>
<summary><b>Example Terminal Output</b></summary>

```text
alex@Alex-MacBook:~/a1707-ubuntu-installer$ sudo ./install.sh
[2026-07-30T12:50:05+03:00] [INFO] ==================================================
[2026-07-30T12:50:05+03:00] [INFO] Installer Session Started
[2026-07-30T12:50:05+03:00] [INFO] Timestamp     : 2026-07-30T12:50:05+03:00
[2026-07-30T12:50:05+03:00] [INFO] Repository    : v2.0 (Redesign)
[2026-07-30T12:50:05+03:00] [INFO] OS            : Ubuntu 26.04 LTS
[2026-07-30T12:50:05+03:00] [INFO] Kernel        : 7.0.0-28-generic
[2026-07-30T12:50:05+03:00] [INFO] Hostname      : Alex-MacBook
[2026-07-30T12:50:05+03:00] [INFO] Board Model   : MacBookPro14,3
[2026-07-30T12:50:05+03:00] [INFO] ==================================================
[2026-07-30T12:50:05+03:00] [INFO] Detected Platform: MacBookPro14,3 (v1)
[2026-07-30T12:50:05+03:00] [INFO] Phase: prerequisites ... [SUCCESS] Prerequisites met.
[2026-07-30T12:50:05+03:00] [INFO] Phase: wifi          ... [SUCCESS] Wi-Fi firmware installed.
[2026-07-30T12:50:06+03:00] [INFO] Phase: audio         ... [SUCCESS] Package mbp-cirrus-audio-dkms installed.
[2026-07-30T12:50:08+03:00] [INFO] Phase: touchbar      ... [SUCCESS] Touch Bar package verified.
[2026-07-30T12:50:09+03:00] [INFO] Phase: camera        ... [SUCCESS] Camera module installation phase complete.
[2026-07-30T12:50:14+03:00] [INFO] Phase: validation    ... [SUCCESS] Kernel module dependencies updated.
[2026-07-30T12:50:14+03:00] [INFO] Phase: cleanup       ... [SUCCESS] Cleanup complete.
[2026-07-30T12:50:14+03:00] [INFO] ==================================================
[2026-07-30T12:50:14+03:00] [INFO] Installer Session Completed
[2026-07-30T12:50:14+03:00] [INFO] Elapsed Time  : 6 seconds
[2026-07-30T12:50:14+03:00] [INFO] Exit Code     : 0
[2026-07-30T12:50:14+03:00] [WARN] Total Warnings: 4
[2026-07-30T12:50:14+03:00] [INFO] Total Errors  : 0
[2026-07-30T12:50:14+03:00] [INFO] ==================================================
```

</details>

---

## Troubleshooting Tools

If something isn't working right after a kernel update or installation, you can use these tools:

- **`sudo ./doctor.sh`**  
  Checks your system to see what is missing or broken (DKMS modules, packages, firmware) without changing anything.

- **`sudo ./repair.sh --all`**  
  Tries to automatically fix any issues found by the doctor script.

- **`sudo ./rollback.sh`**  
  Undoes the changes made by the installer and restores backup files.

---

## Future Plans

- Improve power management and battery life
- Better suspend/resume support
- Automatic firmware extraction directly from macOS

## License

This project is licensed under the MIT License. Feel free to use and modify it!
