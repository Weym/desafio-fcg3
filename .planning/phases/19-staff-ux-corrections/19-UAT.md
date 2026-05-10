---
status: diagnosed
phase: 19-staff-ux-corrections
source: [19-01-SUMMARY.md, 19-02-SUMMARY.md, 19-03-SUMMARY.md, 19-04-SUMMARY.md, 19-05-SUMMARY.md, 19-06-SUMMARY.md]
started: 2026-05-09T14:00:00Z
updated: 2026-05-09T14:30:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Shell Tab Rename
expected: Bottom navigation tab previously labeled "Intervenção" (support_agent icon) now shows "Chats" with a chat_bubble icon. Tapping it navigates to the chats screen.
result: pass

### 2. Dashboard KPI Card Navigation
expected: Tapping "Chats Hoje" KPI card navigates to /staff/chats with today's filter pre-applied. Tapping "Docs Pendentes" navigates to /staff/documents with processing filter pre-applied.
result: issue
reported: "tapping 'Chats' navigates to /staff/chats and shows 'Todos', not only today's. Tapping 'Documentos' navigates to /staff/documents and shows 'Todos'"
severity: major

### 3. Dashboard AI Rate & Quick Actions
expected: AI resolution rate displays with 1 decimal (e.g., 95.3% not 95.33333%). Below AI Insights card, an "Ações Rápidas" section appears with "Gerenciar Alunos" button that navigates to /staff/cadastro.
result: pass

### 4. Appointments Card Redesign & Search
expected: Appointment cards show CircleAvatar with student initial, student name as title, resource as subtitle, date/time below, and status badge on right. Search bar filters by student name (case-insensitive) and RA.
result: issue
reported: "All circles are with '?', and all titles are written 'Aluno', and all subtitles are 'Recurso não definido', all date/time below are '2026-05-09 9:00' and status badge on right."
severity: major

### 5. Appointment Detail & Actions
expected: Tapping an appointment card opens detail screen showing Nome, RA, Data de emissão (DD/MM/YYYY), Recurso, Status (colored badge), and Motivo. Confirm/cancel buttons work with error SnackBar on failures.
result: issue
reported: "Shows Nome, RA, Data de emissão (DD/MM/YYYY), Recurso, Status, Motivo. Status and Motivo are correctly filled. All the others with 'Não informado'/'Não definido'. Confirm button returns 404 and Cancel button correctly cancels."
severity: major

### 6. Unified Chats Screen — Sub-Tabs
expected: StaffChatsScreen shows 4 tabs: Todos, Pendentes, Em atendimento, Concluídos. "Todos" merges AI sessions + interventions sorted by date. Other tabs filter by respective status. Search filters by name, RA, or phone.
result: issue
reported: "Shows these 4 tabs. Is not filtering by status, they are all in 'Todos'"
severity: major

### 7. Chat Detail Informative Header
expected: Opening a chat shows informative header with CircleAvatar (student initial), student name (bold), RA, session start date, and status. AppBar title shows student name instead of generic "Conversa".
result: issue
reported: "Yes, but all are returning 'Aluno' and not the student name. And in R/A all are returning 'N/A'"
severity: major

### 8. Documents Filter Tabs & Type Pills
expected: Documents screen shows 3 status tabs: Todos | Processando | Prontos. Below, horizontal scrollable type filter pills: Todos, Histórico, Declaração, Atestado, Diploma, Outros. Both filters apply simultaneously.
result: pass

### 9. Document Detail Sheet & Finalization Error
expected: Tapping a document card opens a bottom sheet showing Tipo, Status, Data solicitação, Observações, and action buttons. Trying to finalize (mark as 'ready') without attaching a file shows error SnackBar.
result: pass

### 10. Resources Toggle Switch
expected: Resource cards display a Switch widget for availability. Toggling the Switch updates the resource state, animates the switch, and refreshes the list. Error SnackBar on failure.
result: pass

### 11. Resources Delete with Confirmation
expected: 3-dot menu on resource cards shows "Deletar" option with error-colored text. Tapping it triggers a confirmation AlertDialog. Confirming deletes the resource; canceling dismisses.
result: issue
reported: "it shows the AlertDialog, but when confirmed, just changes the toggle state, like disable"
severity: major

