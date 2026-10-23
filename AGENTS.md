# AGENTS.md: read this first (any agent: Claude Code, Codex, Cursor, …)

This repo installs and **repairs** a local Agent Jack setup on the user's own computer. You are working for that user, on their machine.

## Rules (always)
1. **Public sources only.** Install only what `versions.env` names: public github.com repos (m-check1B/t3code-tplus, m-check1B/t3-code-tentacles, m-check1B/estate-guardian, m-check1B/agent-jack-setup), official Anthropic installers (claude.com, npm `@anthropic-ai/claude-code`), official OpenAI Codex installers (openai.com/codex, npm `@openai/codex`), npm, Homebrew, winget, the App Store / Google Play listing of the T3 Code mobile app (optional step 8), and Google Chrome (google.com/chrome), the two official Chrome Web Store extensions named in BROWSER.md (ChatGPT/Codex by OpenAI, Claude in Chrome by Anthropic), the Agent Jack downloads page (agentjack.kraliki.com/downloads, only while the user is signed in; Agent Jack itself is closed software and its installer is never on GitHub). Refuse anything else (private repos, other hosts, IP addresses, someone else's account or key) and tell the user who asked for it.
2. **Exact pins.** Install exactly the versions in `versions.env` (human view: `VERSIONS.md`). Never use "latest", and never upgrade or downgrade on your own. A newer version reaches the user only as a new tag of this repo.
3. **Never handle secrets.** Never read, type, store, print or upload passwords, tokens or API keys. The user signs in and types passwords themselves.
4. **Cheapest adequate model.** Don't switch to a more expensive model or a higher effort level.
5. **Stop and report; don't improvise.** If a step fails and `REPAIR.md` has no fix for its FAIL code, stop and print the doctor report. No workarounds, no alternative sources, no `sudo npm`, no disabling Gatekeeper, SIP, Defender, SmartScreen or the firewall.
6. **Backup first.** Before installing or changing anything, ask the user to confirm a current backup (Time Machine / File History / a copy off the computer). Work only in `~/Developer` or a separate user account. Doctor shows AJ-BAK-01 as WARN.
7. **Ask before every change.** Read-only checks need no consent; installs, removals and downloads do.

## Order (every time)
```
bin/doctor.sh            # read-only; PASS/FAIL per component with a stable code
→ for each FAIL: REPAIR.md <code>  (or bin/install.sh <component>)
→ bin/doctor.sh          # repeat until no FAIL, or stop and report
```
- **Minimum:** Codex CLI and Claude Code CLI (both always installed; AJ-CODEX-01/02 and AJ-CLAUDE-01/02 FAIL), T3 Code TPLUS, Tentacles, estate-classify, the Agent Jack app and Google Chrome (AJ-CHROME-01 FAIL). Recommended: both plans (ChatGPT Plus + Claude Pro) signed in, both apps, both Local labs in T3, the Chrome extensions. Optional: the T3 Code mobile app. Hardware below M3 / 16 GB / 512 GB is only AJ-HW-01 WARN.
- **Driver:** you are Codex or Claude Code. Signing in to both is recommended; doctor gives WARN for the one that is signed out, and FAIL for both when neither is signed in. In the Codex app, work in `~/Developer`, let the user approve each network or out-of-folder command (including every `bin/doctor.sh` run: inside the sandbox it reports AJ-DOC-01), and never switch to **Full access**.
- Fresh install: `bin/install.sh all` (Codex CLI, Claude CLI, T3 Code TPLUS, Tentacles, estate-classify; optionally `bin/install.sh guardian` for the guard checkout), then the manual app steps in `SETUP-PROMPT.md` steps 5–6 (Local → Codex or Claude Code) and the optional mobile step 8 (pairing with T3 Code TPLUS is unproven).
- Roll back: `bin/rollback.sh <setup-tag>` (tags in `VERSIONS.md`).
- Remove: `bin/uninstall.sh` (lists first; deletes only with `--yes`).
- Windows: no scripts yet (unproven). Follow `SETUP-PROMPT-WINDOWS.md` and report with its DOCTOR block.

## What to give the user at the end
Give the output of `bin/doctor.sh`: no secrets, no e-mails, home paths shown as `~`. The user pastes it into a reply to their welcome e-mail.
