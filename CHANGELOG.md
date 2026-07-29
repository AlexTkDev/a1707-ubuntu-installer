# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-07-30

### Added
- Complete offline installer architecture (`install.sh`).
- Hardware-specific definitions via `platforms/macbookpro14-3.sh`.
- Phase-based execution registry.
- `doctor.sh` for non-destructive system health diagnostics.
- `repair.sh` for targeted, granular issue resolution.
- `rollback.sh` for safe, transactional restoration to pre-install states.
- Wi-Fi offline deployment (handling the 339-byte board file issue).
- Audio (CS8409) DKMS offline deployment.
- Touch Bar (T1) DKMS offline deployment.
- Centralized execution context (`common/context.sh`).
- Migrations framework.
- Diagnostic collection tool (`collect.sh`).
