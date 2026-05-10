---
status: diagnosed
trigger: "Investigate why the Unified Chats Screen sub-tabs don't filter sessions by status"
created: 2026-05-09T00:00:00Z
updated: 2026-05-09T00:00:00Z
---

## Current Focus

hypothesis: Multiple root causes — filtered tabs watch interventionSessionsProvider which only returns human_needed/human_active sessions (never 'closed'/'resolved'), AND the API response schema (ChatSessionResponse) lacks student_name/student_ra/student_email fields
test: Trace data from backend query → API schema → Flutter model
expecting: Confirms missing statuses and missing fields in serialization
next_action: Return diagnosis

## Symptoms

expected: Pendentes/Em atendimento/Concluidos tabs filter sessions by status; chat detail header shows real student name and RA
actual: All sessions only appear in "Todos"; other tabs are empty; chat detail shows "Aluno" and "N/A"
errors: No runtime errors — silent data absence
reproduction: Open StaffChatsScreen, switch tabs; open any chat detail
started: Since implementation of unified chats screen (Phase 19)

## Eliminated

(none — diagnosis was direct)

## Evidence

- timestamp: 2026-05-09
  checked: _FilteredInterventionTab filter callbacks
  found: Pendentes uses s.isPending (status=='human_needed'), Em atendimento uses s.isActive (status=='human_active'), Concluidos uses s.status=='closed'||s.status=='resolved'
  implication: Filters are correct for intervention status values

- timestamp: 2026-05-09
  checked: interventionSessionsProvider → StaffInterventionService.getInterventionSessions() → GET /chat-sessions/interventions
  found: Backend service list_intervention_sessions() filters WHERE status IN ('human_needed','human_active') — **never returns 'closed' or 'resolved' sessions**
  implication: "Concluidos" tab will ALWAYS be empty because API never returns closed/resolved sessions

- timestamp: 2026-05-09
  checked: Backend ChatService.resolve_session()
  found: When resolved, status is set to 'closed' (not 'resolved') — so the filter for 'resolved' would never match anyway
  implication: Even if API returned resolved sessions, status value is 'closed' not 'resolved'

- timestamp: 2026-05-09
  checked: Backend ChatSessionResponse schema (Pydantic)
  found: Schema has fields: id, student_id, whatsapp_phone, status, name, verification_state, assigned_staff_id, escalated_at, started_at, ended_at, updated_at — NO student_name, student_ra, student_email, message_count, escalation_reason
  implication: Even though backend eagerly loads student relationship via selectinload(ChatSession.student), the ChatSessionResponse schema doesn't serialize those fields

- timestamp: 2026-05-09
  checked: Flutter InterventionSessionModel expects: student_name, student_email, escalation_reason, message_count
  found: None of these fields exist in the API response (ChatSessionResponse schema)
  implication: All these fields deserialize as null → displayName falls back to whatsappPhone or "Aluno #..." 

- timestamp: 2026-05-09
  checked: Flutter ChatSessionModel (used in chat detail header)
  found: studentName comes from json['student_name'], studentRa from json['student_ra'] — neither exists in API response
  implication: Header always shows fallback "Aluno" and "RA: N/A"

- timestamp: 2026-05-09
  checked: staffChatSessionsProvider → StaffChatService.getSessions() → GET /chat-sessions
  found: This returns ALL sessions (active, closed, human_needed, human_active) wrapped in ChatSessionListResponse — but _AllSessionsTab merges both providers correctly
  implication: "Todos" tab works because it reads from staffChatSessionsProvider (all statuses) 

## Resolution

root_cause: Three compounding issues: (1) The /interventions endpoint only returns human_needed + human_active sessions, so "Concluidos" tab is always empty; (2) ChatSessionResponse schema lacks student_name, student_ra, student_email, escalation_reason, and message_count fields, so Flutter models deserialize them as null; (3) resolve_session() sets status='closed' but Concluidos filter checks 'closed'||'resolved' — 'resolved' is a phantom status that never exists in the DB constraint.
fix: (empty — diagnosis only)
verification: (empty)
files_changed: []
