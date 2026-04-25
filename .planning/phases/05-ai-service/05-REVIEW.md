---
phase: 05-ai-service
reviewed: 2026-04-25T23:38:12Z
depth: standard
files_reviewed: 22
files_reviewed_list:
  - AGENTS.md
  - .planning/phases/05-ai-service/05-01-PLAN.md
  - .planning/phases/05-ai-service/05-02-PLAN.md
  - .planning/phases/05-ai-service/05-03-PLAN.md
  - .planning/phases/05-ai-service/05-04-PLAN.md
  - .planning/phases/05-ai-service/05-05-PLAN.md
  - .planning/phases/05-ai-service/05-01-SUMMARY.md
  - .planning/phases/05-ai-service/05-02-SUMMARY.md
  - .planning/phases/05-ai-service/05-03-SUMMARY.md
  - .planning/phases/05-ai-service/05-04-SUMMARY.md
  - .planning/phases/05-ai-service/05-05-SUMMARY.md
  - ai_service/config.py
  - ai_service/database.py
  - ai_service/llm_factory.py
  - ai_service/ingest.py
  - ai_service/rag.py
  - ai_service/mcp_tools.py
  - ai_service/agent.py
  - ai_service/main.py
  - ai_service/Dockerfile
  - ai_service/requirements.txt
  - ai_service/prompts/system_prompt.txt
findings:
  critical: 1
  warning: 3
  info: 0
  total: 4
status: issues_found
---

# Phase 05: Code Review Report

**Reviewed:** 2026-04-25T23:38:12Z
**Depth:** standard
**Files Reviewed:** 22
**Status:** issues_found

## Summary

Reviewed the Phase 05 AI service scaffold, RAG flow, MCP tool wiring, and `/chat` endpoint against the phase plans and summaries. The implementation is close to plan, but it currently has one meaningful authorization gap, one conversation-history persistence bug, one response-extraction bug, and no test coverage for the new AI-service behavior.

## Critical Issues

### CR-01: `/chat` trusts arbitrary `session_id` without authenticating the caller

**File:** `ai_service/main.py:64-75`, `ai_service/mcp_tools.py:19-30`
**Issue:** The AI service accepts any `session_id` from the request body and forwards it as `X-Chat-Session-ID` to the MCP server, but the endpoint itself performs no caller authentication or service-token validation. If this service is ever reachable outside the intended private network boundary, a caller can impersonate another chat session and access that student's academic context through MCP tools.
**Fix:** Require an internal authentication mechanism on `/chat` before accepting a session id, e.g. validate a shared service header and reject unauthorized callers.

```python
from fastapi import Header, HTTPException, status

async def require_internal_token(x_service_token: str = Header(...)) -> None:
    if x_service_token != settings.MCP_SERVICE_TOKEN:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN)


@app.post("/chat", response_model=ChatResponse, dependencies=[Depends(require_internal_token)])
async def chat(request: ChatRequest) -> ChatResponse:
    ...
```

## Warnings

### WR-01: User messages are never persisted, so chat history becomes incomplete

**File:** `ai_service/main.py:68-82`
**Issue:** The endpoint saves only the assistant reply. Because `invoke_agent()` reloads history from `chat_messages` on every request, a direct `/chat` conversation loses prior user turns unless another service persisted them beforehand. That breaks the phase goal of observable end-to-end chat behavior from this service alone and weakens future-turn context.
**Fix:** Persist the incoming user message before invoking the agent, or explicitly enforce and document an upstream contract that guarantees user-message persistence before `/chat` is called.

```python
save_chat_message(app.state.db_pool, request.session_id, "user", request.message)
response_text = await invoke_agent(...)
save_chat_message(app.state.db_pool, request.session_id, "assistant", response_text)
```

### WR-02: Agent response extraction can return the wrong message type

**File:** `ai_service/agent.py:35-60`
**Issue:** `_extract_response_text()` always reads `result["messages"][-1]`. In LangChain agent flows the final item is not guaranteed to be the assistant reply; it can be a tool/result message or other structured message. In that case the API can return raw tool output or a stringified structure instead of the final student-facing answer.
**Fix:** Walk backward through the message list and return the last assistant/AI message only.

```python
from langchain_core.messages import AIMessage

for message in reversed(response_messages):
    if isinstance(message, AIMessage):
        return _coerce_content_to_text(message.content)
return FALLBACK_MESSAGE
```

### WR-03: Phase 05 ships without tests for the new AI-service behavior

**File:** `ai_service/agent.py:35-111`, `ai_service/main.py:64-111`, `ai_service/rag.py:16-68`
**Issue:** The repository has tests for backend and MCP server modules, but there is no `ai_service` test coverage for the newly added endpoint, history persistence, RAG threshold behavior, MCP header propagation, or response extraction edge cases. That leaves the highest-risk Phase 05 paths unguarded against regressions.
**Fix:** Add targeted unit/integration tests for at least: `/chat` success/fallback paths, user+assistant persistence ordering, `_extract_response_text()` with non-string and non-final assistant messages, and `create_rag_tool()` no-result / top-3 threshold behavior.

---

_Reviewed: 2026-04-25T23:38:12Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
