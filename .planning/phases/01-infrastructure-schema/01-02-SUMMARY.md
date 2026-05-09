---
phase: 01-infrastructure-schema
plan: 02
subsystem: database
tags: [sqlalchemy, alembic, postgres, pgvector, hnsw]
requires:
  - phase: 01-infrastructure-schema
    provides: docker and backend dependency scaffolding from plan 01-01
provides:
  - feature-scoped SQLAlchemy ORM models for the documented academic schema
  - sync Alembic configuration with ordered pgvector-first migrations
  - central metadata registry for Alembic autogenerate and schema discovery
affects: [authentication, business-slices, mcp-server, ai-service]
tech-stack:
  added: [SQLAlchemy ORM models, Alembic migrations, pgvector schema support]
  patterns: [feature-scoped models, sync-migration-async-runtime split, domain-grouped revisions]
key-files:
  created:
    - backend/src/infrastructure/database.py
    - backend/src/features/auth/models.py
    - backend/src/features/courses/models.py
    - backend/src/features/enrollment/models.py
    - backend/src/features/students/models.py
    - backend/src/features/documents/models.py
    - backend/src/features/scheduling/models.py
    - backend/src/features/chat/models.py
    - backend/src/features/knowledge_base/models.py
    - backend/alembic/env.py
    - backend/alembic/versions/001_create_pgvector.py
    - backend/alembic/versions/006_create_chat_knowledge_tables.py
  modified:
    - backend/src/infrastructure/models.py
key-decisions:
  - "Kept runtime database access async while Alembic remains sync via psycopg2-compatible URLs."
  - "Split migrations by domain and added the students->curriculum foreign key in migration 003 to preserve the planned revision order."
  - "Used docs/database.md as the source of truth when it conflicted with the plan's outdated 17-table count."
patterns-established:
  - "Feature models own their table definitions while infrastructure/models.py aggregates metadata for tooling."
  - "PostgreSQL enum-like fields are represented as VARCHAR + CHECK constraints for explicit schema control."
requirements-completed: [INFRA-02]
duration: 17 min
completed: 2026-04-24
---

# Phase 01 Plan 02: Alembic async configuration Summary

**SQLAlchemy models and Alembic migrations now define the full documented academic schema, including pgvector bootstrap and the HNSW knowledge-base index.**

## Performance

- **Duration:** 17 min
- **Started:** 2026-04-24T02:51:49Z
- **Completed:** 2026-04-24T03:08:32Z
- **Tasks:** 3
- **Files modified:** 29

## Accomplishments
- Added backend database infrastructure with async engine/session primitives and a shared declarative base.
- Implemented feature-scoped ORM models for students, auth, curriculum, enrollment, documents, scheduling, chat, and knowledge base data.
- Added a six-step Alembic revision chain that creates pgvector first and then applies domain-grouped schema migrations.

## Task Commits

Each task was committed atomically:

1. **Task 1: Database infrastructure** - `9bf2958` (feat)
2. **Task 2: SQLAlchemy ORM models for all documented tables** - `735a422` (feat)
3. **Task 3: Alembic config and domain-grouped migrations** - `d52b4db` (feat)

**Plan metadata:** pending

## Files Created/Modified
- `backend/src/infrastructure/database.py` - async SQLAlchemy engine, session factory, and `Base`
- `backend/src/infrastructure/models.py` - central metadata registry with dual import-path support
- `backend/src/features/auth/models.py` - students, staff, verification codes, sessions, and FCM tokens
- `backend/src/features/courses/models.py` - courses, prerequisites, curriculum, and curriculum-course joins
- `backend/src/features/enrollment/models.py` - enrollment periods, enrollments, and enrollment-course rows
- `backend/src/features/students/models.py` - grade records with numeric grading columns and indexes
- `backend/src/features/documents/models.py` - document request lifecycle schema
- `backend/src/features/scheduling/models.py` - resources, slots, and appointments
- `backend/src/features/chat/models.py` - chat sessions, chat messages, and MCP action logs
- `backend/src/features/knowledge_base/models.py` - pgvector-backed RAG chunk storage with HNSW index metadata
- `backend/alembic/env.py` - sync Alembic environment derived from env vars only
- `backend/alembic/versions/001_create_pgvector.py` - pgvector extension bootstrap
- `backend/alembic/versions/002_create_auth_tables.py` - auth schema migration
- `backend/alembic/versions/003_create_curriculum_tables.py` - curriculum schema plus deferred students FK
- `backend/alembic/versions/004_create_enrollment_tables.py` - enrollment and grades schema
- `backend/alembic/versions/005_create_documents_scheduling_tables.py` - documents and scheduling schema
- `backend/alembic/versions/006_create_chat_knowledge_tables.py` - chat, MCP logs, and knowledge base schema

## Decisions Made
- Used `VARCHAR` + `CHECK` constraints instead of database enum types so migrations stay explicit and autogenerate-friendly.
- Preserved the planned migration ordering by creating `students.curriculum_id` in auth first and attaching its foreign key only after `curriculum` exists.
- Added import fallbacks in the model registry so both `backend/src`-root imports and `src.*` package imports work during verification and Alembic execution.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected the schema count from 17 to 21 tables**
- **Found during:** Task 2 (SQLAlchemy ORM models)
- **Issue:** `01-02-PLAN.md` repeatedly stated 17 tables, but `docs/database.md` defines 21 concrete tables.
- **Fix:** Implemented all 21 documented tables and aligned verification around the authoritative schema source.
- **Files modified:** `backend/src/features/*/models.py`, `backend/src/infrastructure/models.py`, `backend/alembic/versions/*.py`
- **Verification:** `python -c` metadata load reported 21 tables; offline Alembic SQL generation included all 21 table creates.
- **Committed in:** `735a422`, `d52b4db`

**2. [Rule 3 - Blocking] Added dual import-path support for the metadata registry**
- **Found during:** Task 3 (Alembic config and migrations)
- **Issue:** `backend/src`-root imports worked, but `src.infrastructure.models` failed, which blocked Alembic's package-style loading.
- **Fix:** Added a top-level/package import fallback in `backend/src/infrastructure/models.py`.
- **Files modified:** `backend/src/infrastructure/models.py`
- **Verification:** Both `from infrastructure.models import Base` and `import src.infrastructure.models` loaded 21 tables successfully.
- **Committed in:** `d52b4db`

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking)
**Impact on plan:** Both fixes were required for correctness and executable migrations. No extra feature scope was added.

## Issues Encountered
- Docker Desktop's Linux engine was unavailable in this environment, so live PostgreSQL migration execution could not be completed against a running container.
- As a fallback, offline Alembic upgrade and downgrade SQL generation succeeded, and Python compilation/import checks passed for the ORM and migration modules.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- ORM metadata, migration chain, and pgvector schema artifacts are in place for downstream auth and business-feature work.
- Before phase verification, rerun `alembic upgrade head` and `alembic downgrade base` against a live PostgreSQL + pgvector instance once Docker is available.

## Deferred Issues
- Live container-backed verification of upgrade/downgrade remains pending because the local Docker daemon could not start the Linux engine during execution.

## Self-Check: PASSED
- Verified summary and key schema files exist on disk.
- Verified task commits `9bf2958`, `735a422`, and `d52b4db` exist in git history.

---
*Phase: 01-infrastructure-schema*
*Completed: 2026-04-24*
