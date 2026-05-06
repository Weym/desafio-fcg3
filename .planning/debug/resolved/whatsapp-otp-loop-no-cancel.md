---
status: resolved
trigger: "whatsapp-otp-loop-no-cancel"
created: 2026-05-06T00:00:00Z
updated: 2026-05-06T00:30:00Z
---

## Current Focus

hypothesis: Fix applied and self-verified against the test suite; awaiting human confirmation on WhatsApp in the live stack.
test: Ran `pytest tests/features/webhook/` inside `fcg3-api` container — 75/75 passed including new regression tests for expanded cancel vocabulary and terminal max-attempts behaviour.
expecting: User confirms via live WhatsApp reproduction that sending "cancelar"/"parar" during `awaiting_code` now closes the session and that 3 wrong codes terminate with the new "Sessao encerrada" message.
next_action: Wait for checkpoint response. On confirmation, archive session to `.planning/debug/resolved/` and append to knowledge base.

## Symptoms

expected: Usuário deve conseguir interromper o fluxo de OTP a qualquer momento (ex: enviando "cancelar", "sair", "parar") e o bot deve reconhecer e encerrar/resetar o fluxo. Também deve haver limite de tentativas.
actual: Bot entra em loop pedindo código OTP após receber email válido. Qualquer mensagem que não seja o código correto é ignorada ou tratada como tentativa inválida, sem permitir cancelamento.
errors: Nenhum erro de crash — problema de fluxo/máquina de estados.
reproduction: |
  1. Usuário inicia conversa no WhatsApp com o bot
  2. Bot pede email
  3. Usuário envia email válido
  4. Bot envia OTP por email e pede o código
  5. Usuário tenta qualquer coisa diferente do código correto ("cancelar", "não quero mais", outra pergunta) → bot continua pedindo o código indefinidamente
started: After completion of WhatsApp + LangChain + MCP integration in backend milestone v1.0

## Eliminated

- hypothesis: LangChain agent prompt forces the OTP loop / agent has no escape hatch
  evidence: Router `backend/src/features/webhook/router.py:167` gates the agent behind `session.verification_state == "verified"`. While in `awaiting_email`/`awaiting_code`, the agent is never called. The bug is in the hardcoded state machine, not the ReAct prompt.
  timestamp: 2026-05-06T00:09:00Z

- hypothesis: MCP `verify_otp` tool lacks a retry/exit path
  evidence: OTP generation/verification is NOT exposed as an MCP tool — it runs inline in `WebhookService._handle_awaiting_email` and `_handle_awaiting_code` (`backend/src/features/webhook/service.py:214-372`) using `otp_service.generate_and_send_code` / `otp_service.verify_code_hash` directly from the FastAPI backend. MCP tools (`mcp_server/tools/`) cover curriculum, document, enrollment, grade, scheduling, student — no auth/OTP tool exists.
  timestamp: 2026-05-06T00:09:00Z

## Evidence

- timestamp: 2026-05-06T00:05:00Z
  checked: `backend/src/features/webhook/router.py` lines 147-172 (the cancel-keyword gate and verification dispatch)
  found: |
    Line 148: `if text_content.strip().lower() in {"sair", "encerrar"}:` — the ONLY exit recognized. Hardcoded inline set literal (NOT using the module constant `SESSION_CLOSE_KEYWORDS` defined in service.py:38).
    Line 167: `if session.verification_state != "verified":` → calls `handle_verification_flow` → never reaches agent.
  implication: |
    (a) "cancelar", "parar", "cancelar fluxo", "não quero mais" are not recognized. User-reported vocabulary mismatch confirmed.
    (b) DRY violation: `SESSION_CLOSE_KEYWORDS` constant exists in service.py but router uses its own literal — fix must align both or route through the constant.

- timestamp: 2026-05-06T00:06:00Z
  checked: `backend/src/features/webhook/service.py` lines 224-272 (`_handle_awaiting_email`) and 269-271 (prompt after OTP sent)
  found: OTP-waiting prompt text is `"Enviei um codigo para seu email. Informe o codigo de 6 digitos."` — no mention of any way to exit/cancel. Same with the retry/reprompt messages at lines 292, 360. User has no discoverable path out even if "sair" worked (which it does).
  implication: Even if we expand cancel vocabulary, UX stays broken unless prompts TELL the user how to cancel. Two-part fix: expand keywords AND update prompts.

