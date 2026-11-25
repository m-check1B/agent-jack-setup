#!/usr/bin/env python3
"""Validate (or sync checksums & v2 manifest for) the portable Agent Jack E2E Test Agent bundle.

Modes:
  python3 validate_bundle.py
      Standalone check (stdlib only): verifies BUNDLE.json SHA-256s, SKILL.md
      frontmatter & 32 KB Bot cap, JSON syntax, verdict schema + sample verdict
      fixture, bot-template skill coverage & sync, team.v2.jack.md presence &
      skill sync, and zero secret/internal-host leaks.

  python3 validate_bundle.py --sync
      Updates skills/BUNDLE.json SHA-256 digests, bot-template.v1.json inline
      skillDefinitions, and team.v2.jack.md (jack.team version 2) from
      skills/*/SKILL.md, then runs validation.

  /path/to/agent-jack-3/api/.venv/bin/python validate_bundle.py \\
      --jack-api-src /path/to/agent-jack-3/api/src
      Additionally imports Agent Jack's real parsers and schemas (read-only):
        - jack_api.team_package.{parse_team_markdown, render_team_markdown, package_digest}
        - jack_api.team_package_store.{MemoryTeamPackageStore, TeamPackageService}
        - jack_api.routine_scheduler.routine_schedule_supported
        - jack_api.skill_catalog.{_builtin_skill_texts, _frontmatter, split_sections, INSTRUCTIONS_MAX}
        - jack_api.schemas.v1.template_share.TemplateShareSnapshotV1
      Validates BOTH team.jack.md (version 1) AND team.v2.jack.md (version 2)!
"""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path
from typing import Any

BUNDLE_ROOT = Path(__file__).resolve().parents[1]
SKILLS_DIR = BUNDLE_ROOT / "skills"
TEAM_MD = BUNDLE_ROOT / "team.jack.md"
TEAM_V2_MD = BUNDLE_ROOT / "team.v2.jack.md"
BOT_TEMPLATE = BUNDLE_ROOT / "bot-template.v1.json"
TOOLBELT_PRESET = BUNDLE_ROOT / "toolbelt-preset.json"
MATRIX_TEMPLATE = BUNDLE_ROOT / "templates" / "MATRIX.template.md"
VERDICT_SCHEMA = BUNDLE_ROOT / "templates" / "verdict.schema.json"
VERDICT_SAMPLE = BUNDLE_ROOT / "templates" / "verdict.sample.json"
BUNDLE_JSON = SKILLS_DIR / "BUNDLE.json"

SKILL_ORDER = (
    "webapp-e2e",
    "api-contract-probe",
    "visual-a11y-audit",
    "desktop-mobile-e2e",
    "evidence-pack-verdict",
)

SKILL_TITLES = {
    "webapp-e2e": "Webapp E2E Verification",
    "api-contract-probe": "API & CLI Contract Probe",
    "visual-a11y-audit": "Visual & Accessibility Audit",
    "desktop-mobile-e2e": "Desktop & Mobile Native E2E",
    "evidence-pack-verdict": "Evidence Pack & Verdict Filing",
}

V2_MEMBER_SKILLS = {
    "e2e-lead": ("evidence-pack-verdict", "webapp-e2e"),
    "web-api-tester": (
        "webapp-e2e",
        "api-contract-probe",
        "visual-a11y-audit",
        "evidence-pack-verdict",
    ),
    "native-app-tester": (
        "desktop-mobile-e2e",
        "visual-a11y-audit",
        "evidence-pack-verdict",
    ),
}

V2_MEMBER_CAPABILITIES = {
    "e2e-lead": ("linear.read", "linear.file_issue", "artifact.attach"),
    "web-api-tester": ("browser.use", "http.probe", "webmcp.call", "artifact.attach", "sandbox.fly"),
    "native-app-tester": ("tentacles.hire", "machines.dispatch", "artifact.attach"),
}

V2_MEMBER_WEBMCP = {
    "e2e-lead": (),
    "web-api-tester": (
        {
            "id": "target-app-staging",
            "label": "Target App Staging WebMCP (replace with your staging URL)",
            "url": "https://staging.example.com/webmcp",
        },
    ),
    "native-app-tester": (),
}

SKIP_SCAN_DIR_NAMES = frozenset({"__pycache__", ".git", ".pytest_cache"})
SKIP_SCAN_SUFFIXES = frozenset({".pyc", ".pyo", ".pyd"})
SKIP_SCAN_FILE_NAMES = frozenset({".DS_Store", "validate_bundle.py"})

