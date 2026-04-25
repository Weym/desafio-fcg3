---
phase: 05-ai-service
plan: 03
subsystem: ai
tags: [langchain, rag, pgvector, psycopg3, openai]
requires:
  - phase: 05-ai-service
    provides: AI service scaffold with psycopg3 pool, settings, and prompt loading
provides:
  - LangChain RAG tool factory bound to the AI service DB pool
  - Pgvector cosine similarity search against knowledge_base_chunks with 0.75 threshold
  - Formatted top-3 knowledge-base chunks for academic policy responses
affects: [05-04, 05-05, ai_service]
tech-stack:
  added: []
  patterns: [LangChain @tool factory, raw psycopg3 pgvector similarity query, OpenAIEmbeddings query generation]
key-files:
  created: [ai_service/rag.py]
  modified: []
key-decisions:
  - "Used a raw parameterized pgvector SQL query instead of a higher-level retriever so retrieval matches the existing knowledge_base_chunks schema exactly."
  - "Formatted retrieved chunks with source, category, and similarity so the agent receives grounded RAG context instead of raw text fragments."
patterns-established:
  - "RAG tools in the AI service are created through factory closures that capture shared dependencies like the DB pool and embeddings client."
  - "Knowledge base retrieval returns an empty string when no chunk clears the threshold, letting the system prompt drive the fallback response."
requirements-completed: [AI-03]
duration: 4 min
completed: 2026-04-25
---

# Phase 05 Plan 03: RAG Tool Summary

**LangChain knowledge-base search tool using OpenAI query embeddings and pgvector cosine similarity against academic policy chunks.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-25T20:25:00-03:00
- **Completed:** 2026-04-25T20:29:01.9369948-03:00
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Added `create_rag_tool` to bind a LangChain `@tool` to the AI service DB pool.
- Implemented query embedding generation with `text-embedding-3-small` and parameterized pgvector similarity search.
- Returned formatted top-3 chunk context or an empty string when no result meets the 0.75 threshold.

## Task Commits

Each task was committed atomically:

1. **Task 1: RAG tool with pgvector cosine search** - `b3d3a33` (feat)

## Files Created/Modified
- `ai_service/rag.py` - exports the LangChain RAG tool factory and the thresholded similarity-search logic.

## Decisions Made
- Used a raw SQL query with `%s` parameters and `::vector` casting so the tool stays aligned with the existing `knowledge_base_chunks` table and threat-model mitigation for SQL injection.
- Included source, category, and similarity metadata in each returned chunk to help the agent ground policy answers.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first patch targeted the wrong repository root; the file was immediately recreated in the dedicated worktree and the stray file was removed before continuing.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for Plan 05-04 to wire this tool into the agent alongside MCP tools.
- The AI service now has a reusable RAG retrieval primitive matching the documented threshold and chunk limits.

## Self-Check: PASSED

---
*Phase: 05-ai-service*
*Completed: 2026-04-25*
