# M4 — Multi-App Release Gate Playbook & Commercial Showcase Brief

- **Tracking issue**: `KRA-11035` (Milestone M4 — Reusable Multi-App Release Gate & Flagship Agent Jack Business Use-Case)
- **Bundle version**: `jack.team` v2 (`team.v2.jack.md`, backwards-compatible v1 in `team.jack.md`)
- **Architectural boundary**: 100% portable Agent Jack Use-Case outside `agent-jack-3` core. Powered exclusively by Agent Jack's general platform capabilities (`http.probe`, `browser.*`, `webmcp.*`, `machines.dispatch`, `linear.file_issue`, `artifact.attach`, Paired Mac / Tentacles, and review-gated `jack.team` v2 imports).

---

## Part 1 — Reusable Multi-App Release Gate Workflow (Ocelot Product Estate)

Use the same imported **Multi-Approach E2E Test Agent** team (`E2E QA Lead`, `Web & API Tester`, `Desktop & Mobile Tester`) as the standard pre-release and post-deploy verification gate across every product line.

### Standard Release-Gate Flow (5 Steps)

1. **Trigger**: Product engineering line reports a candidate SHA or staging/production deployment (never auto-mutates app repos; never writes to production).
2. **Scope Selection**: Select the target row from the Product Matrix below. Staging runs full read + fixture-isolated write journeys (`[e2e]`-prefixed); production runs **strictly read-only** public & contract probes.
3. **Multi-Approach Execution**:
   - **API / Edge Contract** (`api-contract-probe` via `http.probe` or local CLI): `/health`, TLS, HTTP→HTTPS redirect, security headers, non-contradictory `Cache-Control`, auth fail-closed checks (`401`/`403`/`404`).
   - **Webapp + WebMCP** (`webapp-e2e` via `webmcp.list`/`webmcp.call` + Jack `browser.*` or clean-profile Playwright): signed-out chrome, legal links, branded `404`, cookie banner locale parity, `0` console/page/XHR errors, pre-auth cookie hygiene, and fixture-only signed-in journeys.
   - **Visual & Accessibility** (`visual-a11y-audit`): `360x800`, `390x844`, `1280x800` × `light`/`dark` × active locales (`en`/`cs`), bounding-box clipping, phone pane height (`>= 160px`), WCAG 2.1 AA contrast, and direct multimodal vision inspection of captured screenshots.
   - **Desktop / Mobile Native** (`desktop-mobile-e2e` via Paired Mac Device Bridge `app.status` / `window.screenshot` / `window.ax_tree` + Tentacles `swift test` / Playwright Electron / `xcrun simctl`): zero personal accounts and zero macOS Login Keychain access.
4. **Tamper-Evident Evidence Pack** (`evidence-pack-verdict` via `artifact.attach`):
   - Emit `MATRIX.md`, schema-valid `verdict.json` (`Draft202012Validator` = `0` errors), `evidence-pack-<app>-<timestamp>.zip`, and up to 2 inline failure PNGs (total `<= 5` attachments).
5. **Approval-Gated Bug Filing & Re-Verification**:
   - Deduplicate against open Linear issues first (`linear.issues`).
   - Propose every confirmed new `FAIL` via `linear.file_issue` (held for explicit owner approval before touching Linear; never auto-approved on unattended routines).
   - After engineering merges a fix, re-run the failing rows against the new build SHA and comment `PASS on <new-sha>` on the issue (leaving closure to the owning product team).

### Ocelot Product Release-Gate Matrix

