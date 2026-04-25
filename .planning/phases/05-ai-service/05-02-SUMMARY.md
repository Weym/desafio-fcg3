---
phase: 05-ai-service
plan: 02
subsystem: ai
tags: [langchain, openai, pgvector, psycopg, rag, ingest]
requires:
  - phase: 01-infrastructure-schema
    provides: PostgreSQL schema with knowledge_base_chunks table and pgvector extension
  - phase: 05-ai-service
    provides: AI service scaffold and container stub
provides:
  - Knowledge base placeholder documents in Portuguese for matricula, FAQ, calendario, curriculo, and regulamento
  - Ingest script with token-based chunking, OpenAI embeddings, delete-then-insert persistence, and audit JSON output
  - Docker packaging updates so the AI service can run `python -m ai_service.ingest`
affects: [05-03, rag, ai_service]
tech-stack:
  added: [langchain, langchain-community, langchain-openai, langchain-text-splitters, psycopg, tiktoken, pypdf]
  patterns: [token-based document chunking, per-source delete-then-insert refresh, PDF parse fallback to plain text]
key-files:
  created: [ai_service/knowledge/matricula.md, ai_service/knowledge/faq.md, ai_service/knowledge/calendario.md, ai_service/knowledge/curriculo.md, ai_service/knowledge/regulamento.pdf, ai_service/ingest.py, ai_service/__init__.py]
  modified: [ai_service/requirements.txt, ai_service/Dockerfile, .gitignore]
key-decisions:
  - "Used raw psycopg writes for knowledge_base_chunks so the ingest pipeline matches the existing Phase 1 schema exactly."
  - "Persisted ingest audit data to ai_service/knowledge/.last_ingest.json because no dedicated audit table exists in the current schema."
patterns-established:
  - "Knowledge documents live under ai_service/knowledge and are processed through CATEGORY_MAP-controlled source ordering."
  - "Placeholder PDFs are attempted with PyPDFLoader first, then downgraded to plain-text fallback for development content."
requirements-completed: [AI-05]
duration: 2 min
completed: 2026-04-25
---

# Phase 05 Plan 02: Knowledge Base Ingest Summary

**Knowledge base placeholders plus a PGVector ingest script with tiktoken chunking, OpenAI embeddings, and per-source refresh semantics.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-25T20:09:19-03:00
- **Completed:** 2026-04-25T20:10:52-03:00
- **Tasks:** 2
- **Files modified:** 10

## Accomplishments

- Added the five source documents required for the first academic knowledge base.
- Implemented `ai_service/ingest.py` with 500/50 token chunking, OpenAI `text-embedding-3-small`, and parameterized psycopg inserts.
- Updated AI service packaging so the ingest module, knowledge files, and audit output path work in the container layout.

## Task Commits

Each task was committed atomically:

1. **Task 1: Knowledge base placeholder documents** - `71e0c17` (feat)
2. **Task 2: Ingest script with chunking, embedding, and DB storage** - `2d0b0b8` (feat)

## Files Created/Modified

- `ai_service/knowledge/matricula.md` - Placeholder enrollment rules and deadlines in Portuguese.
- `ai_service/knowledge/faq.md` - Frequently asked questions for secretaria workflows.
- `ai_service/knowledge/calendario.md` - Semester, enrollment, exam, and holiday dates.
- `ai_service/knowledge/curriculo.md` - Eight-semester Computer Science curriculum overview.
- `ai_service/knowledge/regulamento.pdf` - Development placeholder for PDF ingest fallback handling.
- `ai_service/ingest.py` - Manual ingest pipeline for loading, chunking, embedding, and persisting knowledge chunks.
- `ai_service/requirements.txt` - Runtime dependencies required by the ingest pipeline.
- `ai_service/Dockerfile` - Package-oriented copy and module import path for AI service execution.
- `ai_service/__init__.py` - AI service package marker for module execution.
- `.gitignore` - Ignore generated ingest audit output.

## Decisions Made

- Used raw psycopg SQL for writes so `knowledge_base_chunks` continues to match the schema documented in `docs/database.md`.
- Stored the ingest audit summary in `ai_service/knowledge/.last_ingest.json` instead of inventing a new database table outside plan scope.
- Added Dockerfile and dependency updates as execution support because the original stub image could not package or run `ai_service.ingest` from the worktree layout.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Enabled packaged ingest execution in the AI service container**
- **Found during:** Task 2 (Ingest script with chunking, embedding, and DB storage)
- **Issue:** The existing AI service stub only copied `main.py`, so `python -m ai_service.ingest` and bundled knowledge files would not exist in Docker.
- **Fix:** Added `ai_service/__init__.py`, expanded `ai_service/requirements.txt`, updated `ai_service/Dockerfile` to copy the package, and ignored the generated `.last_ingest.json` audit artifact.
- **Files modified:** `ai_service/__init__.py`, `ai_service/requirements.txt`, `ai_service/Dockerfile`, `.gitignore`
- **Verification:** `python -c "import ast, pathlib; ast.parse(pathlib.Path('ai_service/ingest.py').read_text(encoding='utf-8')); print('ingest.py parses OK')"` and static pattern verification for delete/query/chunker/model strings.
- **Committed in:** `2d0b0b8`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The deviation kept scope aligned while making the documented ingest execution path actually packageable.

## Issues Encountered

- Initial file creation landed outside the worktree because of a patch path mismatch; the task was immediately redone with explicit worktree paths before verification and commit.

## Known Stubs

- `ai_service/knowledge/regulamento.pdf` - placeholder text file with `.pdf` extension by plan design; real PDF content will replace it later.
- `ai_service/knowledge/matricula.md` - development placeholder content pending official academic source text.
- `ai_service/knowledge/faq.md` - development placeholder content pending official academic source text.
- `ai_service/knowledge/calendario.md` - development placeholder content pending official academic source text.
- `ai_service/knowledge/curriculo.md` - development placeholder content pending official academic source text.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The repository now has source documents and a refreshable ingest pipeline for Plan 05-03 retrieval work.
- Running the ingest script still requires valid `DATABASE_URL` and `OPENAI_API_KEY` at execution time.

## Self-Check: PASSED

- Found summary file: `.planning/phases/05-ai-service/05-02-SUMMARY.md`
- Found commit: `71e0c17`
- Found commit: `2d0b0b8`

---
*Phase: 05-ai-service*
*Completed: 2026-04-25*
