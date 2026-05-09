---
phase: 05-ai-service
fixed_at: 2026-04-26T00:07:06.9318714-03:00
review_path: .planning/phases/05-ai-service/05-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 05: Code Review Fix Report

**Fixed at:** 2026-04-26T00:07:06.9318714-03:00
**Source review:** `.planning/phases/05-ai-service/05-REVIEW.md`
**Iteration:** 1

**Summary:**

- Findings in scope: 3
- Fixed: 3
- Skipped: 0

## Fixed Issues

### CR-01: `/chat` accepts arbitrary session IDs and is published outside the backend boundary

**Files modified:** `ai_service/main.py`, `ai_service/config.py`, `ai_service/tests/test_chat_gap_closure.py`, `ai_service/tests/test_runtime_entrypoint.py`, `docker-compose.yml`
**Commit:** `e9553a2`
**Applied fix:** Required `X-Service-Token` on `/chat` with constant-time validation, added regression coverage, and removed default host port publishing for the AI and MCP services.

### WR-01: Gemini deployments are wired with the wrong environment variable name

**Files modified:** `ai_service/config.py`, `ai_service/llm_factory.py`, `ai_service/tests/test_llm_factory.py`
**Commit:** `757bf38`
**Applied fix:** Standardized Gemini credential loading on `GEMINI_API_KEY` across runtime config, model construction, and tests.

### WR-02: The AI service receives many unrelated secrets it does not use

**Files modified:** `docker-compose.yml`, `ai_service/tests/test_runtime_entrypoint.py`
**Commit:** `38ad4b1`
**Applied fix:** Reduced the `langchain-service` environment to only the settings consumed by Phase 05 code and added compose assertions to prevent secret sprawl regression.

---

_Fixed: 2026-04-26T00:07:06.9318714-03:00_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
