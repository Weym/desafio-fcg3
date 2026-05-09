---
phase: 19-staff-ux-corrections
plan: 04
subsystem: mobile-staff-documents
tags: [flutter, staff, documents, filters, bottom-sheet, ux]
dependency_graph:
  requires: []
  provides: [staff-document-type-filter, staff-document-detail-sheet, document-error-validation]
  affects: [staff_documents_screen, staff_document_provider, update_status_sheet]
tech_stack:
  added: []
  patterns: [type-filter-pills, detail-bottom-sheet, query-param-prefilter, client-side-validation]
key_files:
  created: []
  modified:
    - mobile/lib/features/staff/screens/staff_documents_screen.dart
    - mobile/lib/features/staff/providers/staff_document_provider.dart
    - mobile/lib/features/staff/providers/staff_document_provider.g.dart
    - mobile/lib/features/staff/screens/widgets/update_status_sheet.dart
decisions:
  - "Type filter uses horizontal scrollable pills (not dropdown) for quick visual scanning"
  - "Detail sheet provides action buttons (Atualizar Status, Enviar Arquivo) contextual to document state"
  - "send_document_sheet already compliant with drawer pattern — no changes needed"
metrics:
  duration: ~5min
  completed: 2026-05-09T02:55:00Z
  tasks_completed: 2
  tasks_total: 2
---

# Phase 19 Plan 04: Staff Documents Filter Tabs, Type Filter, Detail Sheet & Error Messaging Summary

**One-liner:** Corrected document tabs to Todos/Processando/Prontos, added type filter pills, detail bottom sheet on card tap, query param support, and error SnackBar for finalization without file.

## What Was Done

### Task 1: Correct filter tabs + type filter + detail bottom sheet
- Renamed filter tab from 'Pendentes' (requested) to 'Processando' (processing)
- Final tabs: Todos | Processando | Prontos
- Added `StaffDocumentTypeFilter` Riverpod notifier provider for secondary type filtering
- Added horizontal scrollable type pills: Todos, Histórico, Declaração, Atestado, Diploma, Outros
- Filter logic applies BOTH status AND type filters simultaneously
- Converted `StaffDocumentsScreen` from `ConsumerWidget` to `ConsumerStatefulWidget` for `initState`
- Added `_showStaffDocumentDetailSheet` with full document data (Tipo, Status, Data solicitação, Observações)
- Detail sheet includes action buttons: "Atualizar Status" and "Enviar Arquivo" (when processing)
- Query param support: `?filter=pendentes` from Dashboard navigation pre-applies 'processing' filter

### Task 2: Error SnackBar + send document sheet compliance
- Added file validation in `update_status_sheet.dart` `_submit()` method
- When status is 'ready' and no file attached (neither new pick nor existing fileUrl): shows error SnackBar
- SnackBar uses `Theme.of(context).colorScheme.error` background for clear error indication
- `send_document_sheet.dart` already uses `showModalBottomSheet` with `isScrollControlled: true, useSafeArea: true` — verified compliant

## Deviations from Plan

None — plan executed exactly as written.

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 | b96294b | feat(19-04): correct document filter tabs + type filter + detail sheet |
| 2 | 2d9bb80 | fix(19-04): error SnackBar when finalizing document without file |

## Verification

- `flutter analyze --no-pub` passes with 0 errors
- Document tabs show "Processando" instead of "Pendentes" ✓
- Type filter pills present (Histórico, Declaração, Atestado, Diploma, Outros) ✓
- Card tap opens detail bottom sheet with `showModalBottomSheet` ✓
- Query param `?filter=pendentes` maps to 'processing' filter ✓
- Error SnackBar with `colorScheme.error` prevents finalization without file ✓

## Self-Check: PASSED
