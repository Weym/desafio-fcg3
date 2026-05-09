---
phase: 18-student-ux-corrections
plan: 01
subsystem: ui
tags: [flutter, navigation, quick-actions, bottom-nav, app-bar, riverpod]

# Dependency graph
requires:
  - phase: 12-client-screens
    provides: "Client screens scaffold with home, shell, and navigation"
provides:
  - "Corrected quick actions (Agendamentos -> nearest appointment, Docs -> auto-open drawer)"
  - "Support icon in AppBar header on all client screens"
  - "Notifications icon in AppBar header (moved from bottom nav)"
  - "4-item bottom navigation (Início, Chat, Docs, Recursos)"
affects: [18-student-ux-corrections, 24-ui-polish]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "documentAutoOpenDrawerProvider StateProvider for cross-screen drawer auto-open"
    - "showModalBottomSheet for appointment detail display from quick actions"

key-files:
  created: []
  modified:
    - "mobile/lib/features/client/screens/client_home_screen.dart"
    - "mobile/lib/shared/widgets/app_bar_actions.dart"
    - "mobile/lib/features/client/screens/client_shell.dart"
    - "mobile/lib/features/client/providers/document_provider.dart"
    - "mobile/lib/features/client/screens/client_documents_screen.dart"

key-decisions:
  - "Used StateProvider (documentAutoOpenDrawerProvider) for cross-screen drawer auto-open instead of route query params"
  - "Converted ClientDocumentsScreen to ConsumerStatefulWidget to support initState-based auto-open check"
  - "Notifications moved to header icon (not bottom nav) per STUX-14"

patterns-established:
  - "StateProvider flag pattern: set flag before navigation, check in initState, reset after use"
  - "AppBarActions as central location for header icon buttons (support, notifications, theme, logout)"

requirements-completed: [STUX-01, STUX-02, STUX-03, STUX-04]

# Metrics
duration: 5min
completed: 2026-05-09
---

# Phase 18 Plan 01: Quick Actions & Header Icons Summary

**Corrected home screen quick actions (Agendamentos/Docs/Notificações), added support + notifications icons to AppBar, removed Avisos from bottom nav**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-09T01:25:05Z
- **Completed:** 2026-05-09T01:30:05Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Quick actions grid corrected: "Agendamentos" shows nearest appointment in modal bottom sheet, "Solicitar documentos" navigates to docs screen and auto-opens request drawer, "Notificações" remains
- "Conversar com Mentor" and "Suporte" removed from quick actions grid entirely
- Support icon (Icons.support_agent_outlined) added to AppBarActions header — accessible on all client screens
- Notifications icon added to AppBarActions header (moved from bottom nav per STUX-14)
- Bottom navigation reduced from 5 to 4 items: Início, Chat, Docs, Recursos

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix quick actions and add support header icon** - `3a437b2` (feat)
2. **Task 2: Remove Avisos from bottom navigation (STUX-14)** - `5ea3ed3` (feat)

## Files Created/Modified
- `mobile/lib/features/client/screens/client_home_screen.dart` - Corrected quick actions list (3 items), added appointment detail modal bottom sheet
- `mobile/lib/shared/widgets/app_bar_actions.dart` - Added support + notifications icon buttons before theme toggle
- `mobile/lib/features/client/screens/client_shell.dart` - Removed Avisos from bottom nav and rail, updated indices to 0-3
- `mobile/lib/features/client/providers/document_provider.dart` - Added documentAutoOpenDrawerProvider StateProvider
- `mobile/lib/features/client/screens/client_documents_screen.dart` - Converted to ConsumerStatefulWidget with initState auto-open check

## Decisions Made
- Used StateProvider pattern for cross-screen auto-open instead of route query parameters — simpler, no URL pollution, Riverpod-native
- Converted ClientDocumentsScreen from ConsumerWidget to ConsumerStatefulWidget to access initState lifecycle for post-frame callback
- Placed notifications header icon between support and theme toggle for logical grouping

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Home screen quick actions are now correct and functional
- AppBarActions header provides consistent access to support + notifications across all client screens
- Bottom nav is clean with 4 items, ready for further client UX improvements in subsequent plans

---
*Phase: 18-student-ux-corrections*
*Completed: 2026-05-09*

## Self-Check: PASSED

- All 5 modified files exist on disk
- Commit 3a437b2 (Task 1) verified in git log
- Commit 5ea3ed3 (Task 2) verified in git log
- Commit 0a88291 (docs) verified in git log
- flutter analyze: 0 errors, 0 warnings on modified files
