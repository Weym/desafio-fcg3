---
phase: 22-fcm-push-notifications
reviewed: 2026-05-09T22:00:00Z
depth: standard
files_reviewed: 20
files_reviewed_list:
  - backend/src/features/notifications/__init__.py
  - backend/src/features/notifications/services.py
  - backend/src/features/notifications/schemas.py
  - backend/src/features/students/controllers.py
  - backend/src/main.py
  - backend/src/features/documents/controllers.py
  - backend/src/features/enrollment/controllers.py
  - backend/src/features/appointments/controllers.py
  - backend/tests/test_notifications.py
  - mobile/pubspec.yaml
  - mobile/lib/main.dart
  - mobile/lib/core/providers/fcm_provider.dart
  - mobile/lib/core/providers/fcm_provider.g.dart
  - mobile/lib/core/providers/notification_handler_provider.dart
  - mobile/lib/core/providers/notification_handler_provider.g.dart
  - mobile/lib/core/providers/notification_routes.dart
  - mobile/lib/features/auth/providers/auth_provider.dart
  - mobile/android/app/build.gradle.kts
  - mobile/android/build.gradle.kts
  - mobile/android/app/src/main/AndroidManifest.xml
findings:
  critical: 1
  warning: 4
  info: 3
  total: 8
status: issues_found
---

# Phase 22: Code Review Report

**Reviewed:** 2026-05-09T22:00:00Z
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

Phase 22 implements FCM push notifications across backend and Flutter mobile:
- Backend: `NotificationService` with fire-and-forget sending, invalid token cleanup, event helpers, and FCM token CRUD endpoints on the students router.
- Flutter: Firebase initialization, `FcmService` for token registration/unregistration, `NotificationHandler` for foreground/background/cold-start message handling, deep-link routing.

**Overall assessment:** Solid implementation with good patterns (fire-and-forget, graceful degradation, IDOR checks). However, there is one critical issue with database session management in background tasks that can cause silent failures or connection leaks, and several warnings around race conditions and missing error handling.

## Critical Issues

### CR-01: Background task DB session not properly consumed from async generator

**File:** `backend/src/features/documents/controllers.py:151-158`
**Also affects:** `backend/src/features/enrollment/controllers.py:141-148`, `backend/src/features/appointments/controllers.py:139-146`

**Issue:** The background notification tasks use `async for fresh_db in get_db_session()` to obtain a database session. `get_db_session()` is an `AsyncGenerator` that yields exactly once. While this works functionally, the pattern has a subtle problem: if an **unhandled exception** occurs inside the `try` block (before or after the notification call), the `finally: await fresh_db.close()` attempts to close the session, but the async generator's cleanup (the `async with` context manager in `get_db_session`) may not complete properly because the generator is never fully exhausted or closed. More critically, calling `fresh_db.close()` manually is **redundant and potentially conflicting** with the `async with` block in `get_db_session()` which already handles session cleanup.

Additionally, the `asyncio.create_task` pattern means any exceptions in `_send_notification` are silently swallowed (unobserved task exceptions) — if the generator raises during session creation, there's no logging.

**Fix:**
```python
# In documents/controllers.py (and similarly in enrollment, appointments)
if data.status == "ready":
    async def _send_notification():
        async for fresh_db in get_db_session():
            try:
                await notification_service.notify_document_ready(
                    fresh_db, document.student_id, document.type, document.id
                )
            except Exception as exc:
                import logging
                logging.getLogger(__name__).error(
                    "FCM notification failed in background task: %s", exc
                )
            # Remove `finally: await fresh_db.close()` — the async generator
            # context manager handles cleanup automatically

    asyncio.create_task(_send_notification())
```

The `finally: await fresh_db.close()` should be removed. The `async with async_session() as session` in `get_db_session()` already closes the session when the generator finishes. Manually closing it creates a double-close scenario. Also, add error logging since `create_task` swallows exceptions.

## Warnings

### WR-01: Race condition — notification uses stale `user.id` after `db.commit()`

**File:** `backend/src/features/enrollment/controllers.py:144-145`

**Issue:** In `confirm_enrollment`, the background task captures `user.id` from the request context. While `user.id` is a UUID (immutable value), the `enrollment_id` parameter comes from the URL path — this is safe. However, if the `confirm_enrollment` service internally changes the enrollment's `student_id` (unlikely but architecturally possible), the notification would go to the wrong student. More importantly, `result.id` in appointments controller (line 144) reads from the Pydantic response model which is fine, but the pattern of accessing ORM objects after `db.commit()` in the enrollment controller could trigger lazy-load issues if `result` were an ORM instance.

**Fix:** Ensure all data needed by the background task is captured as simple values (UUIDs, strings) before `db.commit()`, not as ORM model references. Current code appears safe since `user.id` and `enrollment_id` are path/context values, but document the constraint:

```python
# Capture values before commit to avoid lazy-load issues
student_id_for_notification = user.id
enrollment_id_for_notification = enrollment_id
await db.commit()

async def _send_notification():
    ...
    await notification_service.notify_enrollment_confirmed(
        fresh_db, student_id_for_notification, enrollment_id_for_notification
    )
```