SKILL_NAME_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
FRONTMATTER_RE = re.compile(r"\A---\s*\n(.*?)\n---\s*\n?(.*)\Z", re.DOTALL)
NAME_LINE_RE = re.compile(r"^name:\s*[\"']?([^\"'\n]+?)[\"']?\s*$", re.MULTILINE)
DESC_LINE_RE = re.compile(r"^description:\s*[\"']?([^\"'\n]+?)[\"']?\s*$", re.MULTILINE)
INSTRUCTIONS_MAX = 32_768
MAX_V2_MEMBER_SKILLS_BYTES = 32_768

SECRET_OR_INTERNAL_PATTERNS = (
    re.compile(r"(?<![A-Za-z0-9])sk-"),
    re.compile(r"BEGIN (?:RSA )?PRIVATE KEY"),
    re.compile(r"ghp_|github_pat_|xoxb-|xoxp-|ya29\.|AKIA|CANARY-SECRET"),
    re.compile(r"\.ts\.net|ocelotnas|192\.168\.", re.I),
)


def parse_skill_frontmatter(text: str) -> tuple[dict[str, str], str]:
    match = FRONTMATTER_RE.match(text)
    if not match:
        raise ValueError("missing YAML frontmatter")
    raw, body = match.group(1), match.group(2)
    meta: dict[str, str] = {}
    name_m = NAME_LINE_RE.search(raw)
    desc_m = DESC_LINE_RE.search(raw)
    if name_m:
        meta["name"] = name_m.group(1).strip()
    if desc_m:
        meta["description"] = desc_m.group(1).strip()
    return meta, body.strip()


def _yaml_block(text: str, indent: int) -> list[str]:
    prefix = " " * indent
    return [f"{prefix}{line}" if line else "" for line in text.splitlines()]