### 12. Cadastro Screen — Cards, Search & Filters
expected: StaffCadastroScreen shows expandable GlassCards with CircleAvatar colored by status, student name/RA, and status dot. Expanding shows Email, Telefone, Endereço, Período, Campus. Search filters by name/RA/phone. Filter pills: Todos | Ativos | Inativos.
result: issue
reported: "Expanding just shows the email. And editing is not saving the other informations"
severity: major

### 13. Cadastro CRUD — Add, Edit, Toggle, Delete
expected: FAB opens form sheet with fields (Nome*, Email*, Celular, Endereço, RA, Período, Campus). Required field validation works. 3-dot menu offers Editar (pre-fills form), Ativar/Desativar (toggles status), Excluir. State refreshes after each action.
result: issue
reported: "It is just not saving the informations like celular, endereço... It just saves Nome and email"
severity: major

## Summary

total: 13
passed: 5
issues: 8
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "KPI card navigation pre-applies query param filters on target screens"
  status: failed
  reason: "User reported: tapping 'Chats' navigates to /staff/chats and shows 'Todos', not only today's. Tapping 'Documentos' navigates to /staff/documents and shows 'Todos'"
  severity: major
  test: 2
  root_cause: "Router constructs screens as const (ignoring query params); screens re-derive params in lifecycle callbacks with timing issues and no visual filter indicator"
  artifacts:
    - path: "mobile/lib/core/router/app_router.dart"
      issue: "const StaffChatsScreen() and const StaffDocumentsScreen() discard query params from state"
    - path: "mobile/lib/features/staff/screens/staff_chats_screen.dart"
      issue: "initState reads filter=hoje but stays on tab 0 (Todos) with no visual indicator"
    - path: "mobile/lib/features/staff/screens/staff_documents_screen.dart"
      issue: "addPostFrameCallback sets filter after first build — race condition with provider"
  missing:
    - "Pass initialFilter param from router to screen constructors (remove const)"
    - "StaffChatsScreen needs visible filter indication when filter=hoje is active"
    - "StaffDocumentsScreen needs synchronous filter application on first build"
  debug_session: ".planning/debug/kpi-card-filter-not-applied.md"

- truth: "Appointment cards display student name, resource name, and student initial from API data"
  status: failed
  reason: "User reported: All circles '?', titles 'Aluno', subtitles 'Recurso não definido' — fallback values instead of real data"
  severity: major
  test: 4
  root_cause: "Backend AppointmentListItem schema and builder never include student_name, student_ra, resource_name fields in API response"
  artifacts:
    - path: "backend/src/features/appointments/schemas.py"
      issue: "AppointmentListItem missing student_name, student_ra, resource_name fields"
    - path: "backend/src/features/appointments/services.py"
      issue: "_build_appointment_list_item() ignores loaded student/resource relationships"
  missing:
    - "Add student_name, student_ra, resource_name to AppointmentListItem schema"
    - "Update _build_appointment_list_item() to map relationship data to new fields"
    - "Add joinedload(Appointment.student) to list_appointments() query"
  debug_session: ".planning/debug/appt-fallback-data.md"

- truth: "Appointment detail shows populated Nome, RA, Data, Recurso fields and confirm action works"
  status: failed
  reason: "User reported: Status/Motivo filled correctly, all others 'Não informado'/'Não definido'. Confirm returns 404, cancel works."
  severity: major
  test: 5
  root_cause: "Same schema gap as Test 4; additionally PUT /appointments/{id}/confirm endpoint does not exist in backend"
  artifacts:
    - path: "backend/src/features/appointments/controllers.py"
      issue: "No PUT /{id}/confirm route handler exists"
    - path: "mobile/lib/features/staff/services/staff_schedule_service.dart"
      issue: "Calls PUT /appointments/{id}/confirm which is a non-existent endpoint"
  missing:
    - "Create PUT /appointments/{id}/confirm endpoint in backend controllers"
    - "Add confirm_appointment service method (change status scheduled→confirmed/completed)"
  debug_session: ".planning/debug/appt-fallback-data.md"

- truth: "Chat sub-tabs filter sessions by status (Pendentes/Em atendimento/Concluídos)"
  status: failed
  reason: "User reported: Shows 4 tabs but not filtering by status, all sessions appear in 'Todos'"
  severity: major
  test: 6
  root_cause: "Backend /interventions endpoint only returns human_needed+human_active sessions (no closed); Flutter Concluídos tab checks for phantom 'resolved' status that doesn't exist in DB"
  artifacts:
    - path: "backend/src/features/chat/service.py"
      issue: "list_intervention_sessions() filters WHERE status IN ('human_needed','human_active') — excludes closed"
    - path: "mobile/lib/features/staff/screens/staff_chats_screen.dart"
      issue: "Concluídos filter checks for 'resolved' status that is not a valid DB value"
  missing:
    - "Expand intervention query to optionally include closed sessions OR filter Concluídos from staffChatSessionsProvider"
    - "Remove phantom 'resolved' status check; use 'closed' only"
  debug_session: ".planning/debug/chats-tab-filtering-broken.md"

