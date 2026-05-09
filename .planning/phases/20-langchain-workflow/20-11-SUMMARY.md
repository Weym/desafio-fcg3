---
phase: 20-langchain-workflow
plan: 11
subsystem: auth
tags: [mcp, middleware, verification, lazy-otp, system-prompt, langchain]

# Dependency graph
requires:
  - phase: 20-langchain-workflow (plan 10)
    provides: MCP tool annotations with readOnlyHint, lazy OTP webhook routing
provides:
  - MCP middleware verification gate blocking mutating tools for unverified students
  - System prompt rule #9 rewritten for lazy OTP (reads free, mutations gated)
  - verification_state end-to-end flow from router to agent
  - Agent context injection for unverified students
affects: [20-langchain-workflow UAT tests 5 and 6]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "MCP middleware verification gate using readOnlyHint annotations"
    - "End-to-end verification_state propagation through HTTP service boundary"
    - "SystemMessage context injection for unverified students"

key-files:
  created: []
  modified:
    - mcp_server/middleware.py
    - mcp_server/dependencies.py
    - ai_service/prompts/system_prompt.txt
    - ai_service/main.py
    - ai_service/agent.py
    - backend/src/features/webhook/background.py
    - backend/src/features/webhook/router.py

key-decisions:
  - "MCP middleware reads verification_state from DB (authoritative source), not from HTTP body — defense in depth"
  - "Verification context SystemMessage only injected for unverified students to save tokens"
  - "ToolError message in Portuguese instructs agent to ask student for email"

patterns-established:
  - "readOnlyHint annotation check in middleware for verification gating"
  - "verification_state propagation: router → background → AI service → agent"

requirements-completed: [LANG-04, LANG-09, LANG-10]

# Metrics
duration: 2min
completed: 2026-05-09
---

# Phase 20 Plan 11: Lazy OTP Verification Gate Summary

**MCP middleware verification gate blocking mutating tools for unverified students, system prompt rewritten for lazy OTP, and verification_state flowing end-to-end from webhook router to LangChain agent**

## Performance

- **Duration:** 2 min
- **Started:** 2026-05-09T21:51:50Z
- **Completed:** 2026-05-09T21:54:03Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments
- MCP middleware now blocks mutating tools (no readOnlyHint) for unverified students with actionable ToolError
- Read-only tools (readOnlyHint=True) pass through freely for all students
- System prompt rule #9 rewritten: reads don't require verification, mutations gated by MCP middleware
- verification_state flows end-to-end: router.py → background.py → ai_service/main.py → agent.py
- Agent receives SystemMessage with verification context for unverified students

## Task Commits

Each task was committed atomically:

1. **Task 1: MCP middleware verification gate + system prompt rewrite** - `4d74818` (feat)
2. **Task 2: Pass verification_state from backend through AI service to agent** - `aa6e98c` (feat)

## Files Created/Modified
- `mcp_server/middleware.py` - Added _enforce_verification_gate method with readOnlyHint check
- `mcp_server/dependencies.py` - Added verification_state to validate_active_chat_session query
- `ai_service/prompts/system_prompt.txt` - Rewrote rule #9 for lazy OTP (reads free, mutations gated)
- `ai_service/main.py` - Added verification_state to ChatRequest model and invoke_agent call
- `ai_service/agent.py` - Added verification_state param and SystemMessage injection for unverified
- `backend/src/features/webhook/background.py` - Added verification_state param and HTTP body field
- `backend/src/features/webhook/router.py` - Passes session.verification_state to process_message

## Decisions Made
- MCP middleware reads verification_state from DB (authoritative source), not from HTTP body — even if HTTP body is spoofed, the DB-level check in middleware is the enforcement layer
- Verification context SystemMessage only injected for unverified students to save tokens for verified ones
- ToolError message in Portuguese instructs the agent to ask student for email verification

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 20 is now complete (plan 11 of 11)
- All lazy OTP layers are in place: webhook routing, MCP middleware gate, system prompt alignment
- Ready for UAT verification of Tests 5 and 6

## Self-Check: PASSED

All 7 modified files verified on disk. Both commit hashes (4d74818, aa6e98c) found in git log.

---
*Phase: 20-langchain-workflow*
*Completed: 2026-05-09*
