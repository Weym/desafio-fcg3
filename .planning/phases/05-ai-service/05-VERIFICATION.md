---
phase: 05-ai-service
verified: 2026-04-25T23:50:00Z
status: gaps_found
score:
  passed: 3
  total: 5
requirements:
  passed: [AI-03, AI-04, AI-05]
  gaps: [AI-01, AI-02]
source_summaries:
  - 05-01-SUMMARY.md
  - 05-02-SUMMARY.md
  - 05-03-SUMMARY.md
  - 05-04-SUMMARY.md
  - 05-05-SUMMARY.md
---

# Phase 05 Verification

## Verdict

Phase 05 is not ready to be marked complete. The AI service scaffold, ingest pipeline, RAG tool, MCP loading, and `/chat` endpoint all exist, but two core phase requirements are still only partially met in the live code.

## Requirement Status

| Requirement | Status | Evidence |
|---|---|---|
| AI-01 | GAP | `ai_service/agent.py` builds a ReAct agent and `ai_service/main.py` exposes `/chat`, but `_extract_response_text()` returns the last message blindly (`ai_service/agent.py:35-60`). In LangChain agent flows the last message is not guaranteed to be the final assistant reply, so the endpoint can return tool/result content instead of a coherent student-facing response. |
| AI-02 | GAP | `invoke_agent()` reloads history from `chat_messages` (`ai_service/agent.py:82-87`), but `/chat` only persists the assistant response and never saves the incoming user turn (`ai_service/main.py:68-82`). Direct service-to-service use therefore loses user-side conversation context across turns. |
| AI-03 | PASS | `ai_service/rag.py:11-66` uses `text-embedding-3-small`, pgvector cosine similarity, threshold `0.75`, and `LIMIT 3`, returning an empty string when nothing qualifies. |
| AI-04 | PASS | `ai_service/config.py:18-34` exposes provider settings and `ai_service/llm_factory.py:11-46` switches between `openai:{model}` and `google_genai:{model}` without code changes. |
| AI-05 | PASS | `ai_service/ingest.py:16-269` loads all five knowledge files, chunks with `RecursiveCharacterTextSplitter` 500/50, embeds with `text-embedding-3-small`, and writes chunk rows with delete-then-insert semantics. |

## Gaps Found

### 1. Response extraction is not reliably student-facing

- **Requirement impacted:** AI-01
- **Files:** `ai_service/agent.py:35-60`
- **Issue:** The endpoint trusts the final entry in `result["messages"]` to be the assistant answer. Tool or structured messages can appear last, which means `/chat` may return the wrong content.
- **Expected fix direction:** Walk backward through the returned message list and return the last `AIMessage` only.

### 2. Conversation memory drops user turns

- **Requirement impacted:** AI-02
- **Files:** `ai_service/main.py:68-82`, `ai_service/database.py:44-55`
- **Issue:** `/chat` persists only the assistant reply. Because history is rebuilt from `chat_messages`, a conversation invoked directly through the AI service loses prior user turns unless another upstream service stored them first.
- **Expected fix direction:** Persist the incoming user message before agent invocation, then persist the assistant reply after generation.

## Additional Verification Debt

- No `ai_service/tests/` coverage was added, so the highest-risk Phase 05 behaviors still lack regression protection.
- End-to-end proof with a real LLM provider and live MCP server was not captured in this execution run.

## Recommended Next Step

Plan a gap-closure loop for Phase 05 before marking the phase complete.
