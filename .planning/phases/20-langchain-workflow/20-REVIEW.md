---
phase: 20-langchain-workflow
reviewed: 2026-05-09T21:56:45Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - ai_service/agent.py
  - ai_service/main.py
  - ai_service/prompts/system_prompt.txt
  - backend/src/features/webhook/background.py
  - backend/src/features/webhook/service.py
  - backend/src/features/webhook/router.py
  - backend/tests/features/webhook/test_verification_state.py
  - mcp_server/middleware.py
  - mcp_server/dependencies.py
findings:
  critical: 0
  warning: 3
  info: 4
  total: 7
status: issues_found
---

# Phase 20: Code Review Report

**Reviewed:** 2026-05-09T21:56:45Z
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Reviewed changes from plans 20-09 (welcome/farewell fixes), 20-10 (stale OTP timezone defense), and 20-11 (lazy OTP verification gate + verification_state end-to-end flow). The code is well-structured with clear intent, good documentation, and proper defense-in-depth design. The MCP middleware verification gate correctly blocks mutating tools for unverified students and the system prompt aligns with the lazy OTP architecture.

Three warnings identified: (1) the verification gate raises before the audit logging block, creating an audit gap for blocked mutating calls; (2) silent exception swallowing in annotation lookup hides debugging information; (3) message ordering when both welcome and verification contexts are injected may cause LLM priority confusion. Four informational items related to code quality and maintainability.

No critical security issues found. The security design is sound — `student_id` never leaks to the agent, the verification gate reads from the DB (authoritative source) not from the HTTP request body, and the fail-closed pattern in annotation lookup is correct.

## Warnings

### WR-01: Verification gate blocks BEFORE audit logging — blocked calls are not logged

**File:** `mcp_server/middleware.py:60`
**Issue:** `_enforce_verification_gate()` raises `ToolError` at line 60, which is BEFORE `start = time.monotonic()` at line 62 and the `try/finally` block that logs to `mcp_action_logs`. When an unverified student attempts a mutating tool, the call is correctly blocked but produces zero audit trail in `mcp_action_logs`. Per CONVENTIONS.md: "Every MCP tool call must be logged with: tool_name, input_params, ...". This creates a gap — staff/admins cannot see how often unverified students attempt mutating actions, which is valuable security telemetry.
**Fix:** Move the verification gate inside the try/finally block, or add a dedicated log entry before raising:

```python
async def on_call_tool(self, context: MiddlewareContext, call_next):
    tool_name = context.message.name
    input_params = _sanitize_input_params(context.message.arguments or {})
    headers = get_http_headers(include={"x-chat-session-id"})
    raw_chat_session_id = headers.get("x-chat-session-id")
    fastmcp_context = context.fastmcp_context
    if fastmcp_context is None:
        raise RuntimeError("FastMCP context unavailable for audit logging.")

    chat_session_id = validate_chat_session_id(raw_chat_session_id)
    db_pool = get_db_pool(fastmcp_context.lifespan_context)
    session_data = await validate_active_chat_session(db_pool, chat_session_id)

    start = time.monotonic()
    result: Any = None
    status = "success"

    try:
        # D-15/D-21: Enforce verification gate on mutating tools
        await self._enforce_verification_gate(context, session_data)
        result = await call_next(context)
    except ToolError:
        status = "error"
        raise
    except Exception:
        status = "error"
        raise
    finally:
        latency_ms = int((time.monotonic() - start) * 1000)
        await self._log_call(
            context=context,
            tool_name=tool_name,
            input_params=input_params,
            db_pool=db_pool,
            chat_session_id=chat_session_id,
            result=result,
            latency_ms=latency_ms,
            status=status,
        )

    return result
```

### WR-02: Silent exception swallowing in annotation lookup hides errors

**File:** `mcp_server/middleware.py:105-106`
**Issue:** The bare `except Exception: pass` in `_enforce_verification_gate` silently swallows any error from `context.fastmcp_context.fastmcp.get_tool(tool_name)`. While the fail-closed behavior (block by default) is the correct security posture, completely suppressing the exception makes it invisible during debugging. If the FastMCP API changes or a bug appears in tool registry lookup, this would silently block ALL tools for unverified students with no log trail explaining why.
**Fix:** Add a warning log so the fail-closed behavior is visible:

