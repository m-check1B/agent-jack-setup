---
name: evidence-pack-verdict
description: Use this when assembling an E2E test evidence pack, writing a PASS/FAIL/BLOCKED matrix with exact SHA and timestamps, attaching artifacts via artifact.attach, and filing approval-gated Linear bugs via linear.file_issue.
---

Compile every test run into a single, tamper-evident, zero-fabrication verdict pack and file actionable Linear bug tickets for confirmed failures strictly through Agent Jack's approval gate.

## Zero-Fabrication Rules

1. **No evidence, no PASS.** Every `PASS` cell must cite a concrete observation from THIS run (exact command/tool call, HTTP status, DOM/AX measurement, test count, or inspected screenshot filename). Never carry over a `PASS` from an earlier build or assumption.
2. **Exact provenance header.** Every matrix and JSON verdict MUST record:
   - `app` name and target repository/surface
   - `environment` (`staging` | `production` | `local-fixture`)
   - `buildSha` (exact git SHA or deployed build version; write `"unknown (not exposed by app)"` if unavailable — never invent one)
   - `runTimestampUtc` (exact ISO-8601 UTC timestamp)
   - `approachesUsed` (e.g. `["webmcp", "playwright-local", "api-probe", "visual-a11y"]`, using exact values from `templates/verdict.schema.json`)
   - `runnerSurface` (`paired-mac` | `jack-cloud-computer` | `fly-sandbox` | `hybrid`; never leak private IPs or usernames)
3. **Honest `BLOCKED` classification.** Use `BLOCKED` whenever a row could not run due to missing fixture account, read-only production guard, staging host down, missing OS permission, or an Agent Jack platform gap (cite gap ID `G1`–`G10` when applicable). State the exact unblocker in one sentence.
4. **Strict redaction.** Never include passwords, session cookies, bearer authorization headers, API keys, private emails, or local home-directory paths in matrices, JSON verdicts, or Linear issues.

## Evidence Pack Assembly (Talk Artifacts Budget)

Agent Jack promotes at most **5 attachments per reply** (`TURN_ARTIFACT_LIMIT = 5`, 25 MB archive limit). Promote deliverables directly via **`artifact.attach(filename, client_request_id, text=... | content_base64=..., mime_type=...)`** (preferred on any engine) or by saving under the turn's `outputs/` folder:

1. `MATRIX.md` — Human-readable pass/fail/blocked matrix following `templates/MATRIX.template.md`, ending with the exact reproducible re-run command.
2. `verdict.json` — Machine-readable summary validating strictly against `templates/verdict.schema.json` (`jack.e2e-verdict.v1`, 0 schema errors).
3. `evidence-pack-<app>-<timestamp>.zip` — Complete archive containing all viewport/theme screenshots, redacted console/network logs, API probe transcripts, and native/simulator logs.
4. Up to **2 key failure PNGs** attached directly alongside the ZIP so reviewers immediately see visual failures inline in Talk without unzipping.

## Overall Verdict Logic

- `FAIL`: One or more executed cells failed (`failed > 0`).
- `BLOCKED`: Zero failures, but one or more required release-gate cells were blocked (`failed == 0 && blocked > 0`).
- `PASS`: All required cells executed and passed (`failed == 0 && blocked == 0`).

## Linear Bug Filing Protocol (Approval-Gated)

For every **new** `FAIL` (never file duplicates — search existing open issues first!):

1. **Deduplicate first**:
   - Check open issues via `linear.issues` or the connected Linear OAuth MCP (`linear`).
   - If an open issue already tracks the exact defect, add a fresh comment (`linear.comment` / `evidence.append`) with the new `buildSha` and timestamp instead of creating a duplicate.
   - If a previously filed issue now **passes** on a newer `buildSha`, comment with verification proof (`PASS on <buildSha>`) and leave closing to the owning app team.
2. **Prepare concise, high-signal bug draft**:
   - **Title**: `<App> (<env>): <plain-language symptom> (<viewport/theme/surface>)`
   - **Description**: Environment, URL/surface, exact `buildSha`, UTC timestamp, approach used, 3–6 numbered reproduction steps, Expected vs Actual measurements, screenshot/evidence reference, and recommended priority (`P0` crash/auth/data leak, `P1` blocked core flow/unreadable UI, `P2` layout/theme/i18n/a11y polish).
3. **Human approval gate (`linear.file_issue`)**:
   - Prefer Agent Jack's native approval-gated **`linear.file_issue(team_id, title, client_request_id, description, priority, labels)`** tool, which holds the issue for explicit owner approval before touching Linear (and never auto-approves on unattended routine wakes).
   - If `linear.file_issue` or Linear write access is unavailable on the current seat, output the ready-to-paste draft in the verdict report and record an entry in `linearIssues[]` with `action: "draft-awaiting-approval"` and `status: "pending human approval"` (or `action: "blocked"` and `status: "linear write unavailable"`).

## Final Reply Format

End every test run with:
1. One-line verdict headline: `VERDICT: PASS | FAIL | BLOCKED — <app> (<env>) @ <buildSha> — <pass> pass / <fail> fail / <blocked> blocked`
2. Compact table of failures and blockers only (linking `MATRIX.md`, `verdict.json`, and ZIP pack).
3. Filed / pending-approval Linear ticket links or drafts.
4. Exact next action for the owning engineering team or operator.
