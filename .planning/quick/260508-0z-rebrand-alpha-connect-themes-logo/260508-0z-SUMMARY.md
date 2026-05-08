---
status: complete
---

# Quick Task 260508-0z: Rebrand to Alpha Connect + Themes + Logo

**Completed:** 2026-05-08

## Summary

Reverted app branding from "SIAC" back to "Alpha Connect" across all user-facing surfaces, integrated the Alpha Connect logo asset, and verified that light/dark mode support is fully operational.

## Changes Made

### 1. Renamed SIAC → Alpha Connect
- `mobile/lib/main.dart` — MaterialApp title
- `mobile/lib/features/splash/screens/splash_screen.dart` — splash branding text
- `mobile/lib/features/auth/screens/login_screen.dart` — login branding text
- `mobile/lib/features/client/screens/client_home_screen.dart` — AppBar title

### 2. Updated Platform App Labels
- `mobile/android/app/src/main/AndroidManifest.xml` — `android:label="Alpha Connect"`
- `mobile/ios/Runner/Info.plist` — CFBundleDisplayName + CFBundleName
- `mobile/web/index.html` — `<title>` + `apple-mobile-web-app-title`
- `mobile/web/manifest.json` — `name` + `short_name`

### 3. Implemented Logo Asset
- Copied `design ideas/alpha connect logo.jpeg` → `mobile/assets/images/alpha_connect_logo.jpeg`
- Declared asset in `mobile/pubspec.yaml` under `flutter: assets:`
- Replaced `Icons.school_rounded` with `Image.asset(...)` in:
  - Splash screen (80x80)
  - Login screen (64x64)
  - Home screen AppBar (32x32)

### 4. Light/Dark Mode Verified
- `AppTheme.light` and `AppTheme.dark` fully defined with Material 3
- `ThemeModeNotifier` persists user preference via SharedPreferences
- Default `ThemeMode.system` follows OS; toggle available on login screen
- All screens properly use `Theme.of(context).colorScheme` for adaptivity
