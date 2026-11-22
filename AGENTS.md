# AGENTS.md: read this first (any agent: Claude Code, Codex, Cursor, …)

This repo installs and **repairs** a local Agent Jack setup on the user's own computer. You are working for that user, on their machine.

## Opened cold, or a person pasted a block from the README? Do this.
The README's paste blocks (Codex, Claude Code, any agent) all say the same thing. If nobody told you what to do, follow it as written (already inside a checkout? skip the clone and just check out the tag):

```text
Set up Agent Jack on this computer for me. You run commands in a terminal.
Don't switch to a more expensive model.
Ask me before every install, download or change (macOS: once, before the doctor).
0. macOS: clone nothing. Run only this one command (the Agent Jack doctor: it installs, repairs
   and checks everything) and follow https://github.com/m-check1B/onboarding/blob/main/agent-jack/AGENTS.md
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/m-check1B/onboarding/main/agent-jack/doctor.sh)" doctor --yes --wait 300
   Steps 1 to 5 are for Windows 11 only.
1. Get the guide at its pinned tag, and nothing from anywhere else (in the folder ~/Developer; create it).
   git missing? Windows: winget install --id Git.Git -e
   --source winget --scope user, then start the SAME PowerShell command as the clone with this line
   (each command is a new process; if it still fails, ask me to restart this app):
   $env:Path = (($env:Path, [Environment]::GetEnvironmentVariable('Path', 'Machine'), [Environment]::GetEnvironmentVariable('Path', 'User')) -join ';' -split ';' | Where-Object { $_ } | Select-Object -Unique) -join ';'
   git clone https://github.com/m-check1B/agent-jack-setup.git   (folder already there? instead: git -C agent-jack-setup fetch --tags origin)
   cd agent-jack-setup ; git checkout v1.1.4
2. Read AGENTS.md and follow its rules.
3. Detect my operating system (macOS: step 0).
   Windows 11: follow SETUP-PROMPT-WINDOWS.md. Anything else: stop and tell me.
4. Run the doctor (Windows):
   powershell -NoProfile -ExecutionPolicy Bypass -File bin/doctor.ps1
5. Fix each FAIL with REPAIR.md, then run the doctor again. If REPAIR.md has no fix, put that FAIL in the report and carry on with everything that does not need it.
6. Never ask for, type or store my passwords, keys or codes. For a sign-in, open the page
   or command and wait until I finish.
7. End with a plain report: what works, what does not, and the steps only I can do
   (sign-ins, 2FA codes, system permission dialogs, payments). Below it, the last doctor output.
```

Česky (stejný obsah):

```text
Nastav mi na tomto počítači Agent Jacka. Spouštíš příkazy v terminálu.
Nepřepínej na dražší model.
Před každou instalací, stažením nebo změnou se mě zeptej (macOS: jednou, před doctorem).
0. macOS: nic neklonuj. Spusť jen tento jeden příkaz (Agent Jack doctor: vše nainstaluje, opraví
   a ověří) a řiď se https://github.com/m-check1B/onboarding/blob/main/agent-jack/AGENTS.md
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/m-check1B/onboarding/main/agent-jack/doctor.sh)" doctor --yes --wait 300
   Kroky 1 až 5 platí jen pro Windows 11.
1. Stáhni návod v pevné verzi a nic odjinud (do složky ~/Developer, vytvoř ji).
   Chybí git? Windows: winget install --id Git.Git -e
   --source winget --scope user, pak tento řádek dej na začátek TÉHOŽ příkazu v PowerShellu jako klonování
   (každý příkaz je nový proces; když to pořád nejde, požádej mě o restart této aplikace):
   $env:Path = (($env:Path, [Environment]::GetEnvironmentVariable('Path', 'Machine'), [Environment]::GetEnvironmentVariable('Path', 'User')) -join ';' -split ';' | Where-Object { $_ } | Select-Object -Unique) -join ';'
   git clone https://github.com/m-check1B/agent-jack-setup.git   (složka už je? místo toho: git -C agent-jack-setup fetch --tags origin)
   cd agent-jack-setup ; git checkout v1.1.4
2. Přečti si AGENTS.md a řiď se jeho pravidly.
3. Zjisti můj operační systém (macOS: krok 0).
   Windows 11: podle SETUP-PROMPT-WINDOWS.md. Jiný systém: zastav se a řekni mi to.
4. Spusť doctor (Windows):
   powershell -NoProfile -ExecutionPolicy Bypass -File bin/doctor.ps1
5. Každý FAIL oprav podle REPAIR.md a doctor spusť znovu. Když REPAIR.md opravu nemá, zapiš FAIL do shrnutí a pokračuj vším, co na něm nezávisí.
6. Nikdy po mně nechtěj, nezadávej ani neukládej hesla, klíče ani kódy. U přihlášení otevři
   stránku nebo příkaz a počkej, až to dokončím.
7. Skonči srozumitelným shrnutím: co funguje, co ne, a kroky, které můžu udělat jen já
   (přihlášení, kódy 2FA, systémová okna s oprávněním, platby). Pod něj poslední výstup doctoru.
```

