# E2E Verification Matrix — `<app-name>`

## Run Provenance

| Field | Value |
|---|---|
| **App / Target** | `<app-name>` (`<repo-or-surface>`) |
| **Environment** | `staging` \| `production` (read-only) \| `local-fixture` |
| **Base URL / Bundle ID** | `<https://... or com.example.app>` |
| **Build SHA / Version** | `<exact git sha or app version; never guessed>` |
| **Run Timestamp (UTC)** | `<YYYY-MM-DDTHH:MM:SSZ>` |
| **Runner Surface** | `paired-mac` \| `jack-cloud-computer` \| `fly-sandbox` \| `hybrid` |
| **Approaches Executed** | `webmcp`, `playwright-local`, `jack-browser`, `api-probe`, `cli-db-probe`, `visual-a11y`, `macos-native`, `electron-desktop`, `ios-simulator` |
| **Overall Verdict** | `PASS` \| `FAIL` \| `BLOCKED` (`<P> pass / <F> fail / <B> blocked`) |

## Summary of Failures & Blockers

| Row ID | Status | Surface / Viewport / Theme / Locale | Symptom / Blocker Reason | Evidence / Linear Issue |
|---|---|---|---|---|
| `R-01` | `FAIL` | `browser · 390x844 · dark · cs` | Example: primary CTA contrast `2.1:1 < 4.5:1` | `screenshots/r01-390-dark-cs.png` · `KRA-XXXX` (pending approval) |
| `R-02` | `BLOCKED` | `browser · signed-in` | No staging fixture account provisioned | Needs fixture user grant |

## Multi-Approach Verification Matrix

| Row ID | Journey / Check | WebMCP | Browser / App | API / CLI | 360 / 390 / 1280 | Light / Dark | Locales | Status | Evidence (exact observation) |
|---|---|---|---|---|---|---|---|---|---|
| `W-01` | Health, TLS, security headers, build SHA | `N/A` | `N/A` | `PASS` | `N/A` | `N/A` | `N/A` | `PASS` | `GET /health -> 200 (42ms), sha=<sha>, HSTS+nosniff present` |
| `W-02` | Signed-out landing, nav chrome, legal links, 404 | `PASS` | `PASS` | `PASS` | `PASS` | `PASS` | `PASS` | `PASS` | `0 console errors, 0 pageerror, 0 clipped controls, 404 branded` |
| `W-03` | Cookie banner & clean-profile cookie flags | `N/A` | `PASS` | `N/A` | `PASS` | `PASS` | `PASS` | `PASS` | `Locale matches active UI; pre-auth cookies clean (values redacted)` |
| `W-04` | Auth fail-closed & invite gate (uninvited user) | `PASS` | `BLOCKED` | `PASS` | `N/A` | `N/A` | `N/A` | `BLOCKED` | `API returns 401; browser gate needs uninvited fixture user` |
| `W-05` | Signed-in primary journey 1 (fixture account) | `PASS` | `PASS` | `PASS` | `PASS` | `PASS` | `PASS` | `PASS` | `WebMCP & UI agree; state survives reload; [e2e] prefix used` |
| `W-06` | Signed-in primary journey 2 (fixture account) | `PASS` | `PASS` | `PASS` | `PASS` | `PASS` | `PASS` | `PASS` | `Zero failed XHRs; tenant isolation verified (cross-ID -> 404)` |
| `W-07` | Signed-in primary journey 3 (fixture account) | `PASS` | `PASS` | `PASS` | `PASS` | `PASS` | `PASS` | `PASS` | `Keyboard Tab/Escape & focus ring verified; sign-out clears session` |
| `N-01` | Desktop / Native app launch, signature & AX tree | `N/A` | `PASS` | `PASS` | `N/A` | `PASS` | `PASS` | `PASS` | `Paired Mac: codesign valid, 0 crash logs, primary AX controls live` |
| `N-02` | Mobile / iOS Simulator install, launch & deep link | `N/A` | `PASS` | `N/A` | `PASS` | `PASS` | `PASS` | `PASS` | `simctl boot+install+screenshot OK; safe-area insets intact` |

## Artifacts Attached (`outputs/`)

- `MATRIX.md` — this verification matrix
- `verdict.json` — machine-readable verdict conforming to `verdict.schema.json`
- `evidence-pack-<app>-<timestamp>.zip` — full screenshots, redacted console/network/API logs, AX/simulator dumps
- Key inline failure screenshots (at most 2 PNGs directly attached to stay within Jack's 5-attachment turn cap)

## Exact Re-Run Command

```bash
# Record the exact command or Talk prompt needed to reproduce this run verbatim
# Example (Paired Mac / Local route):
# /webapp-e2e target=<https://staging.example.com> env=staging locales=en,cs viewports=360,390,1280 themes=light,dark
```
