# Phase 6: WhatsApp Webhook & Integration - Context

**Gathered:** 2026-04-23
**Status:** Ready for planning

<domain>
## Phase Boundary

End-to-end WhatsApp chatbot flow: student sends a WhatsApp message and receives an AI-powered response about their academic situation. Includes webhook hardening (HMAC-SHA256 validation, message deduplication, 5-second timeout compliance), WhatsApp identity verification, media message handling with standard replies, chat session lifecycle management, chat visibility endpoints for staff, and integration tests (TEST-04, TEST-05). The webhook handler connects the FastAPI backend to the AI Service (Phase 5) and MCP Server (Phase 4) built in prior phases.

</domain>

<decisions>
## Implementation Decisions

### Verificacao de Identidade WhatsApp
- **D-01:** Add `verification_state` enum column to `chat_sessions` table with values: `unverified`, `awaiting_email`, `awaiting_code`, `verified`. Resolves the schema gap identified in SUMMARY.md. Requires a new Alembic migration.
- **D-02:** Verification logic lives in the webhook handler (FastAPI), PRE-AGENT. Unverified students never reach the LangChain agent. The verification flow is purely mechanical (ask email, validate OTP code) — no LLM latency needed.
- **D-03:** Unknown phone numbers (not found in `students.phone`) receive a generic friendly message: "Nao encontrei cadastro para este numero. Procure a secretaria para cadastro." No `chat_session` is created for unknown numbers.
- **D-04:** Phone number normalization: store `students.phone` in international format without `+` prefix (e.g., `5521999999999`). WhatsApp sends in this format. Direct string comparison — no regex needed.
- **D-05:** Verification session expiration follows the JWT/refresh token lifecycle from Phase 2 auth (access token 1h, refresh token per Phase 2 config). When both tokens expire, verification_state reverts to `unverified` and re-verification is required. This is not a Phase 6 decision — it follows from Phase 2 D-01/D-02/D-03.

### Falha no Background Task & UX
- **D-06:** On background task failure (AI service unavailable, timeout, exception): retry ONCE, then send fallback message to student via WhatsApp: "Desculpe, estou com dificuldades tecnicas. Tente novamente em alguns minutos." (per `docs/chatbot.md` error table). The `done_callback` handles both retry and fallback sending.
- **D-07:** WhatsApp Graph API send failures: one immediate retry on the POST to Graph API. If second attempt fails, log the error. The message is already saved in `chat_messages` for audit even without delivery.
- **D-08:** WhatsApp client isolated in `backend/src/infrastructure/whatsapp_client.py` with `send_text_message()`, `validate_signature()` methods. `httpx.AsyncClient` singleton with built-in retry. All Graph API details encapsulated.
- **D-09:** Per-session `asyncio.Lock` for concurrent message protection. Messages from the same student are processed sequentially. Prevents DB conflicts and out-of-order responses when a student sends multiple messages rapidly.

### Ciclo de Vida da Chat Session
- **D-10:** Reuse active session: one `chat_session` per phone number while status is `active`. New messages join the existing session. Agent has access to full conversation history (k=20 from Phase 5).
- **D-11:** Session closure via TWO mechanisms: (a) student can close manually by typing "sair" or "encerrar"; (b) auto-close after 24 hours of inactivity via `pg_cron` scheduled job.
- **D-12:** `pg_cron` for auto-close: requires custom PostgreSQL Docker image with both `pgvector` and `pg_cron` extensions. Cron job runs periodically (e.g., every hour) executing: `UPDATE chat_sessions SET status = 'closed' WHERE updated_at < NOW() - INTERVAL '24 hours' AND status = 'active'`. This overrides the original PROJECT.md "pg_cron is post-MVP" constraint — user explicitly chose to include it.
- **D-13:** When a closed session's phone sends a new message, a new `chat_session` is created. The student must re-verify identity (verification_state starts at `unverified`).

