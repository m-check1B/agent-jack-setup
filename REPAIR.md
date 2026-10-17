# REPAIR: one fix per FAIL code

Run `bin/doctor.sh`, find the code, apply the fix (ask the user before any change), then verify with `bin/doctor.sh`. If a code is missing here, or the fix doesn't work: stop and report the doctor output. This file grows from real cases, and every new real problem gets a code.

| Code | Meaning | Fix | Verify |
|---|---|---|---|
| AJ-BAK-01 (WARN) | No recent Time Machine backup (or doctor can't see it) | The user backs up their data before AI runs on the computer: Time Machine (System Settings → General → Time Machine) or a copy of important folders off the computer. If the backup lives elsewhere, the user confirms it and you continue. Never change backup settings yourself | doctor AJ-BAK-00, or the user's confirmation |
| AJ-DISK-01 (WARN) | Less than 20 GB free | Free space; the agent ASKS before each step and touches only what this setup or its tools created: `brew cleanup`, `npm cache clean --force`, `~/.agent-jack/` caches, Tentacles/T3 logs, old agent worktrees that the user confirms are finished. **Never delete the user's own files**; suggest the user empty the Trash or move large folders themselves | doctor AJ-DISK-00 |
| AJ-DISK-02 | Less than 5 GB free: install refuses to start | Same safe cleanups as AJ-DISK-01, then re-run. If it's still under 5 GB, stop: the user frees space themselves | doctor |
| AJ-PIN-00 | A pin in versions.env is not published yet | Nothing to fix locally. Tell the user the setup isn't released yet and stop. | — |
| AJ-SYS-01 | macOS older than the minimum | Update macOS via System Settings → General → Software Update (the user does it). | doctor AJ-SYS-00 |
| AJ-BREW-01 | Homebrew missing | Send the user to https://brew.sh. The user runs the installer and types the password, then runs the two "Next steps" PATH lines. | `brew -v` |
| AJ-NODE-01 / AJ-NODE-02 | Node.js missing or too old | `brew install node` (or `brew upgrade node`) | `node -v` ≥ 22 |
| AJ-GIT-01 | git missing | `xcode-select --install` (the user confirms the dialog) | `git --version` |
| AJ-NPM-01 | `EACCES` on npm install -g | Never sudo. `mkdir -p ~/.npm-global && npm config set prefix ~/.npm-global`, add `export PATH="$HOME/.npm-global/bin:$PATH"` to `~/.zshrc`, open a new terminal, re-run the install | re-run the failed install |
| AJ-CLAUDE-01 | Claude Code CLI missing | `bin/install.sh claude` | doctor AJ-CLAUDE-00 |
| AJ-CLAUDE-02 | Claude Code CLI older than the minimum | `bin/install.sh claude` (or `claude update`) | doctor |
| AJ-CLAUDE-03 | CLI signed out | The user runs `claude auth login` and signs in with their Claude Pro account | `claude auth status` |
| AJ-ENV-01 | A shell file or the environment sets ANTHROPIC_BASE_URL / ANTHROPIC_AUTH_TOKEN / ANTHROPIC_API_KEY. It silently overrides your Claude sign-in (e.g. another provider), and `claude -p` can hang | Show the user the file and line name (never the value). With their OK, comment out that line, open a new terminal and re-run doctor. Never copy or print the value | doctor AJ-ENV-00 |
| AJ-CLAUDE-04 | `claude -p "Reply with exactly: OK"` gave no OK within 60 s (only tested once signed in) | Fix AJ-CLAUDE-03 and AJ-ENV-01 first. Then the user runs `claude auth logout && claude auth login` (over ssh: open the link, paste the code into the same terminal) and re-runs doctor | doctor AJ-CLAUDE-05 |
| AJ-BROWSER-01 (manual) | Claude Code reports "no connected browser" | BROWSER.md: install the official Claude in Chrome extension (publisher Anthropic) in the right Chrome profile, pin it via 🧩, and sign in with the SAME Claude account as Claude Code. After an account switch, reinstall it | Claude Code lists ≥1 connected browser |
| AJ-CODEX-01 (optional) | Codex CLI is signed out | The user runs `codex login` themselves | `codex login status` |
| AJ-T3-01 | T3 Code missing | `bin/install.sh t3` | doctor AJ-T3-00 |
| AJ-T3-02 | T3 Code version ≠ pin (often after an upstream update) | `bin/install.sh t3` (quits T3, reinstalls the pinned fork) | doctor |
| AJ-T3-05 (manual) | macOS says T3 Code TPLUS "can't be opened" / unidentified developer | The build isn't notarized yet. The user right-clicks the app → **Open**, or System Settings → Privacy & Security → **Open Anyway**. Never disable Gatekeeper | the app opens |
| AJ-T3-03 | T3 download, dmg mount or copy failed (network, release not reachable, or no write access) | Retry once. If it fails again, do NOT look for the file elsewhere: stop and report | doctor AJ-T3-00 |
| AJ-T3-04 | Downloaded T3 doesn't match the checksum | Don't install. Delete the download and retry once. If it fails again, stop and report | — |
| AJ-TENT-01 | Tentacles missing | `bin/install.sh tentacles` | `tentacles --version` |
| AJ-TENT-02 | Tentacles version ≠ pin | `bin/install.sh tentacles` | doctor |
| AJ-TENT-03 | `tentacles doctor` not ready (often "T3 token file … missing" until T3 Code TPLUS has been opened once) | Make sure T3 Code TPLUS is running and Claude Code is signed in to it (T3 → Settings → Providers), then re-run doctor. If it's still not ready, stop and report | doctor AJ-TENT-00 |
| AJ-PY-01 | Python older than 3.11 (macOS ships 3.9) | `brew install python@3.12`, then `bin/install.sh classify` | `python3.12 --version` |
| AJ-EC-01 | estate-classify (classifier + router for Tentacles) not installed | `bin/install.sh classify` (venv in `~/.agent-jack/venv`) | doctor AJ-EC-00 |
| AJ-EC-02 | estate-classify version ≠ pin | `bin/install.sh classify` | doctor |
| AJ-EC-03 | estate-classify smoke test fails | `rm -rf ~/.agent-jack/venv` and run `bin/install.sh classify` again. If it still fails, stop and report | doctor AJ-EC-00 |
| AJ-EG-02 | Optional guard checkout off-pin | `bin/install.sh guardian`, or remove it with `rm -rf ~/Developer/estate-guardian` (it's optional) | doctor |
| AJ-JACK-02 | Agent Jack app older than the minimum | The app updates itself; or download it again from https://agentjack.kraliki.com/downloads while signed in | doctor AJ-JACK-00 |
| AJ-JACK-01 | Agent Jack app missing | The user signs in at https://agentjack.kraliki.com/app, downloads from /downloads and drags it to Applications (SETUP-PROMPT step 5) | doctor AJ-JACK-00 |
| AJ-PAIR-00 (manual) | Not paired | In the app: Settings → Computers & labs → Pair / **Repair now** | "Paired · ready" |
| AJ-LOCAL-00 (manual) | Local Bot doesn't answer ("The turn failed", "Pairer offer is expired") | **Repair now**, then on the Bot pick Provider → Local → Claude Code → **Start new session**. If it still fails, switch the Bot to Server and report | Bot replies |

## Real cases
(none yet: the first pilot starts in October 2026)
