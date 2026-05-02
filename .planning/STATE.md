---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
last_updated: "2026-05-02T20:29:14.389Z"
last_activity: 2026-05-02
progress:
  total_phases: 6
  completed_phases: 6
  total_plans: 46
  completed_plans: 46
  percent: 100
---

# Project State

## Current Position

Phase: 06
Plan: Not started
Status: Ready to execute
Last activity: 2026-05-02

Progress: [█████████░] 90%

## Performance Metrics

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 01-infrastructure-schema P06 | 8 min | 2 tasks | 4 files |
| Phase 01-infrastructure-schema P07 | 25 min | 2 tasks | 7 files |
| Phase 02-authentication P01 | 10 min | 6 tasks | 26 files |
| Phase 02-authentication P02 | 18 min | 6 tasks | 12 files |
| Phase 02-authentication P03 | 3 min | 3 tasks | 5 files |
| Phase 02-authentication P04 | 5 min | 6 tasks | 5 files |
| Phase 03 P10 | 4 min | 2 tasks | 2 files |
| Phase 03 P09 | 8 min | 2 tasks | 3 files |
| Phase 03 P11 | 4 min | 2 tasks | 2 files |
| Phase 03 P12 | 74 min | 2 tasks | 3 files |
| Phase 03 P13 | 20 min | 2 tasks | 3 files |
| Phase 03-business-feature-slices P14 | 8 min | 2 tasks | 2 files |
| Phase 04 P05 | 19 min | 2 tasks | 5 files |
| Phase 04 P06 | 5 min | 2 tasks | 4 files |
| Phase 05 P07 | 25 | 2 tasks | 6 files |
| Phase 06 P01 | 6 min | 2 tasks | 11 files |
| Phase 06 P02 | 3 min | 2 tasks | 5 files |
| Phase 06 P03 | 2 min | 2 tasks | 4 files |
| Phase 06 P04 | 13 min | 2 tasks | 17 files |
| Phase 05 P10 | 2 min | 2 tasks | 6 files |
| Phase 01-infrastructure-schema P08 | 1 min | 3 tasks | 2 files |

## Phase Status

| Phase | Name | Status |
|-------|------|--------|
| 1 | Infrastructure & Schema | complete |
| 2 | Authentication | complete |
| 3 | Business Feature Slices | complete |
| 4 | MCP Server | complete |
| 5 | AI Service | gaps_found |
| 6 | WhatsApp Webhook & Integration | blocked |

## Current Focus

**Phase 05 UAT re-run complete (2026-04-30) — 1 blocker remains**
Plans 08-09 fixed the credential alignment and UUID generation issues. Fresh UAT passed 4/6 tests. One blocker: RAG similarity scores via OpenRouter embeddings are systematically low (max ~0.67 vs threshold 0.75), so the knowledge base tool always returns empty. MCP action logging also has a UUID issue (non-blocking for Phase 05 scope but affects Phase 06 integration).
Next action: `/gsd-plan-phase 05 --gaps` to plan the RAG threshold fix, then execute.
Resume file: None

## Accumulated Context

### Decisions

Recent decisions affecting current work:

