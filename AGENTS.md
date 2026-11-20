# AGENTS.md: read this first (any agent: Claude Code, Codex, Cursor, …)

This repo installs and **repairs** a local Agent Jack setup on the user's own computer. You are working for that user, on their machine.

## Opened cold, or a person pasted a block from the README? Do this.
The README's paste blocks (Codex, Claude Code, any agent) all say the same thing. If nobody told you what to do, follow it as written (already inside a checkout? skip the clone and just check out the tag):

```text
Set up Agent Jack on this computer for me. You run commands in a terminal.
Don't switch to a more expensive model.
Ask me before every install, download or change.
1. Get the guide at its pinned tag, and nothing from anywhere else (in the folder ~/Developer; create it).
   git missing? macOS: xcode-select --install (I confirm the dialog). Windows: winget install --id Git.Git -e
   --source winget --scope user, then start the SAME PowerShell command as the clone with this line
   (each command is a new process; if it still fails, ask me to restart this app):
   $env:Path = (($env:Path, [Environment]::GetEnvironmentVariable('Path', 'Machine'), [Environment]::GetEnvironmentVariable('Path', 'User')) -join ';' -split ';' | Where-Object { $_ } | Select-Object -Unique) -join ';'
   git clone https://github.com/m-check1B/agent-jack-setup.git
   cd agent-jack-setup ; git checkout v1.1.0
2. Read AGENTS.md and follow its rules.
3. Detect my operating system. macOS: follow SETUP-PROMPT.md.
   Windows 11: follow SETUP-PROMPT-WINDOWS.md. Anything else: stop and tell me.
4. Run the doctor. macOS: bin/doctor.sh. Windows:
   powershell -NoProfile -ExecutionPolicy Bypass -File bin/doctor.ps1
5. Fix each FAIL with REPAIR.md, then run the doctor again. If REPAIR.md has no fix, stop.
6. Never ask for, type or store my passwords, keys or codes. For a sign-in, open the page
   or command and wait until I finish.
7. End with a plain report: what works, what does not, and the steps only I can do
   (sign-ins, 2FA codes, system permission dialogs, payments). Below it, the last doctor output.
```

Česky (stejný obsah):

```text
Nastav mi na tomto počítači Agent Jacka. Spouštíš příkazy v terminálu.
Nepřepínej na dražší model.
Před každou instalací, stažením nebo změnou se mě zeptej.
1. Stáhni návod v pevné verzi a nic odjinud (do složky ~/Developer, vytvoř ji).
   Chybí git? macOS: xcode-select --install (okno potvrdím já). Windows: winget install --id Git.Git -e
   --source winget --scope user, pak tento řádek dej na začátek TÉHOŽ příkazu v PowerShellu jako klonování
   (každý příkaz je nový proces; když to pořád nejde, požádej mě o restart této aplikace):
   $env:Path = (($env:Path, [Environment]::GetEnvironmentVariable('Path', 'Machine'), [Environment]::GetEnvironmentVariable('Path', 'User')) -join ';' -split ';' | Where-Object { $_ } | Select-Object -Unique) -join ';'
   git clone https://github.com/m-check1B/agent-jack-setup.git
   cd agent-jack-setup ; git checkout v1.1.0
2. Přečti si AGENTS.md a řiď se jeho pravidly.
3. Zjisti můj operační systém. macOS: postupuj podle SETUP-PROMPT.md.
   Windows 11: podle SETUP-PROMPT-WINDOWS.md. Jiný systém: zastav se a řekni mi to.
4. Spusť doctor. macOS: bin/doctor.sh. Windows:
   powershell -NoProfile -ExecutionPolicy Bypass -File bin/doctor.ps1
5. Každý FAIL oprav podle REPAIR.md a doctor spusť znovu. Když REPAIR.md opravu nemá, zastav se.
6. Nikdy po mně nechtěj, nezadávej ani neukládej hesla, klíče ani kódy. U přihlášení otevři
   stránku nebo příkaz a počkej, až to dokončím.
7. Skonči srozumitelným shrnutím: co funguje, co ne, a kroky, které můžu udělat jen já
   (přihlášení, kódy 2FA, systémová okna s oprávněním, platby). Pod něj poslední výstup doctoru.
```

