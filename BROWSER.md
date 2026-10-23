# Prohlížeč pro agenty / Browser for agents

[Česky](#česky) · [English](#english)

## Česky
Agenti mohou pracovat ve vašem prohlížeči (otevřít stránku, vyplnit formulář, zkontrolovat web). Potřebujete **Google Chrome** (povinný, https://www.google.com/chrome) a k němu rozšíření pro agenta, kterého používáte. Rozšíření jsou volitelná.

**Pozor na napodobeniny.** Instalujte jen z Chrome Web Store a jen rozšíření od vydavatele uvedeného níže („Offered by“ / „Nabízí“). Podobně pojmenovaná rozšíření od jiných vydavatelů neinstalujte.

### Codex: rozšíření ChatGPT (dříve „Codex“), vydavatel OpenAI
1. **Jen oficiální rozšíření:** https://chromewebstore.google.com/detail/hehggadaopoacecdllhhajmbjkdcmajg (id `hehggadaopoacecdllhhajmbjkdcmajg`, vydavatel **OpenAI**). V obchodě se dnes jmenuje **ChatGPT**; je to totéž rozšíření, které dřív neslo název Codex.
2. **Instalace z aplikace** (podle návodu OpenAI, https://learn.chatgpt.com/docs/chrome-extension): aktualizujte aplikaci, otevřete **Settings → Computer Use**, vyberte **Google Chrome** a potvrďte instalaci pluginu, pokud se objeví. Pak **Install** u prohlížeče → na stránce obchodu nainstalujte rozšíření **ChatGPT** (zkontrolujte id a vydavatele výše) a projděte souhlasy. Starší verze aplikace to mají v **Plugins → Chrome**.
3. **Ověření:** v **Settings → Computer Use** ukazuje Chrome **Manage** („Connected to browser extension“). V novém vlákně napište `@Chrome` a krátký úkol, v profilu Chrome, kde je rozšíření nainstalované.
4. Podle OpenAI dostupnost prohlížeče závisí na postupném zpřístupnění a nastavení pracovního prostoru. Když volbu nevidíte, krok přeskočte. Pro stránky, kde přihlášení nepotřebujete, a pro localhost má aplikace vestavěný prohlížeč (`@Browser`).

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
2. **Install it from the app** (per OpenAI's guide, https://learn.chatgpt.com/docs/chrome-extension): update the app, open **Settings → Computer Use**, select **Google Chrome** and accept the plugin install if prompted. Then **Install** beside the browser → install the **ChatGPT** extension from its store page (check the id and publisher above) and review the permission prompts. Older app versions have this under **Plugins → Chrome**.
3. **Verify:** in **Settings → Computer Use**, Chrome shows **Manage** ("Connected to browser extension"). In a new thread, type `@Chrome` and a short task, in the Chrome profile where the extension is installed.
4. Per OpenAI, browser availability can depend on rollout and workspace settings. If you don't see the option, skip this step. For pages that need no sign-in, and for localhost, the app has a built-in browser (`@Browser`).

### Claude Code: the Claude in Chrome extension, publisher Anthropic (Claude plan only)
1. **Official extension only:** https://chromewebstore.google.com/detail/fcoeoabgfenejglbffodgkkbkcdhcgfn (publisher **Anthropic**). Watch out for look-alikes such as "Claude On Google". It works only with a paid Claude plan (Pro and up).
2. **Per Chrome profile:** install it in the profile the agent should use, and pin it via the 🧩 icon.
3. **Same account:** sign in to the extension with the **same Claude account** as Claude Code / the Claude app. With a different account the agent reports "no connected browser". After switching accounts the extension may disconnect or disappear; reinstall it then.
4. **Verify:** in Claude Code, ask it to "list connected browsers". It must show at least one.

**Codex CLI:** installed by `bin/install.sh codex` (part of `all`). Sign in yourself with `codex login` using your own ChatGPT plan; for the "Local · Codex" lab in Agent Jack this local sign-in is enough.

**Claude Code sign-in over ssh (a second Mac):** `claude auth logout && claude auth login` → open the link → paste the code into the same terminal.