| Product | Primary Surfaces | Required Approaches | Viewports / Themes / Locales | Mandatory Release-Gate Checks | Production Safety Guard |
|---|---|---|---|---|---|
| **CouncilNow** | Webapp, Public API, WebMCP | `api-probe`, `webmcp`, `playwright-local`/`jack-browser`, `visual-a11y` | `360/390/1280` · `light/dark` · `en/cs` | `/health` + `/api/v1/health` 200, `/cs/` + `/login` Czech cookie banner, legal links (`terms`/`privacy`), branded `404`, privacy-tier & fixture Problem/Council flows (staging) | Production strictly read-only; no real Problems/runs created |
| **Koolna** | Webapp, Classroom API, WebMCP | `api-probe`, `webmcp`, `playwright-local`/`jack-browser`, `visual-a11y` | `360/390/1280` · `light/dark` · `en/cs` | Auto `Accept-Language: cs-CZ`, phone lesson pane height (`>= 160px`), `/auth/not-invited` beta gate, EN/CS legal footer, branded `404`, fixture classroom journeys (staging) | Production strictly read-only; no live tenant mutations |
| **Tržnice** | Webapp, API, WebMCP | `api-probe`, `webmcp`, `playwright-local`/`jack-browser`, `visual-a11y` | `360/390/1280` · `light/dark` · `en/cs` | Public catalog/listing read, sign-in hop, invite-gate & seller/buyer fixture flows (staging), legal links, branded `404` | Production strictly read-only; no listings/orders created |
| **Work Security (BOZP)** | Webapp, API, WebMCP | `api-probe`, `webmcp`, `playwright-local`/`jack-browser`, `visual-a11y` | `360/390/1280` · `light/dark` · `cs` (and `en` where present) | Public landing, legal/seller lines, auth fail-closed (`401`/`403`), fixture compliance record journeys (staging), branded `404` | Production strictly read-only; no customer records created |
| **Shop & Storefront (Verduona)** | Storefront, WooCommerce Shop, Edge redirects | `api-probe`, `playwright-local`/`jack-browser`, `visual-a11y` | `360/390/1280` · `light/dark` · `en/cs` | HTTP→HTTPS & canonical origin redirects, `prefers-color-scheme: dark` parity, phone header & cookie banner non-overlap on CTA, `/en/` & `/cs/` routes, non-contradictory `Cache-Control`, branded `404` | **ZERO** live orders, payments, cart mutations, or sign-ups on production |
| **Kraliki Sphere** | Auth / Licensing / Billing / Readiness APIs | `api-probe`, `cli-db-probe` (staging/local) | API-only (`N/A` viewports) | `/health` `< 50ms` under load, unauthenticated `/health/ready` minimal payload (no topology leak), `401` fail-closed on protected routes, security headers, `Cache-Control: no-store` on auth endpoints | Read-only probes only on production; zero token minting or seat writes |
| **Si2phone (Multi-Tenant Product)** | Web Console, Telephony/API, WebMCP | `api-probe`, `webmcp`, `playwright-local`, `visual-a11y` | `360/390/1280` · `light/dark` · `en/cs` | Unauthenticated console `401` (zero admin-username leak), per-tenant isolation & live-test floor boundaries (staging/ephemeral PG only), WebMCP contract coverage | **NEVER** touch live customer voice/SMS lines or place real calls/SMS |
| **`si2mac` (macOS Swift App)** | Native macOS SwiftUI/AppKit `.app` | `macos-native` (`swift test` + Paired Mac Device Bridge `app.status` / `window.screenshot` / `window.ax_tree`) | Desktop window · `light/dark` · `en/cs` | `swift test` 0 failures (in-memory secret store), `codesign -dv` valid on release bundles, `0` `DiagnosticReports` crashes, AX tree interactive controls enabled & labeled, Light/Dark window screenshots | **NEVER** read, unlock, or modify macOS Login Keychain or personal licenses |
| **Agent Jack (Web, Desktop Electron, iOS)** | Web Talk UI, Electron Desktop shell, iOS app, MCP API | `api-probe`, `playwright-local`, `visual-a11y`, `electron-desktop`, `ios-simulator` | `360/390/1280` + Desktop + iOS · `light/dark` · `en/cs` | Talk readiness, sign-in handoff, `team.v2.jack.md` preview/import (review-gated capabilities never auto-granted), `http.probe`/`browser.*`/`artifact.attach`/`linear.file_issue` contracts, Electron offline recovery, iOS Simulator launch & safe-area insets | Fixture accounts & isolated `--user-data-dir` only; zero production seat mutations |

### Go / No-Go Release Gate Policy

