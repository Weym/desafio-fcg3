---
status: complete
phase: 05-ai-service
source: [05-VERIFICATION.md]
started: 2026-05-02T16:15:00Z
updated: 2026-05-02T21:35:00Z
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
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""

- truth: "MCP tool calls execute successfully and mcp_action_logs rows are created with valid UUIDs"
  status: failed
  reason: "User reported: UUID fix works (all rows have non-null id). But ALL MCP tool calls fail with ToolError: Header X-Student-Id obrigatorio para chamadas de servico. MCP server not injecting X-Student-Id header when proxying to FastAPI backend."
  severity: blocker
  test: 2
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""
