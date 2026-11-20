# VERSIONS: the tested combination

`versions.env` is the machine-readable source of truth; `bin/doctor.sh` fails (AJ-*-02) when an installed version drifts from it.

**Release rule:** a combination is published here only after it has run on our own estate and passed our tests, and after one clean install by a fresh agent from this public repo alone ended with DOCTOR all PASS. Users upgrade only by moving to a new tag of this repo.

| Setup tag | Date | T3 Code | Tentacles | estate-guardian (classify standard, guard optional) | Claude Code CLI / Codex CLI (driver) | Agent Jack desktop | Tested on | Co je nového / What's new |
|---|---|---|---|---|---|---|---|---|
| v1.1.1 | 2026-11-20 | official T3 Code (Beta) v0.1.11 from pingdotgg/t3code (macOS dmg arm64/x64 sha256 pinned; supported range 0.1.8+, T3 updates itself; Windows pin TBD until its proof run) | v0.5.0-jack.17 (commit 82e40af; stock T3 range, DeepSeek headless read-only; desktop 3.17.68 still bundles jack.16) | v1.0.0 (estate-classify 0.3.0) | Codex CLI ≥ 0.164.0 + Claude Code ≥ 2.1.310, both required (sign-in to both recommended) | ≥ 3.17.68 | proof pending: clean Mac install paired with a non-Founder seat (KRA-10804 S3) | desktop minimum 3.17.68 (Local labs per seat, KRA-10804); guides check out v1.1.1 |
| v1.1.0 | 2026-11-13 | v0.0.42-tplus.2 (macOS; Windows build not published: `T3_ASSET_WIN_X64=TBD`) | v0.5.0-jack.16 (commit 29b8e7d; the Tentacles bundled in Agent Jack 3.17.56) | v1.0.0 (estate-classify 0.3.0) | Codex CLI ≥ 0.164.0 + Claude Code ≥ 2.1.310, both required (sign-in to both recommended) | ≥ 3.17.56 | proof pending: clean Mac user and Windows 11 VM | Windows 11 as a first-class path: `bin/doctor.ps1`, `bin/install.ps1`, REPAIR Windows section (PowerShell 5.1, winget, no admin where possible, execution policy per process only); paste-to-your-AI blocks (Codex, Claude Code, any agent) in README, AGENTS.md, CLAUDE.md; `bin/doctor.sh --selftest` / `doctor.ps1 -SelfTest`; honest per-platform scope (Mac app signed and notarised, Windows installer unsigned: SmartScreen + SHA-256 check) |
| v1.0.5 | 2026-10-23 | v0.0.42-tplus.2 | v0.4.1-jack.1 | v1.0.0 (estate-classify 0.3.0) | Codex CLI ≥ 0.162.1 + Claude Code ≥ 2.1.302, both required (sign-in to both recommended) | ≥ 3.17.41 | proof pending: first assisted install (Codex path, MacBook) | recommended minimum = ChatGPT Plus + Claude Pro, both CLIs required; Google Chrome required (AJ-CHROME-*); official Chrome extensions in BROWSER.md (ChatGPT/Codex by OpenAI, Claude in Chrome by Anthropic); recommended hardware M3+/16 GB/512 GB (AJ-HW-01 WARN); "what you end up with" and "where Agent Jack runs" in README |
| v1.0.4 | 2026-10-23 | v0.0.42-tplus.2 | v0.4.1-jack.1 | v1.0.0 (estate-classify 0.3.0) | ≥ 2.1.302 + Codex CLI ≥ 0.162.1 (one of them signed in) | ≥ 3.17.41 | superseded by v1.0.5 before its first install (no separate proof) | Codex path: ChatGPT Plus + Codex app as the driver (README, SETUP-PROMPT, AGENTS); doctor: Claude optional when Codex is signed in, Codex reply check AJ-CODEX-04/05; optional step 8 T3 Code mobile app (pairing with TPLUS unproven) |
| v1.0.3 | 2026-10-19 | v0.0.42-tplus.2 (dmg sha256 re-verified by download 2026-10-19) | v0.4.1-jack.1 | v1.0.0 (estate-classify 0.3.0) | ≥ 2.1.302 (+ Codex CLI ≥ 0.162.1) | ≥ 3.17.41 | proof pending: first assisted install on an early person's own computer (see "Assisted first install" below) | REPAIR AJ-T3-06: provider "not found" in T3 (login-shell PATH / binary path fallback); Windows still not proven |
| v1.0.2 | 2026-10-17 | v0.0.42-tplus.2 | v0.4.1-jack.1 | v1.0.0 (estate-classify 0.3.0) | ≥ 2.1.302 (+ Codex CLI ≥ 0.162.1) | ≥ 3.17.41 | edge-device install (macOS 26.4, arm64), sign-ins pending | Codex CLI is now a standard component (the "Local · Codex" lab): install, doctor AJ-CODEX-*, REPAIR |
| v1.0.1 | 2026-10-17 | v0.0.42-tplus.2 | v0.4.1-jack.1 | v1.0.0 (estate-classify 0.3.0) | ≥ 2.1.302 | ≥ 3.17.41 | first real edge-device install (macOS 26.4, arm64) | fix: `install.sh all` recursed in the Tentacles step; doctor skips the reply test while Claude is signed out |
| v1.0.0 | 2026-10-17 · ⚠ do not roll back to it (`install.sh all` recurses in the Tentacles step) | v0.0.42-tplus.2 (T3 Code TPLUS, 0.0.42 @ 6d8dfb7f + turn-result patch; not notarized, no update feed) | v0.4.1-jack.1 | v1.0.0 (estate-classify 0.3.0) | ≥ 2.1.302 | ≥ 3.17.41 | fresh-agent sandbox install on macOS 27 (sign-in steps manual) | first public combination |

