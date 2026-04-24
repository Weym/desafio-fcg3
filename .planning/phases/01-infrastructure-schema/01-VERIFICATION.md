---
phase: 01-infrastructure-schema
verified: 2026-04-24T14:53:08Z
status: gaps_found
score: 7/9 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 9/9
  gaps_closed: []
  gaps_remaining:
    - "Running `alembic upgrade head` succeeds against the current Docker runtime database"
    - "Running `docker compose exec fastapi-app python -m scripts.seed` succeeds against the current Docker runtime database"
  regressions:
    - "Alembic can no longer connect from `fastapi-app` to PostgreSQL; `alembic upgrade head` now fails with password authentication error for user `fcg3`."
    - "The destructive seed script can no longer connect from `fastapi-app` to PostgreSQL; `python -m scripts.seed` now fails with `asyncpg.exceptions.InvalidPasswordError`."
gaps:
  - truth: "Running `alembic upgrade head` creates all application tables (21 in the current documented schema, including the pgvector extension as migration #001) and the HNSW index on `knowledge_base_chunks.embedding`."
    status: failed
    reason: "The schema artifacts and live tables exist, but Alembic cannot currently connect from `fastapi-app` to PostgreSQL. `docker compose exec fastapi-app alembic upgrade head` fails with `password authentication failed for user \"fcg3\"`."
    artifacts:
      - path: "backend/alembic/env.py"
        issue: "Wired to env-driven sync DSN, but runtime connection fails before migrations can run."
      - path: "backend/src/infrastructure/database.py"
        issue: "Current container DB credentials do not authenticate against PostgreSQL from application code."
    missing:
      - "Align the configured backend/Alembic database credentials with the live PostgreSQL role/database used by the persisted Docker volume."
      - "Re-run `docker compose exec fastapi-app alembic upgrade head` successfully from the current stack."
      - "Re-run `docker compose exec fastapi-app alembic check` or equivalent to prove the migration path is healthy again."
  - truth: "Running the seed script populates the `curriculum`, `curriculum_courses`, and `courses` tables with 8 semesters and ~40 disciplines including prerequisite relationships."
    status: failed
    reason: "The database still contains seeded data, but the seed path is not currently usable. `docker compose exec fastapi-app python -m scripts.seed` fails with `asyncpg.exceptions.InvalidPasswordError: password authentication failed for user \"fcg3\"`."
    artifacts:
      - path: "backend/scripts/seed.py"
        issue: "The script is substantive and wired to `async_session`, but runtime DB authentication fails before any reseed occurs."
      - path: "backend/src/infrastructure/database.py"
        issue: "Async runtime connection used by the seed script cannot authenticate to PostgreSQL."
    missing:
      - "Restore working async DB connectivity from `fastapi-app` to PostgreSQL."
      - "Re-run `docker compose exec fastapi-app python -m scripts.seed` successfully."
      - "Re-confirm seeded counts after the successful reseed (40 courses, 8 semesters, prerequisite chain present)."
---

# Phase 1: Infrastructure & Schema Verification Report

