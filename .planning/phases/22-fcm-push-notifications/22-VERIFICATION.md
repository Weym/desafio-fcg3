---
phase: 22-fcm-push-notifications
verified: 2026-05-09T04:10:00Z
status: human_needed
score: 7/7 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Verify push notification appears in system tray (background state)"
    expected: "When document status set to 'ready' by staff, student's phone shows notification with title 'Documento pronto'"
    why_human: "Requires running Android device/emulator with Firebase configured and actual push delivery"
  - test: "Verify foreground snackbar appears and 'Ver' tap navigates"
    expected: "With app open, receiving notification shows floating snackbar; tapping 'Ver' navigates to documents/support/home"
    why_human: "Requires running Flutter app with live Firebase connection to verify UI behavior"
  - test: "Verify cold start from notification navigates to correct screen"
    expected: "Tapping notification when app is terminated opens app and navigates to relevant screen after auth"
    why_human: "Requires device-level testing of terminated state + Firebase message delivery"
  - test: "Verify token registration on real device login"
    expected: "After student login on device, backend receives PUT /students/{id}/fcm-token with valid Firebase token"
    why_human: "Requires Firebase project configured with google-services.json and real device"
---

# Phase 22: FCM Push Notifications Verification Report

**Phase Goal:** Students receive push notifications on their phone for key academic events, with tap-to-navigate functionality
**Verified:** 2026-05-09T04:10:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Flutter app registers FCM token on login and refreshes it automatically; backend stores tokens per device | ✓ VERIFIED | `auth_provider.dart:81` calls `fcmServiceProvider.notifier.registerToken(user.id)` on verifyCode success; `fcm_provider.dart:16` sets `onTokenRefresh` listener; `students/controllers.py:246` has PUT endpoint with upsert logic |
| 2 | Push notification dispatched when document is ready | ✓ VERIFIED | `documents/controllers.py:160` fires `asyncio.create_task(_send_notification())` when `data.status == "ready"` |
| 3 | Push notification dispatched when enrollment confirmed | ✓ VERIFIED | `enrollment/controllers.py:150` fires `asyncio.create_task(_send_notification())` after confirm |
| 4 | Push notification dispatched when appointment confirmed/booked | ✓ VERIFIED | `appointments/controllers.py:148` fires `asyncio.create_task(_send_notification())` after booking |
| 5 | Notifications handle foreground and background states | ✓ VERIFIED | `notification_handler_provider.dart:42` — `onMessage.listen` for foreground; `firebaseMessagingBackgroundHandler` (line 18) as top-level function; `main.dart:21` registers background handler |
| 6 | Tapping notification navigates to relevant screen | ✓ VERIFIED | `notification_handler_provider.dart:48` — `onMessageOpenedApp.listen` calls `_handleNotificationTap`; `notification_routes.dart:8` maps events to hardcoded RoutePaths; `notification_handler_provider.dart:102` handles cold start via `getInitialMessage` |
| 7 | FCM token removed on logout and invalid tokens cleaned on send failure | ✓ VERIFIED | `auth_provider.dart:144-148` calls `unregisterToken` before clearing auth; `services.py:139-153` catches `UnregisteredError` and deletes token from DB |

**Score:** 7/7 truths verified

### Note on FCM-06 (chat_reply)

