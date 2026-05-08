---
phase: 15-cyber-academic-visual-redesign
plan: 04
subsystem: mobile-ui
tags: [logo, custom-painter, vector-graphics, theme-adaptive, branding]
dependency_graph:
  requires: [15-02]
  provides: [alpha-connect-logo-widget]
  affects: [splash-screen, login-screen, client-home-screen]
tech_stack:
  added: []
  patterns: [CustomPainter, Path.combine, PathOperation.difference, size-adaptive-widget]
key_files:
  created:
    - mobile/lib/shared/widgets/alpha_connect_logo.dart
  modified:
    - mobile/lib/features/splash/screens/splash_screen.dart
    - mobile/lib/features/auth/screens/login_screen.dart
    - mobile/lib/features/client/screens/client_home_screen.dart
    - mobile/pubspec.yaml
  deleted:
    - mobile/assets/images/alpha_connect_logo.jpeg
decisions:
  - "Used Path.combine with PathOperation.difference to create the α eye/counter hole"
  - "Removed redundant 'Alpha Connect' text widgets since AlphaConnectLogo renders them"
  - "Splash neon glow uses BoxShadow on parent Container (not inside the logo widget)"
metrics:
  duration: "2m 21s"
  completed: "2026-05-08T18:32:22Z"
  tasks_completed: 2
  tasks_total: 2
  files_changed: 6
---

# Phase 15 Plan 04: Replace JPEG Logo with Programmatic Vector Widget Summary

**One-liner:** CustomPainter-based AlphaConnectLogo widget rendering filled α mark + Montserrat text, theme-adaptive at all sizes (36–100px), JPEG eliminated.

## What Was Done

### Task 1: Create AlphaConnectLogo widget with CustomPainter
- Created `mobile/lib/shared/widgets/alpha_connect_logo.dart`
- Implements `_AlphaMarkPainter` with filled α path (outer body + inner eye via `PathOperation.difference`)
- Size-adaptive behavior: mark-only at ≤40px, full branding (mark + ALPHA + CONNECT) at >40px
- Optional `showTagline` parameter for splash screen
- Color defaults to `Theme.of(context).colorScheme.primary` — no hardcoded colors
- Text uses `GoogleFonts.montserrat` with proportional sizing
- Commit: `9a669d4`

### Task 2: Replace JPEG logo usage in all screens and remove asset
- **splash_screen.dart**: Replaced 100×100 white Container + Image.asset with `AlphaConnectLogo(size: 100, showTagline: true)` wrapped in a neon glow BoxShadow Container. Removed redundant "Alpha Connect" Text widget.
- **login_screen.dart**: Replaced 80×80 white Container + Image.asset with `AlphaConnectLogo(size: 80)` inside Transform.rotate. Removed redundant "Alpha Connect" Text widget.
- **client_home_screen.dart**: Replaced 36×36 circular white Container + ClipOval + Image.asset with `AlphaConnectLogo(size: 36)` (mark-only mode).
- **pubspec.yaml**: Removed `assets:` section entirely (was only entry).
- Deleted `mobile/assets/images/alpha_connect_logo.jpeg` and empty directories.
- Commit: `b7f4296`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed redundant "Alpha Connect" text in splash and login screens**
- **Found during:** Task 2
- **Issue:** Both splash_screen.dart and login_screen.dart had a separate `Text('Alpha Connect')` widget below the old logo. Since `AlphaConnectLogo` at size > 40 already renders "ALPHA" + "CONNECT" text, keeping the separate Text widget would create duplicate branding.
- **Fix:** Removed the standalone Text widgets in both screens.
- **Files modified:** splash_screen.dart, login_screen.dart
- **Commit:** b7f4296

**2. [Rule 1 - Bug] Removed unused google_fonts import in splash_screen.dart**
- **Found during:** Task 2
- **Issue:** After removing the standalone Text widget that used GoogleFonts, the import became unused.
- **Fix:** Removed unused import.
- **Files modified:** splash_screen.dart
- **Commit:** b7f4296

## Verification Results

- ✅ `AlphaConnectLogo` widget exists with CustomPainter, PaintingStyle.fill, shouldRepaint
- ✅ Widget uses `colorScheme.primary` for theme-adaptive color
- ✅ All 3 screens import and use `AlphaConnectLogo`
- ✅ Zero references to `alpha_connect_logo.jpeg` anywhere in `mobile/`
- ✅ No `Colors.white` background containers around logo in any screen
- ✅ JPEG file deleted from filesystem
- ✅ pubspec.yaml has no asset reference

## Self-Check: PASSED
