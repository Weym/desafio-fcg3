---
phase: 17-ui-polish-nav-animations-glows-logo
plan: 01
subsystem: ui
tags: [flutter, animation, navigation, statefulwidget, animationcontroller]

# Dependency graph
requires:
  - phase: 16-micro-animations-transitions
    provides: "GlassBottomNav shared widget, AppAnimations constants"
provides:
  - "StatefulWidget GlassBottomNav with explicit AnimationController for persistent animations"
  - "6-tab client navigation (Suporte tab at index 5)"
affects: [17-02, 17-03]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Explicit AnimationController + TickerProviderStateMixin for GoRouter-safe animations"
    - "CurvedAnimation with easeOutBack for springy nav transitions"

key-files:
  created: []
  modified:
    - mobile/lib/shared/widgets/glass_bottom_nav.dart
    - mobile/lib/features/client/screens/client_shell.dart

key-decisions:
  - "Replaced implicit animations (AnimatedContainer + TweenAnimationBuilder) with explicit AnimationController to survive GoRouter widget tree reconstruction"
  - "Single AnimationController per GlassBottomNav instance — tracks _previousIndex for outgoing item animation"

patterns-established:
  - "GoRouter-compatible animation: Use StatefulWidget + explicit AnimationController instead of implicit animations when GoRouter may reconstruct the widget"

requirements-completed: [UI-NFR-02, UI-NFR-04]

# Metrics
duration: 3min
completed: 2026-05-11
---

# Phase 17 Plan 01: Bottom Nav Animation Fix & Support Tab Summary

**Explicit AnimationController-based GlassBottomNav with springy easeOutBack glow+scale transitions and 6th Suporte NavItem for ClientShell**

## Performance

- **Duration:** 3 min
- **Started:** 2026-05-11T00:41:31Z
- **Completed:** 2026-05-11T00:44:21Z
- **Tasks:** 2/2
- **Files modified:** 2

## Accomplishments
- Converted GlassBottomNav from StatelessWidget to StatefulWidget with TickerProviderStateMixin and explicit AnimationController — animations now persist across GoRouter navigation rebuilds
- Added springy easeOutBack glow + scale transitions: icon size 24→28px, neon teal glow (blur 16, spread 4), background alpha fade — all driven by CurvedAnimation
- Added 6th NavItem (headset_mic icon, "Suporte" label) to ClientShell matching its 6 routes (index 0-5)
- Reduced-motion support via MediaQuery.disableAnimations snaps to final state

## Task Commits

Each task was committed atomically:

1. **Task 1: Convert GlassBottomNav to StatefulWidget with AnimationController** - `7393674` (feat)
2. **Task 2: Add 6th Support NavItem to ClientShell destinations** - `a27d422` (feat)

## Files Created/Modified
- `mobile/lib/shared/widgets/glass_bottom_nav.dart` - Rewritten from StatelessWidget to StatefulWidget with explicit AnimationController, CurvedAnimation, _previousIndex tracking, and per-item lerp calculations
- `mobile/lib/features/client/screens/client_shell.dart` - Added 6th NavItem (headset_mic/Suporte) to _destinations and _railDestinations lists

## Decisions Made
- Used single AnimationController per GlassBottomNav instance tracking `_previousIndex` to animate both incoming (selected) and outgoing (deselected) items simultaneously
- CurvedAnimation wraps controller with easeOutBack for springy overshoot feel
- Icon color and label color switch instantly (no lerp) — only size, glow, and background alpha are animated
- Glow/background threshold check (> 0.001) avoids rendering BoxShadow/color when effectively zero

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- GlassBottomNav now has reliable explicit animations for both client and staff shells
- Plan 02 (light mode glow colors) and Plan 03 (logo readability) can proceed independently
- All 48 existing tests pass, flutter analyze clean (only pre-existing info-level lints)

## Self-Check: PASSED

- [x] `mobile/lib/shared/widgets/glass_bottom_nav.dart` — FOUND
- [x] `mobile/lib/features/client/screens/client_shell.dart` — FOUND
- [x] `17-01-SUMMARY.md` — FOUND
- [x] Commit `7393674` — FOUND
- [x] Commit `a27d422` — FOUND

---
*Phase: 17-ui-polish-nav-animations-glows-logo*
*Completed: 2026-05-11*
