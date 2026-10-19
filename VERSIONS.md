# VERSIONS: the tested combination

`versions.env` is the machine-readable source of truth; `bin/doctor.sh` fails (AJ-*-02) when an installed version drifts from it.

**Release rule:** a combination is published here only after it has run on our own estate and passed our tests, and after one clean install by a fresh agent from this public repo alone ended with DOCTOR all PASS. Users upgrade only by moving to a new tag of this repo.

| Setup tag | Date | T3 Code (fork) | Tentacles | estate-guardian (classify standard, guard optional) | Claude Code CLI | Agent Jack desktop | Tested on | Co je nového / What's new |
|---|---|---|---|---|---|---|---|---|
| v1.0.3 | 2026-10-19 | v0.0.42-tplus.2 (dmg sha256 re-verified by download 2026-10-19) | v0.4.1-jack.1 | v1.0.0 (estate-classify 0.3.0) | ≥ 2.1.302 (+ Codex CLI ≥ 0.162.1) | ≥ 3.17.41 | fresh-agent proof with sign-ins: pending (see below) | REPAIR AJ-T3-06: provider "not found" in T3 (login-shell PATH / binary path fallback); Windows still not proven |
| v1.0.2 | 2026-10-17 | v0.0.42-tplus.2 | v0.4.1-jack.1 | v1.0.0 (estate-classify 0.3.0) | ≥ 2.1.302 (+ Codex CLI ≥ 0.162.1) | ≥ 3.17.41 | edge-device install (macOS 26.4, arm64), sign-ins pending | Codex CLI is now a standard component (the "Local · Codex" lab): install, doctor AJ-CODEX-*, REPAIR |
| v1.0.1 | 2026-10-17 | v0.0.42-tplus.2 | v0.4.1-jack.1 | v1.0.0 (estate-classify 0.3.0) | ≥ 2.1.302 | ≥ 3.17.41 | first real edge-device install (macOS 26.4, arm64) | fix: `install.sh all` recursed in the Tentacles step; doctor skips the reply test while Claude is signed out |
| v1.0.0 | 2026-10-17 · ⚠ do not roll back to it (`install.sh all` recurses in the Tentacles step) | v0.0.42-tplus.2 (T3 Code TPLUS, 0.0.42 @ 6d8dfb7f + turn-result patch; not notarized, no update feed) | v0.4.1-jack.1 | v1.0.0 (estate-classify 0.3.0) | ≥ 2.1.302 | ≥ 3.17.41 | fresh-agent sandbox install on macOS 27 (sign-in steps manual) | first public combination |
