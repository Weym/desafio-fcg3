---
status: partial
phase: 21-roles-auth-expansion
source: [21-VERIFICATION.md]
started: 2026-05-09T03:55:00Z
updated: 2026-05-09T03:55:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Provider Login & Navigation Flow

expected: App navigates to /staff (not /client), 6-tab bottom nav visible, tapping "Gestão" tab shows TabBar with "Staff" and "Alunos" tabs
result: [pending]

### 2. Staff List Card Rendering

expected: Cards show avatar initial, name (bold), email, position (if set), colored status badge (green "Ativo" / red "Inativo"), PopupMenuButton
result: [pending]

### 3. Staff CRUD Full Lifecycle

expected: All operations succeed (create via FAB → form → submit; edit via card tap; deactivate via PopupMenu → AlertDialog) with SnackBar feedback and list refresh
result: [pending]

## Summary

total: 3
passed: 0
issues: 0
pending: 3
skipped: 0
blocked: 0

## Gaps
