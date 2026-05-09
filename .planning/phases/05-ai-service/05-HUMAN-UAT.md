---
status: diagnosed
phase: 05-ai-service
source: [05-VERIFICATION.md]
started: 2026-05-02T16:15:00Z
updated: 2026-05-02T21:45:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Re-run UAT Test 3 (academic policy via /chat with new threshold)

expected: POST /chat with a valid `X-Service-Token` and an academic-policy question (e.g. "Quais são os critérios para tranca de matrícula?") returns a Portuguese answer grounded in knowledge-base chunks (not the fallback). With `RAG_SIMILARITY_THRESHOLD=0.45` (default) and OpenRouter-proxied embeddings, relevant chunks scoring ≥ 0.45 must reach the agent and be cited in the response.
result: issue
reported: "RAG grounding still not working. Agent returns generic fallback: 'Desculpe, mas no momento não consigo acessar o sistema para fornecer os critérios exatos de trancamento de matrícula.' Response contains generic advice (consulte regulamento, entre em contato com secretaria) instead of knowledge-base content. The agent appears to not even attempt the RAG tool or MCP tools — falling back to parametric knowledge."
severity: blocker

### 2. MCP tool call without crash (mcp_action_logs INSERT)

expected: Send a question that should trigger an MCP tool call, e.g. "Quais são minhas matrículas ativas?" POST /chat with a valid chat session. Verify the response comes back without error and `SELECT * FROM mcp_action_logs ORDER BY created_at DESC LIMIT 5;` shows rows with non-null UUID `id` column populated by `gen_random_uuid()` — no NOT NULL violation.
result: issue
reported: "UUID fix works — all 4 mcp_action_logs rows have non-null id (id_ok = t, gen_random_uuid() functioning). However, ALL MCP tool calls fail with status 'error'. MCP server logs show: ToolError: Erro: Header X-Student-Id obrigatorio para chamadas de servico. The MCP server is not injecting X-Student-Id header when proxying calls to FastAPI backend. Tools affected: get_student_info, get_available_courses, get_enrollment_period. Agent falls back to generic advice."
severity: blocker

### 3. Provider switch (LLM_PROVIDER=gemini or alternate provider)

expected: Set `LLM_PROVIDER=gemini` (or any non-openai supported provider available to you) in `.env`, `docker compose restart langchain-service`, send the same academic question via POST /chat — receive a valid Portuguese response without code changes. If no alternate provider API key is available, this item can be marked SKIPPED — unit test `test_create_llm_builds_gemini_client` already verifies the code path.
result: skipped
reason: "Only OpenRouter will be used as provider — no alternate provider needed"

## Summary

total: 3
passed: 0
issues: 2
pending: 0
skipped: 1
blocked: 0

## Gaps

- truth: "POST /chat with a Portuguese academic question returns a response grounded in knowledge-base chunks, not the generic fallback"
  status: failed
  reason: "User reported: RAG grounding still not working. Agent returns generic fallback 'não consigo acessar o sistema' with generic advice instead of knowledge-base content. The agent does not appear to invoke the RAG tool or MCP tools."
  severity: blocker
  test: 1
  root_cause: "Two compounding causes: (1) MCP tool failures (X-Student-Id missing) cause the ReAct agent to conclude 'the system is inaccessible' and give up on ALL tools — including the local RAG tool which does NOT depend on MCP. The agent never reaches search_knowledge_base because it stops after MCP errors. (2) System prompt at ai_service/prompts/system_prompt.txt line 12-13 tells the agent the relevance threshold is 0.75, but the actual code threshold is 0.45 — even if RAG runs, the LLM may discard valid results in the 0.45-0.74 range as 'not relevant'."
  artifacts:
    - path: "ai_service/prompts/system_prompt.txt"
      issue: "Lines 12-13: Tells agent threshold is 0.75 but code uses 0.45 — prompt-code mismatch"
    - path: "ai_service/agent.py"
      issue: "Lines 89-94: RAG tool IS registered alongside MCP tools — not a binding issue"
    - path: "ai_service/rag.py"
      issue: "Lines 20-62: Local RAG tool (direct DB query) is mechanically sound but never gets called due to agent behavior cascade"
  missing:
    - "Fix X-Student-Id injection in MCP (see Gap 2) — this unblocks agent tool usage"
    - "Update system_prompt.txt to match actual RAG_SIMILARITY_THRESHOLD (0.45 or make it dynamic)"
    - "Consider adding resilience: agent should still try RAG tool even if MCP tools fail"
  debug_session: ""

- truth: "MCP tool calls execute successfully and mcp_action_logs rows are created with valid UUIDs"
  status: failed
  reason: "User reported: UUID fix works (all rows have non-null id). But ALL MCP tool calls fail with ToolError: Header X-Student-Id obrigatorio para chamadas de servico. MCP server not injecting X-Student-Id header when proxying to FastAPI backend."
  severity: blocker
  test: 2
  root_cause: "MCP server resolves student_id correctly from chat_sessions via resolve_student_id() (mcp_server/dependencies.py:54-62), but only passes it in URL paths or JSON bodies — never as the X-Student-Id HTTP header. The shared httpx.AsyncClient (mcp_server/lifespan.py:22-28) sets X-Service-Token but not X-Student-Id (it's per-request, not static). FastAPI backend (backend/src/shared/dependencies.py:99-103) requires X-Student-Id header when X-Service-Token is present — raises 401 IDENTIFICACAO_AUSENTE if absent."
  artifacts:
    - path: "mcp_server/lifespan.py"
      issue: "Lines 22-28: httpx client sets X-Service-Token but no X-Student-Id (static headers only)"
    - path: "mcp_server/api_client.py"
      issue: "Lines 52-80: call_api_raw has no logic to inject X-Student-Id; passes **kwargs through"
    - path: "mcp_server/tools/student_tools.py"
      issue: "Lines 23-28: call_api() invoked without headers kwarg — student_id only in URL path"
    - path: "mcp_server/tools/enrollment_tools.py"
      issue: "Lines 17-34: Same pattern — student_id in body/path but not header"
    - path: "mcp_server/tools/grade_tools.py"
      issue: "Lines 18-31: Same pattern"
    - path: "mcp_server/tools/document_tools.py"
      issue: "Lines 17-29: Same pattern"
    - path: "mcp_server/tools/scheduling_tools.py"
      issue: "Lines 41-53: Same pattern"
    - path: "backend/src/shared/dependencies.py"
      issue: "Lines 98-103: The guard that rejects when X-Student-Id is missing (this is correct behavior)"
  missing:
    - "Modify call_api/call_api_raw in api_client.py to accept student_id parameter and inject as X-Student-Id header"
    - "Update ALL tool functions to pass student_id to call_api(..., student_id=student_id)"
    - "Centralized injection preferred over per-tool headers to prevent omission in future tools"
  debug_session: ""
