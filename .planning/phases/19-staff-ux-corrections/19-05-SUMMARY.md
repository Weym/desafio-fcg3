---
phase: 19-staff-ux-corrections
plan: 05
subsystem: mobile-staff-resources
tags: [flutter, staff, resources, toggle, delete, ux]
dependency_graph:
  requires: []
  provides: [resource-toggle, resource-delete]
  affects: [staff-resources-screen]
tech_stack:
  added: []
  patterns: [ConsumerWidget-for-ref-access, Switch-toggle-pattern, confirmation-dialog]
key_files:
  created: []
  modified:
    - mobile/lib/features/staff/screens/staff_resources_screen.dart
    - mobile/lib/features/staff/services/staff_resource_service.dart
decisions:
  - "Converted _ResourceCard from StatelessWidget to ConsumerWidget for direct ref access to toggle/delete"
  - "Toggle Switch placed between text column and PopupMenuButton for visual clarity"
  - "PopupMenu retains both toggle and delete as separate options alongside the Switch"
metrics:
  duration: ~3min
  completed: 2026-05-08
---

# Phase 19 Plan 05: Staff Resources Toggle & Delete Summary

**One-liner:** Switch widget for resource availability toggle + Deletar menu option with confirmation dialog

## What Was Done

### Task 1: Add toggle Switch + Deletar menu option to resource cards

**Commit:** `0794c53`

1. **StaffResourceService** — Added `toggleAvailability(id, isAvailable)` method that calls `PUT /resources/$id` with `is_available` payload. Kept existing `deleteResource` method with `DELETE /resources/$id`.

2. **_ResourceCard → ConsumerWidget** — Converted from StatelessWidget to ConsumerWidget to enable direct `ref` access for toggle and delete operations without callback drilling.

3. **Switch widget** — Replaced the static green/grey availability dot with an interactive `Switch` widget. Placed after the text column and before the PopupMenuButton. Uses `activeColor: colors.primary` for theme consistency.

4. **PopupMenu updates:**
   - "Editar" kept as-is
   - Dynamic "Ativar"/"Desativar" label based on `resource.isAvailable` state
   - New "Deletar" option with `colors.error` text styling

5. **Confirmation dialog** — "Deletar" triggers an `AlertDialog` with destructive action confirmation. FilledButton uses `colors.error` background. Includes message: "Tem certeza que deseja deletar...? Esta ação não pode ser desfeita."

6. **Error handling** — Both toggle and delete operations have try/catch with error SnackBars using `colorScheme.error` background.

7. **Removed `_deactivateResource`** from `StaffResourcesScreen` — functionality now lives inside `_ResourceCard` as `_handleToggle` and `_handleDelete` methods.

## Deviations from Plan

None — plan executed exactly as written.

## Verification

- `flutter analyze --no-pub` — 0 errors
- All 6 acceptance criteria verified via grep:
  - ✅ `Switch(` widget present
  - ✅ `'Deletar'` as PopupMenuItem
  - ✅ `'Tem certeza que deseja deletar'` in confirmation dialog
  - ✅ `toggleAvailability` method call in screen
  - ✅ `toggleAvailability` method in service
  - ✅ `deleteResource` with `.delete(` call in service

## Self-Check: PASSED