**Phase Goal:** The four-service Docker stack starts cleanly and every application table exists in the database, seeded with curriculum data ready for testing.
**Verified:** 2026-04-24T14:53:08Z
**Status:** gaps_found
**Re-verification:** Yes — existing verification report re-checked against current runtime

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Running `docker compose up` brings all four containers (postgres, fastapi-app, langchain-service, mcp-server) to a healthy state with passing healthchecks. | ✓ VERIFIED | `docker compose ps` shows `fcg3-postgres`, `fcg3-api`, `fcg3-ai`, and `fcg3-mcp` all `Up ... (healthy)`. |
| 2 | Compose defines bind-mounted hot reload for all Python services. | ✓ VERIFIED | `docker-compose.yml` bind-mounts `./backend/src:/app/src`, `./backend/scripts:/app/scripts`, `./ai_service:/app`, and `./mcp_server:/app`; all Python services run `uvicorn ... --reload`. |
| 3 | Dockerfiles and service entrypoints exist for backend, AI, and MCP with working `/health` endpoints. | ✓ VERIFIED | `backend/Dockerfile`, `ai_service/main.py`, and `mcp_server/main.py` are substantive; `curl` to `:8000/:8001/:8002 /health` all returned HTTP 200 JSON. |
| 4 | Running `alembic upgrade head` creates all application tables (21 in the current documented schema, including the pgvector extension as migration #001) and the HNSW index on `knowledge_base_chunks.embedding`. | ✗ FAILED | `docker compose exec fastapi-app alembic upgrade head` fails now with `sqlalchemy.exc.OperationalError` / `psycopg2.OperationalError: password authentication failed for user "fcg3"`. |
| 5 | Every application table currently exists in PostgreSQL. | ✓ VERIFIED | Direct `psql` query reports `21` public application tables excluding `alembic_version`; `alembic_version` contains `006a`; `pg_extension` contains `vector`; `pg_indexes` contains `idx_knowledge_base_embedding`. |
| 6 | All required environment variables are documented in `.env.example` so the project can be configured from scratch without reading source code. | ✓ VERIFIED | `.env.example` documents `DATABASE_URL`, `ALEMBIC_DATABASE_URL`, `DATABASE_URL_AI`, `DATABASE_URL_MCP`, `MCP_SERVICE_TOKEN`, WhatsApp vars, `RESEND_API_KEY`, `JWT_*`, `LLM_PROVIDER`, `LLM_MODEL`, `OPENAI_API_KEY`, `GEMINI_API_KEY`, `FASTAPI_URL`, and `FCM_CREDENTIALS_PATH`. |
| 7 | Pydantic settings are lazy and import-safe for the backend entrypoint. | ✓ VERIFIED | `backend/src/infrastructure/config.py` defines cached `get_settings()` with `@lru_cache`; `backend/src/main.py` imports `get_settings` from `src.infrastructure.config` without calling it. |
| 8 | Running the seed script populates the `curriculum`, `curriculum_courses`, and `courses` tables with 8 semesters and ~40 disciplines including prerequisite relationships. | ✗ FAILED | `docker compose exec fastapi-app python -m scripts.seed` now fails with `asyncpg.exceptions.InvalidPasswordError: password authentication failed for user "fcg3"`. |
| 9 | The current database still contains seeded testing fixtures beyond curriculum data. | ✓ VERIFIED | `psql` queries return `40` courses, `8` semesters, `5` students, `2` staff, `1` active enrollment period, `1` resource, `5` scheduling slots, `3` failed grades, `4` in-progress grades, and prerequisite `SCC0102` for `SCC0201`. |

**Score:** 7/9 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `docker-compose.yml` | 4-service compose stack with healthchecks, networks, and bind mounts | ✓ VERIFIED | Defines all four services, both bridge networks, healthchecks, and development mounts. |
| `backend/src/main.py` | Import-safe backend entrypoint with `/health` | ✓ VERIFIED | Uses `from src.infrastructure.config import get_settings` and exposes `/health`. |
| `backend/src/infrastructure/config.py` | Lazy typed settings module | ✓ VERIFIED | Contains `Settings(BaseSettings)`, DSN fields, validators, and cached `get_settings()`. |
| `backend/src/infrastructure/database.py` | Async DB runtime used by app and seed script | ⚠️ HOLLOW | File is substantive, but live async connection from `fastapi-app` fails with `InvalidPasswordError` before any DB work can run. |
| `backend/alembic/env.py` | Sync Alembic config bound to shared metadata | ⚠️ HOLLOW | File derives sync URL correctly in code, but current runtime connection fails with `password authentication failed for user "fcg3"`. |
| `backend/alembic/versions/*.py` | Ordered migration chain with pgvector + HNSW | ✓ VERIFIED | `001_create_pgvector.py` creates `vector`; `006_create_chat_knowledge_tables.py` creates `idx_knowledge_base_embedding`. |
| `backend/src/infrastructure/models.py` | Central model registry for ORM metadata | ✓ VERIFIED | Loads `21` tables into `Base.metadata`. |
| `backend/scripts/seed.py` | Destructive curriculum + fixture seed script | ⚠️ HOLLOW | Code is substantive and wired to `async_session`, but the current runtime cannot authenticate to PostgreSQL, so reseed fails. |
| `.env.example` | Bootstrap configuration reference | ✓ VERIFIED | Documents the required environment surface with placeholder values. |
| `ai_service/main.py` / `mcp_server/main.py` | Stub health services for Phase 1 | ✓ VERIFIED | Both endpoints respond successfully and containers are healthy. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `backend/src/main.py` | `backend/src/infrastructure/config.py` | `from src.infrastructure.config import get_settings` | ✓ WIRED | Import path matches the Docker `uvicorn src.main:app` entrypoint. |
| `docker-compose.yml` | `backend/src/main.py` | `uvicorn src.main:app` | ✓ WIRED | Backend container starts and serves `/health`. |
| `backend/alembic/env.py` | PostgreSQL | env-driven sync DSN | ✗ NOT_WIRED | `docker compose exec fastapi-app alembic upgrade head` fails with `password authentication failed for user "fcg3"`. |
| `backend/src/infrastructure/database.py` | PostgreSQL | asyncpg `DATABASE_URL` | ✗ NOT_WIRED | `docker compose exec fastapi-app python -c ... async_session ... SELECT 1` fails with `asyncpg.exceptions.InvalidPasswordError`. |
| `backend/scripts/seed.py` | `backend/src/infrastructure/database.py` | `async_session` + ORM imports | ✗ NOT_WIRED | Script imports are correct, but execution stops at first DB call because async authentication fails. |
| `006_create_chat_knowledge_tables.py` | PostgreSQL index catalog | HNSW index creation | ✓ WIRED | `pg_indexes` returns `idx_knowledge_base_embedding`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `backend/alembic/env.py` | `sqlalchemy.url` | `ALEMBIC_DATABASE_URL` / derived `DATABASE_URL` | No — current runtime cannot authenticate to PostgreSQL | ✗ DISCONNECTED |
| `backend/scripts/seed.py` | `COURSES_DATA`, `PREREQUISITE_DATA`, `STUDENTS_DATA` | `async_session` writes into PostgreSQL | No — current runtime fails before first write with `InvalidPasswordError` | ✗ DISCONNECTED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Stack health | `docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Health}}"` | All 4 services show `healthy` | ✓ PASS |
| Backend health endpoint | `curl -fsS http://localhost:8000/health` | `{"status":"ok"}` | ✓ PASS |
| AI health endpoint | `curl -fsS http://localhost:8001/health` | `{"status":"ok","service":"langchain-service","phase":"stub"}` | ✓ PASS |
| MCP health endpoint | `curl -fsS http://localhost:8002/health` | `{"status":"ok","service":"mcp-server","phase":"stub"}` | ✓ PASS |
| ORM metadata load | `docker compose exec fastapi-app python -c "from src.infrastructure.models import Base; print(len(Base.metadata.tables))"` | `21` | ✓ PASS |
| Live schema + seed snapshot | `docker compose exec postgres psql ...` | `21 tables / 40 courses / 8 semesters / 5 students / 2 staff / 1 active period / vector ext / HNSW index` | ✓ PASS |
| Alembic migration path | `docker compose exec fastapi-app alembic upgrade head` | Fails: `password authentication failed for user "fcg3"` | ✗ FAIL |
| Alembic drift check | `docker compose exec fastapi-app alembic check` | Fails with the same authentication error | ✗ FAIL |
| Backend async DB connectivity | `docker compose exec fastapi-app python -c "... async_session ... SELECT 1"` | Fails: `asyncpg.exceptions.InvalidPasswordError` | ✗ FAIL |
| Seed execution | `docker compose exec fastapi-app python -m scripts.seed` | Fails: `asyncpg.exceptions.InvalidPasswordError` | ✗ FAIL |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| `INFRA-01` | `01-01-PLAN.md`, `01-05-PLAN.md`, `01-06-PLAN.md` | Sistema pode ser iniciado com `docker compose up` — 4 containers sobem com healthchecks | ✓ SATISFIED | Current `docker compose ps` shows all four services healthy and all three HTTP `/health` endpoints return 200. |
| `INFRA-02` | `01-02-PLAN.md` | Schema completo do banco é criado via Alembic migrations com pgvector + HNSW | ✗ BLOCKED | Live tables, extension, and index exist, but `alembic upgrade head` and `alembic check` currently fail from `fastapi-app` with password authentication errors. |
| `INFRA-03` | `01-01-PLAN.md`, `01-03-PLAN.md` | `.env.example` documenta todas as variáveis de ambiente necessárias | ✓ SATISFIED | `.env.example` documents the full bootstrap variable surface with placeholder values. |
| `INFRA-04` | `01-04-PLAN.md` | Seed data do currículo está disponível e pode ser executado via script | ✗ BLOCKED | Seed data remains in PostgreSQL, but `docker compose exec fastapi-app python -m scripts.seed` currently fails with `InvalidPasswordError`, so the runnable seed requirement is not met. |

**Orphaned requirements:** None. All phase requirement IDs declared by the plans (`INFRA-01` through `INFRA-04`) are present in `.planning/REQUIREMENTS.md` and accounted for above.

### Anti-Patterns Found

No TODO/FIXME-style stub markers were found in the phase-critical code inspected here. The blocking issue is runtime configuration drift: the current backend/Alembic credentials no longer authenticate against the live PostgreSQL container.

### Human Verification Required After Gap Closure

1. **Hot-reload smoke check**

**Test:** With the stack running, edit `backend/src/main.py` and confirm `uvicorn --reload` picks up the change without rebuild.
**Expected:** FastAPI reloads automatically and the updated `/health` response is visible.
**Why human:** Requires observing live reload behavior across file edits and container logs.

2. **Volume persistence check**

**Test:** After a successful reseed, run `docker compose down`, then `docker compose up -d`, and re-check `SELECT count(*) FROM courses`.
**Expected:** Seeded data persists across restart.
**Why human:** Requires a restart-cycle workflow and operational judgment about expected persistence behavior.

### Gaps Summary

The stack health stub is still up, the schema and seed data are still present in PostgreSQL, and the Phase 1 documentation/config artifacts remain substantive. However, Phase 1 is **not currently goal-complete** because the live backend runtime has regressed on database authentication. From inside `fastapi-app`, both sync Alembic access and async application access now fail with password-authentication errors for user `fcg3`. That breaks two roadmap-contract behaviors: rerunning migrations from the application container and rerunning the destructive seed script from the application container.

This appears to be a current-environment/runtime wiring problem, not missing code structure: the migration files, model registry, and seed script all exist and are substantive, and direct `psql` queries inside the PostgreSQL container confirm the expected Phase 1 tables and seeded data remain present. But until the backend/Alembic DSNs authenticate successfully against the live PostgreSQL instance again, the phase is not ready for testing as promised.

---

_Verified: 2026-04-24T14:53:08Z_
_Verifier: the agent (gsd-verifier)_
