---
phase: 07-flutter-scaffold-auth
plan: 03
subsystem: mobile/navigation
tags: [flutter, gorouter, navigation, role-guards, shell-route, splash]
dependency_graph:
  requires: [07-01, 07-02]
  provides: [navigation-infrastructure, route-guards, role-shells]
  affects: [mobile/lib/main.dart, mobile/lib/core/router/, mobile/lib/features/splash/, mobile/lib/features/client/, mobile/lib/features/staff/]
tech_stack:
  added: []
  patterns: [GoRouter redirect guards, ShellRoute BottomNavigationBar, Riverpod-generated router provider]
key_files:
  created:
    - mobile/lib/core/router/route_names.dart
    - mobile/lib/core/router/app_router.dart
    - mobile/lib/core/router/app_router.g.dart
    - mobile/lib/features/splash/screens/splash_screen.dart
    - mobile/lib/features/client/screens/client_shell.dart
    - mobile/lib/features/client/screens/client_home_screen.dart
    - mobile/lib/features/staff/screens/staff_shell.dart
    - mobile/lib/features/staff/screens/staff_home_screen.dart
  modified:
    - mobile/lib/main.dart
decisions:
  - GoRouter redirect integrates with Riverpod auth state for declarative guard logic
  - ShellRoute pattern with NavigatorKey per role preserves navigation state within each shell
  - Placeholder screens use _PlaceholderScreen private class within app_router.dart for future-phase tabs
key_decisions:
  - "GoRouter redirect reads authProvider state directly — no separate guard class needed"
  - "Client and staff shells are separate ShellRoutes with distinct navigator keys for isolation"
  - "Splash screen triggers checkAuthStatus; GoRouter redirect handles all navigation automatically"
metrics:
  duration: ~4min
  completed: 2026-05-04T16:40:00Z
  tasks_completed: 2
  tasks_total: 2
  files_created: 8
  files_modified: 1
---

# Phase 07 Plan 03: Navigation & Route Guards Summary

GoRouter configuration with role-based redirect guards, ShellRoutes with BottomNavigationBar for client (5 tabs) and staff (4 tabs), splash screen with JWT validity check, and main.dart wired to MaterialApp.router.

## What Was Built

### Task 1: Route Constants & GoRouter Configuration
- **route_names.dart**: `RouteNames` (named constants) and `RoutePaths` (path strings) for all routes — splash, login, 5 client paths, 4 staff paths
- **app_router.dart**: `@riverpod` GoRouter provider with:
  - Redirect logic: AuthInitial/AuthLoading → stay on splash; AuthUnauthenticated/AuthError → login; AuthAuthenticated → role home
  - Role guards: student blocked from `/staff/*` → redirected to `/client`; staff blocked from `/client/*` → redirected to `/staff`
  - ShellRoute for client (5 sub-routes with `_clientShellKey`)
  - ShellRoute for staff (4 sub-routes with `_staffShellKey`)
  - `_PlaceholderScreen` for tabs not yet implemented (Phase 8/9)
- **app_router.g.dart**: Generated provider (`appRouterProvider`)

### Task 2: Splash Screen, Role Shells & Main Wiring
- **splash_screen.dart**: ConsumerStatefulWidget that calls `checkAuthStatus()` on init, shows app icon + CircularProgressIndicator. GoRouter redirect navigates once auth state resolves.
- **client_shell.dart**: 5-tab BottomNavigationBar (Home, Chat, Documentos, Notificacoes, Suporte) with `GoRouterState.of(context).matchedLocation` for active index tracking
- **client_home_screen.dart**: Placeholder home showing user name and logout button
- **staff_shell.dart**: 4-tab BottomNavigationBar (Dashboard, Agenda, IA, Documentos) with same pattern
- **staff_home_screen.dart**: Placeholder home showing user name and logout button
- **main.dart**: Updated from `StatelessWidget` with `MaterialApp` to `ConsumerWidget` with `MaterialApp.router` using `appRouterProvider`

## Verification Results

- `flutter pub run build_runner build` — 12 outputs generated successfully
- `flutter analyze lib/` — No issues found
- `flutter analyze lib/core/router/` — No issues found

## Deviations from Plan

None — plan executed exactly as written.

## Commits

| # | Hash | Message |
|---|------|---------|
| 1 | 7ef43d2 | feat(07-03): add GoRouter with role-based route guards and ShellRoutes |
| 2 | d48c601 | feat(07-03): add splash screen, role shells with BottomNav, and main.dart wiring |

## Self-Check: PASSED

All created files verified present, all commits verified in git log.
