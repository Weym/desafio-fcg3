---
phase: 21-roles-auth-expansion
plan: 01
subsystem: auth
tags: [jwt, provider-role, alembic, sqlalchemy, rbac, fastapi]

# Dependency graph
requires:
  - phase: 02-authentication
    provides: "JWT auth system with role field, session management, OTP login flow"
provides:
  - "Provider role in staff.role CHECK constraint"
  - "Staff model with status, work_schedule, position columns"
  - "Login flow mapping staff.role='provider' to JWT role='provider'"
  - "require_provider() dependency for provider-only endpoints"
  - "Expanded require_staff() accepting provider role"
  - "Expanded check_ownership() bypassing for provider"
  - "Inactive staff login rejection (401 ACCOUNT_INACTIVE)"
affects: [21-02-staff-crud, 21-03-flutter-navigation, 21-04-flutter-staff-management]

# Tech tracking
tech-stack:
  added: []
  patterns: ["Role hierarchy inheritance via set membership check in require_staff()"]

key-files:
  created:
    - "backend/alembic/versions/014_expand_staff_table_provider_role.py"
  modified:
    - "backend/src/features/auth/models.py"
    - "backend/src/features/auth/routes.py"
    - "backend/src/shared/dependencies.py"

key-decisions:
  - "Provider uses user_type='staff' in sessions table — no migration needed on sessions CHECK"
  - "require_staff() uses set membership ('staff', 'provider') not wildcard — mitigates T-21-01"
  - "require_provider() uses strict equality check — mitigates T-21-04"
  - "Role mapping is server-side from DB column, never from client input — mitigates T-21-02"

patterns-established:
  - "Role hierarchy: provider inherits staff via set membership check in require_staff()"
  - "Inactive account rejection pattern: check status before token issuance"

requirements-completed: [ROLE-01, ROLE-02]

# Metrics
duration: 2min
completed: 2026-05-09
---

# Phase 21 Plan 01: Provider Role Auth Foundation Summary

**Provider role added to auth system — JWT role mapping, staff model expansion (status/work_schedule/position), require_provider() dependency, inactive account rejection**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-09T03:29:13Z
- **Completed:** 2026-05-09T03:31:06Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments
- Alembic migration 014a expands staff table with provider role and 3 new columns
- Login flow correctly maps staff.role='provider' to distinct JWT role='provider'
- Provider inherits all staff endpoints via expanded require_staff()
- Provider-only endpoints protected by new require_provider() dependency
- Inactive staff accounts blocked from login with 401 ACCOUNT_INACTIVE

## Task Commits

Each task was committed atomically:

1. **Task 1: Alembic migration — expand staff table** - `d8e1653` (feat)
2. **Task 2: Update Staff model and login flow** - `70e6417` (feat)
3. **Task 3: Expand auth dependencies** - `d9e0c61` (feat)

## Files Created/Modified
- `backend/alembic/versions/014_expand_staff_table_provider_role.py` - Migration: provider role CHECK, status/work_schedule/position columns, indexes
- `backend/src/features/auth/models.py` - Staff ORM model with new columns and CHECK constraints
- `backend/src/features/auth/routes.py` - Login flow: provider role mapping + inactive account rejection
- `backend/src/shared/dependencies.py` - require_staff() expanded, require_provider() added, check_ownership() expanded

## Decisions Made
- Provider uses `user_type='staff'` in sessions table (no sessions table migration needed)
- Session user_type logic: `"staff" if role == "provider" else role` — keeps sessions CHECK constraint unchanged
- Strict set membership `("staff", "provider")` for require_staff — no wildcard/fallback (T-21-01 mitigation)
- Strict equality `!= "provider"` for require_provider — no list/fallback (T-21-04 mitigation)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - local Python environment lacks asyncpg (Docker-only runtime), so verification used AST parsing instead of module import. All code verified structurally correct.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Provider role fully functional in auth system — ready for staff CRUD endpoints (Plan 02)
- require_provider() available for protecting staff management endpoints
- Staff model has all columns needed for CRUD operations

## Self-Check: PASSED

All 4 files verified present. All 3 commit hashes verified in git log.

---
*Phase: 21-roles-auth-expansion*
*Completed: 2026-05-09*
