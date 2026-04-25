---
phase: 04-mcp-server
verified: 2026-04-25T18:47:04Z
status: gaps_found
score: 7/9 must-haves verified
overrides_applied: 0
gaps:
  - truth: "MCP server exposes all 16 tools over streamable-http transport on port 8002"
    status: failed
    reason: "The code registers all 16 tools and configures HTTP/8002, but the checked-in Docker image cannot start the MCP server: it copies only main.py and starts uvicorn main:app even though the implementation exports mcp and imports package modules that are not copied into the image."
    artifacts:
      - path: "mcp_server/main.py"
        issue: "The runtime object is `mcp`, not `app` (line 20 vs Docker CMD main:app)."
      - path: "mcp_server/Dockerfile"
        issue: "Copies only `requirements.txt` and `main.py`, then runs `uvicorn main:app --reload`; package imports and entrypoint do not match the actual service."
    missing:
      - "Copy the full `mcp_server/` package into the image."
      - "Use the MCP server entrypoint (for example `python -m mcp_server.main`) instead of `uvicorn main:app`."
  - truth: "Every tool invocation produces a row in mcp_action_logs with required audit fields"
    status: failed
    reason: "Happy-path logging exists, but `_log_call()` returns without writing anything when the chat-session header is missing/invalid or `db_pool` is absent, and it silently swallows insert failures. That breaks the roadmap contract that every tool call is logged."
    artifacts:
      - path: "mcp_server/middleware.py"
        issue: "Lines 74-84 skip logging entirely on missing/invalid header or missing db_pool."
      - path: "mcp_server/middleware.py"
        issue: "Lines 91-116 swallow database insert failures, so logging can fail silently."
    missing:
      - "Reject or otherwise handle headerless/invalid tool calls in a way that preserves the audit guarantee."
      - "Do not silently ignore `mcp_action_logs` write failures if audit logging is mandatory."
---

# Phase 4: MCP Server Verification Report

**Phase Goal:** The MCP server exposes all 16 tools over streamable-http transport, injects student_id from session context (never from the agent), and logs every tool call to mcp_action_logs.
**Verified:** 2026-04-25T18:47:04Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | MCP server exposes all 16 tools over streamable-http transport on port 8002 | ✗ FAILED | `mcp_server/main.py:20-36` creates `FastMCP(... lifespan=app_lifespan)` and runs `mcp.run(transport="http", host="0.0.0.0", port=8002)`, and `python -c "from mcp_server.main import mcp; ..."` listed 16 tools. But `mcp_server/Dockerfile:8-15` copies only `requirements.txt` + `main.py` and starts `uvicorn main:app`, which does not match the actual package/runtime object. |
| 2 | `student_id` is resolved from active chat session context, never from agent input schemas | ✓ VERIFIED | `mcp_server/dependencies.py:15-46` reads `X-Chat-Session-ID`, validates UUID, queries `chat_sessions` for active session, and returns `student_id`; `mcp_server/tests/test_tool_schemas.py:45-62` passed and asserts `student_id` is absent from every schema while remaining a hidden dependency on the 7 student-scoped tools. |
| 3 | All student-scoped tools use hidden dependency injection, and all 16 tools proxy through `call_api` | ✓ VERIFIED | `grep` found `Depends(resolve_student_id)` exactly 7 times across tool modules and `call_api(` exactly 16 times across the 16 tool implementations. |
| 4 | Lifespan initializes asyncpg pool and httpx client with FASTAPI base URL, service token, and 10s timeout | ✓ VERIFIED | `mcp_server/lifespan.py:17-29` creates `asyncpg.create_pool(...)` and `httpx.AsyncClient(base_url=settings.fastapi_base_url, timeout=10.0, headers={"X-Service-Token": ...})`; `mcp_server/tests/test_service_token.py:14-42` passed. |
| 5 | Healthcheck validates PostgreSQL and FastAPI reachability | ✓ VERIFIED | `mcp_server/healthcheck.py:16-40` registers `/health`, runs `pool.fetchval("SELECT 1")`, then `client.get("/health")`, and returns `503` with details on failure. |
| 6 | Every tool invocation produces a row in `mcp_action_logs` with required audit fields | ✗ FAILED | `mcp_server/middleware.py:73-116` writes the correct columns, but returns early when `raw_chat_session_id`/`db_pool` is missing and suppresses insert exceptions; that means some tool calls are not guaranteed to be logged. |
| 7 | Retry behavior is exactly one retry on 5xx/timeout, never on 4xx, with Portuguese `ToolError` translation | ✓ VERIFIED | `mcp_server/api_client.py:52-93` retries only after 5xx/timeout/request errors, translates 4xx via `_translate_error_message`, and raises generic server error after failed retry; `mcp_server/tests/test_api_client.py` passed all 6 targeted cases. |
| 8 | MCP → FastAPI requests use `X-Service-Token`, and invalid tokens are rejected via constant-time comparison | ✓ VERIFIED | `mcp_server/lifespan.py:25-28` injects `X-Service-Token`; `backend/src/shared/auth.py:101-121` validates with `hmac.compare_digest`; `backend/tests/integration/test_service_token.py:18-45` covers missing/wrong/correct/different-length token handling. |
| 9 | Test coverage exists for the core MCP security/operational contract | ✓ VERIFIED | `python -m pytest mcp_server/tests -v` passed 19 tests covering tool schemas, resolver behavior, retry behavior, middleware happy/error paths, and service-token configuration. |

