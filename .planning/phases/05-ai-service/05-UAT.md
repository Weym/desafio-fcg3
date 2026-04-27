---
status: diagnosed
phase: 05-ai-service
source: [05-01-SUMMARY.md, 05-02-SUMMARY.md, 05-03-SUMMARY.md, 05-04-SUMMARY.md, 05-05-SUMMARY.md, 05-06-SUMMARY.md, 05-07-SUMMARY.md, 05-REVIEW-FIX.md]
started: 2026-04-27T16:00:00Z
updated: 2026-04-27T16:12:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Cold Start Smoke Test
expected: Kill any running Phase 05 containers (`docker compose down`), then rebuild and start the stack from scratch (`docker compose up -d --build`). The `langchain-service` container should become healthy within ~30s. Since port 8001 is intentionally not published to the host (CR-01 security fix), verify health via `docker compose exec langchain-service curl -sf http://localhost:8001/health` — it should return a healthy JSON response with no import or startup errors in the container logs.
result: issue
reported: "All containers started successfully, but `docker compose exec langchain-service curl -sf http://localhost:8001/health` returned empty output with a non-zero exit code — the health endpoint is not returning a successful response."
severity: blocker

### 2. Knowledge Base Ingest
expected: Run `docker compose exec langchain-service python -m ai_service.ingest` with a valid `OPENAI_API_KEY` configured in the environment. The script should complete without crashing, log chunk counts per source category (matricula, faq, calendario, curriculo, regulamento), and write `ai_service/knowledge/.last_ingest.json` inside the container with a summary of what was ingested.
result: issue
reported: "Running `python -m ai_service.ingest` inside langchain-service crashed with `psycopg.OperationalError: password authentication failed for user \"fcg3\"` — the DATABASE_URL credentials don't match the PostgreSQL instance."
severity: blocker

### 3. Academic Policy Answer
expected: Send an authorized POST to `/chat` (via internal network or `docker compose exec`) with a valid `X-Service-Token` and a Portuguese academic question like "Quais sao as regras de matricula?". The response should contain a student-facing Portuguese answer grounded in knowledge base content — not a generic fallback or empty response.
result: issue
reported: "POST /chat with valid X-Service-Token returned empty output and non-zero exit code — endpoint not responding. Likely cascading from the health check failure in Test 1."
severity: blocker

### 4. Conversation Continuity
expected: Send a follow-up `/chat` request using the same `session_id` from Test 3. The response should clearly reflect context from the earlier exchange (e.g., referencing the prior topic) without needing the full question repeated.
result: blocked
blocked_by: prior-phase
reason: "/chat endpoint not responding (Test 1/3 blocker)"

### 5. Ordered Chat Persistence
expected: After Tests 3-4, query `chat_messages` for the session. Both user and assistant turns should be present in chronological order — user turn stored before the assistant turn for each exchange, with no null `id` violations or missing rows.
result: blocked
blocked_by: prior-phase
reason: "/chat endpoint not responding (Test 1/3 blocker)"

### 6. Service Token Enforcement
expected: Call `/chat` without the `X-Service-Token` header — the request should be rejected (401 or 403). Call `/chat` with a valid `X-Service-Token` — validation should pass and the request should proceed to agent execution. The AI and MCP service ports should not be reachable from the host (no published ports in compose).
result: blocked
blocked_by: prior-phase
reason: "/chat endpoint not responding (Test 1/3 blocker)"

## Summary

total: 6
passed: 0
issues: 3
pending: 0
skipped: 0
blocked: 3

## Gaps

- truth: "The langchain-service health endpoint should return a successful JSON response when curled from inside the container after a cold start."
  status: failed
  reason: "User reported: All containers started successfully, but `docker compose exec langchain-service curl -sf http://localhost:8001/health` returned empty output with a non-zero exit code — the health endpoint is not returning a successful response."
  severity: blocker
  test: 1
  root_cause: "DATABASE_URL in .env has password 'backend' but POSTGRES_PASSWORD is 'change_me_in_production'. The reconcile_dev_credentials.sh script enforces POSTGRES_PASSWORD on every startup, so the pool in ai_service/database.py fails all connections and /health returns 503. curl -sf suppresses 503 body, showing empty output."
  artifacts:
    - path: ".env"
      issue: "DATABASE_URL password ('backend') does not match POSTGRES_PASSWORD ('change_me_in_production')"
    - path: "ai_service/database.py"
      issue: "Pool creation with mismatched credentials causes all health checks to return 503"
    - path: "ai_service/main.py"
      issue: "/health returns 503 when DB pool has no working connections"
  missing:
    - "Synchronize all DATABASE_URL passwords with POSTGRES_PASSWORD in .env"
    - "Consider constructing DATABASE_URL from component env vars in docker-compose.yml to prevent drift"
  debug_session: ""
- truth: "The ingest script should connect to PostgreSQL and complete without crashing."
  status: failed
  reason: "User reported: Running `python -m ai_service.ingest` inside langchain-service crashed with `psycopg.OperationalError: password authentication failed for user \"fcg3\"` — the DATABASE_URL credentials don't match the PostgreSQL instance."
  severity: blocker
  test: 2
  root_cause: "Same root cause as Test 1 — .env DATABASE_URL embeds password 'backend' but PostgreSQL only accepts 'change_me_in_production'. ai_service/ingest.py line 206 calls psycopg.connect(settings.database_url) with the wrong password. Additionally, all URL variants in .env (DATABASE_URL, ALEMBIC_DATABASE_URL, DATABASE_URL_AI, DATABASE_URL_MCP) have different passwords and none match POSTGRES_PASSWORD."
  artifacts:
    - path: ".env"
      issue: "Five different passwords across DATABASE_URL variants, none matching POSTGRES_PASSWORD"
    - path: "ai_service/ingest.py"
      issue: "Line 206 connects with credentials from DATABASE_URL which has wrong password"
  missing:
    - "Fix all DATABASE_URL passwords in .env to match POSTGRES_PASSWORD"
  debug_session: ""
- truth: "POST /chat with valid X-Service-Token should return a student-facing Portuguese answer grounded in knowledge base content."
  status: failed
  reason: "User reported: POST /chat with valid X-Service-Token returned empty output and non-zero exit code — endpoint not responding. Likely cascading from the health check failure in Test 1."
  severity: blocker
  test: 3
  root_cause: "Cascading from Test 1 — the AI service DB pool has no working connections due to the credential mismatch. /chat depends on DB connectivity for chat history persistence and agent execution, so it also fails."
  artifacts:
    - path: ".env"
      issue: "DATABASE_URL password mismatch (same root cause as Tests 1 and 2)"
    - path: "ai_service/main.py"
      issue: "/chat endpoint fails when DB pool is unhealthy"
  missing:
    - "Fix DATABASE_URL password in .env (same fix as Tests 1 and 2)"
  debug_session: ""