def _render_team_v2_markdown(skills_data: dict[str, tuple[str, str]]) -> str:
    """Render jack.team version 2 Markdown with synced skill_definitions & review-gated capabilities."""
    members_spec = (
        {
            "key": "e2e-lead",
            "name": "E2E QA Lead",
            "title": "Release Gate & Evidence Coordinator",
            "domain": "quality-assurance",
            "playbook": (
                "You lead the Multi-Approach E2E Test Team running on Agent Jack.\n\n"
                "Operating principles:\n"
                "1. Never modify target application repositories. You test, verify, collect evidence, and file bugs.\n"
                "2. Staging first; production is strictly read-only (never submit forms, place orders, trigger payments, or sign up accounts on production).\n"
                "3. Never ask for, read, type, or store personal or Founder passwords, keys, or 2FA codes. Signed-in flows require a designated test fixture account; mark missing-fixture rows BLOCKED with the exact prerequisite.\n"
                "4. Zero fabrication: every PASS cell must cite concrete evidence from THIS run (exact build SHA, UTC timestamp, tool/command output, HTTP status, DOM/AX measurement, or inspected screenshot).\n"
                "5. Coordinate specialists in E2E QA Desk: assign WebMCP, browser, visual/a11y, and HTTP/API contract rows to Web & API Tester; assign macOS native, Electron/WebView, and iOS Simulator rows to Desktop & Mobile Tester.\n"
                "6. Follow `evidence-pack-verdict` to attach `MATRIX.md`, `verdict.json`, and `evidence-pack-<app>-<timestamp>.zip` via `artifact.attach`, deduplicate open Linear tickets, and propose new failures strictly via approval-gated `linear.file_issue`."
            ),
            "hat_name": "e2e-lead",
            "hat_title": "E2E QA Lead",
            "locks": (
                "read-only-production",
                "no-app-repo-writes",
                "no-personal-credentials",
                "approval-before-issue-filing",
                "zero-fabricated-pass",
            ),
        },
        {
            "key": "web-api-tester",
            "name": "Web & API Tester",
            "title": "WebMCP, Browser, Visual/A11y & API Specialist",
            "domain": "webapp-and-api-testing",
            "playbook": (
                "You execute multi-approach verification for web applications and HTTP/API backends.\n\n"
                "Follow your bundled skills in order:\n"
                "1. `webapp-e2e`: discover and run WebMCP tools (`webmcp.list`, `webmcp.call`), then run clean-profile browser journeys via Jack `browser.*` (`browser.inventory`, `browser.navigate`, `browser.console`, `browser.network`, `browser.screenshot`) or Paired Mac Playwright.\n"
                "2. `api-contract-probe`: verify health/readiness, TLS, redirects, security headers, non-contradictory `Cache-Control`, auth fail-closed boundaries, and JSON contracts via `http.probe` or local CLI.\n"
                "3. `visual-a11y-audit`: inspect `360x800`, `390x844`, and `1280x800` viewports across `light`/`dark` themes and active locales (`en`/`cs`), checking bounding-box clipping, phone pane height, WCAG contrast, and visual screenshots.\n\n"
                "Honesty rule: mark any unverified sub-check BLOCKED with exact prerequisite or gap ID rather than claiming PASS. Hand structured per-cell results and screenshots back to E2E QA Lead."
            ),
            "hat_name": "web-api-tester",
            "hat_title": "Web & API Tester",
            "locks": (
                "read-only-production",
                "no-app-repo-writes",
                "clean-browser-profile",
                "redact-auth-and-cookies",
                "no-unverified-pass",
            ),
        },
        {
            "key": "native-app-tester",
            "name": "Desktop & Mobile Tester",
            "title": "macOS, Electron & iOS Simulator Specialist",
            "domain": "desktop-and-mobile-testing",
            "playbook": (
                "You verify native desktop applications (macOS Swift/AppKit/SwiftUI, Electron/WebView shells) and mobile builds (iOS Simulator / XCTest) using Paired Mac Device Bridge (`machines.dispatch`: `app.status`, `window.screenshot`, `window.ax_tree`) and Tentacles local routes.\n\n"
                "Follow your bundled skill `desktop-mobile-e2e`:\n"
                "1. Confirm a Paired Mac is connected before running native or simulator checks. If offline or missing macOS Screen Recording / Accessibility / Xcode permissions, mark rows BLOCKED with the exact prerequisite.\n"
                "2. Launch native and Electron apps strictly with isolated fixture data directories; never read, unlock, or modify macOS Login Keychain or personal accounts.\n"
                "3. Record exact app version, build SHA, OS/Swift/Xcode/Electron versions, test counts, crash-log check, AX tree status, and Light/Dark window screenshots.\n"
                "4. Mark physical-hardware-only checks BLOCKED with crisp human verification steps. Hand structured findings to E2E QA Lead."
            ),
            "hat_name": "native-app-tester",
            "hat_title": "Desktop & Mobile Tester",
            "locks": (
                "paired-mac-isolated-fixtures",
                "no-app-repo-writes",
                "no-personal-keychain-or-accounts",
                "fail-honest-when-unattached",
            ),
        },
    )

    lines: list[str] = [
        "---",
        "format: jack.team",
        "version: 2",
        'name: "Multi-Approach E2E Test Agent"',
        "members:",
    ]
    for m in members_spec:
        key = m["key"]
        member_skills = V2_MEMBER_SKILLS[key]
        total_bytes = sum(len(skills_data[slug][1].encode("utf-8")) for slug in member_skills)
        if total_bytes > MAX_V2_MEMBER_SKILLS_BYTES:
            raise ValueError(
                f"team.v2.jack.md member {key} skill_definitions total {total_bytes} > {MAX_V2_MEMBER_SKILLS_BYTES} bytes"
            )
        lines.extend(
            [
                f"  - key: {key}",
                f'    name: {json.dumps(m["name"], ensure_ascii=True)}',
                f'    title: {json.dumps(m["title"], ensure_ascii=True)}',
                f'    domain: {json.dumps(m["domain"], ensure_ascii=True)}',
                "    playbook: |",
                *_yaml_block(m["playbook"], 6),
                "    hat:",
                f'      name: {m["hat_name"]}',
                f'      title: {json.dumps(m["hat_title"], ensure_ascii=True)}',
                "      locks:",
                *[f"        - {lock}" for lock in m["locks"]],
                "      tools:",
                "        - talk.read",
                "    skills:",
                *[f"      - {slug}" for slug in member_skills],
                "    skill_definitions:",
            ]
        )
        for slug in member_skills:
            desc, body = skills_data[slug]
            lines.extend(
                [
                    f"      - slug: {slug}",
                    f"        name: {json.dumps(SKILL_TITLES[slug], ensure_ascii=True)}",
                    f"        description: {json.dumps(desc, ensure_ascii=True)}",
                    "        body: |-",
                    *_yaml_block(body, 10),
                ]
            )
        caps = V2_MEMBER_CAPABILITIES[key]
        lines.append("    requested_capabilities:")
        lines.extend(f"      - {cap}" for cap in caps)
        webmcp = V2_MEMBER_WEBMCP[key]
        if webmcp:
            lines.append("    webmcp_servers:")
            for srv in webmcp:
                lines.extend(
                    [
                        f'      - id: {srv["id"]}',
                        f'        label: {json.dumps(srv["label"], ensure_ascii=True)}',
                        f'        url: {json.dumps(srv["url"], ensure_ascii=True)}',
                    ]
                )

    lines.extend(
        [
            "groups:",
            "  - key: e2e-qa-desk",
            '    name: "E2E QA Desk"',
            "    members:",
            "      - e2e-lead",
            "      - web-api-tester",
            "      - native-app-tester",
            "connectors:",
            "  - connector: linear",
            '    alias: "bug-tracker"',
            "routines:",
            "  - key: daily-staging-smoke",
            "    member: web-api-tester",
            '    title: "Daily Staging Read-Only Smoke"',
            '    schedule: "weekdays at 08:00 UTC"',
            "    instructions: |",
            "      Run a read-only multi-approach smoke check on the staging URLs listed in the Talk pinned context (`http.probe` health/headers, WebMCP tool inventory, and signed-out landing/404/legal checks).",
            "      If a routine turn lacks browser or Paired Mac opt-in (Agent Jack gap G8), execute `http.probe` + WebMCP probes only and mark browser/native rows BLOCKED (G8).",
            "      Post a compact PASS/FAIL/BLOCKED digest to E2E QA Desk; unattended routines never auto-approve `linear.file_issue`.",
            "    paused: true",
            "  - key: release-gate-triage",
            "    member: e2e-lead",
            '    title: "Open E2E Failure Re-Verification Reminder"',
            '    schedule: "daily at 07:30 UTC"',
            "    instructions: |",
            "      Check open E2E bug tickets via the connected Linear bug-tracker (`bug-tracker`) for items marked ready for re-test or updated since the last run.",
            "      Summarize which apps and build SHAs are due for a fresh multi-approach verification run in E2E QA Desk and wait for operator confirmation before dispatching checks.",
            "    paused: true",
            "teams:",
            "  - key: e2e-qa-team",
            '    name: "E2E Test Team"',
            "    chief: e2e-lead",
            "    members:",
            "      - e2e-lead",
            "      - web-api-tester",
            "      - native-app-tester",
            "---",
            "",
            "# Multi-Approach E2E Test Agent (`jack.team` v2)",
            "",
            "Portable Agent Jack Team package (`jack.team` v2) bundling all 5 taught skills inline, explicit review-gated `requested_capabilities` (held for owner consent at import — never auto-granted), and non-secret `webmcp_servers` hints.",
            "",
            "For seats still on `jack.team` v1, use the backwards-compatible `team.jack.md` + `skills/` bundle.",
            "",
        ]
    )
    return "\n".join(lines)