### Organizacao do Test Suite
- **D-14:** Each phase writes its OWN tests. Test distribution: Phase 1 creates test infrastructure (conftest.py, test DB, base fixtures); Phase 2 writes TEST-01 (auth flow); Phase 3 writes TEST-02 (enrollment IDOR) and TEST-03 (CRA calculation); Phase 6 writes TEST-04 (webhook HMAC + dedup + media) and TEST-05 (X-Service-Token middleware + IDOR prevention).
- **D-15:** Test infrastructure created in Phase 1: `backend/tests/conftest.py` with `client` fixture (httpx.AsyncClient), `db_session` fixture (transaction rollback), entity factories. All phases build on this base.
- **D-16:** Phase 6 test coverage is COMPLETE: beyond TEST-04 and TEST-05, write unit tests for HMAC validation, phone normalization, media type routing, deduplication logic, verification state machine, background task error handling, WhatsApp client, and chat visibility endpoints.
- **D-17:** Mock strategy: mock `httpx.AsyncClient` for WhatsApp Graph API and AI Service calls. Real PostgreSQL test DB for everything else. Per `.planning/codebase/TESTING.md` prescription: "Mock external HTTP, do NOT mock PostgreSQL."

### Agent's Discretion
- Exact verification state machine implementation (how transitions between states are enforced)
- Background task retry timing (immediate vs short delay)
- `asyncio.Lock` storage mechanism (dict keyed by session_id vs WeakValueDictionary)
- Exact pg_cron schedule interval (every 30min vs every 1h)
- Chat visibility endpoint pagination and filtering details
- WhatsApp client connection pool sizing and timeout configuration
- How "sair"/"encerrar" keywords are detected (exact match vs fuzzy)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Chatbot Architecture & Flows
- `docs/chatbot.md` -- Complete chatbot architecture: webhook sequence diagram, media type response table (6 types with exact Portuguese messages), verification flow with 3-attempt logic, agent system prompt, intent table, conversation flow diagrams, error handling table. Primary spec for Plans 6.1 and 6.2.

### API Contract (Webhook & Chat Endpoints)
- `docs/api.md` -- Full endpoint contracts including `POST /webhook/whatsapp`, `GET /webhook/whatsapp` (challenge), `GET /chat-sessions`, `GET /chat-sessions/{id}/messages`, `GET /chat-sessions/{id}/action-logs`. Request/response shapes, WhatsApp payload JSON structure.

### Database Schema
- `docs/database.md` -- Schema for `chat_sessions` (6 columns + new `verification_state`), `chat_messages` (7 columns including `media_type` and `whatsapp_message_id`), `mcp_action_logs` (10 columns), indexes (`idx_chat_sessions_student`, `idx_mcp_logs_session`). Primary schema reference for all Phase 6 DB operations.

### MCP Protocol (for action log viewing)
- `docs/mcp.md` -- MCP tool schemas, logging specification. Relevant for Plan 6.3 (staff viewing MCP action logs per session).

### Architecture & Async Patterns
- `docs/architecture.md` -- C4 diagrams, Docker topology, async message flow (text + media), service communication patterns. Webhook-to-agent-to-MCP data flow diagram.

### Critical Pitfalls (MUST READ)
- `.planning/research/SUMMARY.md` -- CRITICAL-1 (HMAC body consumption order), CRITICAL-3 (create_task + done_callback), CRITICAL-4 (SQLAlchemy session in background tasks), MODERATE-1 (deduplication by wamid), MINOR-3 (per-session async lock). All directly impact Phase 6 implementation.

### Testing Patterns
- `.planning/codebase/TESTING.md` -- Prescriptive test patterns: pytest + pytest-asyncio, httpx.AsyncClient, transaction rollback fixtures, conftest.py templates, mock patterns for asyncio.create_task, X-Hub-Signature-256 computation, background task testing.

### WhatsApp Integration Details
- `.planning/codebase/INTEGRATIONS.md` -- WhatsApp Business Cloud API: Graph API v18.0 URL, HMAC validation header, env vars needed (WHATSAPP_TOKEN, WHATSAPP_APP_SECRET, WHATSAPP_PHONE_NUMBER_ID, WHATSAPP_VERIFY_TOKEN).

