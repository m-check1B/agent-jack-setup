# M3 — Staging Dogfood Execution Runbook (Webapp + `si2mac` Desktop)

- **Tracking issue**: `KRA-11035` (Milestone M3 — First Live Dogfood Run inside Agent Jack)
- **Architectural rule**: Zero hardcoded test harness in `agent-jack-3`. Run the portable **Multi-Approach E2E Test Agent** (`use-cases/e2e-test-agent/`) *inside* Agent Jack using Jack's general capabilities and Paired Mac / Tentacles routes.
- **Quality bar**: Matches `KRA-10684` (exact build SHA + UTC timestamp, zero fabricated `PASS`, honest `BLOCKED` on missing fixtures or unshipped capabilities, read-only production guard, approval-gated Linear bug filing).

---

## 1. Prerequisites & Pre-Flight Checklist

Verify every item before launching the dogfood run:

1. **Bundle integrity passes locally**:
   ```bash
   python3 use-cases/e2e-test-agent/scripts/validate_bundle.py
   ```
2. **Paired Mac healthy** (required for Playwright local checks when `G1`–`G3` are not yet deployed, and required for native `si2mac` desktop verification):
   ```bash
   bin/doctor.sh
   ```
   Confirm `0 FAIL` (Tentacles paired, Agent Jack Desktop signed in, Google Chrome present).
3. **Target selection (staging first; production strictly read-only)**:
   - **Webapp target**: 1 live staging web application URL (e.g. a staging deployment of Shop, Koolna, CouncilNow, Work Security, or Trznice). If testing a production URL instead, **read-only mode is mandatory** (no form submits, no orders, no payments, no sign-ups).
   - **Desktop target**: Local built/installed `si2mac` macOS Swift app bundle (isolated test configuration, never personal accounts or live production writes).
4. **Credentials & fixtures**:
   - **Never** use Founder or personal credentials.
   - If a designated staging fixture account exists for signed-in rows, supply it through the seat's isolated test environment; otherwise leave signed-in rows `BLOCKED` and state the missing fixture account explicitly.
5. **macOS permissions for `si2mac` desktop verification** (on the Paired Mac):
   - **Screen Recording** enabled for the paired terminal / Agent Jack Desktop (for `window.screenshot` / `screencapture`).
   - **Accessibility** enabled (for `window.ax_tree` / `AXUIElement` inspection).

---

## 2. Import & Wire the Use-Case Inside Agent Jack

### Step 2.1 — Import the Team Package (`team.jack.md`)

1. Open Agent Jack → **Settings › Teams › Import Team Package**.
2. Upload `use-cases/e2e-test-agent/team.jack.md`.
3. Verify the import preview shows:
   - **3 Bots**: `E2E QA Lead` (`e2e-lead`), `Web & API Tester` (`web-api-tester`), `Desktop & Mobile Tester` (`native-app-tester`)
   - **1 Group**: `E2E QA Desk` (`e2e-qa-desk`)
   - **1 Team**: `E2E Test Team` (`e2e-qa-team`, chief: `E2E QA Lead`)
   - **1 Connector requirement**: `linear` (`bug-tracker`, shown as `unbound`)
   - **2 Routines**: both **paused** (`daily-staging-smoke`, `release-gate-triage`)
4. Confirm import.

### Step 2.2 — Install the 5 Taught Skills

- **On `jack.team` v1 (current)**: Copy `use-cases/e2e-test-agent/skills/*` into `~/.agent-jack/skills/` (or install each `SKILL.md` onto the Bots in **Bot Settings › Skills**):
  - `E2E QA Lead`: `evidence-pack-verdict`, `webapp-e2e`
  - `Web & API Tester`: `webapp-e2e`, `api-contract-probe`, `visual-a11y-audit`, `evidence-pack-verdict`
  - `Desktop & Mobile Tester`: `desktop-mobile-e2e`, `visual-a11y-audit`, `evidence-pack-verdict`
- **Once `G9` (`jack.team` v2) lands**: Skills and review-gated capability requests import directly in Step 2.1 after owner checkbox confirmation.

### Step 2.3 — Bind Connectors, Capabilities & Routes

Follow `use-cases/e2e-test-agent/toolbelt-preset.json`:

1. **Linear connector**: Connect **Linear** in **Settings › Plugins** and grant it to `E2E Test Team` (keep `gmail`, `stripe`, `cloudflare` **excluded** from the Team ceiling).
   - **With `G7` (`linear.file_issue` MCP tool, `agent-jack-3#463`)**: `E2E QA Lead` calls `linear.file_issue` behind Jack's durable human-approval gate so every new bug ticket shows a review card before creation.
   - **Before `G7` merges**: `E2E QA Lead` deduplicates via `linear.issues` / Linear OAuth MCP and pauses for explicit operator approval before creating any issue (or outputs a `draft-awaiting-approval` entry in `verdict.json`).
2. **WebMCP**: If the staging webapp exposes a WebMCP server, verify it appears in `webmcp.list` for `Web & API Tester` and is allowed in the `E2E Test Team` ceiling.
3. **Browser & API capabilities**:
   - Grant `browser.use` on `Web & API Tester`.
   - **Today (pre-`G1`–`G3`/`G5` deployment)**: Route `Web & API Tester` to your **Paired Mac** (`Local Claude` or `Local Codex` via Tentacles) so Playwright clean-profile browser runs, console/network capture, and full HTTP contract probes run end-to-end.
   - **Once `G1`+`G3` (CDP console/network + persisted vision screenshots) and `G5` (`http.probe`, `agent-jack-3#464`) land**: `Web & API Tester` can also execute public/allowlisted staging web + API checks directly from a Server Bot route.
