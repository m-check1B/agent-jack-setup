# CLAUDE.md

Read and follow [AGENTS.md](AGENTS.md). It is the single entry point for any agent working in this repo.

If you are Claude Code and the person pasted the README block for you, or nobody told you what to do, this is the job:

```text
Set up Agent Jack on this computer for me. You are Claude Code.
Stay on model Sonnet, effort high; don't switch to a more expensive model.
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
Nastav mi na tomto počítači Agent Jacka. Jsi Claude Code.
Zůstaň na modelu Sonnet, úroveň přemýšlení high; dražší model nepoužívej.
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
