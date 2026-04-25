---
phase: 03-business-feature-slices
plan: 09
subsystem: api
tags: [fastapi, students, regression, response-model, docs]

# Dependency graph
requires:
  - phase: 03-business-feature-slices/03-02
    provides: "Students feature slice with available-courses service and controller"
  - phase: 03-business-feature-slices/03-05
    provides: "Phase context for the remaining available-courses gap closure wave"
provides:
  - "Regression coverage for the available-courses raw-list response contract"
  - "Students available-courses controller aligned with response_model=list[AvailableCourseItem]"
  - "API documentation synchronized with the implemented raw-array response"
affects: ["04 (MCP server available-courses tool)", "UAT test 3", "docs/api.md"]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Controller regression tests may monkeypatch the service layer while preserving auth and route wiring"
    - "FastAPI handlers must return the exact top-level shape declared in response_model"

key-files:
  created:
    - "backend/tests/integration/test_students_available_courses.py"
  modified:
    - "backend/src/features/students/controllers.py"
    - "docs/api.md"

key-decisions:
  - "Kept the fix in the controller/docs layer because student_service.get_available_courses already returned the correct list[AvailableCourseItem] shape"
  - "Used an authenticated integration test with a monkeypatched service result to isolate the route contract bug without re-testing prerequisite filtering"

patterns-established:
  - "When a FastAPI response_model already expresses the intended public contract, fix serialization mismatches at the handler boundary instead of wrapping the payload"

requirements-completed: [STU-07]

# Metrics
duration: 8 min
completed: 2026-04-25
---

# Phase 03 Plan 09: Available Courses Contract Fix Summary

**Available-courses now returns the MCP-safe raw `AvailableCourseItem[]` response with matching regression coverage and synced API docs.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-04-25T03:11:49Z
- **Completed:** 2026-04-25T03:19:49Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Added a focused integration regression that authenticates through the real route and locks the response to HTTP 200 plus a top-level JSON list.
- Removed the `{"data": ...}` wrapper from `GET /students/{id}/available-courses` while preserving dual-auth and ownership checks.
- Updated `docs/api.md` so the documented response example matches the existing `response_model=list[AvailableCourseItem]` contract.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add a regression test for the raw-list contract** - `9f2a54a` (test)
2. **Task 2: Align controller and docs to the existing list response model** - `bede357` (fix)

## Files Created/Modified
- `backend/tests/integration/test_students_available_courses.py` - Authenticated regression test for the available-courses response shape.
- `backend/src/features/students/controllers.py` - Returns the service result directly as `list[AvailableCourseItem]`.
- `docs/api.md` - Documents the endpoint as a raw JSON array instead of a wrapped object.

## Decisions Made
- Kept `student_service.get_available_courses` unchanged because the bug was only in response serialization, not in prerequisite filtering.
- Used a monkeypatched service return in the integration test so the test proves controller contract correctness while still exercising auth, ownership checks, and route wiring.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- UAT Test 3 is covered by regression and no longer depends on a controller/docs mismatch.
- Phase 4 MCP work can rely on `GET /api/v1/students/{id}/available-courses` returning a raw list that matches its declared FastAPI contract.

## Self-Check: PASSED

- Summary file exists on disk
- Commit `9f2a54a` verified in git log
- Commit `bede357` verified in git log
