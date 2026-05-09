---
phase: 21-roles-auth-expansion
plan: 04
subsystem: ui
tags: [flutter, riverpod, crud, staff-management, cards, form, search, filter]

# Dependency graph
requires:
  - phase: 21-roles-auth-expansion
    plan: 02
    provides: "5 CRUD endpoints at /staff/members/* protected by require_provider()"
  - phase: 21-roles-auth-expansion
    plan: 03
    provides: "StaffGestaoScreen with conditional TabBar, 6-tab StaffShell"
provides:
  - "StaffMemberModel data class with json_annotation for API mapping"
  - "StaffManagementService HTTP client for all /staff/members endpoints"
  - "StaffMemberList Riverpod provider with search, filter, and CRUD state"
  - "Full staff list UI with cards (name, email, status badge, position)"
  - "Search bar with debounced API search and filter chips (Todos/Ativos/Inativos)"
  - "PopupMenuButton with Edit/Deactivate/Reactivate + AlertDialog confirmation"
  - "StaffMemberFormScreen full-screen form with 6 fields and validation"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns: ["Debounced search in StatefulWidget with Timer", "Record type for paginated API response"]

key-files:
  created:
    - "mobile/lib/features/staff/models/staff_member_model.dart"
    - "mobile/lib/features/staff/models/staff_member_model.g.dart"
    - "mobile/lib/features/staff/services/staff_management_service.dart"
    - "mobile/lib/features/staff/providers/staff_management_provider.dart"
    - "mobile/lib/features/staff/providers/staff_management_provider.g.dart"
    - "mobile/lib/features/staff/screens/staff_member_form_screen.dart"
  modified:
    - "mobile/lib/features/staff/screens/staff_gestao_screen.dart"

key-decisions:
  - "Used Dart record type for listStaff return: ({List<StaffMemberModel> items, int total})"
  - "Debounced search with 400ms Timer to avoid excessive API calls (T-21-15)"
  - "Form has both AppBar 'Salvar' action and bottom FilledButton for better mobile UX"
  - "Alunos tab remains as placeholder per D-13 — Phase 19 scope"

patterns-established:
  - "Staff management data layer: Model → Service → Riverpod notifier with CRUD methods"
  - "Card-based list with inline search + segmented filter chips + PopupMenuButton"

requirements-completed: [ROLE-03, ROLE-05, ROLE-07]

# Metrics
duration: 5min
completed: 2026-05-09
---

# Phase 21 Plan 04: Flutter Staff Management UI Summary

**Card-based staff list with debounced search, status filter chips, PopupMenu for deactivate/reactivate with AlertDialog, and full-screen create/edit form with 6 validated fields**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-09T03:42:08Z
- **Completed:** 2026-05-09T03:47:11Z
- **Tasks:** 3
- **Files created:** 6
- **Files modified:** 1

## Accomplishments

- StaffMemberModel with json_annotation — maps all StaffDetail/StaffListItem fields
- StaffManagementService with list (paginated), get, create, update, delete operations
- StaffMemberList Riverpod notifier with setSearch, setStatusFilter, refresh, CRUD methods
- StaffGestaoScreen rewritten — Staff tab now shows real card list with search, filters, and FAB
- _StaffCard widget with avatar initial, name, email, position, status badge, PopupMenuButton
- AlertDialog confirmation for destructive actions (deactivate/reactivate) per D-30
- StaffMemberFormScreen with name, email, phone, position, work_schedule, and role dropdown
- Form validation: required name/email, email regex check, required role selection
- Error handling: 409 → "Email já está em uso", 403 → "Sem permissão", generic fallback
- Alunos tab preserved as placeholder per D-13

## Task Commits

Each task was committed atomically:

1. **Task 1: Data layer (model, service, providers)** - `0cbe115` (feat)
2. **Task 2: StaffGestaoScreen full list UI** - `89f87da` (feat)
3. **Task 3: StaffMemberFormScreen create/edit form** - `dea79c8` (feat)

## Files Created/Modified

- `mobile/lib/features/staff/models/staff_member_model.dart` — StaffMemberModel data class
- `mobile/lib/features/staff/models/staff_member_model.g.dart` — Generated JSON serialization
- `mobile/lib/features/staff/services/staff_management_service.dart` — HTTP client for /staff/members
- `mobile/lib/features/staff/providers/staff_management_provider.dart` — Riverpod state management
- `mobile/lib/features/staff/providers/staff_management_provider.g.dart` — Generated Riverpod code
- `mobile/lib/features/staff/screens/staff_gestao_screen.dart` — Full staff list with cards, search, filters
- `mobile/lib/features/staff/screens/staff_member_form_screen.dart` — Full-screen create/edit form

## Decisions Made

- Used Dart record type `({List<StaffMemberModel> items, int total})` for paginated API response — cleaner than separate class
- 400ms debounce on search to avoid excessive API calls while typing
- Both AppBar action and bottom FilledButton for save — supports both thumb-zone and top-bar patterns
- `initialValue` used for DropdownButtonFormField (deprecated `value` param avoided for Flutter 3.41.6)
- Filter chips use toggle behavior (tap active filter again to deselect → shows all)

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

| Stub | File | Reason |
| --- | --- | --- |
| Alunos tab placeholder | staff_gestao_screen.dart:60 | Intentional per D-13 — Phase 19 delivers student CRUD UI |

## Self-Check: PASSED
