---
status: partial
phase: 05-ai-service
source: [05-VERIFICATION.md]
started: 2026-05-02T16:15:00Z
updated: 2026-05-02T16:15:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Re-run UAT Test 3 (academic policy via /chat with new threshold)

expected: POST /chat with a valid `X-Service-Token` and an academic-policy question (e.g. "Quais são os critérios para tranca de matrícula?") returns a Portuguese answer grounded in knowledge-base chunks (not the fallback). With `RAG_SIMILARITY_THRESHOLD=0.45` (default) and OpenRouter-proxied embeddings, relevant chunks scoring ≥ 0.45 must reach the agent and be cited in the response.
result: [pending]

### 2. MCP tool call without crash (mcp_action_logs INSERT)

expected: Send a question that should trigger an MCP tool call, e.g. "Quais são minhas matrículas ativas?" POST /chat with a valid chat session. Verify the response comes back without error and `SELECT * FROM mcp_action_logs ORDER BY created_at DESC LIMIT 5;` shows rows with non-null UUID `id` column populated by `gen_random_uuid()` — no NOT NULL violation.
result: [pending]

### 3. Provider switch (LLM_PROVIDER=gemini or alternate provider)

expected: Set `LLM_PROVIDER=gemini` (or any non-openai supported provider available to you) in `.env`, `docker compose restart langchain-service`, send the same academic question via POST /chat — receive a valid Portuguese response without code changes. If no alternate provider API key is available, this item can be marked SKIPPED — unit test `test_create_llm_builds_gemini_client` already verifies the code path.
result: [pending]

## Summary

total: 3
passed: 0
issues: 0
pending: 3
skipped: 0
blocked: 0

## Gaps
