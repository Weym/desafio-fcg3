---
phase: 20-langchain-workflow
reviewed: 2026-05-09T04:15:00Z
depth: standard
files_reviewed: 16
files_reviewed_list:
  - ai_service/prompts/system_prompt.txt
  - ai_service/config.py
  - ai_service/rag.py
  - ai_service/main.py
  - ai_service/agent.py
  - ai_service/Dockerfile
  - ai_service/entrypoint.sh
  - ai_service/security/__init__.py
  - ai_service/security/input_sanitizer.py
  - ai_service/security/output_filter.py
  - backend/src/features/webhook/service.py
  - backend/src/features/webhook/background.py
  - backend/src/features/webhook/router.py
  - backend/src/features/webhook/idle_monitor.py
  - backend/alembic/versions/014_add_rag_logs_table.py
  - docker-compose.yml
findings:
  critical: 1
  warning: 5
  info: 3
  total: 9
status: issues_found
---

# Phase 20: Code Review Report

**Reviewed:** 2026-05-09T04:15:00Z
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

Phase 20 implements the LangChain agent workflow including system prompt, input sanitization, output filtering, RAG tool, webhook background processing, idle monitoring, and Docker infrastructure. The code is generally well-structured with good separation of concerns, proper error handling, and thoughtful security layers (defense-in-depth with canary token, input sanitizer, output filter).

Key concerns: the output filter uses overly broad regex patterns that will produce false positives on common English words that happen to be database table names (blocking legitimate agent responses), and the input sanitizer logs the raw user message content which could be a PII/audit concern.

## Critical Issues

### CR-01: Output filter false-positive on common English words used as table names

**File:** `ai_service/security/output_filter.py:34-38`
**Issue:** The `BLOCKED_OUTPUT_PATTERNS` regex matches bare English words like `grades`, `documents`, `appointments`, `courses`, `enrollments`, `sessions` which are also database table names. If the LLM ever uses these English words in a response (e.g., "Your grades are excellent" or "I found your enrollment"), the entire response is replaced with the generic error message. Given the system prompt instructs the agent to respond in Portuguese, the English words are less likely — but `grades` and `documents` are common enough in mixed-language contexts (e.g., bilingual students, the agent explaining concepts) to cause real user-facing failures. This will silently eat valid responses and replace them with "Desculpe, tive um problema ao formular a resposta."

**Fix:** Use word-boundary patterns that require underscore context (actual table name format) or prefix/suffix patterns that indicate code identifiers rather than natural language:
```python
# Database table names — require snake_case context (underscore neighbor)
re.compile(
    r"\b(chat_sessions|chat_messages|knowledge_base_chunks|mcp_action_logs|"
    r"rag_logs|verification_codes|enrollment_items|enrollment_periods|fcm_tokens)\b"
),
# Single-word table names — only block when they look like identifiers
# (preceded/followed by period, backtick, or in a SQL-like context)
re.compile(
    r"(?:FROM|INTO|UPDATE|JOIN|TABLE)\s+(students|enrollments|courses|grades|documents|appointments|sessions)\b",
    re.IGNORECASE,
),
```

## Warnings

### WR-01: Input sanitizer logs raw message content (PII exposure)

**File:** `ai_service/security/input_sanitizer.py:54`
**Issue:** When an injection pattern is detected, the raw user message is logged (truncated to 100 chars): `logger.warning("Injection pattern detected in message: %s", message[:100])`. This logs user-provided content to application logs. While truncated, it may still contain PII (student names, emails mentioned in conversation). For a security-focused module, logging the input that triggered the detection is useful for forensics — but it should be noted that this content will end up in container logs that may have broader access than the database.

**Fix:** Log only the pattern that matched rather than the raw content, or ensure log aggregation has appropriate access controls:
```python
# Option A: Log which pattern matched (safer)
for pattern in INJECTION_PATTERNS:
    if pattern.search(message):
        logger.warning("Injection pattern matched: %s (session context only)", pattern.pattern[:60])
        break
```

### WR-02: Session lock cleanup has race condition

**File:** `backend/src/features/webhook/background.py:313-315`
**Issue:** The lock cleanup logic `if not lock.locked(): _session_locks.pop(lock_key, None)` runs immediately after exiting the `async with lock:` block. At this exact point, the lock is guaranteed to be unlocked (we just released it). However, between releasing the lock and this check, another coroutine could have called `_session_locks.setdefault(lock_key, asyncio.Lock())` and acquired it. Since `setdefault` returns the existing lock (not creating a new one), the pop would remove a lock that another coroutine is actively holding, making it unreachable from `_session_locks`. The next message for that session would then create a NEW lock, breaking the per-session serialization guarantee.

