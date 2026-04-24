---
status: diagnosed
phase: 01-infrastructure-schema
source: [01-01-SUMMARY.md, 01-02-SUMMARY.md, 01-03-SUMMARY.md, 01-04-SUMMARY.md, 01-05-SUMMARY.md]
started: 2026-04-24T13:49:46.0302700Z
updated: 2026-04-24T14:57:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Cold Start Smoke Test
expected: Stop any running containers, then start the stack from scratch with `docker compose up --build -d`. Treat the detached compose output as an intermediate startup state only. Before recording any failure, spend up to 60 seconds re-running `docker compose ps` until the stack settles into healthy service states or clearly stops progressing, then call `curl http://localhost:8000/health`, and judge the cold-start result only from that post-start health evidence. The four services should boot without crashing, PostgreSQL should become healthy, and the backend health endpoint should respond with live JSON at `http://localhost:8000/health`.
result: issue
reported: "Historical UAT evidence stopped at the immediate detached `docker compose up --build -d` output (#32 [mcp-server] resolving provenance for metadata file #32 DONE 0.0s [+] up 7/7 ✔ Image desafio-fcg3-fastapi-app Built 3.3s ✔ Image desafio-fcg3-langchain-service Built 3.3s ✔ Image desafio-fcg3-mcp-server Built 3.3s ✔ Container fcg3-ai Created 0.2s ✔ Container fcg3-api Recreated 0.3s ✔ Container fcg3-mcp Created 0.2s ✔ Container fcg3-postgres Healthy 5.5s) without the required `docker compose ps` or backend `/health` follow-up evidence."
severity: major

### 2. Service Health Endpoints
expected: With the stack running, the three HTTP health endpoints should respond successfully: backend at `:8000`, AI service at `:8001`, and MCP server at `:8002`.
result: pass

### 3. Environment Bootstrap
expected: A developer should be able to copy `.env.example` to `.env`, fill real values, and import the backend app without an immediate configuration crash before first protected use.
result: pass

### 4. Database Schema Ready
expected: After running `alembic upgrade head`, the academic schema should exist in PostgreSQL with the Phase 1 application tables and no pending Alembic drift.
result: pass

### 5. Seeded Development Dataset
expected: Running `python -m scripts.seed` should rebuild the development dataset with curriculum, prerequisite chains, students, staff, enrollment periods, and scheduling fixtures, and running it again should keep the same counts.
result: pass

## Summary

total: 5
passed: 4
issues: 1
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "After a cold start, all four services become healthy and the backend health endpoint responds with live JSON once `docker compose ps` and `curl http://localhost:8000/health` confirm the post-start state."
  status: failed
  reason: "Historical UAT evidence ended at the immediate detached compose output and did not include the now-required `docker compose ps` re-check or `curl http://localhost:8000/health` verification."
  severity: major
  test: 1
  root_cause: "The cold-start check was judged from the immediate detached `docker compose up --build -d` output before the app service healthchecks finished; no follow-up `docker compose ps` or backend `/health` check was captured, so an intermediate startup state was mistaken for a failure."
  artifacts:
    - path: ".planning/phases/01-infrastructure-schema/01-UAT.md"
      issue: "Test 1 was marked failed from incomplete startup evidence rather than a completed cold-start verification sequence."
    - path: "README.md"
      issue: "The bootstrap instructions already require post-start verification with `docker compose ps` and health endpoint checks, but UAT Test 1 did not enforce them."
    - path: "docker-compose.yml"
      issue: "Service healthchecks use start periods and healthy transitions, so immediate `up -d` output is expected to show transient Created/Recreated states."
  missing:
    - "Require a post-start `docker compose ps` health re-check before judging the cold-start result."
    - "Require an explicit backend `/health` request as part of Cold Start Smoke Test acceptance criteria."
    - "Clarify in UAT/docs that immediate detached compose output is intermediate startup state, not final health status."
  debug_session: ".planning/debug/cold-start-smoke-test-uat-gap.md"
