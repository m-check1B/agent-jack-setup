# Prohlížeč pro agenty / Browser for agents

[Česky](#česky) · [English](#english)

## Česky
Agenti mohou pracovat ve vašem prohlížeči (otevřít stránku, vyplnit formulář, zkontrolovat web). Potřebujete **Google Chrome** (povinný, https://www.google.com/chrome) a k němu rozšíření pro agenta, kterého používáte. Rozšíření jsou volitelná.

**Pozor na napodobeniny.** Instalujte jen z Chrome Web Store a jen rozšíření od vydavatele uvedeného níže („Offered by“ / „Nabízí“). Podobně pojmenovaná rozšíření od jiných vydavatelů neinstalujte.

### Codex: rozšíření ChatGPT (dříve „Codex“), vydavatel OpenAI
1. **Jen oficiální rozšíření:** https://chromewebstore.google.com/detail/hehggadaopoacecdllhhajmbjkdcmajg (id `hehggadaopoacecdllhhajmbjkdcmajg`, vydavatel **OpenAI**). V obchodě se dnes jmenuje **ChatGPT**; je to totéž rozšíření, které dřív neslo název Codex.
2. **Instalace z aplikace Codex:** v aplikaci Codex otevřete **Plugins** → přidejte plugin **Chrome** a projděte průvodce (nainstaluje rozšíření a vyžádá souhlasy Chrome). Odkaz výše slouží ke kontrole, že jde o pravé rozšíření.
3. **Ověření:** v Chrome ukazuje rozšíření stav **Connected**. V novém vlákně v Codexu napište `@Chrome` a krátký úkol.
4. Kvůli postupnému zpřístupnění podle regionu se může stát, že plugin nebo rozšíření ještě neuvidíte. Pak tento krok přeskočte: Codex má i vlastní vestavěný prohlížeč pro veřejné stránky.

### Claude Code: rozšíření Claude in Chrome, vydavatel Anthropic (jen s plánem Claude)
1. **Jen oficiální rozšíření:** https://chromewebstore.google.com/detail/fcoeoabgfenejglbffodgkkbkcdhcgfn (vydavatel **Anthropic**). Pozor na napodobeniny jako „Claude On Google“. Funguje jen s placeným plánem Claude (Pro a vyšší).
2. **Pro každý profil Chrome zvlášť:** nainstalujte ho v profilu, se kterým má agent pracovat, a připněte ho přes ikonu 🧩.
3. **Stejný účet:** v rozšíření se přihlaste **stejným účtem Claude** jako v Claude Code / aplikaci Claude. S jiným účtem agent hlásí „no connected browser“. Po přepnutí účtu se rozšíření může odpojit nebo zmizet; pak ho nainstalujte znovu.
4. **Ověření:** v Claude Code napište „vypiš připojené prohlížeče“. Musí ukázat aspoň jeden.

**Codex CLI:** instaluje ho `bin/install.sh codex` (součást `all`). Přihlaste se sami příkazem `codex login` svým vlastním předplatným ChatGPT; pro lokální lab „Local · Codex“ v Agent Jackovi stačí toto lokální přihlášení.

**Přihlášení Claude Code přes ssh (druhý Mac):** `claude auth logout && claude auth login` → otevřete odkaz → kód vložte do téhož terminálu.

## English
Agents can work in your browser (open a page, fill a form, check a site). You need **Google Chrome** (required, https://www.google.com/chrome) plus the extension for the agent you use. The extensions are optional.

**Watch out for look-alikes.** Install only from the Chrome Web Store, and only the extension from the publisher named below ("Offered by"). Don't install similarly named extensions from other publishers.

### Codex: the ChatGPT extension (formerly "Codex"), publisher OpenAI
1. **Official extension only:** https://chromewebstore.google.com/detail/hehggadaopoacecdllhhajmbjkdcmajg (id `hehggadaopoacecdllhhajmbjkdcmajg`, publisher **OpenAI**). The store now lists it as **ChatGPT**; it's the same extension that used to be called Codex.
2. **Install it from the Codex app:** in the Codex app open **Plugins** → add the **Chrome** plugin and follow the guide (it installs the extension and asks for Chrome's permissions). Use the link above to check that it's the real extension.
3. **Verify:** in Chrome the extension shows **Connected**. In a new Codex thread, type `@Chrome` and a short task.
4. Because of a gradual, region-based rollout, the plugin or extension may not show up for you yet. Then skip this step: Codex also has its own built-in browser for public pages.

### Claude Code: the Claude in Chrome extension, publisher Anthropic (Claude plan only)
1. **Official extension only:** https://chromewebstore.google.com/detail/fcoeoabgfenejglbffodgkkbkcdhcgfn (publisher **Anthropic**). Watch out for look-alikes such as "Claude On Google". It works only with a paid Claude plan (Pro and up).
2. **Per Chrome profile:** install it in the profile the agent should use, and pin it via the 🧩 icon.
3. **Same account:** sign in to the extension with the **same Claude account** as Claude Code / the Claude app. With a different account the agent reports "no connected browser". After switching accounts the extension may disconnect or disappear; reinstall it then.
4. **Verify:** in Claude Code, ask it to "list connected browsers". It must show at least one.

**Codex CLI:** installed by `bin/install.sh codex` (part of `all`). Sign in yourself with `codex login` using your own ChatGPT plan; for the "Local · Codex" lab in Agent Jack this local sign-in is enough.

**Claude Code sign-in over ssh (a second Mac):** `claude auth logout && claude auth login` → open the link → paste the code into the same terminal.
