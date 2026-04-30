---
phase: 06-whatsapp-webhook-integration
plan: 04
subsystem: testing
tags: [testing, pytest, webhook, hmac, dedup, media, verification, background-task, chat-visibility, service-token]

# Dependency graph
requires:
  - phase: 06-whatsapp-webhook-integration
    plan: 01
    provides: "Webhook router, WhatsAppClient, WebhookService, verification state machine"
  - phase: 06-whatsapp-webhook-integration
    plan: 02
    provides: "Background task with retry/fallback, per-session lock, session lifecycle"
  - phase: 06-whatsapp-webhook-integration
    plan: 03
    provides: "Chat visibility endpoints (list sessions, messages, action logs)"
  - phase: 02-authentication
    provides: "JWT service (issue_access), require_service_token, OTP service"
provides:
  - "TEST-04: HMAC validation rejects unsigned/wrong-signature requests"
  - "TEST-04: Duplicate wamid produces only one chat_message row"
  - "TEST-04: Media messages receive standard Portuguese response without agent"
  - "TEST-05: X-Service-Token middleware rejects missing/invalid tokens"
  - "TEST-05: timing-safe comparison via hmac.compare_digest verified"
  - "Comprehensive unit tests: phone normalization, verification state machine, background task, session lifecycle, WhatsApp client"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns: [patch-webhook-db-fixture, sqlite-unique-index-for-dedup-test, mock-httpx-for-background]

key-files:
  created:
    - backend/tests/features/__init__.py
    - backend/tests/features/webhook/__init__.py
    - backend/tests/features/webhook/conftest.py
    - backend/tests/features/webhook/test_webhook_hmac.py
    - backend/tests/features/webhook/test_webhook_dedup.py
    - backend/tests/features/webhook/test_webhook_media.py
    - backend/tests/features/webhook/test_phone_normalization.py
    - backend/tests/features/webhook/test_verification_state.py
    - backend/tests/features/webhook/test_background_task.py
    - backend/tests/features/webhook/test_whatsapp_client.py
    - backend/tests/features/webhook/test_session_lifecycle.py
    - backend/tests/features/chat/__init__.py
    - backend/tests/features/chat/conftest.py
    - backend/tests/features/chat/test_chat_visibility.py
    - backend/tests/middleware/__init__.py
    - backend/tests/middleware/test_service_token.py
  modified:
    - backend/tests/conftest.py

key-decisions:
  - "Included chat_sessions and chat_messages in SQLite test tables (they have no JSONB/Vector columns)"
  - "Created patch_webhook_db fixture to redirect webhook's direct async_session() to test DB"
  - "Used SQLite CREATE UNIQUE INDEX for dedup tests (mirrors PostgreSQL partial unique index)"
  - "Mocked httpx responses with MagicMock (not AsyncMock) because httpx.Response.json() is sync"
  - "Used jwt_service.issue_access() for test JWT creation with real session DB rows"

patterns-established:
  - "patch_webhook_db: asynccontextmanager fixture patching router's async_session for integration tests"
  - "MagicMock for httpx Response objects (sync .json() method)"
  - "Per-test SQLite unique index creation for constraint-dependent tests"

requirements-completed: [TEST-04, TEST-05]

# Metrics
duration: 13min
completed: 2026-04-30
---

# Phase 6 Plan 04: Comprehensive Test Suite Summary

**81 tests covering HMAC validation, message deduplication, media routing, verification state machine, background task retry/fallback, session lifecycle, chat visibility, and X-Service-Token middleware with mocked external HTTP and real SQLite test DB**

## Performance

- **Duration:** 13 min
- **Started:** 2026-04-30T16:54:21Z
- **Completed:** 2026-04-30T17:07:00Z
- **Tasks:** 2
- **Files modified:** 17

## Accomplishments
- TEST-04 complete: HMAC validation (unsigned→403, wrong sig→403, valid→200), deduplication (same wamid=1 row), all 6 media types tested with exact Portuguese strings
- TEST-05 complete: X-Service-Token middleware rejects missing/invalid tokens, accepts valid, uses timing-safe comparison
- Verification state machine fully tested through all transitions and error paths (9 tests)
- Background task retry/fallback logic fully tested with mocked httpx (8 tests)
- WhatsApp client retry logic tested (5 send tests + 2 signature tests)
- Session lifecycle: active reuse, close, new unverified session creation (7 tests)
- Chat visibility: staff access (200), student rejection (403), filters, 404 handling (8 tests)
- Service token: unit + integration tests (9 tests)
- Updated conftest.py to include chat tables in SQLite (enabling DB-level webhook tests)

## Task Commits

Each task was committed atomically:

1. **Task 1: TEST-04 — Webhook HMAC, deduplication, media type, phone normalization** - `0fa1547` (test)
2. **Task 2: TEST-05 — Service token, verification, background task, session, chat visibility** - `97fe4b6` (test)