### Phase Dependencies
- `.planning/phases/01-infrastructure-schema/01-CONTEXT.md` -- D-05/D-06/D-07: Docker setup, service directories, requirements.txt per service. D-09: Migration #006 creates chat_sessions, chat_messages, mcp_action_logs tables. NOTE: Phase 1 needs update for pg_cron in Docker image (D-12 here).
- `.planning/phases/02-authentication/02-CONTEXT.md` -- D-01/D-02/D-03: JWT lifecycle (access 1h, refresh rotation). D-07/D-08: Only registered emails get OTP, generic response for unknown. D-12/D-13/D-14: Rate limiting on OTP.
- `.planning/phases/03-business-feature-slices/03-CONTEXT.md` -- D-02: Dual-auth dependency. D-03: Error codes in Portuguese SCREAMING_SNAKE_CASE. D-06: Staff bypasses ownership.
- `.planning/phases/04-mcp-server/04-CONTEXT.md` -- D-04/D-05/D-06: X-Chat-Session-ID header for session context, student_id resolved from chat_sessions.
- `.planning/phases/05-ai-service/05-CONTEXT.md` -- D-05: FastAPI for AI service on port 8001. D-08/D-09: Stateless per request, AI service writes assistant response to chat_messages. D-07: max_iterations=10, max_execution_time=45s.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- No existing Python code -- all backend directories contain only `.gitkeep` scaffolding. All prior phases (1-5) must be completed first.
- `docs/chatbot.md` contains media type response table with exact Portuguese messages -- copy directly into implementation.
- `.planning/codebase/TESTING.md` contains conftest.py templates and fixture patterns -- use as blueprint for test infrastructure.
- `.planning/codebase/INTEGRATIONS.md` has WhatsApp Graph API URL pattern and auth header format.

### Established Patterns
- Vertical slice architecture: `backend/src/features/webhook/` for webhook handler, `backend/src/features/chat/` for chat visibility endpoints.
- Settings via Pydantic BaseSettings -- `WHATSAPP_TOKEN`, `WHATSAPP_APP_SECRET`, `WHATSAPP_PHONE_NUMBER_ID`, `WHATSAPP_VERIFY_TOKEN` as env vars.
- Error response shape: `{"error": {"code": "...", "message": "...", "details": [...]}}` with Portuguese codes.
- All FastAPI route handlers `async def`. Background work via `asyncio.create_task` + `add_done_callback`.
- `lazy="raise"` on all SQLAlchemy relationships, explicit `selectinload()`.

### Integration Points
- `backend/src/main.py` -- Register webhook and chat routers, configure middleware.
- `backend/src/infrastructure/` -- DB session factory (Phase 1), settings (Phase 1), new `whatsapp_client.py`.
- `backend/src/shared/` -- Auth dependencies `get_current_user`, `require_role` (Phase 2), dual-auth `get_current_user_or_service()` (Phase 3).
- AI Service HTTP endpoint on port 8001 -- webhook background task calls this with message + session_id.
- PostgreSQL tables: `chat_sessions`, `chat_messages`, `mcp_action_logs`, `students` (phone lookup).

</code_context>

<specifics>
## Specific Ideas

- Verification flow is purely mechanical (ask email, send OTP, validate code) -- no LLM involved. This keeps it fast and predictable.
- The 5-second WhatsApp timeout is the dominant constraint: webhook saves message + returns 200, ALL processing is async via background task.
- Per-session async lock prevents a race condition documented in SUMMARY.md (MINOR-3): rapid messages from the same student creating parallel tasks that corrupt conversation state.
- pg_cron inclusion overrides original "post-MVP" constraint -- this decision needs to propagate to Phase 1 planning (custom Postgres Docker image with pgvector + pg_cron).
- Media type responses are exact strings from `docs/chatbot.md` table -- hardcoded, no LLM involved.

</specifics>

<deferred>
## Deferred Ideas

- Whisper API for audio transcription (post-MVP per PROJECT.md)
- GPT-4o Vision for image analysis (post-MVP per PROJECT.md)
- Redis cache for conversation sessions (post-MVP per PROJECT.md)
- FCM push notifications for chat_reply events (out of scope for this cycle)
- Knowledge base admin UI (staff manages via `docker exec` in MVP)

</deferred>

---

*Phase: 06-whatsapp-webhook-integration*
*Context gathered: 2026-04-23*
