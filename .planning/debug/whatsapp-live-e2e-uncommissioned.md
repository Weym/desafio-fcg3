---
status: awaiting_human_verify
trigger: "Commission WhatsApp webhook end-to-end against real Meta Cloud API — test and don't stop until it works. Unit tests pass but live flow never exercised."
created: 2026-05-05T20:09:28-03:00
updated: 2026-05-06T02:10:00-03:00
---

## Current Focus

hypothesis: All three root causes found and fixed:
  (A) invalid WHATSAPP_TOKEN (env, user-resolved)
  (B) Brazilian 9th-digit phone format mismatch (code, commit 0e12e14)
  (C) webhook → AI /chat HTTP call missing X-Service-Token header causing 401 → fallback (code, commit 4f05ee8)
Also resolved the silent-logging blocker that masked (B) and (C) (commit e6f1845).

Local synthetic probe and real user message both produce the full happy path: webhook → AI /chat 200 → LangChain agent invokes MCP grades tool → backend /students/.../grades 200 → reply sent to Meta 200.

test: Live user-initiated round-trip — user sends a verified-flow question from their real phone, expects a real AI-generated answer (not the fallback).
expecting: User confirms they receive a meaningful reply (e.g., their actual grades or a coherent academic response) instead of "Desculpe, estou com dificuldades tecnicas...".
next_action: CHECKPOINT human-verify. If confirmed, archive + update knowledge base.

## Symptoms

expected: |
  1. GET /webhook/whatsapp subscribe challenge returns challenge 200 when Meta verifies.
  2. POST /webhook/whatsapp with valid signature returns 200 within <5s.
  3. First message from registered-but-unverified phone triggers OTP email via Resend; reply with code → session verified.
  4. Verified text messages dispatch to process_verified_message → LangChain → MCP tools (student_id injected) → RAG context → reply sent via Meta Cloud API.
  5. Unknown phones get Portuguese rejection: "Nao encontrei cadastro para este numero. Procure a secretaria para cadastro."
  6. Media messages (audio/image/document/video/sticker) get hardcoded media response, no agent.
  7. "sair"/"encerrar" closes session with "Sessao encerrada. Ate logo!"

actual: Unknown — this has never been tested against real Meta Cloud API. Unit tests pass. Live flow uncommissioned. Failure modes possible across signature validation, Meta webhook registration, outbound send_text_message, LangChain dispatch timing, OTP email, RAG quality.

errors: None observed yet — testing has not begun.

reproduction: |
  1. docker-compose running: fcg3-api:8000, fcg3-ai:8001, fcg3-mcp:8002, fcg3-postgres:5432 (all healthy per docker ps).
  2. WHATSAPP_TOKEN, WHATSAPP_PHONE_NUMBER_ID, WHATSAPP_WEBHOOK_VERIFY_TOKEN, WHATSAPP_APP_SECRET set in .env per user — real-vs-placeholder to be verified.
  3. No public tunnel yet (blocker for live E2E).
  4. A student must exist in `students` with `whatsapp_phone` matching the tester's E.164 number and a valid email.

started: Never worked live — feature built across Phases 1-6 of Milestone v1.0, only unit-tested.

## Eliminated

- hypothesis: WHATSAPP_TOKEN is invalid/expired → outbound send_text_message returns 401 code 190
  evidence: After user refreshed WHATSAPP_TOKEN AND WHATSAPP_PHONE_NUMBER_ID (now 1030509390153653) and restarted fcg3-api, a signed POST with Henry's real phone (5583998257544) completed with HTTP 200 in 1.96s and produced ZERO error logs — which means whatsapp_client.send_text_message received a 200 from Meta Graph API (otherwise lines 48-53 of whatsapp_client.py would have logged "WhatsApp send attempt N failed"). DB state also confirms the handle_verification_flow ran successfully: session.verification_state transitioned to 'awaiting_email'.
  timestamp: 2026-05-06T01:28:00-03:00

