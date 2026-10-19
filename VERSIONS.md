# VERSIONS: the tested combination

`versions.env` is the machine-readable source of truth; `bin/doctor.sh` fails (AJ-*-02) when an installed version drifts from it.

**Release rule:** a combination is published here only after it has run on our own estate and passed our tests, and after one clean install by a fresh agent from this public repo alone ended with DOCTOR all PASS. Users upgrade only by moving to a new tag of this repo.

| Setup tag | Date | T3 Code (fork) | Tentacles | estate-guardian (classify standard, guard optional) | Claude Code CLI | Agent Jack desktop | Tested on | Co je nového / What's new |
|---|---|---|---|---|---|---|---|---|
| v1.0.3 | 2026-10-19 | v0.0.42-tplus.2 (dmg sha256 re-verified by download 2026-10-19) | v0.4.1-jack.1 | v1.0.0 (estate-classify 0.3.0) | ≥ 2.1.302 (+ Codex CLI ≥ 0.162.1) | ≥ 3.17.41 | proof pending: first assisted install on an early person's own computer (see "Assisted first install" below) | REPAIR AJ-T3-06: provider "not found" in T3 (login-shell PATH / binary path fallback); Windows still not proven |
| v1.0.2 | 2026-10-17 | v0.0.42-tplus.2 | v0.4.1-jack.1 | v1.0.0 (estate-classify 0.3.0) | ≥ 2.1.302 (+ Codex CLI ≥ 0.162.1) | ≥ 3.17.41 | edge-device install (macOS 26.4, arm64), sign-ins pending | Codex CLI is now a standard component (the "Local · Codex" lab): install, doctor AJ-CODEX-*, REPAIR |
| v1.0.1 | 2026-10-17 | v0.0.42-tplus.2 | v0.4.1-jack.1 | v1.0.0 (estate-classify 0.3.0) | ≥ 2.1.302 | ≥ 3.17.41 | first real edge-device install (macOS 26.4, arm64) | fix: `install.sh all` recursed in the Tentacles step; doctor skips the reply test while Claude is signed out |
| v1.0.0 | 2026-10-17 · ⚠ do not roll back to it (`install.sh all` recurses in the Tentacles step) | v0.0.42-tplus.2 (T3 Code TPLUS, 0.0.42 @ 6d8dfb7f + turn-result patch; not notarized, no update feed) | v0.4.1-jack.1 | v1.0.0 (estate-classify 0.3.0) | ≥ 2.1.302 | ≥ 3.17.41 | fresh-agent sandbox install on macOS 27 (sign-in steps manual) | first public combination |

## Assisted first install (how a release gets its proof)

Since v1.0.3 the release proof is an early person's **own computer**, with the Founder sitting beside them and Claude Code following this public repo (README → [SETUP-PROMPT.md](SETUP-PROMPT.md)). Nothing from our estate is used.

**Have ready before the sitting**
- The person's Mac (macOS ≥ 13) with an admin account, ≥ 20 GB free, the power cable connected, and a working Time Machine or other backup (step 0).
- Their own Claude plan (Pro/Max) for Claude Code. Optionally, their own ChatGPT plan for Codex.
- Their Agent Jack account (Google or the email and password from the welcome mail), plus their phone for 2FA.
- The Claude app from https://claude.com/download, signed in, **Code** tab open, model **Sonnet**, effort **high** (README steps 1–3), with the whole SETUP-PROMPT.md text pasted in.

**The person does these themselves (their passwords, their 2FA, their clicks)**
1. Their Mac admin password (Homebrew) and "Open Anyway" in System Settings → Privacy & Security.
2. `claude auth login` in their browser, and `codex login` if they use Codex.
3. Opening T3 Code TPLUS once and checking Settings → Providers → Claude Code (step 4).
4. Downloading Agent Jack from https://agentjack.kraliki.com/downloads, dragging it to Applications and signing in on the web and in the app (step 5).
5. Approving the pairing (Settings → Computers & labs → Pair this Mac), then Bot → Provider → Local → Claude Code → one message (step 6).

**Claude does the rest**: the backup and disk check, `bin/doctor.sh`, `bin/install.sh all`, the dmg shasum check, guiding each of the person's steps, and the final `bin/doctor.sh` with the two manual lines (step 7).

**What counts as the proof ("all PASS")**
- The final `bin/doctor.sh` has **no FAIL**. AJ-PAIR-00, AJ-LOCAL-00 and AJ-BROWSER-00 always print SKIP (they are checked by hand). AJ-CODEX-03 (Codex signed out) and AJ-BAK-01 (backup other than a recent Time Machine) may be WARN.
- The two manual lines say pairing = **Paired · ready** and Local Bot replied = **yes**.

**Saving the proof**
- Run `bin/doctor.sh > ~/Desktop/agent-jack-doctor.txt; cat ~/Desktop/agent-jack-doctor.txt` and add the two manual lines, as in SETUP-PROMPT step 7.
- Check it has no passwords, keys, emails or home-folder names, then send it in reply to the welcome mail.
- Proof met → the release row above gets `Tested on: assisted install, macOS <ver> <arch>, DOCTOR no FAIL + paired + Local Bot reply (date)`. Any FAIL → a [REPAIR.md](REPAIR.md) "Real cases" entry (date, code, symptom, cause, fix) and a fix in the next tag.
- Windows stays "not yet proven" until one of these sittings runs on Windows ([SETUP-PROMPT-WINDOWS.md](SETUP-PROMPT-WINDOWS.md)).
