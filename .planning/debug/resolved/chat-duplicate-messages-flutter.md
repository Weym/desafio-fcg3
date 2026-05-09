---
status: resolved
trigger: "Mensagens aparecem duplicadas na tela de chat tanto no app Flutter do client quanto do staff."
created: 2026-05-06T00:00:00Z
updated: 2026-05-06T00:30:00Z
---

## Current Focus

hypothesis: CONFIRMED — double-write between backend webhook flow and AI service. Fix applied and validated.
test: End-to-end human verification in WhatsApp → Flutter (client + staff).
expecting: Each send/receive in the Flutter chat UI appears exactly once.
next_action: (none — resolved)

## Symptoms

expected: Cada mensagem enviada/recebida aparece uma única vez na lista de mensagens do chat.
actual: As mensagens estão sendo renderizadas duplicadas na UI de chat — tanto na interface client quanto na staff (ambos Flutter).
errors: Nenhum erro reportado — é um bug de comportamento, não crash.
reproduction: Abrir a tela de chat (client ou staff) e enviar/receber mensagens. As mensagens aparecem em dobro na lista.
started: Não especificado — reportado ao finalizar integração do chatbot (milestone v2.0 Flutter frontend, phases 7-10).

## Eliminated

<!-- APPEND only -->

## Evidence

- timestamp: 2026-05-06T00:05:00Z
  checked: mobile/lib/features/client/screens/client_chat_detail_screen.dart AND mobile/lib/features/staff/screens/staff_chat_detail_screen.dart
  found: Both screens are read-only. No send-message input, no optimistic update, no Timer/polling, no StreamSubscription, no listener that could append messages client-side. They just `ref.watch(chatMessagesProvider(sessionId))` and render with ListView.builder.
  implication: Duplication cannot be produced by Flutter UI code. Must be in the data layer — either the API response returns duplicates, or the service layer duplicates on parse (ruled out below).

- timestamp: 2026-05-06T00:05:00Z
  checked: mobile/lib/features/client/providers/chat_provider.dart AND staff/providers/staff_chat_provider.dart
  found: Providers are thin wrappers: `Future<List<ChatMessageModel>> chatMessages(ref, sessionId) async => service.getMessages(sessionId);`. No keepAlive on the family (so no cached accumulation). No merging of multiple sources.
  implication: Providers return exactly what the service returns. Not the duplication source.

- timestamp: 2026-05-06T00:05:00Z
  checked: mobile/lib/features/client/services/chat_service.dart AND staff/services/staff_chat_service.dart
  found: Both `getMessages` methods do a single `GET /chat-sessions/{id}/messages` and map the JSON list one-to-one with `ChatMessageModel.fromJson`. No duplication possible here.
  implication: Confirmed — duplication source is server-side. Need to investigate backend.

- timestamp: 2026-05-06T00:08:00Z
  checked: backend/src/features/chat/router.py (GET /chat-sessions/{id}/messages) + service.py::get_session_messages
  found: Clean `SELECT * FROM chat_messages WHERE chat_session_id = :id ORDER BY created_at ASC`. No JOIN, no duplication possible in the query itself.
  implication: If duplicates appear, they are already duplicated rows in the DB table — i.e., a double-write.

- timestamp: 2026-05-06T00:08:30Z
  checked: backend/src/features/webhook/router.py + background.py + service.py (save_message)
  found: On a verified text message, the backend (1) saves the user message with wamid dedup (router line 160), (2) dispatches asyncio.create_task(process_verified_message), and (3) inside the background task AFTER the AI service reply, saves the assistant message via webhook_service.save_message(role='assistant', ..., wamid=None) (background.py line 129).
  implication: Backend writes BOTH user and assistant rows. This is correct behavior on its own.

- timestamp: 2026-05-06T00:09:00Z
  checked: ai_service/main.py::chat endpoint (lines 105-162) and ai_service/database.py::save_chat_message
  found: The AI service ALSO inserts into chat_messages. Line 113 `save_chat_message(role='user', content=request.message)` is called BEFORE agent invocation; line 128 `save_chat_message(role='assistant', content=response_text)` is called after success; line 147 saves the fallback on exception. None of these use wamid, so there is no dedup.
  implication: ROOT CAUSE. On every verified text turn, both the backend AND the AI service independently write user+assistant rows to chat_messages. Net effect: each message shows up twice in GET /chat-sessions/{id}/messages, causing the duplication seen in Flutter client and staff UIs (which are pure read-only consumers of that endpoint).

- timestamp: 2026-05-06T00:09:30Z
  checked: ai_service/agent.py line 96-101 (load_chat_history + in-memory HumanMessage append)
  found: `load_chat_history(...)` loads prior messages from DB; then `all_messages = [*history_messages, HumanMessage(content=user_message)]` appends the current user message in memory before invoking the agent. The agent never relies on `save_chat_message('user', ...)` being called first to see the current user message.
  implication: Removing the AI service's save_chat_message calls will NOT break agent context. The backend already persists user+assistant messages, so next-turn history loading will still see the full conversation.