## Files Created/Modified
- `backend/tests/features/webhook/conftest.py` - Fixtures: HMAC computation, payload factories, patch_webhook_db, test_student, sessions
- `backend/tests/features/webhook/test_webhook_hmac.py` - HMAC unit + integration tests (10 tests)
- `backend/tests/features/webhook/test_webhook_dedup.py` - Deduplication with SQLite unique index (4 tests)
- `backend/tests/features/webhook/test_webhook_media.py` - Media responses unit + integration (14 tests)
- `backend/tests/features/webhook/test_phone_normalization.py` - Phone lookup + unknown phone (5 tests)
- `backend/tests/features/webhook/test_verification_state.py` - Full state machine lifecycle (9 tests)
- `backend/tests/features/webhook/test_background_task.py` - AI service retry, fallback, done_callback (8 tests)
- `backend/tests/features/webhook/test_whatsapp_client.py` - WhatsApp client retry + signature (7 tests)
- `backend/tests/features/webhook/test_session_lifecycle.py` - Session reuse/close/create (7 tests)
- `backend/tests/features/chat/conftest.py` - Chat test data fixtures (student, staff, sessions, messages)
- `backend/tests/features/chat/test_chat_visibility.py` - Staff endpoints + authorization (8 tests)
- `backend/tests/middleware/test_service_token.py` - Service token unit + integration (9 tests)
- `backend/tests/conftest.py` - Updated _SQLITE_SAFE_TABLES to include chat_sessions/chat_messages

## Decisions Made
- **chat_sessions/chat_messages included in SQLite:** These tables have no JSONB/Vector columns. Only mcp_action_logs and knowledge_base_chunks remain excluded.
- **patch_webhook_db fixture:** The webhook handler uses `async_session()` directly (not DI), so a contextmanager patch is needed to redirect to the test session.
- **SQLite unique index for dedup test:** PostgreSQL partial unique index doesn't exist in SQLite, so a regular unique index is created per-test to verify IntegrityError dedup logic.
- **MagicMock for httpx Response:** httpx Response.json() is synchronous; using AsyncMock would return coroutines instead of dicts, causing test failures.
- **jwt_service.issue_access() for test tokens:** Creates real JWT + real session row in test DB so get_current_user validates successfully.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated conftest.py to include chat tables in SQLite**
- **Found during:** Task 1
- **Issue:** `_SQLITE_SAFE_TABLES` excluded chat_sessions and chat_messages unnecessarily. Without these tables, webhook integration tests cannot operate on the test DB.
- **Fix:** Changed exclusion list from `("chat_sessions", "chat_messages", "mcp_action_logs", "knowledge_base_chunks")` to `("mcp_action_logs", "knowledge_base_chunks")`. Verified chat tables have no JSONB/Vector columns.
- **Files modified:** backend/tests/conftest.py
- **Commit:** 0fa1547

**2. [Rule 3 - Blocking] Created patch_webhook_db fixture for async_session redirect**
- **Found during:** Task 1
- **Issue:** Webhook handler uses `async with async_session() as db:` (CRITICAL-4 pattern), bypassing FastAPI DI. Integration tests using `client` fixture couldn't redirect the DB session.
- **Fix:** Created `patch_webhook_db` fixture that patches `src.features.webhook.router.async_session` with a context manager yielding the test session.
- **Files modified:** backend/tests/features/webhook/conftest.py
- **Commit:** 0fa1547

**3. [Rule 1 - Bug] Used MagicMock for httpx Response objects**
- **Found during:** Task 2
- **Issue:** AsyncMock for httpx Response made `.json()` return a coroutine. The background task code calls `response.json()` synchronously (httpx pattern), causing `'coroutine' object has no attribute 'get'` errors.
- **Fix:** Used MagicMock instead of AsyncMock for mock response objects.
- **Files modified:** backend/tests/features/webhook/test_background_task.py
- **Commit:** 97fe4b6

---

**Total deviations:** 3 auto-fixed (2 blocking, 1 bug)
**Impact on plan:** All fixes required for tests to pass. No scope creep.

## Issues Encountered
None — all 81 tests pass after the deviations were resolved.

## Known Stubs
None — this is a test-only plan with no production stubs.

## Next Phase Readiness
- Phase 6 is COMPLETE: all 4 plans executed (webhook handler, background task, chat visibility, test suite)
- 81 new tests provide comprehensive coverage of webhook, chat, and middleware security
- TEST-04 and TEST-05 requirements satisfied per D-14/D-16

---
*Phase: 06-whatsapp-webhook-integration*
*Completed: 2026-04-30*

## Self-Check: PASSED

All 16 created files verified on disk. Both task commits (0fa1547, 97fe4b6) verified in git log. 81 tests passing.
