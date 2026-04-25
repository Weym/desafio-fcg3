---
phase: 4
slug: mcp-server
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-23
updated: 2026-04-25
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | pytest 8.x + pytest-asyncio + AsyncMock-backed FastMCP tests + backend integration check for service-token enforcement |
| **Config file** | `backend/pyproject.toml` (`asyncio_mode = "auto"`) + `mcp_server/tests/conftest.py` |
| **Quick run command** | `python -m pytest mcp_server/tests/test_healthcheck.py mcp_server/tests/test_tool_http_wiring.py -q` |
| **Full suite command** | `python -m pytest mcp_server/tests -q` |
| **Estimated runtime** | MCP suite ~2s; backend service-token integration ~1s |

---

## Sampling Rate

- **After every task commit:** Run the task-scoped `<automated>` verify command from the map below
- **After every plan wave:** Run `python -m pytest mcp_server/tests -q`
- **Before `/gsd-verify-work`:** MCP suite must be green + `python -m pytest backend/tests/integration/test_service_token.py -q`
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 4-01-01 | 01 | 1 | MCP-01,MCP-04 | — | FastMCP runtime boots through the package entrypoint, lifespan provisions the shared HTTP client, and the MCP service token is injected from environment-backed settings | pytest | `python -m pytest mcp_server/tests/test_runtime_entrypoint.py mcp_server/tests/test_service_token.py -q` | ✅ | ✅ green |
| 4-01-02 | 01 | 1 | MCP-01,MCP-02,MCP-03,MCP-04,MCP-05 | — | Session resolution rejects invalid sessions, audit logging is mandatory, retry logic matches the contract, `/health` checks DB and API reachability, and backend service-token validation rejects bad callers | pytest | `python -m pytest mcp_server/tests/test_session_resolver.py mcp_server/tests/test_middleware_logging.py mcp_server/tests/test_api_client.py mcp_server/tests/test_service_token.py mcp_server/tests/test_healthcheck.py backend/tests/integration/test_service_token.py -q` | ✅ | ✅ green |
| 4-02-01 | 02 | 2 | MCP-01,MCP-02 | T-04-07,T-04-08 | Student and grade tools keep `student_id` hidden while proxying the documented backend paths and optional query params through `call_api` | pytest | `python -m pytest mcp_server/tests/test_tool_schemas.py mcp_server/tests/test_tool_http_wiring.py -q` | ✅ | ✅ green |
| 4-02-02 | 02 | 2 | MCP-01,MCP-02 | T-04-09 | Curriculum tools remain public, expose the documented names, and proxy the expected backend endpoints without hidden student context | pytest | `python -m pytest mcp_server/tests/test_tool_schemas.py mcp_server/tests/test_tool_http_wiring.py -q` | ✅ | ✅ green |
| 4-03-01 | 03 | 2 | MCP-01,MCP-02 | T-04-10,T-04-12 | Enrollment tools send the expected resource IDs/body payloads, with `student_id` injected only for `create_enrollment` | pytest | `python -m pytest mcp_server/tests/test_tool_schemas.py mcp_server/tests/test_tool_http_wiring.py -q` | ✅ | ✅ green |
| 4-03-02 | 03 | 2 | MCP-01,MCP-02 | T-04-11,T-04-13 | Document and scheduling tools proxy the documented path/query/body contracts and keep `student_id` hidden except where the API requires it | pytest | `python -m pytest mcp_server/tests/test_tool_schemas.py mcp_server/tests/test_tool_http_wiring.py -q` | ✅ | ✅ green |
| 4-04-01 | 04 | 3 | MCP-01,MCP-02,MCP-05 | T-04-14 | Shared fixtures exercise active-session lookup and exact retry/no-retry behavior for MCP HTTP calls | pytest | `python -m pytest mcp_server/tests/test_session_resolver.py mcp_server/tests/test_api_client.py -q` | ✅ | ✅ green |
| 4-04-02 | 04 | 3 | MCP-01,MCP-02,MCP-03,MCP-04 | T-04-14,T-04-15 | Middleware writes audit rows, tool schemas exclude `student_id`, and the service-token contract is enforced on both outbound and inbound paths | pytest | `python -m pytest mcp_server/tests/test_middleware_logging.py mcp_server/tests/test_tool_schemas.py mcp_server/tests/test_service_token.py backend/tests/integration/test_service_token.py -q` | ✅ | ✅ green |
| 4-05-01 | 05 | 4 | MCP-01 | T-04-05-01,T-04-05-02 | The checked-in Docker and package startup path are import-safe and aligned on `python -m mcp_server.main` | pytest | `python -m pytest mcp_server/tests/test_runtime_entrypoint.py -q` | ✅ | ✅ green |
| 4-05-02 | 05 | 4 | MCP-01 | T-04-05-03 | Runtime regressions preserve the 16-tool surface, `/health` route registration, and manifest alignment | pytest | `python -m pytest mcp_server/tests/test_runtime_entrypoint.py -q` | ✅ | ✅ green |
| 4-06-01 | 06 | 4 | MCP-03 | T-04-06-01,T-04-06-02 | Tool calls without valid audit context fail closed before execution and valid sessions remain attributable | pytest | `python -m pytest mcp_server/tests/test_session_resolver.py mcp_server/tests/test_middleware_logging.py -q` | ✅ | ✅ green |
| 4-06-02 | 06 | 4 | MCP-03 | T-04-06-02,T-04-06-03 | Audit-log insert failures surface instead of being swallowed, while success/error/retry_success writes remain intact | pytest | `python -m pytest mcp_server/tests/test_session_resolver.py mcp_server/tests/test_middleware_logging.py -q` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Integration Tests (Phase-specific Validation)

