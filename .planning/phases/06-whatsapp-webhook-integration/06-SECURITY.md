---
phase: 06
slug: whatsapp-webhook-integration
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-30
---

# Phase 06 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| WhatsApp Cloud API -> FastAPI webhook | External untrusted HTTP from Meta servers | Raw message payload (HMAC-SHA256 validated) |
| Webhook -> Database | User input (message content) stored | Text/media type strings, student PII (phone) |
| Webhook -> WhatsApp Graph API | Outbound HTTP with Bearer token | Response messages, verification prompts |
| FastAPI -> AI Service (langchain-service:8001) | Internal HTTP within Docker app-network | Message text + session_id |
| Background task -> Database | Async session opened after request ends | Assistant responses, session state |
| Staff JWT -> Chat endpoints | Role-gated access to monitoring data | Chat sessions, messages, MCP action logs |
| pg_cron -> Database | Scheduled job within PostgreSQL container | Session status updates (auto-close) |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-06-01 | Spoofing | POST /webhook/whatsapp | mitigate | HMAC-SHA256 validation using raw body bytes before any JSON parsing (CRITICAL-1). Reject with 403 on mismatch. Implemented in `whatsapp_client.validate_signature()`. | closed |
| T-06-02 | Tampering | WhatsApp message payload | mitigate | Raw body read first via `request.body()`, then parsed; no Pydantic body parameter. Signature covers entire payload. | closed |
| T-06-03 | Repudiation | Message processing | mitigate | All messages saved to `chat_messages` with `whatsapp_message_id` for audit trail. Partial unique index ensures integrity. | closed |
| T-06-04 | Information Disclosure | WhatsApp tokens | mitigate | All tokens configured via environment variables in `config.py` Settings class. Never in source code (per AGENTS.md constraint). `.env.example` documents required vars. | closed |
| T-06-05 | Denial of Service | Duplicate webhook deliveries | mitigate | Deduplication by `whatsapp_message_id` partial unique index (`WHERE whatsapp_message_id IS NOT NULL`). IntegrityError caught gracefully, duplicate skipped. | closed |
| T-06-06 | Elevation of Privilege | Unverified user accessing agent | mitigate | Verification state machine (unverified->awaiting_email->awaiting_code->verified) gates agent access. Unverified sessions never reach LangChain agent (D-02). | closed |
| T-06-07 | Spoofing | Webhook challenge endpoint | mitigate | GET /webhook/whatsapp verify token compared against `WHATSAPP_WEBHOOK_VERIFY_TOKEN` env var; 403 on mismatch. | closed |
| T-06-08 | Denial of Service | Background task exception | mitigate | `_handle_task_result` done_callback logs all exceptions via structured logging (CRITICAL-3). Fallback message "Desculpe..." sent to student on failure (D-06). | closed |
| T-06-09 | Tampering | AI service response | accept | Internal Docker `app-network`. AI service (`langchain-service:8001`) is trusted. No external access to internal network. | closed |
| T-06-10 | Denial of Service | Rapid concurrent messages | mitigate | Per-session `asyncio.Lock` keyed by `str(session_id)` serializes processing for same student (D-09, MINOR-3). | closed |
| T-06-11 | Information Disclosure | DB session leaked to background | mitigate | Background task opens own session via `async_session()` context manager (CRITICAL-4). Never uses request-scoped session. | closed |
| T-06-12 | Elevation of Privilege | pg_cron job | accept | Job runs as DB superuser within the PostgreSQL container; no external access. Standard pg_cron security model. Job only performs `UPDATE chat_sessions SET status='closed'`. | closed |
| T-06-13 | Elevation of Privilege | Chat visibility endpoints | mitigate | All three endpoints (`/chat-sessions`, `/{id}/messages`, `/{id}/action-logs`) gated by `require_role("staff")`. Students cannot access. | closed |
| T-06-14 | Information Disclosure | Message content exposure to staff | accept | Staff legitimately need to view all chat content for support, quality assurance, and audit purposes. This is a business requirement (CHAT-03). | closed |
| T-06-15 | Spoofing | Session ID parameter enumeration | mitigate | Session existence check returns 404 for invalid/non-existent IDs. No information leakage about valid session IDs via error messages. | closed |
| T-06-16 | Spoofing | HMAC validation (test coverage) | mitigate | TEST-04 specifically tests: unsigned requests -> 403, wrong-signature requests -> 403, valid signature -> 200. 10 HMAC tests passing. | closed |
| T-06-17 | Elevation of Privilege | Service token middleware (test coverage) | mitigate | TEST-05 verifies: missing X-Service-Token -> 401, invalid token -> 401, valid token -> passes. Timing-safe comparison via `hmac.compare_digest` verified. 9 tests passing. | closed |
| T-06-18 | Repudiation | Background task failures (test coverage) | mitigate | Tests verify `_handle_task_result` done_callback logs all exceptions. 8 background task tests covering retry, fallback, and exception scenarios. | closed |

*Status: open / closed*
*Disposition: mitigate (implementation required) / accept (documented risk) / transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-06-01 | T-06-09 | AI service response is on internal Docker network (`app-network`). No external actors can inject responses. Service-to-service trust within the container orchestration boundary. | gsd-security-audit | 2026-04-30 |
| AR-06-02 | T-06-12 | pg_cron job runs within PostgreSQL container with no external network exposure. Only performs bounded UPDATE on `chat_sessions` table. Standard operational pattern for scheduled maintenance. | gsd-security-audit | 2026-04-30 |
| AR-06-03 | T-06-14 | Staff access to message content is a core business requirement for support and audit. Access is gated by `require_role("staff")` — only authenticated staff users can view. | gsd-security-audit | 2026-04-30 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-30 | 18 | 18 | 0 | gsd-security-audit (automated) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-30

---

## Implementation Evidence Summary

### Critical Security Controls (verified in implementation + tests)

| Control | Implementation File | Test Coverage |
|---------|-------------------|---------------|
| HMAC-SHA256 webhook validation | `backend/src/infrastructure/whatsapp_client.py` | `test_webhook_hmac.py` (10 tests) |
| Raw body before parse (CRITICAL-1) | `backend/src/features/webhook/router.py` | Covered in HMAC integration tests |
| Message deduplication | Alembic migration 010a (partial unique index) | `test_webhook_dedup.py` (4 tests) |
| Verification state machine | `backend/src/features/webhook/service.py` | `test_verification_state.py` (9 tests) |
| Per-session locking (D-09) | `backend/src/features/webhook/background.py` | `test_background_task.py` (8 tests) |
| Own DB session (CRITICAL-4) | `backend/src/features/webhook/background.py` | Verified via patch_webhook_db fixture |
| Background task done_callback (CRITICAL-3) | `backend/src/features/webhook/background.py` | `test_background_task.py` |
| Staff-only chat endpoints | `backend/src/features/chat/router.py` | `test_chat_visibility.py` (8 tests) |
| X-Service-Token middleware | `backend/src/shared/auth.py` | `test_service_token.py` (9 tests) |
| Tokens in env vars only | `backend/src/infrastructure/config.py` | `.env.example` documents all vars |

**Total test coverage:** 81 tests across webhook, chat, and middleware security.

---

*Phase: 06-whatsapp-webhook-integration*
*Security verified: 2026-04-30*