**Score:** 7/9 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `mcp_server/main.py` | FastMCP app, middleware, healthcheck, tool registration, run entrypoint | ✓ VERIFIED | Present (36 lines), wires lifespan + middleware + six tool registration functions; import-time `asyncio.run(...)` is a warning, not the main blocker. |
| `mcp_server/lifespan.py` | asyncpg pool + httpx client init/teardown | ✓ VERIFIED | Present (38 lines), substantive, used by `FastMCP(... lifespan=app_lifespan)`. |
| `mcp_server/dependencies.py` | hidden session/student resolution | ✓ VERIFIED | Present (50 lines), substantive, wired through 7 `Depends(resolve_student_id)` usages. |
| `mcp_server/api_client.py` | shared retry/error translation helper | ✓ VERIFIED | Present (93 lines), substantive, used by all 16 tools. |
| `mcp_server/middleware.py` | tool-call audit logging to `mcp_action_logs` | ⚠️ HOLLOW | Insert logic exists and happy-path tests pass, but logging can be bypassed or silently dropped on failure paths. |
| `mcp_server/healthcheck.py` | `/health` route checking DB + API | ✓ VERIFIED | Present (40 lines), registered via `register_healthcheck(mcp)`. |
| `mcp_server/tools/*.py` | 16 documented MCP tools | ✓ VERIFIED | Six register functions and 16 tool implementations present; runtime spot-check listed all expected names. |
| `mcp_server/tests/*.py` | tests for resolver, logging, retry, schemas, service token | ✓ VERIFIED | 19 tests passed. |
| `mcp_server/Dockerfile` | runnable MCP server image | ✗ STUB | Exists, but startup wiring is wrong for this package (`COPY main.py`, `uvicorn main:app`). |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `mcp_server/main.py` | `mcp_server/lifespan.py` | `FastMCP(... lifespan=app_lifespan)` | ✓ WIRED | `mcp_server/main.py:20` |
| `mcp_server/dependencies.py` | asyncpg pool | `get_context().lifespan_context["db_pool"]` + `fetchrow(...)` | ✓ WIRED | `mcp_server/dependencies.py:32-42` |
| `mcp_server/middleware.py` | `mcp_action_logs` table | `INSERT INTO mcp_action_logs` | ⚠️ PARTIAL | Insert exists (`mcp_server/middleware.py:92-114`), but surrounding guards allow silent no-log paths. |
| `mcp_server/main.py` | tool modules | six `register_*_tools(mcp)` calls | ✓ WIRED | `mcp_server/main.py:24-32` |
| tool modules | `mcp_server/api_client.py` | `call_api(...)` for every HTTP request | ✓ WIRED | 16 `call_api(` usages found across the six tool modules. |
| MCP client config | FastAPI auth | `X-Service-Token` header + backend `compare_digest` | ✓ WIRED | `mcp_server/lifespan.py:25-28`, `backend/src/shared/auth.py:115-120` |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `mcp_server/dependencies.py` | `student_id` | `chat_sessions` lookup by `X-Chat-Session-ID` | Yes | ✓ FLOWING |
| `mcp_server/api_client.py` → `mcp_server/middleware.py` | retry flag | FastMCP context state via `RETRY_STATE_KEY` | Yes | ✓ FLOWING |
| `mcp_server/middleware.py` | audit row write | `db_pool.execute(INSERT INTO mcp_action_logs ...)` | Not on all paths | ✗ DISCONNECTED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| MCP test suite passes | `python -m pytest mcp_server/tests -v` | `19 passed in 1.07s` | ✓ PASS |
| Server module imports in plain context | `python -c "import mcp_server.main; print('IMPORT_OK')"` | `IMPORT_OK` | ✓ PASS |
| 16 tools are registered on exported MCP app | `python -c "from mcp_server.main import mcp; import asyncio; tools=asyncio.run(mcp.list_tools()); ..."` | `16` plus all expected names | ✓ PASS |
| Server module import is safe inside active event loop | `python -c "import asyncio; exec('async def main():\n import mcp_server.main\n print(\'ASYNC_IMPORT_OK\')'); asyncio.run(main())"` | `RuntimeError: asyncio.run() cannot be called from a running event loop` | ✗ FAIL |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| MCP-01 | 04-01, 04-02, 04-03, 04-04 | 16 MCP tools via Streamable HTTP transport | ✗ BLOCKED | 16 tools are registered and `main.py` runs HTTP/8002, but the checked-in Docker image cannot boot the service correctly. |
| MCP-02 | 04-01, 04-02, 04-03, 04-04 | `student_id` injected from session and absent from schemas | ✓ SATISFIED | Resolver query in `dependencies.py`; schema assertions passed in `test_tool_schemas.py`. |
| MCP-03 | 04-01, 04-04 | every tool call logged to `mcp_action_logs` | ✗ BLOCKED | Middleware writes expected fields on happy paths, but early returns and swallowed insert failures violate the “every call” guarantee. |
| MCP-04 | 04-01, 04-04 | MCP calls use `X-Service-Token`; API rejects invalid tokens with `compare_digest` | ✓ SATISFIED | Header configured in `lifespan.py`; backend auth uses `hmac.compare_digest`; backend integration tests pass. |
| MCP-05 | 04-01, 04-04 | retry once on 5xx/timeout, no retry on 4xx | ✓ SATISFIED | `api_client.py` implements exact branching; targeted retry/no-retry tests passed. |

