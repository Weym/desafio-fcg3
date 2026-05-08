---
phase: 15-cyber-academic-visual-redesign
plan: 01
subsystem: mobile-theme
tags: [design-system, colors, typography, glassmorphism, tokens]
dependency_graph:
  requires: []
  provides: [cyber-academic-color-tokens, montserrat-typography, glass-card-neon-glow, pill-button-variants]
  affects: [all-mobile-screens, all-mobile-widgets]
tech_stack:
  added: []
  patterns: [design-tokens, glassmorphism, neon-glow-effects, 8px-grid-spacing]
key_files:
  created: []
  modified:
    - mobile/lib/core/theme/app_colors.dart
    - mobile/lib/core/theme/app_theme.dart
    - mobile/lib/core/theme/app_spacing.dart
    - mobile/lib/shared/widgets/glass_card.dart
    - mobile/lib/shared/widgets/pill_button.dart
    - mobile/test/theme_test.dart
decisions:
  - "Electric Teal (#00E5FF) is the same in both light and dark modes for maximum neon consistency"
  - "Montserrat used for both headings and body text with different weight hierarchy"
  - "JetBrains Mono reserved for technical/code data display via monoStyle getter"
  - "GlassCard glow intensity is halved in light mode (alpha * 0.5) for visual balance"
metrics:
  duration: "5m"
  completed: "2026-05-08"
  tasks_completed: 3
  tasks_total: 3
---

# Phase 15 Plan 01: Design Tokens & Theme Foundation Summary

**One-liner:** Cyber-Academic design system with Electric Teal (#00E5FF) primary, Montserrat + JetBrains Mono typography, glassmorphism cards with neon glow, and 8px grid spacing tokens.

## What Was Done

### Task 1: Replace color palette and typography with Cyber-Academic tokens

- **app_colors.dart**: Full palette replacement — Electric Teal (#00E5FF) primary, Cyber Violet (#7209B7) secondary, Magenta (#F72585) tertiary, Obsidian (#111317) dark surface. Added light/dark theme variants for all Material 3 surface containers. Added `neonTeal`, `neonViolet`, `neonMagenta` static constants for BoxShadow effects.
- **app_theme.dart**: Typography switched from Inter/Plus Jakarta Sans to Montserrat (all weights: w900 display, w800 headline, w700 headlineSmall, w600 title). Added `monoStyle` static getter using JetBrains Mono for technical data. Updated letterSpacing (-0.5 headings, -0.3 titles). AppBar title uses onSurface/darkOnSurface. ElevatedButton uses primary/onPrimary (teal/black). OutlinedButton uses primary border.
- **app_spacing.dart**: Updated documentation comment to explicitly reference 8px base unit grid system.

**Commit:** `57d340d` — feat(mobile): apply Cyber-Academic visual redesign (Phase 15)

### Task 2: Enhance GlassCard and PillButton with neon glow and Cyber-Academic styling

- **glass_card.dart**: Backdrop blur increased to 20px (sigmaX/Y: 20). Fill color changed to 5% white (`Colors.white.withValues(alpha: 0.05)`). Border set to 12% white. Added neon outer glow BoxShadow using `AppColors.neonTeal` with configurable `elevation` parameter (1=0.15, 2=0.25, 3=0.35 alpha). Added `glowColor` parameter for per-card customization. Light mode glow uses half intensity.
- **pill_button.dart**: Ghost variant updated — transparent background, `colors.primary` (teal) text and border. Primary variant works via ColorScheme (solid teal background, black text). Secondary and error variants use ColorScheme containers.

**Commit:** `57d340d` — feat(mobile): apply Cyber-Academic visual redesign (Phase 15)

### Task 3: Update theme tests to validate Cyber-Academic tokens

- **theme_test.dart**: All color assertions updated to Cyber-Academic values. Test descriptions reference "Cyber-Academic" instead of "alpha-connect". Added `neon glow colors are defined` test validating `neonTeal`, `neonViolet`, `neonMagenta`. All 21 tests pass.

**Commit:** `57d340d` — feat(mobile): apply Cyber-Academic visual redesign (Phase 15)

## Deviations from Plan

None — plan executed exactly as written. All tasks were implemented in a single atomic commit.

## Verification Results

| Check | Result |
|-------|--------|
| `flutter test test/theme_test.dart` | ✅ 21/21 tests pass |
| `flutter analyze` (theme files) | ✅ No issues found |
| No old Alpha Connect colors (0xFF3B608F, 0xFF6A548A) | ✅ Clean |
| No old fonts (plusJakartaSans, interTextTheme) | ✅ Clean |
| `0xFF00E5FF` in app_colors.dart | ✅ Present |
| `montserrat` in app_theme.dart | ✅ Present |
| `jetBrainsMono` in app_theme.dart | ✅ Present |
| `sigmaX: 20` in glass_card.dart | ✅ Present |
| `neonTeal` in glass_card.dart | ✅ Present |
| `Colors.transparent` in pill_button.dart | ✅ Present |
| `Cyber-Academic` in theme_test.dart | ✅ Present |

## Decisions Made

1. **Same primary in light/dark**: Electric Teal (#00E5FF) is identical in both modes for maximum neon consistency — typical Material 3 would lighten the dark variant.
2. **Single font family for body+headings**: Montserrat serves both headings (w600-w900) and body (w400), simplifying the font stack while maintaining visual hierarchy through weights.
3. **Glow halved in light mode**: GlassCard neon glow uses `glowAlpha * 0.5` in light mode to avoid overwhelming the lighter surfaces.
4. **Elevation as glow intensity**: The `elevation` parameter (1-3) controls glow alpha rather than traditional shadow depth, aligning with the cyberpunk aesthetic.

## Self-Check: PASSED

- ✅ `mobile/lib/core/theme/app_colors.dart` — FOUND (contains 0xFF00E5FF)
- ✅ `mobile/lib/core/theme/app_theme.dart` — FOUND (contains montserrat)
- ✅ `mobile/lib/core/theme/app_spacing.dart` — FOUND (contains 8px base unit)
- ✅ `mobile/lib/shared/widgets/glass_card.dart` — FOUND (contains sigmaX: 20, neonTeal)
- ✅ `mobile/lib/shared/widgets/pill_button.dart` — FOUND (contains Colors.transparent)
- ✅ `mobile/test/theme_test.dart` — FOUND (contains Cyber-Academic, 0xFF00E5FF)
- ✅ Commit `57d340d` exists in git log
