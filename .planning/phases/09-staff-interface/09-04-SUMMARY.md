---
phase: 09-staff-interface
plan: 04
subsystem: ui
tags: [flutter, riverpod, file-picker, fastapi, file-upload, autocomplete]

# Dependency graph
requires:
  - phase: 09-staff-interface
    plan: 01
    provides: "Staff service classes (StaffDocumentService), Riverpod providers (staffDocumentsProvider, staffDocumentFilterProvider, studentSearchProvider, staffDocumentServiceProvider)"
provides:
  - "Staff Documents screen with filter chips, pull-to-refresh, and FAB"
  - "Update Status bottom sheet with conditional file picker (D-15)"
  - "Send Document bottom sheet with student autocomplete (D-17)"
  - "Backend POST /documents/upload endpoint for multipart file upload"
  - "Static file serving for uploads directory"
affects: [09-05]

# Tech tracking
tech-stack:
  added: []
  patterns: [conditional file picker visibility, autocomplete with async optionsBuilder, multipart file upload endpoint]

key-files:
  created:
    - mobile/lib/features/staff/screens/staff_documents_screen.dart
    - mobile/lib/features/staff/screens/widgets/update_status_sheet.dart
    - mobile/lib/features/staff/screens/widgets/send_document_sheet.dart
  modified:
    - backend/src/features/documents/controllers.py
    - backend/src/main.py

key-decisions:
  - "Backend upload uses local filesystem storage (uploads/documents/) with UUID prefix for MVP — production uses nginx/CDN"
  - "Bulk send (D-18) deferred as TODO — individual send implemented fully"
  - "File validation server-side: extension whitelist + 10MB max size"
  - "Autocomplete uses direct service call in optionsBuilder (not provider) for simplicity in bottom sheet context"

patterns-established:
  - "File upload flow: pick → validate size client-side → upload → use returned URL in subsequent API call"
  - "Conditional form fields: Visibility widget toggled by dropdown state"
  - "Autocomplete<Model> with async optionsBuilder for search-as-you-type"

requirements-completed: [UI-F04]

# Metrics
duration: 19min
completed: 2026-05-05
---

# Phase 09 Plan 04: Document Management Summary

**Staff document management with filter chips, status update sheet with conditional file upload, send document sheet with student autocomplete, and backend multipart upload endpoint**

## Performance

- **Duration:** 19 min
- **Started:** 2026-05-05T03:25:31Z
- **Completed:** 2026-05-05T03:44:46Z
- **Tasks:** 3
- **Files modified:** 5 (3 Flutter screens/widgets + 2 backend files)

## Accomplishments
- Backend POST /documents/upload endpoint with extension validation, 10MB max, UUID filename prefix, and static file serving
- StaffDocumentsScreen with 4 filter chips (Todos, Pendentes, Processando, Prontos), status-colored document cards, pull-to-refresh, and FAB
- UpdateStatusSheet with conditional file picker (only visible when status == 'ready') and upload-then-update flow
- SendDocumentSheet with Autocomplete<StudentSummaryModel> search, document type dropdown, optional file attachment, and createDocument API call
- All Flutter files pass `dart analyze` with zero issues

## Task Commits

Each task was committed atomically:

1. **Task 1: Backend file upload endpoint** - `47a13ac` (feat)
2. **Task 2: Staff Documents screen with filter chips and update status sheet** - `5281ca4` (feat)
3. **Task 3: Send Document sheet with student autocomplete** - `9733763` (feat)

## Files Created/Modified
- `backend/src/features/documents/controllers.py` - Added POST /documents/upload with validation and UUID-prefixed storage
- `backend/src/main.py` - Added StaticFiles import and mount for /uploads
- `mobile/lib/features/staff/screens/staff_documents_screen.dart` - Document list with filter chips, FAB, pull-to-refresh
- `mobile/lib/features/staff/screens/widgets/update_status_sheet.dart` - Bottom sheet for status update with conditional file picker
- `mobile/lib/features/staff/screens/widgets/send_document_sheet.dart` - Bottom sheet for proactive document sending with autocomplete

## Decisions Made
- Used local filesystem (`uploads/documents/`) for MVP file storage — production should serve via nginx/CDN with auth
- Autocomplete widget uses direct service call in `optionsBuilder` rather than provider — simpler in bottom sheet context where ref is available
- Bulk send (D-18) left as TODO comment — individual send fully functional, bulk can be added as future enhancement
- Used `initialValue` on DropdownButtonFormField (consistent with Phase 8 pattern for Flutter 3.41.6)

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

| File | Line | Stub | Reason |
|------|------|------|--------|
| send_document_sheet.dart | 1 | `// TODO: Bulk send (D-18)` | Per plan instruction: individual send implemented, bulk deferred to avoid complexity. Plan explicitly says "may leave bulk as TODO if complexity exceeds scope" |

## Threat Flags

None — all threat model items (T-09-08 through T-09-11) addressed as specified.

## Issues Encountered
- No Python virtual env with FastAPI available for import check — verified syntax correctness with `ast.parse()` instead
- `flutter analyze` not directly available via WSL — used `dart.exe analyze` from Windows Flutter SDK path

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Documents screen ready to be wired into staff navigation (Plan 05 handles router integration)
- Upload endpoint ready for integration tests when Docker environment runs
- All 3 staff domain screens complete (Dashboard, Schedule, AI/Chat, Documents) — Plan 05 can wire navigation

## Self-Check: PASSED

- All 3 created files verified present on disk
- All 3 task commits verified in git log (47a13ac, 5281ca4, 9733763)
- `dart analyze` reports 0 issues for all Flutter files
- Backend Python syntax verified via ast.parse()

---
*Phase: 09-staff-interface*
*Completed: 2026-05-05*
