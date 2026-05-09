---
phase: 04-mcp-server
reviewed: 2026-04-25T18:41:16.4274688Z
depth: standard
files_reviewed: 28
files_reviewed_list:
  - mcp_server/__init__.py
  - mcp_server/main.py
  - mcp_server/settings.py
  - mcp_server/lifespan.py
  - mcp_server/dependencies.py
  - mcp_server/api_client.py
  - mcp_server/middleware.py
  - mcp_server/healthcheck.py
  - mcp_server/requirements.txt
  - mcp_server/Dockerfile
  - mcp_server/tools/__init__.py
  - mcp_server/tools/student_tools.py
  - mcp_server/tools/grade_tools.py
  - mcp_server/tools/curriculum_tools.py
  - mcp_server/tools/enrollment_tools.py
  - mcp_server/tools/document_tools.py
  - mcp_server/tools/scheduling_tools.py
  - mcp_server/tests/__init__.py
  - mcp_server/tests/conftest.py
  - mcp_server/tests/test_session_resolver.py
  - mcp_server/tests/test_api_client.py
  - mcp_server/tests/test_middleware_logging.py
  - mcp_server/tests/test_tool_schemas.py
  - mcp_server/tests/test_service_token.py
  - .planning/phases/04-mcp-server/04-01-SUMMARY.md
  - .planning/phases/04-mcp-server/04-02-SUMMARY.md
  - .planning/phases/04-mcp-server/04-03-SUMMARY.md
  - .planning/phases/04-mcp-server/04-04-SUMMARY.md
findings:
  critical: 1
  warning: 3
  info: 0
  total: 4
status: issues_found
---

# Phase 04: Code Review Report

**Reviewed:** 2026-04-25T18:41:16.4274688Z
**Depth:** standard
**Files Reviewed:** 28
**Status:** issues_found

## Summary

Reviewed the full `mcp_server/**` implementation plus the four phase summaries. The good news: all 16 tools are registered, `student_id` is hidden from tool schemas, and the existing 19-test suite passes. The phase is not clean, though: the Docker image is currently non-runnable, the server module does async work at import time, audit logging can be bypassed or silently dropped, and core deployment/healthcheck failure paths are still untested.

## Critical Issues

### CR-01: Docker image still boots a non-existent ASGI app

**File:** `mcp_server/Dockerfile:8-15`
**Issue:** The container only copies `main.py`, but `main.py` imports `mcp_server.*` modules that are never copied into the image. It also starts `uvicorn main:app`, but this code exposes `mcp`, not `app`, and the phase design is a standalone FastMCP server rather than a Uvicorn-served FastAPI app. In Docker, Phase 04 will fail to start.
**Fix:**
```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY mcp_server/requirements.txt ./requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

COPY mcp_server ./mcp_server

EXPOSE 8002
CMD ["python", "-m", "mcp_server.main"]
```

## Warnings

### WR-01: Importing `mcp_server.main` inside an active event loop crashes

**File:** `mcp_server/main.py:22`
**Issue:** `asyncio.run(register_healthcheck(mcp))` executes during module import. Importing this module from any already-running async context raises `RuntimeError: asyncio.run() cannot be called from a running event loop`. I reproduced that failure with `import mcp_server.main` inside `asyncio.run(...)`.
**Fix:**
```python
# healthcheck.py
def register_healthcheck(mcp: FastMCP) -> None:
    @mcp.custom_route("/health", methods=["GET"])
    async def healthcheck(request: Request) -> JSONResponse:
        ...

# main.py
register_healthcheck(mcp)
```

### WR-02: Audit logging is silently skipped on invalid headers or DB insert failures

**File:** `mcp_server/middleware.py:73-116`
**Issue:** `_log_call()` returns without error when `X-Chat-Session-ID` is missing/invalid, and it also swallows any exception from the `mcp_action_logs` insert. That breaks the phase guarantee that every tool call is logged to `mcp_action_logs`, especially for public tools that do not force `resolve_student_id`.
**Fix:**
```python
if not raw_chat_session_id:
    raise ToolError("Sessao invalida, nao foi possivel identificar o aluno.")

chat_session_id = UUID(raw_chat_session_id)
await db_pool.execute(...)
```
If log persistence is mandatory, do not suppress DB write failures; fail the request or degrade the service as unhealthy.

### WR-03: Core deployment and healthcheck regressions are not covered by tests

**File:** `mcp_server/healthcheck.py:15-40`
**Issue:** The current suite covers schemas, retry logic, session resolution, middleware happy paths, and service-token configuration, but it does not test `/health` success/failure branches, Docker startup wiring, the import-time `asyncio.run(...)` failure, or the headerless/unlogged public-tool path. Those are exactly the areas where the current regressions slipped through.
**Fix:** Add tests for:
- healthy/unhealthy `register_healthcheck()` behavior
- importing `mcp_server.main` from an async context
- rejecting or logging tool calls without `X-Chat-Session-ID`
- a container smoke test (or at minimum a Dockerfile contract check) that verifies the image starts the MCP server entrypoint

---

_Reviewed: 2026-04-25T18:41:16.4274688Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
