---
phase: 1
slug: infrastructure-schema
status: verified
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-23
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `pytest` smoke/integration tests using Docker Compose, Alembic CLI, psql assertions, and Python import checks |
| **Config file** | None committed — run explicit Phase 1 test file paths |
| **Quick run command** | `pytest backend/tests/phase_01/test_phase_01_stack.py -v` |
| **Full suite command** | `pytest backend/tests/phase_01/test_phase_01_stack.py -v && pytest backend/tests/phase_01/test_phase_01_schema_seed.py -v` |
| **Estimated runtime** | Stack smoke ~2s · schema/seed verification ~10s |

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
| 1-01-01 | 01 | 1 | INFRA-01 | T-01-06 | Dockerfiles include curl support, service images exist, and the AI stub keeps Phase 1 dependencies minimal | smoke | `pytest backend/tests/phase_01/test_phase_01_stack.py -v` | ✅ | ✅ green |
| 1-01-02 | 01 | 1 | INFRA-01 | T-01-05 | `docker compose config` resolves a valid 4-service topology with healthchecks and both bridge networks | smoke | `pytest backend/tests/phase_01/test_phase_01_stack.py -v` | ✅ | ✅ green |
| 1-01-03 | 01 | 1 | INFRA-01,INFRA-03 | T-01-01 / T-01-02 | All 4 containers healthy, healthcheck endpoints return 200, `.env.example` stays placeholder-only, `.env` remains gitignored, backend bootstrap stays import-safe | integration | `pytest backend/tests/phase_01/test_phase_01_stack.py -v` | ✅ | ✅ green |
| 1-02-01 | 02 | 1 | INFRA-02 | T-02-02 | Metadata registry loads the current 21 application tables and matches the live database table count | integration | `pytest backend/tests/phase_01/test_phase_01_schema_seed.py -v` | ✅ | ✅ green |
| 1-02-02 | 02 | 1 | INFRA-02 | T-02-04 | Live schema exposes the expected Phase 1 application tables, including knowledge base and MCP log artifacts | integration | `pytest backend/tests/phase_01/test_phase_01_schema_seed.py -v` | ✅ | ✅ green |
| 1-02-03 | 02 | 1 | INFRA-02 | T-02-01 / T-02-04 | Alembic state is at head and `alembic check` reports no pending upgrade operations | integration | `pytest backend/tests/phase_01/test_phase_01_schema_seed.py -v` | ✅ | ✅ green |
| 1-03-01 | 03 | 2 | INFRA-03 | T-03-01 / T-03-02 | `.env.example` documents required vars with placeholder secrets only, and `.gitignore` protects `.env` | integration | `pytest backend/tests/phase_01/test_phase_01_stack.py -v` | ✅ | ✅ green |
| 1-03-02 | 03 | 2 | INFRA-03 | T-03-03 / T-03-05 | Settings stay lazy until first use and validate successfully when required env vars are supplied | integration | `pytest backend/tests/phase_01/test_phase_01_stack.py -v` | ✅ | ✅ green |
| 1-03-03 | 03 | 2 | INFRA-03 | T-03-04 | `src.main` imports without env configuration and still exposes `/health` | integration | `pytest backend/tests/phase_01/test_phase_01_stack.py -v` | ✅ | ✅ green |
| 1-04-01 | 04 | 2 | INFRA-04 | T-04-01 / T-04-03 | Seed command rebuilds the Phase 1 dataset with expected curriculum, student, staff, and scheduling counts | integration | `pytest backend/tests/phase_01/test_phase_01_schema_seed.py -v` | ✅ | ✅ green |
| 1-04-02 | 04 | 2 | INFRA-04 | T-04-02 | Running the seed twice yields identical counts and preserves prerequisite, status, and scheduling fixtures | integration | `pytest backend/tests/phase_01/test_phase_01_schema_seed.py -v` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Phase 1 now has committed pytest-based validation under `backend/tests/phase_01/`.

- No dedicated pytest config is required yet; commands use explicit file paths.
- Test helpers live in `backend/tests/phase_01/conftest.py`.
- Coverage stays phase-scoped: stack/config smoke checks and schema/seed integration checks.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Hot-reload reflects code changes without rebuild | INFRA-01 (D-05) | Requires editing a file and observing uvicorn reload in container logs | 1. Run `docker compose up -d` 2. Edit `backend/src/main.py` (e.g., change health response) 3. Watch `docker compose logs -f fastapi-app` for "Reloading..." 4. `curl localhost:8000/health` shows updated response |
| PostgreSQL data survives container restart | INFRA-02 | Requires Docker restart cycle | 1. Run seed 2. `docker compose down` 3. `docker compose up -d` 4. Verify `SELECT count(*) FROM courses` still returns ~40 |
| USP ICMC curriculum fidelity | INFRA-04 (D-02) | Visual review of course names and prerequisite chains | 1. Run seed 2. `SELECT code, name, credits FROM courses ORDER BY code` 3. Verify SCC/SMA/SSC prefixes match ICMC program structure |

---

## Validation Audit 2026-04-24

| Metric | Count |
|--------|-------|
| Gaps found | 4 |
| Resolved | 4 |
| Escalated | 0 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or equivalent pytest/CLI command
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Phase-scoped pytest scaffold now exists at `backend/tests/phase_01/`
- [x] No watch-mode flags
- [x] Feedback latency < 60s (Docker-dependent)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** verified 2026-04-24