### WR-02: `_onTokenRefresh` is `async` but declared as `void` — exceptions silently lost

**File:** `mobile/lib/core/providers/fcm_provider.dart:76`

**Issue:** `_onTokenRefresh` is declared as `void _onTokenRefresh(String newToken) async`. Making a callback `async` with a `void` return type means any thrown exceptions are silently swallowed — they won't appear in error logs or crash reports. The `.listen()` call on line 16 passes this as a synchronous callback to the stream, so the `Future` returned by the async body is dropped.

**Fix:** This is intentional fire-and-forget behavior (the catch block on line 88 handles errors), so the current code is functionally correct. However, for defensive coding, wrap the entire body in try-catch to guarantee no unhandled exception propagates:

```dart
void _onTokenRefresh(String newToken) async {
  try {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    if (!authState.user.isStudent) return;

    final dioClient = ref.read(dioClientProvider);
    await dioClient.dio.put(
      '/students/${authState.user.id}/fcm-token',
      data: {'token': newToken},
    );
  } catch (e) {
    developer.log(
      'FCM token refresh registration failed: $e',
      name: 'FcmService',
    );
  }
}
```

This is already the case — the existing code is actually fine. Downgrading to info.

### WR-03: Cold-start deep-link uses arbitrary `Future.delayed` timing

**File:** `mobile/lib/core/providers/notification_handler_provider.dart:110`

**Issue:** `await Future.delayed(const Duration(milliseconds: 500))` before navigating on cold start is a fragile timing hack. If the router isn't fully initialized within 500ms (slow device, heavy app startup), navigation will fail silently. If the router initializes faster, there's an unnecessary 500ms delay for the user.

**Fix:** Instead of an arbitrary delay, use the router's initialization state or a `WidgetsBinding.instance.addPostFrameCallback` to ensure navigation happens after the frame is rendered:

```dart
Future<void> _checkInitialMessage() async {
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    _pendingDeepLink = NotificationRouter.routeFor(initialMessage.data);
    // Let auth flow consume it via consumePendingDeepLink() instead of
    // navigating directly — safer pattern already used in auth_provider.dart
  }
}
```

The `consumePendingDeepLink()` pattern in `auth_provider.dart` (line 85-93) already handles this correctly for the expired-JWT case. The cold-start case at line 110-111 duplicates navigation logic and could conflict with the auth redirect.

### WR-04: FCM token max_length=255 may be insufficient for future token formats

**File:** `backend/src/features/notifications/schemas.py:19`
**Also:** `backend/src/features/auth/models.py:128`

**Issue:** FCM registration tokens are currently ~163 characters, but Google does not guarantee a maximum length. The FCM documentation states tokens can be up to 4096 bytes. Using `max_length=255` in both the Pydantic schema and the database column (`String(255)`) could silently truncate tokens in the future, causing delivery failures that are very hard to debug.

**Fix:**
```python
# schemas.py
token: str = Field(..., min_length=1, max_length=4096, description="FCM device token")

# models.py — migrate column to Text or String(4096)
token: Mapped[str] = mapped_column(String(4096), nullable=False)
```

## Info

### IN-01: `registerToken` called without `await` — fire-and-forget is intentional but undocumented

**File:** `mobile/lib/features/auth/providers/auth_provider.dart:81`

**Issue:** `ref.read(fcmServiceProvider.notifier).registerToken(user.id)` is called without `await`. This means login completes before FCM registration finishes. If registration fails, the user won't know. This is intentional fire-and-forget (per D-12), but a code comment would clarify intent for future maintainers.

**Fix:** Add comment:
```dart
// Fire-and-forget (D-12) — don't block login flow for FCM registration
ref.read(fcmServiceProvider.notifier).registerToken(user.id);
```

### IN-02: `notification_handler_provider.dart` uses `context.mounted` check only for foreground messages

**File:** `mobile/lib/core/providers/notification_handler_provider.dart:43`

**Issue:** The `context.mounted` check is correctly applied for the foreground message listener callback (line 43), but the `initialize()` method itself doesn't verify context is still valid when accessing `ScaffoldMessenger.maybeOf(context)` (line 74). Since `addPostFrameCallback` in `main.dart` already checks `context.mounted` before calling `initialize()`, and the stream listener also checks, this is safe. Good defensive coding.

**Fix:** No action needed — noting as positive pattern.

### IN-03: Background handler is minimal but correctly structured

**File:** `mobile/lib/core/providers/notification_handler_provider.dart:17-25`

**Issue:** The `firebaseMessagingBackgroundHandler` function only logs the message ID. Per D-16, the system displays the notification automatically via the `notification` field in the FCM payload. This is correct — no additional handling needed for background messages in MVP. The `@pragma('vm:entry-point')` annotation ensures the function isn't tree-shaken.

**Fix:** No action needed — noting as correctly implemented.

---

_Reviewed: 2026-05-09T22:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
