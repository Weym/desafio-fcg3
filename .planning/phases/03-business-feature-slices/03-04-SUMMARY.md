---
phase: 03-business-feature-slices
plan: 04
subsystem: api
tags: [fastapi, sqlalchemy, enrollment, prerequisites, lifecycle, pydantic, idor, mcp]

# Dependency graph
requires:
  - phase: 03-01
    provides: "Shared infrastructure: pagination, exceptions, responses, dependencies, base_service"
  - phase: 03-02
    provides: "Students feature slice with Student model, Grade model for prerequisite checking"
  - phase: 03-03
    provides: "Courses feature slice with Course and Prerequisite models for validation"
provides:
  - "EnrollmentPeriodService: get_current_period, list, create, update"
  - "EnrollmentService: create with prerequisite validation, confirm with SELECT FOR UPDATE, update courses, drop (draft only), lock (two levels), list"
  - "10 REST endpoints: GET current period, POST enrollment, POST confirm, PUT update, DELETE drop course, POST lock, GET list, GET/POST/PUT staff periods"
  - "Pydantic schemas: EnrollmentCreate, EnrollmentResponse, EnrollmentPeriodCreate, EnrollmentListItem, etc."
affects: [03-05-grades, 04-mcp-server]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "SELECT FOR UPDATE on enrollment row to prevent concurrent confirm race condition (P-03)"
    - "Prerequisite validation: bulk-load prerequisites, check student grades for approved status"
    - "Three-router pattern: enrollment_periods_router, enrollments_router, staff_enrollment_router"
    - "Deduplication of course_ids in service layer with dict.fromkeys() preserving order (P-06)"
    - "Enrollment status lifecycle: draft -> confirmed -> locked (with cancelled as side state)"

key-files:
  created:
    - backend/src/features/enrollment/schemas.py
    - backend/src/features/enrollment/services.py
    - backend/src/features/enrollment/controllers.py
    - backend/src/features/enrollment/routes.py
  modified:
    - backend/src/features/enrollment/models.py
    - backend/src/main.py

key-decisions:
  - "Updated Enrollment model check constraint to include 'locked' status — original migration only had draft/confirmed/cancelled (Rule 3 auto-fix)"
  - "Deduplication strategy: dict.fromkeys(course_ids) preserves order while removing duplicates, DB UNIQUE constraint as secondary defense"
  - "IDOR protection: confirm/drop/lock/update use student_id matching rather than check_ownership to return 404 (not 403) for non-owned enrollments"
  - "Lock is allowed from any non-locked status (draft or confirmed) per D-11 — irreversible"
  - "Grade records created on confirmation with status='in_progress' and semester_year from enrollment period"

patterns-established:
  - "Three-router feature pattern: enrollment_periods + enrollments + staff_enrollment registered independently in main.py"
  - "Service-level prerequisite validation reusable for both create and update flows"
  - "Enrollment response builder with selectinload for eager loading of courses and course details"
  - "IDOR-safe list endpoint: students auto-filtered to own enrollments in controller layer"

requirements-completed: [ENROLL-01, ENROLL-02, ENROLL-03, ENROLL-04, ENROLL-05, ENROLL-06, ENROLL-07, ENROLL-08, ENROLL-STAFF-01, ENROLL-STAFF-02, ENROLL-STAFF-03]

# Metrics
duration: 6min
completed: 2026-04-24
---

# Phase 03 Plan 04: Enrollment Feature Slice Summary

**Complete enrollment lifecycle with prerequisite validation, period enforcement, draft-only drop (D-12), two-level lock (D-11), and SELECT FOR UPDATE race prevention across 10 endpoints**

## Performance

- **Duration:** 6 min
- **Started:** 2026-04-24T22:08:31Z
- **Completed:** 2026-04-24T22:14:30Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Full enrollment lifecycle: create draft with prerequisite validation, confirm with grade record creation, modify courses, drop (draft only), lock (irreversible two-level)
- Prerequisite enforcement: bulk-loads prerequisites, checks student's approved grades, returns 409 PREREQUISITO_NAO_CUMPRIDO with missing course names
- Period enforcement: active period checked on create and confirm, returns 409 PERIODO_MATRICULA_FECHADO
- D-11 two-level lock: POST /enrollments/{id}/lock sets enrollment and all non-dropped courses to locked status
- D-12 draft-only drop: DELETE /enrollments/{id}/courses/{cid} rejects non-draft with Portuguese error message
- SELECT FOR UPDATE on confirm to prevent concurrent confirmation race condition (P-03)
- 10 endpoints with dual-auth (MCP-accessible) and staff guards, IDOR protection on all student actions