def sync_generated_manifests() -> None:
    skills_manifest: dict[str, dict[str, str]] = {}
    skill_defs: list[dict[str, str]] = []
    skills_data: dict[str, tuple[str, str]] = {}
    for slug in SKILL_ORDER:
        skill_path = SKILLS_DIR / slug / "SKILL.md"
        raw_bytes = skill_path.read_bytes()
        text = raw_bytes.decode("utf-8")
        meta, body = parse_skill_frontmatter(text)
        if meta.get("name") != slug:
            raise ValueError(f"{skill_path}: frontmatter name {meta.get('name')!r} != {slug!r}")
        skills_manifest[slug] = {"sha256": hashlib.sha256(raw_bytes).hexdigest()}
        skill_defs.append({"name": slug, "instructions": body})
        skills_data[slug] = (meta.get("description", ""), body)

    bundle_payload = {
        "schema": "jack.skill-bundle.v1",
        "version": 1,
        "skills": skills_manifest,
    }
    BUNDLE_JSON.write_text(json.dumps(bundle_payload, indent=2) + "\n", encoding="utf-8")

    bot_payload = {
        "name": "Multi-Approach E2E Test Agent",
        "domain": "quality-assurance",
        "kind": "specialist",
        "instructions": (
            "You are the Multi-Approach E2E Test Agent running on Agent Jack. "
            "Test web applications, HTTP/API backends, native desktop apps (macOS/Electron), "
            "and mobile builds (iOS Simulator) using WebMCP, Jack browser tools / clean-profile "
            "Playwright, http.probe, visual/a11y audits, and Paired Mac Device Bridge / Tentacles. "
            "Hard rules: staging first; production is strictly read-only; never ask for or use "
            "personal/Founder credentials (use fixture accounts or mark BLOCKED); never touch "
            "macOS Login Keychain; never modify target app repositories; never fabricate PASS "
            "results; always attach MATRIX.md, verdict.json, and a ZIP evidence pack via "
            "artifact.attach with exact build SHA and UTC timestamp; and propose new Linear "
            "bugs strictly through approval-gated linear.file_issue."
        ),
        "avatar": {
            "kind": "face",
            "shape": "shield",
            "color": "#0F766E",
            "crest": "none",
            "eyes": "dot",
            "tilt": 0,
            "spacing": 16,
            "eyeX": 0,
            "eyeY": 0,
            "mouth": False,
        },
        "skills": list(SKILL_ORDER),
        "skillDefinitions": skill_defs,
        "skillsCount": len(SKILL_ORDER),
        "plugins": ["linear"],
        "mcpPresets": ["linear"],
        "capabilities": ["browser.use"],
        "routines": [
            {
                "kind": "pulse",
                "title": "Open E2E Failure Re-Verification Reminder",
                "schedule": "daily at 07:30 UTC",
                "prompt": (
                    "Check open E2E bug tickets in Linear for items ready for re-verification. "
                    "Summarize which apps and build SHAs are due for a fresh multi-approach "
                    "run and wait for operator confirmation before running tests."
                ),
                "enabled": False,
            }
        ],
        "routinesCount": 1,
        "preferences": (
            "Use Jack's native http.probe, browser.console/network/screenshot, artifact.attach, "
            "and approval-gated linear.file_issue first; use Paired Mac Device Bridge "
            "(app.status, window.screenshot, window.ax_tree) and Tentacles for native/mobile "
            "and full viewport/theme Playwright sweeps. Keep output concise: verdict headline, "
            "failures/blockers table, attached evidence pack, and Linear ticket links."
        ),
        "preferencesRouted": False,
    }
    BOT_TEMPLATE.write_text(json.dumps(bot_payload, indent=2) + "\n", encoding="utf-8")

    TEAM_V2_MD.write_text(_render_team_v2_markdown(skills_data), encoding="utf-8")
    print("Synced skills/BUNDLE.json, bot-template.v1.json, and team.v2.jack.md from skills/*/SKILL.md")


