---
status: investigating
trigger: "OTP flow rejects valid institutional email and read-only operations skip code step, returning info directly"
created: 2026-05-09T00:00:00Z
updated: 2026-05-09T00:00:00Z
---

## Current Focus

hypothesis: Two separate architectural gaps — (1) the LLM agent handles verification via text (system_prompt rule #9) instead of the backend state machine, causing it to "ask for email" then process the email as a normal message to the agent (not to the OTP flow), and (2) mutating action gating is entirely LLM-based (no programmatic check in MCP middleware), so the agent can skip OTP for read-only ops and hallucinate "not institutional" for mutating ops.
test: Trace the message flow for both scenarios (read-only and mutating) through router.py -> background.py -> ai_service
expecting: Confirm that (a) unverified session messages always go to agent, never to verification flow, (b) agent's "ask for email" text doesn't trigger initiate_mid_conversation_verification, (c) no MCP-level verification gate exists
next_action: Document root cause with evidence

## Symptoms

expected: (1) When unverified student asks for read-only data, system should still return data (by design D-14) but through proper phone identity. (2) When agent requests verification for mutating action, student provides institutional email, system should accept it and send OTP code.
actual: (1) Read-only ops return data with no verification prompt at all — working as designed per D-14 lazy OTP. (2) When student provides email after agent asks for it (mutating action), agent says "email is not institutional" even though it is correct — the email goes to the LLM not the verification state machine.
errors: "Email not institutional" rejection for valid institutional emails during mutating action verification
reproduction: (1) Send read-only question to WhatsApp bot as unverified student → data returned immediately. (2) Request mutating action (e.g. enrollment) → agent asks for email → student provides valid email → agent rejects it as "not institutional".
started: Since lazy OTP (D-13/D-14) was implemented — verification was always handled by LLM text, never properly wired to backend state machine.

## Eliminated

(none yet)

## Evidence

- timestamp: 2026-05-09T00:01:00Z
  checked: router.py lines 174-186 — how verification routing works
  found: Only `awaiting_email` and `awaiting_code` states route to handle_verification_flow. Both `unverified` and `verified` states dispatch to AI agent via process_message.
  implication: An unverified student's messages ALWAYS go to the AI agent. The backend verification state machine is only entered when session.verification_state is already "awaiting_email" or "awaiting_code".

- timestamp: 2026-05-09T00:02:00Z
  checked: service.py line 215 — initiate_mid_conversation_verification method
  found: Method exists to transition session to "awaiting_email" state, but grep shows it is NEVER CALLED anywhere in the codebase. Zero callers.
  implication: The critical bridge between "agent detects mutating action needs verification" and "backend enters OTP state machine" does not exist. The method was written but never wired.

- timestamp: 2026-05-09T00:03:00Z
  checked: system_prompt.txt rule #9
  found: "Antes de executar acoes que alteram dados, verifique se o aluno esta verificado. Se nao, solicite email institucional para verificacao."
  implication: The LLM is told to "check if student is verified" and "ask for institutional email" — but the LLM has NO way to check verification_state (it's not passed to the agent) and NO tool to initiate the OTP flow. The LLM simply generates text asking for email.

- timestamp: 2026-05-09T00:04:00Z
  checked: ai_service/agent.py invoke_agent function — what context the agent receives
  found: Agent receives: system_prompt, chat_history (from chat_messages), user message, is_new_session flag, student_name. It does NOT receive verification_state. It has NO tool to check or change verification state.
  implication: The LLM cannot programmatically know if a student is verified. It tries to enforce verification via text generation, which is unreliable.

- timestamp: 2026-05-09T00:05:00Z
  checked: MCP server middleware.py and dependencies.py — any verification gating
  found: MCP middleware only validates chat_session_id and logs tool calls. Dependencies resolve student_id from session. ZERO checks on verification_state for any tool (mutating or read-only). The `readOnlyHint` annotation exists on read-only tools but is NOT enforced anywhere.
  implication: There is no programmatic gate preventing unverified students from executing mutating actions via MCP tools. The only gate is the LLM's "judgment" based on system prompt rule #9.

- timestamp: 2026-05-09T00:06:00Z
  checked: What happens when LLM asks for email and student replies
  found: Student's email reply goes to router.py → session.verification_state is still "unverified" (nobody called initiate_mid_conversation_verification) → message dispatched to AI agent as regular text. The LLM receives the email as a chat message and tries to "validate" it using its own text-based logic — it has no actual validation function.
  implication: The LLM "validates" email by pattern-matching in natural language, which explains the false "not institutional" rejection — the LLM is hallucinating email validation.

## Resolution

root_cause: |
  TWO interconnected architectural gaps:
  
  **Bug 1 — Read-only bypass (actually by design, but with no safety net):**
  Per D-14 lazy OTP, unverified students CAN use read-only MCP tools (get_grades, get_student_info, etc.). This is WORKING AS DESIGNED. However, the MCP server has no programmatic enforcement of readOnlyHint — if the LLM decides to call a mutating tool (create_enrollment, confirm_enrollment), nothing stops it. The `readOnlyHint` annotation is metadata only, not enforced.
  
  **Bug 2 — Email rejection for mutating actions (the actual bug):**
  When the LLM detects a mutating action is needed, system_prompt rule #9 tells it to "ask for institutional email". The student provides their email. But this email goes BACK to the AI agent as a regular chat message (because session.verification_state is still "unverified" — router.py line 178 only intercepts "awaiting_email"/"awaiting_code"). The LLM tries to "validate" the email using natural language pattern matching and hallucinate whether it's "institutional" or not — there is no actual email validation happening.
  
  The root cause is that `WebhookService.initiate_mid_conversation_verification()` (service.py:215) exists but is NEVER CALLED. This method was designed to transition the session to "awaiting_email" so the NEXT message from the student would be intercepted by the backend's real email validation (service.py:260-309) and OTP flow. Without this call, the email goes to the LLM instead of the state machine.
  
  **Missing integration point:**
  There is no mechanism for the AI agent/MCP layer to signal "verification needed" back to the webhook service to call `initiate_mid_conversation_verification()`. The system_prompt tells the LLM to handle it via text, but the backend state machine can't receive that signal.

fix: (not yet applied)
verification: (not yet verified)
files_changed: []