ROADMAP SC #2 mentions "or new chat message received." However, user decision D-10 (in 22-CONTEXT.md) explicitly excludes `chat_reply` from this phase: *"chat_reply event explicitly excluded — interaction with bot is real-time, push would be redundant."* Plan 01 acknowledges this (line 182). This is a user-accepted scope reduction, not a gap. The REQUIREMENTS.md still shows FCM-06 as Pending but this is a documentation mismatch, not a code gap.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `backend/src/features/notifications/services.py` | Centralized notification service | ✓ VERIFIED | 218 lines, NotificationService class with send_push + 3 helpers, init_firebase(), singleton |
| `backend/src/features/notifications/schemas.py` | NotificationEvent enum and payload schemas | ✓ VERIFIED | 45 lines, FcmTokenRegister, FcmTokenDelete, NotificationEvent (3 values), NotificationPayload |
| `backend/src/features/notifications/__init__.py` | Module init | ✓ VERIFIED | Exists |
| `backend/tests/test_notifications.py` | Unit tests | ✓ VERIFIED | 291 lines, 8 tests all passing |
| `mobile/lib/core/providers/fcm_provider.dart` | FCM token management provider | ✓ VERIFIED | 96 lines, FcmService with register/unregister/refresh, permission-gated |
| `mobile/lib/core/providers/notification_handler_provider.dart` | Foreground/background/tap handlers | ✓ VERIFIED | 142 lines, NotificationHandler with initialize, foreground snackbar, tap navigate, cold start, pending deep-link |
| `mobile/lib/core/providers/notification_routes.dart` | Event-to-route mapping | ✓ VERIFIED | 29 lines, NotificationRouter.routeFor + isAlreadyOnTarget |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `notifications/services.py` | `firebase_admin.messaging` | `messaging.send()` call | ✓ WIRED | Line 132: `await asyncio.to_thread(messaging.send, message)` |
| `notifications/services.py` | `FcmToken model` | SQLAlchemy query | ✓ WIRED | Line 105: `select(FcmToken).where(FcmToken.student_id == student_id)` |
| `documents/controllers.py` | `notifications/services.py` | `asyncio.create_task(notify_document_ready)` | ✓ WIRED | Line 154-160: closure with fresh DB session |
| `enrollment/controllers.py` | `notifications/services.py` | `asyncio.create_task(notify_enrollment_confirmed)` | ✓ WIRED | Line 141-150: closure with fresh DB session |
| `appointments/controllers.py` | `notifications/services.py` | `asyncio.create_task(notify_appointment_confirmed)` | ✓ WIRED | Line 139-148: closure with fresh DB session |
| `auth_provider.dart` | `fcm_provider.dart` | `fcmServiceProvider.notifier.registerToken/unregisterToken` | ✓ WIRED | Line 81 (register) and 146 (unregister) |
| `fcm_provider.dart` | `PUT /students/{id}/fcm-token` | `dioClient.dio.put('/students/$studentId/fcm-token')` | ✓ WIRED | Lines 42-43, 63, 84-85 |
| `notification_handler_provider.dart` | `notification_routes.dart` | `NotificationRouter.routeFor(data)` | ✓ WIRED | Lines 83, 96, 106 |
| `notification_handler_provider.dart` | GoRouter | `router.go(targetPath)` | ✓ WIRED | Lines 84, 98, 111 |
| `main.dart` | `notification_handler_provider.dart` | `notificationHandlerProvider.notifier.initialize(context)` | ✓ WIRED | Lines 63-64 via addPostFrameCallback |
| `main.py` | `notifications/services.py` | `init_firebase()` in lifespan | ✓ WIRED | Lines 53-54 |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|-------------------|--------|
| `services.py` | `tokens` | `select(FcmToken).where(student_id)` | Yes — real DB query | ✓ FLOWING |
| `notification_handler_provider.dart` | `message.data` | Firebase SDK stream (`onMessage`) | Yes — Firebase delivers real payload | ✓ FLOWING |
| `notification_routes.dart` | `data['event']` | Notification payload from backend | Yes — derived from NotificationEvent enum values set in services.py | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Backend notification tests pass | `pytest tests/test_notifications.py -v` | 8 passed in 0.09s | ✓ PASS |
| Python imports resolve correctly | `python -c "from src.features.notifications.services import ..."` | "service OK" | ✓ PASS |
| Dart static analysis passes | `dart analyze` (5 notification files) | "No issues found!" | ✓ PASS |
| Generated .g.dart files exist | `ls mobile/lib/core/providers/*.g.dart` | Both fcm_provider.g.dart and notification_handler_provider.g.dart exist | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| FCM-01 | Plan 02 | Flutter registra FCM token no login e envia ao backend | ✓ SATISFIED | `fcm_provider.dart:33` registerToken called from `auth_provider.dart:81` after login |
| FCM-02 | Plan 01 | Backend armazena/atualiza FCM tokens por dispositivo | ✓ SATISFIED | `students/controllers.py:246-285` PUT endpoint with upsert logic, unique constraint |
| FCM-03 | Plan 01, 03 | Notificação push enviada quando documento fica pronto | ✓ SATISFIED | `documents/controllers.py:150-160` triggers notification on status="ready" |
| FCM-04 | Plan 01, 03 | Notificação push enviada quando matrícula é confirmada | ✓ SATISFIED | `enrollment/controllers.py:140-150` triggers after confirm_enrollment |
| FCM-05 | Plan 01, 03 | Notificação push enviada quando agendamento é confirmado | ✓ SATISFIED | `appointments/controllers.py:138-148` triggers after book_appointment |
| FCM-06 | Plan 01 | Notificação push enviada para nova mensagem de chat | ⚠️ EXCLUDED (D-10) | User decision: "chat_reply event explicitly excluded — interaction with bot is real-time, push would be redundant" |
| FCM-07 | Plan 04 | Notificação push exibida na barra de notificações (foreground + background) | ✓ SATISFIED | Background: `firebaseMessagingBackgroundHandler` + notification field in payload. Foreground: snackbar in `_handleForegroundMessage` |
| FCM-08 | Plan 04 | Tap na notificação navega para a tela relevante no app | ✓ SATISFIED | `_handleNotificationTap` + `_checkInitialMessage` + `NotificationRouter.routeFor` maps events to routes |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | — | — | No anti-patterns found |

