---
phase: 04-mcp-server
verified: 2026-04-25T20:54:05Z
status: passed
score: 9/9 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 7/9
  gaps_closed:
    - "MCP server exposes all 16 tools over streamable-http transport on port 8002"
    - "Every tool invocation produces a row in mcp_action_logs with required audit fields"
  gaps_remaining: []
  regressions: []
---

# Phase 4: MCP Server Verification Report

**Phase Goal:** The MCP server exposes all 16 tools over streamable-http transport, injects student_id from session context (never from the agent), and logs every tool call to mcp_action_logs.
**Verified:** 2026-04-25T20:54:05Z
**Status:** passed
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | MCP server exposes all 16 tools over streamable-http transport on port 8002 | ✓ VERIFIED | `mcp_server/main.py:18-38` exports `mcp`, registers middleware/routes/tools, and runs `mcp.run(transport="http", host="0.0.0.0", port=8002)` from `main()`; `mcp_server/Dockerfile:11-15` and `docker-compose.yml:152-166` both use the package entrypoint `python -m mcp_server.main`; spot-check `python -c "from mcp_server.main import mcp; ..."` listed 16 tools and `/health`; `python -m pytest mcp_server/tests -q` passed `53 passed`. |
| 2 | `student_id` is resolved from active chat session context, never from agent input schemas | ✓ VERIFIED | `mcp_server/dependencies.py:16-24` validates `X-Chat-Session-ID`, `:34-45` loads active session from `chat_sessions`, and `:54-62` returns `student_id`; `mcp_server/tests/test_tool_schemas.py:45-62` asserts `student_id` is absent from schemas while remaining a hidden dependency on student-scoped tools. |
| 3 | All student-scoped tools use hidden dependency injection, and all 16 tools proxy through `call_api` | ✓ VERIFIED | `grep` found `Depends(resolve_student_id)` exactly 7 times across `mcp_server/tools/*.py` and `call_api(` exactly 16 times across the 16 tool implementations. |
| 4 | Lifespan initializes asyncpg pool and httpx client with FASTAPI base URL, service token, and 10s timeout | ✓ VERIFIED | `mcp_server/lifespan.py:13-38` creates `asyncpg.create_pool(...)` and `httpx.AsyncClient(base_url=settings.fastapi_base_url, timeout=10.0, headers={"X-Service-Token": ...})`; `mcp_server/tests/test_service_token.py:14-42` verifies the configured header and base URL. |
| 5 | Healthcheck validates PostgreSQL and FastAPI reachability | ✓ VERIFIED | `mcp_server/healthcheck.py:15-40` registers `/health`, checks `pool.fetchval("SELECT 1")`, then `client.get("/health")`, and returns `503` with details on failure; `mcp_server/tests/test_healthcheck.py:39-103` covers healthy and dependency-failure behavior. |
| 6 | Every tool invocation produces a row in `mcp_action_logs` with required audit fields | ✓ VERIFIED | `mcp_server/middleware.py:45-80` validates header/session/DB pool before tool execution and always calls `_log_call(...)` in `finally`; `:100-122` inserts `chat_session_id`, `tool_name`, sanitized `input_params`, `output_result`, `reasoning`, `latency_ms`, `retry`, and `status`; `mcp_server/tests/test_middleware_logging.py:27-62,65-131,158-285` covers success, error, retry_success, missing header, invalid session, missing db pool, and surfaced insert-failure paths. |
| 7 | Retry behavior is exactly one retry on 5xx/timeout, never on 4xx, with Portuguese `ToolError` translation | ✓ VERIFIED | `mcp_server/api_client.py:52-80` retries only after 5xx/timeout/request errors, never on 4xx, and translates 4xx payloads into Portuguese `ToolError`s; `mcp_server/tests/test_api_client.py:27-84` covers retry-on-500, timeout failure after one retry, and no-retry 400/404/422 paths. |
| 8 | MCP → FastAPI requests use `X-Service-Token`, and invalid tokens are rejected via constant-time comparison | ✓ VERIFIED | `mcp_server/lifespan.py:22-29` injects `X-Service-Token`; `backend/src/shared/auth.py:101-121` validates it with `hmac.compare_digest`; `backend/tests/integration/test_service_token.py:18-45` covers missing, wrong, correct, and different-length tokens. |
| 9 | Test coverage exists for the core MCP security/operational contract | ✓ VERIFIED | `python -m pytest mcp_server/tests -q` passed `53 passed in 1.74s`, including runtime entrypoint, schema hiding, session resolution, middleware logging, retry behavior, service-token configuration, healthcheck behavior, and per-tool HTTP wiring regressions. |

