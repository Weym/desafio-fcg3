---
phase: 10-cross-platform-polish
plan: 02
subsystem: mobile-flutter
tags: [widgets, skeleton, shimmer, empty-state, error-state, offline, responsive, ux]
dependency_graph:
  requires: []
  provides: [shared-ux-widgets, skeleton-shimmer, offline-banner, responsive-container]
  affects: [all-screens]
tech_stack:
  added: [shimmer ^3.0.0, connectivity_plus ^6.0.0]
  patterns: [StatefulWidget connectivity stream, Shimmer.fromColors, ConstrainedBox max-width]
key_files:
  created:
    - mobile/lib/shared/widgets/app_skeleton_list.dart
    - mobile/lib/shared/widgets/app_skeleton_card.dart
    - mobile/lib/shared/widgets/app_empty_state.dart
    - mobile/lib/shared/widgets/app_error_state.dart
    - mobile/lib/shared/widgets/app_offline_banner.dart
    - mobile/lib/shared/widgets/responsive_container.dart
  modified:
    - mobile/pubspec.yaml
    - mobile/pubspec.lock
decisions:
  - "Shimmer uses colorScheme.surfaceContainerHighest/surface for M3 dark-mode compatibility"
  - "AppOfflineBanner uses Stream<List<ConnectivityResult>> (connectivity_plus v6 API)"
  - "ResponsiveContainer defaults to 720dp max-width per D-04/D-06 decisions"
metrics:
  duration: ~3 min
  completed: 2026-05-05T14:27:00Z
  tasks_completed: 2
  tasks_total: 2
  files_created: 6
  files_modified: 2
---

# Phase 10 Plan 02: Shared UX State Widgets Summary

**One-liner:** Six reusable widgets (skeleton shimmer, empty/error state, offline banner, responsive container) providing consistent loading/error/empty UX across all 18 screens.

## Tasks Completed

| # | Task | Commit | Key Files |
|---|------|--------|-----------|
| 1 | Add shimmer and connectivity_plus dependencies | b34e167 | mobile/pubspec.yaml, mobile/pubspec.lock |
| 2 | Create all 6 shared widgets | dc7910d | mobile/lib/shared/widgets/*.dart (6 files) |

## What Was Built

### AppSkeletonList
Configurable shimmer list placeholder with `itemCount`, `itemHeight`, and `padding` parameters. Uses Material 3 `surfaceContainerHighest`/`surface` colors for dark mode compatibility.

### AppSkeletonCard
Configurable shimmer card placeholder with `height`, `width`, and `margin` parameters. Same M3-aware color scheme as AppSkeletonList.

### AppEmptyState
Centered widget with icon (64dp) + message + optional action button. Accepts `IconData icon`, `String message`, optional `actionLabel` and `onAction` callback.

### AppErrorState
Centered widget with error icon (64dp, colorScheme.error) + message + retry button. Defaults: icon=`Icons.error_outline`, message="Erro ao carregar dados", retryLabel="Tentar novamente".

### AppOfflineBanner
Thin persistent strip (4dp vertical padding) showing wifi_off icon + "Sem conexao" text. Uses `connectivity_plus` stream to listen for `ConnectivityResult.none`. Renders `SizedBox.shrink()` when online. Uses `errorContainer`/`onErrorContainer` colors.

### ResponsiveContainer
Max-width centered container (default 720dp) with optional padding. Uses `Center` + `ConstrainedBox` pattern for large screen centering per D-04/D-06.

## Verification Results

- `dart analyze lib/shared/widgets/` — 0 issues found
- All 6 files exist in `mobile/lib/shared/widgets/`
- Each widget is standalone (3 StatelessWidget, 1 StatefulWidget for offline banner)
- AppEmptyState accepts icon + message + optional action per UI-SPEC
- AppErrorState defaults to "Tentar novamente" per UI-SPEC copywriting contract
- AppOfflineBanner checks `ConnectivityResult.none` for offline detection

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED

- [x] mobile/lib/shared/widgets/app_skeleton_list.dart exists — FOUND
- [x] mobile/lib/shared/widgets/app_skeleton_card.dart exists — FOUND
- [x] mobile/lib/shared/widgets/app_empty_state.dart exists — FOUND
- [x] mobile/lib/shared/widgets/app_error_state.dart exists — FOUND
- [x] mobile/lib/shared/widgets/app_offline_banner.dart exists — FOUND
- [x] mobile/lib/shared/widgets/responsive_container.dart exists — FOUND
- [x] Commit b34e167 exists — FOUND
- [x] Commit dc7910d exists — FOUND
