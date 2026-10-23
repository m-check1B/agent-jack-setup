# Agent Jack: nastavení / setup

[Česky](#česky) · [English](#english)

---

## Česky

**Agent Jack** je pracovní AI asistent. Píšete mu běžnou řečí a jeho Boti připraví texty, dohledají informace, rozdělí si práci a hlídají, co jim svěříte. Běží na našem serveru a volitelně i přímo na vašem počítači.

Tento repozitář obsahuje vše, co k nastavení potřebujete. Všechny nástroje v něm pocházejí z veřejných zdrojů.

### 0. Nejdřív záloha a místo na disku
**Než pustíte AI na svůj počítač, zálohujte si data** (Time Machine / Historie souborů / kopie důležitých složek mimo počítač). Doporučujeme agentům dát samostatný uživatelský účet nebo aspoň samostatnou složku (např. `~/Developer`). Před prvním spuštěním: **záloha + dost místa na disku** (viz níže).

### Místo na disku
Měřeno na reálné instalaci (Mac, říjen 2026): Claude Code CLI ≈ 0,4 GB, T3 Code TPLUS ≈ 0,3 GB, Tentacles ≈ 25 MB, estate-guardian (venv) ≈ 15 MB, aplikace Agent Jack ≈ 0,4 GB, Homebrew + Node.js 1–2 GB (pokud je ještě nemáte). Samotná instalace tedy ≈ 2–3 GB, ale **agenti při práci rychle přidávají další data** (pracovní kopie, node_modules, logy, cache; datová složka T3 může narůst na ~10 GB). **Doporučujeme mít volných aspoň 20 GB**; pod 5 GB instalace nezačne.

### 1. Přihlášení do Agent Jacka (stačí prohlížeč)
1. Otevřete https://agentjack.kraliki.com/app
2. Zvolte **Google** a vyberte e-mail, na který vám přišla pozvánka. (Pokud jste od nás dostali e-mail a heslo, přihlaste se jimi.)
3. Otevře se úvodní průvodce a váš hlavní Bot. Napište mu třeba „Co umíš?“.
4. Když uvidíte hlášku, že váš účet Google tu zatím nemá přidělený přístup („no seat here“), přístup ještě není odemčený. Odpovězte na uvítací e-mail a my to vyřešíme.

### 2. Lokální nastavení (doporučeno)
Agent Jack může pouštět Boty i přímo na vašem počítači, přes vaše vlastní předplatné AI.

**Co získáte:** Codex nebo Claude Code (aplikace i příkazový řádek; jeden z nich řídí instalaci a pak běží jako lab „Local“), [T3 Code TPLUS](https://github.com/m-check1B/t3code-tplus) (naše otestovaná verze T3 Code: víc AI agentů vedle sebe), [Tentacles](https://github.com/m-check1B/t3-code-tentacles) (jeden agent řídí další), [estate-guardian (klasifikátor + router pro Tentacles)](https://github.com/m-check1B/estate-guardian) (rozhoduje, kterému agentovi práce patří; samotný hlídač je volitelný pro pokročilé) a aplikaci Agent Jack spárovanou s počítačem.

**Vyberte si jednoho agenta, který instalaci provede.** Stačí jedno předplatné:

| | **A: Codex (ChatGPT Plus)** · nová cesta od v1.0.4 | **B: Claude Code (Claude Pro)** · ověřená cesta |
|---|---|---|
| Předplatné | **ChatGPT Plus**, na https://openai.com/codex uvedeno za 499 Kč měsíčně (≈ 20 USD) | **Claude Pro**, 20 USD měsíčně, https://claude.com/pricing |
| Aplikace | **Codex** pro macOS: https://openai.com/codex → **Download for macOS** | **Claude**: https://claude.com/download |
| Kam vložit návod | do aplikace Codex: otevřete složku `~/Developer` (vytvořte ji) a oprávnění nechte na **Ask for approval** | záložka **Code**, model **Sonnet**, úroveň přemýšlení **high** |

Obě předplatná mají limity použití. Když limit vyčerpáte, aplikace napíše, kdy se obnoví (obvykle za několik hodin), a do té doby počkáte. Nic se automaticky nedoplácí, pokud si placené navýšení sami nezapnete. Bot na našem serveru běží dál. Dražší model ani vyšší úroveň přemýšlení nejsou potřeba.

**Postup:**
1. Kupte si předplatné A nebo B, nainstalujte jeho aplikaci a přihlaste se.
2. Otevřete návod pro svůj systém, zkopírujte **celý** text, vložte ho do aplikace (Codex nebo Claude Code) a odešlete:
   - **Mac (ověřená cesta):** [SETUP-PROMPT.md](SETUP-PROMPT.md)
   - **Windows (zatím neověřeno):** [SETUP-PROMPT-WINDOWS.md](SETUP-PROMPT-WINDOWS.md)
3. Agent vás provede krok za krokem, před každou změnou se zeptá a každý krok sám ověří. Hesla a přihlášení zadáváte vždy sami.
4. Na konci vypíše **DOCTOR report**. Zkopírujte ho do odpovědi na uvítací e-mail. Tak uvidíme, co funguje, aniž bychom potřebovali přístup k vašemu počítači.
5. Volitelně: aplikace **T3 Code** na mobil nebo iPad (návod krok 8). Párování s naší verzí T3 Code TPLUS zatím **není ověřené**.

**Pevné verze:** instalujeme přesně tu kombinaci, kterou jsme sami otestovali ([VERSIONS.md](VERSIONS.md)). Nic se samo neaktualizuje; novou verzi vydáme jako nový tag tohoto repozitáře.

**Oprava:** když něco přestane fungovat, otevřete Codex nebo Claude Code a napište: „oprav mi nastavení Agent Jacka podle github.com/m-check1B/agent-jack-setup“. Agent spustí `bin/doctor.sh` a opraví chyby podle [REPAIR.md](REPAIR.md).

**Prohlížeč pro agenty (volitelné):** rozšíření Claude in Chrome, viz [BROWSER.md](BROWSER.md). **Codex CLI i Claude Code CLI** instaluje `install.sh` vždy. Přihlásit musíte aspoň jeden z nich (`codex login` nebo `claude auth login`); každý zapne svůj lab („Local · Codex“, „Local · Claude Code“).

### Doporučené nástroje (volitelné)
Jen doporučení: `install.sh` je neinstaluje a DOCTOR je nekontroluje. Všechno z oficiálních zdrojů, s vlastním účtem.
| Nástroj | K čemu s Agent Jackem | Odkaz | Cena |
|---|---|---|---|
| **Linear** | úkoly a evidence práce; do Claude Code ho připojíte oficiálním MCP konektorem | https://linear.app · https://linear.app/docs/mcp | zdarma základní plán, placené týmové plány |
| **GitHub** | kód a repozitáře (i tento návod); příkaz `gh` přes `brew install gh` | https://github.com · https://cli.github.com | zdarma, placené plány pro týmy |
| **Thunderbird** | lokální poštovní klient: pošta zůstává na vašem počítači, takže s ní Claude může pracovat lokálně | https://www.thunderbird.net | zdarma |

### 3. Problém? Napište nám
Odpovězte na uvítací e-mail. Napište, u kterého kroku jste se zasekli, a přiložte DOCTOR report. Hesla ani klíče nikdy neposílejte.

**Podmínky:** Používáním aplikací souhlasíte s Podmínkami použití (https://verduona.com/podminky); zpracování údajů popisují Zásady ochrany osobních údajů (https://verduona.com/ochrana-udaju).

---

## English

**Agent Jack** is an AI work assistant. You write to it in plain language and its Bots draft texts, look things up, split the work and keep track of what you hand them. It runs on our server and, optionally, on your own computer.

This repository holds everything you need for setup. Every tool in it comes from a public source.

### 0. Back up first, and check disk space
**Before you let AI run on your computer, back up your data** (Time Machine / File History / a copy of important folders off the computer). We recommend giving the agents a separate user account, or at least a separate folder (e.g. `~/Developer`). Before the first run: **a backup + enough disk space** (see below).

### Disk space
Measured on a real install (Mac, October 2026): Claude Code CLI ≈ 0.4 GB, T3 Code TPLUS ≈ 0.3 GB, Tentacles ≈ 25 MB, estate-guardian (venv) ≈ 15 MB, the Agent Jack app ≈ 0.4 GB, Homebrew + Node.js 1–2 GB (if you don't have them yet). So the install itself is ≈ 2–3 GB, but **agents add data quickly while they work** (working copies, node_modules, logs, caches; T3's data folder can grow to ~10 GB). **Keep at least 20 GB free**; below 5 GB the install won't start.

### 1. Sign in to Agent Jack (browser only)
1. Open https://agentjack.kraliki.com/app
2. Choose **Google** and pick the email your invitation was sent to. (If we gave you an email and password, sign in with those.)
3. The welcome guide and your main Bot open. Try "What can you do?".
4. If you see that your Google account has no seat here, your access isn't unlocked yet. Reply to the welcome email and we'll sort it out.

### 2. Local setup (recommended)
Agent Jack can also run Bots on your own computer, on your own AI subscription.

**What you get:** Codex or Claude Code (app and CLI; one of them runs the install and then works as the "Local" lab), [T3 Code TPLUS](https://github.com/m-check1B/t3code-tplus) (our tested build of T3 Code: several AI agents side by side), [Tentacles](https://github.com/m-check1B/t3-code-tentacles) (one agent steers others), [estate-guardian (classifier + router for Tentacles)](https://github.com/m-check1B/estate-guardian) (decides which agent a job goes to; the watchdog itself is optional, for advanced users), and the Agent Jack app paired with your computer.

**Pick one agent to run the install.** One plan is enough:

| | **A: Codex (ChatGPT Plus)** · new path since v1.0.4 | **B: Claude Code (Claude Pro)** · proven path |
|---|---|---|
| Plan | **ChatGPT Plus**, shown at CZK 499/month (≈ USD 20) on https://openai.com/codex | **Claude Pro**, USD 20/month, https://claude.com/pricing |
| App | **Codex** for macOS: https://openai.com/codex → **Download for macOS** | **Claude**: https://claude.com/download |
| Where the guide goes | the Codex app: open the folder `~/Developer` (create it) and keep permissions on **Ask for approval** | the **Code** tab, model **Sonnet**, effort **high** |

Both plans have usage limits. When you reach one, the app tells you when it resets (usually within a few hours), and you wait until then. Nothing is charged extra unless you switch on paid extra usage yourself. Your Bot on our server keeps working. You don't need a more expensive model or a higher effort level.

**Steps:**
1. Get plan A or B, install its app and sign in.
2. Open the guide for your system, copy the **whole** text, paste it into the app (Codex or Claude Code) and send it:
   - **Mac (proven path):** [SETUP-PROMPT.md](SETUP-PROMPT.md)
   - **Windows (not yet proven):** [SETUP-PROMPT-WINDOWS.md](SETUP-PROMPT-WINDOWS.md)
   The guides are in Czech; the agent answers in the language you write to it in.
3. The agent walks you through it step by step, asks before each change and checks each step itself. You always type passwords and sign-ins yourself.
4. At the end it prints a **DOCTOR report**. Paste it into your reply to the welcome email. That way we can see what works without ever needing access to your machine.
5. Optional: the **T3 Code** app on your phone or iPad (guide step 8). Pairing it with our T3 Code TPLUS build is **not proven yet**.

**Pinned versions:** we install exactly the combination we tested ourselves ([VERSIONS.md](VERSIONS.md)). Nothing updates by itself; a new version ships as a new tag of this repo.

**Repair:** if something stops working, open Codex or Claude Code and say "repair my Agent Jack setup using github.com/m-check1B/agent-jack-setup". It runs `bin/doctor.sh` and fixes each FAIL with [REPAIR.md](REPAIR.md).

**For agents:** start at [AGENTS.md](AGENTS.md).

**Browser for agents (optional):** the Claude in Chrome extension, see [BROWSER.md](BROWSER.md). `install.sh` always installs **both Codex CLI and Claude Code CLI**. Sign in to at least one (`codex login` or `claude auth login`); each one enables its lab ("Local · Codex", "Local · Claude Code").

### Recommended tools (optional)
Recommendations only: `install.sh` doesn't install them and DOCTOR doesn't check them. All from official sources, with your own account.
| Tool | What it's for with Agent Jack | Link | Price |
|---|---|---|---|
| **Linear** | tasks and work ledger; connect it to Claude Code with its official MCP connector | https://linear.app · https://linear.app/docs/mcp | free basic plan, paid team plans |
| **GitHub** | code and repos (including this guide); the `gh` CLI via `brew install gh` | https://github.com · https://cli.github.com | free, paid team plans |
| **Thunderbird** | local email client: mail stays on your computer, so Claude can work with it locally | https://www.thunderbird.net | free |

### 3. Problems? Write to us
Reply to the welcome email. Say which step you got stuck on and include the DOCTOR report. Never send passwords or keys.

**Terms:** By using our apps you accept the Terms of Use (https://verduona.com/podminky); the Privacy Policy (https://verduona.com/ochrana-udaju) describes how we process data.

---

License: MIT. © 2026 m-check1B · [Verduona](https://verduona.com).