| Test ID | Scope | Requirements | Test Type | Automated Command | File Exists | Status |
|---------|-------|-------------|-----------|-------------------|-------------|--------|
| V-04-01 | Session resolver: valid session returns `student_id`; missing/malformed/inactive sessions raise `ToolError` | MCP-02 | integration | `python -m pytest mcp_server/tests/test_session_resolver.py -q` | ✅ | ✅ green |
| V-04-02 | Tool registry and schemas: all 16 documented tools are present and none exposes `student_id` in input schemas | MCP-01, MCP-02 | unit | `python -m pytest mcp_server/tests/test_tool_schemas.py -q` | ✅ | ✅ green |
| V-04-03 | Middleware logging: every valid tool call writes the required audit fields and non-auditable calls fail closed | MCP-03 | integration | `python -m pytest mcp_server/tests/test_middleware_logging.py -q` | ✅ | ✅ green |
| V-04-04 | Service-token contract: MCP lifespan injects `X-Service-Token`, and backend validation rejects missing/invalid tokens via the service-token middleware | MCP-04 | integration | `python -m pytest mcp_server/tests/test_service_token.py backend/tests/integration/test_service_token.py -q` | ✅ | ✅ green |
| V-04-05 | Retry logic: 5xx retries once, 4xx does not retry, and timeout retry exhaustion surfaces a Portuguese `ToolError` | MCP-05 | unit | `python -m pytest mcp_server/tests/test_api_client.py -q` | ✅ | ✅ green |
| V-04-06 | Healthcheck behavior: `/health` returns 200 when DB and API are reachable and 503 with details when either dependency fails | MCP-01 | integration | `python -m pytest mcp_server/tests/test_healthcheck.py -q` | ✅ | ✅ green |
| V-04-07 | Tool HTTP wiring: all 16 tools call the documented backend path/query/body contracts and respect student-scoped vs public boundaries | MCP-01, MCP-02 | unit | `python -m pytest mcp_server/tests/test_tool_http_wiring.py -q` | ✅ | ✅ green |
| V-04-08 | Runtime entrypoint: importing `mcp_server.main` inside an active loop stays safe and Docker/compose preserve the package entrypoint | MCP-01 | smoke | `python -m pytest mcp_server/tests/test_runtime_entrypoint.py -q` | ✅ | ✅ green |

### Coverage Matrix (Success Criteria -> Validations)

| Success Criterion | Validations |
|-------------------|-------------|
| SC-1: MCP server boots with the documented 16-tool HTTP surface | V-04-02, V-04-07, V-04-08 |
| SC-2: `student_id` is hidden from schemas and injected from active sessions only where required | V-04-01, V-04-02, V-04-07 |
| SC-3: Every tool call is auditable and missing audit context fails closed | V-04-03 |
| SC-4: `X-Service-Token` is injected outbound and rejected inbound when missing/invalid | V-04-04 |
| SC-5: 5xx/timeout retries exactly once and 4xx never retries | V-04-05 |
| SC-6: `/health` reflects DB/API reachability correctly | V-04-06 |

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. Wave 0 completed in Plan 04-04, with additional Nyquist gap-closure coverage added in Plans 04-05, 04-06, and this audit (`test_healthcheck.py`, `test_tool_http_wiring.py`).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| All 16 tools callable end-to-end via a real MCP client against the Docker stack | MCP-01 | Requires all containers, seeded data, and a live chat session to exercise the full network path rather than mocked unit boundaries | 1. `docker compose up -d` 2. Seed the database 3. Create an active `chat_sessions` row for a student 4. Call `get_student_info` through a real MCP client 5. Verify the returned JSON matches the student's data |
| Live container smoke for the packaged MCP server and `/health` route | MCP-01 | Automated tests cover route logic and manifest alignment, but not a live container boot with networked dependencies | 1. `docker compose up -d mcp-server fastapi-app postgres` 2. `curl -sf http://localhost:8002/health` 3. Verify the HTTP 200 response when dependencies are healthy |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-25 (Nyquist audit completed)

## Validation Audit 2026-04-25

| Metric | Count |
|--------|-------|
| Gaps found | 2 |
| Resolved | 2 |
| Escalated | 0 |

## Validation Audit 2026-04-25

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

Re-audit confirmed the existing Nyquist coverage remains green via `python -m pytest mcp_server/tests -q` (`53 passed`) and `python -m pytest backend/tests/integration/test_service_token.py -q` (`4 passed`).
