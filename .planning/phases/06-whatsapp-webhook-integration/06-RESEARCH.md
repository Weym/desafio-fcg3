# Phase 6 Research — WhatsApp Webhook & Integration

**Phase:** 06-whatsapp-webhook-integration
**Researched:** 2026-04-23
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

*Phase 6 research completed: 2026-04-23*
*Ready for planning: yes*
