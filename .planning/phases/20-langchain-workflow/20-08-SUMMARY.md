---
phase: 20-langchain-workflow
plan: 08
subsystem: ai-service, backend-webhook
tags: [ux, whatsapp, formatting, personalization, gap-closure]
dependency_graph:
  requires: [20-07]
  provides: [plain-text-whatsapp, personalized-welcome]
  affects: [ai_service/prompts/system_prompt.txt, ai_service/agent.py, ai_service/main.py, backend/src/features/webhook/background.py, backend/src/features/webhook/router.py]
tech_stack:
  added: []
  patterns: [post-processing-filter, parameter-threading]
key_files:
  created: []
  modified:
    - ai_service/prompts/system_prompt.txt
    - ai_service/main.py
    - ai_service/agent.py
    - backend/src/features/webhook/background.py
    - backend/src/features/webhook/router.py
decisions:
  - Strip markdown before WhatsApp send but preserve original in DB for Flutter rendering
  - Use defensive post-processing (strip_markdown) even though system prompt instructs plain text
  - Thread student_name through entire chain rather than fetching in AI service
metrics:
  duration: 2m10s
  completed: 2026-05-09T20:13:24Z
  tasks_completed: 2
  tasks_total: 2
  files_modified: 5
requirements: [LANG-01, LANG-07]
---

# Phase 20 Plan 08: WhatsApp Plain-Text Formatting & Personalized Welcome Summary

Strip markdown from LLM responses before WhatsApp delivery and thread student_name for personalized welcome greetings.

## What Was Done

### Task 1: Plain-text formatting rule and strip_markdown post-processing
- Added rule 10 to system prompt instructing agent to format all responses as plain text (no markdown)
- Implemented `_strip_markdown()` helper in background.py that strips **, ##, ```, inline code, and converts markdown lists
- Applied strip_markdown at both WhatsApp send points (main response + escalation response)
- Database `chat_messages` retains original unstripped content for Flutter display

### Task 2: Student name pass-through for personalized welcome
- router.py: passes `student.name` to `process_message()` call
- background.py: accepts `student_name` param and includes it in AI service HTTP POST payload
- ai_service/main.py: added `student_name` field to `ChatRequest` model (defaults to "" for backward compat)
- ai_service/agent.py: accepts `student_name` and interpolates into welcome SystemMessage instruction

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

- `_strip_markdown` correctly removes bold, headers, code blocks, inline code, and list markers
- `ChatRequest` model accepts and defaults `student_name` field
- `process_message` signature includes `student_name` parameter
- `invoke_agent` signature includes `student_name` parameter
- Welcome instruction interpolates student name when provided

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 | 5ba1022 | feat(20-08): add plain-text formatting rule and strip_markdown post-processing |
| 2 | 3808dc4 | feat(20-08): pass student_name through chain for personalized welcome greeting |

## Self-Check: PASSED

All modified files exist and both commits verified in git log.
