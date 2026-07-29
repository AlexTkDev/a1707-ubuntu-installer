# Contributing

Thank you for your interest in contributing to the MacBook Pro Linux Support Framework!

## Coding Style & Requirements
To ensure safety and reliability across platforms, we enforce the following rules:

- **Bash 5+**: The framework utilizes modern Bash features (arrays, pipefail, `local -n`).
- **ShellCheck Clean**: Every script must pass ShellCheck without exceptions.
- **No External Dependencies**: Modules cannot rely on external tools like `jq`, `curl`, or `wget` during runtime (offline-first design).
- **Small Commits**: Commits must be atomic, e.g., `feat(audio): add CS8409 dkms package`.
- **No Force Pushes**: Once a PR is opened, avoid force pushing if others are reviewing.
- **No Generated Files**: Do not commit generated artifacts outside of `assets/`.
- **Atomic PRs**: PRs should address a single feature or bug fix.

## Architecture
Before writing a new module, read `README.md`.
- Never put installation logic inside `install.sh`.
- Modules must be idempotent (safe to run multiple times).
- All changes must be recorded via `record_install` in `common/state.sh` to ensure `rollback.sh` functions correctly.

Thanks for helping make Linux on MacBooks better!
