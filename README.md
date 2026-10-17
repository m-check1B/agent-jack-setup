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

**Co získáte:** Claude Code (aplikace i příkazový řádek), [T3 Code TPLUS](https://github.com/m-check1B/t3code-tplus) (naše otestovaná verze T3 Code: víc AI agentů vedle sebe), [Tentacles](https://github.com/m-check1B/t3-code-tentacles) (jeden agent řídí další), [estate-guardian (klasifikátor + router pro Tentacles)](https://github.com/m-check1B/estate-guardian) (rozhoduje, kterému agentovi práce patří; samotný hlídač je volitelný pro pokročilé) a aplikaci Agent Jack spárovanou s počítačem.

**Náklady:** jedno předplatné **Claude Pro (20 USD měsíčně)**, https://claude.com/pricing. Pro má limity použití. Když limit vyčerpáte, Claude napíše, kdy se obnoví (obvykle za několik hodin), a do té doby počkáte. Nic se automaticky nedoplácí, pokud si placené navýšení sami nezapnete. Bot na našem serveru běží dál.

**Postup:**
1. Kupte Claude Pro a nainstalujte aplikaci Claude z https://claude.com/download. Přihlaste se.
2. V aplikaci otevřete záložku **Code**, vyberte model **Sonnet** a úroveň přemýšlení **high**. Dražší model není potřeba.
3. Otevřete návod pro svůj systém, zkopírujte **celý** text, vložte ho do Claude Code a odešlete:
   - **Mac (ověřená cesta):** [SETUP-PROMPT.md](SETUP-PROMPT.md)
   - **Windows (zatím neověřeno):** [SETUP-PROMPT-WINDOWS.md](SETUP-PROMPT-WINDOWS.md)
4. Claude vás provede krok za krokem, před každou změnou se zeptá a každý krok sám ověří. Hesla a přihlášení zadáváte vždy sami.
5. Na konci vypíše **DOCTOR report**. Zkopírujte ho do odpovědi na uvítací e-mail. Tak uvidíme, co funguje, aniž bychom potřebovali přístup k vašemu počítači.

**Pevné verze:** instalujeme přesně tu kombinaci, kterou jsme sami otestovali ([VERSIONS.md](VERSIONS.md)). Nic se samo neaktualizuje; novou verzi vydáme jako nový tag tohoto repozitáře.

**Oprava:** když něco přestane fungovat, otevřete Claude Code a napište: „oprav mi nastavení Agent Jacka podle github.com/m-check1B/agent-jack-setup“. Claude spustí `bin/doctor.sh` a opraví chyby podle [REPAIR.md](REPAIR.md).

**Prohlížeč pro agenty (volitelné):** rozšíření Claude in Chrome, viz [BROWSER.md](BROWSER.md). **Codex CLI** instaluje `install.sh` vždy; přihlášení `codex login` je volitelné (vlastní předplatné ChatGPT) a zapne lab „Local · Codex“.

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

**What you get:** Claude Code (app and CLI), [T3 Code TPLUS](https://github.com/m-check1B/t3code-tplus) (our tested build of T3 Code: several AI agents side by side), [Tentacles](https://github.com/m-check1B/t3-code-tentacles) (one agent steers others), [estate-guardian (classifier + router for Tentacles)](https://github.com/m-check1B/estate-guardian) (decides which agent a job goes to; the watchdog itself is optional, for advanced users), and the Agent Jack app paired with your computer.

**Cost:** one **Claude Pro** plan (**USD 20/month**), https://claude.com/pricing. Pro has usage limits. When you reach one, Claude tells you when it resets (usually within a few hours), and you wait until then. Nothing is charged extra unless you switch on paid extra usage yourself. Your Bot on our server keeps working.

**Steps:**
1. Get Claude Pro and install the Claude app from https://claude.com/download. Sign in.
2. Open the **Code** tab, choose model **Sonnet** and effort **high**. You don't need a more expensive model.
3. Open the guide for your system, copy the **whole** text, paste it into Claude Code and send it:
   - **Mac (proven path):** [SETUP-PROMPT.md](SETUP-PROMPT.md)
   - **Windows (not yet proven):** [SETUP-PROMPT-WINDOWS.md](SETUP-PROMPT-WINDOWS.md)
   The guides are in Czech; Claude answers in the language you write to it in.
4. Claude walks you through it step by step, asks before each change and checks each step itself. You always type passwords and sign-ins yourself.
5. At the end it prints a **DOCTOR report**. Paste it into your reply to the welcome email. That way we can see what works without ever needing access to your machine.

**Pinned versions:** we install exactly the combination we tested ourselves ([VERSIONS.md](VERSIONS.md)). Nothing updates by itself; a new version ships as a new tag of this repo.

**Repair:** if something stops working, open Claude Code and say "repair my Agent Jack setup using github.com/m-check1B/agent-jack-setup". It runs `bin/doctor.sh` and fixes each FAIL with [REPAIR.md](REPAIR.md).

**For agents:** start at [AGENTS.md](AGENTS.md).

**Browser for agents (optional):** the Claude in Chrome extension, see [BROWSER.md](BROWSER.md). **Codex CLI** is always installed by `install.sh`; signing in with `codex login` is optional (your own ChatGPT plan) and enables the "Local · Codex" lab.

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