**Fix:** Use a more robust cleanup strategy — only pop if the lock reference is still the same one AND it's not locked:
```python
# After async with lock:
if _session_locks.get(lock_key) is lock and not lock.locked():
    _session_locks.pop(lock_key, None)
```

### WR-03: RAG tool `_log_rag_invocation` can leave dangling connections on error

**File:** `ai_service/rag.py:27-47`
**Issue:** The `_log_rag_invocation` function uses `with db_pool.connection() as conn:` which properly releases back to pool, and `conn.commit()` is called. However, if an exception occurs between the INSERT and `conn.commit()`, the `with` block will return the connection with an uncommitted transaction. While psycopg3's context manager does issue an implicit rollback on `__exit__` when there's an active transaction, the explicit `try/except` at line 46 catches ALL exceptions silently (just logs a warning). If the pool is exhausted or the connection is broken, the warning-level log may not surface the issue adequately in production debugging.

**Fix:** This is acceptable for a non-critical observability path (the docstring says "Non-blocking"), but consider adding `exc_info=True` to the warning for production debugging:
```python
except Exception as exc:
    logger.warning("Failed to log RAG invocation: %s", exc, exc_info=True)
```

### WR-04: Dockerfile does not use entrypoint.sh by default

**File:** `ai_service/Dockerfile:17` and `docker-compose.yml:126`
**Issue:** The Dockerfile's `CMD` is `["python", "-m", "ai_service.main"]`, but `docker-compose.yml` overrides with `command: bash /app/entrypoint.sh` which runs RAG ingest first. If the container is run outside docker-compose (e.g., in CI, k8s, or directly via `docker run`), the `entrypoint.sh` (which handles RAG ingest) would be skipped. The Dockerfile copies `entrypoint.sh` and `chmod +x` it, suggesting it was intended as the default entrypoint.

**Fix:** Make `entrypoint.sh` the default in Dockerfile so behavior is consistent regardless of orchestration:
```dockerfile
CMD ["/app/entrypoint.sh"]
```

### WR-05: Output filter blocks word "container" which has legitimate Portuguese usage

**File:** `ai_service/security/output_filter.py:40`
**Issue:** The pattern `\b(docker-compose|container|microservice|fastapi|langchain|mcp.server)\b` with `re.IGNORECASE` will match the word "container" which, while uncommon in academic Portuguese conversations, could appear if the agent discusses logistics, storage, or shipping contexts. More importantly, `mcp.server` uses `.` which in regex matches ANY character — so `mcp server`, `mcpXserver`, etc. would also match.

**Fix:** Escape the dot and consider removing overly generic words or requiring multi-word context:
```python
re.compile(r"\b(docker-compose|microservice|fastapi|langchain|mcp\.server)\b", re.IGNORECASE),
# "container" only in Docker context:
re.compile(r"\b(docker\s+)?container(s|ized)?\b", re.IGNORECASE),
```

## Info

### IN-01: Settings dataclass evaluates env vars at class definition (import) time

**File:** `ai_service/config.py:15-38`
**Issue:** The `@dataclass(frozen=True)` class uses `os.environ.get(...)` as default values, which are evaluated when the module is first imported — not when `Settings()` is instantiated. This works correctly in Docker (env vars set before process starts) but makes the settings class non-testable without patching at import time or using `importlib.reload`. The `__post_init__` hook partially addresses this for `DATABASE_URL`, but other fields have the same pattern.

**Fix:** This is acceptable for the current Docker-only deployment, but if testability becomes important, consider using a factory function or `pydantic.BaseSettings` which evaluates at instantiation time.

### IN-02: `reload=True` left in production uvicorn config

**File:** `ai_service/main.py:104`
**Issue:** The `main()` function passes `reload=True` to uvicorn. In the Docker container, the `command` in docker-compose uses `entrypoint.sh` which calls `python -m ai_service.main`, triggering this code path. File watching for reload adds CPU overhead in production. In Docker with volume mounts this is useful for dev, but in production deployments it should be disabled.

**Fix:** Make reload conditional on an environment variable:
```python
uvicorn.run(
    "ai_service.main:app",
    host="0.0.0.0",
    port=8001,
    reload=os.environ.get("RELOAD", "false").lower() == "true",
)
```

### IN-03: Unused import `Request` not needed in main.py chat endpoint

**File:** `ai_service/main.py:11`
**Issue:** `Request` is imported from FastAPI and used in the `health_check` endpoint (line 109), so it's not truly unused. However, `status` is imported but could be accessed via `HTTPException(status_code=401)` directly. Minor — no action needed, just noting that all imports are used.

**Fix:** No fix needed — all imports are used upon closer inspection.

---

_Reviewed: 2026-05-09T04:15:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
