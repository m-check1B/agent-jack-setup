---
name: api-contract-probe
description: Use this when verifying HTTP API endpoints via http.probe or CLI, checking status codes, response headers, redirects, JSON schema contracts, auth boundaries, or read-only database invariants.
---

Verify backend APIs, HTTP edge routing, CLI tools, and read-only data invariants directly so backend regressions are separated cleanly from frontend bugs.

## Safety and Redaction Rules

1. **Read-only on production.** On production hosts, run `GET`, `HEAD`, and `OPTIONS` probes only. Never send mutating `POST`, `PUT`, `PATCH`, or `DELETE` requests to production.
2. **Never log or echo secrets.** Redact `Authorization`, `Cookie`, `Set-Cookie` values, API keys, JWTs, and session tokens before writing any probe log or matrix note. Record only header presence and cookie security attributes (`HttpOnly`, `Secure`, `SameSite`, `Path`, `Domain`).
3. **Respect host boundaries.** Only probe origins explicitly authorized in the user's request or test plan. Never scan private networks or metadata endpoints.
4. **Fixture isolation.** State-changing API checks run only on staging or ephemeral test environments using fixture identities and `[e2e]`-prefixed payloads.

## Execution Surfaces

Select the cleanest tool available on the active Bot route and record it in the evidence:

1. **Jack Bounded HTTP Probe (`http.probe`)** (preferred default on Server and Paired Mac seats):
   - Call `http.probe(url, method="GET"|"HEAD"|"OPTIONS", headers=..., max_redirects=5)` for read-only public HTTPS contract verification with per-hop SSRF defense.
   - Inspect returned HTTP status code, redirect chain, latency, redacted response headers, and bounded response body.
2. **Paired Mac / Local CLI or Fly Sandbox** (`curl`, `python3`, `node`, `jq`, or repo contract scripts via Local route, `tentacles.hire`, or `sandbox_run`):
   - Use for staging-only mutating idempotency checks, custom non-public staging origins, JSON schema suites, and read-only CLI/DB probes.
3. **WebMCP Backend Probes (`webmcp.call`)**:
   - Cross-check backend WebMCP tool output against HTTP API responses for the same entity and tenant.

## Core Contract Probes

Run these probe categories against each target service:

1. **Health, readiness, and build identity**:
   - Probe `/health`, `/healthz`, `/ready`, or `/api/v1/health` with `http.probe`.
   - Verify HTTP `200`, valid JSON, expected dependency readiness, and deployed SHA/version stamp.
2. **TLS, redirects, and security headers**:
   - Verify `http://` redirects cleanly (`301`/`302`/`308`) to `https://` without open-redirect bugs.
   - Check `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `Content-Security-Policy` or `X-Frame-Options`, `Referrer-Policy`, `Content-Type`, and non-contradictory `Cache-Control` (especially `no-store`/`private` on authenticated endpoints).
3. **Auth and tenant isolation boundaries**:
   - Unauthenticated request to a protected endpoint must fail closed (`401`/`403`/`404`, never `200` or `500` stack trace).
   - Wrong-tenant or cross-user resource ID must return `403`/`404` with zero data leakage.
   - Malformed staging payloads must return structured `400`/`422` validation errors, never unhandled `500`s.
4. **Schema, pagination, and idempotency checks**:
   - Validate JSON keys, types, required fields, and error envelope consistency.
   - On staging write endpoints that accept `clientRequestId` / `Idempotency-Key`, verify exact replay returns the original result without duplicate side effects.
5. **CLI and read-only DB/storage probes** (when Paired Mac / local workspace access is authorized):
   - Run documented CLI health/doctor/contract commands and capture exact exit code + bounded stdout/stderr.
   - Run read-only SQL/state checks only against staging or local test databases to verify writes persisted cleanly.

## Output Contract

Record every probe with exact method, URL (query secrets redacted), HTTP status code, latency in ms, checked headers, assertion result (`PASS` | `FAIL` | `BLOCKED`), and concise excerpt (<= 500 chars) on failure. Clearly separate backend/API defects from frontend rendering defects.
