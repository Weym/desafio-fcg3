---
phase: 03-business-feature-slices
plan: 01
subsystem: api
tags: [fastapi, pagination, exceptions, dual-auth, idor, crud, pydantic]

# Dependency graph
requires:
  - phase: 02-authentication
    provides: "get_current_user JWT dependency, require_role, require_service_token, CurrentUser dataclass"
provides:
  - "PaginationParams dependency and paginated_response helper"
  - "AppException hierarchy with Portuguese error codes (D-03)"
  - "register_exception_handlers for AppException in main.py"
  - "ErrorResponse, PaginationMeta Pydantic response models"
  - "get_current_user_or_service dual-auth dependency (JWT + X-Service-Token)"
  - "UserContext unified identity dataclass"
  - "check_ownership IDOR protection (D-05, D-06)"
  - "require_staff role guard"
  - "BaseService[T] generic CRUD with paginated list, get_by_id, get_or_404, create, update"
affects: [03-02, 03-03, 03-04, 03-05, 03-06, 03-07, 03-08, 04-mcp-server]

# Tech tracking
tech-stack:
  added: []
  patterns: ["dual-auth dependency (JWT-first, service-token-fallback)", "BaseService[T] generic CRUD", "AppException hierarchy with Portuguese codes", "check_ownership defense-in-depth IDOR protection"]

key-files:
  created:
    - backend/src/shared/pagination.py
    - backend/src/shared/exceptions.py
    - backend/src/shared/responses.py
    - backend/src/shared/dependencies.py
    - backend/src/shared/base_service.py
  modified:
    - backend/src/shared/__init__.py
    - backend/src/main.py

key-decisions:
  - "Dual-auth tries JWT Bearer first, falls back to X-Service-Token with hmac.compare_digest (D-02)"
  - "MCP requests send X-Student-Id header to identify target student"
  - "Portuguese SCREAMING_SNAKE_CASE error codes with resource-specific not-found codes (D-03)"
  - "Staff bypasses ownership check; student and service roles both require resource.student_id == user.id (D-05, D-06)"
  - "BaseService validates sort_by against model columns to prevent SQL injection (T-03-03)"
  - "NotFoundException uses generic message to avoid leaking resource existence (T-03-04)"

patterns-established:
  - "PaginationParams: FastAPI dependency with page/per_page/sort_by/order defaults"
  - "paginated_response: {data: [...], pagination: {page, per_page, total}} envelope"
  - "AppException → JSONResponse via register_exception_handlers"
  - "get_current_user_or_service → UserContext for all dual-auth endpoints"
  - "check_ownership(resource_student_id, user) called in every endpoint touching student data"
  - "BaseService[T]: subclass with model type, inject AsyncSession per-request"

requirements-completed: [STU-01, ENROLL-07, DOCS-01, APPT-04]

# Metrics
duration: 9min
completed: 2026-04-24
---

# Phase 03 Plan 01: Shared Infrastructure Summary

**Pagination, dual-auth (JWT + X-Service-Token), Portuguese exceptions, IDOR ownership check, and generic BaseService[T] CRUD for all 7 feature slices**

## Performance

- **Duration:** 9 min
- **Started:** 2026-04-24T21:40:46Z
- **Completed:** 2026-04-24T21:50:00Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments
- PaginationParams dependency with defaults matching docs/api.md (page=1, per_page=20, sort_by=created_at, order=desc)
- Dual-auth dependency that unifies JWT and X-Service-Token into a single UserContext, with hmac.compare_digest for constant-time token comparison
- Complete AppException hierarchy with Portuguese error codes (ALUNO_NAO_ENCONTRADO, SEM_PERMISSAO, ERRO_VALIDACAO, etc.) and global exception handler registered in main.py
- IDOR protection via check_ownership with defense-in-depth (D-05: even service token requests are checked)
- BaseService[T] generic CRUD with SQL injection protection on sort_by column validation

## Task Commits

Each task was committed atomically:

1. **Task 1: Pagination, exception handling, and response schemas** - `42b40a9` (feat)
2. **Task 2: Dual-auth dependency and ownership checker** - `fe39a1e` (feat)
3. **Task 3: Base CRUD service class** - `2065fa6` (feat)

## Files Created/Modified
- `backend/src/shared/pagination.py` - PaginationParams dependency and paginated_response helper
- `backend/src/shared/exceptions.py` - AppException, NotFoundException, ConflictException, ForbiddenException, ValidationException, register_exception_handlers
- `backend/src/shared/responses.py` - ErrorDetail, ErrorBody, ErrorResponse, PaginationMeta Pydantic models
- `backend/src/shared/dependencies.py` - get_current_user_or_service dual-auth, check_ownership, require_staff, UserContext
- `backend/src/shared/base_service.py` - BaseService[T] generic CRUD with list/get_by_id/get_or_404/create/update
- `backend/src/shared/__init__.py` - Updated exports for all new shared modules
- `backend/src/main.py` - Registered AppException handler via register_exception_handlers(app)

## Decisions Made
- **D-02 implementation:** JWT validation reuses Phase 2's `get_current_user` via import; X-Service-Token path creates UserContext with role="service"
- **X-Student-Id header:** MCP server sends student UUID in X-Student-Id header alongside X-Service-Token for service auth path
- **D-03 codes:** Resource-specific 404 codes (ALUNO_NAO_ENCONTRADO, MATRICULA_NAO_ENCONTRADA, etc.) with fallback pattern for unknown resources
- **D-05/D-06:** check_ownership is a simple function (not dependency) — called explicitly in endpoints for maximum clarity
- **T-03-03:** BaseService._get_sort_column validates against SQLAlchemy mapper column_attrs; falls back to created_at then primary key

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- Local Python is 3.10 (project requires 3.12 in Docker) — imports verified via syntax checking with `ast.parse()` since SQLAlchemy and other deps aren't installable locally with `typing.Self` requirement

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- All 7 feature slices (plans 03-02 through 03-08) can now import from `src.shared` for pagination, exceptions, dual-auth, ownership checks, and base CRUD
- Feature slices should subclass BaseService[T] with their SQLAlchemy model and use get_current_user_or_service as the auth dependency
- Exception handlers are already registered in main.py — new AppException subclasses will automatically get the standard error envelope

## Self-Check: PASSED

- All 7 created/modified files verified present on disk
- All 3 task commits verified in git log (42b40a9, fe39a1e, 2065fa6)

---
*Phase: 03-business-feature-slices*
*Completed: 2026-04-24*
