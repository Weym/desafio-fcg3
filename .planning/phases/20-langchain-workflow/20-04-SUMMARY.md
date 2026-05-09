---
phase: 20-langchain-workflow
plan: 04
subsystem: webhook
tags: [lazy-otp, verification, whatsapp, fastapi, async]

# Dependency graph
requires:
  - phase: 06-whatsapp-webhook-integration
    provides: "Verification state machine, session management, background processing"
provides:
  - "Lazy OTP routing — unverified students reach AI agent for read-only operations"
  - "Mid-conversation verification trigger (initiate_mid_conversation_verification method)"
  - "process_message function handling both verified and unverified students"
affects: [ai_service, mcp_server, system_prompt]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Lazy OTP: route by state (awaiting_* → verification, else → agent)"
    - "Mid-conversation verification via session state transition"

key-files:
  created: []
  modified:
    - backend/src/features/webhook/router.py
    - backend/src/features/webhook/background.py
    - backend/src/features/webhook/service.py

key-decisions:
  - "Unverified sessions route to agent; only awaiting_email/awaiting_code trigger verification flow"
  - "Backward-compatible alias (process_verified_message = process_message) preserves existing test imports"
  - "Removed 'unverified' branch from handle_verification_flow — it is no longer reachable via router"

patterns-established:
  - "Lazy OTP gating: phone-based identity trusted for reads; OTP required only for mutations"
  - "State-based routing in webhook: explicit state checks (in tuple) rather than != 'verified'"

requirements-completed: [LANG-14, LANG-04, LANG-03]

# Metrics
duration: 2min
completed: 2026-05-09
---

# Phase 20 Plan 04: Lazy OTP Strategy Summary

**Lazy OTP routing where unverified students reach AI agent for read-only operations; verification triggered mid-conversation only for mutating actions (D-13/D-14/D-15/D-16)**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-09T03:37:40Z
- **Completed:** 2026-05-09T03:39:17Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments
- Unverified students now reach the AI agent for informational queries and read-only MCP tools without OTP friction
- Verification state machine only activates when OTP is in progress (awaiting_email/awaiting_code)
- Added `initiate_mid_conversation_verification` method for agent-triggered verification mid-conversation
- Backward-compatible alias ensures existing imports/tests continue working

## Task Commits

Each task was committed atomically:

1. **Task 1: Modify webhook router to allow unverified students to reach agent** - `9b68400` (feat)
2. **Task 2: Modify webhook service for mid-conversation verification trigger** - `57e8e0b` (feat)

## Files Created/Modified
- `backend/src/features/webhook/router.py` - Lazy OTP routing: unverified → agent, awaiting_* → verification flow
- `backend/src/features/webhook/background.py` - Renamed to process_message, handles both verified/unverified students
- `backend/src/features/webhook/service.py` - Added initiate_mid_conversation_verification, removed unverified branch from handle_verification_flow

## Decisions Made
- Kept backward-compatible alias `process_verified_message = process_message` to avoid breaking other modules or tests that import the old name
- Completely removed the "unverified" state handling from `handle_verification_flow` rather than making it a pass-through, since the router no longer dispatches unverified sessions to that method
- The `initiate_mid_conversation_verification` method is intentionally minimal (just sets state) — the AI agent's response tells the student what to do next

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The agent + MCP middleware layer needs to enforce mutating action gates (system prompt D-21 + MCP middleware safety net)
- Agent system prompt must instruct verification check before mutating tools (covered by other plans in this phase)
- `initiate_mid_conversation_verification` is available for the AI service to call when it detects a mutating action is needed

---
*Phase: 20-langchain-workflow*
*Completed: 2026-05-09*