- truth: "Chat detail header displays actual student name and RA from API data"
  status: failed
  reason: "User reported: all returning 'Aluno' and RA returning 'N/A' instead of real student data"
  severity: major
  test: 7
  root_cause: "Backend ChatSessionResponse schema lacks student_name, student_ra fields — ORM loads student relationship but schema never serializes it"
  artifacts:
    - path: "backend/src/features/chat/schemas.py"
      issue: "ChatSessionResponse missing student_name, student_ra, student_email fields"
    - path: "backend/src/features/chat/service.py"
      issue: "selectinload(ChatSession.student) loads data but schema discards it"
  missing:
    - "Add student_name, student_ra fields to ChatSessionResponse schema"
    - "Add selectinload(ChatSession.student) to staff list_sessions query if not present"
  debug_session: ".planning/debug/chats-tab-filtering-broken.md"

- truth: "Resource 'Deletar' confirmation executes delete (not toggle)"
  status: failed
  reason: "User reported: shows AlertDialog, but confirming just changes toggle state like disable instead of deleting"
  severity: major
  test: 11
  root_cause: "Backend soft_delete_resource() only sets is_available=False — functionally identical to toggle; no true soft-delete marker"
  artifacts:
    - path: "backend/src/features/resources/services.py"
      issue: "soft_delete_resource() just sets is_available=False — same as toggle"
    - path: "backend/src/features/resources/controllers.py"
      issue: "DELETE endpoint delegates to soft_delete that behaves like toggle"
  missing:
    - "Add is_deleted/deleted_at column to Resource model OR implement hard delete"
    - "Update list queries to exclude deleted resources"
    - "Ensure frontend removes resource from list after successful delete"
  debug_session: ".planning/debug/delete-resource-does-toggle.md"

- truth: "Cadastro expanded card shows all fields (Email, Telefone, Endereço, Período, Campus)"
  status: failed
  reason: "User reported: Expanding just shows the email. Editing not saving other fields."
  severity: major
  test: 12
  root_cause: "Flutter model uses field names (ra, address, period, campus) that don't match backend (registration_number, semester) or don't exist in DB at all (address, campus)"
  artifacts:
    - path: "mobile/lib/features/staff/models/staff_student_model.dart"
      issue: "Fields ra/address/period/campus don't match backend names registration_number/semester; address/campus don't exist in DB"
    - path: "mobile/lib/features/staff/screens/staff_cadastro_screen.dart"
      issue: "Form submits with Flutter field names instead of backend names; expanded card guards on null fields"
    - path: "backend/src/features/students/schemas.py"
      issue: "StudentListItem response omits phone field; no address/campus in any schema"
  missing:
    - "Fix Flutter model to use @JsonKey(name: 'registration_number') for ra"
    - "Map period→semester with int/string conversion"
    - "Decide on address/campus: add to DB or remove from form"
    - "Add phone to StudentListItem backend response"
  debug_session: ".planning/debug/cadastro-fields-missing.md"

- truth: "Cadastro CRUD persists all student fields (Celular, Endereço, RA, Período, Campus)"
  status: failed
  reason: "User reported: only saves Nome and Email, other fields not persisted"
  severity: major
  test: 13
  root_cause: "Same field name mismatch as Test 12 — form sends ra/address/period/campus but backend expects registration_number/semester and doesn't have address/campus columns"
  artifacts:
    - path: "mobile/lib/features/staff/screens/staff_cadastro_screen.dart"
      issue: "_submit() builds request body with wrong field names (ra instead of registration_number)"
    - path: "mobile/lib/features/staff/services/staff_cadastro_service.dart"
      issue: "Service passes body as-is with mismatched keys"
  missing:
    - "Fix form _submit() to send registration_number instead of ra"
    - "Send semester (int) instead of period (string)"
    - "Either add address/campus to backend or remove from form"
  debug_session: ".planning/debug/cadastro-fields-missing.md"
