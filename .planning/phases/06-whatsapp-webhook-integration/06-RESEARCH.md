# Phase 6 Research — WhatsApp Webhook & Integration

**Phase:** 06-whatsapp-webhook-integration
**Researched:** 2026-04-23 (re-verified 2026-04-23)
**Discovery Level:** Level 1 (Quick Verification)
**Confidence:** HIGH

---

## Research Summary

Phase 6 uses well-established patterns with no novel libraries. All technologies are already specified in the project research (`.planning/research/`). This phase-level research verifies specific implementation details for the integration layer.

---

## WhatsApp Business Cloud API — Webhook

### Webhook Verification (GET)
- Meta sends `hub.mode=subscribe`, `hub.verify_token`, `hub.challenge`
- Respond with `hub.challenge` value as plain text if `hub.verify_token` matches
- Return 403 if token mismatch

### Incoming Message Payload (POST)
- Body structure: `{ "object": "whatsapp_business_account", "entry": [{ "changes": [{ "value": { "messages": [...], "statuses": [...] } }] }] }`
- CRITICAL: `statuses` key indicates delivery receipts — must be filtered out (not messages)
- Message fields: `from` (phone number without +), `id` (wamid for dedup), `type`, `text.body` or media type object
- Media types: `audio`, `image`, `video`, `document`, `sticker`, `location`
- HMAC validation: `X-Hub-Signature-256: sha256=<hex>` using `WHATSAPP_APP_SECRET` against raw body bytes

### Sending Messages
- `POST https://graph.facebook.com/v18.0/{phone_number_id}/messages`
- Auth: `Authorization: Bearer {WHATSAPP_TOKEN}`
- Body: `{ "messaging_product": "whatsapp", "to": "5521999999999", "type": "text", "text": { "body": "..." } }`
- Graph API version should be configurable via env var (MINOR-2 from PITFALLS.md)

---

## pg_cron for Session Auto-Close (D-12)

### Docker Setup
- Requires custom Dockerfile extending `pgvector/pgvector:pg16`
- Install pg_cron via `apt-get install postgresql-16-cron` in Dockerfile
- Add to postgresql.conf: `shared_preload_libraries = 'pg_cron'`
- Configure: `cron.database_name = 'desafio_fcg3'` (match app DB name)
- After container starts: `CREATE EXTENSION pg_cron;`

### Session Auto-Close Job
```sql
SELECT cron.schedule(
    'close-inactive-sessions',
    '0 * * * *',  -- every hour
    $$UPDATE chat_sessions SET status = 'closed', ended_at = NOW() WHERE updated_at < NOW() - INTERVAL '24 hours' AND status = 'active'$$
);
```