4. **Native desktop (`si2mac`)**:
   - Route `Desktop & Mobile Tester` to the **Paired Mac** (`Local Claude` or `Local Codex`), or use the Paired Mac Device Bridge verbs once `G6` (`app.status/launch`, `window.screenshot`, `window.ax_tree`) lands.

---

## 3. Execute the M3 Dogfood Run (Inside `E2E QA Desk`)

### Run 1 — Staging Webapp Multi-Approach Matrix

Post this prompt in **E2E QA Desk** (replacing placeholders with your target staging URL and app name):

```text
@E2E QA Lead Run an M3 dogfood E2E verification on <APP_NAME> at <STAGING_URL> (environment: staging; locales: en, cs; viewports: 360x800, 390x844, 1280x800; themes: light, dark).

Required approaches:
1. WebMCP (`webmcp.list` + read-only `webmcp.call` checks if registered; otherwise mark WebMCP column BLOCKED with exact reason).
2. API contract probes (`http.probe` or local CLI): `/health` or status endpoint, TLS/redirects, security headers, unauthenticated 401/403 fail-closed check, and deployed build SHA.
3. Clean-profile browser journeys (`webapp-e2e`) + responsive/visual/a11y audit (`visual-a11y-audit`): signed-out landing, navigation chrome, legal links, 404 page, cookie banner locale, bounding-box overflow/clipping, phone pane height, WCAG contrast, console errors (`0`), and failed XHRs (`0`).
4. Signed-in rows: use only an explicitly provisioned staging fixture account; if none is available, mark those rows BLOCKED (never ask for or use personal/Founder credentials).

Deliverables in `outputs/`:
- `MATRIX.md` (following `templates/MATRIX.template.md`, ending with exact re-run command)
- `verdict.json` (validating against `templates/verdict.schema.json`)
- `evidence-pack-<app>-<timestamp>.zip` (all screenshots + redacted console/network/API logs)
- Up to 2 key failure PNGs inline (total <= 5 attachments).

Bug filing: deduplicate against open Linear issues first; if any real FAIL is found, submit ONE approval-gated `linear.file_issue` request (or draft awaiting approval) — do not create duplicates and do not touch app repos.
```

### Run 2 — Native macOS Desktop Verification (`si2mac`)

Post this follow-up prompt in **E2E QA Desk**:

```text
@Desktop & Mobile Tester Run an M3 desktop E2E verification of `si2mac` on the Paired Mac (`desktop-mobile-e2e`).

Checks:
1. Record macOS version (`sw_vers`), `si2mac` bundle ID, `CFBundleShortVersionString`, build SHA, and read-only code signature status (`codesign -dv --verbose=2`).
2. Launch `si2mac` cleanly with an isolated fixture config (never personal accounts or live production writes); verify main window renders with 0 new crash reports in `~/Library/Logs/DiagnosticReports/`.
3. Inspect the Accessibility tree (`window.ax_tree` / `AXUIElement`) for primary navigation and controls (enabled + non-empty accessible labels).
4. Capture Light and Dark window screenshots into `outputs/` and inspect via vision for truncation, clipped labels, or low contrast.
5. Quit cleanly (`Cmd+Q` / SIGTERM) and confirm zero orphaned helper processes remain.

Hand structured `macos-native` rows and screenshots to @E2E QA Lead to merge into the M3 evidence pack (`MATRIX.md`, `verdict.json`, ZIP). If any macOS permission or build artifact is missing, mark the row BLOCKED honestly with the exact unblocker.
```

---

## 4. Post-Run Verification & M3 Acceptance Gate

M3 is **DONE** only when ALL of the following are verified with artifacts from the live Agent Jack run:

1. **Schema-valid `verdict.json`**:
   ```bash
   python3 -c '
   import json, pathlib, jsonschema
   schema = json.loads(pathlib.Path("use-cases/e2e-test-agent/templates/verdict.schema.json").read_text())
   verdict = json.loads(pathlib.Path("<path-to-downloaded-verdict.json>").read_text())
   jsonschema.validate(verdict, schema, cls=jsonschema.Draft202012Validator)
   print("verdict.json VALID:", verdict["verdict"], verdict["counts"])
   '
   ```
2. **Exact provenance**: Both `MATRIX.md` and `verdict.json` contain real `buildSha`, UTC `runTimestampUtc`, `runnerSurface`, and `approachesUsed` matching the actual run.
3. **Zero fabricated passes**: Every `PASS` cites concrete observed output/measurement; every unrun row is `BLOCKED` with its exact prerequisite or gap ID (`G1`–`G10`).
4. **Redaction verified**: Zero passwords, tokens, `Cookie`/`Authorization` header values, private IPs, or personal home paths in any attached file or Linear draft.
5. **Approval-gated Linear proof**: Either (a) at least one real `FAIL` filed via human-approved `linear.file_issue` / Linear MCP (with issue URL recorded in `verdict.json` `linearIssues[]`), or (b) clean `PASS`/`BLOCKED` run with a verified dry-run/approval-gate exercise on staging.
6. **Zero app-repo mutations**: `git status` on tested app repositories remains untouched.
7. **Ledger updated**: Post the verdict summary, artifact links, and any filed Linear bug URLs as a comment on `KRA-11035`.
