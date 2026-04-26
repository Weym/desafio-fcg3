---
status: partial
phase: 05-ai-service
source: [05-01-SUMMARY.md, 05-02-SUMMARY.md, 05-03-SUMMARY.md, 05-04-SUMMARY.md, 05-05-SUMMARY.md, 05-06-SUMMARY.md, 05-07-SUMMARY.md, 05-REVIEW-FIX.md]
started: 2026-04-26T03:24:00.286Z
updated: 2026-04-26T03:35:07.507Z
---

## Current Test

[testing paused — 3 items outstanding]

## Tests

### 1. Cold Start Smoke Test
expected: Stop any running Phase 05 services, then start the AI stack from scratch. The packaged AI service should boot cleanly without import or DATABASE_URL compatibility errors, and `http://localhost:8001/health` should return a healthy response once startup finishes.
result: issue
reported: "The stack rebuilt and the AI container became healthy, but `http://localhost:8001/health` on the host failed with connection refused because the current compose config does not publish port 8001."
severity: blocker

### 2. Knowledge Base Ingest
expected: Running the ingest flow with the Phase 05 environment configured should complete without crashing, refresh the academic source documents, and write or update `ai_service/knowledge/.last_ingest.json` with a chunking summary.
result: issue
reported: "Running `python -m ai_service.ingest` inside `langchain-service` failed with `401 Unauthorized` from the OpenAI embeddings API because the configured API key is invalid, and `ai_service/knowledge/.last_ingest.json` was not created."
severity: blocker

### 3. Academic Policy Answer
expected: Sending an authorized `/chat` request with a question about matricula, calendario, curriculo, or FAQ content should return a student-facing Portuguese answer grounded in the academic knowledge base instead of a placeholder or empty response.
result: issue
reported: "An authorized `/chat` request returned only the generic fallback response instead of an academic answer. AI-service logs show `psycopg.errors.NotNullViolation` because inserts into `chat_messages` fail with `null value in column \"id\"` when persisting both the user and fallback assistant turns."
severity: blocker

### 4. Conversation Continuity
expected: Sending a follow-up `/chat` request with the same `session_id` should preserve context from the earlier exchange, so the second answer clearly reflects the prior question without needing the full context repeated.
result: [pending]

### 5. Ordered Chat Persistence
expected: After a `/chat` exchange, the same session should behave as if the user turn was saved before the assistant turn, so follow-up requests continue from the right order instead of losing or scrambling the conversation.
result: [pending]

### 6. Protected Chat Boundary
expected: Calling `/chat` without the internal service token should be rejected, while the same request with the valid internal token should be accepted. The default compose stack should not rely on host-published AI or MCP ports to make chat work.
result: [pending]

## Summary

total: 6
passed: 0
issues: 3
pending: 3
skipped: 0
blocked: 0

## Gaps

- truth: "Stop any running Phase 05 services, then start the AI stack from scratch. The packaged AI service should boot cleanly without import or DATABASE_URL compatibility errors, and `http://localhost:8001/health` should return a healthy response once startup finishes."
  status: failed
  reason: "User reported: The stack rebuilt and the AI container became healthy, but `http://localhost:8001/health` on the host failed with connection refused because the current compose config does not publish port 8001."
  severity: blocker
  test: 1
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""
- truth: "Running the ingest flow with the Phase 05 environment configured should complete without crashing, refresh the academic source documents, and write or update `ai_service/knowledge/.last_ingest.json` with a chunking summary."
  status: failed
  reason: "User reported: Running `python -m ai_service.ingest` inside `langchain-service` failed with `401 Unauthorized` from the OpenAI embeddings API because the configured API key is invalid, and `ai_service/knowledge/.last_ingest.json` was not created."
  severity: blocker
  test: 2
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""
- truth: "Sending an authorized `/chat` request with a question about matricula, calendario, curriculo, or FAQ content should return a student-facing Portuguese answer grounded in the academic knowledge base instead of a placeholder or empty response."
  status: failed
  reason: "User reported: An authorized `/chat` request returned only the generic fallback response instead of an academic answer. AI-service logs show `psycopg.errors.NotNullViolation` because inserts into `chat_messages` fail with `null value in column \"id\"` when persisting both the user and fallback assistant turns."
  severity: blocker
  test: 3
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""
