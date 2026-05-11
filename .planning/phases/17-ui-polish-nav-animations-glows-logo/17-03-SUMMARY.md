---
phase: 17-ui-polish-nav-animations-glows-logo
plan: 03
subsystem: ui
tags: [flutter, logo, neon-glow, branding, svg]

requires:
  - phase: 15.2-add-alpha-connect-svg-logos
    provides: "SVG logo assets (full + short, dark + light variants)"
  - phase: 15-cyber-academic-visual-redesign
    provides: "AppColors neon palette (neonTeal, neonViolet, neonMagenta)"
provides:
  - "Large readable logo (180px) on login screen with neon glow halo"
  - "Clean AlphaConnectLogo API without dead showTagline parameter"
affects: [any-future-phase-using-AlphaConnectLogo]

tech-stack:
  added: []
  patterns:
    - "Brightness-adaptive neon glow via BoxShadow with AppColors.neonTeal (dark) / AppColors.primaryContainer (light)"

key-files:
  created: []
  modified:
    - mobile/lib/shared/widgets/alpha_connect_logo.dart
    - mobile/lib/features/auth/screens/login_screen.dart
    - mobile/lib/features/splash/screens/splash_screen.dart

key-decisions:
  - "Used AppColors.primaryContainer for light-mode glow instead of nonexistent neonTealLight — deep teal is subtle yet on-brand"
  - "Removed showTagline entirely (not just deprecated) since SVG bakes in tagline text and parameter was never wired"

patterns-established:
  - "Neon glow pattern: Container with BoxShadow wrapping logo, blurRadius 40, spreadRadius 8, alpha 0.3"

requirements-completed: [UI-NFR-02]

duration: 2min
completed: 2026-05-11
---

# Phase 17 Plan 03: Login Logo + Neon Glow + showTagline Cleanup Summary

**Login logo scaled from 80px to 180px with brightness-adaptive neon glow halo, dead showTagline parameter removed from AlphaConnectLogo**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-11T00:46:41Z
- **Completed:** 2026-05-11T00:48:22Z
- **Tasks:** 1
- **Files modified:** 3

## Accomplishments
- Login screen logo enlarged from 80px to 180px — tagline, text, and alpha mark all readable
- Neon glow BoxShadow surrounds logo: neonTeal in dark mode, deep teal (primaryContainer) in light mode
- Dead `showTagline` parameter completely removed from AlphaConnectLogo widget and all call sites
- All 48 existing Flutter tests pass, `flutter analyze` clean (no new issues)

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix login logo size, add neon glow, clean up showTagline** - `52c9659` (feat)

**Plan metadata:** [pending final commit]

## Files Created/Modified
- `mobile/lib/shared/widgets/alpha_connect_logo.dart` - Removed dead showTagline param + field + doc comment
- `mobile/lib/features/auth/screens/login_screen.dart` - Logo 80->180px, neon glow BoxShadow, AppColors import
- `mobile/lib/features/splash/screens/splash_screen.dart` - Removed showTagline: true argument (Rule 3 fix)

## Decisions Made
- **Light-mode glow color:** Used `AppColors.primaryContainer` (0xFF004D57, deep teal) instead of nonexistent `neonTealLight` — subtle but on-brand for light backgrounds
- **showTagline removal:** Full removal (not deprecation) since the parameter was never wired to any logic and the SVG bakes in the tagline text natively
- **Splash screen fix:** Proactively fixed `splash_screen.dart` which passed `showTagline: true` — would have been a compile error after parameter removal

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed splash_screen.dart passing removed showTagline parameter**
- **Found during:** Task 1 (grep for showTagline callers)
- **Issue:** `splash_screen.dart` line 43 passed `showTagline: true` to AlphaConnectLogo — would break after parameter removal
- **Fix:** Removed `showTagline: true` from the AlphaConnectLogo call
- **Files modified:** mobile/lib/features/splash/screens/splash_screen.dart
- **Verification:** `flutter analyze` + `flutter test` both pass
- **Committed in:** 52c9659 (part of task commit)

**2. [Rule 1 - Bug] Adapted neonTealLight reference to existing AppColors.primaryContainer**
- **Found during:** Task 1 (checking AppColors for neonTealLight)
- **Issue:** Plan referenced `AppColors.neonTealLight` which doesn't exist in AppColors palette
- **Fix:** Used `AppColors.primaryContainer` (0xFF004D57) for light-mode glow — deep teal that's visible but not overpowering on light backgrounds
- **Files modified:** mobile/lib/features/auth/screens/login_screen.dart
- **Verification:** Visual inspection confirms subtle teal glow in light mode
- **Committed in:** 52c9659 (part of task commit)

---

**Total deviations:** 2 auto-fixed (1 blocking, 1 bug)
**Impact on plan:** Both auto-fixes necessary for correctness. No scope creep.

## Issues Encountered
None — plan executed smoothly with minor adaptations for missing color constant and extra call site.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 17 plan 03 is the final plan — phase should be complete after this
- All AlphaConnectLogo usages verified: login (180px full), splash (100px full), client_home (36px short)
- No remaining references to showTagline in codebase

---
*Phase: 17-ui-polish-nav-animations-glows-logo*
*Completed: 2026-05-11*
