---
phase: 20-langchain-workflow
plan: 09
subsystem: ai, webhook
tags: [langchain, farewell-detection, welcome-message, chatbot, session-management]

# Dependency graph
requires:
  - phase: 20-langchain-workflow (plans 01-08)
    provides: Agent factory, webhook background processing, session management
provides:
  - Personalized welcome message on new chat sessions (is_new_session flag)
  - Tiered farewell detection with strong/weak indicators for session closure
affects: [20-10, 20-11, UAT verification]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Tiered indicator pattern: strong (1 match) vs weak (2+ matches) for NLP-lite detection"

key-files:
  created: []
  modified:
    - ai_service/agent.py
    - backend/src/features/webhook/background.py

key-decisions:
  - "Removed 'and not history_messages' guard — is_new_session flag is the reliable indicator since the router commits the user message to DB before dispatching the background task"
  - "Split farewell indicators into strong (1 match sufficient) and weak (2+ required) tiers to reduce false negatives while preventing false positives"
  - "Added 'bons estudos' (plural) and 'estou a disposicao' as new farewell indicators — LLM naturally generates these phrases"

patterns-established:
  - "Tiered NLP indicator pattern: strong indicators (explicit intent, 1 match) vs weak indicators (polite closings, 2+ matches)"

requirements-completed: [LANG-01, LANG-08]

# Metrics
duration: 1min
completed: 2026-05-09
---

# Phase 20 Plan 09: Welcome & Farewell Fix Summary

**Fixed welcome message personalization (removed stale history guard) and implemented tiered strong/weak farewell detection for reliable session closure**

## Performance

- **Duration:** 1 min
- **Started:** 2026-05-09T21:45:56Z
- **Completed:** 2026-05-09T21:47:10Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments
- Welcome message now includes student's name on all new sessions (UAT Test 9)
- Farewell detection uses tiered strong/weak indicators for reliable session closure (UAT Test 10)
- Added missing LLM farewell phrases ("bons estudos", "estou a disposicao")

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix welcome message condition (UAT Test 9)** - `c1250c8` (fix)
2. **Task 2: Fix farewell detection threshold and indicators (UAT Test 10)** - `7166a68` (fix)

## Files Created/Modified
- `ai_service/agent.py` - Removed `and not history_messages` from welcome condition (line 155)
- `backend/src/features/webhook/background.py` - Replaced flat FAREWELL_INDICATORS with tiered STRONG/WEAK system and rewrote `_is_farewell_response`

## Decisions Made
- **Welcome condition**: Removed `and not history_messages` guard because the router commits the user message to DB before dispatching the background task, making `history_messages` always non-empty on new sessions. The `is_new_session` flag from `get_or_create_session()` is the reliable indicator.
- **Tiered farewell detection**: Strong indicators (tchau, adeus, etc.) trigger with 1 match. Weak indicators (boa sorte, se precisar, etc.) need 2+ matches. This prevents false negatives on typical LLM goodbyes while avoiding false positives from casual mentions.
- **New indicators**: Added "bons estudos" (LLM uses plural form) and "estou a disposicao" (common LLM farewell phrase) that were missing from the original list.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Welcome and farewell bugs fixed, ready for plans 10-11 (remaining Phase 20 work)
- Both fixes are independent and don't affect other plan areas

## Self-Check: PASSED

All files verified on disk, all commit hashes found in git log.

---
*Phase: 20-langchain-workflow*
*Completed: 2026-05-09*
