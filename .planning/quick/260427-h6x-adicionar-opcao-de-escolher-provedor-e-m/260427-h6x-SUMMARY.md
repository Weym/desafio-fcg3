---
phase: quick-260427-h6x
plan: 01
subsystem: ai
tags: [embeddings, openai, openrouter, langchain, rag, ingest]

# Dependency graph
requires:
  - phase: 05-ai-service
    provides: "AI service with RAG pipeline, ingest, agent, and llm_factory pattern"
provides:
  - "Provider-agnostic embedding factory (create_embeddings, get_embedding_api_key)"
  - "EMBEDDING_PROVIDER and EMBEDDING_MODEL env var support across AI service"
affects: [05-ai-service, 06-whatsapp-webhook]

# Tech tracking
tech-stack:
  added: []
  patterns: ["embedding_factory.py mirrors llm_factory.py for provider-agnostic embeddings"]

key-files:
  created:
    - ai_service/embedding_factory.py
  modified:
    - ai_service/config.py
    - ai_service/ingest.py
    - ai_service/rag.py
    - ai_service/agent.py
    - docker-compose.yml
    - .env.example
    - ai_service/tests/test_ingest.py
    - ai_service/tests/test_rag_retrieval.py
    - ai_service/tests/test_agent_flow.py
    - ai_service/tests/test_conversation_memory.py

key-decisions:
  - "Followed llm_factory.py pattern: lazy imports per provider branch, same function signature style"
  - "embed_chunks() now receives pre-built Embeddings instance instead of raw API key for full decoupling"
  - "get_embedding_api_key() helper provides raw key for IngestSettings backward compat"

patterns-established:
  - "embedding_factory.py: provider-agnostic embedding creation matching llm_factory.py pattern"

requirements-completed: [QUICK-embedding-provider-config]

# Metrics
duration: 4min
completed: 2026-04-27
---

# Quick Task 260427-h6x: Configurable Embedding Provider Summary

**Provider-agnostic embedding factory with EMBEDDING_PROVIDER/EMBEDDING_MODEL env vars, routing embeddings through OpenAI or OpenRouter across ingest and RAG pipelines**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-27T15:26:00Z
- **Completed:** 2026-04-27T15:30:43Z
- **Tasks:** 3
- **Files modified:** 11

## Accomplishments
- Created `embedding_factory.py` with `create_embeddings()` and `get_embedding_api_key()` following `llm_factory.py` pattern
- Removed all hardcoded `text-embedding-3-small` and direct `OpenAIEmbeddings` from `ingest.py` and `rag.py`
- Wired configurable embeddings through `agent.py` → `rag.py` and `ingest.py` → `embedding_factory.py`
- Updated docker-compose.yml and .env.example with new environment variables
- All 19 existing tests pass with updated signatures

## Task Commits

Each task was committed atomically:

1. **Task 1: Add embedding config + factory** - `6764b16` (feat)
2. **Task 2: Wire factory into ingest, rag, and agent** - `1d8a0f7` (feat)
3. **Task 3: Update env config, docker-compose, and fix tests** - `0aceac2` (chore)

## Files Created/Modified
- `ai_service/embedding_factory.py` - Provider-agnostic embedding instance factory with openai/openrouter support
- `ai_service/config.py` - Added EMBEDDING_PROVIDER and EMBEDDING_MODEL settings fields
- `ai_service/ingest.py` - Replaced hardcoded embedding model with factory-based creation
- `ai_service/rag.py` - Receives pre-built embeddings instance instead of creating internally
- `ai_service/agent.py` - Wires create_embeddings() to build embeddings before rag tool creation
- `docker-compose.yml` - Added EMBEDDING_PROVIDER/EMBEDDING_MODEL to langchain-service env block
- `.env.example` - Documented both new environment variables
- `ai_service/tests/test_ingest.py` - Updated IngestSettings mock and embed_chunks signature
- `ai_service/tests/test_rag_retrieval.py` - Pass FakeEmbeddings instance instead of api_key string
- `ai_service/tests/test_agent_flow.py` - Added create_embeddings monkeypatch and embedding assertions
- `ai_service/tests/test_conversation_memory.py` - Added create_embeddings monkeypatch and settings fields

## Decisions Made
- Followed `llm_factory.py` pattern: lazy imports per provider branch, same function signature style
- Changed `embed_chunks()` to accept pre-built `Embeddings` instance instead of raw API key for full decoupling from specific providers
- Added `get_embedding_api_key()` helper so `IngestSettings` can still validate the required key at startup

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required. Backward-compatible defaults (`openai` + `text-embedding-3-small`) preserve existing behavior.

## Next Phase Readiness
- Embedding configuration is fully decoupled from provider — ready for any provider the team selects
- Phase 05 AI service gaps (ingest key validation, chat_messages insert) are pre-existing and not affected by this change

---
*Quick Task: 260427-h6x*
*Completed: 2026-04-27*

## Self-Check: PASSED

All 5 created/modified files verified on disk. All 3 task commits verified in git log.