def _should_skip_scan(path: Path) -> bool:
    rel_parts = path.relative_to(BUNDLE_ROOT).parts
    if any(part in SKIP_SCAN_DIR_NAMES for part in rel_parts):
        return True
    if path.name in SKIP_SCAN_FILE_NAMES:
        return True
    if path.suffix.lower() in SKIP_SCAN_SUFFIXES:
        return True
    return False


def _validate_sample_verdict_stdlib(
    schema: dict[str, Any], sample: dict[str, Any]
) -> list[str]:
    """Check sample verdict against verdict.schema.json using stdlib only."""
    errors: list[str] = []
    props = schema.get("properties", {})
    allowed_top = set(props)
    missing_req = [k for k in schema.get("required", []) if k not in sample]
    if missing_req:
        errors.append(f"verdict.sample.json missing required fields: {missing_req}")
    extra_top = set(sample) - allowed_top
    if schema.get("additionalProperties") is False and extra_top:
        errors.append(f"verdict.sample.json has unexpected top-level fields: {sorted(extra_top)}")

    if sample.get("schemaVersion") != props.get("schemaVersion", {}).get("const"):
        errors.append("verdict.sample.json schemaVersion mismatch")

    for field in ("environment", "runnerSurface", "verdict"):
        allowed = set(props.get(field, {}).get("enum", []))
        if sample.get(field) not in allowed:
            errors.append(f"verdict.sample.json {field}={sample.get(field)!r} not in {sorted(allowed)}")

    allowed_approaches = set(props.get("approachesUsed", {}).get("items", {}).get("enum", []))
    approaches = sample.get("approachesUsed")
    if not isinstance(approaches, list) or not approaches or not set(approaches).issubset(allowed_approaches):
        errors.append("verdict.sample.json approachesUsed invalid")

    row_props = props.get("rows", {}).get("items", {}).get("properties", {})
    row_req = set(props.get("rows", {}).get("items", {}).get("required", []))
    allowed_row_status = set(row_props.get("status", {}).get("enum", []))
    rows = sample.get("rows")
    if not isinstance(rows, list) or not rows:
        errors.append("verdict.sample.json rows must be a non-empty list")
    else:
        for idx, row in enumerate(rows):
            if not isinstance(row, dict) or not row_req.issubset(row):
                errors.append(f"verdict.sample.json rows[{idx}] missing required keys")
                continue
            if row.get("approach") not in allowed_approaches:
                errors.append(f"verdict.sample.json rows[{idx}].approach invalid: {row.get('approach')!r}")
            if row.get("status") not in allowed_row_status:
                errors.append(f"verdict.sample.json rows[{idx}].status invalid: {row.get('status')!r}")

    issue_props = props.get("linearIssues", {}).get("items", {}).get("properties", {})
    issue_req = set(props.get("linearIssues", {}).get("items", {}).get("required", []))
    allowed_actions = set(issue_props.get("action", {}).get("enum", []))
    for idx, item in enumerate(sample.get("linearIssues", [])):
        if not isinstance(item, dict) or not issue_req.issubset(item):
            errors.append(f"verdict.sample.json linearIssues[{idx}] missing required keys")
            continue
        if item.get("action") not in allowed_actions:
            errors.append(f"verdict.sample.json linearIssues[{idx}].action invalid: {item.get('action')!r}")

    artifacts = sample.get("artifacts")
    if not isinstance(artifacts, list) or not 1 <= len(artifacts) <= 5:
        errors.append("verdict.sample.json artifacts must have 1..5 items")

    return errors


def _validate_sample_verdict_jsonschema(
    schema: dict[str, Any], sample: dict[str, Any]
) -> list[str]:
    try:
        import jsonschema  # type: ignore[import-not-found]
    except ImportError:
        return []
    try:
        jsonschema.Draft202012Validator.check_schema(schema)
        jsonschema.validate(sample, schema, cls=jsonschema.Draft202012Validator)
    except Exception as exc:
        return [f"verdict.sample.json failed Draft202012Validator: {exc}"]
    return []