- timestamp: 2026-05-06T00:07:00Z
  checked: `backend/src/features/webhook/service.py` lines 342-362 (the `MAX_ATTEMPTS_REACHED` branch)
  found: |
    When `code_row.attempts >= settings.otp_max_attempts`:
      code_row.used = True
      await otp_service.generate_and_send_code(db, student.email)  # AUTO-ISSUES NEW CODE
      # Sends "Codigo invalido. Limite atingido. Enviei um novo codigo para seu email."
      # Session stays in verification_state == "awaiting_code"
    No attempt to close the session, no state reset, no rate limiting, no total-attempts counter across OTP cycles.
  implication: |
    The "limit" is per-code only. On every wrong answer, a new code is emailed and the user is kept in `awaiting_code`. This is an INFINITE loop by construction — the user can never trigger a real `MAX_ATTEMPTS_REACHED` end-state.
    Convention requires 429/`MAX_ATTEMPTS_REACHED` to be a terminal state (AGENTS.md CONVENTIONS section, "Rate limiting: 429 for OTP attempts exhausted").
    This is the SECOND defect: even without a cancel, a user who gives up and sends garbage should eventually be bounced out — but currently they can't be.

- timestamp: 2026-05-06T00:08:00Z
  checked: `ai_service/agent.py` and `ai_service/prompts/system_prompt.txt`
  found: The ReAct agent is called only from `process_verified_message` (router dispatches to background only after `verified`). The system prompt has no OTP/verification instructions because the agent never sees pre-verification traffic. No memory/state problem in LangChain for this bug.
  implication: Bug is fully contained in `backend/src/features/webhook/`. AI service needs no changes.

- timestamp: 2026-05-06T00:09:00Z
  checked: `backend/tests/features/webhook/test_session_lifecycle.py` lines 54-84 and grep for "cancel"
  found: Existing tests exercise "sair" and "encerrar" (exact case + case-insensitive) closing the session. NO test covers "cancelar" or any user-friendly variant. NO test covers max-attempts terminal behaviour. This means the convention mismatch is pure drift, not a deliberate test-covered decision.
  implication: Safe to expand the vocabulary and change max-attempts terminal behaviour without breaking existing guarantees. New tests required.

## Resolution

root_cause: |
  Two independent defects in `backend/src/features/webhook/` (the hardcoded verification state machine — the LangChain agent is NOT involved pre-verification):

  1. **Cancel vocabulary is too narrow AND undiscoverable.** Only "sair"/"encerrar" close the session (router.py:148). The OTP prompts ("Enviei um codigo...", "Por favor, informe o codigo...") never tell the user they can cancel with any keyword. Users naturally reach for "cancelar"/"parar"/"não quero mais", which fall through the cancel check, get saved as a user message, and are routed into `_handle_awaiting_code` where they fail the `^\d{6}$` regex — producing the "Por favor, informe o codigo de 6 digitos" reprompt forever.

  2. **`MAX_ATTEMPTS_REACHED` is non-terminal.** When per-code attempts hit the configured max, `_handle_awaiting_code` (service.py:347-355) auto-issues a fresh OTP and keeps the session in `awaiting_code`. There is no global attempt counter and no path to close the session, so a user who never sends a valid 6-digit code has no exit regardless of vocabulary. This violates the `MAX_ATTEMPTS_REACHED` / 429 convention declared in CONVENTIONS.md ("Rate limiting: 429 for OTP attempts exhausted").

