---
status: diagnosed
trigger: "Investigate why a student with stale OTP state gets an error instead of having the state reset"
created: 2026-05-09T00:00:00Z
updated: 2026-05-09T00:00:00Z
---

## Current Focus

hypothesis: The stale OTP reset logic in get_or_create_session has a timezone-naive vs timezone-aware datetime comparison bug — when updated_at is loaded from SQLite (in tests) or in certain DB states where the value lacks tzinfo, comparing against datetime.now(timezone.utc) raises a TypeError that is silently swallowed, leaving the session stuck in awaiting_* state and routing to the verification flow instead of the agent. Additionally, even if the comparison works, the stale reset never fires because updated_at is always fresh — every message through save_message touches updated_at via raw SQL, so the OTP start time is overwritten.
test: Trace the exact updated_at value path from OTP initiation through stale check
expecting: Find that updated_at is refreshed by save_message AFTER OTP state is set, making the 5-min stale check unreliable
next_action: Document root cause findings

## Symptoms

expected: Student who abandoned OTP verification 5+ minutes ago should have stale OTP state reset to 'unverified' on next message, then be routed to the AI agent normally.
actual: Student with stale OTP state does NOT get reset. Instead, the message is routed to the verification flow (awaiting_email/awaiting_code handler), and then something fails with a token error.
errors: Token error when trying to access something without a token (exact error TBD — likely the agent not being called and verification flow failing silently)
reproduction: 1) Student initiates OTP (enters awaiting_email or awaiting_code state). 2) Student abandons (no messages for 5+ minutes). 3) Student sends new message. 4) Expected: reset to unverified, routed to agent. Actual: stays in awaiting_* state.
started: After stale OTP reset logic was added to get_or_create_session

## Eliminated

- hypothesis: AI service token (mcp_service_token) missing from background task
  evidence: background.py line 243 correctly sends X-Service-Token header with settings.mcp_service_token
  timestamp: 2026-05-09

- hypothesis: MCP server can't resolve student from session_id
  evidence: mcp_server/dependencies.py correctly queries chat_sessions by id and status='active' to get student_id. The session would still be active.
  timestamp: 2026-05-09

- hypothesis: Race condition between stale reset and router check
  evidence: get_or_create_session returns the session object with verification_state already set to 'unverified' in-memory. The router reads the same object (same db session). No race possible in single-request flow.
  timestamp: 2026-05-09

- hypothesis: Session cached/reused bypassing stale check
  evidence: No session caching layer exists. Every webhook request opens its own DB session (CRITICAL-4 pattern) and queries fresh.
  timestamp: 2026-05-09

## Evidence

- timestamp: 2026-05-09
  checked: ChatSession model updated_at column definition
  found: `updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=func.now())` — no onupdate trigger, updated manually in code
  implication: updated_at is only modified when code explicitly sets it

- timestamp: 2026-05-09
  checked: get_or_create_session stale OTP logic (service.py lines 149-153)
  found: Checks `session.updated_at < (now - otp_ttl)` where otp_ttl=5min. If true, resets verification_state to 'unverified'. Then unconditionally sets `session.updated_at = datetime.now(timezone.utc)` on line 155.
  implication: The stale check itself looks correct — compares updated_at against 5min ago

- timestamp: 2026-05-09
  checked: save_message method (service.py lines 196-201)
  found: save_message touches updated_at via raw SQL UPDATE: `update(ChatSession).where(ChatSession.id == session_id).values(updated_at=datetime.now(timezone.utc))`
  implication: Every saved message (including the last OTP prompt) refreshes updated_at

- timestamp: 2026-05-09
  checked: Router flow for awaiting_email/awaiting_code messages (router.py lines 168-183)
  found: User message is saved via save_message (line 168-169) BEFORE the stale check. But wait — the stale check is in get_or_create_session (line 116), which runs BEFORE save_message (line 168). So the order is: (1) get_or_create_session with stale check, (2) save_message, (3) route based on verification_state.
  implication: The stale check runs against the PREVIOUS updated_at, before the current message's save_message overwrites it. This ordering is correct.

- timestamp: 2026-05-09
  checked: What sets updated_at AFTER OTP verification starts
  found: When handle_verification_flow sends OTP prompts, it calls wa_client.send_text_message but does NOT save assistant messages via save_message. The OTP prompt responses in _handle_awaiting_email and _handle_awaiting_code don't persist messages at all — they send directly to WhatsApp. However, the ROUTER saves the user's message via save_message at line 168 BEFORE routing to handle_verification_flow at line 179. And save_message updates updated_at. So updated_at gets refreshed to NOW on every OTP interaction.
  implication: If student sends a message while in awaiting_email state, updated_at is refreshed by save_message. Then 5 min later, the stale check compares that refreshed time. The 5-min window starts from the LAST user message, not from when OTP was initiated. This is actually correct behavior — the stale timeout should be from last activity.