def validate_standalone() -> list[str]:
    errors: list[str] = []

    # 1. Check all text files for secret or internal-host leaks (skip bytecode/caches)
    for path in sorted(BUNDLE_ROOT.rglob("*")):
        if not path.is_file() or _should_skip_scan(path):
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError as exc:
            errors.append(f"{path.relative_to(BUNDLE_ROOT)}: non-UTF-8 file in bundle ({exc})")
            continue
        for pat in SECRET_OR_INTERNAL_PATTERNS:
            if pat.search(text):
                errors.append(
                    f"{path.relative_to(BUNDLE_ROOT)}: matched forbidden pattern {pat.pattern!r}"
                )

    # 2. Check skills/BUNDLE.json and each SKILL.md
    try:
        bundle = json.loads(BUNDLE_JSON.read_text(encoding="utf-8"))
    except Exception as exc:
        errors.append(f"skills/BUNDLE.json invalid JSON: {exc}")
        return errors

    if bundle.get("schema") != "jack.skill-bundle.v1" or bundle.get("version") != 1:
        errors.append("skills/BUNDLE.json must have schema='jack.skill-bundle.v1' and version=1")

    listed = bundle.get("skills", {})
    if tuple(listed.keys()) != SKILL_ORDER:
        errors.append(f"skills/BUNDLE.json keys {tuple(listed.keys())} != expected {SKILL_ORDER}")

    skill_bodies: dict[str, str] = {}
    skills_data: dict[str, tuple[str, str]] = {}
    for slug in SKILL_ORDER:
        skill_path = SKILLS_DIR / slug / "SKILL.md"
        if not skill_path.is_file():
            errors.append(f"missing {skill_path.relative_to(BUNDLE_ROOT)}")
            continue
        raw = skill_path.read_bytes()
        text = raw.decode("utf-8")
        if len(text) > INSTRUCTIONS_MAX:
            errors.append(f"{slug}: {len(text)} chars exceeds INSTRUCTIONS_MAX ({INSTRUCTIONS_MAX})")
        digest = hashlib.sha256(raw).hexdigest()
        expected = listed.get(slug, {}).get("sha256")
        if digest != expected:
            errors.append(f"{slug}: sha256 {digest} != BUNDLE.json {expected}")
        try:
            meta, body = parse_skill_frontmatter(text)
        except ValueError as exc:
            errors.append(f"{slug}: {exc}")
            continue
        if meta.get("name") != slug or not SKILL_NAME_RE.fullmatch(slug):
            errors.append(f"{slug}: frontmatter name {meta.get('name')!r} mismatch")
        if not meta.get("description"):
            errors.append(f"{slug}: missing single-line description in frontmatter")
        if "## " not in body:
            errors.append(f"{slug}: expected top-level '## ' sections for skill.section loading")
        skill_bodies[slug] = body
        skills_data[slug] = (meta.get("description", ""), body)

    # 3. Cross-file schema terminology checks
    verdict_skill = skill_bodies.get("evidence-pack-verdict", "")
    if "runnerHost" in verdict_skill or "filingStatus" in verdict_skill:
        errors.append(
            "skills/evidence-pack-verdict/SKILL.md must use verdict.schema.json fields "
            "('runnerSurface' and 'linearIssues[]'), not legacy names"
        )
    if "runnerSurface" not in verdict_skill or "linearIssues[]" not in verdict_skill:
        errors.append(
            "skills/evidence-pack-verdict/SKILL.md must reference 'runnerSurface' and 'linearIssues[]'"
        )
    matrix_text = MATRIX_TEMPLATE.read_text(encoding="utf-8")
    if "`electron`" in matrix_text or "`electron-desktop`" not in matrix_text:
        errors.append("templates/MATRIX.template.md must use 'electron-desktop' matching verdict.schema.json")

    # 4. Check team.v2.jack.md exists and stays byte-synced with skills/*/SKILL.md
    if not TEAM_V2_MD.is_file():
        errors.append("missing team.v2.jack.md (run with --sync)")
    elif len(skills_data) == len(SKILL_ORDER):
        expected_v2 = _render_team_v2_markdown(skills_data)
        if TEAM_V2_MD.read_text(encoding="utf-8") != expected_v2:
            errors.append("team.v2.jack.md drifted from skills/*/SKILL.md (run with --sync)")

    # 5. Parse JSON files safely; return early on broken JSON before deeper assertions
    parsed_json: dict[Path, Any] = {}
    for json_path in (BOT_TEMPLATE, TOOLBELT_PRESET, VERDICT_SCHEMA, VERDICT_SAMPLE):
        try:
            parsed_json[json_path] = json.loads(json_path.read_text(encoding="utf-8"))
        except Exception as exc:
            errors.append(f"{json_path.relative_to(BUNDLE_ROOT)}: invalid JSON: {exc}")

    # 6. Validate bot-template.v1.json skill coverage and sync
    bot = parsed_json.get(BOT_TEMPLATE)
    if isinstance(bot, dict):
        skills = bot.get("skills")
        if not isinstance(skills, list) or tuple(skills) != SKILL_ORDER:
            errors.append(f"bot-template.v1.json: skills {skills!r} != expected {list(SKILL_ORDER)!r}")
        if bot.get("skillsCount") != (len(skills) if isinstance(skills, list) else -1):
            errors.append("bot-template.v1.json: skillsCount != len(skills)")
        routines = bot.get("routines")
        if not isinstance(routines, list) or bot.get("routinesCount") != len(routines):
            errors.append("bot-template.v1.json: routinesCount != len(routines)")
        skill_defs = bot.get("skillDefinitions")
        if not isinstance(skill_defs, list):
            errors.append("bot-template.v1.json: skillDefinitions must be a list")
        else:
            seen_names: list[str] = []
            for entry in skill_defs:
                if not isinstance(entry, dict):
                    errors.append("bot-template.v1.json: skillDefinitions entry must be an object")
                    continue
                name = entry.get("name")
                if not isinstance(name, str) or name not in skill_bodies:
                    errors.append(f"bot-template.v1.json: unknown skillDefinition {name!r}")
                    continue
                seen_names.append(name)
                if entry.get("instructions") != skill_bodies[name]:
                    errors.append(
                        f"bot-template.v1.json: skillDefinition {name!r} drifted from skills/{name}/SKILL.md"
                    )
            if len(seen_names) != len(set(seen_names)):
                errors.append(f"bot-template.v1.json: duplicate skillDefinitions entries: {seen_names}")
            missing_defs = [s for s in SKILL_ORDER if s not in seen_names]
            if missing_defs:
                errors.append(
                    f"bot-template.v1.json: skillDefinitions missing skills from SKILL_ORDER: {missing_defs}"
                )
    elif BOT_TEMPLATE in parsed_json:
        errors.append("bot-template.v1.json: root must be a JSON object")

    # 7. Validate templates/verdict.sample.json against templates/verdict.schema.json
    schema = parsed_json.get(VERDICT_SCHEMA)
    sample = parsed_json.get(VERDICT_SAMPLE)
    if isinstance(schema, dict) and isinstance(sample, dict):
        errors.extend(_validate_sample_verdict_stdlib(schema, sample))
        errors.extend(_validate_sample_verdict_jsonschema(schema, sample))

    return errors


