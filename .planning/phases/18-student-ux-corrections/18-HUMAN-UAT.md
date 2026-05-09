---
status: partial
phase: 18-student-ux-corrections
source: [18-VERIFICATION.md]
started: 2026-05-09T02:09:30Z
updated: 2026-05-09T02:09:30Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Quick Actions Navigation Flow

expected: Tap "Agendamentos" quick action on home screen and see nearest appointment details in a modal bottom sheet (reason, date, time, status). If no upcoming appointments, a snackbar "Sem agendamentos proximos" appears.
result: [pending]

### 2. Document Auto-Open Drawer

expected: Tap "Solicitar documentos" quick action on home screen, app navigates to documents screen, and the document request bottom sheet auto-opens.
result: [pending]

### 3. Chat Rename Interaction

expected: Long-press a chat session card to see a rename dialog with text field pre-filled with current name (or empty). Type new name, tap "Salvar", and session card updates to show the new name.
result: [pending]

### 4. Notification Read/Unread Visual State

expected: Unread notifications show full opacity with blue dot indicator. Tapping a notification marks it as read (opacity reduces to 0.6, blue dot disappears). Filter tabs (Todas/Nao lidas/Lidas) correctly filter the list.
result: [pending]

### 5. Bulk Mark As Read

expected: Tap "Visualizar todos" button and all notification cards transition to read state (reduced opacity, no blue dots). Unread count updates to 0.
result: [pending]

## Summary

total: 5
passed: 0
issues: 0
pending: 5
skipped: 0
blocked: 0

## Gaps
