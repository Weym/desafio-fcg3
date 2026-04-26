---
phase: 05-ai-service
reviewed: 2026-04-26T02:53:37Z
depth: standard
files_reviewed: 22
files_reviewed_list:
  - .gitignore
  - ai_service/__init__.py
  - ai_service/agent.py
  - ai_service/config.py
  - ai_service/database.py
  - ai_service/Dockerfile
  - ai_service/ingest.py
  - ai_service/knowledge/calendario.md
  - ai_service/knowledge/curriculo.md
  - ai_service/knowledge/faq.md
  - ai_service/knowledge/matricula.md
  - ai_service/knowledge/regulamento.pdf
  - ai_service/llm_factory.py
  - ai_service/main.py
  - ai_service/mcp_tools.py
  - ai_service/prompts/system_prompt.txt
  - ai_service/rag.py
  - ai_service/requirements.txt
  - ai_service/tests/__init__.py
  - ai_service/tests/test_chat_gap_closure.py
  - ai_service/tests/test_runtime_entrypoint.py
  - docker-compose.yml
findings:
  critical: 1
  warning: 2
  info: 0
  total: 3
status: issues_found
---

# Phase 05: Code Review Report

**Reviewed:** 2026-04-26T02:53:37Z
**Depth:** standard
**Files Reviewed:** 22
**Status:** issues_found

## Summary

Reviewed the current Phase 05 AI-service scope after plans `05-06` and `05-07`. The earlier chat-history and response-extraction gaps are now fixed and covered by tests, but the current phase still ships with one direct session-spoofing exposure and two deployment/configuration problems.

## Critical Issues

### CR-01: `/chat` accepts arbitrary session IDs and is published outside the backend boundary

**File:** `ai_service/main.py:20-23`, `ai_service/main.py:75-105`, `ai_service/mcp_tools.py:19-26`, `docker-compose.yml:84-89`, `docker-compose.yml:126-130`

**Issue:** The AI service accepts a caller-supplied `session_id` in the request body and forwards it directly to MCP as `X-Chat-Session-ID`, but `/chat` performs no service-to-service authentication. At the same time, `docker-compose.yml` publishes both `langchain-service` (`8001`) and `mcp-server` (`8002`) to the host. Any caller that can reach those ports can bypass the FastAPI backend boundary and attempt to act under another chat session.

**Why it matters:** This undermines the intended trust boundary for student context injection. A guessed or stolen session identifier becomes sufficient to query or mutate academic data through the AI/MCP path.

**Fix:** Keep these services private by default and require an internal auth header before accepting `/chat` requests. If host port exposure is only for local development, gate it behind an override file rather than the default compose manifest.

## Warnings

### WR-01: Gemini deployments are wired with the wrong environment variable name

**File:** `ai_service/config.py:20-21`, `ai_service/llm_factory.py:35-41`, `docker-compose.yml:104-107`

**Issue:** The AI service reads Gemini credentials from `GOOGLE_API_KEY`, but the compose service injects only `GEMINI_API_KEY`. A compose-based Gemini deployment therefore starts without the credential the code actually consumes.

**Why it matters:** The phase advertises provider-agnostic OpenAI/Gemini support, but the Gemini path is broken in the default runtime wiring.

**Fix:** Standardize on one variable name across config, compose, and tests. Either rename the service setting to `GEMINI_API_KEY` or export `GOOGLE_API_KEY` into `langchain-service`.

### WR-02: The AI service receives many unrelated secrets it does not use

**File:** `ai_service/config.py:14-34`, `docker-compose.yml:89-109`

**Issue:** `langchain-service` receives unrelated secrets such as `JWT_SECRET`, `WHATSAPP_*`, and `RESEND_API_KEY`, even though Phase 05 code only reads database, LLM, and MCP settings.

**Why it matters:** This widens the blast radius if the service is exposed or compromised, and it makes local/runtime configuration harder to reason about.

**Fix:** Limit the AI-service environment to the variables it actually consumes. Keep backend- and messaging-specific secrets on the services that need them.

## Notes

- `ai_service/tests` currently passes (`16 passed`), and the Phase 05 regressions for assistant-only response extraction and ordered chat persistence are covered.
- The stale pre-`05-06` findings previously present in this file no longer apply to the current source state.

---

_Reviewed: 2026-04-26T02:53:37Z_
_Reviewer: OpenCode manual review after gsd-code-reviewer artifact refresh failed_
_Depth: standard_
