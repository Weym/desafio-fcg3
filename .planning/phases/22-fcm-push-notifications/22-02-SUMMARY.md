---
phase: 22-fcm-push-notifications
plan: 02
subsystem: notifications
tags: [fcm, firebase, flutter, riverpod, firebase-messaging, firebase-core]

# Dependency graph
requires:
  - phase: 22-fcm-push-notifications
    provides: "PUT/DELETE /students/{id}/fcm-token backend endpoints"
  - phase: 07-flutter-scaffold-auth
    provides: "Auth provider with verifyCode/logout, Dio provider, Riverpod architecture"
provides:
  - "Firebase SDK initialized on Flutter app startup"
  - "FcmService Riverpod provider managing token lifecycle"
  - "FCM token auto-registered on student login"
  - "FCM token unregistered on logout"
  - "Automatic token refresh re-registration"
  - "Notification permission request flow"
affects: [22-03, 22-04]

# Tech tracking
tech-stack:
  added: [firebase_core, firebase_messaging, google-services-plugin]
  patterns: [fire-and-forget FCM registration, graceful Firebase init failure, permission-gated token registration]

key-files:
  created:
    - mobile/lib/core/providers/fcm_provider.dart
    - mobile/lib/core/providers/fcm_provider.g.dart
  modified:
    - mobile/pubspec.yaml
    - mobile/android/app/build.gradle.kts
    - mobile/android/build.gradle.kts
    - mobile/android/app/src/main/AndroidManifest.xml
    - mobile/lib/main.dart
    - mobile/lib/features/auth/providers/auth_provider.dart

key-decisions:
  - "Firebase.initializeApp wrapped in try/catch — app still works without Firebase configured"
  - "FCM token registration is fire-and-forget — never blocks auth flow"
  - "Permission requested immediately after first login (not on app start)"
  - "Token refresh listener auto-re-registers with backend if user is authenticated"

patterns-established:
  - "Graceful Firebase degradation: try/catch in main.dart, app continues without push"
  - "Permission-gated token registration: no token sent if user denies notification permission"
  - "Fire-and-forget service calls: FCM registration errors caught and swallowed silently"

requirements-completed: [FCM-01]

# Metrics
duration: 5min
completed: 2026-05-09
---

# Phase 22 Plan 02: Flutter Firebase Setup & FCM Token Lifecycle Summary

**Firebase SDK integration with Riverpod FcmService provider managing permission-gated token registration on login, cleanup on logout, and automatic refresh re-registration**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-09T03:31:00Z
- **Completed:** 2026-05-09T03:36:00Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments
- Firebase Core and Messaging SDKs configured for Android with Google Services plugin
- FcmService Riverpod provider with full token lifecycle (register, unregister, refresh)
- Auth flow integration: token registered after student verifyCode, unregistered before logout
- Notification permission request gated on first login (denied = no token sent)
- Graceful Firebase initialization failure handling (app runs without push notifications)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add Firebase dependencies and configure Android platform** - `d279a18` (chore)
2. **Task 2: Firebase initialization and FCM token provider** - `2b6a4d9` (feat)
3. **Task 3: Verify Firebase build configuration** - user-verified (checkpoint: build succeeded with google-services.json)

## Files Created/Modified
- `mobile/lib/core/providers/fcm_provider.dart` - FcmService Riverpod provider with register/unregister/refresh token logic
- `mobile/lib/core/providers/fcm_provider.g.dart` - Generated Riverpod code for FcmService
- `mobile/pubspec.yaml` - Added firebase_core and firebase_messaging dependencies
- `mobile/android/app/build.gradle.kts` - Added Google Services plugin application
- `mobile/android/build.gradle.kts` - Added Google Services plugin declaration
- `mobile/android/app/src/main/AndroidManifest.xml` - Default notification channel metadata
- `mobile/lib/main.dart` - Firebase.initializeApp() call with error handling
- `mobile/lib/features/auth/providers/auth_provider.dart` - FCM registerToken/unregisterToken wired into verifyCode/logout

## Decisions Made
- Firebase init wrapped in try/catch so missing google-services.json doesn't crash the app in development
- Permission request occurs immediately after first login, not on app startup (per D-26)
- FCM registration is fire-and-forget: errors are silently caught to never block the auth flow
- Only students register FCM tokens (staff excluded from push notifications)
- iOS configuration deferred to separate task (per D-24: Android-first validation)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

**External services require manual configuration.** See Firebase Console:
- Add Android app to Firebase project (package name from AndroidManifest.xml)
- Download `google-services.json` and place in `mobile/android/app/`
- Without this file, Firebase init will fail gracefully (app still works, push disabled)

## Next Phase Readiness
- FCM token lifecycle complete — backend always knows active device tokens
- Ready for Plan 03 (event triggers wiring NotificationService to business events)
- Ready for Plan 04 (foreground/background notification handling in Flutter)

## Self-Check: PASSED

All key files verified present via prior task commits. Build verified by user at checkpoint.

---
*Phase: 22-fcm-push-notifications*
*Completed: 2026-05-09*
