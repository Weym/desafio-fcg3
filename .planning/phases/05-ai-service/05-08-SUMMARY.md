---
phase: 05-ai-service
plan: 08
subsystem: infra
tags: [postgresql, credentials, psycopg, docker-compose, uuid]

# Dependency graph
requires:
  - phase: 01-infrastructure-schema
    provides: "reconcile_dev_credentials.sh that enforces POSTGRES_PASSWORD on every postgres startup"
  - phase: 05-ai-service
    provides: "ai_service package with config.py, database.py, and main.py"
provides:
  - "Consistent DATABASE_URL credentials matching POSTGRES_PASSWORD across all services"
  - "Drift-proof AI service config building DATABASE_URL from POSTGRES_* component vars"
  - "save_chat_message with gen_random_uuid() for chat_messages.id NOT NULL column"
affects: [06-whatsapp-webhook, ai-service, mcp-server]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "POSTGRES_* component vars for drift-proof DATABASE_URL construction"
    - "gen_random_uuid() for PostgreSQL-side UUID generation in raw SQL inserts"

key-files:
  created: []
  modified:
    - ".env"
    - "docker-compose.yml"
    - "ai_service/config.py"
    - "ai_service/database.py"

key-decisions:
  - "Removed explicit DATABASE_URL from langchain-service compose config; AI service builds URL from POSTGRES_* components at runtime"
  - "Used gen_random_uuid() (PostgreSQL server-side) instead of Python uuid.uuid4() for consistency with rest of stack"
  - "Duplicate MCP_SERVICE_TOKEN removed from .env (kept first real value, removed second placeholder)"

patterns-established:
  - "POSTGRES_* component vars: Services that need DB access receive POSTGRES_USER/PASSWORD/HOST/PORT/DB instead of a pre-built DATABASE_URL to prevent credential drift"

requirements-completed: [AI-01, AI-02, AI-05]

# Metrics
duration: 3min
completed: 2026-04-27
---

# Phase 05 Plan 08: Gap Closure Summary

**Aligned DATABASE_URL credentials with POSTGRES_PASSWORD and fixed chat_messages UUID generation to unblock all Phase 05 UAT tests**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-27T14:38:01Z
- **Completed:** 2026-04-27T14:41:55Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- All DATABASE_URL passwords in `.env` now match `POSTGRES_PASSWORD` (`change_me_in_production`), preventing auth failures after cold start
- langchain-service Docker config uses POSTGRES_* component vars, preventing future credential drift
- `ai_service/config.py` builds DATABASE_URL from POSTGRES_* components when no explicit URL is set (matching backend pattern)
- `save_chat_message()` generates UUID via `gen_random_uuid()`, fixing the NOT NULL violation on chat_messages.id

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix credential alignment and drift-proof DATABASE_URL construction** - `0cd4473` (fix)
2. **Task 2: Fix save_chat_message UUID generation for chat_messages.id** - `6e37e71` (fix)

## Files Created/Modified
- `.env` - Aligned all DATABASE_URL passwords with POSTGRES_PASSWORD; removed duplicate MCP_SERVICE_TOKEN (gitignored, not committed)
- `docker-compose.yml` - Replaced langchain-service DATABASE_URL with POSTGRES_* component vars
- `ai_service/config.py` - Added `__post_init__` for POSTGRES_* component-based URL construction with psycopg normalization
- `ai_service/database.py` - Added `id` column with `gen_random_uuid()` to save_chat_message INSERT

## Decisions Made
- Removed explicit `DATABASE_URL` from langchain-service compose config — AI service now builds the URL from POSTGRES_* components at runtime, same pattern used by backend `build_database_url()`
- Used PostgreSQL's `gen_random_uuid()` (cryptographically random UUIDv4) server-side instead of Python `uuid.uuid4()` for consistency with rest of stack
- `.env` changes are local-only (gitignored) — the committed code (docker-compose.yml, config.py) ensures correct URLs regardless of `.env` content

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- Alembic migrations and seed had not been run on the fresh database volume, which caused the verification script to fail initially with "relation students does not exist". Resolved by running `alembic upgrade head` and `scripts/seed.py` — not a code bug, just container lifecycle ordering.

## User Setup Required

None - no external service configuration required. The `.env` credential alignment is the only manual step, and it was applied during execution.

## Next Phase Readiness
- All Phase 05 UAT blockers (Tests 1, 2, 3) are now resolved
- langchain-service health endpoint returns `{"status":"healthy"}`
- Chat message persistence works end-to-end (save + load round-trip verified)
- Phase 06 (WhatsApp Webhook & Integration) is now unblocked

## Self-Check: PASSED

- [x] docker-compose.yml — FOUND
- [x] ai_service/config.py — FOUND
- [x] ai_service/database.py — FOUND
- [x] 05-08-SUMMARY.md — FOUND
- [x] Commit 0cd4473 — FOUND
- [x] Commit 6e37e71 — FOUND

---
*Phase: 05-ai-service*
*Completed: 2026-04-27*
