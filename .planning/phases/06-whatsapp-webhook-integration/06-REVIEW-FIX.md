---
phase: 06
fixed_at: 2026-04-30T19:15:00Z
review_path: .planning/phases/06-whatsapp-webhook-integration/06-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 06: Code Review Fix Report

**Fixed at:** 2026-04-30T19:15:00Z
**Source review:** .planning/phases/06-whatsapp-webhook-integration/06-REVIEW.md
**Iteration:** 1

**Summary:**

- Findings in scope: 4
- Fixed: 4
- Skipped: 0

## Fixed Issues

### CR-01: Empty `whatsapp_app_secret` default allows signature bypass

**Files modified:** `backend/src/infrastructure/config.py`
**Commit:** 112ac2f
**Applied fix:** Removed `default=""` from `whatsapp_app_secret` Field and added `min_length=1` constraint. The field is now required with no default — Pydantic will raise a validation error at startup if the environment variable is not set, preventing the silent degradation to an insecure empty-key HMAC.

### CR-02: Inconsistent transaction boundaries in verification flow

**Files modified:** `backend/src/features/webhook/service.py`
**Commit:** a280d62
**Applied fix:** Removed all internal `await db.commit()` calls from `_handle_awaiting_email` and `_handle_awaiting_code` methods. The service now only uses `flush()` to stage changes, and the router's single `await db.commit()` at line 161 handles committing for ALL verification flow branches. This eliminates the inconsistency where some paths committed internally while others relied on the caller.

### HI-01: Unbounded `_session_locks` dictionary — memory leak

**Files modified:** `backend/src/features/webhook/background.py`
**Commit:** d5a1777
**Applied fix:** Added lock cleanup after the `async with lock:` block exits. After processing completes, the lock is removed from `_session_locks` if no other coroutine is currently holding it (`not lock.locked()`). Uses `pop(lock_key, None)` for safe removal. This prevents unbounded growth of the dictionary over the server's lifetime while remaining safe for concurrent access.

### HI-02: `save_message` rollback on IntegrityError corrupts transaction state

**Files modified:** `backend/src/features/webhook/service.py`
**Commit:** 049dabf
**Applied fix:** Replaced `await db.rollback()` with `async with db.begin_nested():` (SAVEPOINT) wrapping the flush and updated_at touch. On IntegrityError, only the savepoint is rolled back — not the entire transaction. This preserves any prior session state changes (from `get_or_create_session` or other operations) that were already flushed in the same transaction. The explicit `await db.rollback()` was removed since SQLAlchemy's `begin_nested()` context manager handles savepoint rollback automatically on exception.

---

_Fixed: 2026-04-30T19:15:00Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
