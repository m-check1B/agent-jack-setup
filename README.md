# Agent Jack: nastavení / setup

[Česky](#česky) · [English](#english)

---

## Česky

**Agent Jack** je pracovní AI asistent. Píšete mu běžnou řečí a jeho Boti připraví texty, dohledají informace, rozdělí si práci a hlídají, co jim svěříte. Běží na našem serveru a volitelně i přímo na vašem počítači.

Tento repozitář obsahuje vše, co k nastavení potřebujete. Všechny nástroje v něm pocházejí z veřejných zdrojů.

### Nejrychlejší cesta: vložte to svému AI
Používáte už Codex, Claude Code nebo jiného AI agenta? Nejdřív si zálohujte data (bod 0) a přihlaste se na webu (bod 1). Pak zkopírujte **jeden** blok podle svého asistenta, vložte ho tam a odešlete. Agent si stáhne tento návod v pevné verzi, zjistí váš systém, nainstaluje a zkontroluje vše potřebné, opraví, co nejde, a na konci vám napíše, co funguje a co musíte udělat sami (přihlášení, kódy 2FA, systémová okna s oprávněním, platby). Hesla ani kódy po vás chtít nesmí.

**Codex (aplikace Codex nebo `codex` v terminálu)**
```text
Nastav mi na tomto počítači Agent Jacka. Jsi Codex.
Pracuj ve složce ~/Developer, oprávnění nech na „Ask for approval“, nikdy Full access.
Před každou instalací, stažením nebo změnou se mě zeptej; síťové příkazy jen s mým schválením.
1. Stáhni návod v pevné verzi a nic odjinud (do složky ~/Developer, vytvoř ji).
   Chybí git? macOS: xcode-select --install (okno potvrdím já). Windows: winget install --id Git.Git -e
   --source winget --scope user, pak tento řádek dej na začátek TÉHOŽ příkazu v PowerShellu jako klonování
   (každý příkaz je nový proces; když to pořád nejde, požádej mě o restart této aplikace):
   $env:Path = (($env:Path, [Environment]::GetEnvironmentVariable('Path', 'Machine'), [Environment]::GetEnvironmentVariable('Path', 'User')) -join ';' -split ';' | Where-Object { $_ } | Select-Object -Unique) -join ';'
   git clone https://github.com/m-check1B/agent-jack-setup.git
   cd agent-jack-setup ; git checkout v1.1.2
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

**Claude Code (aplikace Claude → záložka Code, nebo `claude` v terminálu)**
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
   cd agent-jack-setup ; git checkout v1.1.2
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

**Jiný AI agent (Cursor, Gemini CLI, …), který umí spouštět příkazy v terminálu**
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
   cd agent-jack-setup ; git checkout v1.1.2
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

### 0. Nejdřív záloha a místo na disku
**Než pustíte AI na svůj počítač, zálohujte si data** (Time Machine / Historie souborů / kopie důležitých složek mimo počítač). Doporučujeme agentům dát samostatný uživatelský účet nebo aspoň samostatnou složku (např. `~/Developer`). Před prvním spuštěním: **záloha + dost místa na disku** (viz níže).

### Místo na disku
Měřeno na reálné instalaci (Mac, říjen 2026): Claude Code CLI ≈ 0,4 GB, Codex CLI ≈ 0,3 GB, T3 Code (Beta) ≈ 0,55 GB (aplikace 0.1.11 na Macu s Apple Silicon, změřeno 20. 11. 2026), Tentacles ≈ 25 MB, estate-guardian (venv) ≈ 15 MB, aplikace Agent Jack ≈ 0,4 GB, Homebrew + Node.js 1–2 GB (pokud je ještě nemáte). Samotná instalace tedy ≈ 2–3 GB, ale **agenti při práci rychle přidávají další data** (pracovní kopie, node_modules, logy, cache; datová složka T3 může narůst na ~10 GB). **Doporučujeme mít volných aspoň 20 GB**; pod 5 GB instalace nezačne.

### Doporučený hardware
Mac s čipem **Apple M3 nebo novějším**, **16 GB RAM** a **disk 512 GB**. Na slabším Macu (Intel, M1/M2, méně paměti nebo menší disk) instalace proběhne, jen DOCTOR ukáže upozornění (WARN) a agenti poběží pomaleji.

### Kam s Agent Jackem
- **Mac M3+ / 16 GB / 512 GB** je doporučený pro roli osobního asistenta a jako hlavní zařízení stačí.
- **Další krok pro firmu:** vlastní hlavní linuxový server a k němu další koncová zařízení stejného typu.
- **Mac má přednost před Windows** a **notebook (MacBook) před Macem mini**, protože ho máte stále s sebou.
- **Mobil:** aplikace Agent Jack pro iPhone a CarPlay je v testování, spuštění plánujeme do 1. prosince 2026.

### Co dnes dostanete na Macu a na Windows
| | Mac | Windows 11 |
|---|---|---|
| Aplikace Agent Jack | **podepsaná a notarizovaná** (Apple), otevře se bez varování | instalátor je zatím **nepodepsaný**, proto Windows ukáže SmartScreen „Systém Windows ochránil váš počítač“: klikněte na **Další informace** → zkontrolujte název `AgentJack-Setup-…exe` → **Přesto spustit**. **Předtím** ověřte otisk: `Get-FileHash -Algorithm SHA256 "$HOME\Downloads\AgentJack-Setup-<verze>.exe"` se musí shodovat s hodnotou SHA-256 na stránce stažení |
| Kde ji stáhnout | **jen** v přihlášené webové aplikaci, https://agentjack.kraliki.com/downloads; nikdy z GitHubu | stejně |
| S čím začnete | aplikace Agent Jack + Bot na Local i na našem serveru | aplikace **Agent Jack**, přihlášená, s Botem na **našem serveru** (lab **Server · …**) |
| Bot na Local (na vašem počítači) | ano (Codex a Claude Code v T3 Code (Beta)) | **čeká, až ověříme T3 Code (Beta) pro Windows** (oficiální Windows verze existuje, naše pevná verze zatím není nastavená); do té doby Bot běží na našem serveru a doctor ukazuje WAIT (ne FAIL) |
| T3 Code (Beta) | oficiální aplikace z [pingdotgg/t3code](https://github.com/pingdotgg/t3code); instaluje ji `install.sh` a dál se aktualizuje sama | pevná verze pro Windows **zatím není nastavená** (ověření čeká); doctor ukazuje WAIT AJ-PIN-00 |
| Tentacles | ano | ano (pevný tag, propojený přes `npm link`, aby ho aplikace našla); připravený až s T3 Code (Beta) (do té doby WAIT AJ-TENT-03) |
| Codex CLI, Claude Code CLI, estate-classify, Chrome | ano | ano |
| Stav návodu | ověřená cesta | ověřovací běh naplánovaný; ověřeno dne: _<doplní se>_ |

### 1. Přihlášení do Agent Jacka (stačí prohlížeč)
1. Otevřete https://agentjack.kraliki.com/app
2. Zvolte **Google** a vyberte e-mail, na který vám přišla pozvánka. (Pokud jste od nás dostali e-mail a heslo, přihlaste se jimi.)
3. Otevře se úvodní průvodce a váš hlavní Bot. Napište mu třeba „Co umíš?“.
4. Když uvidíte hlášku, že váš účet Google tu zatím nemá přidělený přístup („no seat here“), přístup ještě není odemčený. Odpovězte na uvítací e-mail a my to vyřešíme.

### 2. Lokální nastavení (doporučeno)
Agent Jack může pouštět Boty i přímo na vašem počítači, přes vaše vlastní předplatné AI.

**Co získáte:** Codex a Claude Code (aplikace i příkazový řádek; běží jako dva laby „Local · Codex“ a „Local · Claude Code“), [T3 Code (Beta)](https://github.com/pingdotgg/t3code) (oficiální aplikace T3 Code: víc AI agentů vedle sebe), [Tentacles](https://github.com/m-check1B/t3-code-tentacles) (jeden agent řídí další), [estate-guardian (klasifikátor + router pro Tentacles)](https://github.com/m-check1B/estate-guardian) (rozhoduje, kterému agentovi práce patří; samotný hlídač je volitelný pro pokročilé) a aplikaci Agent Jack spárovanou s počítačem.

**Co budete mít:**

| | Povinné / doporučené minimum | Volitelné |
|---|---|---|
| Předplatné | **ChatGPT Plus** + **Claude Pro** (obě ≈ 20 USD měsíčně) | — |
| Agent | **Codex CLI** + aplikace Codex, **Claude Code CLI** + aplikace Claude; v T3 oba laby Local | — |
| Pracovní prostředí | **T3 Code (Beta)**, **Tentacles**, estate-guardian (klasifikátor) | samotný hlídač estate-guardian (pro pokročilé) |
| Agent Jack | **aplikace Agent Jack** spárovaná s počítačem | aplikace **T3 Code** na mobil / iPad (párování s T3 Code (Beta) zatím neověřené) |
| Prohlížeč | **Google Chrome** + doporučená rozšíření **Claude in Chrome** (Anthropic) a **ChatGPT** (OpenAI, pro Codex, pokud ho máte k dispozici: postupné zpřístupnění, nastavení pracovního prostoru); viz [BROWSER.md](BROWSER.md) | — |

**Náklady:** doporučené minimum jsou **obě předplatná, ≈ 2 × 20 USD měsíčně**:

| | **Codex (ChatGPT Plus)** | **Claude Code (Claude Pro)** |
|---|---|---|
| Předplatné | **ChatGPT Plus**, na https://openai.com/codex uvedeno za 499 Kč měsíčně (≈ 20 USD) | **Claude Pro**, 20 USD měsíčně, https://claude.com/pricing |
| Aplikace | **Codex** pro macOS: https://openai.com/codex → **Download for macOS** | **Claude**: https://claude.com/download |
| Když řídí instalaci | otevřete složku `~/Developer` (vytvořte ji) a oprávnění nechte na **Ask for approval** | záložka **Code**, model **Sonnet**, úroveň přemýšlení **high** |

Instalaci řídí **jedna** z obou aplikací, kterákoli. Když máte zatím jen jedno předplatné, instalace projde a DOCTOR u druhého ukáže upozornění (WARN); druhé přidáte později. Obě předplatná mají limity použití. Když limit vyčerpáte, aplikace napíše, kdy se obnoví (obvykle za několik hodin), a do té doby počkáte. Nic se automaticky nedoplácí, pokud si placené navýšení sami nezapnete. Bot na našem serveru běží dál. Dražší model ani vyšší úroveň přemýšlení nejsou potřeba.

**Postup:**
1. Kupte si obě předplatná (nebo zatím jedno), nainstalujte aplikace Codex a Claude a přihlaste se.
2. Vložte jeden z bloků výše (nejrychlejší cesta), nebo otevřete návod pro svůj systém, zkopírujte **celý** text, vložte ho do jedné z aplikací (Codex nebo Claude Code) a odešlete:
   - **Mac (ověřená cesta):** [SETUP-PROMPT.md](SETUP-PROMPT.md)
   - **Windows 11 (ověřovací běh naplánovaný; Bot zatím na našem serveru):** [SETUP-PROMPT-WINDOWS.md](SETUP-PROMPT-WINDOWS.md)
3. Agent vás provede krok za krokem, před každou změnou se zeptá a každý krok sám ověří. Hesla a přihlášení zadáváte vždy sami.
4. Na konci vypíše **DOCTOR report**. Zkopírujte ho do odpovědi na uvítací e-mail. Tak uvidíme, co funguje, aniž bychom potřebovali přístup k vašemu počítači.
5. Volitelně: aplikace **T3 Code** na mobil nebo iPad (návod krok 8). Párování s T3 Code (Beta) jsme zatím **neověřili**.

**Pevné verze:** instalujeme přesně tu kombinaci, kterou jsme sami otestovali ([VERSIONS.md](VERSIONS.md)). Kromě T3 Code (Beta) a Claude Code, které se aktualizují samy (doctor hlídá podporovaný rozsah T3 a minimální verzi Claude Code), se nic samo neaktualizuje; novou verzi vydáme jako nový tag tohoto repozitáře.

**Oprava:** když něco přestane fungovat, otevřete Codex nebo Claude Code a napište: „oprav mi nastavení Agent Jacka podle github.com/m-check1B/agent-jack-setup“. Agent spustí `bin/doctor.sh` (Windows: `bin/doctor.ps1`) a opraví chyby podle [REPAIR.md](REPAIR.md).

**Prohlížeč pro agenty:** Google Chrome je povinný; rozšíření Claude in Chrome (Anthropic) a ChatGPT (OpenAI, pro Codex) doporučujeme, viz [BROWSER.md](BROWSER.md). **Codex CLI i Claude Code CLI** jsou povinné a instaluje je `install.sh` (Windows: `install.ps1`) vždy. Doporučujeme přihlásit oba (`codex login` a `claude auth login`); každý zapne svůj lab („Local · Codex“, „Local · Claude Code“). S jedním přihlášeným instalace projde s upozorněním.

### Doporučené nástroje (volitelné)
Jen doporučení: `install.sh` je neinstaluje a DOCTOR je nekontroluje. Všechno z oficiálních zdrojů, s vlastním účtem.
| Nástroj | K čemu s Agent Jackem | Odkaz | Cena |
|---|---|---|---|
| **Linear** | úkoly a evidence práce; do Claude Code ho připojíte oficiálním MCP konektorem | https://linear.app · https://linear.app/docs/mcp | zdarma základní plán, placené týmové plány |
| **GitHub** | kód a repozitáře (i tento návod); příkaz `gh` přes `brew install gh` (Windows: `winget install --id GitHub.cli -e --source winget`) | https://github.com · https://cli.github.com | zdarma, placené plány pro týmy |
| **Thunderbird** | lokální poštovní klient: pošta zůstává na vašem počítači, takže s ní Claude může pracovat lokálně | https://www.thunderbird.net | zdarma |

### 3. Problém? Napište nám
Odpovězte na uvítací e-mail. Napište, u kterého kroku jste se zasekli, a přiložte DOCTOR report. Hesla ani klíče nikdy neposílejte.

**Podmínky:** Používáním aplikací souhlasíte s Podmínkami použití (https://verduona.com/podminky); zpracování údajů popisují Zásady ochrany osobních údajů (https://verduona.com/ochrana-udaju).

---

## English

**Agent Jack** is an AI work assistant. You write to it in plain language and its Bots draft texts, look things up, split the work and keep track of what you hand them. It runs on our server and, optionally, on your own computer.

This repository holds everything you need for setup. Every tool in it comes from a public source.

### Fastest path: paste this into your AI
Already using Codex, Claude Code or another AI agent? First back up your data (step 0) and sign in on the web (step 1). Then copy **one** block for your assistant, paste it there and send it. The agent fetches this guide at its pinned tag, detects your system, installs and checks everything, repairs what fails, and ends by telling you what works and what only you can do (sign-ins, 2FA codes, system permission dialogs, payments). It must never ask for your passwords or codes.

**Codex (the Codex app, or `codex` in a terminal)**
```text
Set up Agent Jack on this computer for me. You are Codex.
Work in the folder ~/Developer, keep permissions on "Ask for approval", never Full access.
Ask me before every install, download or change; run network commands only with my approval.
1. Get the guide at its pinned tag, and nothing from anywhere else (in the folder ~/Developer; create it).
   git missing? macOS: xcode-select --install (I confirm the dialog). Windows: winget install --id Git.Git -e
   --source winget --scope user, then start the SAME PowerShell command as the clone with this line
   (each command is a new process; if it still fails, ask me to restart this app):
   $env:Path = (($env:Path, [Environment]::GetEnvironmentVariable('Path', 'Machine'), [Environment]::GetEnvironmentVariable('Path', 'User')) -join ';' -split ';' | Where-Object { $_ } | Select-Object -Unique) -join ';'
   git clone https://github.com/m-check1B/agent-jack-setup.git
   cd agent-jack-setup ; git checkout v1.1.2
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

**Claude Code (the Claude app → Code tab, or `claude` in a terminal)**
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
   cd agent-jack-setup ; git checkout v1.1.2
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

**Any other AI agent that can run terminal commands (Cursor, Gemini CLI, …)**
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
   cd agent-jack-setup ; git checkout v1.1.2
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

### 0. Back up first, and check disk space
**Before you let AI run on your computer, back up your data** (Time Machine / File History / a copy of important folders off the computer). We recommend giving the agents a separate user account, or at least a separate folder (e.g. `~/Developer`). Before the first run: **a backup + enough disk space** (see below).

### Disk space
Measured on a real install (Mac, October 2026): Claude Code CLI ≈ 0.4 GB, Codex CLI ≈ 0.3 GB, T3 Code (Beta) ≈ 0.55 GB (the 0.1.11 app on an Apple Silicon Mac, measured 20 Nov 2026), Tentacles ≈ 25 MB, estate-guardian (venv) ≈ 15 MB, the Agent Jack app ≈ 0.4 GB, Homebrew + Node.js 1–2 GB (if you don't have them yet). So the install itself is ≈ 2–3 GB, but **agents add data quickly while they work** (working copies, node_modules, logs, caches; T3's data folder can grow to ~10 GB). **Keep at least 20 GB free**; below 5 GB the install won't start.

### Recommended hardware
A Mac with an **Apple M3 chip or later**, **16 GB RAM** and a **512 GB disk**. On a smaller Mac (Intel, M1/M2, less memory or a smaller disk) the install still works; DOCTOR just shows a warning (WARN) and agents run slower.

### Where Agent Jack runs
- **An M3+ / 16 GB / 512 GB Mac** is recommended for the personal-assistant role and is good enough as your main device.
- **The next step for a company:** its own main Linux server, plus more edge devices of the same kind.
- **Mac is preferred over Windows**, and a **laptop (MacBook) over a Mac mini**, because it moves with you.
- **Mobile:** the Agent Jack app for iPhone and CarPlay is in testing; launch is planned by 1 December 2026.

### What you get on Mac and on Windows today
| | Mac | Windows 11 |
|---|---|---|
| Agent Jack app | **signed and notarised** (Apple); it opens without a warning | the installer is **not signed yet**, so Windows shows SmartScreen "Windows protected your PC": click **More info** → check the name `AgentJack-Setup-…exe` → **Run anyway**. **Before that**, check its fingerprint: `Get-FileHash -Algorithm SHA256 "$HOME\Downloads\AgentJack-Setup-<version>.exe"` must match the SHA-256 shown on the downloads page |
| Where to get it | **only** inside the signed-in web app, https://agentjack.kraliki.com/downloads; never from GitHub | the same |
| What you start with | the Agent Jack app + the Bot on Local and on our server | the **Agent Jack app**, signed in, with the Bot on **our server** (lab **Server · …**) |
| Local Bot (on your computer) | yes (Codex and Claude Code in T3 Code (Beta)) | **waits until we have proven T3 Code (Beta) on Windows** (the official Windows build exists; our pin is not set yet); until then the Bot runs on our server and doctor shows WAIT (not FAIL) |
| T3 Code (Beta) | the official app from [pingdotgg/t3code](https://github.com/pingdotgg/t3code); `install.sh` installs it and it then updates itself | the Windows pin is **not set yet** (proof pending); doctor shows WAIT AJ-PIN-00 |
| Tentacles | yes | yes (pinned tag, linked with `npm link` so the app finds it); ready only once T3 Code (Beta) is there (WAIT AJ-TENT-03 until then) |
| Codex CLI, Claude Code CLI, estate-classify, Chrome | yes | yes |
| Guide status | proven path | proof run scheduled; proven on: _<to be filled in>_ |

### 1. Sign in to Agent Jack (browser only)
1. Open https://agentjack.kraliki.com/app
2. Choose **Google** and pick the email your invitation was sent to. (If we gave you an email and password, sign in with those.)
3. The welcome guide and your main Bot open. Try "What can you do?".
4. If you see that your Google account has no seat here, your access isn't unlocked yet. Reply to the welcome email and we'll sort it out.

### 2. Local setup (recommended)
Agent Jack can also run Bots on your own computer, on your own AI subscription.

**What you get:** Codex and Claude Code (app and CLI; they run as two labs, "Local · Codex" and "Local · Claude Code"), [T3 Code (Beta)](https://github.com/pingdotgg/t3code) (the official T3 Code app: several AI agents side by side), [Tentacles](https://github.com/m-check1B/t3-code-tentacles) (one agent steers others), [estate-guardian (classifier + router for Tentacles)](https://github.com/m-check1B/estate-guardian) (decides which agent a job goes to; the watchdog itself is optional, for advanced users), and the Agent Jack app paired with your computer.

**What you end up with:**

| | Required / recommended minimum | Optional |
|---|---|---|
| Plans | **ChatGPT Plus** + **Claude Pro** (each ≈ USD 20/month) | — |
| Agent | **Codex CLI** + the Codex app, **Claude Code CLI** + the Claude app; both Local labs in T3 | — |
| Workspace | **T3 Code (Beta)**, **Tentacles**, estate-guardian (classifier) | the estate-guardian watchdog itself (advanced) |
| Agent Jack | the **Agent Jack app**, paired with your computer | the **T3 Code** app on your phone / iPad (pairing with T3 Code (Beta) not proven yet) |
| Browser | **Google Chrome** + the recommended **Claude in Chrome** (Anthropic) and **ChatGPT** (OpenAI, for Codex, where available: rollout and workspace settings) extensions; see [BROWSER.md](BROWSER.md) | — |

**Cost:** the recommended minimum is **both plans, ≈ 2 × USD 20/month**:

| | **Codex (ChatGPT Plus)** | **Claude Code (Claude Pro)** |
|---|---|---|
| Plan | **ChatGPT Plus**, shown at CZK 499/month (≈ USD 20) on https://openai.com/codex | **Claude Pro**, USD 20/month, https://claude.com/pricing |
| App | **Codex** for macOS: https://openai.com/codex → **Download for macOS** | **Claude**: https://claude.com/download |
| When it runs the install | open the folder `~/Developer` (create it) and keep permissions on **Ask for approval** | the **Code** tab, model **Sonnet**, effort **high** |

**One** of the two apps runs the install, either one. If you have only one plan so far, the install still passes and DOCTOR shows a warning (WARN) for the other; add it later. Both plans have usage limits. When you reach one, the app tells you when it resets (usually within a few hours), and you wait until then. Nothing is charged extra unless you switch on paid extra usage yourself. Your Bot on our server keeps working. You don't need a more expensive model or a higher effort level.

**Steps:**
1. Get both plans (or one for now), install the Codex and Claude apps and sign in.
2. Paste one of the blocks above (fastest path), or open the guide for your system, copy the **whole** text, paste it into one of the apps (Codex or Claude Code) and send it:
   - **Mac (proven path):** [SETUP-PROMPT.md](SETUP-PROMPT.md)
   - **Windows 11 (proof run scheduled; the Bot runs on our server for now):** [SETUP-PROMPT-WINDOWS.md](SETUP-PROMPT-WINDOWS.md)
   The guides are in Czech; the agent answers in the language you write to it in.
3. The agent walks you through it step by step, asks before each change and checks each step itself. You always type passwords and sign-ins yourself.
4. At the end it prints a **DOCTOR report**. Paste it into your reply to the welcome email. That way we can see what works without ever needing access to your machine.
5. Optional: the **T3 Code** app on your phone or iPad (guide step 8). We have **not proven** pairing it with T3 Code (Beta) yet.

**Pinned versions:** we install exactly the combination we tested ourselves ([VERSIONS.md](VERSIONS.md)). Apart from T3 Code (Beta) and Claude Code, which update themselves (doctor checks the supported T3 range and the minimum Claude Code version), nothing updates by itself; a new version ships as a new tag of this repo.

**Repair:** if something stops working, open Codex or Claude Code and say "repair my Agent Jack setup using github.com/m-check1B/agent-jack-setup". It runs `bin/doctor.sh` (Windows: `bin/doctor.ps1`) and fixes each FAIL with [REPAIR.md](REPAIR.md).

**For agents:** start at [AGENTS.md](AGENTS.md).

**Browser for agents:** Google Chrome is required; we recommend the Claude in Chrome (Anthropic) and ChatGPT (OpenAI, for Codex) extensions, see [BROWSER.md](BROWSER.md). **Codex CLI and Claude Code CLI** are both required and `install.sh` (Windows: `install.ps1`) always installs them. We recommend signing in to both (`codex login` and `claude auth login`); each one enables its lab ("Local · Codex", "Local · Claude Code"). With only one signed in, the install passes with a warning.

### Recommended tools (optional)
Recommendations only: `install.sh` doesn't install them and DOCTOR doesn't check them. All from official sources, with your own account.
| Tool | What it's for with Agent Jack | Link | Price |
|---|---|---|---|
| **Linear** | tasks and work ledger; connect it to Claude Code with its official MCP connector | https://linear.app · https://linear.app/docs/mcp | free basic plan, paid team plans |
| **GitHub** | code and repos (including this guide); the `gh` CLI via `brew install gh` (Windows: `winget install --id GitHub.cli -e --source winget`) | https://github.com · https://cli.github.com | free, paid team plans |
| **Thunderbird** | local email client: mail stays on your computer, so Claude can work with it locally | https://www.thunderbird.net | free |

### 3. Problems? Write to us
Reply to the welcome email. Say which step you got stuck on and include the DOCTOR report. Never send passwords or keys.

**Terms:** By using our apps you accept the Terms of Use (https://verduona.com/podminky); the Privacy Policy (https://verduona.com/ochrana-udaju) describes how we process data.

---

License: MIT. © 2026 m-check1B · [Verduona](https://verduona.com).
