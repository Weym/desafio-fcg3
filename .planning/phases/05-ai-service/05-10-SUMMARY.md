---
phase: 05-ai-service
plan: 10
subsystem: ai
tags: [rag, pgvector, embeddings, openrouter, mcp, asyncpg, configuration]

requires:
  - phase: 05-ai-service
    provides: RAG tool wired into LangChain agent (create_rag_tool) and MCP ToolLoggingMiddleware writing to mcp_action_logs
  - phase: 01-infrastructure-schema
    provides: mcp_action_logs.id UUID NOT NULL column (migration 006_create_chat_knowledge_tables.py)
provides:
  - RAG_SIMILARITY_THRESHOLD Settings field (env-tunable, default 0.45) exposed from ai_service/config.py
  - create_rag_tool(db_pool, embeddings, similarity_threshold) signature accepting per-call threshold override
  - mcp_action_logs INSERT that populates id via server-side gen_random_uuid(), eliminating NOT NULL violations
affects: [06-whatsapp-webhook-integration, phase-05-uat, phase-06-uat]

tech-stack:
  added: []
  patterns:
    - "Per-provider tunables (RAG threshold) exposed as Settings fields instead of module constants"
    - "Use PostgreSQL server-side defaults (gen_random_uuid()) in INSERT statements when the column lacks a server_default on the schema"

key-files:
  created: []
  modified:
    - ai_service/config.py
    - ai_service/rag.py
    - ai_service/agent.py
    - ai_service/tests/test_rag_retrieval.py
    - mcp_server/middleware.py
    - mcp_server/tests/test_middleware_logging.py

key-decisions:
  - "RAG threshold default lowered from 0.75 to 0.45 because OpenRouter embedding proxy caps similarity at ~0.67 for even perfect matches (UAT evidence)"
  - "Keep gen_random_uuid() call server-side in the SQL string rather than generating UUIDs in Python — keeps the MCP log UUID authoritatively owned by PostgreSQL and avoids adding a new positional parameter"
  - "Exposed threshold via ai_service/config.py Settings instead of a module-level constant so it can be tuned per-provider via RAG_SIMILARITY_THRESHOLD env var without code changes"

patterns-established:
  - "Retrieval tunables: make provider-sensitive thresholds configurable via Settings and pass them into factory functions as keyword arguments, rather than referencing module constants inside the tool closure"
  - "DB INSERTs for columns without a server_default: call the Postgres generator function (gen_random_uuid()) directly in the VALUES list — do not add a Python-side parameter"

requirements-completed: [AI-03, MCP-03]

duration: 2 min
completed: 2026-05-02
---

# Phase 05 Plan 10: Gap Closure — RAG Threshold + MCP UUID Summary

**Configurable RAG similarity threshold (default 0.45 for OpenRouter) and server-side gen_random_uuid() in mcp_action_logs INSERT — both Phase 05 runtime blockers closed, 13/13 unit tests green.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-02T19:04:45Z
- **Completed:** 2026-05-02T19:06:44Z
- **Tasks:** 2 (both autonomous)
- **Files modified:** 6

## Accomplishments

- Added `RAG_SIMILARITY_THRESHOLD` to `ai_service.config.Settings` with default `0.45` (tunable via env var); removed hardcoded `SIMILARITY_THRESHOLD = 0.75` module constant from `ai_service/rag.py`.
- Refactored `create_rag_tool` to accept `similarity_threshold` as a keyword argument and wired `settings.RAG_SIMILARITY_THRESHOLD` through `invoke_agent` in `ai_service/agent.py`.
- Added `test_retrieval_uses_custom_threshold` and updated existing tests to pass the threshold explicitly instead of relying on the removed module constant.
- Fixed `mcp_server/middleware.py` INSERT to include the `id` column with `gen_random_uuid()` in the VALUES clause, eliminating the `null value in column "id"` NOT NULL violation that crashed every MCP tool call.
- Added `assert "gen_random_uuid()" in query` to the existing success-path middleware test to lock in the fix.

## Task Commits

Each task was committed atomically:

1. **Task 1: Configurable RAG similarity threshold** — `97fb2d1` (feat)
2. **Task 2: gen_random_uuid() in mcp_action_logs INSERT** — `34d881e` (fix)

**Plan metadata:** _(committed at end of plan)_ (docs: complete gap closure plan)

