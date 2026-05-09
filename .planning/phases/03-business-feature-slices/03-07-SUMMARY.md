---
phase: 03-business-feature-slices
plan: 07
subsystem: api
tags: [fastapi, appointments, scheduling, pessimistic-locking, select-for-update]

# Dependency graph
requires:
  - phase: 03-01
    provides: "Shared infrastructure (BaseService, pagination, dual-auth dependencies, exceptions)"
provides:
  - "5 appointment/scheduling endpoints under /api/v1"
  - "SELECT FOR UPDATE booking with race-condition prevention (D-10)"
  - "Slot creation from time range + duration (APPT-STAFF-01)"
  - "IDOR-safe appointment cancellation with ownership check (T-03-28)"
affects: [04-mcp-server, 05-ai-service]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "SELECT FOR UPDATE pessimistic locking for concurrent booking prevention"
    - "Resource-to-staff API mapping (DB resource_id → API staff_id)"
    - "Slot generation from time range and duration"

key-files:
  created:
    - "backend/src/features/appointments/__init__.py"
    - "backend/src/features/appointments/schemas.py"
    - "backend/src/features/appointments/services.py"
    - "backend/src/features/appointments/controllers.py"
    - "backend/src/features/appointments/routes.py"
  modified:
    - "backend/src/main.py"

key-decisions:
  - "Appointments feature uses existing scheduling/models.py (Resource, SchedulingSlot, Appointment) — no new models needed"
  - "resource_id in DB maps to staff_id in API per SM-03 research finding"
  - "Slot overlap detection rejects entire range on conflict (409 HORARIO_CONFLITANTE) rather than skipping individual overlaps"
  - "AppointmentService handles ownership check internally rather than via shared check_ownership (needs user_role context)"

patterns-established:
  - "SELECT FOR UPDATE + joinedload pattern for pessimistic locking with eager-loaded relationships"
  - "Dual router registration: scheduling_router (/scheduling) + appointments_router (/appointments) under /api/v1"

requirements-completed: [APPT-01, APPT-02, APPT-03, APPT-04, APPT-STAFF-01]

# Metrics
duration: 4min
completed: 2026-04-24
---

# Phase 03 Plan 07: Appointments Summary

**Scheduling slots and appointment booking with SELECT FOR UPDATE pessimistic locking, slot generation from time ranges, and IDOR-safe cancellation**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-24T19:23:04Z
- **Completed:** 2026-04-24T19:27:30Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- Slot availability query with date range defaults (today → today+7) and resource/staff filter (APPT-01)
- Staff slot creation from time range with overlap detection and individual slot generation (APPT-STAFF-01)
- Appointment booking with SELECT FOR UPDATE preventing double-booking race conditions (APPT-02, D-10)
- Appointment cancellation releasing slot back to available, with IDOR ownership check (APPT-03, T-03-28)
- Paginated appointment listing with student auto-filter for IDOR safety (APPT-04)

## Task Commits

Each task was committed atomically:

1. **Task 1: Schemas and service with SELECT FOR UPDATE** - `ee735bc` (feat)
2. **Task 2: Controllers and route registration** - `f175381` (feat)

## Files Created/Modified
- `backend/src/features/appointments/__init__.py` - Package init
- `backend/src/features/appointments/schemas.py` - Pydantic models: SlotCreate, SlotResponse, AppointmentCreate, AppointmentResponse, AppointmentListItem, StaffInfo (118 lines)
- `backend/src/features/appointments/services.py` - SlotService and AppointmentService with SELECT FOR UPDATE, slot generation, overlap detection (406 lines)
- `backend/src/features/appointments/controllers.py` - 5 endpoint handlers with dual-auth and IDOR protection (185 lines)
- `backend/src/features/appointments/routes.py` - Router re-exports for main.py registration
- `backend/src/main.py` - Added scheduling_router and appointments_router under /api/v1

## Decisions Made
- Reused existing `features/scheduling/models.py` models (Resource, SchedulingSlot, Appointment) created in Phase 1 — no new model files needed
- Resource-to-staff mapping (SM-03): DB `resource_id` is exposed as `staff_id` in API query params, and `resource.name` mapped to `staff.name` in slot responses
- Slot overlap detection rejects the entire requested range with 409 `HORARIO_CONFLITANTE` rather than silently skipping overlapping sub-ranges — explicit error is safer for staff UX
- AppointmentService.cancel_appointment handles ownership internally (checks `user_role` and `student_id`) rather than using shared `check_ownership` because the cancel endpoint needs role-aware logic (staff can cancel any, students only own)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- Local Python 3.10.2 cannot fully import project modules (requires Python 3.12 `Self` type) — verified using AST parsing and structural checks instead of runtime imports. Code correctness confirmed via Docker runtime environment.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- All 5 APPT requirements have working endpoints ready for MCP tool integration (Phase 4)
- MCP tools `get_available_slots`, `book_appointment`, `cancel_appointment` can now call these endpoints via X-Service-Token auth
- Scheduling slots linked to resources table (D-09) — staff members represented as resources with `resource_type='staff'`

## Self-Check: PASSED

All 5 created files verified present on disk. Both task commit hashes (ee735bc, f175381) verified in git log.

---
*Phase: 03-business-feature-slices*
*Completed: 2026-04-24*
