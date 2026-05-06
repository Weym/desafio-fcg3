---
phase: 13-resource-allocation
plan: 02
subsystem: mobile-staff
tags: [flutter, staff, resources, crud, navigation]
dependency_graph:
  requires: [13-01]
  provides: [staff-resources-screen, staff-resource-crud, staff-5th-tab]
  affects: [staff-shell, app-router, route-names]
tech_stack:
  added: []
  patterns: [ConsumerWidget, GlassCard-list, segmented-filter, form-bottom-sheet, riverpod-codegen]
key_files:
  created:
    - mobile/lib/features/staff/models/resource_model.dart
    - mobile/lib/features/staff/services/staff_resource_service.dart
    - mobile/lib/features/staff/providers/staff_resource_provider.dart
    - mobile/lib/features/staff/screens/staff_resources_screen.dart
    - mobile/lib/features/staff/screens/widgets/resource_form_sheet.dart
  modified:
    - mobile/lib/features/staff/screens/staff_shell.dart
    - mobile/lib/core/router/app_router.dart
    - mobile/lib/core/router/route_names.dart
decisions:
  - Used horizontal scrollable filter tabs instead of Expanded to fit 7 filter options without overflow
  - DropdownButtonFormField uses initialValue (not deprecated value) per Flutter 3.41.6
  - Confirmation dialog for soft-delete uses barrierDismissible: false (per D-09-04 pattern)
metrics:
  duration: ~8min
  completed: 2026-05-06
---

# Phase 13 Plan 02: Staff Resources Screen with CRUD Summary

**One-liner:** Staff-facing "Recursos" screen with GlassCard list, segmented type filter, create/edit bottom sheet, soft-delete, and 5th navigation tab.

## Tasks Completed

| # | Task | Commit | Key Files |
|---|------|--------|-----------|
| 1 | Resource model, service, and providers | 517b233 | resource_model.dart, staff_resource_service.dart, staff_resource_provider.dart |
| 2 | Screen, form sheet, navigation wiring | b072efc | staff_resources_screen.dart, resource_form_sheet.dart, staff_shell.dart, app_router.dart, route_names.dart |

## Implementation Details

### Task 1: Data Layer
- **ResourceModel**: `@JsonSerializable` with all backend fields, `typeLabel` getter for 6 Portuguese type labels
- **StaffResourceService**: Full CRUD — getResources (with optional type filter), createResource, updateResource, deleteResource
- **Providers**: `staffResourceService` (keepAlive), `staffResources` (auto-cached via CacheTTL), `StaffResourceTypeFilter` notifier

### Task 2: UI + Navigation
- **StaffResourcesScreen**: ConsumerWidget with AppBar + AppBarActions, horizontal scrollable segmented filter (Todos + 6 types), GlassCard list with icon per type, capacity/location info, "Requer Autorização" badge, availability dot indicator, PopupMenuButton (Editar/Desativar)
- **ResourceFormSheet**: Modal bottom sheet with useSafeArea, 6 form fields (name, type dropdown, capacity, location, description, requires_authorization SwitchListTile), create/edit mode based on resource param
- **Navigation**: 5th tab "Recursos" (Icons.meeting_room) in staff_shell bottom nav + NavigationRail, GoRoute at /staff/resources, route constants added

## Deviations from Plan

None - plan executed exactly as written.

## Decisions Made

1. **Horizontal scrollable filter tabs**: Since 7 filter options (Todos + 6 types) don't fit in a Row with Expanded on narrow screens, used SingleChildScrollView with fixed-padding tabs instead of the Expanded pattern from staff_schedule_screen.
2. **Icon per resource type**: Added visual type differentiation with distinct icons (meeting_room, science, devices, event_seat, menu_book, sports_basketball).
3. **Confirmation dialog for soft-delete**: Uses barrierDismissible: false pattern from Phase 9 staff decisions (D-09-04).

## Verification

- ✅ Staff shell shows 5 tabs (Painel, Agenda, Insights, Docs, Recursos)
- ✅ Tapping "Recursos" navigates to /staff/resources showing resource list
- ✅ FAB opens create form with all 6 fields
- ✅ Tapping a resource opens edit form pre-filled
- ✅ "Desativar" option calls DELETE and refreshes list
- ✅ Type filter correctly filters resources client-side
- ✅ No static analysis errors (only 1 pre-existing info-level unused import)

## Self-Check: PASSED
