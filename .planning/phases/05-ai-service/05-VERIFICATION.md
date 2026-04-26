---
phase: 05-ai-service
verified: 2026-04-26T03:35:07Z
status: gaps_found
score: 0/5 live outcomes verified
overrides_applied: 0
re_verification:
  previous_status: complete
  previous_score: 5/5 must-haves verified
  gaps_closed: []
  gaps_remaining:
    - "Host-level Phase 05 health verification no longer works because `langchain-service` is private in the default compose topology."
    - "`python -m ai_service.ingest` fails with `401 Unauthorized` from OpenAI embeddings and does not write `.last_ingest.json`."
    - "Authorized `/chat` requests return only the fallback response because `chat_messages` inserts fail with `null value in column \"id\"`."
  regressions:
    - "The prior `05-UAT.md` and `05-VERIFICATION.md` complete verdicts were superseded by resumed manual UAT on 2026-04-26."
gaps:
  - truth: "The packaged AI service cold-starts cleanly and is reachable through the expected verification contract."
    status: failed
    reason: "`fcg3-ai` becomes healthy after `docker compose up -d --build postgres langchain-service`, but `http://localhost:8001/health` on the host returns connection refused because the default compose file no longer publishes port 8001."
    artifacts:
      - path: "docker-compose.yml"
        issue: "`langchain-service` intentionally runs without a host port mapping, so the legacy host-level UAT contract no longer matches the secured runtime topology."
      - path: ".planning/phases/05-ai-service/05-UAT.md"
        issue: "The current manual UAT records this as a blocker for the verification contract."
    missing:
      - "Decide whether Phase 05 verification should target in-container/internal health only or reintroduce a development-only host exposure path."
      - "Update the UAT/verification contract so health checks align with the intended secured topology."
  - truth: "Running `python -m ai_service.ingest` completes successfully and writes `ai_service/knowledge/.last_ingest.json`."
    status: failed
    reason: "`docker compose exec langchain-service python -m ai_service.ingest` failed with `openai.AuthenticationError` / `401 Unauthorized` because the configured API key is invalid, and the audit artifact was not created."
    artifacts:
      - path: "ai_service/ingest.py"
        issue: "The ingest path depends on live OpenAI embeddings and cannot complete with the current invalid credential."
      - path: "ai_service/knowledge/.last_ingest.json"
        issue: "Expected audit output is missing after the failed run."
    missing:
      - "Provide a valid OpenAI embeddings key (or equivalent supported provider path) in the Phase 05 runtime environment."
      - "Re-run the ingest flow successfully and confirm `.last_ingest.json` is written."
  - truth: "Authorized `/chat` requests return grounded academic answers instead of the generic fallback response."
    status: failed
    reason: "An authorized `/chat` request returned only the generic fallback response. AI-service logs show `psycopg.errors.NotNullViolation` because inserts into `chat_messages` fail with `null value in column \"id\"` when persisting both the user and fallback assistant turns."
    artifacts:
      - path: "ai_service/main.py"
        issue: "The endpoint calls `save_chat_message(...)` before and after agent execution, so the request falls back immediately when persistence cannot insert a row."
      - path: "ai_service/database.py"
        issue: "`INSERT INTO chat_messages (chat_session_id, role, content)` assumes the table can generate `id`, but the live schema rejects rows with `id = NULL`."
    missing:
      - "Align the AI-service chat insert path with the live `chat_messages` schema so new rows satisfy the `id` requirement."
      - "Re-run an authorized `/chat` request and confirm a grounded Portuguese answer is returned for academic-policy questions."
---

# Phase 5: AI Service Verification Report

**Phase Goal:** The AI service can ingest academic knowledge, rebuild chat memory, call MCP tools through a provider-agnostic LangChain agent, and answer `/chat` requests with a student-facing Portuguese response.
**Verified:** 2026-04-26T03:35:07Z
**Status:** gaps_found
**Re-verification:** Yes - previous complete verdict was superseded by resumed UAT

## Verdict

Phase 05 is no longer goal-complete in the current runtime state. The AI container still boots and passes its internal healthcheck, but resumed UAT found three blockers that prevent advancing to Phase 06:

1. The secured compose topology no longer exposes `langchain-service` on host port `8001`, so the existing host-level health verification contract fails.
2. The knowledge-base ingest flow cannot complete because the configured OpenAI embeddings credential is invalid.
3. Authorized `/chat` requests return only the generic fallback response because chat persistence fails before agent execution can produce an academic answer.

## Live Verification Summary

| Check | Result | Evidence |
| --- | --- | --- |
| `docker compose up -d --build postgres langchain-service` | PASS | `fcg3-ai` rebuilt and started cleanly. |
| `docker compose exec langchain-service curl -sf http://localhost:8001/health` | PASS | Returned `{"status":"healthy"}` inside the container. |
| `http://localhost:8001/health` from the host | FAIL | Connection refused because `langchain-service` is not published to the host in `docker-compose.yml`. |
| `docker compose exec langchain-service python -m ai_service.ingest` | FAIL | OpenAI embeddings request returned `401 Unauthorized` / `invalid_api_key`; `.last_ingest.json` was not created. |
| Authorized `POST /chat` for an academic-policy question | FAIL | Returned only the fallback response; AI-service logs show `psycopg.errors.NotNullViolation` on `chat_messages.id`. |

## Requirement Status

| Requirement | Status | Evidence |
| --- | --- | --- |
| AI-01 | BLOCKED | The live `/chat` flow does not produce a usable academic answer; it falls back after a persistence error before the agent can complete. |
| AI-02 | BLOCKED | User-turn persistence fails on the first insert into `chat_messages`, so ordered history persistence is not operational in the current runtime. |
| AI-03 | UNVERIFIED | RAG retrieval could not be proven end-to-end because ingest failed and the live `/chat` path fell back before grounded output. |
| AI-04 | PARTIAL | Provider-agnostic wiring remains in code, but no live provider switch was re-verified in this session. |
| AI-05 | FAILED | Ingest currently fails with an invalid embeddings credential and produces no audit artifact. |

## Gap Status

- `05-UAT.md` is now `partial` with 3 issues recorded and 3 tests still outstanding.
- Root-cause diagnosis and gap-closure planning were not run in this session because the user explicitly stopped after recording the issue.
- Phase 06 should remain blocked until the three recorded Phase 05 runtime gaps are closed and Phase 05 UAT returns to `complete`.

## Final Outcome

The earlier Phase 05 complete verdict is superseded. As of 2026-04-26T03:35:07Z, Phase 05 is reopened with runtime/UAT blockers, and the correct resume point is `.planning/phases/05-ai-service/05-UAT.md`.