- timestamp: 2026-05-06T00:09:45Z
  checked: ai_service/tests/test_chat_gap_closure.py
  found: The existing test `test_chat_persists_user_before_agent_and_assistant_after_success` and `test_chat_persists_fallback_after_agent_error` assert the (incorrect) duplicate-write behavior. These tests must be updated to assert that the AI service does NOT persist chat messages and that the agent still runs with the correct user message.
  implication: Fix must include updating these tests. Also, `save_chat_message` in ai_service/database.py becomes unused and can be removed (keep `load_chat_history`, `check_db_health`, `normalize_psycopg_dsn`, `create_pool`).


## Resolution

root_cause: |
  Double-write of chat messages between two services. On every verified text-message turn:
    1. Backend `webhook/router.py` saves the user message to `chat_messages` (with wamid dedup).
    2. Backend `webhook/background.py::process_verified_message` calls `POST {ai_service}/chat`.
    3. AI service `main.py::chat` ALSO saves the user message (no wamid, no dedup) — DUPLICATE #1.
    4. AI service invokes the agent and saves the assistant response — DUPLICATE #2 candidate.
    5. Background task receives the response and saves the assistant message via
       `webhook_service.save_message(role='assistant', ...)` — DUPLICATE #2 confirmed.
  Net result: both user and assistant messages are inserted twice each, so
  `GET /chat-sessions/{id}/messages` returns duplicated rows and the Flutter UI
  (both client and staff) renders them twice. The UI layer is purely read-only
  and was never the source of duplication.
fix: |
  Remove all three `save_chat_message` calls from `ai_service/main.py::chat` and
  stop importing `save_chat_message`. The AI service becomes a pure reasoning
  endpoint: it reads history via `load_chat_history`, appends the current user
  message in memory (agent.py line 101), invokes the agent, and returns the
  response text. The backend remains the single owner of `chat_messages`
  writes. Also removed the now-unused `save_chat_message` helper from
  `ai_service/database.py` to prevent regression. Updated
  `test_chat_gap_closure.py` to assert the new contract (AI service must not
  persist, and the `save_chat_message` symbol must not be importable from
  `ai_service.main`).
verification: |
  Self-verified:
    - `ai_service/main.py`, `ai_service/database.py`, and the test module all
      parse cleanly (ast.parse).
    - `pytest ai_service/tests/test_chat_gap_closure.py -q` → 4 passed.
    - Wider AI-service unit suite: 15 passed; 1 unrelated pre-existing
      docker-compose env-var assertion failure (MCP_SERVER_URL) that predates
      this fix.
  Awaiting human end-to-end verification: send/receive at least one message
  via WhatsApp and confirm the Flutter client+staff chat screens show each
  message exactly once (no duplicates).
files_changed:
  - ai_service/main.py
  - ai_service/database.py
  - ai_service/tests/test_chat_gap_closure.py

## DEBUG COMPLETE

**Final status:** resolved — 2026-05-06

**Root cause (one line):** Both the FastAPI backend and the AI service were independently inserting user+assistant rows into `chat_messages` on every verified text turn, so `GET /chat-sessions/{id}/messages` returned each message twice and the Flutter client + staff chat UIs rendered duplicates.

**Fix applied:** Made the AI service a pure reasoning endpoint — removed all three `save_chat_message` calls and the import from `ai_service/main.py::chat`, removed the now-unused `save_chat_message` helper from `ai_service/database.py`, and rewrote `ai_service/tests/test_chat_gap_closure.py` to pin the new contract (including a `hasattr` guard that prevents re-importing `save_chat_message` into `ai_service.main`). The backend webhook flow (`webhook/router.py` + `webhook/background.py`) remains the single owner of `chat_messages` writes, with wamid-based dedup for inbound user messages.

**Files changed:**
- `ai_service/main.py` — removed 3 `save_chat_message` calls + import; added docstring pinning the persistence-ownership contract.
- `ai_service/database.py` — removed unused `save_chat_message` helper.
- `ai_service/tests/test_chat_gap_closure.py` — rewrote two tests; added regression guard.

**Verification:**
- AST parse clean on all three files.
- `pytest ai_service/tests/test_chat_gap_closure.py -q` → **4 passed**.
- Wider AI-service unit suite: 15 passed; 1 pre-existing unrelated failure (`test_compose_limits_ai_service_env_to_runtime_dependencies` — docker-compose `MCP_SERVER_URL` env-var assertion, untouched by this fix).
- **End-to-end human verification:** user confirmed messages appear exactly once in both Flutter client and Flutter staff chat UIs after redeploy.

**Key insight for future debugging:** When two services share a database table, the dedup mechanism in one service (wamid UNIQUE index in the backend) does NOT protect the other service's writes. The AI service inserted with `wamid=NULL`, so no dedup applied. The architectural rule that emerges: **exactly one service should own writes to any given table**. The Flutter chat screens were a red herring — they are pure read-only consumers and could not have produced duplicates on their own.
