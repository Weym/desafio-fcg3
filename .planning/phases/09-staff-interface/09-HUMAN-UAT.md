---
status: partial
phase: 09-staff-interface
source: [09-VERIFICATION.md]
started: 2026-05-05T04:30:00Z
updated: 2026-05-05T04:30:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Navigate all 4 staff tabs and verify screens render data from API

expected: Dashboard shows KPI numbers, Schedule shows appointment list, AI shows session list, Documents shows document list
result: [pending]

### 2. Tap KPI cards on dashboard and verify navigation to correct tab

expected: Pending Docs navigates to Documents tab, Appointments navigates to Schedule tab, Chats navigates to AI tab
result: [pending]

### 3. Create a scheduling slot via the FAB bottom sheet

expected: Date picker, time pickers, duration dropdown work; slot created successfully via API
result: [pending]

### 4. Upload a file via Update Status sheet when status is 'ready'

expected: File picker opens, file validates size, uploads to backend, URL returned and used in status update
result: [pending]

## Summary

total: 4
passed: 0
issues: 0
pending: 4
skipped: 0
blocked: 0

## Gaps
