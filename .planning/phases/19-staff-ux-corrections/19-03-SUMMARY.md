---
phase: 19-staff-ux-corrections
plan: 03
title: "Unified Staff Chats Screen"
subsystem: mobile-staff
tags: [flutter, staff, chats, tabs, search, ux]
dependency_graph:
  requires: [19-01]
  provides: [unified-chats-screen, chat-detail-header]
  affects: [staff-navigation, staff-chat-ux]
tech_stack:
  added: []
  patterns: [unified-tab-screen, search-provider, informative-header]
key_files:
  created:
    - mobile/lib/features/staff/screens/staff_chats_screen.dart
  modified:
    - mobile/lib/features/staff/screens/staff_chat_detail_screen.dart
    - mobile/lib/features/staff/providers/staff_chat_provider.dart
    - mobile/lib/features/staff/providers/staff_chat_provider.g.dart
    - mobile/lib/core/router/app_router.dart
    - mobile/lib/features/client/models/chat_session_model.dart
    - mobile/lib/features/client/models/chat_session_model.g.dart
decisions:
  - "Merged ChatSessionModel + InterventionSessionModel into unified view (not combined model)"
  - "Added studentName/studentRa nullable fields to ChatSessionModel for header display"
  - "Sub-route /staff/chats/:sessionId for chat detail navigation from unified screen"
metrics:
  duration: "~8 min"
  completed: "2026-05-09"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 7
---

# Phase 19 Plan 03: Unified Staff Chats Screen Summary

Unified StaffChatsScreen with 4 sub-tabs (Todos/Pendentes/Em atendimento/Concluídos) merging AI sessions and intervention into single view, plus informative chat detail header with student name, RA, session date and status.

## What Was Done

### Task 1: Create unified StaffChatsScreen with 4 sub-tabs + search
- Created `StaffChatsScreen` with `TabController(length: 4)` and tabs: Todos, Pendentes, Em atendimento, Concluídos
- "Todos" tab merges `staffChatSessionsProvider` + `interventionSessionsProvider` into unified sorted list
- "Pendentes" / "Em atendimento" / "Concluídos" filter intervention sessions by status
- Added `StaffSearchBar` for client-side search by name, RA, or phone
- Phone formatting with `(XX) XXXXX-XXXX` pattern
- Query param `?filter=hoje` support for dashboard KPI card navigation
- Added `StaffChatsSearch` notifier provider for search state
- Updated `app_router.dart`: `/staff/chats` now routes to `StaffChatsScreen` (replaced `StaffAiScreen` placeholder)
- Added sub-route `/staff/chats/:sessionId` for detail navigation

### Task 2: Chat detail informative header with student context
- Added `_ChatInfoHeader` widget with `surfaceContainerLow` background and rounded bottom corners
- Header displays: CircleAvatar with initial, student name (titleSmall bold), RA, session start date + status
- AppBar title shows student name (was generic "Conversa")
- Added `studentName` and `studentRa` fields to `ChatSessionModel` for API data binding
- Updated model's `.g.dart` serialization accordingly

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Functionality] Added studentName/studentRa to ChatSessionModel**
- **Found during:** Task 2
- **Issue:** `ChatSessionModel` lacked `studentRa` field needed for header display (D-23)
- **Fix:** Added nullable `studentName` and `studentRa` fields to model + updated generated serialization
- **Files modified:** `chat_session_model.dart`, `chat_session_model.g.dart`
- **Commit:** a3275ab

## Commits

| Task | Commit | Message |
| --- | --- | --- |
| 1 | bce804b | feat(19-03): create unified StaffChatsScreen with 4 sub-tabs + search |
| 2 | a3275ab | feat(19-03): add informative chat detail header with student context |

## Verification

- `flutter analyze --no-pub` passes with 0 errors
- StaffChatsScreen contains class, TabController(length: 4), all 4 tab labels
- StaffSearchBar integrated with search provider
- Chat cards display student name + formatted phone
- Chat detail shows informative header with RA and session date
- Router points `/staff/chats` to StaffChatsScreen

## Self-Check: PASSED
