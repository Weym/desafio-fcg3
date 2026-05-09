---
status: diagnosed
phase: 18-student-ux-corrections
source: [18-VERIFICATION.md]
started: 2026-05-09T02:09:30Z
updated: 2026-05-09T12:00:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Quick Actions Navigation Flow

expected: Tap "Agendamentos" quick action on home screen and see nearest appointment details in a modal bottom sheet (reason, date, time, status). If no upcoming appointments, a snackbar "Sem agendamentos proximos" appears.
result: issue
reported: "apareceu, porém não da maneira que foi planejado. O objetivo é alterar a tela para ir para agendamentos e o próprio agendamento ter a função de quando clicado, aparecer os detalhes."
severity: major

### 2. Document Auto-Open Drawer

expected: Tap "Solicitar documentos" quick action on home screen, app navigates to documents screen, and the document request bottom sheet auto-opens.
result: pass

### 3. Chat Rename Interaction

expected: Long-press a chat session card to see a rename dialog with text field pre-filled with current name (or empty). Type new name, tap "Salvar", and session card updates to show the new name.
result: issue
reported: "It opens to rename and I can type the new name. But when I tap 'Salvar' nothing occurs. It doesn't save."
severity: major

### 4. Notification Read/Unread Visual State

expected: Unread notifications show full opacity with blue dot indicator. Tapping a notification marks it as read (opacity reduces to 0.6, blue dot disappears). Filter tabs (Todas/Nao lidas/Lidas) correctly filter the list.
result: pass

### 5. Bulk Mark As Read

expected: Tap "Visualizar todos" button and all notification cards transition to read state (reduced opacity, no blue dots). Unread count updates to 0.
result: pass

## Summary

total: 5
passed: 3
issues: 2
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "Tap 'Agendamentos' quick action navigates to appointments screen where tapping an appointment shows its details"
  status: failed
  reason: "User reported: apareceu, porém não da maneira que foi planejado. O objetivo é alterar a tela para ir para agendamentos e o próprio agendamento ter a função de quando clicado, aparecer os detalhes."
  severity: major
  test: 1
  root_cause: "Quick action calls _showNearestAppointment() which opens a modal bottom sheet for the nearest appointment directly from home. Should instead navigate to /client/resources (Meus Agendamentos tab). Additionally, _AppointmentCard in client_resources_screen.dart has no onTap handler to show details."
  artifacts:
    - path: "mobile/lib/features/client/screens/client_home_screen.dart"
      issue: "Lines 233-238: onTap calls _showNearestAppointment instead of navigating to resources screen"
    - path: "mobile/lib/features/client/screens/client_resources_screen.dart"
      issue: "Lines 419-513: _AppointmentCard has no onTap to show appointment detail sheet"
  missing:
    - "Change quick action onTap to navigate to /client/resources (tab index 1)"
    - "Add onTap to _AppointmentCard that calls showAppointmentDetailSheet"
    - "Import appointment_detail_sheet.dart in client_resources_screen.dart"
  debug_session: ""

- truth: "Long-press chat session card, type new name, tap Salvar, session card updates with new name"
  status: failed
  reason: "User reported: It opens to rename and I can type the new name. But when I tap 'Salvar' nothing occurs. It doesn't save."
  severity: major
  test: 3
  root_cause: "Backend has NO PUT /chat-sessions/{id} endpoint, NO name column on ChatSession model, and NO name field on ChatSessionResponse schema. Flutter code is correctly wired but the API call fails silently (unhandled exception prevents dialog close)."
  artifacts:
    - path: "mobile/lib/features/client/screens/client_chat_screen.dart"
      issue: "Lines 50-58: Salvar handler calls renameChatSessionProvider but API returns 404/405 — no error handling"
    - path: "backend/src/features/chat/router.py"
      issue: "No PUT /chat-sessions/{id} route exists"
    - path: "backend/src/features/chat/models.py"
      issue: "ChatSession model has no name column"
    - path: "backend/src/features/chat/schemas.py"
      issue: "ChatSessionResponse has no name field"
  missing:
    - "Add name column to ChatSession model (Alembic migration)"
    - "Add name field to ChatSessionResponse schema"
    - "Add rename_session service method"
    - "Add PUT /chat-sessions/{id} route in router.py"
    - "Add try/catch in Flutter Salvar handler for error feedback"
  debug_session: ""
