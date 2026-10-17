# Prohlížeč pro agenty / Browser for agents

[Česky](#česky) · [English](#english)

## Česky
Aby Claude Code mohl pracovat ve vašem prohlížeči (otevřít stránku, vyplnit formulář, zkontrolovat web), potřebuje rozšíření **Claude in Chrome**. Je to volitelné.

1. **Jen oficiální rozšíření:** https://chromewebstore.google.com/detail/fcoeoabgfenejglbffodgkkbkcdhcgfn (vydavatel **Anthropic**). Pozor na podobně pojmenované napodobeniny (např. „Claude On Google“). Funguje jen s placeným plánem Claude (Pro a vyšší).
2. **Pro každý profil Chrome zvlášť:** nainstalujte ho v profilu, se kterým má agent pracovat, a připněte ho přes ikonu 🧩.
3. **Stejný účet:** v rozšíření se přihlaste **stejným účtem Claude** jako v Claude Code / aplikaci Claude. S jiným účtem agent hlásí „no connected browser“. Po přepnutí účtu se rozšíření může odpojit nebo zmizet; pak ho nainstalujte znovu.
4. **Ověření:** v Claude Code napište „vypiš připojené prohlížeče“. Musí ukázat aspoň jeden.

**Codex CLI:** instaluje ho `bin/install.sh codex` (součást `all`). Přihlaste se sami příkazem `codex login` svým vlastním předplatným ChatGPT; pro lokální lab „Local · Codex“ v Agent Jackovi stačí toto lokální přihlášení.

**Přihlášení Claude Code přes ssh (druhý Mac):** `claude auth logout && claude auth login` → otevřete odkaz → kód vložte do téhož terminálu.

## English
For Claude Code to work in your browser (open a page, fill a form, check a site), it needs the **Claude in Chrome** extension. It's optional.

1. **Official extension only:** https://chromewebstore.google.com/detail/fcoeoabgfenejglbffodgkkbkcdhcgfn (publisher **Anthropic**). Watch out for look-alikes such as "Claude On Google". It works only with a paid Claude plan (Pro and up).
2. **Per Chrome profile:** install it in the profile the agent should use, and pin it via the 🧩 icon.
3. **Same account:** sign in to the extension with the **same Claude account** as Claude Code / the Claude app. With a different account the agent reports "no connected browser". After switching accounts the extension may disconnect or disappear; reinstall it then.
4. **Verify:** in Claude Code, ask it to "list connected browsers". It must show at least one.

**Codex CLI:** installed by `bin/install.sh codex` (part of `all`). Sign in yourself with `codex login` using your own ChatGPT plan; for the "Local · Codex" lab in Agent Jack this local sign-in is enough.

**Claude Code sign-in over ssh (a second Mac):** `claude auth logout && claude auth login` → open the link → paste the code into the same terminal.