All requirement IDs declared in phase plans (`MCP-01` through `MCP-05`) were found in `.planning/REQUIREMENTS.md`. No orphaned Phase 4 requirement IDs were identified.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `mcp_server/Dockerfile` | 8-15 | Copies only `main.py` and starts `uvicorn main:app` | 🛑 Blocker | Containerized MCP server will not start with the actual package layout/runtime object. |
| `mcp_server/middleware.py` | 74-84 | Early return skips logging when header/db context is absent | 🛑 Blocker | Breaks the requirement that every tool call be logged. |
| `mcp_server/middleware.py` | 91-116 | Swallows audit insert failures | 🛑 Blocker | Audit logging can fail silently. |
| `mcp_server/main.py` | 22 | `asyncio.run(register_healthcheck(mcp))` at import time | ⚠️ Warning | Importing the module from an active event loop crashes. |
| `mcp_server/tests/` | n/a | No healthcheck/Docker/import-safety regression tests | ⚠️ Warning | The current test suite missed real startup/logging edge cases flagged in review. |

### Human Verification Required

None. Automated verification already found blocking code-level gaps.

### Gaps Summary

Phase 04 is close but not done. The MCP package does contain the 16 documented tools, hidden `student_id` injection, retry logic, and a passing 19-test suite. However, two goal-level contracts are still broken in the actual codebase: the checked-in Docker image does not start the MCP service correctly, and audit logging is not guaranteed for every tool call because the middleware skips or suppresses some failure paths. Until those are fixed, the phase goal is not fully achieved.

---

_Verified: 2026-04-25T18:47:04Z_
_Verifier: the agent (gsd-verifier)_