- [Phase 01]: Preserved D-05 by clarifying the existing Docker Compose bootstrap flow instead of replacing it.
- [Phase 01]: Preserved D-08 by limiting the fix to documentation and keeping AI/MCP as Phase 1 healthcheck stubs.
- [Phase 01]: Gap closure plan 01-07 restores Docker runtime DB authentication without deleting the persisted volume or bypassing Alembic/seed commands.
- [Phase 01]: PostgreSQL startup now reconciles the configured role, password, and database on every container boot instead of requiring manual volume repair.
- [Phase 01]: FastAPI runtime, Alembic, and test helpers now derive DSNs from one POSTGRES_* credential source while preserving explicit DATABASE_URL overrides.
- [Phase 01]: Validation and UAT are both verified; Phase 1 is complete.
- [Phase 02]: Settings module at `config.py` (not `settings.py`) — Phase 1 convention preserved.
- [Phase 02]: Migration numbered 007a (not 003) — Phase 1 already used 003a-006a for business tables.
- [Phase 02]: JSONResponse used instead of HTTPException for canonical error shape `{"error": {...}}`.
- [Phase 02]: BodyCacheMiddleware added for slowapi sync key_func compatibility (P-01).
- [Phase 02]: SQLite+aiosqlite test engine with ForUpdateArg compiler hook for PostgreSQL-free testing.
- [Phase 02]: Security audit passed — 24/24 threats closed at ASVS Level 1.
- [Phase 03]: Shared infrastructure layer: PaginationParams, AppException, dual-auth (JWT + X-Service-Token), check_ownership, BaseService[T].
- [Phase 03]: 7 vertical feature slices implemented: Students, Courses, Enrollment, Grades, Documents, Appointments, Staff Dashboard.
- [Phase 03]: Enrollment model check constraint updated to include 'locked' status (deviation from original schema).
- [Phase 03]: Alembic migration 008a added for missing `notes` column on documents table.
- [Phase 03]: SELECT FOR UPDATE bug in appointments fixed — joinedload with FOR UPDATE causes outer join error in PostgreSQL; separated lock query from relationship loading.
- [Phase 03]: WR-09 from code review: `require_staff` blocks `service` role — MCP cannot access staff endpoints. Must decide in Phase 4 if MCP needs staff-level access.
- [Phase 03]: Fix UAT Test 6 in the database layer by recreating ck_enrollments_status with locked instead of changing already-correct enrollment service logic
- [Phase 03]: Verify the enrollment lock gap with real confirm_enrollment and lock_enrollment calls plus a direct post-commit PostgreSQL re-query
- [Phase 03]: Kept the available-courses fix in the controller/docs layer because the student service already returned list[AvailableCourseItem].
- [Phase 03]: Used an authenticated integration regression with a monkeypatched service result to isolate the route contract bug while preserving auth and ownership checks.
- [Phase 03]: Kept the STU-06 repair in StudentService only so the controller and response schema contract remain unchanged
- [Phase 03]: Used timezone-aware UTC datetimes when combining slot date and start_time for AcademicSummaryResponse.next_appointment
- [Phase 03]: Code-review follow-up was stopped after a capped 3-iteration auto-fix loop; latest fixes are recorded in `03-REVIEW-FIX.md`, but a final clean re-review still has not been captured.
- [Phase 03]: Closed the 009a drift in the dev runtime by mounting Alembic assets into fastapi-app instead of changing enrollment business logic
- [Phase 03]: Made the verifier fail on stale Alembic head/current state before any confirm_enrollment or lock_enrollment write path runs
- [Phase 03]: Installed requirements-dev.txt on top of requirements.txt in fastapi-app so the existing backend container can serve both runtime and focused regression needs
- [Phase 03]: Kept the gap closure scoped to the current fastapi-app service and aligned docs to its Docker exec workflow instead of adding a second backend test container
- [Phase 03]: Follow-up runtime proof for 03-12 succeeded in Docker after `alembic upgrade head` advanced the live stack from `008a` to `009a` and the enrollment lock verifier passed end-to-end
- [Phase 03]: Follow-up runtime proof for 03-13 required adding `aiosqlite` to `backend/requirements-dev.txt` because `backend/tests/conftest.py` uses a `sqlite+aiosqlite` async test engine
- [Phase 03-business-feature-slices]: Kept the COURSE-03 repair inside CourseService._build_prerequisite_tree so the endpoint contract and recursive CTE stay unchanged
- [Phase 03-business-feature-slices]: Used synthetic flat rows in a pure unit regression to prove both the root-cycle bug and the preserved acyclic nesting behavior
- [Phase 04]: Kept FastMCP as the exported server and moved startup side effects behind main() so imports remain safe inside active event loops.
- [Phase 04]: Matched both Docker image and bind-mounted compose development to the same package layout by running python -m mcp_server.main and mounting ./mcp_server at /app/mcp_server.
- [Phase 04]: Centralized chat-session UUID parsing, active-session lookup, and DB-pool validation in dependencies.py so resolver and middleware fail with the same guard logic.
- [Phase 04]: Made audit logging a hard precondition and a hard postcondition: tools only run with valid audit context, and log insert failures now fail the call instead of being swallowed.
- [Phase 04]: Normalized the MCP runtime database DSN before passing it to `asyncpg.create_pool(...)` so the container boot path accepts the shared `postgresql+asyncpg://` configuration used elsewhere in the stack.
- [Phase 04]: Split the MCP backend health probe from the versioned API base URL so the MCP `/health` check hits FastAPI's real root `/health` endpoint during cold starts.
- [Phase 05]: Used python -m ai_service.main as the shared AI runtime entrypoint so Docker and compose stay aligned with the package layout.
- [Phase 05]: Normalized SQLAlchemy-style PostgreSQL URLs before psycopg usage so the AI service can share the repository DATABASE_URL contract.
- [Phase 05]: Closed AI-01 and AI-02 by returning the last assistant-authored LangChain message and persisting the inbound user turn before agent execution.
- [Phase 05]: Plan `05-07` restored package/runtime alignment; `fcg3-ai` is healthy and `/health` returns `{"status":"healthy"}` in the live stack.
- [Phase 05]: Resumed UAT on 2026-04-26 reopened the phase with three blockers recorded in `05-UAT.md`.
- [Phase 05]: The secured compose topology no longer publishes AI-service port `8001` to the host, so host-level `localhost:8001/health` checks fail even though the container healthcheck passes internally.
- [Phase 05]: The current runtime environment has an invalid OpenAI embeddings key for ingest, and the live `chat_messages` insert path fails because it does not satisfy the table's required `id` column.
- [Phase 06]: Settings use config.py (not settings.py) matching Phase 2 convention
- [Phase 06]: Partial unique index on whatsapp_message_id WHERE NOT NULL for message dedup
- [Phase 06]: Verification flow reuses OTP service directly instead of HTTP calls to auth endpoints
- [Phase 06]: Background task opens own async_session (CRITICAL-4) — never request-scoped; AI service retry: 1 retry then fallback; per-session asyncio.Lock keyed by session_id; pg_cron auto-close every hour for 24h inactive sessions
- [Phase 06]: Used require_role('staff') for chat visibility endpoints — simpler than dual-auth for pure staff-only access
- [Phase 06]: Included chat_sessions/chat_messages in SQLite test tables; patch_webhook_db fixture for async_session redirect; MagicMock for httpx Response (sync .json() method)
- [Phase 05]: RAG similarity threshold made configurable via RAG_SIMILARITY_THRESHOLD env var (default 0.45) because OpenRouter embedding proxy caps similarity at ~0.67 for perfect matches — 0.75 default was too aggressive
- [Phase 05]: mcp_action_logs INSERT now uses server-side gen_random_uuid() for the id column instead of adding Python-side UUID generation — schema owns the default, positional parameters unchanged, middleware test destructuring preserved
- [Phase 01-infrastructure-schema]: knowledge_base_chunks placed first in WARNING_TABLES — no FK deps, safe truncate order
- [Phase 01-infrastructure-schema]: Docker pre-flight check requires postgres + fastapi-app services only (minimum for phase_01 tests)

