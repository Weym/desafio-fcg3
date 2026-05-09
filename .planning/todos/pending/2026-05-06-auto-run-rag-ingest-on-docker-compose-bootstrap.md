---
created: 2026-05-06T05:53:35Z
title: Auto-run RAG ingest on docker-compose bootstrap
area: tooling
files:
  - ai_service/ingest.py
  - docker-compose.yml
  - ai_service/Dockerfile
  - ai_service/main.py
source: .planning/debug/resolved/rag-whatsapp-default-error.md
---

## Problem

`knowledge_base_chunks` silently ends up empty whenever the `postgres` volume is recreated (e.g. `docker compose down -v`, fresh clone, new dev machine). When that happens the WhatsApp chatbot falls back to a generic error message for any RAG question because `search_knowledge_base` returns an empty string — see the resolved debug session at `.planning/debug/resolved/rag-whatsapp-default-error.md` for the full investigation.

Today, the ingest script (`python -m ai_service.ingest`) must be run manually and is easy to forget:

- It only runs once, by hand, and there is no startup-time check
- Production/staging operators or new contributors have no signal that the seed step is required
- Nothing in `docker-compose.yml` or the `langchain-service` container's entrypoint wires it into the boot sequence
- There is no health check that confirms `knowledge_base_chunks` has rows

## Solution

TBD — to decide between a few reasonable approaches:

1. **Startup hook in `ai_service/main.py` `lifespan`:** on boot, `SELECT count(*) FROM knowledge_base_chunks`; if 0, call `ai_service.ingest.main(...)` before `yield`. Pros: zero-config, idempotent (ingest already uses upsert via `DELETE ... WHERE source = %s`). Cons: adds embedding API calls to cold start; blocks startup until embeddings succeed.

2. **Dedicated one-shot ingest container/service in `docker-compose.yml`:** service `langchain-ingest` that runs `python -m ai_service.ingest` after `postgres` is healthy and then exits. `langchain-service` depends on it via `depends_on: condition: service_completed_successfully`. Pros: clean separation, easy to re-run. Cons: one more service to maintain.

3. **Makefile / justfile target + documented bootstrap step:** cheapest, still manual — not the goal here.

4. **Idempotent check in `ai_service.ingest` + `docker compose run --rm langchain-service python -m ai_service.ingest` baked into a `bin/bootstrap.sh`:** middle ground.

Recommended direction: option (1) guarded by an env flag (e.g. `RAG_AUTO_INGEST_ON_EMPTY=true`) so production can opt out, with a clear log line when it triggers. The ingest is already idempotent per source file.

Additionally: add a `/health` check (or extend the existing one) that reports `knowledge_base_chunks.count` so monitoring catches an empty table before users do.

## Acceptance Criteria

- [ ] Fresh `docker compose down -v && docker compose up` results in a non-empty `knowledge_base_chunks` without manual steps
- [ ] RAG questions via WhatsApp webhook answer correctly on first boot
- [ ] Re-running does not duplicate chunks (idempotency preserved)
- [ ] Some form of observability reports whether the table is populated
