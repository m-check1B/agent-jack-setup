# Agent Jack Use-Case: Multi-Approach E2E Test Agent

A portable, versioned **Agent Jack Use-Case** for end-to-end testing of **web applications, HTTP/API backends, native desktop apps (macOS Swift, Electron/WebView), and mobile builds (iOS Simulator)**.

> **Architectural Boundary**: This package lives **outside** `agent-jack-3` core. It uses Agent Jack's real portable packaging formats (`jack.team` v1, `jack.skill-bundle.v1`, and `TemplateShareSnapshotV1`) plus taught skills and declarative toolbelt presets — never a hardcoded test-agent monolith inside Agent Jack.

## What's Inside

| Path | Purpose | Validated Against |
|---|---|---|
| [`team.v2.jack.md`](team.v2.jack.md) | **Recommended (`jack.team` v2)**: 3-Bot Team package bundling all 5 taught `skill_definitions` inline, explicit review-gated `requested_capabilities` (held for owner consent — never auto-granted), and non-secret `webmcp_servers` hints | `agent-jack-3` `team_package.parse_team_markdown` v2, `render_team_markdown`, `TeamPackageService.preview` |
| [`team.jack.md`](team.jack.md) | Backwards-compatible `jack.team` v1 Team Package (`E2E QA Lead`, `Web & API Tester`, `Desktop & Mobile Tester`), `E2E QA Desk` group, `E2E Test Team` hierarchy, `linear` connector requirement, and 2 paused routines | `agent-jack-3` `team_package.parse_team_markdown` v1, `render_team_markdown`, `TeamPackageService.preview`, `routine_scheduler` |
| [`bot-template.v1.json`](bot-template.v1.json) | Single-Bot portable snapshot (`TemplateShareSnapshotV1`) for solo seats wanting one unified QA Bot with all 5 skills, `browser.use`, and `linear` pre-wired | `agent-jack-3` `schemas.v1.template_share.TemplateShareSnapshotV1` |
| [`skills/`](skills/) | 5 taught skills (`webapp-e2e`, `api-contract-probe`, `visual-a11y-audit`, `desktop-mobile-e2e`, `evidence-pack-verdict`) + SHA-256-verified [`skills/BUNDLE.json`](skills/BUNDLE.json) | `agent-jack-3` `skill_catalog._builtin_skill_texts`, `_frontmatter`, `split_sections`, `INSTRUCTIONS_MAX` (32 KB) |
| [`toolbelt-preset.json`](toolbelt-preset.json) | Non-secret capability, WebMCP, connector, team-ceiling, and approval preset guide | `scripts/validate_bundle.py` |
| [`templates/MATRIX.template.md`](templates/MATRIX.template.md) | Standardized PASS / FAIL / BLOCKED verification matrix template | Human + `evidence-pack-verdict` skill |
| [`templates/verdict.schema.json`](templates/verdict.schema.json) | JSON Schema (`jack.e2e-verdict.v1`) for machine-readable run verdicts | `scripts/validate_bundle.py` |
| [`templates/verdict.sample.json`](templates/verdict.sample.json) | Canonical sample verdict fixture validated against `verdict.schema.json` | `scripts/validate_bundle.py` |
| [`M1-CAPABILITY-GAP-AUDIT.md`](M1-CAPABILITY-GAP-AUDIT.md) | Read-only audit of `agent-jack-3` tracking existing strengths and 10 surgical general platform gaps (`G1`–`G10`, with merged PR status) | Audited directly on `agent-jack-3` `origin/master` |
| [`M3-DOGFOOD-RUNBOOK.md`](M3-DOGFOOD-RUNBOOK.md) | Step-by-step live dogfood execution runbook (1 staging webapp + `si2mac` desktop check inside Agent Jack) | M3 acceptance checklist |
| [`M4-RELEASE-GATE-PLAYBOOK.md`](M4-RELEASE-GATE-PLAYBOOK.md) | Multi-app release-gate workflow across every Ocelot product + flagship Agent Jack Business showcase brief ("QA / E2E Test Engineer Bot") | M4 release-gate & commercial showcase |
| [`scripts/validate_bundle.py`](scripts/validate_bundle.py) | Standalone + live `agent-jack-3` parser verification script (v1 + v2 + skills + Draft 2020-12 verdict schema) | Python 3.11+ |

## Quick Start (Import Into Agent Jack)

### Option A — 3-Bot QA Team (`team.jack.md`)

1. **Import the Team package**: In Agent Jack, open **Settings › Teams › Import Team Package** and upload `team.jack.md`. Review the preview (3 Bots, 1 Group, 1 Team, 1 unbound `linear` connector, 2 paused routines) and confirm import.
2. **Attach the 5 taught skills** (until `jack.team` v2 gap `G9` lands): Copy `skills/*` into `~/.agent-jack/skills/` (or install each `SKILL.md` onto the corresponding Bot in **Bot Settings › Skills**):
   - **E2E QA Lead**: `evidence-pack-verdict`, `webapp-e2e`
   - **Web & API Tester**: `webapp-e2e`, `api-contract-probe`, `visual-a11y-audit`, `evidence-pack-verdict`
   - **Desktop & Mobile Tester**: `desktop-mobile-e2e`, `visual-a11y-audit`, `evidence-pack-verdict`
3. **Grant capabilities & connectors** (guided by [`toolbelt-preset.json`](toolbelt-preset.json)):
   - Connect **Linear** in **Plugins** and bind it to the `E2E Test Team` ceiling (never mount personal email, billing, or DNS connectors on the QA Team).
   - Enable `browser.use` on **Web & API Tester** (and register your staging WebMCP servers on the seat/Team).
   - Route **Web & API Tester** (recommended today) and **Desktop & Mobile Tester** (required for macOS/Electron/iOS Simulator) to your **Paired Mac** via Tentacles (`Local Claude` or `Local Codex`).
4. **Run your first verification** in **E2E QA Desk**:
   ```text
   Run a staging E2E verification of <App Name> at <https://staging.example.com> (locales: en, cs; viewports: 360, 390, 1280; themes: light, dark). Use WebMCP + clean-profile browser + API health/auth probes. Produce MATRIX.md, verdict.json, and a ZIP evidence pack. Ask before filing any Linear issues.
   ```

### Option B — Single Unified QA Bot (`bot-template.v1.json`)

Use [`bot-template.v1.json`](bot-template.v1.json) as the canonical `TemplateShareSnapshotV1` payload when provisioning a single-Bot QA seat (includes all 5 inline `skillDefinitions`, `browser.use` capability, and `linear` plugin hint).

## Safety Invariants (Non-Negotiable)

- **Staging first; production is strictly read-only**: No form submits, orders, payments, or sign-ups on production.
- **No personal or Founder credentials**: Signed-in tests use dedicated fixture accounts; missing fixtures are recorded honestly as `BLOCKED`.
- **Zero app-repo writes**: The Test Agent never pushes commits or patches target repos; confirmed failures become approval-gated Linear issues.
- **Zero fabrication**: Every `PASS` requires exact `buildSha`, UTC timestamp, and fresh evidence from the current run. Missing platform capabilities are recorded honestly with their gap ID (`G1`–`G10`).

## Validating This Bundle Locally

```bash
# Standalone structural, SHA-256, frontmatter, and secret-hygiene validation:
python3 use-cases/e2e-test-agent/scripts/validate_bundle.py

# Full validation against agent-jack-3's real Python parsers & Pydantic schemas:
/path/to/agent-jack-3/api/.venv/bin/python \
  use-cases/e2e-test-agent/scripts/validate_bundle.py \
  --jack-api-src /path/to/agent-jack-3/api/src
```
