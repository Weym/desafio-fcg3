---
phase: 03-business-feature-slices
plan: 10
subsystem: database
tags: [alembic, postgresql, enrollment, fastapi, runtime-verification]

# Dependency graph
requires:
  - phase: 03-04
    provides: "Enrollment lifecycle service code with confirm_enrollment, lock_enrollment, and draft-only drop enforcement"
provides:
  - "Alembic migration 009a that updates ck_enrollments_status to accept locked"
  - "PostgreSQL-backed verification script for confirm -> lock persistence and post-lock drop rejection"
affects: [03-uat, 04-mcp-server, enrollment-lock-flow]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Constraint-only Alembic repair for schema drift between ORM and migrated PostgreSQL"
    - "Runtime verification script using real async_session service calls plus post-commit database re-read"

key-files:
  created:
    - backend/alembic/versions/009_add_locked_status_to_enrollments.py
    - backend/scripts/verify_enrollment_lock_gap.py
  modified: []

key-decisions:
  - "Fix UAT Test 6 in the database layer by recreating ck_enrollments_status with locked instead of changing already-correct enrollment service logic"
  - "Verify the gap with real confirm_enrollment and lock_enrollment calls, then re-query PostgreSQL directly to prove the locked state persisted"

patterns-established:
  - "When ORM constraints drift from migrated PostgreSQL constraints, close the gap with the smallest explicit Alembic migration"
  - "Gap-closure verification scripts should seed only the minimum runtime entities and assert persisted state after commit"

requirements-completed: [ENROLL-06]

# Metrics
duration: 4 min
completed: 2026-04-25
---

# Phase 03 Plan 10: Enrollment Lock Gap Closure Summary

**Alembic constraint repair plus PostgreSQL runtime proof for confirm -> lock enrollment persistence and post-lock draft-only enforcement**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-25T03:10:57Z
- **Completed:** 2026-04-25T03:14:49Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Added migration `009a` to sync `ck_enrollments_status` with the shipped `draft/confirmed/cancelled/locked` lifecycle.
- Proved against real PostgreSQL that `confirm_enrollment()` and `lock_enrollment()` now succeed and persist `status='locked'`.
- Verified that `drop_course()` still rejects post-lock mutation with the existing draft-only conflict behavior from D-12.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the missing Alembic constraint migration for locked enrollments** - `e591719` (fix)
2. **Task 2: Add a PostgreSQL-backed verification script for confirm -> lock persistence** - `c4d5dd1` (fix)

## Files Created/Modified
- `backend/alembic/versions/009_add_locked_status_to_enrollments.py` - Drops and recreates `ck_enrollments_status` so migrated PostgreSQL databases accept `locked`.
- `backend/scripts/verify_enrollment_lock_gap.py` - Seeds a minimal runtime enrollment flow, exercises the real service methods, re-reads PostgreSQL state, and asserts post-lock drop rejection.

## Decisions Made
- Applied the smallest correct repair at the schema layer because the enrollment service and ORM were already aligned with D-11.
- Kept verification narrowly focused on UAT Test 6 by using a purpose-built script instead of expanding the generic seed or pytest harness.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Imported related ORM models in the runtime verifier**
- **Found during:** Task 2 (PostgreSQL-backed verification script)
- **Issue:** Running the script initially failed during mapper setup because `Student` relationships referenced models like `Document` that were not imported into the runtime metadata.
- **Fix:** Imported the related feature model modules in the script before opening the async session, matching the existing project runtime/test pattern.
- **Files modified:** `backend/scripts/verify_enrollment_lock_gap.py`
- **Verification:** `docker compose exec -T fastapi-app sh -lc "cd /app && alembic upgrade head && python -m scripts.verify_enrollment_lock_gap"`
- **Committed in:** `c4d5dd1`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The auto-fix was required to let the runtime verifier load the full ORM graph. No scope creep.

## Issues Encountered
- Local `alembic check` could not resolve Docker hostname `postgres`, so verification was executed inside `fastapi-app` where the runtime DSN is valid.
- The running `fastapi-app` container does not mount `backend/alembic/`, so the new migration had to be copied into the container before `alembic upgrade head` could apply it during verification.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- UAT Test 6's root cause is closed by migration `009a` and backed by runtime PostgreSQL evidence.
- The enrollment lock flow is ready for targeted UAT re-verification.
- Phase 03 still has another incomplete gap-closure plan (`03-09`), so the phase is not fully closed yet.

## Self-Check: PASSED

- Found `.planning/phases/03-business-feature-slices/03-10-SUMMARY.md` on disk.
- Verified task commits `e591719` and `c4d5dd1` in git history.

---
*Phase: 03-business-feature-slices*
*Completed: 2026-04-25*