## Files Created/Modified

- `ai_service/config.py` — Added `RAG_SIMILARITY_THRESHOLD: float` Settings field reading `RAG_SIMILARITY_THRESHOLD` env var with default `0.45`.
- `ai_service/rag.py` — Removed `SIMILARITY_THRESHOLD = 0.75` module constant; added `similarity_threshold: float = 0.45` keyword argument to `create_rag_tool` and used it inside the SQL execute call.
- `ai_service/agent.py` — `invoke_agent` now passes `settings.RAG_SIMILARITY_THRESHOLD` to `create_rag_tool` so the runtime always uses the configured threshold.
- `ai_service/tests/test_rag_retrieval.py` — Dropped import of removed `SIMILARITY_THRESHOLD` constant; updated existing tests to pass explicit threshold `0.75`; added `test_retrieval_uses_custom_threshold` that verifies the custom value propagates into the SQL parameter tuple.
- `mcp_server/middleware.py` — INSERT INTO `mcp_action_logs` now lists `id` first in the column list and `gen_random_uuid()` first in the VALUES clause; positional parameters `$1–$8` unchanged.
- `mcp_server/tests/test_middleware_logging.py` — Added `assert "gen_random_uuid()" in query` immediately after the existing `"INSERT INTO mcp_action_logs" in query` assertion in the success test.

## Decisions Made

- **RAG default threshold 0.45 (OpenRouter-tuned):** UAT Test 3 showed OpenRouter-proxied `text-embedding-3-small` maxes out around 0.67 for the exact document title (0.49–0.67 range for relevant content). Setting the default to 0.45 keeps relevant chunks above the line while still filtering obvious noise. Operators who switch to direct OpenAI can raise it via env var.
- **Configurable via Settings, not CLI flag:** Putting the threshold into `ai_service.config.Settings` matches the existing pattern (`CHAT_HISTORY_K`, `MAX_AGENT_ITERATIONS`, `EMBEDDING_PROVIDER`) and keeps env-var tuning uniform across the service.
- **Server-side gen_random_uuid() vs Python-side uuid4():** Chose Postgres-side generation because the schema was designed for it (UUID primary keys elsewhere in the stack already rely on Postgres defaults), and it keeps the Python-side positional parameter order stable — avoiding any change to the existing middleware test destructuring.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required. The new `RAG_SIMILARITY_THRESHOLD` env var has a safe default (`0.45`); operators only need to set it if they want to override per-provider.

## Next Phase Readiness

- **Phase 05 gap closure complete** — both blockers from `05-UAT.md` are eliminated at the unit-test level:
  - RAG tool will now return chunks for academic queries whose similarity lies in the 0.45–0.67 band that OpenRouter produces.
  - MCP tool calls no longer crash during action logging, unblocking the end-to-end agent flow that Phase 06 depends on.
- **Live UAT re-run still required** — unit tests verify the code contract; a fresh `/chat` request through the stack (Test 3 + Test 6 in `05-UAT.md`) is the final confirmation that OpenRouter-scored chunks are actually returned and that `mcp_action_logs` accepts inserts. This is an operational step, not a code gate.
- **Phase 06 unblocks** — the MCP action-log NOT NULL violation was the underlying cause of cascading agent failures noted in Phase 05 "Additional Findings"; with that fixed, the WhatsApp → AI → MCP path is free of known code-level crashes.

---
*Phase: 05-ai-service*
*Completed: 2026-05-02*

## Self-Check: PASSED

- `ai_service/config.py` contains `RAG_SIMILARITY_THRESHOLD` — verified with grep
- `ai_service/rag.py` no longer contains `SIMILARITY_THRESHOLD = 0.75` — verified with grep
- `ai_service/rag.py` accepts `similarity_threshold` kwarg — verified with grep
- `ai_service/tests/test_rag_retrieval.py` contains `test_retrieval_uses_custom_threshold` — verified with grep
- `mcp_server/middleware.py` contains `gen_random_uuid()` — verified with grep
- `mcp_server/tests/test_middleware_logging.py` contains `gen_random_uuid()` assertion — verified with grep
- Commits `97fb2d1` (Task 1) and `34d881e` (Task 2) present in `git log` — verified below
- `python -m pytest ai_service/tests/test_rag_retrieval.py mcp_server/tests/test_middleware_logging.py -v` → 13 passed, 0 failed
