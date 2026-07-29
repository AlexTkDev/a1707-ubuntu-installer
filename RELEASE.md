# Release Process

This document is for maintainers to follow when publishing a new version of the framework.

1. **Update VERSION**
   Ensure `VERSION` matches the target release (e.g., `1.0.0`).

2. **Update CHANGELOG**
   Move Unreleased changes in `CHANGELOG.md` to the new version block.

3. **Verify SHA256SUMS**
   Ensure `assets/firmware/SHA256SUMS` and `assets/packages/SHA256SUMS` accurately reflect the bundled assets.

4. **Run ShellCheck**
   ```bash
   shellcheck install.sh doctor.sh repair.sh rollback.sh uninstall.sh scripts/*.sh common/*.sh checks/*.sh repairs/*.sh
   ```

5. **Run Dry-Run**
   ```bash
   sudo ./install.sh --dry-run
   ```

6. **Test install**
   On a fresh Ubuntu test machine, execute `sudo ./install.sh`.

7. **Test doctor**
   Execute `sudo ./doctor.sh` and ensure it exits with `0 (PASS)`.

8. **Test repair**
   Break a component manually (e.g., remove the Wi-Fi symlink) and ensure `sudo ./repair.sh --wifi` heals it.

9. **Test rollback**
   Run `sudo ./rollback.sh` and confirm the machine returns to its pre-installed state.

10. **Create Git tag**
    ```bash
    git tag v1.0.0
    git push origin v1.0.0
    ```

11. **Publish GitHub Release**
    Attach the bundled `.tar.gz` (including `assets/`) to the GitHub release page. Include a summary of the changes from `CHANGELOG.md`.
