---
phase: 19-staff-ux-corrections
plan: 06
subsystem: mobile-staff-cadastro
tags: [flutter, staff, crud, riverpod, ui]
dependency_graph:
  requires: []
  provides: [staff-cadastro-screen, staff-student-model, staff-cadastro-provider]
  affects: [app-router]
tech_stack:
  added: []
  patterns: [expandable-card, filter-pills, search-provider, form-bottom-sheet, crud-service]
key_files:
  created:
    - mobile/lib/features/staff/models/staff_student_model.dart
    - mobile/lib/features/staff/services/staff_cadastro_service.dart
    - mobile/lib/features/staff/providers/staff_cadastro_provider.dart
    - mobile/lib/features/staff/screens/staff_cadastro_screen.dart
  modified:
    - mobile/lib/core/router/app_router.dart
decisions:
  - Used DioClient.dio pattern consistent with StaffResourceService (not direct methods)
  - ExpansionTile inside GlassCard for expandable cards (matches plan requirement)
  - Soft delete semantics via toggleStatus (backend convention — students use inactive, not physical delete)
metrics:
  duration: ~8min
  completed: "2026-05-09T03:10:39Z"
  tasks_completed: 2
  tasks_total: 2
  files_created: 4
  files_modified: 1
---

# Phase 19 Plan 06: Staff Cadastro de Alunos CRUD Screen Summary

**One-liner:** Full CRUD student management screen with expandable GlassCards, search by name/RA/phone, status filters, FAB add form, and 3-dot menu actions.

## What Was Built

### Task 1: Student Model + Service + Provider
- **StaffStudentModel** with JSON serialization, `isActive` getter, full field set (id, name, email, phone, address, ra, period, campus, status, createdAt)
- **StaffCadastroService** with 5 CRUD methods: `getStudents`, `createStudent`, `updateStudent`, `deleteStudent`, `toggleStatus`
- **Provider layer** with `staffStudentsProvider` (cached via CacheTTL), `StaffCadastroFilter` (null/active/inactive), `StaffCadastroSearch` (text query)

### Task 2: StaffCadastroScreen UI
- **StaffCadastroScreen** as ConsumerWidget with AppBar + AppBarActions
- **FAB** with `Icons.add` to open student creation bottom sheet
- **StaffSearchBar** at top filtering by name, RA, and phone simultaneously
- **Filter pills** (Todos | Ativos | Inativos) using consistent _FilterTab pattern
- **_StudentCard** with ExpansionTile inside GlassCard:
  - CircleAvatar colored by status (green/red)
  - Status dot indicator (green active, red inactive)
  - PopupMenuButton with Editar, Ativar/Desativar, Excluir
  - Expanded content shows Email, Telefone, Endereço, Período, Campus
- **_StudentFormSheet** modal bottom sheet with DraggableScrollableSheet:
  - Form fields: Nome*, Email*, Celular, Endereço, RA, Período, Campus
  - Reused for both create and edit (pre-fills when student passed)
  - Client-side validation for required fields
- **Router updated** from placeholder Scaffold to real StaffCadastroScreen

## Commits

| # | Hash | Message |
|---|------|---------|
| 1 | ddca215 | feat(19-06): create student model, service, and provider for cadastro CRUD |
| 2 | dda1dca | feat(19-06): build StaffCadastroScreen with CRUD, search, filters, expandable cards |

## Deviations from Plan

None — plan executed exactly as written.

## Verification

- `flutter analyze --no-pub`: 0 errors (34 pre-existing warnings in test files)
- `dart run build_runner build`: all .g.dart files generated successfully
- All acceptance criteria met for both tasks

## Known Stubs

None — all UI elements are wired to real providers and service calls.

## Self-Check: PASSED
