---
phase: 19-staff-ux-corrections
plan: 02
subsystem: mobile-staff-schedule
tags: [flutter, staff, appointments, search, ux]
dependency_graph:
  requires: []
  provides: [StaffSearchBar-widget, appointment-card-redesign, appointment-detail-fields]
  affects: [staff-schedule-screen, appointment-model]
tech_stack:
  added: []
  patterns: [StaffSearchBar-reusable-widget, _DetailRow-pattern, client-side-search-filter]
key_files:
  created:
    - mobile/lib/shared/widgets/staff_search_bar.dart
  modified:
    - mobile/lib/features/staff/screens/staff_schedule_screen.dart
    - mobile/lib/features/staff/screens/staff_appointment_detail_screen.dart
    - mobile/lib/features/staff/providers/staff_schedule_provider.dart
    - mobile/lib/features/staff/providers/staff_schedule_provider.g.dart
    - mobile/lib/features/client/models/appointment_model.dart
    - mobile/lib/features/client/models/appointment_model.g.dart
decisions:
  - StaffSearchBar as reusable shared widget (not feature-local) for use across staff screens
  - Manual date formatting (DD/MM/YYYY) instead of intl package to avoid adding new dependency
  - AppointmentModel extended with studentName, studentRa, resourceName as nullable fields (API may not always return them)
metrics:
  duration: 366s
  completed: "2026-05-09"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 7
---

# Phase 19 Plan 02: Staff Agendamentos Card Redesign + Search + Detail Fix Summary

**One-liner:** Redesigned appointment cards with student name + resource, added reusable search bar, and fixed detail screen to show all required fields with working confirm/cancel actions.

## Tasks Completed

| # | Task | Commit | Key Changes |
|---|------|--------|-------------|
| 1 | Create StaffSearchBar + redesign cards | `9575148` | New shared widget, AppointmentModel fields, card UI with CircleAvatar/name/resource, search provider |
| 2 | Fix detail screen fields + confirm action | `dad6f1e` | Detail shows Nome/RA/Data emissão/Recurso/Status/Motivo, try/catch on confirm with error SnackBar |

## Implementation Details

### StaffSearchBar Widget
- Created as `mobile/lib/shared/widgets/staff_search_bar.dart`
- Reusable across any staff screen needing search
- Accepts `hintText`, `onChanged`, optional `controller`
- Styled with `surfaceContainerLow` fill and `radiusXl` border radius

### Appointment Card Redesign
- CircleAvatar shows first letter of student name (or '?' fallback)
- Title: student name (was: reason)
- Subtitle: resource name (was: datetime)
- Third line: date/time in smaller text
- Status badge retained on right side

### Client-Side Search
- `StaffScheduleSearch` Riverpod notifier holds query string
- Filter combines status filter AND search query
- Searches `studentName` (case-insensitive) and `studentRa` (exact substring)

### Detail Screen
- Fields displayed: Nome, RA, Data de emissão (DD/MM/YYYY), Recurso, Status (colored badge), Motivo
- `_DetailRow` widget: Row with label (bodySmall) + Spacer + value (bodyMedium bold)
- Confirm action: try/catch wrapping `confirmAppointment(id)`, success SnackBar + invalidate + pop
- Cancel action: same error handling pattern
- Error SnackBar uses `colors.error` background

### AppointmentModel Extension
- Added nullable fields: `studentName`, `studentRa`, `resourceName`
- Updated `.g.dart` for JSON serialization with snake_case keys

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed intl dependency**
- **Found during:** Task 2
- **Issue:** Plan suggested `DateFormat('dd/MM/yyyy')` from `package:intl` but intl is not a project dependency
- **Fix:** Manual date formatting with `padLeft(2, '0')` — no new dependency needed
- **Files modified:** `staff_appointment_detail_screen.dart`
- **Commit:** `dad6f1e`

**2. [Rule 2 - Critical] Added error handling on confirm/cancel actions**
- **Found during:** Task 2
- **Issue:** Original code had no try/catch — network errors would crash silently
- **Fix:** Wrapped both actions in try/catch with error SnackBar (colors.error background)
- **Files modified:** `staff_appointment_detail_screen.dart`
- **Commit:** `dad6f1e`

## Known Stubs

None — all fields use model data with appropriate null fallbacks.

## Self-Check: PASSED

- All 7 files exist on disk
- Commit `9575148` found in git log
- Commit `dad6f1e` found in git log
- `flutter analyze` passes with 0 errors