- hypothesis: Pydantic schema mismatch is dropping Meta's `messages` array; that's why my DIAG log never prints
  evidence: Runtime check showed root logger level=WARNING and zero handlers, so logger.info is universally suppressed in app modules (uvicorn only attaches handlers to its own loggers). The silence had nothing to do with Pydantic parsing — it was a logging bug. After switching DIAG to logger.warning + print(flush=True), DIAG fired on the very next POST, proving Pydantic was parsing `messages` correctly all along.
  timestamp: 2026-05-06T01:45:00-03:00

## Evidence

- timestamp: 2026-05-05T20:15:00-03:00
  checked: `docker ps`, `/health` on all 3 services
  found: fcg3-api (8000→8000), fcg3-ai (8001), fcg3-mcp (8002), fcg3-postgres (5432→5432) all healthy. /health on api = `{"status":"ok"}`, mcp = `{"status":"healthy"}`, ai = `{"status":"healthy"}`.
  implication: Infra is up. No cold-start issues. All services reachable from each other.

- timestamp: 2026-05-05T20:16:00-03:00
  checked: `docker exec fcg3-api env | grep -i whatsapp/resend/openai/...`
  found: All required WhatsApp vars set (TOKEN, PHONE_NUMBER_ID=1183056894879921, VERIFY_TOKEN, APP_SECRET). LLM_PROVIDER=openrouter, LLM_MODEL=stepfun/step-3.5-flash. All 3 LLM keys set. RESEND_FROM=onboarding@resend.dev (sandbox sender — see implication). FASTAPI_URL=http://fastapi-app:8000 (correct docker-internal).
  implication: Env config is present. RESEND_FROM=onboarding@resend.dev is Resend's sandbox sender — on a free account it can ONLY deliver to the account owner's email, not arbitrary addresses. This will bite at Stage E (OTP email) unless the tester's student email matches the Resend account owner email.

- timestamp: 2026-05-05T20:17:00-03:00
  checked: `rg include_router backend/src/main.py`
  found: Webhook router mounted with `prefix="/api/v1"` → live path is `/api/v1/webhook/whatsapp`.
  implication: Meta's callback URL must be `<tunnel>/api/v1/webhook/whatsapp`, NOT `/webhook/whatsapp`. Record to relay to user at Stage C.

- timestamp: 2026-05-05T20:18:00-03:00
  checked: `SELECT * FROM students` (postgres)
  found: 6 rows. Active test candidate: Henry Gabriel Andrade Oliveira, phone=5583998257544, email=henrygabrielandradeoliveira@gmail.com, status=active.
  implication: Tester already has a student record. No DB seeding needed. Phone is E.164 no-plus (matches code assumption).

- timestamp: 2026-05-05T20:19:00-03:00
  checked: GET /api/v1/webhook/whatsapp with wrong verify_token
  found: HTTP 403 "Verification failed"
  implication: Verify-token gate works. Negative path.

- timestamp: 2026-05-05T20:19:30-03:00
  checked: GET /api/v1/webhook/whatsapp with correct verify_token + challenge=challenge_ok_123
  found: HTTP 200 body `challenge_ok_123`
  implication: Meta verification flow (GET challenge) is functional end-to-end. Stage C "Verify and Save" should succeed on the Meta console side once tunnel is up.

- timestamp: 2026-05-05T20:20:00-03:00
  checked: POST /api/v1/webhook/whatsapp with bogus signature (deadbeef)
  found: HTTP 403 `{"error":{"code":"error","message":"Invalid signature"}}`
  implication: Signature rejection path works. HMAC validator is wired correctly.

