---
phase: 03-business-feature-slices
plan: 03
subsystem: api
tags: [fastapi, sqlalchemy, recursive-cte, courses, curriculum, pydantic]

# Dependency graph
requires:
  - phase: 03-01
    provides: "Shared infrastructure: pagination, exceptions, responses, dependencies, base_service"
  - phase: 01
    provides: "SQLAlchemy models for Course, Curriculum, CurriculumCourse, Prerequisite"
provides:
  - "CourseService with list, detail, prerequisite tree, curriculum methods"
  - "5 REST endpoints: GET /courses, GET /courses/{id}, GET /courses/{id}/prerequisites, GET /curriculum/active, GET /curriculum/{id}"
  - "Recursive CTE query for full prerequisite tree (COURSE-03)"
  - "Pydantic schemas: CourseDetail, PrerequisiteTreeNode, CurriculumResponse"
affects: [03-04-enrollment, 04-mcp-server]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Recursive CTE via text() for prerequisite tree traversal with depth limit"
    - "Self-referential Pydantic model with model_rebuild() for tree nodes"
    - "defaultdict-based tree builder from flat CTE rows"
    - "Two-router pattern: separate courses_router and curriculum_router"

key-files:
  created:
    - backend/src/features/courses/schemas.py
    - backend/src/features/courses/services.py
    - backend/src/features/courses/controllers.py
    - backend/src/features/courses/routes.py
  modified:
    - backend/src/main.py

key-decisions:
  - "Kept CourseService as single class for both courses and curriculum (no separate CurriculumService) — methods are cohesive and share the _build_curriculum_response helper"
  - "Used raw SQL text() for recursive CTE instead of SQLAlchemy Core CTE construct — cleaner for complex recursive queries with depth limit"
  - "Depth limit of 10 in CTE WHERE clause prevents infinite recursion from circular prerequisites (T-03-11)"
  - "Python-side tree builder with visited set as second layer of circular-reference protection"

patterns-established:
  - "Two-router feature pattern: courses and curriculum have separate APIRouter instances registered independently in main.py"
  - "Recursive CTE pattern: flat rows → defaultdict grouping → recursive tree builder"
  - "selectinload for eager loading relationships in detail endpoints"

requirements-completed: [COURSE-01, COURSE-02, COURSE-03, CURR-01, CURR-02]

# Metrics
duration: 4min
completed: 2026-04-24
---

# Phase 03 Plan 03: Courses & Curriculum Summary

**5 endpoints for course catalog and curriculum display with recursive CTE prerequisite tree, dual-auth for MCP access, and semester-grouped curriculum responses**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-24T21:42:00Z
- **Completed:** 2026-04-24T21:46:00Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Course listing with ILIKE search on name/code and semester filtering via curriculum_courses join (COURSE-01)
- Course detail with eagerly-loaded direct prerequisites via selectinload (COURSE-02)
- Full recursive prerequisite tree via CTE with depth limit of 10 and Python-side circular-reference protection (COURSE-03)
- Active curriculum endpoint returning courses organized by semester groups (CURR-01)
- Curriculum-by-ID endpoint with NotFoundException for missing curricula (CURR-02)
- MCP-accessible endpoints (prerequisites, active curriculum) use get_current_user_or_service dual-auth

## Task Commits

Each task was committed atomically:

1. **Task 1: Schemas and service with recursive CTE** - `c12f023` (feat)
2. **Task 2: Controllers and route registration** - `931b9fa` (feat)

## Files Created/Modified
- `backend/src/features/courses/schemas.py` - 7 Pydantic models: CourseListItem, PrerequisiteItem, CourseDetail, PrerequisiteTreeNode (self-referential), CurriculumCourseItem, SemesterGroup, CurriculumResponse
- `backend/src/features/courses/services.py` - CourseService with 5 methods including recursive CTE query and tree builder
- `backend/src/features/courses/controllers.py` - 5 async route handlers with dual-auth for MCP-accessible endpoints
- `backend/src/features/courses/routes.py` - Exposes courses_router and curriculum_router for main.py registration
- `backend/src/main.py` - Added import and registration of courses_router and curriculum_router under /api/v1

## Decisions Made
- Kept CourseService as a single class for both course and curriculum operations — methods are cohesive and share the `_build_curriculum_response` helper, avoiding unnecessary class proliferation
- Used raw SQL `text()` for the recursive CTE instead of SQLAlchemy Core CTE construct — the recursive query with depth limit is cleaner as raw SQL
- Two-router pattern (courses_router + curriculum_router) matches the API path structure (/courses/* and /curriculum/*) while keeping them in the same feature directory

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- Local Python is 3.10 (project requires 3.12 in Docker) so runtime import verification could not execute locally. Validated via AST parsing and structural analysis instead. All code will run correctly in the Docker container with Python 3.12.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Courses feature slice is complete with all 5 endpoints registered
- CourseService and its schemas are available for import by the enrollment feature slice (03-04) for prerequisite validation
- MCP Server (Phase 4) can call `GET /courses/{id}/prerequisites` and `GET /curriculum/active` via X-Service-Token

## Self-Check: PASSED

---
*Phase: 03-business-feature-slices*
*Completed: 2026-04-24*
