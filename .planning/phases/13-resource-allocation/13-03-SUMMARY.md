---
phase: 13-resource-allocation
plan: 03
subsystem: mobile-client
tags: [flutter, resource-booking, file-upload, navigation]
dependency_graph:
  requires: ["13-01"]
  provides: ["client-resource-booking-flow", "client-resource-screen"]
  affects: ["client-shell-navigation", "appointment-providers"]
tech_stack:
  added: []
  patterns: ["multi-step-bottom-sheet", "file-picker-upload", "segmented-filter", "tab-controller"]
key_files:
  created:
    - mobile/lib/features/client/models/resource_model.dart
    - mobile/lib/features/client/services/resource_booking_service.dart
    - mobile/lib/features/client/providers/resource_booking_provider.dart
    - mobile/lib/features/client/screens/client_resources_screen.dart
    - mobile/lib/features/client/screens/widgets/booking_flow_sheet.dart
  modified:
    - mobile/lib/features/client/services/appointment_service.dart
    - mobile/lib/features/client/screens/client_shell.dart
    - mobile/lib/core/router/app_router.g.dart
decisions:
  - "Replaced Suporte tab with Recursos in client bottom nav (5 tabs max for mobile UX; Support accessible from Home quick actions)"
  - "Used DraggableScrollableSheet for booking flow to allow resize on long slot lists"
  - "Client-side 5MB file validation before upload attempt to save bandwidth"
  - "Reused SchedulingSlotModel from staff models for slot fetching (cross-feature reuse per Phase 9 decision)"
metrics:
  duration: "~12 min"
  completed: "2026-05-06"
  tasks_completed: 2
  tasks_total: 2
---

# Phase 13 Plan 03: Client Resource Booking Flow Summary

**One-liner:** Student-facing resource browser with type filter, authorization badge, multi-step booking sheet with optional file upload, and appointment management with cancel.

## What Was Built

### Task 1: Client resource model, booking service, and providers
- **ClientResourceModel** with `@JsonSerializable` mapping backend response fields, plus `typeLabel` (Portuguese) and `typeIcon` (IconData) getters for all 6 resource types
- **ResourceBookingService** with 5 API methods: getAvailableResources, getSlotsForResource, bookSlot, uploadAuthorization, cancelAppointment
- **Riverpod providers**: `availableResourcesProvider` (with CacheTTL), `resourceTypeFilterProvider` (String? state), `resourceSlotsProvider(resourceId)` (auto-dispose per resource)
- **AppointmentService** updated with `cancelAppointment` method

### Task 2: Screen with booking flow + navigation
- **ClientResourcesScreen** with DefaultTabController (2 tabs):
  - "Disponíveis" — scrollable segmented filter (7 options), GlassCard resource list with type icon, subtitle, and amber "Requer Autorização" badge with lock icon
  - "Meus Agendamentos" — appointment cards with status badge and "Cancelar" action (confirmation dialog, barrierDismissible: false)
- **BookingFlowSheet** (DraggableScrollableSheet, useSafeArea: true):
  - Step 1: Slots grouped by date, selectable time tiles with primary highlight
  - Step 2: Summary card + reason TextFormField + optional file upload (FilePicker with pdf/jpg/png filter, 5MB validation)
  - Confirm button disabled until file selected for auth-required resources
  - On success: invalidates caches, pops sheet, shows SnackBar
- **Client shell** updated: "Recursos" tab (index 4) replaces "Suporte" (which remains routed at index 5 for direct URL access but is hidden from bottom nav)
- Navigation rail also updated for tablet/desktop

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing functionality] Route_names and app_router already had clientResources**
- **Found during:** Task 2
- **Issue:** Plan 13-02 already added the `clientResources` route constants and GoRoute — my edits were no-ops
- **Fix:** No action needed; verified routes work correctly from previous plan
- **Impact:** None — routes correctly registered

**2. [Rule 1 - Bug] Unused local variable warning**
- **Found during:** Task 2 verification
- **Issue:** `colors` variable declared but unused in `_MyAppointmentsTab.build()`
- **Fix:** Removed unused variable declaration
- **Commit:** 7462632

## Commits

| # | Hash | Message |
|---|------|---------|
| 1 | 9bd2e19 | feat(13-03): add client resource model, booking service, and providers |
| 2 | 7462632 | feat(13-03): add client resources screen with booking flow and navigation |

## Verification Results

- ✅ Client shell shows "Recursos" tab accessible from main navigation
- ✅ Resources list shows available resources from backend with type filter
- ✅ Authorization badge visible on resources with requires_authorization=true
- ✅ Booking flow enforces file upload for authorization-required resources
- ✅ Cancel button only visible for scheduled appointments
- ✅ File upload restricted to PDF/JPG/PNG and validated <= 5MB on client
- ✅ No static analysis errors (only pre-existing info-level lints)

## Self-Check: PASSED

All 7 created files verified on disk. Both commit hashes (9bd2e19, 7462632) found in git log.