No TODO/FIXME/placeholder comments, no empty returns, no hardcoded empty data. All implementations are substantive.

### Human Verification Required

#### 1. Background Push Notification Display

**Test:** Send a push notification while app is in background (e.g., staff marks document as "ready")
**Expected:** System notification appears in phone notification bar with title "Documento pronto" and body containing document type
**Why human:** Requires running Android device with Firebase project configured, actual backend running, and real FCM message delivery

#### 2. Foreground Snackbar and Navigation

**Test:** With app open on home screen, trigger notification (document ready). Then repeat while on documents screen.
**Expected:** On home: floating snackbar with "Ver" action appears, tapping navigates to documents. On documents: snackbar suppressed, data refreshes.
**Why human:** Requires live Flutter app with Firebase connection to verify real-time UI behavior

#### 3. Cold Start Deep-Link Navigation

**Test:** Kill app completely. Send push notification. Tap notification from system tray.
**Expected:** App launches, performs auth check, then navigates to the relevant screen (documents/home/support)
**Why human:** Requires device-level testing of terminated state and Firebase `getInitialMessage()` behavior

#### 4. Token Registration Flow on Real Device

**Test:** Login as student on physical/emulator device with Firebase configured
**Expected:** Notification permission dialog appears; if granted, backend receives PUT /students/{id}/fcm-token with valid token string
**Why human:** Requires Firebase project with google-services.json and actual FCM token generation

### Gaps Summary

No code gaps found. All 7 observable truths are verified at the code level (existence, substantive implementation, wiring, and data flow).

**FCM-06 (chat_reply)** is excluded by explicit user decision (D-10 in CONTEXT.md) with clear rationale: "interaction with bot is real-time, push would be redundant." The ROADMAP success criteria #2 still references "new chat message received" which creates a documentation inconsistency, but the code correctly implements the user's final decision. This is not an actionable gap — it's a ROADMAP wording that wasn't updated after the D-10 decision.

**Remaining verification:** 4 items require human testing on a real device with Firebase configured. All automated verification passes (unit tests, static analysis, import checks, wiring traces).

---

_Verified: 2026-05-09T04:10:00Z_
_Verifier: the agent (gsd-verifier)_
