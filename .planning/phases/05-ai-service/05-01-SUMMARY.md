---
phase: 05-ai-service
plan: 01
subsystem: ai
tags: [fastapi, langchain, psycopg3, openai, gemini, postgres]
requires:
  - phase: 04-mcp-server
    provides: MCP server streamable-http endpoint and chat session context injection
provides:
  - FastAPI AI service scaffold on port 8001 with lifespan-managed DB pool
  - Environment-backed configuration and provider-agnostic LLM factory
  - Chat history persistence helpers and canonical system prompt file
affects: [05-02, 05-03, 05-04, 05-05, ai_service]
tech-stack:
  added: [langchain, langchain-mcp-adapters, langchain-openai, langchain-google-genai, psycopg3, psycopg-pool, fastapi]
  patterns: [environment-backed settings object, sync psycopg3 pool for AI service, provider:model LangChain factory]
key-files:
  created: [ai_service/__init__.py, ai_service/config.py, ai_service/database.py, ai_service/llm_factory.py, ai_service/prompts/system_prompt.txt]
  modified: [ai_service/main.py, ai_service/requirements.txt, ai_service/Dockerfile]
key-decisions:
  - "Used lazy imports in database and LLM modules so package imports succeed before service dependencies are installed."
  - "Resolved the system prompt path from the ai_service package directory to keep file loading stable across entrypoints."
  - "Aligned the Dockerfile with the packaged ai_service module layout so container startup matches local imports."
patterns-established:
  - "Settings object: ai_service configuration is centralized in config.py and consumed via a shared settings instance."
  - "Database access: chat history helpers use parameterized psycopg3 queries against chat_messages."
requirements-completed: [AI-01, AI-04]
duration: 3 min
completed: 2026-04-25
---

# Phase 05 Plan 01: AI Service Scaffold Summary

**FastAPI AI service scaffold with psycopg3 chat persistence, provider-agnostic LangChain model selection, and a file-backed academic system prompt.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-25T20:04:33.3666941-03:00
- **Completed:** 2026-04-25T20:07:57.9885011-03:00
- **Tasks:** 2
- **Files modified:** 8

## Accomplishments
- Added the initial `ai_service` package scaffold with environment-backed runtime settings.
- Added chat history database helpers, provider-aware LLM factory helpers, and a lifespan-managed FastAPI app.
- Replaced the stub health service setup with a real prompt-loading and DB-aware runtime foundation.

## Task Commits

Each task was committed atomically:

1. **Task 1: Config, requirements, and system prompt** - `0c13ae9` (feat)
2. **Task 2: Database layer, LLM factory, and FastAPI app** - `a9779fa` (feat)

## Files Created/Modified
- `ai_service/__init__.py` - marks the AI service as a Python package.
- `ai_service/config.py` - central settings object for DB, LLM, MCP, prompt, and agent limits.
- `ai_service/database.py` - psycopg3 pool creation plus chat history load/save and DB health helpers.
- `ai_service/llm_factory.py` - provider-agnostic model string and chat model factory.
- `ai_service/main.py` - FastAPI app with lifespan, `/health`, and placeholder `/chat` endpoint.
- `ai_service/prompts/system_prompt.txt` - canonical Portuguese academic assistant prompt from `docs/chatbot.md`.
- `ai_service/requirements.txt` - AI service runtime dependencies.
- `ai_service/Dockerfile` - container startup aligned to the packaged module layout.

## Decisions Made
- Used lazy imports inside dependency-heavy helpers so `import ai_service.*` works even before local environment packages are installed.
- Loaded the system prompt relative to `ai_service/main.py` instead of the process working directory to avoid path drift.
- Updated the existing Dockerfile with the package-based entrypoint because the old stub container layout no longer matched the new module structure.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Aligned Docker startup with the new package layout**
- **Found during:** Task 2 (Database layer, LLM factory, and FastAPI app)
- **Issue:** The existing stub Dockerfile copied `main.py` directly and launched `uvicorn main:app`, which would break once the service moved to `ai_service.main:app`.
- **Fix:** Updated the Dockerfile to copy the full `ai_service/` package, install requirements from `ai_service/requirements.txt`, and start `uvicorn ai_service.main:app`.
- **Files modified:** `ai_service/Dockerfile`
- **Verification:** Module imports passed and the Dockerfile now references the packaged module path consistently.
- **Committed in:** `a9779fa`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The deviation kept the scaffold runnable in containerized environments without expanding scope beyond the service foundation.

## Issues Encountered

- The first patch attempt targeted the wrong repository root instead of the dedicated worktree; after detecting the mismatch from a failed verification, the files were applied directly to the worktree and execution continued normally.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for Plan 05-02 to add the knowledge-base ingest flow and retrieval primitives on top of the new settings and database modules.
- The AI service package, prompt file, and container entrypoint are now consistent for downstream plans.

## Self-Check: PASSED

---
*Phase: 05-ai-service*
*Completed: 2026-04-25*
