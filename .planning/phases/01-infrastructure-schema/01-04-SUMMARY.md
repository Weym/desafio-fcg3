---
phase: 01-infrastructure-schema
plan: 04
subsystem: database
tags: [seed, postgres, sqlalchemy, docker, curriculum]
requires:
  - phase: 01-infrastructure-schema
    provides: Dockerized backend runtime and migrated schema from plans 01-01 and 01-02
provides:
  - Destructive development seed script for the USP ICMC curriculum and sample academic data
  - Repeatable student, staff, enrollment history, and scheduling fixtures for downstream feature testing
affects: [authentication, enrollment, grades, scheduling, mcp-server, ai-service]
tech-stack:
  added: [Python seed module]
  patterns: [destructive dev reseed, runtime integrity guards, in-container script execution]
key-files:
  created:
    - backend/scripts/__init__.py
    - backend/scripts/seed.py
  modified:
    - backend/Dockerfile
    - docker-compose.yml
key-decisions:
  - "Seeded historical enrollment periods and enrollment records so grade fixtures satisfy the schema's non-null enrollment_course_id constraint."
  - "Mounted backend scripts and Alembic assets into fastapi-app so verification can run exactly as the plan specifies inside Docker."
patterns-established:
  - "Seed scripts live under backend/scripts and run via python -m scripts.<name>."
  - "Development seed data fails fast when curriculum coverage or prerequisite acyclicity drifts."
requirements-completed: [INFRA-04]
duration: 3 min
completed: 2026-04-24
---

# Phase 01 Plan 04: Seed script Summary

**A destructive Docker-runnable seed now loads a 40-course USP ICMC curriculum, prerequisite chains, historical enrollment data, five sample students, two staff members, and scheduling fixtures for downstream backend testing.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-24T11:05:08Z
- **Completed:** 2026-04-24T11:07:43Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Added `backend/scripts/seed.py` with destructive reseeding for curriculum, students, staff, enrollment history, and scheduling data.
- Seeded realistic academic histories with approved, failed, and in-progress grades while honoring the existing relational constraints.
- Verified the seed twice inside Docker and confirmed stable counts for courses, semesters, students, staff, prerequisite chains, active enrollment period, and scheduling fixtures.

## Task Commits

Each task was committed atomically:

1. **Task 1: Create destructive seed script with USP ICMC curriculum** - `3949e84` (feat)
2. **Task 2: Verify seed idempotency and data integrity** - `6ad0138` (fix)

**Plan metadata:** pending

## Files Created/Modified
- `backend/scripts/__init__.py` - Package marker so the seed runs via `python -m scripts.seed`.
- `backend/scripts/seed.py` - Async destructive seed with curriculum, users, enrollment history, scheduling data, and integrity guards.
- `backend/Dockerfile` - Copies `scripts/`, `alembic/`, and `alembic.ini` into the backend container for in-container verification.
- `docker-compose.yml` - Mounts `backend/scripts` into `fastapi-app` so local script edits are runnable without rebuilding unrelated services.

## Decisions Made
- Seeded historical `enrollment_periods`, `enrollments`, and `enrollment_courses` instead of orphan grade rows because the current schema requires `grades.enrollment_course_id`.
- Added runtime validation for the expected 40-course / 8-semester shape and acyclic prerequisites so future curriculum edits fail loudly instead of silently corrupting fixtures.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Exposed scripts and Alembic files inside fastapi-app**
- **Found during:** Task 1 (Create destructive seed script with USP ICMC curriculum)
- **Issue:** `docker compose exec fastapi-app python -m scripts.seed` could not work because the backend image only copied `src/`, and Alembic artifacts were also unavailable for container-backed verification.
- **Fix:** Copied `scripts/`, `alembic/`, and `alembic.ini` into the backend image and mounted `backend/scripts` in Compose.
- **Files modified:** `backend/Dockerfile`, `docker-compose.yml`
- **Verification:** `docker compose exec fastapi-app alembic upgrade head` and `docker compose exec fastapi-app python -m scripts.seed` both ran successfully after the fix.
- **Committed in:** `3949e84`

**2. [Rule 2 - Missing Critical] Added seed-time integrity guards**
- **Found during:** Task 2 (Verify seed idempotency and data integrity)
- **Issue:** The script relied on manual review to catch curriculum drift or accidental prerequisite cycles.
- **Fix:** Added startup validation that enforces exactly 40 courses, semester coverage 1-8, and an acyclic prerequisite graph before any writes occur.
- **Files modified:** `backend/scripts/seed.py`
- **Verification:** `python -m py_compile backend/scripts/seed.py` and `docker compose exec fastapi-app python -m scripts.seed` both passed after the guard was added.
- **Committed in:** `6ad0138`

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 missing critical)
**Impact on plan:** Both fixes were required to make the seed runnable and trustworthy in the real Docker verification path. No unrelated scope was added.

## Issues Encountered
- The local PostgreSQL volume had been initialized with a different database/user than the current `.env`, so the planned `fcg3` role and database were missing. I recreated the expected local role/database and reran migrations before running the seed.
- The first backend container rebuild hit the same transient Docker EOF seen in Plan 01-01; an immediate retry succeeded without additional repo changes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 2 and Phase 3 can now rely on realistic curriculum, transcript, prerequisite, and scheduling fixtures from a single reseed command.
- Local verification path is established: `docker compose exec fastapi-app python -m scripts.seed` after `alembic upgrade head` produces a clean dev dataset repeatedly.

## Self-Check: PASSED
- Verified `.planning/phases/01-infrastructure-schema/01-04-SUMMARY.md` exists on disk.
- Verified task commits `3949e84` and `6ad0138` exist in git history.

---
*Phase: 01-infrastructure-schema*
*Completed: 2026-04-24*