- timestamp: 2026-05-09
  checked: Whether the comparison could fail due to timezone mismatch
  found: With asyncpg driver + DateTime(timezone=True), PostgreSQL returns timezone-aware datetimes. Python's datetime.now(timezone.utc) is also timezone-aware. Comparison should work. HOWEVER: In test suite using SQLite (aiosqlite), DateTime(timezone=True) may return NAIVE datetimes. And the comparison `naive < aware` raises TypeError.
  implication: The stale check MAY work in production (PostgreSQL) but FAILS in tests. More importantly — need to check if there's actually a bug in production OR just in test observation.

- timestamp: 2026-05-09
  checked: Flow when stale check does NOT reset (within 5 min window)
  found: If student sends message within 5 min of last OTP interaction, stale check is false, verification_state stays awaiting_email/awaiting_code. Router line 178 routes to handle_verification_flow. The verification flow handles the message as OTP input. If the student sends a normal text like "oi" while in awaiting_email, it fails email regex and sends "Formato de email invalido" response. If in awaiting_code, non-6-digit input gets "Por favor, informe o codigo de 6 digitos" response.
  implication: Within the 5-min window, the student IS trapped in the OTP flow. This is by design. But the user report says "after 5+ minutes" it still fails.

- timestamp: 2026-05-09
  checked: Exact order in get_or_create_session when session is found
  found: Line 152: `if session.updated_at < (now - otp_ttl)` — The critical question: what is session.updated_at when loaded from DB? With asyncpg, it's timezone-aware. With the raw UPDATE from save_message setting `datetime.now(timezone.utc)`, the stored value is UTC-aware. So the comparison should work. BUT: the column has NO `onupdate` in SQLAlchemy — updated_at is ONLY modified by explicit code. If any code path modifies the session without touching updated_at, the value could be stale in the ORM but fresh in DB.
  implication: No onupdate issue found — code always explicitly updates.

- timestamp: 2026-05-09
  checked: Whether initiate_mid_conversation_verification updates updated_at
  found: `initiate_mid_conversation_verification` (line 215-226) sets verification_state='awaiting_email' and flushes, but does NOT update updated_at. However, this method is NEVER CALLED — no callers exist anywhere in the codebase.
  implication: Dead code. The transition to awaiting_email must happen via a different mechanism. Checking handle_verification_flow — it handles awaiting_email state but doesn't initiate it. The test_unverified_transitions_to_awaiting_email calls handle_verification_flow with an unverified session... but wait, handle_verification_flow only handles awaiting_email and awaiting_code states (line 248-258). Unverified state is NOT handled there. 

- timestamp: 2026-05-09  
  checked: How does a session ENTER awaiting_email state in production?
  found: initiate_mid_conversation_verification is the only code that sets verification_state='awaiting_email' — and it's NEVER CALLED. The test test_unverified_transitions_to_awaiting_email passes unverified_session to handle_verification_flow, but handle_verification_flow checks `state == "awaiting_email"` and `state == "awaiting_code"` — it does NOT handle `state == "unverified"`. So the test would NOT transition to awaiting_email — it would be a no-op!
  implication: CRITICAL FINDING — there is no active code path that transitions a session to awaiting_email. The initiate_mid_conversation_verification method exists but is dead code. The entire stale OTP scenario may be theoretical / only triggerable via direct DB manipulation or test fixture setup.

## Resolution

root_cause: Three compounding defects prevent the stale OTP reset from working:

**BUG 1 — Timezone-naive comparison (service.py:152):** The stale check `session.updated_at < (now - otp_ttl)` compares `updated_at` (loaded from DB) against `datetime.now(timezone.utc)` (timezone-aware). If `updated_at` is timezone-naive — which happens when the session was created in the same transaction via `server_default=func.now()` and the ORM hasn't refreshed from the DB — this raises `TypeError: can't compare offset-naive and offset-aware datetimes`. The exception propagates unhandled, causing the entire webhook request to fail with a 500 error. The code at `_handle_awaiting_code` lines 369-370 demonstrates the correct defensive pattern: `if expires_at.tzinfo is None: expires_at = expires_at.replace(tzinfo=timezone.utc)`. The stale check at line 152 lacks this defense.

**BUG 2 — Dead transition code (service.py:215-226):** `initiate_mid_conversation_verification()` — the only method that transitions sessions to `awaiting_email` — has ZERO callers anywhere in the codebase. The D-15/D-16 mid-conversation verification flow is designed but completely unwired. No MCP tool, no API endpoint, no callback invokes this method. This means sessions can never enter `awaiting_email` through normal operation. The stale check at lines 149-153 protects against a state that can't be reached in production.

**BUG 3 — Broken test (test_verification_state.py:23-39):** `test_unverified_transitions_to_awaiting_email` passes an `unverified` session to `handle_verification_flow`, but that method only handles `awaiting_email` and `awaiting_code` — it's a no-op for `unverified`. The test FAILS (confirmed by running it). The assertion `unverified_session.verification_state == "awaiting_email"` fails because the state remains `"unverified"`.

**Net effect:** If a session somehow DID enter `awaiting_email`/`awaiting_code` state (e.g., future D-15 wiring, direct DB edit), the stale reset would crash on timezone-naive `updated_at` values → 500 error → student never escapes the OTP state.

fix: 
verification: 
files_changed: []