```python
try:
    tool = await context.fastmcp_context.fastmcp.get_tool(tool_name)
    annotations = getattr(tool, "annotations", None)
    if annotations and getattr(annotations, "readOnlyHint", False):
        return  # Read-only tool, allowed for unverified students
except Exception as exc:
    # Fail closed: if we can't determine, block by default (safe side)
    import logging
    logging.getLogger(__name__).warning(
        "Could not resolve annotations for tool '%s' (blocking by default): %s",
        tool_name,
        exc,
    )
```

### WR-03: Message ordering conflict when both welcome and verification contexts are injected

**File:** `ai_service/agent.py:156-179`
**Issue:** When `is_new_session=True` AND `verification_state != "verified"` (which is the default case for new sessions), line 165 builds `all_messages = [welcome_instruction, *history_messages, HumanMessage(...)]`, then line 179 prepends: `all_messages = [verification_context, *all_messages]`. The final order is `[verification_context, welcome_instruction, history..., user_msg]`. The verification context at position 0 becomes the highest-priority system instruction, potentially causing the LLM to focus on verification warnings rather than the welcome greeting. On a new session with a read-only question, the student should get a warm welcome — not a verification-focused response.
**Fix:** Inject the verification context AFTER the welcome instruction so welcome takes priority on new sessions:

```python
# D-14/D-15: Inject verification state context so agent knows student status
if verification_state != "verified":
    verification_context = SystemMessage(
        content=(
            "Estado de verificacao do aluno: NAO VERIFICADO. "
            "Operacoes de leitura estao liberadas. "
            "Se o aluno solicitar uma acao que altere dados e a ferramenta retornar erro de verificacao, "
            "solicite o email institucional do aluno para enviar o codigo de verificacao."
        )
    )
    # Insert after welcome (if present) but before history, so welcome takes priority
    if is_new_session:
        # all_messages is [welcome_instruction, *history, HumanMessage]
        all_messages = [all_messages[0], verification_context, *all_messages[1:]]
    else:
        all_messages = [verification_context, *all_messages]
```

## Info

### IN-01: `load_chat_history` is synchronous and blocks the event loop

**File:** `ai_service/agent.py:149-153`
**Issue:** `load_chat_history()` (defined in `ai_service/database.py:26`) uses a synchronous psycopg3 `ConnectionPool` with `pool.connection()` context manager. This blocks the asyncio event loop during the DB query. Called from the async `invoke_agent()`, this prevents other coroutines from progressing while chat history loads. Pre-existing issue (not introduced by plans 20-09/10/11), but worth noting as it runs on every chat request.
**Fix:** Either use `asyncio.to_thread(load_chat_history, ...)` to offload to a thread, or migrate to an async pool (`psycopg_pool.AsyncConnectionPool`).

### IN-02: `reload=True` hardcoded in `uvicorn.run` for AI service

**File:** `ai_service/main.py:106`
**Issue:** `uvicorn.run(..., reload=True)` is hardcoded. In a Docker production container, file-watching reload wastes resources and could cause unexpected restarts. This is pre-existing and not introduced by plan 20-11, but the `main()` function is in scope.
**Fix:** Make reload configurable via an environment variable:

```python
uvicorn.run(
    "ai_service.main:app",
    host="0.0.0.0",
    port=8001,
    reload=os.environ.get("UVICORN_RELOAD", "false").lower() == "true",
)
```

### IN-03: `import os as _os` inside lifespan function

**File:** `ai_service/main.py:70`
**Issue:** `os` is imported as `_os` inside the `lifespan()` function body with a leading underscore alias. The underscore convention suggests a private/unused name, but it's actively used on lines 73-76 to set environment variables. This is a minor readability issue — the module could simply `import os` at the top level.
**Fix:** Move `import os` to the module-level imports (alongside `logging`, `hmac`, etc.) and use `os` directly instead of `_os`.

### IN-04: Test file module docstring mentions old state machine flow

**File:** `backend/tests/features/webhook/test_verification_state.py:4`
**Issue:** The module docstring on line 4 says `unverified -> awaiting_email -> awaiting_code -> verified`, but with lazy OTP (D-13/D-14), the `unverified -> awaiting_email` transition no longer goes through `handle_verification_flow`. The test `test_unverified_skips_verification_flow` was correctly updated (line 23), but the module docstring still describes the old flow.
**Fix:** Update the module docstring to reflect the lazy OTP design:

```python
"""Verification state machine tests (D-01, D-02, D-13/D-14).

Tests the verification flow lifecycle:
awaiting_email -> awaiting_code -> verified
Plus: unverified students skip verification flow (lazy OTP).
Including invalid paths: wrong email, wrong code, max attempts.
"""
```

---

_Reviewed: 2026-05-09T21:56:45Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
