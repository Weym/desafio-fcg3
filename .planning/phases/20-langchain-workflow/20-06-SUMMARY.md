---
phase: 20-langchain-workflow
plan: 06
subsystem: webhook
tags: [langchain, asyncio, session-lifecycle, whatsapp, idle-timeout, farewell-detection]

# Dependency graph
requires:
  - phase: 20-langchain-workflow plan 01
    provides: "System prompt with Alpha persona and farewell instructions"
  - phase: 20-langchain-workflow plan 04
    provides: "AI service agent invocation and /chat endpoint"
provides:
  - "AI-generated welcome message on new sessions (is_new_session flag)"
  - "Farewell detection with automatic session close (2+ indicator threshold)"
  - "Idle timeout monitor: 5-min follow-up + 10-min auto-close"
  - "3-layer session end: AI farewell, 24h pg_cron, 5-10min idle"
affects: [webhook-processing, ai-service-chat, session-management]

# Tech tracking
tech-stack:
  added: []
  patterns: [asyncio-idle-timer, farewell-indicator-threshold, is_new_session-flag-propagation]

key-files:
  created:
    - backend/src/features/webhook/idle_monitor.py
  modified:
    - backend/src/features/webhook/background.py
    - backend/src/features/webhook/router.py
    - backend/src/features/webhook/service.py
    - ai_service/agent.py
    - ai_service/main.py

key-decisions:
  - "Farewell detection uses 2+ indicator threshold (not regex or single keyword) for natural language understanding"
  - "get_or_create_session returns (session, is_new) tuple to signal new session to router"
  - "Idle timers use asyncio.Task per session — reset on each new message"
  - "Welcome instruction injected as SystemMessage only when is_new_session=True AND no prior history"

patterns-established:
  - "is_new_session propagation: router -> background -> AI service -> agent"
  - "Idle timer lifecycle: schedule on response, cancel on farewell/close, cleanup in finally"
  - "Farewell indicator threshold pattern for session close detection"

requirements-completed: [LANG-01, LANG-02, LANG-06]

# Metrics
duration: 4min
completed: 2026-05-09
---

# Phase 20 Plan 06: Session Lifecycle Summary

**AI welcome on new sessions, farewell-triggered session close with 2+ indicator threshold, and asyncio idle timeout monitor (5-min follow-up + 10-min auto-close)**

## Performance

- **Duration:** 4 min
- **Started:** 2026-05-09T03:44:13Z
- **Completed:** 2026-05-09T03:47:49Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- AI-generated personalized welcome message when student starts a new session (D-01, LANG-01)
- Agent farewell detection with 2+ indicator threshold closes session automatically (D-02 Layer 1)
- Idle timeout monitor with 5-min follow-up and 10-min auto-close (D-02 Layer 3, D-03)
- Complete 3-layer session end detection operational (AI farewell + 24h pg_cron + idle timeout)
- Existing escalation logic (HI-01) preserved unchanged

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement welcome message and farewell-triggered session close** - `d5f71ed` (feat)
2. **Task 2: Implement idle timeout monitor with follow-up and auto-close** - `973af4b` (feat)

## Files Created/Modified
- `backend/src/features/webhook/idle_monitor.py` - Asyncio idle timeout with 2-phase check (5min + 5min)
- `backend/src/features/webhook/background.py` - is_new_session param, farewell detection, idle integration
- `backend/src/features/webhook/router.py` - New session detection, pass is_new_session to process_message
- `backend/src/features/webhook/service.py` - get_or_create_session returns (session, is_new) tuple
- `ai_service/agent.py` - Welcome instruction injection on new sessions
- `ai_service/main.py` - is_new_session field in ChatRequest model

## Decisions Made
- Used 2+ farewell indicator threshold instead of single keyword matching — reduces false positives when agent casually mentions one phrase
- Modified `get_or_create_session` to return tuple `(session, is_new)` — cleanest signal for new session detection without fragile timestamp comparison
- Idle timer resets on every `process_message` call (via `schedule_idle_check`) — ensures genuine idle detection per D-03
- Welcome SystemMessage only injected when `is_new_session=True` AND `history_messages` is empty — prevents duplicate welcomes on reconnection

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Modified get_or_create_session return type to tuple**
- **Found during:** Task 1 (Welcome message detection)
- **Issue:** Plan says "router already knows if session was just created" but no reliable detection mechanism existed
- **Fix:** Changed `get_or_create_session` to return `tuple[ChatSession, bool]` — is_new flag signals creation
- **Files modified:** backend/src/features/webhook/service.py, backend/src/features/webhook/router.py
- **Verification:** Router correctly receives and propagates is_new_session flag
- **Committed in:** d5f71ed (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** Essential for correct new session detection. No scope creep.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Session lifecycle complete: welcome → assistance → farewell/idle/timeout
- Ready for integration testing with full conversation flows
- Idle timeout values (5min/10min) are configurable constants if tuning needed

---
*Phase: 20-langchain-workflow*
*Completed: 2026-05-09*
