---
phase: 19-staff-ux-corrections
plan: 01
subsystem: mobile-staff-ui
tags: [navigation, dashboard, ux-correction]
dependency_graph:
  requires: []
  provides: [staffChats-route, staffCadastro-route, dashboard-query-nav]
  affects: [staff_shell, staff_dashboard_screen, app_router, route_names]
tech_stack:
  added: []
  patterns: [query-param-navigation, truncated-decimal-display, quick-actions-section]
key_files:
  created: []
  modified:
    - mobile/lib/features/staff/screens/staff_shell.dart
    - mobile/lib/features/staff/screens/staff_dashboard_screen.dart
    - mobile/lib/core/router/route_names.dart
    - mobile/lib/core/router/app_router.dart
decisions:
  - "staffChats route temporarily points to StaffAiScreen until Plan 03 replaces it"
  - "staffCadastro uses placeholder Scaffold until Plan 06 implements full CRUD"
  - "AI rate truncation uses double.parse(toStringAsFixed(1)) for clean display"
metrics:
  duration: ~5min
  completed: 2026-05-08T23:38:00Z
  tasks_completed: 2
  tasks_total: 2
---

# Phase 19 Plan 01: Staff Dashboard Navigation & Shell Tab Rename Summary

**One-liner:** Renamed bottom nav tab "Intervenção" to "Chats" with chat_bubble icon, added staffChats/staffCadastro routes, wired KPI cards with query param navigation, truncated AI rate display, and added "Ações Rápidas" section.

## Task Completion

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 | Rename shell tab + add route constants | 49a86aa | staff_shell.dart, route_names.dart, app_router.dart |
| 2 | Dashboard KPI navigation + AI rate + Ações Rápidas | b8f68d3 | staff_dashboard_screen.dart |

## Changes Made

### Task 1: Shell Tab Rename + Route Constants
- Renamed bottom nav tab at position 2 from "Intervenção" (support_agent icon) to "Chats" (chat_bubble icon)
- Updated rail destinations for tablet/desktop layout
- Added `staffChats` and `staffCadastro` to both RouteNames and RoutePaths
- Registered `/staff/chats` route pointing to StaffAiScreen (temporary)
- Registered `/staff/cadastro` route with placeholder screen
- Updated `_currentIndex` and `_onTap` to use `RoutePaths.staffChats`

### Task 2: Dashboard KPI Navigation + AI Rate + Quick Actions
- Truncated AI resolution rate to 1 decimal (95.3% not 95.33333%)
- "Chats Hoje" KPI navigates to `/staff/chats?filter=hoje`
- "Docs Pendentes" KPI navigates to `/staff/documents?filter=pendentes`
- Added "Ações Rápidas" section below AI Insights card
- "Gerenciar Alunos" button navigates to `/staff/cadastro`

## Deviations from Plan

None - plan executed exactly as written.

## Verification

- `flutter analyze --no-pub`: 0 errors (31 pre-existing warnings unrelated to changes)
- All acceptance criteria verified via grep

## Self-Check: PASSED
