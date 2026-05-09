---
phase: 05-ai-service
plan: 06
subsystem: ai
tags: [fastapi, langchain, chat, testing]
requires:
  - phase: 05-ai-service
    plan: 04
    provides: Session-aware agent invocation and mixed LangChain message handling
  - phase: 05-ai-service
    plan: 05
    provides: POST /chat endpoint and assistant fallback flow
provides:
  - Reliable extraction of the final assistant-authored reply from LangChain results
  - Ordered user and assistant persistence for direct AI-service chat requests
  - Regression coverage for the Phase 05 verification gaps
affects: [ai_service/agent.py, ai_service/main.py, ai_service/tests/test_chat_gap_closure.py]
tech-stack:
  added: []
  patterns:
    - Backward scan of LangChain messages until the last AIMessage
    - Endpoint-level regression tests with monkeypatched persistence and agent execution
key-files:
  created: [ai_service/tests/__init__.py, ai_service/tests/test_chat_gap_closure.py]
  modified: [ai_service/agent.py, ai_service/main.py]
key-decisions:
  - "Kept the existing fallback behavior but made response extraction explicitly assistant-only so tool payloads never leak into /chat responses."
  - "Persisted the inbound user turn in the endpoint before agent execution so stateless history reloads reconstruct both sides of the conversation."
patterns-established:
  - "AI service chat persistence now records the user turn before invocation and the assistant turn after success or fallback."
  - "LangChain result parsing now filters by message type instead of trusting the last emitted message."
requirements-completed: [AI-01, AI-02]
duration: unknown
completed: 2026-04-25
---

# Phase 05 Plan 06: Gap Closure Summary

**Assistant-only response extraction and ordered chat persistence that close the final Phase 05 verification gaps with focused regressions.**

## Accomplishments

- Updated `ai_service/agent.py` to walk backward through LangChain messages and return only the last `AIMessage` content.
- Updated `POST /chat` to persist the inbound `role="user"` message before agent execution and keep assistant persistence on success and fallback.
- Added focused regression tests covering both the message-extraction and persistence-order failures called out in `05-VERIFICATION.md`.

## Task Commits

No commit was created in this execution.

## Files Created/Modified

- `ai_service/agent.py` - extracts the final assistant-authored reply instead of trusting the last emitted message.
- `ai_service/main.py` - persists the user turn before `invoke_agent(...)` and preserves assistant persistence behavior.
- `ai_service/tests/__init__.py` - marks the AI service test package.
- `ai_service/tests/test_chat_gap_closure.py` - adds regressions for AI-01 and AI-02.

## Decisions Made

- Reused the existing content-normalization logic by extracting it into a helper instead of adding a second parsing path.
- Kept persistence inside the endpoint rather than moving it into `invoke_agent(...)`, which preserves the current service boundary and minimizes scope.

## Verification

- `python -m pytest ai_service/tests/test_chat_gap_closure.py -q`
- `python -c "from pathlib import Path; text=Path('ai_service/agent.py').read_text(encoding='utf-8'); assert 'reversed(' in text and 'AIMessage' in text"`
- `python -c "from pathlib import Path; text=Path('ai_service/main.py').read_text(encoding='utf-8'); assert 'role=\"user\"' in text and 'role=\"assistant\"' in text"`

## Deviations from Plan

None - plan executed within the intended file scope.

## Issues Encountered

None.

## Self-Check: PASSED

- Found summary file: `.planning/phases/05-ai-service/05-06-SUMMARY.md`
- Found regression module: `ai_service/tests/test_chat_gap_closure.py`
