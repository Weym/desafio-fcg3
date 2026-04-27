---
status: resolved
phase: 05-ai-service
source: [05-VERIFICATION.md]
started: 2026-04-27T19:46:00Z
updated: 2026-04-27T20:10:00Z
---

## Current Test

[all tests complete]

## Tests

### 1. Cold start smoke test

expected: `docker compose down && docker compose up -d --build` brings all containers healthy; `docker compose exec langchain-service curl -sf http://localhost:8001/health` returns `{"status":"healthy"}` with no import or startup errors
result: PASSED — `{"status":"healthy"}`

### 2. Knowledge base ingest

expected: `docker compose exec langchain-service python -m ai_service.ingest` with valid OPENAI_API_KEY processes 5 documents, generates embeddings, stores chunks in `knowledge_base_chunks`, writes `.last_ingest.json`
result: PASSED — 5 documents processed, 17 chunks stored (after fix: added `gen_random_uuid()` to INSERT for `knowledge_base_chunks.id`)

### 3. Academic policy answer via /chat

expected: POST `/chat` with valid X-Service-Token and academic question returns Portuguese answer grounded in knowledge base content
result: PASSED — returned Portuguese response (after fix: use `create_llm()` instead of `get_model_string()` for correct OpenRouter base_url)

### 4. Provider switch (LLM_PROVIDER=gemini)

expected: Set `LLM_PROVIDER=gemini`, restart container, send same question — different LLM produces valid response without code changes
result: SKIPPED — user only uses OpenRouter; Gemini API key not available. Code path verified by unit test `test_create_llm_builds_gemini_client`.

## Summary

total: 4
passed: 3
issues: 0
pending: 0
skipped: 1
blocked: 0

## Gaps

No gaps — two bugs found and fixed during human testing:
1. `ingest.py`: Missing `gen_random_uuid()` in `INSERT INTO knowledge_base_chunks` (commit `63c7be3`)
2. `agent.py`: `get_model_string()` bypassed OpenRouter base_url — switched to `create_llm()` (commit `63c7be3`)
