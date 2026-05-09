---
phase: 22-fcm-push-notifications
plan: 04
subsystem: notifications
tags: [fcm, firebase-messaging, flutter, riverpod, deep-link, go-router, push-notifications]

# Dependency graph
requires:
  - phase: 22-fcm-push-notifications
    plan: 02
    provides: "FcmService provider, Firebase.initializeApp in main.dart, auth flow FCM registration"
provides:
  - "NotificationRouter mapping event types to GoRouter paths"
  - "NotificationHandler with foreground snackbar, background system display, cold start handling"
  - "D-14 snackbar suppression when user is already on target screen"
  - "D-15 auto-refresh via provider invalidation on notification receipt"
  - "D-18 pending deep-link preserved through expired JWT recovery"
  - "D-19 cold start notification handling via getInitialMessage"
  - "Background message handler registration"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns: [event-to-route mapping, foreground notification suppression, pending deep-link pattern, post-frame notification init]

key-files:
  created:
    - mobile/lib/core/providers/notification_routes.dart
    - mobile/lib/core/providers/notification_handler_provider.dart
    - mobile/lib/core/providers/notification_handler_provider.g.dart
  modified:
    - mobile/lib/main.dart
    - mobile/lib/features/auth/providers/auth_provider.dart
    - mobile/lib/features/auth/providers/auth_provider.g.dart

key-decisions:
  - "NotificationRouter only returns hardcoded RoutePaths constants — never constructs paths from raw payload (T-22-12 mitigation)"
  - "AlphaConnectApp converted from ConsumerWidget to ConsumerStatefulWidget to support post-frame callback initialization"
  - "Notification handler initialized via addPostFrameCallback to ensure BuildContext is available"
  - "Pending deep-link consumed in auth verifyCode with 300ms delay to let router redirect complete first"
  - "Provider invalidation triggers data refresh for documents, appointments, and derived notifications"

patterns-established:
  - "Event-to-route mapping: centralized NotificationRouter.routeFor() for all notification navigation"
  - "Foreground suppression: check current route before showing snackbar (D-14)"
  - "Pending deep-link: store path on cold start, consume after re-authentication (D-18)"
  - "Post-frame init: notification handlers initialized after widget tree build via addPostFrameCallback"

requirements-completed: [FCM-07, FCM-08]

# Metrics
duration: 5min
completed: 2026-05-09
---

# Phase 22 Plan 04: Flutter Notification Handlers & Deep-Link Navigation Summary

**Complete notification handling pipeline with foreground snackbar (auto-suppression), background system display, tap-to-navigate deep-links, and cold start handling with JWT expiry recovery**

## Performance

- **Duration:** 5 min
- **Started:** 2026-05-09T03:50:52Z
- **Completed:** 2026-05-09T03:56:45Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- NotificationRouter maps all 3 event types (document_ready, enrollment_confirmed, appointment_confirmed) to correct GoRouter paths
- Foreground handler shows floating snackbar with "Ver" action, suppressed when already on target screen
- Background handler registered as top-level function for Firebase SDK system tray display
- Cold start handling via getInitialMessage with pending deep-link stored for auth recovery
- Auth flow wired to consume pending deep-link after successful re-authentication
- Provider invalidation triggers auto-refresh of documents, appointments, and derived notifications

## Task Commits

Each task was committed atomically:

1. **Task 1: Notification route mapper and foreground/background handlers** - `65d96a4` (feat)
2. **Task 2: Wire notification handlers into app lifecycle and auth flow** - `47debd8` (feat)

## Files Created/Modified
- `mobile/lib/core/providers/notification_routes.dart` - Centralized event-to-route mapping (NotificationRouter.routeFor, isAlreadyOnTarget)
- `mobile/lib/core/providers/notification_handler_provider.dart` - Full notification lifecycle: foreground snackbar, background handler, cold start, pending deep-link
- `mobile/lib/core/providers/notification_handler_provider.g.dart` - Generated Riverpod code
- `mobile/lib/main.dart` - Firebase background handler registration, ConsumerStatefulWidget with post-frame init
- `mobile/lib/features/auth/providers/auth_provider.dart` - Pending deep-link consumption after successful verifyCode
- `mobile/lib/features/auth/providers/auth_provider.g.dart` - Regenerated Riverpod code (hash update)

## Decisions Made
- NotificationRouter uses only hardcoded RoutePaths constants to prevent path injection (T-22-12)
- AlphaConnectApp changed from ConsumerWidget to ConsumerStatefulWidget to track initialization state
- Background handler registered after Firebase.initializeApp (not before, per Firebase SDK requirement)
- Foreground context.mounted check added to prevent async gap lint issues
- 300ms delay on deep-link navigation after auth to allow router redirect to complete

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Next Phase Readiness
- Full notification handling pipeline complete across all app states (foreground, background, terminated)
- Phase 22 notification system is end-to-end functional:
  - Plan 01: Backend notification service and FCM token endpoints
  - Plan 02: Flutter Firebase SDK + token lifecycle
  - Plan 03: Backend event triggers wired to business actions
  - Plan 04: Flutter notification display and deep-link navigation (this plan)

## Self-Check: PASSED

All key files verified present. Both commits verified in git log.

---
*Phase: 22-fcm-push-notifications*
*Completed: 2026-05-09*
