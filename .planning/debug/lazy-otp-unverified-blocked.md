---
status: diagnosed
trigger: "Investigate why unverified students cannot access read-only operations without OTP in the Phase 20 LangChain workflow"
created: 2026-05-09T00:00:00Z
updated: 2026-05-09T00:00:00Z
symptoms_prefilled: true
goal: find_root_cause_only
---

## Current Focus

hypothesis: System prompt rule #9 instructs the agent to require email verification before ALL data-altering actions, but the wording is ambiguous and the agent has no way to know the student's verification_state, causing it to proactively ask for verification on ANY tool call.
test: Confirmed by tracing full message flow
expecting: Agent asks for email even for read-only ops because system prompt rule #9 + agent has no verification context
next_action: Return diagnosis

## Symptoms

expected: Unverified student sends read-only question (e.g. "quais minhas notas?") and reaches the AI agent, which answers using read-only MCP tools or RAG without requiring OTP.
actual: Unverified student reaches the AI agent (router correctly routes), but the agent itself asks for email verification before answering read-only queries.
errors: Agent responds with "solicite email institucional para verificacao" for read-only operations.
reproduction: Send any read-only question from an unverified student phone number.
started: Phase 20 LangChain integration.

## Eliminated

- hypothesis: Router incorrectly gates unverified students behind OTP flow
  evidence: router.py:178 only routes awaiting_email/awaiting_code to verification flow. "unverified" state correctly falls through to agent dispatch at line 197.
  timestamp: 2026-05-09

- hypothesis: MCP middleware blocks unverified students
  evidence: mcp_server/middleware.py and mcp_server/dependencies.py have zero references to verification_state — they only validate chat_session_id and student_id from session context.
  timestamp: 2026-05-09

- hypothesis: AI service checks verification state before processing
  evidence: ai_service/main.py and ai_service/agent.py have zero references to verification_state. No verification check in the /chat endpoint or invoke_agent function.
  timestamp: 2026-05-09

## Evidence

- timestamp: 2026-05-09
  checked: backend/src/features/webhook/router.py lines 174-203
  found: Routing logic is CORRECT for lazy OTP. Line 178 checks only for awaiting_email/awaiting_code states. Both "unverified" and "verified" states fall through to the agent dispatch at line 197.
  implication: The backend routing is not the source of the problem.

- timestamp: 2026-05-09
  checked: backend/src/features/webhook/background.py process_message()
  found: Function explicitly documents "Handles both verified and unverified students." No verification_state check. Calls AI service at settings.ai_service_url/chat with session_id, message, is_new_session, student_name — does NOT pass verification_state.
  implication: The background task correctly dispatches to AI without gating on verification.

- timestamp: 2026-05-09
  checked: ai_service/prompts/system_prompt.txt rule #9
  found: "Antes de executar acoes que alteram dados, verifique se o aluno esta verificado. Se nao, solicite email institucional para verificacao."
  implication: CRITICAL — This rule tells the agent to check verification and ask for email, but (1) the agent has NO mechanism to check verification_state (no tool, no context variable), and (2) the wording says "acoes que alteram dados" (data-altering actions) but an LLM may interpret this broadly to include read-only MCP tool calls since both involve "executing tools".

- timestamp: 2026-05-09
  checked: ai_service/agent.py invoke_agent()
  found: No verification_state is passed to the agent. The agent receives only: session_id, user_message, is_new_session, student_name. The system prompt is loaded once at startup.
  implication: The agent has no way to distinguish verified from unverified students, so rule #9 causes it to ALWAYS ask for email before any tool use.

- timestamp: 2026-05-09
  checked: mcp_server/tools/ and mcp_server/middleware.py
  found: Zero references to verification_state anywhere in MCP server. No verification gating at the tool execution layer.
  implication: MCP server is correctly agnostic to verification state — gating should happen elsewhere.

- timestamp: 2026-05-09
  checked: Knowledge base entry for whatsapp-otp-loop-no-cancel
  found: Previous bug described "LangChain agent is gated behind verification_state == 'verified' at router.py:167". This was ALREADY FIXED — router.py now correctly allows unverified through. But the system prompt rule #9 was NOT updated to match the lazy OTP architecture.
  implication: The router fix was necessary but insufficient — the system prompt still instructs the agent to gate ALL tool calls behind verification.

## Resolution

root_cause: System prompt rule #9 in `ai_service/prompts/system_prompt.txt` instructs the agent "Antes de executar acoes que alteram dados, verifique se o aluno esta verificado. Se nao, solicite email institucional para verificacao." This has TWO problems: (1) The agent has NO mechanism to check the student's verification_state — no tool, no context variable, no header. Since it cannot determine verification status, it defensively asks for email on ALL operations. (2) The rule's intent is to gate only MUTATING actions, but "verifique se o aluno esta verificado" gives the agent no way to actually verify — it can only ask. Combined, this causes the agent to proactively ask for email verification even for read-only queries (RAG, read-only MCP tools), breaking the lazy OTP contract (D-13/D-14).
fix:
verification:
files_changed: []