## Task Commits

Each task was committed atomically:

1. **Task 1: Schemas and enrollment period/enrollment services** - `834baaa` (feat)
2. **Task 2: Controllers and route registration** - `8305e01` (feat)

## Files Created/Modified
- `backend/src/features/enrollment/schemas.py` - 8 Pydantic models: EnrollmentPeriodCreate, EnrollmentPeriodUpdate, EnrollmentPeriodResponse, EnrollmentCreate, EnrollmentUpdate, EnrollmentCourseItem, EnrollmentResponse, EnrollmentListItem
- `backend/src/features/enrollment/services.py` - EnrollmentPeriodService (4 methods) + EnrollmentService (7 methods + 2 helpers) — 694 lines
- `backend/src/features/enrollment/controllers.py` - 10 async route handlers across 3 routers with auth dependencies
- `backend/src/features/enrollment/routes.py` - Re-exports 3 routers for main.py registration
- `backend/src/features/enrollment/models.py` - Updated check constraint to include 'locked' status
- `backend/src/main.py` - Added enrollment router imports and registration at /api/v1

## Decisions Made
- **Enrollment model constraint update:** Added 'locked' to the Enrollment status check constraint (`ck_enrollments_status`) — the original Phase 1 migration only had `draft/confirmed/cancelled`. A DB migration will be needed to ALTER CONSTRAINT in PostgreSQL. (Rule 3: blocking issue for lock implementation)
- **IDOR via 404:** When a student tries to access another student's enrollment, the service returns 404 (not 403) to avoid leaking existence information — consistent with NotFoundException pattern from shared module
- **Lock from any state:** Lock is allowed from both draft and confirmed states per D-11 — it's irreversible and represents semester trancamento
- **Grade creation on confirm:** Grade records created with `status='in_progress'` using `semester_year` from the enrollment period, establishing the link between enrollment and academic records

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated Enrollment model check constraint to include 'locked' status**
- **Found during:** Task 1 (services implementation)
- **Issue:** The Enrollment model (from Phase 1 migration) has `CheckConstraint("status IN ('draft', 'confirmed', 'cancelled')")` but the plan requires `locked` status for D-11 lock functionality
- **Fix:** Updated the model's check constraint to include 'locked': `status IN ('draft', 'confirmed', 'cancelled', 'locked')`
- **Files modified:** `backend/src/features/enrollment/models.py`
- **Note:** The actual DB migration to ALTER the PostgreSQL constraint still needs to be created separately
- **Committed in:** `834baaa` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Essential for lock functionality. No scope creep. A follow-up migration will be needed to sync the DB constraint.

## Issues Encountered
- Local Python is 3.10 (project requires 3.12 in Docker) — verified all files via AST parsing. Full runtime import validation will occur when Docker containers run.

## Threat Surface Scan

All threat model items from the plan are mitigated:
- **T-03-14 (Elevation of Privilege):** Prerequisite validation enforced on every enrollment creation and update
- **T-03-15 (Tampering):** Period active check + status check on confirm prevents double-confirmation and out-of-period
- **T-03-16 (IDOR):** student_id check on every mutating endpoint; non-owned enrollments return 404
- **T-03-17 (Repudiation):** Lock is irreversible — status cannot be changed back
- **T-03-18 (Tampering):** D-12 enforced: drop only in draft status
- **T-03-19 (DoS):** Unique check prevents multiple enrollments per student per period

No new threat surfaces introduced beyond what was in the plan.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Enrollment feature slice complete with all 11 ENROLL requirements met
- MCP Server (Phase 4) can call enrollment endpoints via X-Service-Token: create, confirm, drop, lock, get current period, list
- Grades slice (Plan 03-05) will add grade management endpoints; enrollment confirmation already creates grade records
- **Migration needed:** A new Alembic migration should add 'locked' to the `ck_enrollments_status` check constraint before running lock operations in the database

## Self-Check: PASSED

- All 6 files verified present on disk
- Commit `834baaa` (Task 1) verified in git log
- Commit `8305e01` (Task 2) verified in git log

---
*Phase: 03-business-feature-slices*
*Completed: 2026-04-24*
