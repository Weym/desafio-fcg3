---
status: partial
phase: 05-ai-service
source: [05-VERIFICATION.md]
started: 2026-04-27T19:46:00Z
updated: 2026-04-27T19:46:00Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. Cold start smoke test

expected: `docker compose down && docker compose up -d --build` brings all containers healthy; `docker compose exec langchain-service curl -sf http://localhost:8001/health` returns `{"status":"healthy"}` with no import or startup errors
result: [pending]

### 2. Knowledge base ingest

expected: `docker compose exec langchain-service python -m ai_service.ingest` with valid OPENAI_API_KEY processes 5 documents, generates embeddings, stores chunks in `knowledge_base_chunks`, writes `.last_ingest.json`
result: [pending]

### 3. Academic policy answer via /chat

expected: POST `/chat` with valid X-Service-Token and academic question returns Portuguese answer grounded in knowledge base content
result: [pending]

### 4. Provider switch (LLM_PROVIDER=gemini)

expected: Set `LLM_PROVIDER=gemini`, restart container, send same question — different LLM produces valid response without code changes
result: [pending]

## Summary

total: 4
passed: 0
issues: 0
pending: 4
skipped: 0
blocked: 0

## Gaps
