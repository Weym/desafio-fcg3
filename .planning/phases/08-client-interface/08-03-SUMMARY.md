---
phase: 08-client-interface
plan: 03
title: "Documents Screen & Request Sheet"
subsystem: mobile/flutter
tags: [documents, filter-chips, status-chips, bottom-sheet, url-launcher, riverpod]
dependency_graph:
  requires: [08-01]
  provides: [client-documents-screen, document-request-sheet]
  affects: [08-04]
tech_stack:
  added: []
  patterns: [ConsumerWidget-filter-pattern, ConsumerStatefulWidget-form, url_launcher-download]
key_files:
  created:
    - mobile/lib/features/client/screens/client_documents_screen.dart
    - mobile/lib/features/client/screens/widgets/document_request_sheet.dart
  modified: []
decisions:
  - "Filter chips use toggle behavior — tapping active filter resets to 'Todos' (null)"
  - "Download uses url_launcher with LaunchMode.externalApplication for file viewing"
  - "Document type restricted to 4 hardcoded values via dropdown (T-08-05 mitigation)"
  - "Used initialValue instead of deprecated value on DropdownButtonFormField (Flutter 3.41.6)"
metrics:
  duration: "2m55s"
  completed: "2026-05-04T18:18:08Z"
---

# Phase 08 Plan 03: Documents Screen & Request Sheet Summary

**One-liner:** Documents list with colored status chips (amber/green/grey), filter chips by status, download action via url_launcher, and bottom sheet form for requesting new documents with type dropdown validation.

## What Was Built

### Task 1: Documents List Screen

**File:** `mobile/lib/features/client/screens/client_documents_screen.dart`

| Feature | Implementation |
|---------|---------------|
| Filter chips | 3 FilterChips: Todos (null), Pendentes ('pending'), Prontos ('ready') |
| Document cards | _DocumentCard with type label, date, status chip, conditional download |
| Status chips | amber.shade100/800 for requested/processing, green for ready, grey for delivered |
| Download action | IconButton(Icons.download) only when `isDownloadable && fileUrl != null` |
| FAB | FloatingActionButton.extended with "Solicitar" label opens request sheet |
| Empty state | Icon + "Nenhum documento encontrado" text |
| Error state | Error message + "Tentar novamente" button |
| Pull-to-refresh | RefreshIndicator invalidates documentsProvider |

**Provider wiring:**
- `ref.watch(documentsProvider)` for document list
- `ref.watch(documentFilterProvider)` for current filter
- `ref.read(documentFilterProvider.notifier).setFilter(...)` on chip tap

### Task 2: Document Request Bottom Sheet

**File:** `mobile/lib/features/client/screens/widgets/document_request_sheet.dart`

| Feature | Implementation |
|---------|---------------|
| Entry point | `showDocumentRequestSheet(context, ref)` function |
| Widget type | ConsumerStatefulWidget with _formKey, _selectedType, _notes, _isLoading |
| Type dropdown | DropdownButtonFormField with 4 items (transcript, enrollment_proof, declaration, certificate) |
| Notes field | TextFormField with maxLines: 3, optional |
| Submit | Validates form → calls documentServiceProvider.requestDocument → invalidates documentsProvider → pops sheet |
| Loading state | CircularProgressIndicator replaces button text while submitting |
| Success feedback | SnackBar "Documento solicitado com sucesso!" |
| Error feedback | SnackBar "Erro ao solicitar documento. Tente novamente." |
| Keyboard-aware | Padding uses MediaQuery.of(context).viewInsets.bottom |

## Verification Results

- ✅ `flutter analyze lib/features/client/screens/` — No issues found
- ✅ `flutter analyze lib/features/client/screens/widgets/document_request_sheet.dart` — No issues found
- ✅ FilterChip appears 3 times in documents screen
- ✅ `ref.watch(documentsProvider)` present
- ✅ `ref.watch(documentFilterProvider)` present
- ✅ `isDownloadable` check guards download button
- ✅ FloatingActionButton.extended triggers request sheet
- ✅ Status chip colors: amber, green, grey all mapped
- ✅ `showModalBottomSheet` in sheet file
- ✅ `DropdownButtonFormField<String>` with 4 document types
- ✅ `ref.read(documentServiceProvider)` for submit
- ✅ `ref.invalidate(documentsProvider)` after successful request

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed deprecated `value` on DropdownButtonFormField**

- **Found during:** Task 2
- **Issue:** Flutter 3.41.6 deprecated the `value` parameter — must use `initialValue` instead
- **Fix:** Changed `value: _selectedType` to `initialValue: _selectedType`
- **Files modified:** `mobile/lib/features/client/screens/widgets/document_request_sheet.dart`
- **Commit:** 3d73b8c

## Threat Mitigations Applied

| Threat ID | Mitigation |
|-----------|-----------|
| T-08-05 (Tampering) | Document type restricted to 4 valid dropdown values — no freeform input |
| T-08-06 (Info Disclosure) | file_url only shown/used for authenticated user's own documents; download via external browser |

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | 777d017 | feat(08-03): add documents list screen with filter chips, status chips, and download action |
| 2 | 3d73b8c | feat(08-03): add document request bottom sheet with type dropdown and submit |

## Self-Check: PASSED
