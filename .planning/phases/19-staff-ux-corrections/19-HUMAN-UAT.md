---
status: partial
phase: 19-staff-ux-corrections
source: [19-VERIFICATION.md]
started: 2026-05-09T03:00:00.000Z
updated: 2026-05-10T00:00:00.000Z
---

## Current Test

[awaiting human testing — post-gap-closure re-verification]

## Tests

### 1. Dashboard KPI Filter Navigation

expected: Tap 'Chats Hoje' KPI card → navigates to /staff/chats with today filter pre-applied and visual badge. Tap 'Docs Pendentes' → navigates to /staff/documents with processing filter.
result: [pending]

### 2. Unified Chats Sub-Tabs with Backend Data

expected: Switch between Todos/Pendentes/Em atendimento/Concluídos tabs — Concluídos uses 'closed' status only. Chat cards show student_name and student_ra from backend (not fallback values).
result: [pending]

### 3. Cadastro CRUD Field Mapping

expected: Create/edit student via cadastro form — registration_number and semester fields persist correctly to backend. Expanded card shows Telefone and Periodo from backend data.
result: [pending]

### 4. Appointment Confirm End-to-End

expected: Staff taps confirm on a scheduled appointment → PUT /appointments/{id}/confirm succeeds → status changes to 'completed'. Cards display student_name, student_ra, resource_name (not '?' fallback).
result: [pending]

## Summary

total: 4
passed: 0
issues: 0
pending: 4
skipped: 0
blocked: 0

## Gaps
