---
phase: 06-whatsapp-webhook-integration
plan: 01
subsystem: webhook
tags: [whatsapp, webhook, hmac, fastapi, asyncio, verification-state-machine]

# Dependency graph
requires:
  - phase: 01-infrastructure-schema
    provides: "DB session factory, Alembic migration chain, ChatSession/ChatMessage models"
  - phase: 02-authentication
    provides: "OTP service (generate_and_send_code, verify_code_hash), Student model, Settings"
provides:
  - "GET /webhook/whatsapp challenge endpoint (WH-01)"
  - "POST /webhook/whatsapp with HMAC-SHA256 validation (WH-02)"
  - "WhatsAppClient with send_text_message and validate_signature"
  - "Verification state machine: unverified→awaiting_email→awaiting_code→verified"
  - "Media type response routing with hardcoded Portuguese messages"
  - "Message deduplication by whatsapp_message_id"
  - "Alembic migration 010a adding verification_state column"
affects: [06-02, 06-03, 06-04]

# Tech tracking
tech-stack:
  added: [httpx (WhatsApp client), hmac (HMAC-SHA256)]
  patterns: [background-task-with-done-callback, per-session-db-scope, signature-before-parse]

key-files:
  created:
    - backend/src/infrastructure/whatsapp_client.py
    - backend/src/features/webhook/router.py
    - backend/src/features/webhook/service.py
    - backend/src/features/webhook/schemas.py
    - backend/src/features/webhook/dependencies.py
    - backend/src/features/webhook/__init__.py
    - backend/alembic/versions/010_add_verification_state_to_chat_sessions.py
  modified:
    - backend/src/infrastructure/config.py
    - backend/src/features/chat/models.py
    - backend/src/main.py
    - .env.example

key-decisions:
  - "Settings use config.py (not settings.py) matching Phase 2 convention"
  - "Partial unique index on whatsapp_message_id WHERE NOT NULL for dedup"
  - "WhatsApp client uses httpx.AsyncClient singleton with 10s timeout"
  - "Verification state machine in WebhookService, not in router"

patterns-established:
  - "HMAC-before-parse: raw_body read first, signature validated before JSON parsing"
  - "Background-task-callback: asyncio.create_task + add_done_callback for error visibility"
  - "Own-DB-session: background tasks open their own async_session, not request-scoped"

requirements-completed: [WH-01, WH-02, WH-03, WH-04]

# Metrics
duration: 6min
completed: 2026-04-30
---

# Phase 6 Plan 01: Webhook Handler Core Summary

**HMAC-validated WhatsApp webhook with challenge endpoint, verification state machine, media routing, and message deduplication via WhatsAppClient + WebhookService**

## Performance

- **Duration:** 6 min
- **Started:** 2026-04-30T16:34:04Z
- **Completed:** 2026-04-30T16:40:00Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments
- WhatsApp Business Cloud API client encapsulating all Graph API details with retry logic
- HMAC-SHA256 webhook signature validation reading raw body before any JSON parsing (CRITICAL-1)
- Verification state machine gating agent access: unverified→awaiting_email→awaiting_code→verified
- Media type routing with exact Portuguese responses from docs/chatbot.md (6 media types)
- Message deduplication via partial unique index on whatsapp_message_id
- Session close via "sair"/"encerrar" keywords (D-11)
- Alembic migration 010a adding verification_state to chat_sessions

## Task Commits

Each task was committed atomically:

1. **Task 1: WhatsApp client + settings + Alembic migration** - `3480c6d` (feat)
2. **Task 2: Webhook handler endpoints + service + verification state machine** - `5951425` (feat)

## Files Created/Modified
- `backend/src/infrastructure/whatsapp_client.py` - WhatsApp Graph API client with send_text_message() and validate_signature()
- `backend/src/features/webhook/router.py` - GET and POST /webhook/whatsapp endpoints
- `backend/src/features/webhook/service.py` - Webhook business logic with verification state machine
- `backend/src/features/webhook/schemas.py` - Pydantic schemas for WhatsApp webhook payload parsing
- `backend/src/features/webhook/dependencies.py` - Singleton factories for WhatsAppClient and WebhookService
- `backend/src/features/webhook/__init__.py` - Feature package init
- `backend/alembic/versions/010_add_verification_state_to_chat_sessions.py` - Migration adding verification_state + wamid unique index
- `backend/src/infrastructure/config.py` - Added whatsapp_api_version and ai_service_url settings
- `backend/src/features/chat/models.py` - Added verification_state column to ChatSession model
- `backend/src/main.py` - Registered webhook router at /api/v1
- `.env.example` - Added WHATSAPP_API_VERSION and AI_SERVICE_URL

## Decisions Made
- **Settings module is config.py:** Phase 2 established config.py as the settings module (not settings.py as the plan referenced). Followed existing convention.
- **Partial unique index for dedup:** Used `CREATE UNIQUE INDEX ... WHERE whatsapp_message_id IS NOT NULL` instead of a full unique constraint, since assistant/system messages don't have a wamid.
- **Verification flow reuses existing OTP service:** Instead of making HTTP calls to auth endpoints, directly imported and called `otp_service.generate_and_send_code()` and `otp_service.verify_code_hash()` for tighter integration and fewer network hops.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added partial unique index for message deduplication**
- **Found during:** Task 2 (webhook handler implementation)
- **Issue:** The plan specified deduplication by whatsapp_message_id IntegrityError, but no unique constraint existed on the column. Without it, duplicate messages would silently be accepted.
- **Fix:** Added partial unique index `uq_chat_messages_wamid` on `chat_messages(whatsapp_message_id) WHERE whatsapp_message_id IS NOT NULL` to migration 010a.
- **Files modified:** backend/alembic/versions/010_add_verification_state_to_chat_sessions.py
- **Verification:** Migration script reviewed, index creation confirmed
- **Committed in:** 5951425 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** Essential for deduplication correctness. No scope creep.

## Issues Encountered
None — all imports verified, module chain validated.

## User Setup Required

External WhatsApp Business Cloud API configuration required. The plan's `user_setup` section specifies:
- `WHATSAPP_TOKEN`: Meta Developer Dashboard → WhatsApp → API Setup → Temporary access token
- `WHATSAPP_APP_SECRET`: Meta Developer Dashboard → App Settings → Basic → App Secret
- `WHATSAPP_PHONE_NUMBER_ID`: Meta Developer Dashboard → WhatsApp → API Setup → Phone number ID
- `WHATSAPP_WEBHOOK_VERIFY_TOKEN`: Self-defined secret string for webhook verification challenge
- `WHATSAPP_API_VERSION`: Self-defined, default v18.0
- Dashboard: Configure webhook URL in Meta Developer Dashboard → WhatsApp → Configuration → Webhook

## Known Stubs

| Stub | File | Line | Reason |
|------|------|------|--------|
| `process_verified_message()` placeholder | `backend/src/features/webhook/router.py` | ~48 | Plan 02 implements AI service integration with retry logic |

## Next Phase Readiness
- Webhook handler core complete, ready for Plan 02 (background task + AI service integration)
- Verification state machine fully implemented and gates agent access
- WhatsApp client ready for use by background task processing
- All webhook endpoints registered and importable

---
*Phase: 06-whatsapp-webhook-integration*
*Completed: 2026-04-30*

## Self-Check: PASSED

All 7 created files verified on disk. Both task commits (3480c6d, 5951425) verified in git log.
