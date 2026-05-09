---
status: partial
phase: 18-student-ux-corrections
source: [18-VERIFICATION.md]
started: 2026-05-09T02:09:30Z
updated: 2026-05-09T23:50:00Z
---

## Current Test

[awaiting human testing — post gap closure]

## Tests

### 1. Agendamentos Quick Action Navigation

expected: Tap "Agendamentos" quick action on home screen navigates to /client/resources with 'Meus Agendamentos' tab pre-selected (index 1)
result: [pending]

### 2. Appointment Card Detail Sheet

expected: Tap an appointment card in 'Meus Agendamentos' tab opens bottom sheet showing appointment details (status badge, reason, date, start/end time)
result: [pending]

### 3. Document Auto-Open Drawer

expected: Tap "Solicitar documentos" quick action on home screen, app navigates to documents screen, and the document request bottom sheet auto-opens
result: pass

### 4. Chat Rename Full Stack

expected: Long-press a chat session card, type a new name, tap 'Salvar'. Name is persisted via PUT /chat-sessions/{id}, dialog closes, session list refreshes with new name
result: [pending]

### 5. Chat Rename Error Handling

expected: Long-press a chat session, tap 'Salvar' with server down or invalid response. Red error SnackBar 'Erro ao renomear conversa. Tente novamente.' appears, dialog stays open
result: [pending]

### 6. Notification Read/Unread Visual State

expected: Tap a notification to mark as read. Blue dot disappears, card becomes 60% opacity, unread count decrements
result: pass

### 7. Bulk Mark As Read

expected: Tap 'Visualizar todos' button with multiple unread notifications. All notification cards transition to read state simultaneously
result: pass

## Summary

total: 7
passed: 3
issues: 0
pending: 4
skipped: 0
blocked: 0

## Gaps

- truth: "Tap 'Agendamentos' quick action navigates to appointments screen where tapping an appointment shows its details"
  status: resolved
  reason: "Plan 18-06 navigates to /client/resources?tab=1 and wires showAppointmentDetailSheet on appointment card onTap"

- truth: "Long-press chat session card, type new name, tap Salvar, session card updates with new name"
  status: resolved
  reason: "Plan 18-07 created full backend support (migration, model, schema, service, router) and added Flutter error handling"
