---
phase: 4
slug: mcp-server
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-23
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | pytest 8.x + pytest-asyncio + AST parse checks (no DB in unit; Docker DB for integration) |
| **Config file** | `mcp_server/pyproject.toml` or inline pytest config — created by Wave 0 if absent |
| **Quick run command** | `python -c "import ast; ast.parse(open('mcp_server/main.py').read()); print('OK')"` |
| **Full suite command** | `python -m pytest mcp_server/tests/ -v --tb=short` |
| **Estimated runtime** | AST checks ~2s · unit ~10s · integration (with Docker DB) ~30s |

---

## Sampling Rate

- **After every task commit:** Run the task-scoped `<automated>` verify command from the plan
- **After every plan wave:** Run `python -m pytest mcp_server/tests/ -v --tb=short`
- **Before `/gsd-verify-work`:** Full suite must be green + Docker `curl -sf http://localhost:8002/health`
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 4-01-01 | 01 | 1 | MCP-01 | — | FastMCP app with lifespan (asyncpg pool + httpx client); settings from env vars; MCP_SERVICE_TOKEN not hardcoded | AST parse | `python -c "import ast; ast.parse(open('mcp_server/main.py').read()); ast.parse(open('mcp_server/settings.py').read()); ast.parse(open('mcp_server/lifespan.py').read()); print('OK')"` | ✅ | ⬜ pending |
| 4-01-02 | 01 | 1 | MCP-02,MCP-03,MCP-04,MCP-05 | — | Session resolver via Depends(resolve_student_id) hidden from schema; middleware logs to mcp_action_logs; API client with retry on 5xx (one retry), no retry on 4xx; hmac.compare_digest for service token; healthcheck endpoint | AST parse | `python -c "import ast; ast.parse(open('mcp_server/dependencies.py').read()); ast.parse(open('mcp_server/middleware.py').read()); ast.parse(open('mcp_server/api_client.py').read()); ast.parse(open('mcp_server/healthcheck.py').read()); ast.parse(open('mcp_server/main.py').read()); print('OK')"` | ✅ | ⬜ pending |
| 4-02-01 | 02 | 2 | MCP-01,MCP-02 | — | 4 read-only tools (get_student_info, get_grades, get_transcript, get_available_courses); student_id injected via Depends, not in tool schema | AST parse | `python -c "import ast; ast.parse(open('mcp_server/tools/student_tools.py').read()); ast.parse(open('mcp_server/tools/grade_tools.py').read()); print('4 tools OK')"` | ✅ | ⬜ pending |
| 4-02-02 | 02 | 2 | MCP-01,MCP-02 | — | 3 curriculum tools (get_curriculum, get_course_prerequisites, get_enrollment_period); wired into main.py | AST parse | `python -c "import ast; ast.parse(open('mcp_server/tools/curriculum_tools.py').read()); ast.parse(open('mcp_server/main.py').read()); print('3 curriculum tools + wiring OK')"` | ✅ | ⬜ pending |
| 4-03-01 | 03 | 2 | MCP-01,MCP-02 | — | 4 enrollment tools (create_enrollment, confirm_enrollment, drop_course, lock_enrollment) | AST parse | `python -c "import ast; ast.parse(open('mcp_server/tools/enrollment_tools.py').read()); print('4 enrollment tools OK')"` | ✅ | ⬜ pending |
| 4-03-02 | 03 | 2 | MCP-01,MCP-02 | — | 5 tools (request_document, get_document_status, get_available_slots, book_appointment, cancel_appointment); all 16 tools wired in main.py | AST parse | `python -c "import ast; ast.parse(open('mcp_server/tools/document_tools.py').read()); ast.parse(open('mcp_server/tools/scheduling_tools.py').read()); ast.parse(open('mcp_server/main.py').read()); print('5 tools + final wiring OK')"` | ✅ | ⬜ pending |
| 4-04-01 | 04 | 3 | MCP-01..05 | — | Test fixtures; session resolver returns correct student_id from chat_sessions; API client retries 5xx, skips 4xx retry | pytest | `python -m pytest mcp_server/tests/test_session_resolver.py mcp_server/tests/test_api_client.py -v --tb=short` | ❌ W0 | ⬜ pending |
| 4-04-02 | 04 | 3 | MCP-01..05 | — | Middleware logs every tool call to mcp_action_logs with correct fields; all 16 tool schemas exclude student_id; service token validated with hmac.compare_digest | pytest | `python -m pytest mcp_server/tests/test_middleware_logging.py mcp_server/tests/test_tool_schemas.py mcp_server/tests/test_service_token.py -v --tb=short` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Integration Tests (Phase-specific Validation)

