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
| Power & Thermal| ✅      | TLP power optimization, mbpfan fan control & T1 USB sleep hook |
| Bluetooth      | ✅      | Native kernel support       |

---

## How to Install

1. Clone or download this repository.
2. Run the main installation script:

```bash
sudo ./install.sh
```

3. Once the script finishes,❗️ **reboot your laptop**. ❗️

### Useful Options
- `--phase NAME` : Run only a specific part (e.g., `sudo ./install.sh --phase audio`).
- `--skip NAME` : Skip a specific part.
- `--with-gnome-settings` : Apply the author's custom macOS-like GNOME keybindings & desktop settings.
- `--verbose` or `--debug` : Get more detailed output if something goes wrong.

> **Note on Custom Keybindings:** By default, the installer leaves standard Ubuntu keybindings intact. However, if you want the author's personal GNOME shortcuts tuned for macOS muscle memory (such as `Command` key shortcuts like `Cmd+C` / `Cmd+V` instead of standard Ctrl, and `<Shift><Alt>Space` for input source switching), you can run the installer with `--with-gnome-settings`.

<details>
<summary><b>Example Terminal Output</b></summary>

```text
alex@ubuntu:~/a1707-ubuntu-installer$ sudo ./install.sh --with-gnome-settings
[2026-08-01T14:23:19+03:00] [INFO] ==================================================
[2026-08-01T14:23:19+03:00] [INFO] Installer Session Started
[2026-08-01T14:23:19+03:00] [INFO] OS            : Ubuntu 26.04 LTS
[2026-08-01T14:23:19+03:00] [INFO] Kernel        : 7.0.0-28-generic
[2026-08-01T14:23:19+03:00] [INFO] Board Model   : MacBookPro14,3
[2026-08-01T14:23:19+03:00] [INFO] ==================================================
[2026-08-01T14:23:19+03:00] [INFO] Detected Platform: MacBookPro14,3 (v1)
[2026-08-01T14:23:19+03:00] [INFO] Phase: prerequisites ... [SUCCESS] Prerequisites met.
[2026-08-01T14:23:20+03:00] [INFO] Phase: wifi          ... [SUCCESS] Wi-Fi firmware installed.
[2026-08-01T14:23:20+03:00] [INFO] Phase: audio         ... [SUCCESS] Package mbp-cirrus-audio-dkms installed.
[2026-08-01T14:23:22+03:00] [INFO] Phase: touchbar      ... [SUCCESS] Touch Bar package verified.
[2026-08-01T14:23:23+03:00] [INFO] Phase: camera        ... [SUCCESS] Camera module installation phase complete.
[2026-08-01T14:23:24+03:00] [INFO] Phase: power         ... [SUCCESS] Custom GNOME settings & i915 CPU fix applied.
[2026-08-01T14:23:26+03:00] [INFO] Phase: validation    ... [SUCCESS] Kernel module dependencies updated.
[2026-08-01T14:23:30+03:00] [INFO] Phase: cleanup       ... [SUCCESS] Cleanup complete.
[2026-08-01T14:23:30+03:00] [INFO] ==================================================
[2026-08-01T14:23:30+03:00] [INFO] Installer Session Completed
[2026-08-01T14:23:30+03:00] [INFO] Elapsed Time  : 6 seconds
[2026-08-01T14:23:30+03:00] [INFO] Exit Code     : 0
[2026-08-01T14:23:30+03:00] [WARN] Total Warnings: 1
[2026-08-01T14:23:30+03:00] [INFO] Total Errors  : 0
[2026-08-01T14:23:30+03:00] [INFO] ==================================================
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

## 🗺️ Roadmap & Community Support

This framework is modular and scalable by design, but its future evolution depends on **community activity**. If this project saved your time, please **star the repository** ⭐ to support its development!

### 🎯 Completed & High Priority
- [x] Refine suspend/resume hooks for stable Touch Bar wakeups. *(Done!)*
- [ ] Improve power management profiles and maximize battery life on Linux.
- [ ] Implement automatic firmware extraction tools directly from a local macOS partition.

### 🚀 Future Milestones (Driven by Stars & Community Feedback)
- **At 50 Stars:** 🌐 Multi-distro compatibility checks (Fedora and Arch Linux modular script adaptation).
- **At 100 Stars:** 💻 Expand framework architecture to officially support **MacBookPro14,1 (A1708)** and **MacBookPro14,2 (A1706)**.
- **At 200 Stars:** 🎨 Python-based GTK/Qt Graphical User Interface (GUI) for one-click installation and visual hardware diagnostics.

## 🤝 Expanding to Other MacBooks

If you own a different MacBook Pro model (e.g., A1706, A1708) and want to help expand support:
1. Review our [Contribution Guidelines](CONTRIBUTING.md) for core architecture and formatting rules.
2. You can add new device profiles under the `platforms/` directory without changing the core installation loop.
3. Open an Issue or Pull Request with your hardware log generated by `sudo ./doctor.sh`.



## License

This project is licensed under the MIT License. Feel free to use and modify it!