- timestamp: 2026-05-05T20:21:00-03:00
  checked: POST /api/v1/webhook/whatsapp with HMAC-valid signature (computed using container's WHATSAPP_APP_SECRET) + payload from unknown phone 5599999999999
  found: HTTP 200 from webhook (correct — returned in <1s). Background Meta Graph API call logged:
    `WhatsApp send attempt 1 failed: 401 {"error":{"message":"Authentication Error","code":190,"type":"OAuthException","fbtrace_id":"ANQRsJvIPjZChi0a62C55-Y"}}`
    `WhatsApp send attempt 2 failed: 401 {...same error, different fbtrace_id}`
    `WhatsApp send failed after 2 attempts to 5599999999999`
  implication: **BLOCKER FOUND.** Webhook POST + signature + payload parsing + student lookup + unknown-phone branch + outbound httpx → all correct. But the Meta Cloud API rejects our token: error `code 190` = access token invalid/expired. Until WHATSAPP_TOKEN is fixed, zero outbound replies can work — that kills the entire live flow (unknown-phone rejection, OTP prompt, verified replies, media responses, session-close farewell). NOTE: this tautologically confirms our signature validator works too, because we used the container's own APP_SECRET on both sides.

- timestamp: 2026-05-06T01:26:00-03:00
  checked: `docker exec fcg3-api printenv WHATSAPP_TOKEN WHATSAPP_PHONE_NUMBER_ID` after user refresh
  found: Token begins `EAA2Qd7Feg4EBRWlL7if...` (different prefix, fresh). PHONE_NUMBER_ID changed from 1183056894879921 → 1030509390153653. User refreshed both.
  implication: New token + new phone number ID. Good — token and phone ID likely paired correctly in Meta.

- timestamp: 2026-05-06T01:27:00-03:00
  checked: Signed POST /api/v1/webhook/whatsapp with Henry's real phone 5583998257544, body "oi", signed with new APP_SECRET.
  found: HTTP 200 in 1.965s. No error lines in logs (no "WhatsApp send attempt N failed"). Chat session created, student linked (a7571e3d...), verification_state transitioned to 'awaiting_email'. User message "oi" persisted with wamid.probe_real_001.
  implication: Outbound Meta Graph API send succeeded — Henry should have received WhatsApp text "Preciso verificar sua identidade. Qual seu email institucional?" on 5583998257544. Full local backend path is now functional: signature validation → payload parse → student lookup → session create → verification state machine → outbound send_text_message → Meta → end user. Note: the verification-flow's outgoing "ask for email" message is NOT saved to chat_messages (service.py _handle_verification_flow unverified→awaiting_email branch calls wa_client.send_text_message directly without save_message). This is an audit-trail gap but not a spec violation — docs don't require persisting verification-flow system messages.

- timestamp: 2026-05-06T01:40:00-03:00
  checked: User report: Meta is forwarding messages to the tunnel but replies always say "Nao encontrei cadastro..." (the D-03 unknown-phone rejection)
  found: lookup_student_by_phone returns None for real inbound, even though Henry's student row exists.
  implication: Format mismatch between what Meta sends and what's stored.

- timestamp: 2026-05-06T01:46:00-03:00
  checked: DIAG logger.warning + print(flush=True) with full raw body on live inbound
  found: `[DIAG] webhook msg received: from='558398257544' wamid=... type=text student_found=False`. Meta is sending 12 digits. DB has 13 digits (`5583998257544`) with the mobile `9`.
  implication: **Brazilian 9th-digit quirk.** Meta Cloud API delivered this mobile number in legacy 12-digit form, but the DB stores the modern 13-digit form. service.py lookup_student_by_phone did direct string equality, so every real inbound missed.

- timestamp: 2026-05-06T01:48:00-03:00
  checked: Introduced _phone_variants helper; changed lookup to col.in_(variants). Added 3 regression tests.
  found: `pytest tests/features/webhook/ -q` → 67 passed. `pytest tests/features/webhook/test_phone_normalization.py -q` → 8 passed (4 original + 4 new). Pre-existing failure in tests/features/chat/test_chat_visibility.py is unrelated and fails on main (verified by stashing my changes).
  implication: Fix validated at unit-test level + regression preserved.

- timestamp: 2026-05-06T01:51:00-03:00
  checked: Post-fix live probe: signed POST with `from=558398257544` (12-digit form) to local webhook.
  found: `INFO src.features.webhook.router: webhook msg: from=558398257544 wamid=wamid.ninth_fix_probe_001 type=text student_found=True` followed by `INFO httpx: HTTP Request: POST https://graph.facebook.com/v18.0/1030509390153653/messages "HTTP/1.1 200 OK"`. Response time 818 ms.
  implication: Fix confirmed functional end-to-end in local integration. Existing Henry session (from Stage B) is reused in state `awaiting_email` — next live message from Henry will be interpreted as an email attempt by the verification state machine.

- timestamp: 2026-05-06T01:52:00-03:00
  checked: Root-logger fix deployed (logging.basicConfig(level=INFO, force=True) in main.py).
  found: `2026-05-06 01:51:29,357 INFO src.features.webhook.router: webhook msg: ...` — formatted log now visible with timestamp, level, logger name. Observability restored.
  implication: Future debugging sessions can rely on logger.info(...) output. Closes the meta-debugging loop that made this session 10x harder.

- timestamp: 2026-05-06T02:00:00-03:00
  checked: User report after .env edit + force-recreate all services: WhatsApp reply is "Desculpe, estou com dificuldades tecnicas. Tente novamente em alguns minutos."
  found: Message string matches the short fallback defined in backend/src/features/webhook/background.py:27 AND ai_service/main.py:141. Session state in DB is 'verified' — user had completed OTP. All 4 containers healthy. MCP_SERVICE_TOKEN identical across all 3 services. RESEND_FROM changed to contato@alphaconnect-ed.xyz (not relevant — session already verified, no OTP send happening).
  implication: Failure is on the verified-chat path, not OTP/Resend. Two candidate sites for the fallback.

- timestamp: 2026-05-06T02:01:00-03:00
  checked: `docker logs fcg3-api | grep -iE 'error|401|fallback'`
  found: Multiple repetitions of:
    `WARNING src.features.webhook.background: AI service returned 401 on attempt 1`
    `WARNING src.features.webhook.background: AI service returned 401 on attempt 2`
    `ERROR src.features.webhook.background: AI service unavailable for session ..., sending fallback`
  fcg3-ai and fcg3-mcp logs: zero errors.
  implication: The 401 is coming from fcg3-ai rejecting the webhook's request, not from anything downstream. Webhook → AI service HTTP call is unauthorized.

- timestamp: 2026-05-06T02:02:00-03:00
  checked: Read ai_service/main.py::chat handler (line 105-108)
  found: `/chat` has `_: None = Depends(require_service_token)`. require_service_token (line 21-47) requires `X-Service-Token` header matching settings.MCP_SERVICE_TOKEN. 401 is raised if header is missing OR doesn't match.
  implication: `/chat` is auth-gated. Caller must send the shared service token.

- timestamp: 2026-05-06T02:02:30-03:00
  checked: Read backend/src/features/webhook/background.py::process_verified_message httpx.post call (line 79-85)
  found: `await http.post(f"{settings.ai_service_url}/chat", json={...})` — NO headers argument at all.
  implication: **PRIMARY CODE BUG #2.** The webhook's background task is making an unauthenticated POST to a token-guarded endpoint. Every verified student's message 401s twice and falls back. This is a pre-existing latent bug — prior unit tests mock httpx.AsyncClient so they never hit the auth wall, and every prior live probe in this debug ended before the session transitioned to verified.

- timestamp: 2026-05-06T02:05:00-03:00
  checked: Added `headers={"X-Service-Token": settings.mcp_service_token}` on the http.post call + regression test in test_background_task.py asserting every http.post call carries the correct header.
  found: `pytest tests/features/webhook/ -q` → 68/68 passed (previously 67, +1 new regression test).
  implication: Fix validated at unit level.

- timestamp: 2026-05-06T02:07:00-03:00
  checked: Live synthetic probe after fix — signed POST with phone=558398257544, text="quais sao minhas notas" (a verified-flow question).
  found: Full happy path observed:
    - api: `webhook msg: from=558398257544 wamid=... type=text student_found=True`
    - api: `httpx: POST http://langchain-service:8001/chat "HTTP/1.1 200 OK"` (was 401 before)
    - ai: `POST /chat HTTP/1.1 200 OK`
    - mcp: `POST /mcp ... 200 OK` ... `202 Accepted` ... DELETE /mcp 200 OK (full MCP session lifecycle)
    - api: `GET /api/v1/students/a7571e3d-.../grades HTTP/1.1 200 OK` (MCP tool invoked real endpoint)
    - api: `httpx: POST https://graph.facebook.com/v18.0/.../messages "HTTP/1.1 200 OK"` (reply sent to Meta)
    - Zero error lines in any of the three services.
  implication: **Full end-to-end verified chat path functional.** User's real message that arrived just seconds before the probe also followed the same path successfully — they should have received a real AI-generated answer about their grades. Awaiting user confirmation.

## Resolution

root_cause: Three sequential issues uncovered while commissioning the WhatsApp chatbot end-to-end for the first time.
  (A) WHATSAPP_TOKEN in the running container was invalid/expired (Meta Graph API returned code 190 OAuthException). Resolved by the user refreshing token and phone_number_id.
  (B) **PRIMARY CODE BUG #1** — Brazilian 9th-digit phone quirk. service.py::lookup_student_by_phone did direct string equality on a format that Meta's Cloud API does not always match. Meta sends Brazilian mobile numbers in the **legacy 12-digit form** (e.g., `558398257544` = 55 + DDD 83 + 98257544) while student records are stored with the **modern 13-digit form including the mobile `9`** (e.g., `5583998257544`). Every real inbound was routed to the unknown-phone rejection branch.
  (C) **PRIMARY CODE BUG #2** — missing X-Service-Token header on webhook → AI service call. background.py::process_verified_message POSTed to `/chat` with no headers at all, but the AI service's `/chat` endpoint requires the shared MCP_SERVICE_TOKEN for internal service auth. Every verified student got 401 on both retries → fallback "Desculpe, estou com dificuldades tecnicas". Pre-existing latent bug — unit tests mocked httpx so they never hit the auth wall, and prior live probes never reached the verified code path.
  Also uncovered during debugging: the whole app had **no logging configuration**, so logger.info calls were silently dropped, which turned investigations into multiple unnecessary round-trips. Fixed as a companion commit.

fix: |
  commit 0e12e14 — fix(webhook): normalize Brazilian 9th-digit phone format in student lookup
    - backend/src/features/webhook/service.py: added _phone_variants() helper; lookup uses Student.phone.in_(variants).
    - backend/src/features/webhook/router.py: single structured info log on each inbound for future observability.
    - backend/tests/features/webhook/test_phone_normalization.py: 4 new tests covering both directions of the quirk plus non-Brazilian numbers.
  commit e6f1845 — fix(backend): configure root logging so application logs actually appear
    - backend/src/main.py: logging.basicConfig(level=$LOG_LEVEL or INFO, format=..., force=True) at import time.
  commit 4f05ee8 — fix(webhook): send X-Service-Token when calling AI service /chat
    - backend/src/features/webhook/background.py: added headers={"X-Service-Token": settings.mcp_service_token} on the http.post call.
    - backend/tests/features/webhook/test_background_task.py: regression test asserting every http.post call to the AI service carries the correct header.

verification:
  - Unit tests: 68/68 webhook tests pass (previously 67 + 1 new background-task regression).
  - Pre-existing failure in tests/features/chat/test_chat_visibility.py is unrelated (reproduced on main with our changes stashed) — out of scope.
  - Local synthetic probe (signed POST, 12-digit from=558398257544, verified session): full happy path observed end-to-end — webhook 200, /chat 200, MCP tool lifecycle, /students/.../grades 200, Meta Graph API 200. Zero error lines across all three services.
  - Observability: logger.info now emits to docker logs with timestamp/level/name formatting.
  - Live user-initiated round-trip: **pending user verification** (Checkpoint #N).

files_changed:
  - backend/src/features/webhook/service.py
  - backend/src/features/webhook/router.py
  - backend/src/features/webhook/background.py
  - backend/tests/features/webhook/test_phone_normalization.py
  - backend/tests/features/webhook/test_background_task.py
  - backend/src/main.py

## Resolution

root_cause:
fix:
verification:
files_changed: []
