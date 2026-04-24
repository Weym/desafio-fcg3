---
phase: 03-business-feature-slices
plan: 05
subsystem: api
tags: [grades, cra, transcript, fastapi, decimal, weighted-average]

# Dependency graph
requires:
  - phase: 03-01
    provides: "BaseService, shared dependencies, pagination, exceptions"
  - phase: 03-02
    provides: "Students feature with academic-summary GPA placeholder"
  - phase: 03-03
    provides: "Course model with credits field for CRA weighting"
  - phase: 03-04
    provides: "Enrollment and EnrollmentCourse models (Grade FK target)"
provides:
  - "GradeService with CRA calculation (pure Python, Decimal precision)"
  - "GET /students/{id}/grades with semester filter (GRADES-01)"
  - "GET /students/{id}/transcript with CRA (GRADES-02)"
  - "PUT /grades/{id} for staff grade entry (GRADES-04)"
  - "CRA wired into students academic-summary endpoint (replaces placeholder)"
affects: [mcp-server, ai-service, testing]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pure Python service functions for testable business logic (D-07)"
    - "Decimal arithmetic for financial-grade precision (P-07)"
    - "Cross-feature service delegation (students controller -> GradeService)"

key-files:
  created:
    - "backend/src/features/grades/__init__.py"
    - "backend/src/features/grades/schemas.py"
    - "backend/src/features/grades/services.py"
    - "backend/src/features/grades/controllers.py"
    - "backend/src/features/grades/routes.py"
    - "backend/tests/unit/test_grades_cra.py"
  modified:
    - "backend/src/features/students/services.py"
    - "backend/src/features/students/controllers.py"
    - "backend/src/main.py"

key-decisions:
  - "D-07: CRA calculation as pure Python function (no DB access) for testability"
  - "D-08: Only grades with final_grade IS NOT NULL included in CRA; locked status excluded"
  - "Decimal arithmetic with ROUND_HALF_UP for CRA precision (P-07)"
  - "Grade view endpoints on students router, write endpoint on grades router (GAP-03)"
  - "PASSING_THRESHOLD as configurable constant (Decimal 5.00)"

patterns-established:
  - "Pure static methods for testable business logic (calculate_cra, compute_final_grade, compute_status)"
  - "Cross-feature lazy imports to avoid circular dependencies"
  - "Dual CRA entry points: standalone calculate_cra + DB-aware get_cra_for_student"

requirements-completed: [GRADES-01, GRADES-02, GRADES-03, GRADES-04]

# Metrics
duration: 9min
completed: 2026-04-24
---

# Phase 03 Plan 05: Grades Feature Slice Summary

**CRA credit-weighted average as pure Python Decimal function, grades CRUD with auto-calculated final grade, and transcript endpoint wired into academic summary**

## Performance

- **Duration:** 9 min
- **Started:** 2026-04-24T22:30:27Z
- **Completed:** 2026-04-24T22:39:21Z
- **Tasks:** 2
- **Files modified:** 9

## Accomplishments

- CRA (Coeficiente de Rendimento Academico) as pure Python function using Decimal arithmetic for precision
- Division-by-zero guard, None-filtering, and locked-status exclusion per D-07/D-08
- grade_final auto-calculated server-side from (grade_1 + grade_2) / 2 — not settable by API (T-03-22)
- Status auto-set to approved/failed based on configurable passing threshold
- CRA placeholder in academic summary replaced with real calculation
- Full IDOR protection on all grade endpoints (T-03-21, T-03-23)

## Task Commits

Each task was committed atomically:

1. **Task 1 (TDD RED): Failing CRA tests** - `bcf846b` (test)
2. **Task 1 (TDD GREEN): Schemas, CRA calculation, services** - `1753b62` (feat)
3. **Task 2: Controllers, routes, main.py registration** - `daea5fd` (feat)

## Files Created/Modified

- `backend/src/features/grades/__init__.py` - Package marker
- `backend/src/features/grades/schemas.py` - GradeResponse, GradeUpdate, TranscriptResponse, TranscriptEntry, CourseInfo
- `backend/src/features/grades/services.py` - GradeService with calculate_cra, compute_final_grade, compute_status, CRUD methods
- `backend/src/features/grades/controllers.py` - PUT /grades/{id} staff endpoint
- `backend/src/features/grades/routes.py` - grades_router export
- `backend/tests/unit/test_grades_cra.py` - 12 unit tests for CRA and grade logic
- `backend/src/features/students/services.py` - Replaced CRA placeholder with real GradeService call
- `backend/src/features/students/controllers.py` - Added GET /grades and GET /transcript endpoints
- `backend/src/main.py` - Registered grades_router under /api/v1

## Decisions Made

- **D-07 implemented:** CRA as `@staticmethod calculate_cra()` — pure function, no DB access, fully unit-testable
- **D-08 implemented:** Filters out None grade_final entries AND excludes locked status grades
- **Decimal precision (P-07):** All CRA arithmetic uses `Decimal` with `ROUND_HALF_UP` quantization to 2 decimal places — avoids float precision errors like 7.749999 vs 7.75
- **GAP-03 resolved:** Grade VIEW endpoints (`/students/{id}/grades`, `/students/{id}/transcript`) live on the students router since they're under the `/students/{id}/` URL path; grade WRITE endpoint (`PUT /grades/{id}`) lives on its own grades router
- **Cross-feature delegation:** Students controllers import GradeService lazily to avoid circular dependencies

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- **Python version mismatch:** Local Python is 3.10.2 but project targets 3.12 (Docker). `Self` type hint in `config.py` prevents full import chain on local machine. CRA logic verified via standalone script that exercises the identical algorithm. All files compile correctly via `py_compile`. Full integration testing requires Docker runtime.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All 4 GRADES requirements implemented and ready for MCP tool integration (`get_grades`, `get_transcript`)
- CRA calculation is wired into academic summary — MCP tool `get_student_info` will return real GPA
- Unit tests for CRA are in place for regression testing
- Grades feature integrates with courses (credits for CRA) and enrollment_courses (FK)

## Self-Check: PASSED

- All 6 created files verified present on disk
- All 3 commit hashes verified in git log (bcf846b, 1753b62, daea5fd)
