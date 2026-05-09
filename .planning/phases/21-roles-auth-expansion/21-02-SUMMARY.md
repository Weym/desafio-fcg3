---
phase: 21-roles-auth-expansion
plan: 02
subsystem: staff-crud
tags: [fastapi, crud, provider, rbac, pydantic, pagination]

# Dependency graph
requires:
  - phase: 21-roles-auth-expansion
    plan: 01
    provides: "require_provider() dependency, Staff model with status/work_schedule/position columns"
provides:
  - "5 CRUD endpoints at /staff/members/* protected by require_provider()"
  - "StaffManagementService with list, get, create, update, soft_delete"
  - "StaffCreate/StaffUpdate/StaffDetail/StaffListItem Pydantic schemas"
  - "Provider hidden from staff list (WHERE role != 'provider')"
  - "Self-operation blocked (PUT/DELETE on own ID returns 403)"
  - "Email uniqueness enforced (409 on duplicate)"
  - "Role restricted to staff/coordinator/secretary on create/update (schema regex)"
affects: [21-03-flutter-navigation, 21-04-flutter-staff-management]

# Tech tracking
tech-stack:
  added: []
  patterns: ["Staff CRUD mirrors student CRUD pattern (BaseService, paginated_response, soft delete)"]

key-files:
  created: []
  modified:
    - "backend/src/features/staff/schemas.py"
    - "backend/src/features/staff/services.py"
    - "backend/src/features/staff/controllers.py"

key-decisions:
  - "Endpoints at /staff/members/* sub-path to avoid conflict with existing /staff/dashboard"
  - "Provider record filtered from list via WHERE role != 'provider' (D-17)"
  - "Self-operation check uses UUID equality (staff_id == current_user_id) — prevents lockout"
  - "Email uniqueness check reused for both create and update operations"

patterns-established:
  - "Provider-only endpoint pattern: require_provider(user) at handler start"
  - "Self-operation guard: compare resource ID with user.id before mutation"

requirements-completed: [ROLE-03, ROLE-07]

# Metrics
duration: 2min
completed: 2026-05-09
---

# Phase 21 Plan 02: Staff CRUD Endpoints Summary

**5 provider-only CRUD endpoints at /staff/members/* with self-operation blocking, email uniqueness, role restriction (never provider), and provider hidden from list results**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-09T03:33:06Z
- **Completed:** 2026-05-09T03:35:28Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- StaffCreate/StaffUpdate/StaffDetail/StaffListItem Pydantic schemas with proper validation
- StaffManagementService extending BaseService[Staff] with full CRUD + security guards
- 5 new endpoints on existing staff_router under /members/* sub-path
- All endpoints protected by require_provider() — returns 403 for non-provider
- Provider cannot edit or deactivate own record (D-21, T-21-08)
- Provider hidden from GET list results via WHERE role != 'provider' (D-17, T-21-09)
- Cannot create staff with role='provider' — schema regex blocks it (T-21-06)
- Email uniqueness enforced on create and update (T-21-10)
- Existing GET /staff/dashboard untouched and still works for staff + provider

## Task Commits

Each task was committed atomically:

1. **Task 1: Staff CRUD schemas** - `b149868` (feat)
2. **Task 2: Staff management service** - `5db9a55` (feat)
3. **Task 3: Staff CRUD controllers** - `64af69c` (feat)

## Files Created/Modified

- `backend/src/features/staff/schemas.py` — Added StaffCreate, StaffUpdate, StaffDetail, StaffListItem schemas
- `backend/src/features/staff/services.py` — Added StaffManagementService with 5 CRUD methods + singleton
- `backend/src/features/staff/controllers.py` — Added 5 endpoints: list, get, create, update, delete at /members/*

## Decisions Made

- Used `/staff/members/*` sub-path (not `/staff/*` root) to avoid collision with existing `/staff/dashboard`
- StaffManagementService as separate class from DashboardService — clean separation of concerns
- Soft delete sets status='inactive' (matches student pattern) — no physical deletion
- Self-operation guard uses simple UUID comparison — no extra DB query needed

## Deviations from Plan

None - plan executed exactly as written.

## Threat Mitigations Applied

| Threat ID | Mitigation |
| --- | --- |
| T-21-06 | StaffCreate.role regex `^(staff|coordinator|secretary)$` blocks provider creation |
| T-21-07 | StaffUpdate.role regex prevents escalation; self-edit blocked by ID check |
| T-21-08 | Explicit `staff_id == current_user_id` check on PUT and DELETE |
| T-21-09 | `Staff.role != 'provider'` filter on list query |
| T-21-10 | ConflictException on duplicate email in create and update |

## Self-Check: PASSED

All 3 files verified present. All 3 commit hashes verified in git log.

---
*Phase: 21-roles-auth-expansion*
*Completed: 2026-05-09*
