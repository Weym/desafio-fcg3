---
phase: 06-whatsapp-webhook-integration
plan: 02
subsystem: webhook
tags: [whatsapp, background-task, asyncio, httpx, pg_cron, retry, fallback]

# Dependency graph
requires:
  - phase: 06-whatsapp-webhook-integration
    plan: 01
    provides: "Webhook router, WebhookService, WhatsAppClient, verification state machine"
  - phase: 01-infrastructure-schema
    provides: "DB session factory, ChatSession/ChatMessage models, async_session"
provides:
  - "Background task: AI service call with retry and fallback (WH-05)"
  - "Per-session asyncio.Lock for concurrent message protection (D-09)"
  - "Session lifecycle: updated_at tracking for pg_cron auto-close (CHAT-01)"
  - "pg_cron extension + auto-close job for inactive sessions (CHAT-02, D-12)"
  - "Alembic migration 011a: updated_at column + pg_cron scheduled job"
affects: [06-03, 06-04]

# Tech tracking
tech-stack:
  added: [pg_cron (PostgreSQL extension)]
  patterns: [per-session-lock, ai-service-retry-fallback, background-task-own-session, session-updated_at-tracking]

key-files:
  created:
    - backend/src/features/webhook/background.py
    - backend/alembic/versions/011_add_pg_cron_session_autoclose.py
  modified:
    - backend/src/features/webhook/router.py
    - backend/src/features/webhook/service.py
    - backend/src/features/chat/models.py

key-decisions:
  - "Background task opens own async_session (CRITICAL-4) — never request-scoped"
  - "AI service retry: one immediate retry on failure, then fallback message (D-06)"
  - "Per-session asyncio.Lock keyed by session_id str for concurrent protection (D-09)"
  - "pg_cron job runs hourly to close sessions inactive 24+ hours (D-12)"
  - "updated_at touched on every message save and session reuse for accurate inactivity tracking"

patterns-established:
  - "AI-service-retry-fallback: httpx POST with 50s timeout, 1 retry, fallback message"
  - "Per-session-lock: dict[str, asyncio.Lock] with setdefault for thread-safe lock creation"
  - "Session-updated_at-tracking: every message and session access touches updated_at"

requirements-completed: [WH-05, CHAT-01, CHAT-02]

# Metrics
duration: 3min
completed: 2026-04-30
---

# Phase 6 Plan 02: Background Task Processing Summary

**AI service integration with retry/fallback, per-session asyncio.Lock concurrency control, session lifecycle tracking via updated_at, and pg_cron auto-close for inactive sessions**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-30T16:42:52Z
- **Completed:** 2026-04-30T16:45:52Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Background task module bridging webhook to AI service with retry logic and fallback messaging
- Per-session asyncio.Lock preventing concurrent message processing for same student
- Session lifecycle management: updated_at column tracked on every message for pg_cron auto-close
- Alembic migration 011a installing pg_cron extension and scheduling hourly auto-close job
- Router updated to import real process_verified_message (replacing Plan 01 stub)

## Task Commits

Each task was committed atomically:

1. **Task 1: Background task with AI service call, retry, fallback, and per-session lock** - `7de5464` (feat)
2. **Task 2: Session lifecycle management + pg_cron auto-close migration** - `a611d3f` (feat)

## Files Created/Modified
- `backend/src/features/webhook/background.py` - Background task: AI service call, retry, fallback, per-session locking
- `backend/alembic/versions/011_add_pg_cron_session_autoclose.py` - Alembic migration: pg_cron extension + auto-close job + updated_at column
- `backend/src/features/webhook/router.py` - Replaced placeholder stub with real background module import + wa_client pass
- `backend/src/features/webhook/service.py` - Enhanced get_or_create_session and save_message to touch updated_at
- `backend/src/features/chat/models.py` - Added updated_at column to ChatSession model

## Decisions Made
- **Background task opens own session:** Uses `async_session()` context manager, not request-scoped session (CRITICAL-4 compliance).
- **AI service retry pattern:** httpx.AsyncClient with 50s read timeout + 5s connect timeout, two attempts max, then fallback message sent to student via WhatsApp.
- **Per-session lock as dict[str, asyncio.Lock]:** `setdefault` pattern for thread-safe lock creation keyed by `str(session_id)`.
- **updated_at touched in both get_or_create_session and save_message:** Ensures accurate inactivity tracking for pg_cron auto-close.
- **pg_cron migration is migration 011a:** Follows existing 010a (verification_state) in the migration chain.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None — all imports verified, module chain validated.

## User Setup Required

pg_cron requires a custom PostgreSQL Docker image with `pg_cron` installed and `shared_preload_libraries = 'pg_cron'` in postgresql.conf. This is a Phase 1 infrastructure responsibility. The Alembic migration 011a assumes that infrastructure is in place.

## Next Phase Readiness
- Background processing pipeline complete, ready for Plan 03 (chat visibility endpoints for staff)
- Webhook → AI → WhatsApp response flow is end-to-end wired
- Session lifecycle fully managed: manual close via keywords + pg_cron auto-close
- All webhook endpoints and background tasks importable and functional

---
*Phase: 06-whatsapp-webhook-integration*
*Completed: 2026-04-30*

## Self-Check: PASSED

All 5 modified/created files verified on disk. Both task commits (7de5464, a611d3f) verified in git log.
