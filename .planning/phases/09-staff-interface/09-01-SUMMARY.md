---
phase: 09-staff-interface
plan: 01
subsystem: ui
tags: [flutter, riverpod, dart, json-serializable, dio, file-picker]

# Dependency graph
requires:
  - phase: 08-client-interface
    provides: "Client models (AppointmentModel, DocumentModel, ChatSessionModel, ChatMessageModel, ActionLogModel), DioClient pattern, Riverpod provider pattern"
provides:
  - "Staff domain models: StaffDashboardModel, SchedulingSlotModel, StudentSummaryModel"
  - "Staff service classes: StaffDashboardService, StaffScheduleService, StaffDocumentService, StaffChatService"
  - "Staff Riverpod providers with codegen for all 4 domains (dashboard, schedule, documents, chat)"
  - "file_picker dependency for document upload feature"
affects: [09-02, 09-03, 09-04, 09-05]

# Tech tracking
tech-stack:
  added: [file_picker ^8.0.0]
  patterns: [cross-feature model reuse, staff service DioClient injection, riverpod codegen providers]

key-files:
  created:
    - mobile/lib/features/staff/models/staff_dashboard_model.dart
    - mobile/lib/features/staff/models/scheduling_slot_model.dart
    - mobile/lib/features/staff/models/student_summary_model.dart
    - mobile/lib/features/staff/services/staff_dashboard_service.dart
    - mobile/lib/features/staff/services/staff_schedule_service.dart
    - mobile/lib/features/staff/services/staff_document_service.dart
    - mobile/lib/features/staff/services/staff_chat_service.dart
    - mobile/lib/features/staff/providers/staff_dashboard_provider.dart
    - mobile/lib/features/staff/providers/staff_schedule_provider.dart
    - mobile/lib/features/staff/providers/staff_document_provider.dart
    - mobile/lib/features/staff/providers/staff_chat_provider.dart
  modified:
    - mobile/pubspec.yaml

key-decisions:
  - "Reuse client models (AppointmentModel, DocumentModel, ChatSessionModel, etc.) cross-feature instead of duplicating"
  - "Staff-specific models only for staff-unique API responses (dashboard KPIs, scheduling slots, student summary)"
  - "Services follow identical DioClient injection pattern established in Phase 8"

patterns-established:
  - "Cross-feature model imports: staff services import from ../../client/models/ for shared types"
  - "Staff provider pattern: @Riverpod(keepAlive: true) for service, @riverpod for async data"
  - "Null-aware elements lint: use // ignore: use_null_aware_elements for conditional map entries"

requirements-completed: [UI-F01, UI-F02, UI-F03, UI-F04]

# Metrics
duration: 29min
completed: 2026-05-05
---

# Phase 09 Plan 01: Staff Data Layer Summary

**Staff data layer with 3 models (JSON codegen), 4 services (DioClient + REST endpoints), and 4 Riverpod providers — reusing client models cross-feature, all passing static analysis**

## Performance

- **Duration:** 29 min
- **Started:** 2026-05-05T02:15:43Z
- **Completed:** 2026-05-05T02:44:26Z
- **Tasks:** 3
- **Files modified:** 21 (3 models + 3 .g.dart + 4 services + 4 providers + 4 .g.dart + pubspec.yaml + pubspec.lock + GeneratedPluginRegistrant.swift)

## Accomplishments
- Installed file_picker ^8.0.0 dependency for document upload feature
- Created 3 staff-specific models with @JsonSerializable codegen (StaffDashboardModel, SchedulingSlotModel, StudentSummaryModel)
- Created 4 service classes covering all staff API endpoints (dashboard, schedule/appointments, documents, chat)
- Created 4 Riverpod providers exposing async data, filters, and search for all staff domains
- All code passes `flutter analyze` with zero issues
- Client models (AppointmentModel, DocumentModel, ChatSessionModel, etc.) reused cross-feature without duplication

## Task Commits

Each task was committed atomically:

1. **Task 1: Add file_picker dependency and create staff domain models** - `c77362d` (feat)
2. **Task 2: Staff service classes for all API communication** - `5dda0a7` (feat)
3. **Task 3: Riverpod providers for all staff domains** - `1c62574` (feat)

## Files Created/Modified
- `mobile/pubspec.yaml` - Added file_picker ^8.0.0 dependency
- `mobile/lib/features/staff/models/staff_dashboard_model.dart` - Dashboard KPIs + EnrollmentPeriodInfo
- `mobile/lib/features/staff/models/scheduling_slot_model.dart` - Slot with date, time, availability
- `mobile/lib/features/staff/models/student_summary_model.dart` - Student autocomplete search model
- `mobile/lib/features/staff/services/staff_dashboard_service.dart` - GET /staff/dashboard
- `mobile/lib/features/staff/services/staff_schedule_service.dart` - Appointments + slots CRUD
- `mobile/lib/features/staff/services/staff_document_service.dart` - Documents + upload + student search
- `mobile/lib/features/staff/services/staff_chat_service.dart` - Sessions, messages, action logs, stats
- `mobile/lib/features/staff/providers/staff_dashboard_provider.dart` - Dashboard async provider
- `mobile/lib/features/staff/providers/staff_schedule_provider.dart` - Appointments, slots, filter provider
- `mobile/lib/features/staff/providers/staff_document_provider.dart` - Documents, filter, student search provider
- `mobile/lib/features/staff/providers/staff_chat_provider.dart` - Sessions, messages, logs, stats provider

## Decisions Made
- Reused existing client models (AppointmentModel, DocumentModel, ChatSessionModel, ChatMessageModel, ActionLogModel) cross-feature — no duplication
- Staff-specific models only created for staff-unique API responses
- Used `// ignore: use_null_aware_elements` consistent with Phase 8 pattern for conditional map entries
- StaffChatService.getStatistics() computes from session list client-side (no dedicated backend endpoint)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
- Dart build_runner failed in project directory due to special characters in path (`Área de Trabalho`). Resolved by copying project to `C:\tmp_dart` short path, running codegen there, then copying .g.dart files back to project.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- All staff providers ready for screen plans 02-05 to consume
- Services call correct REST endpoints with proper paths and query params
- Filter providers ready for UI filter chips
- Student search provider with debounce guard (query.length < 2 returns [])

## Self-Check: PASSED

- All 18 created files verified present on disk
- All 3 task commits verified in git log (c77362d, 5dda0a7, 1c62574)
- `flutter analyze lib/features/staff/` reports 0 issues

---
*Phase: 09-staff-interface*
*Completed: 2026-05-05*
