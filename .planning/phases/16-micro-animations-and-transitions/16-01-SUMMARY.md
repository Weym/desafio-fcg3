---
phase: 16-micro-animations-and-transitions
plan: 01
subsystem: ui
tags: [flutter, animations, dart, widget, accessibility, reduced-motion]

# Dependency graph
requires:
  - phase: 15-cyber-academic-visual-redesign
    provides: "GlassCard, AppColors, AppSpacing design tokens"
provides:
  - "AppAnimations centralized animation constants with stagger formula"
  - "AnimatedEntrance lifecycle-safe fade+slide-up widget"
  - "GlassBottomNav shared widget (extracted from shell duplication)"
affects: [16-02-PLAN, 16-03-PLAN, any-future-screen-animations]

# Tech tracking
tech-stack:
  added: []
  patterns: ["Timer-based delay with cancel in dispose", "Static const animation tokens", "Shared widget extraction refactoring"]

key-files:
  created:
    - mobile/lib/core/theme/app_animations.dart
    - mobile/lib/shared/widgets/animated_entrance.dart
    - mobile/lib/shared/widgets/glass_bottom_nav.dart
  modified:
    - mobile/lib/features/client/screens/client_shell.dart
    - mobile/lib/features/staff/screens/staff_shell.dart
    - mobile/test/widgets_test.dart

key-decisions:
  - "Timer replaces Future.delayed for lifecycle-safe stagger delays (H1 fix)"
  - "Stagger cap at index 5 (maxStaggerIndex) prevents timer storms on long lists"
  - "AnimatedEntrance animates once on mount — _visible flag persists, rebuilds don't retrigger"
  - "GlassBottomNav extracted as single shared widget from both client and staff shells"

patterns-established:
  - "AppAnimations static const pattern: all animation durations/curves/offsets as named constants"
  - "getEntranceDelay(index) is the SINGLE source of truth for stagger timing"
  - "AnimatedEntrance with MediaQuery.disableAnimations for accessibility"
  - "Shared widgets extracted to mobile/lib/shared/widgets/ when duplicated across features"

requirements-completed: [UI-NFR-02, UI-NFR-04]

# Metrics
duration: 4min
completed: 2026-05-10
---

# Phase 16 Plan 01: Animation Foundation Summary

**Centralized animation constants (AppAnimations), lifecycle-safe AnimatedEntrance widget with Timer-based stagger and reduced-motion support, plus GlassBottomNav extracted from duplicate shells**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-10T23:29:37Z
- **Completed:** 2026-05-10T23:33:34Z
- **Tasks:** 4/4
- **Files modified:** 6

## Accomplishments
- Created `AppAnimations` class with 14 static constants covering entrance, nav, and page transition domains plus `getEntranceDelay()` formula
- Built `AnimatedEntrance` StatefulWidget with Timer-based delay, fade+slide-up animation, and `MediaQuery.disableAnimations` reduced-motion support
- Extracted duplicate `_GlassBottomNav` from both `client_shell.dart` and `staff_shell.dart` into a single shared `GlassBottomNav` widget
- Added 6 AnimatedEntrance widget tests including Timer lifecycle safety and reduced-motion accessibility — all 48 tests pass

## Task Commits

Each task was committed atomically:

1. **Task 1: Create app_animations.dart constants file** - `5ca0c18` (feat)
2. **Task 2: Create lifecycle-safe AnimatedEntrance widget** - `8fee8ee` (feat)
3. **Task 3: Extract _GlassBottomNav to shared widget** - `cc3e268` (refactor)
4. **Task 4: Add AnimatedEntrance widget tests** - `47a15dc` (test)

## Files Created/Modified
- `mobile/lib/core/theme/app_animations.dart` - Centralized animation durations, curves, offsets, stagger formula
- `mobile/lib/shared/widgets/animated_entrance.dart` - Reusable AnimatedEntrance widget with lifecycle-safe Timer
- `mobile/lib/shared/widgets/glass_bottom_nav.dart` - Shared GlassBottomNav widget extracted from shells
- `mobile/lib/features/client/screens/client_shell.dart` - Removed duplicate _GlassBottomNav/_NavItem, imports shared widget
- `mobile/lib/features/staff/screens/staff_shell.dart` - Removed duplicate _GlassBottomNav/_NavItem, imports shared widget
- `mobile/test/widgets_test.dart` - Added AnimatedEntrance test group with 6 tests

## Decisions Made
- Timer replaces Future.delayed for lifecycle-safe stagger delays — H1 review fix addressing setState-after-dispose
- Stagger cap at maxStaggerIndex=5 prevents timer storms on long lists
- AnimatedEntrance animates once on mount — _visible flag persists across rebuilds, no retrigger
- GlassBottomNav extracted as single shared widget — pure refactor with zero functional change

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Animation foundation complete — `AppAnimations` and `AnimatedEntrance` ready for consumption by Plans 02 and 03
- `GlassBottomNav` as shared widget enables future nav animation enhancements in a single location
- All 48 tests pass, no new analyze issues

---
*Phase: 16-micro-animations-and-transitions*
*Completed: 2026-05-10*

## Self-Check: PASSED

All 4 created files verified on disk. All 4 task commit hashes found in git log.
