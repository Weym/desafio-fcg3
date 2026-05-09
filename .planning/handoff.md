# Next Session Handoff

## Resume Point

- Primary resume file: `.planning/phases/05-ai-service/05-UAT.md`
- State file: `.planning/STATE.md`
- Verification context: `.planning/phases/05-ai-service/05-VERIFICATION.md`

## Current Status

- Project state: `blocked`
- Current phase: `05-ai-service` reopened
- Phase 06 status: blocked by Phase 05 UAT/runtime gaps
- Phase 05 UAT status: `partial`
- Outstanding UAT items: 3 blockers, 3 pending tests

## Confirmed Blockers

1. Host health contract mismatch
   - `langchain-service` is healthy inside Docker, but `http://localhost:8001/health` fails on the host because port `8001` is no longer published in `docker-compose.yml`.
   - Decision needed: keep secured private topology and update the UAT contract, or reintroduce a dev-only host exposure path.

2. Ingest blocked by invalid embeddings credential
   - `docker compose exec langchain-service python -m ai_service.ingest` failed with `401 Unauthorized` from OpenAI embeddings.
   - `ai_service/knowledge/.last_ingest.json` was not created.
   - This is currently an environment/runtime blocker, not yet a confirmed code defect.

3. `/chat` persistence fails before useful answer generation
   - Authorized `/chat` requests return the generic fallback response.
   - Live logs show `psycopg.errors.NotNullViolation` on `chat_messages.id`.
   - Current insert path assumes the database can generate `id`, but the live schema rejects `NULL` for that column.

## Pending UAT Tests

1. Conversation Continuity
2. Ordered Chat Persistence
3. Protected Chat Boundary

These should only be resumed after blocker 3 is closed and blocker 1 is either fixed or the UAT contract is updated.

## What Is Still Considered Good

- AI container boots successfully in Docker.
- Internal container health check passes.
- Package/runtime alignment from Phase `05-07` remains in place.
- Phase 05 automated validation was previously green; the current failure is in resumed live UAT/runtime verification.

## Recommended Next Session Order

1. Resolve blocker 3 first.
   - Inspect the live `chat_messages` schema and compare it to `ai_service/database.py` insert behavior.
   - Make the smallest fix so inserts always satisfy the live `id` requirement.
   - Re-run an authorized academic-policy `/chat` request.

2. Resolve blocker 1 second.
   - Decide whether the intended contract is host-reachable AI in development or private-only topology.
   - Update either `docker-compose.yml` or the Phase 05 UAT/verification contract to match the intended behavior.

3. Resolve blocker 2 third.
   - Provide a valid embeddings credential in the runtime environment.
   - Re-run ingest and confirm `ai_service/knowledge/.last_ingest.json` is written.

4. Resume the remaining UAT tests and restore Phase 05 to `complete` before restarting Phase 06.

## Key Evidence Files

- `.planning/STATE.md`
- `.planning/phases/05-ai-service/05-UAT.md`
- `.planning/phases/05-ai-service/05-VERIFICATION.md`
- `.planning/phases/05-ai-service/05-07-SUMMARY.md`
- `.planning/phases/05-ai-service/05-REVIEW-FIX.md`

## Notes

- Do not trust the earlier "Phase 05 complete" verdict; it was superseded by resumed UAT on `2026-04-26`.
- No commit should be created as part of this handoff update.