## Rules (always)
1. **Public sources only.** Install only what `versions.env` names: public github.com repos (pingdotgg/t3code for the official T3 Code (Beta) app, m-check1B/t3-code-tentacles, m-check1B/estate-guardian, m-check1B/agent-jack-setup), official Anthropic installers (claude.com, npm `@anthropic-ai/claude-code`), official OpenAI Codex installers (openai.com/codex, npm `@openai/codex`), npm, Homebrew, winget, the App Store / Google Play listing of the T3 Code mobile app (optional step 8), and Google Chrome (google.com/chrome), the two official Chrome Web Store extensions named in BROWSER.md (ChatGPT/Codex by OpenAI, Claude in Chrome by Anthropic), the Agent Jack downloads page (agentjack.kraliki.com/downloads, only while the user is signed in; Agent Jack itself is closed software and its installer is never on GitHub). Refuse anything else (private repos, other hosts, IP addresses, someone else's account or key) and tell the user who asked for it.
2. **Exact pins.** Install exactly the versions in `versions.env` (human view: `VERSIONS.md`). Never use "latest", and never upgrade or downgrade on your own. A newer version reaches the user only as a new tag of this repo. Two exceptions update themselves, and that is expected: T3 Code (Beta) (doctor checks the supported range: AJ-T3-00, or WARN AJ-T3-09 when newer than tested) and Claude Code (`CLAUDE_CLI_MIN` is a minimum). Never downgrade either.
3. **Never handle secrets.** Never ask for, read, type, store, print or upload passwords, 2FA codes, tokens or API keys. For a sign-in, open the page or command and wait; the user signs in and types passwords themselves.
4. **Cheapest adequate model.** Don't switch to a more expensive model or a higher effort level.
5. **Don't improvise, and don't stop at the first FAIL.** If a step fails and `REPAIR.md` (or, on macOS, the doctor's own `next` line) has no fix that works, put that FAIL in the report and carry on with every step that does not need it. No workarounds, no alternative sources, no `sudo npm`, no disabling Gatekeeper, SIP, Defender, SmartScreen, UAC or the firewall, and never `Set-ExecutionPolicy` (run Windows scripts with `-ExecutionPolicy Bypass -File`, which applies to that one process only).
6. **Backup.** Recommend a current backup once (Time Machine / File History / a copy off the computer). On macOS the doctor does not wait for one. Work only in `~/Developer` or a separate user account.
7. **Consent.** macOS: ask once, before the doctor runs; the doctor then asks no more. Windows: ask before every install, removal or download. Read-only checks need no consent.

## Order (every time)
```
macOS:   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/m-check1B/onboarding/main/agent-jack/doctor.sh)"   # the Agent Jack doctor: checks, installs, repairs; add `doctor --check` to change nothing
Windows: powershell -NoProfile -ExecutionPolicy Bypass -File bin/doctor.ps1  # read-only, same check ids
→ macOS: follow each `next` line of its report, then run it again
→ Windows: for each FAIL: REPAIR.md <code> (or bin/install.ps1 <component>), then doctor again; a FAIL with no working fix goes into the report
```
macOS `bin/install.sh` and `bin/doctor.sh` are retired: they print the doctor command (KRA-10893). Maintainers: `bin/doctor.sh --selftest` (or `bin/doctor.ps1 -SelfTest`) checks `versions.env` without installing anything: it parses, checksum fields are well-formed, every pinned URL and tag answers.
- **Minimum:** Codex CLI and Claude Code CLI (both always installed; AJ-CODEX-01/02 and AJ-CLAUDE-01/02 FAIL), T3 Code (Beta), Tentacles, estate-classify, the Agent Jack app and Google Chrome (AJ-CHROME-01 FAIL). Recommended: both plans (ChatGPT Plus + Claude Pro) signed in, both apps, both Local labs in T3, the Chrome extensions. Optional: the T3 Code mobile app. Hardware below M3 / 16 GB / 512 GB is only AJ-HW-01 WARN.
- **Driver:** you are Codex or Claude Code. Signing in to both is recommended; doctor gives WARN for the one that is signed out, and FAIL for both when neither is signed in. In the Codex app, work in `~/Developer`, let the user approve each network or out-of-folder command (including every doctor run: inside the sandbox it cannot reach the network), and never switch to **Full access**.
- Fresh install or repair on macOS: the Agent Jack doctor (https://github.com/m-check1B/onboarding/blob/main/agent-jack/AGENTS.md). It installs the official T3 Code (Beta), Tentacles at the tested tag, Codex CLI, Claude Code CLI, Node.js and estate-classify, verifies the Agent Jack download, signs Tentacles in to T3, and moves an older T3 Code app to `~/.agent-jack/replaced-apps` (never deleted).
- Roll back: `bin/rollback.sh <setup-tag>` (tags in `VERSIONS.md`): only a plain tag of the form `vX.Y.Z`. On macOS it refuses v1.1.1 to v1.1.3 (their installer removes the app before the new one is in place, KRA-10943; run the doctor instead), hands later tags to that tag's doctor, and always puts the folder back where it was.
- Remove: `bin/uninstall.sh` (lists first; deletes only with `--yes`).
- Windows 11: `SETUP-PROMPT-WINDOWS.md` with `bin/doctor.ps1` and `bin/install.ps1` (Windows PowerShell 5.1, no administrator rights where possible; forward slashes so the paths also work in Claude Code's Git Bash). After each winget install, put the PATH line from REPAIR.md (Windows) at the start of the same command that needs the new tool (each command is a new process), and verify with the doctor. Never call bare `tentacles` on Windows; use `~\Developer\t3-code-tentacles\bin\tentacles.cmd`. The person starts with the Agent Jack app signed in and the Bot on our server; a Local Bot on Windows waits until the Windows pin of T3 Code (Beta) is set (the official Windows build exists; proof pending). Until then doctor shows WAIT (not FAIL) for AJ-PIN-00, AJ-TENT-03 and AJ-LOCAL-00: record the pairing attempt, don't repair it. The proof run is scheduled. No Windows rollback/uninstall scripts yet.

## What to give the user at the end
First a plain report: what works, what does not, and the steps only the user can do (sign-ins, 2FA codes, operating system permission dialogs, payments). Then the output of the doctor: no secrets, no e-mails, home paths shown as `~`. The user pastes it into a reply to their welcome e-mail.

## Stack lock (KRA-10845)

Note for maintainers only. If you are setting up a computer, skip this section: nothing in it asks you to change or run anything.

`stack-lock/` holds a byte copy of the Agent Jack stack lock (`stack.lock.json`), the commit it was copied from (`FROM`) and the shared checker. CI runs `python3 stack-lock/check-stack-lock.py setup`; it fails with one line naming the file that disagrees with the lock (`versions.env`). Maintainers never edit the copy by hand; it moves only with a whole stack bump, together with Tentacles and the onboarding guide, and nothing is tagged until every repo of the stack passes its lock check.