## Assisted first install (how a release gets its proof)

Since v1.0.3 the release proof is an early person's **own computer**, with the Founder sitting beside them and their agent (Codex or Claude Code) following this public repo (README → [SETUP-PROMPT.md](SETUP-PROMPT.md)). Nothing from our estate is used.

**Have ready before the sitting**
- The person's Mac (macOS ≥ 13) with Google Chrome (or it gets installed in step 4) and an admin account, ≥ 20 GB free, the power cable connected, and a working Time Machine or other backup (step 0).
- Their own plans: **ChatGPT Plus** (Codex) and **Claude Pro** (Claude Code), both recommended; one is enough to pass (the other shows WARN). Ideally an Apple M3+ Mac with 16 GB RAM and 512 GB disk (else AJ-HW-01 WARN).
- Their Agent Jack account (Google or the email and password from the welcome mail), plus their phone for 2FA.
- The Codex app from https://openai.com/codex (**Download for macOS**) and the Claude app from https://claude.com/download, both signed in. The driver app gets the whole SETUP-PROMPT.md text: Codex with folder `~/Developer` open and permissions **Ask for approval**, or Claude in the **Code** tab, model **Sonnet**, effort **high**.

**The person does these themselves (their passwords, their 2FA, their clicks)**
1. Their Mac admin password (Homebrew), and "Open" if macOS asks about an app downloaded from the internet.
2. `codex login` and `claude auth login` in their browser (both recommended); in the Codex app, approving each command the agent asks for.
3. Opening **T3 Code (Beta)** (the official app, in Applications) once and checking Settings → Providers → Codex and Claude Code are ready, or the one plan they have (step 4). On a Mac that had an older T3 Code app, `bin/install.sh all` installed T3 Code (Beta) first and then moved the older app to `~/.agent-jack/replaced-apps`; the person's threads in `~/.t3` show up in T3 Code (Beta). With T3 Code (Beta) open, the agent runs `bin/install.sh t3-token` (Tentacles' session for T3; required on a new Mac, else AJ-TENT-03).
4. Downloading Agent Jack from https://agentjack.kraliki.com/downloads, dragging it to Applications and signing in on the web and in the app (step 5).
5. Approving the pairing (Settings → Computers & labs → Pair this Mac), then Bot → gear → Engine → Select (Advanced) → Lab Local · Codex or Local · Claude Code → Apply → one message, badge "Ran on Local · …" (step 6).
6. Optional: installing the T3 Code mobile app (step 8; pairing with T3 Code (Beta) is unproven).

**The agent (Codex or Claude Code) does the rest**: the backup and disk check, `bin/doctor.sh`, `bin/install.sh all` (it checks the T3 Code (Beta) download's SHA-256 and bundle id itself), the Agent Jack dmg shasum check, guiding each of the person's steps, and the final `bin/doctor.sh` with the two manual lines (step 7), plus the mobile line if step 8 was tried.

**What counts as the proof ("all PASS")**
- The final `bin/doctor.sh` has **no FAIL**. AJ-PAIR-00, AJ-LOCAL-00 and AJ-BROWSER-00 always print SKIP (they are checked by hand). AJ-BAK-01 (backup other than a recent Time Machine) and AJ-HW-01 (hardware below M3/16 GB/512 GB) may be WARN, and so may the second plan if it isn't bought yet: AJ-CLAUDE-03/04 or AJ-CODEX-03/04.
- The two manual lines say pairing = **Paired · ready** and Local Bot replied = **yes**.

**Saving the proof**
- Run `bin/doctor.sh > ~/Desktop/agent-jack-doctor.txt; cat ~/Desktop/agent-jack-doctor.txt` and add the two manual lines, as in SETUP-PROMPT step 7.
- Check it has no passwords, keys, emails or home-folder names, then send it in reply to the welcome mail.
- Proof met → the release row above gets `Tested on: assisted install, macOS <ver> <arch>, DOCTOR no FAIL + paired + Local Bot reply (date)`. Any FAIL → a [REPAIR.md](REPAIR.md) "Real cases" entry (date, code, symptom, cause, fix) and a fix in the next tag.
- Windows: the proof run is scheduled. Proven on: _<YYYY-MM-DD, filled in after a sitting on Windows 11 with [SETUP-PROMPT-WINDOWS.md](SETUP-PROMPT-WINDOWS.md) and `bin/doctor.ps1`>_. The person starts with the Agent Jack app signed in and the Bot on our server; until the Windows pin of T3 Code (Beta) is set (proof pending), the sitting ends with no FAIL and WAIT for AJ-PIN-00, AJ-TENT-03 and AJ-LOCAL-00 (Local Bot waiting), plus the recorded pairing attempt.
