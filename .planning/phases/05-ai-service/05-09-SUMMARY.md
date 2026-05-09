---
phase: 05-ai-service
plan: 09
subsystem: ai
tags: [ingest, postgres, config, regression-test, docker-compose]

# Dependency graph
requires:
  - phase: 05-ai-service (plan 08)
    provides: POSTGRES_* component vars in docker-compose.yml and Settings.__post_init__ fallback in config.py
provides:
  - IngestSettings.from_env() derives DATABASE_URL from shared Settings singleton (single source of truth)
  - Regression test aligned with Plan 08's compose topology (POSTGRES_* component vars)
affects: [05-ai-service, 06-whatsapp-webhook]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Centralized DB URL construction: all ai_service consumers import from config.settings instead of reading os.environ directly"

key-files:
  created: []
  modified:
    - ai_service/ingest.py
    - ai_service/tests/test_runtime_entrypoint.py

key-decisions:
  - "IngestSettings delegates DATABASE_URL to the shared Settings singleton rather than duplicating POSTGRES_* fallback logic"

patterns-established:
  - "Single source of truth: ai_service.config.settings.DATABASE_URL is the canonical DB URL for all ai_service modules"

requirements-completed: [AI-05]

# Metrics
duration: 1min
completed: 2026-04-27
---

# Phase 05 Plan 09: Gap Closure Summary

**Fixed IngestSettings to derive DATABASE_URL from shared config.Settings and updated stale regression test to assert POSTGRES_* component vars**

## Performance

- **Duration:** 1 min
- **Started:** 2026-04-27T15:00:14Z
- **Completed:** 2026-04-27T15:01:28Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- IngestSettings.from_env() now imports ai_service.config.settings.DATABASE_URL instead of reading os.environ["DATABASE_URL"] directly, closing the gap left by Plan 08's removal of DATABASE_URL from docker-compose.yml
- Regression test test_compose_limits_ai_service_env_to_runtime_dependencies updated to assert POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_HOST, POSTGRES_PORT instead of stale DATABASE_URL assertion
- DATABASE_URL added to the negative assertion list (should NOT appear in langchain-service env)

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix ingest.py IngestSettings to use shared Settings DATABASE_URL** - `20315cc` (fix)
2. **Task 2: Fix stale regression test to assert POSTGRES_* component vars** - `eb35c8f` (fix)

## Files Created/Modified
- `ai_service/ingest.py` - IngestSettings.from_env() now imports from ai_service.config.settings instead of os.environ
- `ai_service/tests/test_runtime_entrypoint.py` - Replaced DATABASE_URL assertion with 5 POSTGRES_* component var assertions + negative DATABASE_URL assertion

## Decisions Made
- IngestSettings delegates DATABASE_URL to the shared Settings singleton rather than duplicating the POSTGRES_* fallback logic — keeps a single source of truth for URL construction

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- `test_import_preserves_health_and_chat_routes` fails due to missing `langchain_mcp_adapters` package in local dev environment — this is a pre-existing issue unrelated to Plan 09 changes (module only available inside Docker). All 4 other tests pass. Logged but not fixed (out of scope per deviation rules).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- AI-05 (knowledge base ingest in Docker) is unblocked — `python -m ai_service.ingest` will no longer raise RuntimeError about missing DATABASE_URL
- Phase 05 regression test suite is green for compose-related tests (4/4 pass; 1 pre-existing import failure unrelated to this plan)
- Phase 06 can proceed with WhatsApp webhook integration

## Self-Check: PASSED

All files exist and all commits verified.

---
*Phase: 05-ai-service*
*Completed: 2026-04-27*
