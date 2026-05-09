---
phase: 18-student-ux-corrections
plan: 06
status: complete
wave: 3
started: "2026-05-09T22:31:54Z"
completed: "2026-05-09T22:35:18Z"
duration: "3m 23s"
tags: [gap-closure, navigation, appointments, quick-action]
dependency_graph:
  requires: [18-05]
  provides: ["Agendamentos quick action → resources tab", "Appointment card detail on tap"]
  affects: [client_home_screen, client_resources_screen, app_router]
tech_stack:
  added: []
  patterns: ["query param tab selection", "DefaultTabController initialIndex from route"]
key_files:
  modified:
    - mobile/lib/features/client/screens/client_home_screen.dart
    - mobile/lib/features/client/screens/client_resources_screen.dart
    - mobile/lib/core/router/app_router.dart
key_decisions:
  - "Removed _showNearestAppointment and its inline modal — navigation to resources tab is the correct UX"
  - "Tab index passed via query param ?tab=N, defaulting to 0 if invalid"
metrics:
  duration: "3m 23s"
  completed_date: "2026-05-09"
  tasks: 1
  files: 3
requirements: [STUX-06]
---

# Phase 18 Plan 06: Agendamentos Quick Action Navigation + Appointment Card onTap Summary

**One-liner:** Agendamentos quick action now navigates to /client/resources?tab=1 (Meus Agendamentos tab) and appointment cards open detail bottom sheet on tap.

## Objective

Fix UAT Gap 1: "Agendamentos" quick action should navigate to the Meus Agendamentos tab on the resources screen instead of opening a modal from home. Appointment cards on that tab should open a detail bottom sheet when tapped.

## What Was Built

1. **Agendamentos quick action navigation** — The "Agendamentos" quick action on the client home screen now navigates to `/client/resources?tab=1`, which pre-selects the "Meus Agendamentos" tab on the resources screen. The old `_showNearestAppointment` method (which opened an inline modal) was removed entirely as it's no longer needed.

2. **Query param routing** — `app_router.dart` now parses the `?tab=N` query parameter and passes it as `initialTabIndex` to `ClientResourcesScreen`. Invalid values default to 0 (Disponíveis tab).

3. **Appointment card detail on tap** — Each `_AppointmentCard` in the Meus Agendamentos tab now has an `onTap` handler that calls the existing `showAppointmentDetailSheet`, opening a bottom sheet with full appointment details (status, reason, date, time).

## Key Files

| File | Change |
|------|--------|
| `mobile/lib/features/client/screens/client_home_screen.dart` | Quick action navigates via context.go; removed _showNearestAppointment; removed unused import |
| `mobile/lib/core/router/app_router.dart` | Parses ?tab query param, passes initialTabIndex to ClientResourcesScreen |
| `mobile/lib/features/client/screens/client_resources_screen.dart` | Accepts initialTabIndex param; added appointment_detail_sheet import; _AppointmentCard GlassCard has onTap |

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 | `651ed3f` | feat(18-06): navigate to resources tab + appointment card onTap |

## Task Results

### Task 1: Navigate to resources tab + add appointment card onTap ✅

- Changed Agendamentos quick action from `_showNearestAppointment` to `context.go('${RoutePaths.clientResources}?tab=1')`
- Removed `_showNearestAppointment` method (37 lines) and unused `appointment_detail_sheet.dart` import
- AppRouter now extracts `?tab` query param and passes to `ClientResourcesScreen(initialTabIndex: tab)`
- `ClientResourcesScreen` accepts `initialTabIndex` parameter (default 0), passes to `DefaultTabController`
- `_AppointmentCard` GlassCard now has `onTap: () => showAppointmentDetailSheet(context, appointment)`
- `flutter analyze` passes with 0 errors on changed files

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — all functionality is fully wired.

## Issues

None.

## Self-Check: PASSED

- ✅ All 3 modified files exist on disk
- ✅ Commit 651ed3f found in git history
- ✅ flutter analyze: 0 errors on changed files