**Score:** 9/9 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `mcp_server/main.py` | FastMCP app, middleware, healthcheck, tool registration, run entrypoint | ✓ VERIFIED | Present (38 lines), substantive, import-safe, and wired through exported `mcp` plus explicit `main()` runner. |
| `mcp_server/lifespan.py` | asyncpg pool + httpx client init/teardown | ✓ VERIFIED | Present (38 lines), substantive, used by `FastMCP(... lifespan=app_lifespan)`. |
| `mcp_server/dependencies.py` | hidden session/student resolution | ✓ VERIFIED | Present (66 lines), substantive, wired through resolver dependencies and shared middleware guards. |
| `mcp_server/api_client.py` | shared retry/error translation helper | ✓ VERIFIED | Present (93 lines), substantive, used by all 16 tool handlers. |
| `mcp_server/middleware.py` | tool-call audit logging to `mcp_action_logs` | ✓ VERIFIED | Present (122 lines), validates audit prerequisites up front, strips hidden `student_id`, and fails closed on insert errors. |
| `mcp_server/healthcheck.py` | `/health` route checking DB + API | ✓ VERIFIED | Present (40 lines), registered synchronously via `register_healthcheck(mcp)`. |
| `mcp_server/tools/*.py` | 16 documented MCP tools | ✓ VERIFIED | Six register functions and 16 `call_api(...)` tool implementations present; runtime spot-check listed all expected names. |
| `mcp_server/tests/*.py` | tests for resolver, logging, retry, schemas, runtime, service token, healthcheck, and tool wiring | ✓ VERIFIED | Present and substantive; current suite passes with 53 tests. |
| `mcp_server/Dockerfile` | runnable MCP server image | ✓ VERIFIED | Present (15 lines), copies the package and starts it with `python -m mcp_server.main`; matched by compose and guarded by runtime entrypoint tests. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `mcp_server/main.py` | `mcp_server/lifespan.py` | `FastMCP(... lifespan=app_lifespan)` | ✓ WIRED | `mcp_server/main.py:18` |
| `mcp_server/dependencies.py` | asyncpg pool | `get_context().lifespan_context["db_pool"]` + `fetchrow(...)` | ✓ WIRED | `mcp_server/dependencies.py:27-31,34-45,58-60` |
| `mcp_server/middleware.py` | `mcp_action_logs` table | `INSERT INTO mcp_action_logs` | ✓ WIRED | `mcp_server/middleware.py:69-78,100-122`; failure-path tests verify no silent drop paths remain. |
| `mcp_server/main.py` | tool modules | six `register_*_tools(mcp)` calls | ✓ WIRED | `mcp_server/main.py:23-30` |
| tool modules | `mcp_server/api_client.py` | `call_api(...)` for every HTTP request | ✓ WIRED | 16 `call_api(` usages found across the six tool modules. |
| MCP client config | FastAPI auth | `X-Service-Token` header + backend `compare_digest` | ✓ WIRED | `mcp_server/lifespan.py:25-28`, `backend/src/shared/auth.py:101-121` |
| Docker/compose runtime | MCP package entrypoint | `python -m mcp_server.main` | ✓ WIRED | `mcp_server/Dockerfile:15`, `docker-compose.yml:166`, `mcp_server/tests/test_runtime_entrypoint.py:57-82` |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `mcp_server/dependencies.py` | `student_id` | `chat_sessions` lookup by `X-Chat-Session-ID` | Yes | ✓ FLOWING |
| `mcp_server/api_client.py` → `mcp_server/middleware.py` | retry flag | FastMCP context state via `RETRY_STATE_KEY` | Yes | ✓ FLOWING |
| `mcp_server/middleware.py` | audit row write | `db_pool.execute(INSERT INTO mcp_action_logs ...)` after validated session/db prerequisites | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| MCP test suite passes | `python -m pytest mcp_server/tests -q` | `53 passed in 1.74s` | ✓ PASS |
| Healthcheck behavior is covered beyond route registration | `python -m pytest mcp_server/tests/test_healthcheck.py -q` | `3 passed` | ✓ PASS |
| Tool handlers preserve the documented backend path/query/body wiring | `python -m pytest mcp_server/tests/test_tool_http_wiring.py -q` | `16 passed` | ✓ PASS |
| 16 tools and `/health` route are registered | `python -c "from mcp_server.main import mcp; import asyncio; ..."` | `16` tools printed and route list included `/health` | ✓ PASS |
| Importing `mcp_server.main` inside an active event loop is safe | `python -c "import asyncio, importlib, sys; exec('async def _main(): ...'); asyncio.run(_main())"` | `True` | ✓ PASS |
| Runtime manifests use the package entrypoint | `python -m pytest mcp_server/tests/test_runtime_entrypoint.py -q` | Included in full suite pass; assertions cover Dockerfile and compose entrypoint alignment | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| MCP-01 | 04-01, 04-02, 04-03, 04-04, 04-05 | 16 MCP tools via Streamable HTTP transport | ✓ SATISFIED | `main.py` runs HTTP/8002, runtime spot-check lists all 16 tools, and Docker/compose now use `python -m mcp_server.main`. |
| MCP-02 | 04-01, 04-02, 04-03, 04-04 | `student_id` injected from session and absent from schemas | ✓ SATISFIED | Resolver query in `dependencies.py`; schema assertions passed in `test_tool_schemas.py`. |
| MCP-03 | 04-01, 04-04, 04-06 | every tool call logged to `mcp_action_logs` | ✓ SATISFIED | Middleware validates audit prerequisites up front, inserts required fields, and tests prove failure paths are fail-closed. |
| MCP-04 | 04-01, 04-04 | MCP calls use `X-Service-Token`; API rejects invalid tokens with `compare_digest` | ✓ SATISFIED | Header configured in `lifespan.py`; backend auth uses `hmac.compare_digest`; backend integration tests pass. |
| MCP-05 | 04-01, 04-04 | retry once on 5xx/timeout, no retry on 4xx | ✓ SATISFIED | `api_client.py` implements exact branching; targeted retry/no-retry tests passed. |

All requirement IDs declared in phase plans (`MCP-01` through `MCP-05`) were found in `.planning/REQUIREMENTS.md`. No orphaned Phase 4 requirement IDs were identified.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `mcp_server/tests/test_runtime_entrypoint.py` | 57-82 | Manifest-based startup coverage rather than a live container boot | ℹ️ Info | Container boot is inferred from entrypoint/package alignment tests instead of exercised end-to-end, but no code-level blocker remains. |

### Gaps Summary

The two prior blockers are closed. The MCP runtime is now import-safe and consistently launched through `python -m mcp_server.main` in both Docker and compose, preserving the 16-tool HTTP surface. Audit logging also now fails closed: invalid or inactive chat sessions are rejected before tool execution, missing DB audit infrastructure raises immediately, and `mcp_action_logs` insert failures propagate instead of being swallowed. The subsequent Nyquist audit also closed the remaining validation-coverage gaps with dedicated healthcheck-behavior and tool-wiring regressions. Phase 04 now meets its roadmap and validation contracts.

---

_Verified: 2026-04-25T20:54:05Z_
_Verifier: the agent (gsd-verifier)_