- **SHIP (`PASS`)**: `0` `FAIL` rows and `0` `BLOCKED` mandatory release-gate rows on the exact release candidate SHA.
- **CONDITIONAL (`BLOCKED` only on non-gating rows)**: Allowed ONLY if every blocker is explicitly documented (e.g., physical-hardware CarPlay check or production read-only guard on a row already verified `PASS` on staging) and signed off by the release owner.
- **HOLD (`FAIL`)**: Any `P0`/`P1` failure (broken sign-in, auth/tenant leak, crash, unreadable primary UI, broken core flow) blocks release automatically until fixed and re-verified `PASS` on the new SHA.

---

## Part 2 — Flagship Commercial Showcase Brief: "QA / E2E Test Engineer Bot" (Agent Jack Business)

### Positioning

**"Hire a QA / E2E Test Engineer Team inside Agent Jack in 5 minutes — zero proprietary test framework lock-in."**

Instead of maintaining brittle, single-purpose test scripts that miss visual regressions, broken dark mode, or backend contract drift, any engineering team on **Agent Jack Business** imports one portable `jack.team` v2 package (`team.v2.jack.md`) and gets a 3-Bot QA squad that tests **webapps, APIs, desktop apps, and mobile simulators** using the exact same general tools every other Jack Bot uses.

### Target Customer ICP

- B2B SaaS & product engineering teams (5–150 engineers) shipping weekly web, API, Electron, macOS, or iOS releases without a large dedicated QA department.
- Agencies and software studios delivering multi-locale, multi-theme client portals that need auditable pre-release evidence packs (`MATRIX.md` + `verdict.json` + screenshots) for client sign-off.

### Why Customers Trust It (Safety & Governance Differentiators)

1. **Zero-Secret Portable Import (`jack.team` v2)**: Importing `team.v2.jack.md` bundles all 5 QA skills while holding every requested capability (`browser.use`, `http.probe`, `linear.file_issue`, `machines.dispatch`) in **pending owner consent** — nothing is ever silently auto-granted.
2. **Strict Team Ceiling**: The QA Team receives ONLY bug-tracker (`linear`) and explicitly registered staging WebMCP servers — never company billing, personal email, or production DNS.
3. **Read-Only Production & Zero-Credential Guarantee**: Hard locks prevent production writes and forbid touching personal credentials or macOS Login Keychain; missing test fixtures produce honest `BLOCKED` rows instead of false `PASS` badges.
4. **Human-in-the-Loop Bug Filing**: Confirmed failures are deduplicated against existing tickets and surfaced via `linear.file_issue` approval cards with screenshots, measured numbers, and exact repro steps before a single issue is created.
5. **Auditable Evidence Packs**: Every run delivers a compact `<= 5`-attachment Talk bundle (`MATRIX.md`, Draft 2020-12 `verdict.json`, ZIP archive, and inline failure PNGs) via `artifact.attach`.

### 5-Minute Live Commercial Demo Script

1. **Minute 1 — Import**: Upload `team.v2.jack.md` in **Settings › Teams › Import Team Package**. Highlight the security preview: 5 skills bundled, `requestedCapabilitiesPendingConsent` explicitly listed for owner checkboxes, 2 routines imported **paused**, zero secrets in the file.
2. **Minute 2 — Scope**: Connect Linear (scoped to the QA Team ceiling) and approve `browser.use`, `http.probe`, `artifact.attach`, and `linear.file_issue` on the imported Bots.
3. **Minute 3 — Run**: Post one plain-English release-check prompt in **E2E QA Desk** against a demo staging URL (`360/390/1280`, `light/dark`, `en/cs`, API headers + browser + visual screenshot inspection).
4. **Minute 4 — Inspect Real Evidence**: Show the Talk reply with inline failure screenshot, downloadable `MATRIX.md`, schema-valid `verdict.json`, and ZIP evidence pack — demonstrating a real visual/layout defect caught by multimodal screenshot inspection (just like M3 Dogfood Run #1 caught dark-mode & phone CTA overlap in production).
5. **Minute 5 — Approve Bug Ticket**: Click **Approve** on the `linear.file_issue` gate card, creating a clean, deduplicated Linear ticket with exact SHA, timestamp, repro steps, and evidence reference.
