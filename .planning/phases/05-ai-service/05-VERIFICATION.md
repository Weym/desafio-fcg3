---
phase: 05-ai-service
verified: 2026-04-26T00:35:00Z
status: complete
score: 5/5 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 3/5
  gaps_closed:
    - "The AI service returns the last assistant-authored LangChain message instead of trusting the last emitted message."
    - "The /chat endpoint persists the inbound user turn before agent execution and keeps assistant persistence on success/fallback."
    - "AI-RUNTIME-01 was corrected by plan `05-07`, restoring container startup and live health verification for the AI service."
  gaps_remaining:
    []
  regressions: []
human_verification: []
gaps: []
---

# Phase 5: AI Service Verification Report

**Phase Goal:** The AI service can ingest academic knowledge, rebuild chat memory, call MCP tools through a provider-agnostic LangChain agent, and answer `/chat` requests with a student-facing Portuguese response.
**Verified:** 2026-04-26T00:35:00Z
**Status:** complete
**Re-verification:** Yes - after gap closure

## Verdict

Phase 05 is complete. The previously closed code gaps remain closed, `AI-RUNTIME-01` was corrected by plan `05-07`, `docker compose ps` now shows `fcg3-ai` as `healthy`, `curl -sf http://localhost:8001/health` returns `{"status":"healthy"}`, `python -m pytest ai_service/tests -q` returns `7 passed`, and `/gsd-verify-work 05` concluded the phase as `complete` with `05-UAT.md` updated to `4/4` tests passing.

## Requirement Status

| Requirement | Status | Evidence |
| --- | --- | --- |
| AI-01 | PASS | `ai_service/agent.py:56-67` now scans backward through `result["messages"]` and returns only the last `AIMessage`; `ai_service/tests/test_chat_gap_closure.py:14-25` proves trailing tool messages do not leak into the response. |
| AI-02 | PASS | `ai_service/main.py:68-94` persists `role="user"` before `invoke_agent(...)` and persists `role="assistant"` after success; `ai_service/tests/test_chat_gap_closure.py:28-58` and `:61-93` verify ordered persistence on success and fallback. |
| AI-03 | PASS | `python -c` validation confirmed `ai_service/rag.py` parses and still contains `@tool`, `embed_query`, threshold `0.75`, and `LIMIT 3`; knowledge retrieval wiring remains intact. |
| AI-04 | PASS | `python -c` validation confirmed `ai_service/config.py` and `ai_service/llm_factory.py` parse cleanly and still contain both `openai:` and `google_genai:` provider string formats. |
| AI-05 | PASS | `python -c` validation confirmed `ai_service/ingest.py` parses, retains delete-then-insert semantics, `CATEGORY_MAP`, `RecursiveCharacterTextSplitter`, and `text-embedding-3-small`; the five expected knowledge files are present under `ai_service/knowledge/`. |

## Automated Verification Run

| Check | Result |
| --- | --- |
| `python -m pytest ai_service/tests -q` | PASS - `7 passed` |
| `python -c "import ast; ast.parse(open('ai_service/agent.py').read()); ast.parse(open('ai_service/main.py').read())"` | PASS |
| `python -c "import ast; ast.parse(open('ai_service/rag.py').read())"` + pattern assertions | PASS |
| `python -c "import ast; ast.parse(open('ai_service/config.py').read()); ast.parse(open('ai_service/llm_factory.py').read())"` + provider pattern assertions | PASS |
| `python -c "import ast; ast.parse(open('ai_service/ingest.py').read())"` + ingest pattern assertions | PASS |
| `python -c "import os; ..."` knowledge file presence check | PASS |
| `curl -sf http://localhost:8001/health` | PASS - `{"status":"healthy"}` |
| `docker compose ps` | PASS - `fcg3-ai` is `healthy` |
| `/gsd-verify-work 05` | PASS - phase marked `complete`; `05-UAT.md` updated with `4/4` tests passing |

## Runtime Verification

- Plan `05-07` corrected the runtime/container import-path failure tracked as `AI-RUNTIME-01`.
- `docker compose ps` shows `fcg3-ai` as `healthy`.
- `curl -sf http://localhost:8001/health` returns `{"status":"healthy"}`.
- Live verification confirms the AI service starts and serves health checks normally.

## Gap Status

- No open gaps remain for Phase 05.

## Final Outcome

`/gsd-verify-work 05` concluded the phase as `complete`, with all must-have requirements verified, live runtime checks passing, and UAT recorded as `4/4` passing.
