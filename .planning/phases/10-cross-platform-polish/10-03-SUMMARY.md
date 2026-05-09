---
phase: 10-cross-platform-polish
plan: 03
subsystem: mobile-navigation
tags: [responsive, navigation-rail, master-detail, adaptive-layout]
dependency_graph:
  requires: [10-01, 10-02]
  provides: [adaptive-navigation-shells, master-detail-chat, master-detail-ai]
  affects: [client-shell, staff-shell, client-chat-screen, staff-ai-screen]
tech_stack:
  added: []
  patterns: [LayoutBuilder-breakpoint-switch, NavigationRail-adaptive, master-detail-row]
key_files:
  created: []
  modified:
    - mobile/lib/features/client/screens/client_shell.dart
    - mobile/lib/features/staff/screens/staff_shell.dart
    - mobile/lib/features/client/screens/client_chat_screen.dart
    - mobile/lib/features/staff/screens/staff_ai_screen.dart
decisions:
  - NavigationRail uses minWidth 72 / minExtendedWidth 180 per D-01 spec
  - Master-detail uses 35% width for session list panel, remainder for detail
  - Detail panel shows TabBar (Mensagens + Acoes) inline without AppBar
  - Selected session card highlighted with primaryContainer background
metrics:
  duration: 3m8s
  completed: 2026-05-05
  tasks: 2
  files_modified: 4
---

# Phase 10 Plan 03: Adaptive Navigation & Master-Detail Summary

**One-liner:** LayoutBuilder-driven shell refactoring with NavigationRail on tablet/desktop and inline master-detail for Chat/AI screens at >=1024dp.

## Tasks Completed

| # | Task | Commit | Key Changes |
|---|------|--------|-------------|
| 1 | Refactor ClientShell and StaffShell to adaptive navigation | c61a2f2 | LayoutBuilder + AppBreakpoints switch: BottomNav on phone, NavigationRail compact on tablet, extended on desktop; AppOfflineBanner at top |
| 2 | Add master-detail split view for Chat and AI Data screens | 4e5dc06 | ConsumerStatefulWidget with _selectedSessionId; Row with session list + detail panel on desktop; GoRouter navigation preserved on phone/tablet |

## Implementation Details

### Task 1: Adaptive Navigation Shells

Both `ClientShell` and `StaffShell` now use `LayoutBuilder` to determine screen width and render:
- **Phone (<600dp):** `BottomNavigationBar` with existing items (5 for client, 4 for staff)
- **Tablet (600-1023dp):** `NavigationRail` compact (icons only, `minWidth: 72`)
- **Desktop (>=1024dp):** `NavigationRail` extended (icons + labels, `minExtendedWidth: 180`)

Navigation items are extracted as `static const _navItems` and `static const _railDestinations` for consistency between the two modes.

`AppOfflineBanner` is placed at the top in a `Column` wrapping the main body for both phone and tablet/desktop layouts (per D-15).

### Task 2: Master-Detail Split View

**ClientChatScreen:**
- Converted from `ConsumerWidget` to `ConsumerStatefulWidget` to hold `_selectedSessionId` state
- Desktop layout: `Row` with session list (35% width) + `VerticalDivider` + detail panel (expanded)
- Detail panel shows `TabBar` with "Mensagens" and "Acoes" tabs inline
- Phone/tablet: unchanged GoRouter navigation to `/client/chat/{id}`

**StaffAiScreen:**
- Sessions tab receives `isDesktop`, `selectedSessionId`, and `onSessionSelected` callback
- Desktop layout: Same Row-based master-detail pattern
- Detail panel shows messages and actions tabs
- Phone/tablet: unchanged `context.push('/staff/ai/{id}')` navigation

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

- `dart analyze` passes for all 4 modified files (0 issues)
- ClientShell contains: `NavigationRail`, `LayoutBuilder`, `AppBreakpoints`, `AppOfflineBanner`, `minWidth: 72`, `minExtendedWidth: 180`
- StaffShell contains: `NavigationRail`, `LayoutBuilder`, `AppBreakpoints`
- ClientChatScreen contains: `AppBreakpoints`, `VerticalDivider`, `_selectedSessionId`
- StaffAiScreen contains: `AppBreakpoints`, `VerticalDivider`, `selectedSessionId`

## Self-Check: PASSED

All modified files exist and all commits verified.
