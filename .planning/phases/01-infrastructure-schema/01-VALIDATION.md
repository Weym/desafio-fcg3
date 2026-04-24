---
phase: 1
slug: infrastructure-schema
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-23
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Docker Compose healthchecks + Alembic CLI + psql assertions + Python import checks |
| **Config file** | N/A — Phase 1 has no pytest tests; validation is via CLI commands |
| **Quick run command** | `docker compose ps --format "{{.Name}} {{.Status}}"` |
| **Full suite command** | `docker compose up --build -d && sleep 25 && docker compose exec fastapi-app bash -c "cd /app && alembic upgrade head" && docker compose exec fastapi-app python -m scripts.seed` |
| **Estimated runtime** | Docker build ~60s (first) / ~10s (cache) · healthchecks ~25s · migrations ~5s · seed ~3s |

---

## Sampling Rate

- **After every task commit:** Run the task-specific `<verify>` command from the plan
- **After every plan wave:** Run `docker compose ps` to confirm all containers healthy + task-specific verifications
- **Before `/gsd-verify-work`:** Full suite: Docker up + migrations + seed + all verification queries
- **Max feedback latency:** 60 seconds (includes Docker build on cache miss)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 01 | 1 | INFRA-01 | T-01-06 | Dockerfiles with curl installed, requirements.txt per service, .dockerignore excludes .env | file check | `test -f backend/Dockerfile && test -f ai_service/Dockerfile && test -f mcp_server/Dockerfile && grep -q "curl" backend/Dockerfile && grep -q "curl" ai_service/Dockerfile && ! grep -q "langchain" ai_service/requirements.txt` | ✅ | ⬜ pending |
| 1-01-02 | 01 | 1 | INFRA-01 | T-01-05 | docker-compose.yml defines 4 services with healthchecks, 2 networks, service_healthy depends_on | config | `docker compose config > /dev/null 2>&1` | ✅ | ⬜ pending |
| 1-01-03 | 01 | 1 | INFRA-01,INFRA-03 | T-01-01 / T-01-02 | All 4 containers healthy, healthcheck endpoints return 200, .env has dev defaults, .env.example documents all vars, .env in .gitignore | integration | `docker compose up --build -d && sleep 25 && curl -sf http://localhost:8000/health && curl -sf http://localhost:8001/health && curl -sf http://localhost:8002/health && grep -q "^\.env$" .gitignore` | ✅ | ⬜ pending |
| 1-02-01 | 02 | 1 | INFRA-02 | T-02-02 | database.py has AsyncEngine + Base; models.py aggregates all feature models; no hardcoded credentials | module check | `docker compose exec fastapi-app python -c "import sys; sys.path.insert(0,'src'); from infrastructure.models import Base; assert len(Base.metadata.tables) == 17; print('OK')"` | ✅ | ⬜ pending |
| 1-02-02 | 02 | 1 | INFRA-02 | T-02-04 | All 17 ORM models match docs/database.md (columns, types, constraints, indexes); pgvector Vector(1536) used | model check | `docker compose exec fastapi-app python -c "import sys; sys.path.insert(0,'src'); from infrastructure.models import Base; tables = sorted([t.name for t in Base.metadata.sorted_tables]); print(f'{len(tables)} tables: {tables}')"` | ✅ | ⬜ pending |
| 1-02-03 | 02 | 1 | INFRA-02 | T-02-01 / T-02-04 | Alembic migrations create all 17 tables, pgvector extension via #001, HNSW index on knowledge_base_chunks, downgrade+upgrade cycle works | migration | `docker compose exec fastapi-app bash -c "cd /app && alembic upgrade head" && docker compose exec postgres psql -U fcg3 -d fcg3 -t -c "SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';" && docker compose exec postgres psql -U fcg3 -d fcg3 -t -c "SELECT extname FROM pg_extension WHERE extname='vector';" && docker compose exec postgres psql -U fcg3 -d fcg3 -t -c "SELECT indexname FROM pg_indexes WHERE tablename='knowledge_base_chunks' AND indexname='idx_knowledge_base_embedding';"` | ✅ | ⬜ pending |
| 1-03-01 | 03 | 2 | INFRA-03 | T-03-01 / T-03-02 | .env.example has all vars organized by service, asyncpg vs psycopg distinguished, MCP_SERVICE_TOKEN documented, .gitignore has .env | file check | `grep -q "DATABASE_URL=postgresql+asyncpg://" .env.example && grep -q "MCP_SERVICE_TOKEN" .env.example && grep -q "JWT_SECRET" .env.example && grep -q "WHATSAPP_TOKEN" .env.example && grep -q "RESEND_API_KEY" .env.example && grep -q "^\.env$" .gitignore` | ✅ | ⬜ pending |
| 1-03-02 | 03 | 2 | INFRA-03 | T-03-03 / T-03-05 | Pydantic Settings with lazy @lru_cache singleton, min_length on secrets, no module-level instantiation | unit | `cd backend && python -c "import sys; sys.path.insert(0,'src'); from infrastructure.config import Settings, get_settings; import os; os.environ.update({'DATABASE_URL':'postgresql+asyncpg://u:p@h/d','JWT_SECRET':'x'*32,'MCP_SERVICE_TOKEN':'y'*32,'WHATSAPP_TOKEN':'z','WHATSAPP_PHONE_NUMBER_ID':'1','WHATSAPP_WEBHOOK_VERIFY_TOKEN':'a','RESEND_API_KEY':'re_t'}); s=get_settings(); assert s.jwt_algorithm=='HS256'; print('OK')"` | ✅ | ⬜ pending |
| 1-03-03 | 03 | 2 | INFRA-03 | T-03-04 | main.py imports get_settings but does NOT call it at load; app starts even with missing env vars | import check | `cd backend && python -c "import sys; sys.path.insert(0,'src'); from main import app; print('import ok')"` | ✅ | ⬜ pending |
| 1-04-01 | 04 | 2 | INFRA-04 | T-04-01 / T-04-03 | Seed script destructive (truncate + reinsert per D-04); populates ~40 courses, 8 semesters, prerequisite chains, 5 students, 2 staff, 1 enrollment period, scheduling data | integration | `docker compose exec fastapi-app python -m scripts.seed && docker compose exec postgres psql -U fcg3 -d fcg3 -t -c "SELECT count(*) FROM courses;" && docker compose exec postgres psql -U fcg3 -d fcg3 -t -c "SELECT count(*) FROM students;" && docker compose exec postgres psql -U fcg3 -d fcg3 -t -c "SELECT count(*) FROM staff;"` | ✅ | ⬜ pending |
| 1-04-02 | 04 | 2 | INFRA-04 | T-04-02 | Seed idempotency: second run produces identical row counts; data integrity checks (semesters 1-8, failed grades, in-progress grades, prereq chain, scheduling slots) | integration | `docker compose exec fastapi-app python -m scripts.seed && docker compose exec postgres psql -U fcg3 -d fcg3 -t -c "SELECT count(*) FROM courses;" && docker compose exec postgres psql -U fcg3 -d fcg3 -t -c "SELECT count(DISTINCT semester) FROM curriculum_courses;" && docker compose exec postgres psql -U fcg3 -d fcg3 -t -c "SELECT count(*) FROM grades WHERE status='failed';" && docker compose exec postgres psql -U fcg3 -d fcg3 -t -c "SELECT count(*) FROM scheduling_slots;"` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Phase 1 does not require a Wave 0 test scaffold because:
- No pytest-based tests exist yet (pytest infrastructure is created in Phase 2 Wave 0)
- All verifications are CLI-based: Docker commands, Alembic CLI, psql queries, Python import checks
- Every task's `<verify>` block is self-contained and executable without test scaffolding

Phase 2 Wave 0 will create `backend/pyproject.toml` (pytest config), `backend/tests/conftest.py`, and `backend/requirements-dev.txt`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Hot-reload reflects code changes without rebuild | INFRA-01 (D-05) | Requires editing a file and observing uvicorn reload in container logs | 1. Run `docker compose up -d` 2. Edit `backend/src/main.py` (e.g., change health response) 3. Watch `docker compose logs -f fastapi-app` for "Reloading..." 4. `curl localhost:8000/health` shows updated response |
| PostgreSQL data survives container restart | INFRA-02 | Requires Docker restart cycle | 1. Run seed 2. `docker compose down` 3. `docker compose up -d` 4. Verify `SELECT count(*) FROM courses` still returns ~40 |
| USP ICMC curriculum fidelity | INFRA-04 (D-02) | Visual review of course names and prerequisite chains | 1. Run seed 2. `SELECT code, name, credits FROM courses ORDER BY code` 3. Verify SCC/SMA/SSC prefixes match ICMC program structure |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or equivalent CLI command
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 not needed — all verifications are CLI-based (no pytest scaffold required for Phase 1)
- [x] No watch-mode flags
- [x] Feedback latency < 60s (Docker-dependent)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-23 (by planner; awaits execution confirmation)