def validate_against_jack_api(jack_api_src: Path) -> list[str]:
    errors: list[str] = []
    sys.path.insert(0, str(jack_api_src.resolve()))

    from jack_api.routine_scheduler import routine_schedule_supported
    from jack_api.schemas.v1.template_share import TemplateShareSnapshotV1
    from jack_api.skill_catalog import (
        INSTRUCTIONS_MAX as JACK_INSTRUCTIONS_MAX,
        _builtin_skill_texts,
        _frontmatter,
        split_sections,
    )
    from jack_api.team_package import (
        hat_prompt_section,
        package_digest,
        parse_team_markdown,
        render_team_markdown,
    )
    from jack_api.team_package_store import MemoryTeamPackageStore, TeamPackageService

    service = TeamPackageService(MemoryTeamPackageStore())

    # 1. Validate team.jack.md (version 1) round-trip + preview
    team_v1_text = TEAM_MD.read_text(encoding="utf-8")
    pkg1 = parse_team_markdown(team_v1_text)
    if pkg1.version != 1:
        errors.append(f"team.jack.md expected version=1, got {pkg1.version}")
    digest1 = package_digest(pkg1)
    digest1_rt = package_digest(parse_team_markdown(render_team_markdown(pkg1)))
    if digest1 != digest1_rt:
        errors.append(f"team.jack.md round-trip digest mismatch: {digest1} != {digest1_rt}")
    preview1 = service.preview(team_v1_text)
    if len(preview1.members) != 3 or len(preview1.groups) != 1 or len(preview1.routines) != 2:
        errors.append(f"unexpected v1 TeamPackageService.preview counts: {preview1}")

    for member in pkg1.members:
        if "denied-tools:" in hat_prompt_section(member.hat):
            errors.append(f"team.jack.md member {member.key} triggers denied-tools")
    for routine in pkg1.routines:
        if not routine.paused:
            errors.append(f"team.jack.md routine {routine.key} must default to paused: true")
        if not routine_schedule_supported(routine.schedule):
            errors.append(f"team.jack.md routine {routine.key} schedule unsupported: {routine.schedule!r}")

    # 2. Validate team.v2.jack.md (version 2) against merged jack.team v2 parser when present
    v2_summary = "v2-parser-unavailable-on-this-checkout"
    if hasattr(parse_team_markdown, "__code__"):
        team_v2_text = TEAM_V2_MD.read_text(encoding="utf-8")
        try:
            import jack_api.team_package as tp_mod
            has_v2 = hasattr(tp_mod, "MemberV2")
        except Exception:
            has_v2 = False
        if has_v2:
            pkg2 = parse_team_markdown(team_v2_text)
            if pkg2.version != 2:
                errors.append(f"team.v2.jack.md expected version=2, got {pkg2.version}")
            digest2 = package_digest(pkg2)
            digest2_rt = package_digest(parse_team_markdown(render_team_markdown(pkg2)))
            if digest2 != digest2_rt:
                errors.append(f"team.v2.jack.md round-trip digest mismatch: {digest2} != {digest2_rt}")
            preview2 = service.preview(team_v2_text)
            if len(preview2.members) != 3 or len(preview2.groups) != 1 or len(preview2.routines) != 2:
                errors.append(f"unexpected v2 TeamPackageService.preview counts: {preview2}")
            pending = getattr(preview2, "requested_capabilities_pending_consent", ())
            expected_cap_count = sum(len(caps) for caps in V2_MEMBER_CAPABILITIES.values())
            if len(pending) != expected_cap_count:
                errors.append(
                    f"team.v2.jack.md expected {expected_cap_count} requested_capabilities_pending_consent entries, got {len(pending)}"
                )
            for member in pkg2.members:
                if "denied-tools:" in hat_prompt_section(member.hat):
                    errors.append(f"team.v2.jack.md member {member.key} triggers denied-tools")
                if not getattr(member, "skill_definitions", []):
                    errors.append(f"team.v2.jack.md member {member.key} missing inline skill_definitions")
            for routine in pkg2.routines:
                if not routine.paused:
                    errors.append(f"team.v2.jack.md routine {routine.key} must default to paused: true")
                if not routine_schedule_supported(routine.schedule):
                    errors.append(f"team.v2.jack.md routine {routine.key} schedule unsupported")
            v2_summary = f"v2_digest={digest2[:12]} pending_consent_caps={len(pending)}"
        else:
            errors.append(
                "jack_api.team_package does not have MemberV2; point --jack-api-src at agent-jack-3 origin/master (>= #466)"
            )

    # 3. Validate skills/ with Jack's real _builtin_skill_texts + _frontmatter + split_sections
    loaded_skills = _builtin_skill_texts(SKILLS_DIR)
    if len(loaded_skills) != len(SKILL_ORDER):
        errors.append(
            f"skill_catalog._builtin_skill_texts loaded {len(loaded_skills)} skills, expected {len(SKILL_ORDER)}"
        )
    for skill_path, text in loaded_skills:
        meta, body = _frontmatter(text)
        if not meta.get("name") or not meta.get("description"):
            errors.append(f"skill_catalog._frontmatter missing name/description for {skill_path}")
        if len(body) > JACK_INSTRUCTIONS_MAX:
            errors.append(f"{skill_path}: body {len(body)} > JACK_INSTRUCTIONS_MAX")
        _intro, sections = split_sections(body)
        if len(sections) < 3:
            errors.append(f"{skill_path}: expected >=3 '##' sections, got {len(sections)}")

    # 4. Validate bot-template.v1.json with Jack's real TemplateShareSnapshotV1
    bot_data = json.loads(BOT_TEMPLATE.read_text(encoding="utf-8"))
    snapshot = TemplateShareSnapshotV1.model_validate(bot_data)
    for routine in snapshot.routines:
        if not routine_schedule_supported(routine.schedule):
            errors.append(f"bot-template routine schedule unsupported: {routine.schedule!r}")

    print(
        "Agent Jack live parser checks PASSED: "
        f"v1_digest={digest1[:12]} {v2_summary} members={len(pkg1.members)} "
        f"teams={len(pkg1.teams)} skills={len(loaded_skills)} "
        f"bot_template={snapshot.name!r} (skills={snapshot.skills_count})"
    )
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--sync",
        action="store_true",
        help="Regenerate BUNDLE.json, bot-template.v1.json, and team.v2.jack.md",
    )
    parser.add_argument(
        "--jack-api-src",
        type=Path,
        default=None,
        help="Path to agent-jack-3/api/src for live Jack parser & Pydantic validation",
    )
    args = parser.parse_args()

    if args.sync:
        sync_generated_manifests()

    errors = validate_standalone()
    if args.jack_api_src is not None:
        errors.extend(validate_against_jack_api(args.jack_api_src))

    if errors:
        for err in errors:
            print(f"ERROR: {err}", file=sys.stderr)
        return 1

    print("OK: portable E2E Test Agent bundle validated cleanly.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