| Test ID | Scope | Requirements | Test Type | Automated Command | File Exists | Status |
|---------|-------|-------------|-----------|-------------------|-------------|--------|
| V-04-01 | Session resolver: valid session returns student_id; expired/invalid session raises ToolError | MCP-02 | integration | `python -m pytest mcp_server/tests/test_session_resolver.py -x` | ❌ W0 | ⬜ pending |
| V-04-02 | Tool schema validation: all 16 tools registered; none has student_id in input schema | MCP-01, MCP-02 | unit | `python -m pytest mcp_server/tests/test_tool_schemas.py -x` | ❌ W0 | ⬜ pending |
| V-04-03 | Middleware logging: every tool call produces mcp_action_logs row with tool_name, input_params, output_result, latency_ms, retry, status | MCP-03 | integration | `python -m pytest mcp_server/tests/test_middleware_logging.py -x` | ❌ W0 | ⬜ pending |
| V-04-04 | Service token: requests without X-Service-Token rejected 401; invalid token rejected 401; valid token accepted | MCP-04 | integration | `python -m pytest mcp_server/tests/test_service_token.py -x` | ❌ W0 | ⬜ pending |
| V-04-05 | Retry logic: 5xx triggers one retry; 4xx returns error without retry; timeout triggers one retry | MCP-05 | unit | `python -m pytest mcp_server/tests/test_api_client.py -x` | ❌ W0 | ⬜ pending |

### Coverage Matrix (Success Criteria -> Validations)

| Success Criterion | Validations |
|-------------------|-------------|
| SC-1: MCP server starts, 16 tools registered on streamable-http | V-04-02, task 4-01-01 |
| SC-2: student_id hidden from all tool schemas, injected from session | V-04-01, V-04-02 |
| SC-3: Every tool call logged to mcp_action_logs | V-04-03 |
| SC-4: X-Service-Token validated via hmac.compare_digest | V-04-04 |
| SC-5: One retry on 5xx/timeout, no retry on 4xx | V-04-05 |

---

## Wave 0 Requirements

Test stubs must be created during Plan 04 execution:

- [ ] `mcp_server/tests/__init__.py` — package marker
- [ ] `mcp_server/tests/conftest.py` — shared fixtures: mock asyncpg pool, mock httpx client, mock FastMCP context
- [ ] `mcp_server/tests/test_session_resolver.py` — stubs for V-04-01
- [ ] `mcp_server/tests/test_tool_schemas.py` — stubs for V-04-02
- [ ] `mcp_server/tests/test_middleware_logging.py` — stubs for V-04-03
- [ ] `mcp_server/tests/test_service_token.py` — stubs for V-04-04
- [ ] `mcp_server/tests/test_api_client.py` — stubs for V-04-05
- [ ] `mcp_server/requirements-dev.txt` — `pytest>=8`, `pytest-asyncio>=0.23`, `respx>=0.21` (httpx mocking)

*Note: Plan 04-04 (Wave 3) creates all test files. Waves 1-2 use AST parse checks as lightweight validation since test infrastructure is not yet ready.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| All 16 tools callable end-to-end via MCP client with real Docker stack | MCP-01 | Requires all 4 containers running + seeded DB + real MCP client session | 1. `docker compose up -d` 2. Seed DB 3. Create a chat_session for a student 4. Use `fastmcp` CLI or Python `MultiServerMCPClient` to call `get_student_info` 5. Verify JSON response with correct student data |
| Healthcheck endpoint returns 200 with DB + API status | MCP-01 | Requires live Docker network | 1. `docker compose up -d` 2. `curl -sf http://localhost:8002/health` 3. Verify JSON response `{"status": "healthy", "db": "ok", "api": "ok"}` |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (Plan 04-04 creates test files)
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-23 (by planner; awaits execution confirmation)