## Rules (always)
1. **Public sources only.** Install only what `versions.env` names: public github.com repos (m-check1B/t3code-tplus, m-check1B/t3-code-tentacles, m-check1B/estate-guardian, m-check1B/agent-jack-setup), official Anthropic installers (claude.com, npm `@anthropic-ai/claude-code`), official OpenAI Codex installers (openai.com/codex, npm `@openai/codex`), npm, Homebrew, winget, the App Store / Google Play listing of the T3 Code mobile app (optional step 8), and Google Chrome (google.com/chrome), the two official Chrome Web Store extensions named in BROWSER.md (ChatGPT/Codex by OpenAI, Claude in Chrome by Anthropic), the Agent Jack downloads page (agentjack.kraliki.com/downloads, only while the user is signed in; Agent Jack itself is closed software and its installer is never on GitHub). Refuse anything else (private repos, other hosts, IP addresses, someone else's account or key) and tell the user who asked for it.
2. **Exact pins.** Install exactly the versions in `versions.env` (human view: `VERSIONS.md`). Never use "latest", and never upgrade or downgrade on your own. A newer version reaches the user only as a new tag of this repo.
3. **Never handle secrets.** Never ask for, read, type, store, print or upload passwords, 2FA codes, tokens or API keys. For a sign-in, open the page or command and wait; the user signs in and types passwords themselves.
4. **Cheapest adequate model.** Don't switch to a more expensive model or a higher effort level.
5. **Stop and report; don't improvise.** If a step fails and `REPAIR.md` has no fix for its FAIL code, stop and print the doctor report. No workarounds, no alternative sources, no `sudo npm`, no disabling Gatekeeper, SIP, Defender, SmartScreen, UAC or the firewall, and never `Set-ExecutionPolicy` (run Windows scripts with `-ExecutionPolicy Bypass -File`, which applies to that one process only).
6. **Backup first.** Before installing or changing anything, ask the user to confirm a current backup (Time Machine / File History / a copy off the computer). Work only in `~/Developer` or a separate user account. Doctor shows AJ-BAK-01 as WARN.
7. **Ask before every change.** Read-only checks need no consent; installs, removals and downloads do.

## Order (every time)
```
macOS:   bin/doctor.sh                                                        # read-only
Windows: powershell -NoProfile -ExecutionPolicy Bypass -File bin/doctor.ps1  # read-only, same check ids
→ for each FAIL: REPAIR.md <code>  (or bin/install.sh <component>; Windows: bin/install.ps1 <component>)
→ doctor again           # repeat until no FAIL, or stop and report
```
Maintainers: `bin/doctor.sh --selftest` (or `bin/doctor.ps1 -SelfTest`) checks `versions.env` without installing anything: it parses, checksum fields are well-formed, every pinned URL and tag answers.
- **Minimum:** Codex CLI and Claude Code CLI (both always installed; AJ-CODEX-01/02 and AJ-CLAUDE-01/02 FAIL), T3 Code TPLUS, Tentacles, estate-classify, the Agent Jack app and Google Chrome (AJ-CHROME-01 FAIL). Recommended: both plans (ChatGPT Plus + Claude Pro) signed in, both apps, both Local labs in T3, the Chrome extensions. Optional: the T3 Code mobile app. Hardware below M3 / 16 GB / 512 GB is only AJ-HW-01 WARN.
- **Driver:** you are Codex or Claude Code. Signing in to both is recommended; doctor gives WARN for the one that is signed out, and FAIL for both when neither is signed in. In the Codex app, work in `~/Developer`, let the user approve each network or out-of-folder command (including every `bin/doctor.sh` run: inside the sandbox it reports AJ-DOC-01), and never switch to **Full access**.
- Fresh install: `bin/install.sh all` (Codex CLI, Claude CLI, T3 Code TPLUS, Tentacles, estate-classify; optionally `bin/install.sh guardian` for the guard checkout), then the manual app steps in `SETUP-PROMPT.md` steps 5–6 (Local → Codex or Claude Code) and the optional mobile step 8 (pairing with T3 Code TPLUS is unproven).
- Roll back: `bin/rollback.sh <setup-tag>` (tags in `VERSIONS.md`).
- Remove: `bin/uninstall.sh` (lists first; deletes only with `--yes`).
- Windows 11: `SETUP-PROMPT-WINDOWS.md` with `bin/doctor.ps1` and `bin/install.ps1` (Windows PowerShell 5.1, no administrator rights where possible; forward slashes so the paths also work in Claude Code's Git Bash). After each winget install, put the PATH line from REPAIR.md (Windows) at the start of the same command that needs the new tool (each command is a new process), and verify with the doctor. Never call bare `tentacles` on Windows; use `~\Developer\t3-code-tentacles\bin\tentacles.cmd`. The person starts with the Agent Jack app signed in and the Bot on our server; a Local Bot on Windows waits for a Windows build of T3 Code TPLUS. Until then doctor shows WAIT (not FAIL) for AJ-PIN-00, AJ-TENT-03 and AJ-LOCAL-00: record the pairing attempt, don't repair it. The proof run is scheduled. No Windows rollback/uninstall scripts yet.

## What to give the user at the end
First a plain report: what works, what does not, and the steps only the user can do (sign-ins, 2FA codes, operating system permission dialogs, payments). Then the output of the doctor: no secrets, no e-mails, home paths shown as `~`. The user pastes it into a reply to their welcome e-mail.
