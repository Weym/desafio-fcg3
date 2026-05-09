---
phase: 22-fcm-push-notifications
plan: 01
subsystem: notifications
tags: [fcm, firebase, push-notifications, fastapi, sqlalchemy]

# Dependency graph
requires:
  - phase: 03-feature-slices
    provides: "FcmToken model, Student model, dual-auth dependency"
provides:
  - "PUT /students/{id}/fcm-token endpoint for token registration"
  - "DELETE /students/{id}/fcm-token endpoint for token removal"
  - "NotificationService singleton with send_push and 3 event helpers"
  - "Firebase Admin SDK initialization in app lifespan"
  - "NotificationEvent enum and payload schemas"
affects: [22-02, 22-03, 22-04]

# Tech tracking
tech-stack:
  added: [firebase-admin]
  patterns: [fire-and-forget notifications, invalid token cleanup, graceful FCM degradation]

key-files:
  created:
    - backend/src/features/notifications/__init__.py
    - backend/src/features/notifications/schemas.py
    - backend/src/features/notifications/services.py
  modified:
    - backend/src/features/students/controllers.py
    - backend/src/main.py

key-decisions:
  - "asyncio.to_thread wraps blocking firebase-admin SDK calls"
  - "Invalid FCM tokens cleaned up on UnregisteredError/SenderIdMismatchError"
  - "FCM disabled gracefully (no-op) when FCM_CREDENTIALS_PATH not set"

patterns-established:
  - "Fire-and-forget notification: errors logged but never propagated to caller"
  - "Token upsert: PUT is idempotent (existing token updates device_name)"
  - "Event helpers: thin wrappers around send_push with Portuguese content"

requirements-completed: [FCM-02, FCM-03, FCM-04, FCM-05, FCM-06]

# Metrics
duration: 2min
completed: 2026-05-09
---

# Phase 22 Plan 01: FCM Push Notifications Backend Infrastructure Summary

**FCM token CRUD endpoints with IDOR protection + centralized NotificationService dispatching to Firebase with auto-cleanup of invalid tokens**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-09T03:28:46Z
- **Completed:** 2026-05-09T03:30:53Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- FCM token registration (PUT) and deletion (DELETE) endpoints with dual-auth IDOR protection
- Centralized NotificationService with send_push handling multi-device delivery
- Three event-specific helpers (document_ready, enrollment_confirmed, appointment_confirmed)
- Graceful degradation when Firebase credentials not configured
- Invalid token auto-cleanup on Firebase UnregisteredError

## Task Commits

Each task was committed atomically:

1. **Task 1: FCM token registration and deletion endpoints** - `add5faf` (feat)
2. **Task 2: Centralized notification service with Firebase Admin SDK** - `2c41e40` (feat)

## Files Created/Modified
- `backend/src/features/notifications/__init__.py` - Module initialization
- `backend/src/features/notifications/schemas.py` - FcmTokenRegister, FcmTokenDelete, NotificationEvent, NotificationPayload
- `backend/src/features/notifications/services.py` - NotificationService with send_push + event helpers + init_firebase()
- `backend/src/features/students/controllers.py` - Added PUT/DELETE /students/{id}/fcm-token endpoints
- `backend/src/main.py` - Added init_firebase() call in lifespan

## Decisions Made
- Used `asyncio.to_thread` to wrap blocking `messaging.send()` calls rather than a custom async wrapper
- Token upsert pattern: if token exists, update device_name; otherwise insert new record
- Delete endpoint is idempotent (returns 200 even if token not found)
- All notification body content hardcoded in Portuguese per CONTEXT.md specification
- chat_reply event type excluded per user decision (D-10)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None — local verification limited to syntax/import checks since database and Docker env vars are only available at runtime. All code follows existing patterns established in prior phases.

## User Setup Required

**External services require manual configuration.** Firebase setup needed:
- Create Firebase project at https://console.firebase.google.com
- Enable Cloud Messaging API
- Generate service account private key JSON
- Set `FCM_CREDENTIALS_PATH` environment variable pointing to the JSON file

## Next Phase Readiness
- NotificationService singleton ready for integration by Plan 02 (event triggers)
- notification_service importable from `src.features.notifications.services`
- Plan 03/04 can reference NotificationEvent enum for MCP tools

## Self-Check: PASSED

All files verified present. All commits verified in git log.

---
*Phase: 22-fcm-push-notifications*
*Completed: 2026-05-09*