fix: |
  Minimal, surgical changes confined to two files:

  File 1 — `backend/src/features/webhook/service.py`:
    - Widen `SESSION_CLOSE_KEYWORDS` to include common user-friendly variants: `{"sair", "encerrar", "cancelar", "cancel", "parar", "stop"}`. Keep set-based lookup (`.strip().lower() in SESSION_CLOSE_KEYWORDS`).
    - Append " (ou envie 'cancelar' para sair)" to the three OTP-waiting prompts (lines 271, 292, 360 originals) so cancel is discoverable.
    - Change the max-attempts branch (lines 347-355): on `code_row.attempts >= settings.otp_max_attempts`, mark `code_row.used = True`, CLOSE the session (`session.status = "closed"`, `ended_at = now`) and send a terminal message ("Numero maximo de tentativas atingido. Sessao encerrada. Envie qualquer mensagem para recomeçar."). Do NOT auto-issue a fresh code. This matches `MAX_ATTEMPTS_REACHED` convention and guarantees the loop terminates.

  File 2 — `backend/src/features/webhook/router.py`:
    - Replace the inline literal `{"sair", "encerrar"}` at line 148 with the imported `SESSION_CLOSE_KEYWORDS` constant from `service.py`. This fixes the DRY violation and guarantees both sites stay in sync.
    - Update the user-visible close response to match new vocabulary ("Sessao encerrada. Ate logo!" can stay — it's already agnostic.).

verification: |
  Self-verified inside `fcg3-api` container via `docker exec fcg3-api python -m pytest tests/features/webhook/ -q`:
    - 75/75 webhook tests pass.
    - Updated test `test_max_attempts_closes_session` asserts: `generate_and_send_code` NOT called, `session.status == "closed"`, `session.ended_at is not None`, `vc.used is True`, terminal message contains "tentativas" + "encerrada".
    - New parametrized test `test_user_friendly_cancel_keywords_recognized` pins "cancelar"/"cancel"/"parar"/"stop" + case/whitespace variants as close keywords.
    - New test `test_legacy_keywords_still_recognized` pins "sair"/"encerrar" to guarantee backward compat.
    - Full backend suite: only pre-existing unrelated failures (chat role authorization, pg_cron migration quoting, phase_01 docker setup). None in webhook/auth.
  HUMAN-VERIFIED (2026-05-06) on live WhatsApp stack: cancellation via expanded vocabulary works end-to-end; max-attempts now closes session without reissuing a new OTP. User reported "confirmed fixed".
files_changed:
  - backend/src/features/webhook/service.py
  - backend/src/features/webhook/router.py
  - backend/tests/features/webhook/test_verification_state.py
  - backend/tests/features/webhook/test_session_lifecycle.py

## DEBUG COMPLETE

**Final state:** resolved (human-verified on live WhatsApp).

**Root cause (summary):** Two independent defects in `backend/src/features/webhook/` — the hardcoded verification state machine, NOT the LangChain agent (agent is gated behind `verification_state == "verified"` at `router.py:167`):
  1. Cancel vocabulary was limited to `{"sair", "encerrar"}` (hardcoded inline at `router.py:148`) and was undiscoverable — OTP prompts never mentioned any exit. Natural user attempts ("cancelar", "parar", "não quero mais") fell through to `_handle_awaiting_code`, failed the `^\d{6}$` regex, and reprompted forever.
  2. `MAX_ATTEMPTS_REACHED` was non-terminal: on the max-attempt code branch, the handler silently reissued a fresh OTP and kept the session in `awaiting_code`, violating the 429 / `MAX_ATTEMPTS_REACHED` convention and guaranteeing an infinite loop for users who couldn't (or didn't want to) enter a valid code.

**Fix summary:**
  - Expanded `SESSION_CLOSE_KEYWORDS` in `service.py` to `{"sair", "encerrar", "cancelar", "cancel", "parar", "stop"}` (case-insensitive via `.strip().lower()`).
  - Appended `"(ou envie 'cancelar' para sair)"` to the three OTP-waiting prompts so cancellation is discoverable.
  - Changed the max-attempts branch in `_handle_awaiting_code`: now marks the code used, sets `session.status = "closed"` / `session.ended_at = now`, sends a terminal "Sessao encerrada. Envie qualquer mensagem para recomecar." message, and does NOT auto-issue a replacement OTP. A follow-up user message will create a fresh `unverified` session per D-13.
  - `router.py` now imports and uses `SESSION_CLOSE_KEYWORDS` from `service.py` instead of an inline literal (eliminates DRY drift).

**Files changed:**
  - `backend/src/features/webhook/service.py`
  - `backend/src/features/webhook/router.py`
  - `backend/tests/features/webhook/test_verification_state.py` (updated `test_max_attempts_closes_session` to assert terminal behaviour)
  - `backend/tests/features/webhook/test_session_lifecycle.py` (added `test_user_friendly_cancel_keywords_recognized` parametrized regression + `test_legacy_keywords_still_recognized`)

**Verification outcome:**
  - 75/75 `tests/features/webhook/` pass in the live `fcg3-api` container.
  - Full backend suite: no NEW failures introduced (pre-existing unrelated failures in chat auth + pg_cron migrations + phase_01 docker tests untouched).
  - Live WhatsApp reproduction confirmed by user: "cancelar"/"parar" cancel the OTP flow; 3 wrong codes terminate the session without reissuing a new OTP.
