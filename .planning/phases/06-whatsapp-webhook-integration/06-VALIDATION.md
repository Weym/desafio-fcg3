---
phase: 6
slug: whatsapp-webhook-integration
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-23
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | pytest 8.x + pytest-asyncio + httpx AsyncClient |
| **Config file** | `backend/pyproject.toml` (`[tool.pytest.ini_options]`) — created by Phase 1/2 Wave 0 |
| **Quick run command** | `cd backend && pytest tests/features/webhook -x -q` |
| **Full suite command** | `cd backend && pytest -x -q` |
| **Estimated runtime** | unit ~8s · full suite ~35s (mocks httpx + WhatsApp API, real PostgreSQL) |

---

## Sampling Rate

- **After every task commit:** Run `cd backend && pytest tests/features/webhook -x -q` (webhook tests) or task-scoped test
- **After every plan wave:** Run `cd backend && pytest -x -q`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 6-01-01 | 01 | 1 | WH-01,WH-02 | T-06-01 / T-06-04 | WhatsApp client with retry; HMAC validate_signature uses hmac.compare_digest (timing-safe); Settings has all WHATSAPP_* env vars; Alembic migration adds verification_state column | unit | `cd backend && python -c "from src.infrastructure.whatsapp_client import WhatsAppClient, validate_signature; print('ok')" && alembic check` | ❌ W0 | ⬜ pending |
| 6-01-02 | 01 | 1 | WH-01,WH-02,WH-03,WH-04 | T-06-01 / T-06-02 / T-06-05 / T-06-06 / T-06-07 | GET challenge returns hub.challenge on valid token, 403 on mismatch; POST validates HMAC before JSON parse (CRITICAL-1); status updates filtered; unknown phones rejected (D-03); media gets hardcoded response; dedup by wamid; verification state machine gates agent access | integration | `cd backend && pytest tests/features/webhook/test_webhook_hmac.py tests/features/webhook/test_webhook_dedup.py -x` | ❌ W0 | ⬜ pending |
| 6-02-01 | 02 | 2 | WH-05 | T-06-08 / T-06-10 | Background task dispatched via asyncio.create_task with done_callback (CRITICAL-3); own DB session (CRITICAL-4); retry once on AI failure + fallback message (D-06); per-session asyncio.Lock (D-09) | integration | `cd backend && pytest tests/features/webhook/test_background_task.py -x` | ❌ W0 | ⬜ pending |
| 6-02-02 | 02 | 2 | CHAT-01,CHAT-02 | T-06-11 / T-06-12 | Active session reused per phone (D-10); "sair"/"encerrar" closes session (D-11); pg_cron auto-closes inactive sessions after 24h (D-12); closed session → new session, re-verify (D-13) | integration | `cd backend && pytest tests/features/webhook/test_session_lifecycle.py -x` | ❌ W0 | ⬜ pending |
| 6-03-01 | 03 | 2 | CHAT-03 | T-06-13 / T-06-15 | Chat visibility service: list sessions with filters, list messages by session, list MCP action logs; staff-only access | unit | `cd backend && python -c "from src.features.chat.service import ChatService; print('ok')"` | ❌ W0 | ⬜ pending |
| 6-03-02 | 03 | 2 | CHAT-03 | T-06-13 | Staff endpoints registered in main.py; require_role("staff") on all chat endpoints; 403 for students; 404 for invalid session IDs | integration | `cd backend && pytest tests/features/chat/test_chat_visibility.py -x` | ❌ W0 | ⬜ pending |
| 6-04-01 | 04 | 3 | TEST-04 | T-06-16 | HMAC validation tests (unsigned → 403, wrong sig → 403, valid → 200); dedup tests (same wamid → one row); media type tests (each type → correct Portuguese response) | test | `cd backend && pytest tests/features/webhook/test_webhook_hmac.py tests/features/webhook/test_webhook_dedup.py tests/features/webhook/test_webhook_media.py -x` | ❌ W0 | ⬜ pending |
| 6-04-02 | 04 | 3 | TEST-05 | T-06-17 / T-06-18 | Service token middleware tests (missing → 401, invalid → 401, valid → pass); verification state machine full flow; background task error handling; chat visibility authorization | test | `cd backend && pytest tests/features/webhook/ tests/features/chat/ tests/middleware/ -x` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Must be created as part of Plan 04 (test suite plan) or early in Plan 01 before webhook logic:

- [ ] `backend/tests/features/webhook/__init__.py` — package init
- [ ] `backend/tests/features/webhook/conftest.py` — shared fixtures: mock WhatsApp client (mock httpx responses), webhook payload factory (valid/invalid HMAC, text/media/status messages), test student + session seeds, mock AI service response
- [ ] `backend/tests/features/chat/__init__.py` — package init
- [ ] `backend/tests/features/chat/conftest.py` — fixtures: staff user JWT, populated chat sessions with messages and MCP action logs
- [ ] `backend/tests/features/webhook/test_webhook_hmac.py` — stub (TEST-04 HMAC tests)
- [ ] `backend/tests/features/webhook/test_webhook_dedup.py` — stub (TEST-04 dedup tests)
- [ ] `backend/tests/features/webhook/test_webhook_media.py` — stub (TEST-04 media tests)
- [ ] `backend/tests/features/webhook/test_verification_state.py` — stub (verification state machine flow)
- [ ] `backend/tests/features/webhook/test_background_task.py` — stub (background processing + retry)
- [ ] `backend/tests/features/webhook/test_whatsapp_client.py` — stub (WhatsApp client unit tests)
- [ ] `backend/tests/features/webhook/test_phone_normalization.py` — stub (D-04 phone matching)
- [ ] `backend/tests/features/webhook/test_session_lifecycle.py` — stub (session reuse + close + auto-close)
- [ ] `backend/tests/features/chat/test_chat_visibility.py` — stub (staff endpoints + authorization)
- [ ] `backend/tests/middleware/test_service_token.py` — stub (TEST-05 service token middleware)

*Note: Phase 2 Wave 0 already created `backend/tests/conftest.py` with shared test DB fixtures, `app` fixture, and seed users. Phase 6 Wave 0 extends this with webhook-specific fixtures.*

---

## Test Distribution Note (D-14)

Per decision D-14, each phase writes its OWN tests:
- **TEST-01** (auth tests) → Written by Phase 2
- **TEST-02** (enrollment/grade tests) → Written by Phase 3
- **TEST-03** (MCP tool tests) → Written by Phase 3
- **TEST-04** (webhook HMAC + dedup + media) → **Written by Phase 6** (Plan 04, Task 1)
- **TEST-05** (service token middleware) → **Written by Phase 6** (Plan 04, Task 2)

ROADMAP assigns TEST-01/02/03 to Phase 6 requirements, but this is a traceability artifact — those tests are implemented by their respective phases. Phase 6 ensures the **full backend test suite passes** after its tests are written.

---

## Mock Strategy (D-17)

| Component | Strategy |
|-----------|----------|
| WhatsApp Graph API | Mock `httpx.AsyncClient` responses (send_text_message) |
| AI Service (LangChain) | Mock `httpx.AsyncClient` POST to `AI_SERVICE_URL/chat` |
| PostgreSQL | **Real** — test DB with transaction rollback per test |
| Resend (email OTP) | Mock `resend.Emails.send_async` (same as Phase 2) |
| pg_cron | Migration verified via Alembic; cron job execution is manual verification |

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| WhatsApp webhook registration with Meta | WH-01 | Requires Meta Developer Dashboard + ngrok/public URL | Deploy locally, expose via ngrok, register webhook URL in Meta Dashboard, send test message from WhatsApp to verify challenge + message receipt |
| Actual WhatsApp message delivery | WH-02 | Third-party delivery | After webhook registration, send text from WhatsApp. Verify: 200 response logged, message saved in chat_messages, verification prompt sent back |
| pg_cron job execution | CHAT-02 | Requires pg_cron extension running in Docker | Start Docker with pg_cron-enabled image, create a session, wait 24h+ (or set interval to 1 min for test), verify session auto-closed |
| End-to-end verification flow on WhatsApp | WH-02, D-02 | Full integration through Meta API | Send message → receive email prompt → enter email → receive OTP → enter code → receive "verified" → send question → receive AI answer |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING test file references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-23 (by planner; awaits execution confirmation)