### Docker Image Impact
- This is a Phase 1 infrastructure change — the Postgres Dockerfile must include pg_cron
- The Alembic migration adding the cron job belongs in Phase 6 (it's specific to chat session lifecycle)
- NOTE: pg_cron extension creation must happen AFTER pgvector extension (migration ordering)

---

## asyncio Background Task Pattern (Verification)

### Confirmed Pattern (CRITICAL-3 + CRITICAL-4)
```python
async def webhook_handler(request: Request):
    raw_body = await request.body()  # FIRST — before any parsing
    # ... validate HMAC, parse, save message ...
    
    task = asyncio.create_task(process_message(session_id, message_text))
    task.add_done_callback(_handle_task_result)  # ALWAYS
    
    return Response(status_code=200)

async def process_message(session_id: str, message_text: str):
    async with async_session_maker() as db:  # OWN session — not from request
        # ... process with AI service ...
```

### Per-Session Lock Pattern (MINOR-3)
```python
_session_locks: dict[str, asyncio.Lock] = {}

async def process_message(session_id: str, ...):
    lock = _session_locks.setdefault(session_id, asyncio.Lock())
    async with lock:
        # sequential processing per session
```

---

## Verification State Machine (D-01, D-02)

### States
- `unverified` → initial state for new sessions
- `awaiting_email` → bot asked for email, waiting for response
- `awaiting_code` → OTP sent, waiting for code input
- `verified` → identity confirmed, messages go to agent

### Transitions
```
unverified → awaiting_email (any first message triggers "Qual seu email?")
awaiting_email → awaiting_code (email found in students table → OTP sent)
awaiting_email → [no session] (email NOT found → friendly rejection, D-03)
awaiting_code → verified (correct OTP code)
awaiting_code → awaiting_code (wrong code, attempts < 3)
awaiting_code → awaiting_code (attempts = 3 → auto-new-code sent)
verified → unverified (session closed + new message → new session per D-13)
```

### Schema Change
- New column: `chat_sessions.verification_state VARCHAR(20) NOT NULL DEFAULT 'unverified'`
- New Alembic migration required (D-01)

---

## Key Implementation Decisions Verified

| Decision | Verified Pattern | Source |
|----------|-----------------|--------|
| HMAC before JSON parse | `await request.body()` first | PITFALLS CRITICAL-1 |
| Background task error handling | `add_done_callback` always | PITFALLS CRITICAL-3 |
| Own DB session in background | `async with async_session_maker()` | PITFALLS CRITICAL-4 |
| Deduplication | `whatsapp_message_id` UNIQUE or ON CONFLICT | PITFALLS MODERATE-1 |
| Per-session lock | `dict[str, asyncio.Lock]` | PITFALLS MINOR-3 |
| Graph API version | Env var `WHATSAPP_API_VERSION` | PITFALLS MINOR-2 |
| pg_cron setup | `shared_preload_libraries` + Dockerfile | pg_cron docs |

---

## Env Vars Needed for Phase 6

| Var | Purpose | Source |
|-----|---------|--------|
| `WHATSAPP_TOKEN` | Graph API Bearer token | Meta Dashboard |
| `WHATSAPP_APP_SECRET` | HMAC validation secret | Meta Dashboard |
| `WHATSAPP_PHONE_NUMBER_ID` | Sending messages | Meta Dashboard |
| `WHATSAPP_VERIFY_TOKEN` | Webhook challenge verification | Self-defined |
| `WHATSAPP_API_VERSION` | Graph API version (default: v18.0) | Self-defined |
| `AI_SERVICE_URL` | LangChain service endpoint (http://langchain-service:8001) | Docker internal |

---

---

## Validation Architecture

### Test Framework
- **Framework:** pytest 8.x + pytest-asyncio + httpx AsyncClient (same as Phase 2)
- **Config:** `backend/pyproject.toml` — already created by Phase 1/2
- **Quick run:** `cd backend && pytest tests/features/webhook -x -q`
- **Full suite:** `cd backend && pytest -x -q`
- **Estimated runtime:** ~8s webhook tests, ~35s full suite

### Mock Strategy (D-17)
- **WhatsApp Graph API:** Mock `httpx.AsyncClient` responses — no real Meta API calls in tests
- **AI Service:** Mock `httpx.AsyncClient` POST to `AI_SERVICE_URL/chat` — return canned responses
- **PostgreSQL:** Real test database with transaction rollback per test (reuses Phase 1 conftest)
- **pg_cron:** Migration verified via Alembic check; actual cron execution is manual-only

### Test File Structure
```
backend/tests/
├── conftest.py                          # Phase 1/2 — shared DB + app fixtures
├── features/
│   ├── webhook/
│   │   ├── conftest.py                  # Phase 6 — mock WA client, payload factory
│   │   ├── test_webhook_hmac.py         # TEST-04: HMAC validation
│   │   ├── test_webhook_dedup.py        # TEST-04: message deduplication
│   │   ├── test_webhook_media.py        # TEST-04: media type responses
│   │   ├── test_verification_state.py   # Verification state machine flow
│   │   ├── test_background_task.py      # Background processing + retry
│   │   ├── test_whatsapp_client.py      # WhatsApp client unit tests
│   │   ├── test_phone_normalization.py  # D-04 phone matching
│   │   └── test_session_lifecycle.py    # Session reuse + close + auto-close
│   └── chat/
│       ├── conftest.py                  # Phase 6 — staff JWT, seeded sessions
│       └── test_chat_visibility.py      # Staff endpoints + authorization
└── middleware/
    └── test_service_token.py            # TEST-05: service token middleware
```

### Key Fixtures Needed
- `mock_wa_client` — monkeypatch WhatsAppClient.send_text_message to capture outgoing messages
- `webhook_payload_factory` — generate valid/invalid HMAC payloads (text, media, status)
- `test_student_with_phone` — seeded student with phone number for lookup
- `verified_session` / `unverified_session` — pre-created chat sessions in different states
- `mock_ai_service` — httpx mock returning canned AI responses

### Manual-Only Verifications
- WhatsApp webhook registration (requires Meta Developer Dashboard + public URL)
- Actual message delivery through WhatsApp
- pg_cron job execution (requires Docker with pg_cron extension)
- End-to-end verification flow on real WhatsApp

---

*Phase 6 research completed: 2026-04-23*
*Ready for planning: yes*
