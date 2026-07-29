# Testing Guide

This document describes the manual end-to-end testing procedure for validating the framework on a physical MacBookPro14,3.

## E2E Testing Flow

1. **Fresh Environment**
   Boot into a fresh Ubuntu installation. Ensure no proprietary Broadcom or Cirrus drivers are installed.

2. **Execute Installation**
   ```bash
   sudo ./install.sh
   ```
   *Expected:* Finishes with `0` (Success) or `1` (Warnings if a reboot is needed).

3. **Validate with Doctor**
   ```bash
   sudo ./doctor.sh
   ```
   *Expected:* All checks report `PASS`.

4. **Simulate Failure & Repair**
   ```bash
   sudo rm /lib/firmware/brcm/brcmfmac43602-pcie.Apple\ Inc.-MacBookPro14,3.txt
   sudo ./doctor.sh
   ```
   *Expected:* Doctor reports `FAIL` and suggests `repair.sh --repair-id wifi_symlink`.

   ```bash
   sudo ./repair.sh --repair-id wifi_symlink
   sudo ./doctor.sh
   ```
   *Expected:* Repair completes successfully. Doctor reports `PASS`.

5. **Execute Rollback**
   ```bash
   sudo ./rollback.sh
   ```
   *Expected:* Rollback removes installed packages and firmware, restoring the system exactly to Step 1.

6. **Full Uninstall**
   ```bash
   sudo ./uninstall.sh
   ```
   *Expected:* `/var/lib/macbookpro14-installer` and `/var/backups/macbookpro14-linux-support` are deleted.

7. **Reboot**
   Reboot the system and verify no residual components cause boot issues.

8. **Re-Validate**
   ```bash
   sudo ./doctor.sh
   ```
   *Expected:* Hardware failures reported appropriately since the installer is purged.
