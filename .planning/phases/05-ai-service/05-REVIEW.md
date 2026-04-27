---
phase: 05-ai-service
reviewed: 2026-04-27T17:32:00Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - docker-compose.yml
  - ai_service/config.py
  - ai_service/database.py
  - ai_service/main.py
  - ai_service/agent.py
  - ai_service/llm_factory.py
  - ai_service/rag.py
  - ai_service/mcp_tools.py
  - ai_service/ingest.py
  - ai_service/tests/test_runtime_entrypoint.py
findings:
  critical: 0
  warning: 4
  info: 3
  total: 7
status: issues_found
---

# Phase 05: Code Review Report

**Reviewed:** 2026-04-27T17:32:00Z
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

Initial review covered all AI service source files and `docker-compose.yml` after Plan 05-08 changes. Plan 05-09 gap closure fixed the critical `ingest.py` DATABASE_URL regression (CR-01) and updated the regression test to assert `POSTGRES_*` component vars. Both fixes are correct and resolve the original findings. The incremental review of Plan 05-09 changes found one new warning (redundant double-normalization) and one new info item (inconsistent settings access pattern). All previously-reported warnings (WR-01 through WR-03) and info items (IN-01, IN-02) from the original review remain open and are carried forward below.

Authentication, service token validation, and the core chat flow remain well-implemented.

## Resolved Issues (Plan 05-09)

### ~~CR-01~~: `ingest.py` broken — `DATABASE_URL` no longer available ✅ FIXED

**Resolved by:** commit `20315cc` (Plan 05-09)
**Fix applied:** `IngestSettings.from_env()` now imports `settings` from `ai_service.config` to obtain `DATABASE_URL`, which handles `POSTGRES_*` component fallback via `Settings.__post_init__()`. The fix matches the suggested approach from the original review exactly.

## Critical Issues

_No critical issues. CR-01 was resolved by Plan 05-09._

## Warnings

### WR-01: OpenRouter provider broken in `agent.py` — no `base_url` or `api_key` override

**File:** `ai_service/agent.py:28` / `ai_service/llm_factory.py:21-22`
**Issue:** When `LLM_PROVIDER=openrouter`, `get_model_string()` returns `"openai:{model}"`. The `create_agent()` function from `langchain.agents` uses `init_chat_model` internally to create a `ChatOpenAI` instance from this string. This instance will use `OPENAI_API_KEY` env var by default and the standard OpenAI base URL — neither of which is correct for OpenRouter. The `create_llm()` function in `llm_factory.py` (lines 45-52) correctly passes `api_key=settings.OPENROUTER_API_KEY` and `base_url="https://openrouter.ai/api/v1"`, but `create_chat_agent()` in `agent.py` never calls `create_llm()` — it passes the string to `create_agent()` instead.

Result: OpenRouter will fail at runtime with either a missing API key error or will hit the wrong API endpoint.

**Fix:** Use `create_llm()` to get a proper model instance instead of `get_model_string()`:
```python
# ai_service/agent.py — replace create_chat_agent()
def create_chat_agent(settings: Any, tools: list[Any], system_prompt: str) -> Any:
    """Create a provider-agnostic LangChain ReAct agent."""
    from ai_service.llm_factory import create_llm

    return create_agent(
        model=create_llm(settings),
        tools=tools,
        system_prompt=system_prompt,
    )
```

### WR-02: RAG tool requires `OPENAI_API_KEY` even when using non-OpenAI LLM providers

**File:** `ai_service/agent.py:86` / `ai_service/rag.py:16-22`
**Issue:** `create_rag_tool(db_pool, settings.OPENAI_API_KEY)` passes `OPENAI_API_KEY` which may be `None` when using `gemini` or `openrouter` as LLM provider. The embedding model `text-embedding-3-small` is fixed to OpenAI (per project constraint), so `OPENAI_API_KEY` is always required for RAG — but there's no validation or clear error message when it's missing. `OpenAIEmbeddings(api_key=None)` will raise a cryptic error at query time.

**Fix:** Add an explicit guard at agent initialization:
```python
# ai_service/agent.py — inside invoke_agent(), before create_rag_tool()
if not settings.OPENAI_API_KEY:
    logger.error(
        "OPENAI_API_KEY is required for RAG embeddings regardless of LLM_PROVIDER"
    )
    return FALLBACK_MESSAGE

rag_tool = create_rag_tool(db_pool, settings.OPENAI_API_KEY)
```

### WR-03: Synchronous DB calls in async route handler block the event loop

**File:** `ai_service/main.py:113-118` and `ai_service/main.py:128-133`
**Issue:** `save_chat_message()` and `load_chat_history()` (called via `invoke_agent`) are synchronous functions using `psycopg` (sync driver) with a synchronous `ConnectionPool`. These are called directly from the `async def chat()` route handler. Synchronous database I/O blocks the asyncio event loop, preventing other concurrent requests from being processed. With the current single-service design this may be acceptable for MVP, but under load (multiple concurrent WhatsApp messages), requests will queue behind each other's DB calls.

