---
status: complete
phase: 05-ai-service
source: [05-01-SUMMARY.md, 05-02-SUMMARY.md, 05-03-SUMMARY.md, 05-04-SUMMARY.md, 05-05-SUMMARY.md, 05-06-SUMMARY.md, 05-07-SUMMARY.md, 05-08-SUMMARY.md, 05-09-SUMMARY.md]
started: 2026-04-30T19:00:00Z
updated: 2026-04-30T19:15:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Cold Start Smoke Test
expected: Kill any running containers (`docker compose down -v`), then rebuild and start the stack from scratch (`docker compose up -d --build`). The `langchain-service` container should become healthy within ~30s. Verify via `docker compose exec langchain-service curl -sf http://localhost:8001/health` — it should return `{"status":"healthy"}` with no import or startup errors in the container logs.
result: pass
notes: Required fixing CRLF line endings in reconcile_dev_credentials.sh (Windows portability issue). After fix, all containers started and health returned {"status":"healthy"}.

### 2. Knowledge Base Ingest
expected: Run `docker compose exec langchain-service python -m ai_service.ingest` with a valid `OPENAI_API_KEY` configured. The script should complete without crashing, log chunk counts per source category (matricula, faq, calendario, curriculo, regulamento), and write `.last_ingest.json` inside the container with an ingest summary.
result: pass
notes: Requires Alembic migrations and seed to run first (expected for cold start). After prerequisites, ingest processed 5 documents into 17 chunks successfully.

### 3. Academic Policy Answer
expected: Send a POST to `/chat` from inside the Docker network with valid X-Service-Token and an academic question. The response should contain a Portuguese answer grounded in the knowledge base content about enrollment rules — not a generic fallback or empty response.
result: issue
reported: "RAG tool always returns empty because similarity scores (max 0.55-0.67) are always below the 0.75 threshold. Agent responds in Portuguese but says it didn't find information, despite content existing in the knowledge base with matching category. Even querying the exact document title 'Guia de Matricula e Rematricula' only yields similarity 0.6685."
severity: blocker

### 4. Conversation Continuity
expected: Send a follow-up `/chat` request using the same `session_id` from Test 3. The response should clearly reflect context from the earlier exchange without needing the full question repeated — demonstrating conversation memory retention.
result: pass
notes: Agent correctly referenced prior conversation ("você perguntou sobre as regras de matrícula") when asked "Voce lembra o que eu perguntei antes?". Memory loads last k messages from chat_messages table.

### 5. Ordered Chat Persistence
expected: After Tests 3-4, query the database for chat messages in the test session. Both user and assistant turns should be present in chronological order — user turn stored before assistant turn for each exchange, with no null violations or missing rows.
result: pass
notes: 6 messages (3 user + 3 assistant) stored in correct chronological order. IDs generated via gen_random_uuid(). No NULL violations.

### 6. Service Token Enforcement
expected: Call `/chat` without the `X-Service-Token` header — the request should be rejected (401 or 403). Then verify that the langchain-service port (8001) is NOT published to the host.
result: pass
notes: Without token returns 401 with "X-Service-Token header required". Ports 8001 and 8002 confirmed not published to host (docker compose port returns :0).

## Summary

total: 6
passed: 4
issues: 1
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "POST /chat with a Portuguese academic question returns a response grounded in knowledge base content about enrollment rules"
  status: failed
  reason: "User reported: RAG tool always returns empty because similarity scores (max 0.55-0.67) are always below the 0.75 threshold. Agent responds in Portuguese but says it didn't find information, despite content existing in the knowledge base with matching category. Even querying the exact document title 'Guia de Matricula e Rematricula' only yields similarity 0.6685."
  severity: blocker
  test: 3
  root_cause: "OpenRouter embedding proxy produces systematically lower cosine similarity scores than OpenAI direct. The 0.75 threshold (designed for OpenAI direct) is too aggressive for OpenRouter-proxied text-embedding-3-small. Scores range 0.49-0.67 for highly relevant content."
  artifacts:
    - path: "ai_service/rag.py"
      issue: "SIMILARITY_THRESHOLD = 0.75 is too high for OpenRouter embedding provider"
    - path: "ai_service/embedding_factory.py"
      issue: "OpenRouter base_url produces different similarity distributions than OpenAI direct"
  missing:
    - "Lower SIMILARITY_THRESHOLD to ~0.45 for OpenRouter, or make it configurable via env var"
    - "Alternatively, normalize embeddings before storage to improve cosine similarity range"
    - "Add SIMILARITY_THRESHOLD to Settings so it can be tuned per provider"
  debug_session: ""

## Additional Findings (Non-blocking)

### CRLF Line Endings (Windows Portability)
- `backend/docker/postgres/reconcile_dev_credentials.sh` has CRLF on Windows checkout
- Breaks container startup with "cannot execute: required file not found"
- Fix: Add `.gitattributes` with `*.sh text eol=lf`

### MCP Action Logs UUID
- `mcp_action_logs.id` gets NULL when MCP tools are called
- Error: "null value in column id of relation mcp_action_logs violates not-null constraint"
- The MCP server INSERT doesn't include `gen_random_uuid()` for the id column
- When agent invokes MCP tools (like `get_student_info`), the action logging fails
- This causes cascading agent failure and fallback response