### Key Decisions Pending

- LLM provider selection (OpenAI vs Gemini) — decided by third party; architecture supports both via `LLM_PROVIDER` env var
- `asyncio.create_task` + `add_done_callback` pattern must be used in Phase 6 (not bare `create_task`) — see SUMMARY.md CRITICAL-3

### Known Risks

- Phase 05 RAG retrieval is non-functional: OpenRouter embedding proxy produces cosine similarity scores 0.49-0.67 for highly relevant content, always below the 0.75 threshold in `ai_service/rag.py`. Fix: make threshold configurable or lower it.
- MCP action logging (`mcp_action_logs.id`) does not generate UUIDs — MCP tool calls crash during action logging. Affects Phase 06 integration when agent invokes MCP tools.
- Windows portability: `reconcile_dev_credentials.sh` needs `.gitattributes` enforcement of LF line endings.
- Phase 6 must preserve the <5s WhatsApp webhook response budget by keeping AI work in background tasks with explicit `done_callback` error logging.

### Architecture Constraints (non-negotiable)

- `student_id` is NEVER exposed to the LangChain agent — always injected by MCP Server
- `MCP_SERVICE_TOKEN` only in environment variables, never in source code
- Webhook must return 200 OK in < 5 seconds (WhatsApp limit)
- Two separate PostgreSQL drivers: `asyncpg` for FastAPI + MCP; `psycopg3` for LangChain service
- HMAC validation: use `await request.body()` BEFORE any JSON parsing in webhook handler
- Alembic migration #001 MUST be `CREATE EXTENSION IF NOT EXISTS vector` before any table with `vector` column

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260427-h6x | adicionar opcao de escolher provedor e modelo do embedding via env | 2026-04-27 | 0aceac2 | [260427-h6x-adicionar-opcao-de-escolher-provedor-e-m](./quick/260427-h6x-adicionar-opcao-de-escolher-provedor-e-m/) |

## Session Continuity

To resume work: read this file, then read `.planning/ROADMAP.md` to see current phase and plan status.
