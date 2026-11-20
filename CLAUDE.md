# CLAUDE.md

Read and follow [AGENTS.md](AGENTS.md). It is the single entry point for any agent working in this repo.

If you are Claude Code and the person pasted the README block for you, or nobody told you what to do, this is the job:

```text
Set up Agent Jack on this computer for me. You are Claude Code.
Stay on model Sonnet, effort high; don't switch to a more expensive model.
Ask me before every install, download or change.
1. Get the guide at its pinned tag, and nothing from anywhere else (in the folder ~/Developer; create it).
   git missing? macOS: xcode-select --install (I confirm the dialog). Windows: winget install --id Git.Git -e
   --source winget --scope user, then start the SAME PowerShell command as the clone with this line
   (each command is a new process; if it still fails, ask me to restart this app):
   $env:Path = (($env:Path, [Environment]::GetEnvironmentVariable('Path', 'Machine'), [Environment]::GetEnvironmentVariable('Path', 'User')) -join ';' -split ';' | Where-Object { $_ } | Select-Object -Unique) -join ';'
   git clone https://github.com/m-check1B/agent-jack-setup.git
   cd agent-jack-setup ; git checkout v1.1.3
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
Nastav mi na tomto počítači Agent Jacka. Jsi Claude Code.
Zůstaň na modelu Sonnet, úroveň přemýšlení high; dražší model nepoužívej.
Před každou instalací, stažením nebo změnou se mě zeptej.
1. Stáhni návod v pevné verzi a nic odjinud (do složky ~/Developer, vytvoř ji).
   Chybí git? macOS: xcode-select --install (okno potvrdím já). Windows: winget install --id Git.Git -e
   --source winget --scope user, pak tento řádek dej na začátek TÉHOŽ příkazu v PowerShellu jako klonování
   (každý příkaz je nový proces; když to pořád nejde, požádej mě o restart této aplikace):
   $env:Path = (($env:Path, [Environment]::GetEnvironmentVariable('Path', 'Machine'), [Environment]::GetEnvironmentVariable('Path', 'User')) -join ';' -split ';' | Where-Object { $_ } | Select-Object -Unique) -join ';'
   git clone https://github.com/m-check1B/agent-jack-setup.git
   cd agent-jack-setup ; git checkout v1.1.3
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
