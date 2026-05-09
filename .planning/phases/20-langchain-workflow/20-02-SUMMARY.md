---
phase: 20-langchain-workflow
plan: 02
subsystem: database, ai
tags: [rag, observability, langsmith, alembic, psycopg3, jsonb]

# Dependency graph
requires:
  - phase: 05-ai-service
    provides: RAG tool creation (create_rag_tool), psycopg3 pool, AI service config
  - phase: 04-mcp-server
    provides: mcp_action_logs table pattern for structured logging
provides:
  - rag_logs table for per-invocation RAG observability (query, chunks, scores, threshold)
  - LangSmith tracing integration via environment variables
  - session_id parameter flow from agent to RAG tool for log correlation
affects: [staff-debug-tools, langchain-workflow]

# Tech tracking
tech-stack:
  added: [LangSmith (optional tracing)]
  patterns: [non-blocking structured logging with try/except, env-var-driven feature flags]

key-files:
  created:
    - backend/alembic/versions/014_add_rag_logs_table.py
  modified:
    - ai_service/rag.py
    - ai_service/config.py
    - ai_service/main.py
    - ai_service/agent.py
    - docker-compose.yml

key-decisions:
  - "RAG logging is non-blocking — failures are caught and logged as warnings without affecting RAG responses"
  - "LangSmith tracing activated via env var flag (LANGCHAIN_TRACING_V2=true) — graceful when not configured"

patterns-established:
  - "Non-blocking observability: wrap DB inserts in try/except to never block primary tool response"
  - "Feature flag via env var: LANGCHAIN_TRACING_V2 controls LangSmith activation at startup"

requirements-completed: [LANG-10, LANG-11, LANG-12, LANG-13]

# Metrics
duration: 1min
completed: 2026-05-09
---

# Phase 20 Plan 02: RAG Observability & LangSmith Summary

**RAG invocation logging to rag_logs table with chunk scores/queries plus LangSmith tracing via Docker env vars**

## Performance

- **Duration:** 1 min
- **Started:** 2026-05-09T03:32:04Z
- **Completed:** 2026-05-09T03:33:21Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Created rag_logs table migration (UUID PK, FK to chat_messages, JSONB chunks, threshold boolean)
- Enhanced RAG tool with per-invocation structured logging (query, chunks with scores, threshold result)
- Integrated LangSmith tracing configuration (env vars in Settings, lifespan startup, Docker Compose)
- Wired session_id from agent invocation through to RAG tool for log correlation

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Alembic migration for rag_logs table** - `8bd5572` (feat)
2. **Task 2: Enhance RAG tool with per-invocation logging + add LangSmith config** - `f84002b` (feat)

## Files Created/Modified
- `backend/alembic/versions/014_add_rag_logs_table.py` - Alembic migration creating rag_logs table with UUID PK, FK to chat_messages, JSONB chunks, boolean threshold, index
- `ai_service/rag.py` - Added _log_rag_invocation function and session_id parameter to create_rag_tool
- `ai_service/config.py` - Added LANGSMITH_API_KEY, LANGCHAIN_TRACING_V2, LANGCHAIN_PROJECT settings
- `ai_service/main.py` - Set LangSmith env vars in lifespan if LANGCHAIN_TRACING_V2=true
- `ai_service/agent.py` - Pass session_id to create_rag_tool call
- `docker-compose.yml` - Added LANGCHAIN_TRACING_V2, LANGSMITH_API_KEY, LANGCHAIN_PROJECT to langchain-service

## Decisions Made
- RAG logging is non-blocking (try/except with warning log) to satisfy T-20-04 threat mitigation
- LangSmith tracing only activates when LANGCHAIN_TRACING_V2=true in env (safe default=false)
- chunks_retrieved JSONB stores source, category, score, and chunk_index per retrieved chunk
- Log correlation uses session_id → latest user chat_message_id lookup

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required

For LangSmith tracing to work in production:
- Set `LANGCHAIN_TRACING_V2=true` in environment
- Set `LANGSMITH_API_KEY` to a valid LangSmith API key
- Optionally set `LANGCHAIN_PROJECT` (defaults to `fcg3-ai-service`)

## Next Phase Readiness
- rag_logs table ready for staff debug queries (`SELECT * FROM rag_logs WHERE chat_message_id = X`)
- LangSmith tracing available when API key is configured
- MCP tool visibility continues via existing mcp_action_logs + LangSmith traces

---
*Phase: 20-langchain-workflow*
*Completed: 2026-05-09*
