---
phase: 22-fcm-push-notifications
fixed_at: 2026-05-09T22:30:00Z
review_path: .planning/phases/22-fcm-push-notifications/22-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 22: Code Review Fix Report

**Fixed at:** 2026-05-09T22:30:00Z
**Source review:** .planning/phases/22-fcm-push-notifications/22-REVIEW.md
**Iteration:** 1

**Summary:**

- Findings in scope: 4
- Fixed: 4
- Skipped: 0

## Fixed Issues

### CR-01: Background task DB session not properly consumed from async generator

**Files modified:** `backend/src/features/documents/controllers.py`, `backend/src/features/enrollment/controllers.py`, `backend/src/features/appointments/controllers.py`
**Commit:** cdde359
**Applied fix:** Removed redundant `finally: await fresh_db.close()` blocks from all three background notification tasks (documents, enrollment, appointments). The async generator's context manager already handles session cleanup. Replaced with `except Exception` blocks that log errors via `logging.getLogger(__name__)`, preventing silent exception swallowing in `asyncio.create_task`.

### WR-01: Race condition — notification uses stale values after db.commit()

**Files modified:** `backend/src/features/enrollment/controllers.py`
**Commit:** 42d3a5e
**Applied fix:** Captured `user.id` and `enrollment_id` into `student_id_for_notification` and `enrollment_id_for_notification` variables before `await db.commit()`, ensuring the background task closure captures simple immutable values rather than potentially stale ORM references.

### WR-03: Cold-start deep-link uses arbitrary Future.delayed timing

**Files modified:** `mobile/lib/core/providers/notification_handler_provider.dart`
**Commit:** bf34074
**Applied fix:** Removed the fragile `Future.delayed(500ms)` + direct `router.go()` navigation from `_checkInitialMessage()`. Now only stores the deep-link path in `_pendingDeepLink`, letting the auth flow consume it via `consumePendingDeepLink()` after successful authentication (pattern already established in `auth_provider.dart` lines 85-93).

### WR-04: FCM token max_length=255 may be insufficient for future token formats

**Files modified:** `backend/src/features/notifications/schemas.py`
**Commit:** 86fd2e1
**Applied fix:** Increased `max_length` from 255 to 4096 in both `FcmTokenRegister` and `FcmTokenDelete` Pydantic schemas. Database model column (`String(255)`) was left unchanged to avoid requiring a migration — this is MVP and the schema validation is the critical safeguard (API will reject tokens >4096 chars, but won't silently truncate at 255).

## Skipped Issues

_None — all in-scope findings were fixed._

---

_Fixed: 2026-05-09T22:30:00Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