**Fix:** Wrap synchronous DB calls in `asyncio.to_thread()` to avoid blocking the event loop:
```python
import asyncio

# In the chat() handler:
await asyncio.to_thread(
    save_chat_message,
    pool=app.state.db_pool,
    session_id=request.session_id,
    role="user",
    content=request.message,
)
```

Alternatively, migrate to `psycopg` async driver (`AsyncConnectionPool`) for native async DB access.

### WR-04: Redundant double-normalization of DATABASE_URL in `ingest.py` *(NEW — Plan 05-09)*

**File:** `ai_service/ingest.py:49`
**Issue:** `IngestSettings.from_env()` calls `normalize_psycopg_dsn(database_url)` on line 49, where `database_url` is `app_settings.DATABASE_URL`. However, `Settings.__post_init__()` in `config.py` (lines 36-54) already normalizes the URL — it either constructs a clean `postgresql://` URL from `POSTGRES_*` components, or normalizes an existing `DATABASE_URL` env var via the same `normalize_psycopg_dsn()` function. The second normalization in `ingest.py` is always a no-op since the URL is already in `postgresql://` format.

This is not a bug (the function is idempotent), but it obscures the invariant that `settings.DATABASE_URL` is always pre-normalized, and creates a maintenance trap — a future developer might think normalization is still needed here and propagate the pattern elsewhere.

**Fix:** Remove the redundant normalization:
```python
return cls(
    database_url=database_url,  # Already normalized by Settings.__post_init__()
    openai_api_key=openai_api_key,
)
```

And remove the now-unused import at line 15:
```python
# Remove: from ai_service.database import normalize_psycopg_dsn
```

## Info

### IN-01: `create_llm()` function in `llm_factory.py` is unused dead code

**File:** `ai_service/llm_factory.py:29-57`
**Issue:** The `create_llm()` function is defined but never imported or called anywhere in the codebase. Only `get_model_string()` is used (by `agent.py`). If WR-01 is fixed by switching to `create_llm()`, this becomes the correct approach. Otherwise, this is dead code that should be removed or documented as a future migration path.

### IN-02: `mcp-server` receives excessive environment variables in docker-compose.yml

**File:** `docker-compose.yml:120-141`
**Issue:** The `mcp-server` service receives `WHATSAPP_TOKEN`, `WHATSAPP_PHONE_NUMBER_ID`, `WHATSAPP_WEBHOOK_VERIFY_TOKEN`, `WHATSAPP_APP_SECRET`, `RESEND_API_KEY`, `JWT_SECRET`, `LLM_PROVIDER`, `LLM_MODEL`, `OPENAI_API_KEY`, `GEMINI_API_KEY`, `OPENROUTER_API_KEY`, and `FCM_CREDENTIALS_PATH`. Per the architecture, the MCP server only needs database access (`POSTGRES_*` or `DATABASE_URL`), `MCP_SERVICE_TOKEN`, and `FASTAPI_URL`. Passing WhatsApp tokens, JWT secrets, and LLM API keys to the MCP server container violates the principle of least privilege — these secrets are only needed by `fastapi-app` and `langchain-service` respectively.

**Fix:** Trim the MCP server environment to only what it needs:
```yaml
mcp-server:
  environment:
    POSTGRES_DB: ${POSTGRES_DB}
    POSTGRES_USER: ${POSTGRES_USER}
    POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    POSTGRES_HOST: postgres
    POSTGRES_PORT: 5432
    MCP_SERVICE_TOKEN: ${MCP_SERVICE_TOKEN}
    FASTAPI_URL: ${FASTAPI_URL}
```

### IN-03: `ingest.py` reads `OPENAI_API_KEY` from `os.environ` instead of shared Settings *(NEW — Plan 05-09)*

**File:** `ai_service/ingest.py:41`
**Issue:** Plan 05-09 correctly switched `DATABASE_URL` to use the shared `app_settings` object, but `OPENAI_API_KEY` on line 41 is still read directly from `os.environ.get("OPENAI_API_KEY")` instead of using `app_settings.OPENAI_API_KEY`. Both resolve to the same value, so this is not a bug. However, it creates an inconsistent access pattern within the same 10-line method — half uses the Settings object, half bypasses it. If Settings ever adds validation or defaulting for `OPENAI_API_KEY`, `ingest.py` would silently skip it.

**Fix:** Use the shared settings consistently:
```python
@classmethod
def from_env(cls) -> "IngestSettings":
    from ai_service.config import settings as app_settings

    database_url = app_settings.DATABASE_URL
    openai_api_key = app_settings.OPENAI_API_KEY

    if not openai_api_key:
        raise RuntimeError(
            "Missing required environment variable: OPENAI_API_KEY"
        )

    return cls(
        database_url=database_url,
        openai_api_key=openai_api_key,
    )
```

---

_Reviewed: 2026-04-27T17:32:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
