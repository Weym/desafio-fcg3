---
status: diagnosed
trigger: "farewell detection says goodbye but doesn't actually close the session"
created: 2026-05-09T00:00:00Z
updated: 2026-05-09T00:00:00Z
symptoms_prefilled: true
goal: find_root_cause_only
---

## Current Focus

hypothesis: CONFIRMED — _is_farewell_response's 2+ indicator threshold is too strict AND the indicator list has a singular/plural mismatch ("bom estudo" vs LLM's "bons estudos")
test: Ran 15 realistic LLM farewell responses through _is_farewell_response
expecting: Most should match; found only 5/15 detected as farewell
next_action: Return root cause diagnosis

## Symptoms

expected: When student sends farewell (e.g., "Até mais!", "Obrigado, tchau"), agent responds with goodbye AND session.status changes to 'closed'
actual: Agent responds with goodbye message but chat_sessions.status remains 'active'
errors: No error messages — silent logic failure
reproduction: Student sends farewell message via WhatsApp; agent responds with farewell; session stays active
started: Unknown — may have always been broken

## Eliminated

## Evidence

- timestamp: 2026-05-09T00:01:00Z
  checked: background.py farewell detection flow (lines 321-348)
  found: Code structure is correct — detects farewell in agent response, cancels idle check, opens fresh DB session, loads ChatSession, checks status==active, calls close_session+commit
  implication: If close_session is never reached, the issue is in _is_farewell_response returning False

- timestamp: 2026-05-09T00:02:00Z
  checked: _is_farewell_response implementation (lines 91-99)
  found: Requires 2+ matches from FAREWELL_INDICATORS in the agent response. Indicators are accent-stripped. The function checks the AGENT RESPONSE, not the user message.
  implication: The detection target (agent response) is correct per D-02 design. Issue must be in matching threshold or indicator coverage.

- timestamp: 2026-05-09T00:03:00Z
  checked: FAREWELL_INDICATORS list
  found: ["ate mais", "ate logo", "tchau", "adeus", "bom estudo", "boa sorte", "se precisar", "foi um prazer", "ate a proxima"]
  implication: These are all farewell phrases the LLM might use, but the 2-indicator threshold is critical

- timestamp: 2026-05-09T00:04:00Z
  checked: idle_monitor.py close_session pattern (line 150)
  found: idle_monitor loads session from DB, calls webhook_service.close_session(session, db), then db.commit() — same pattern as background.py farewell code
  implication: The close mechanism itself works (idle monitor uses it successfully), confirming the issue is in detection, not in the close logic

- timestamp: 2026-05-09T00:05:00Z
  checked: close_session implementation in service.py (lines 207-213)
  found: Sets session.status = "closed" and session.ended_at = now, then flush(). Uses ORM attribute mutation on the loaded instance.
  implication: close_session works correctly when called. The problem is it's not being reached.

- timestamp: 2026-05-09T00:06:00Z
  checked: _is_farewell_response against 15 realistic LLM farewell responses
  found: Only 5/15 detected as farewell. 10/15 had only 1 indicator match and were MISSED. Examples of missed responses: "Até mais! Bons estudos!" (1 match: ate mais — "bom estudo" doesn't match "bons estudos"), "Ok, até mais!" (1 match), "Tchau!" (1 match), "Adeus!" (1 match), "De nada! Tchau!" (1 match)
  implication: The 2+ threshold causes most legitimate farewell responses to be silently ignored. Session never closes.

- timestamp: 2026-05-09T00:07:00Z
  checked: FAREWELL_INDICATORS singular/plural mismatch
  found: Indicator "bom estudo" (singular) never matches LLM output "bons estudos" (plural). The substring match fails because "bom estudo" is not a substring of "bons estudos". This means "Até mais! Bons estudos!" only matches 1 indicator instead of the expected 2.
  implication: Even responses that seem like they should match 2 indicators only match 1 due to this form mismatch. Compounds the threshold problem.

## Resolution

root_cause: Two compounding defects in `_is_farewell_response` (background.py:91-99) cause 67% of legitimate farewell responses to go undetected: (1) The 2+ indicator threshold is too strict — typical LLM farewell responses contain only 1 farewell phrase (e.g., "Tchau!", "Até mais!", "De nada! Tchau!"), so the function returns False and close_session is never called; (2) The indicator "bom estudo" (singular) never matches the LLM's natural output "bons estudos" (plural) because substring matching fails ("bom estudo" ∉ "bons estudos"), robbing responses like "Até mais! Bons estudos!" of their expected second match. The close_session mechanism itself works correctly (proven by idle_monitor using the identical pattern) — the bug is purely in the detection gate.
fix:
verification:
files_changed: []
