---
phase: 05-ai-service
plan: 07
subsystem: ai
tags: [fastapi, docker, compose, langchain, postgres, testing]
requires:
  - phase: 05-ai-service
    plan: 01
    provides: AI service package scaffold and FastAPI app entrypoint
  - phase: 05-ai-service
    plan: 05
    provides: Chat endpoint and runtime container wiring
  - phase: 05-ai-service
    plan: 06
    provides: Correct /chat persistence and assistant-only response extraction
provides:
  - Package-safe AI runtime entrypoint shared by source, Dockerfile, and compose
  - Live Docker health recovery for langchain-service on port 8001
  - Regression coverage for runtime import-path and shared DSN compatibility
affects: [phase-06, ai_service/main.py, docker-compose.yml, ai_service/Dockerfile]
tech-stack:
  added: []
  patterns:
    - Package entrypoint execution via `python -m ai_service.main`
    - psycopg DSN normalization from shared SQLAlchemy-style DATABASE_URL values
key-files:
  created: [ai_service/tests/test_runtime_entrypoint.py]
  modified: [ai_service/main.py, ai_service/Dockerfile, docker-compose.yml, ai_service/database.py, ai_service/ingest.py]
key-decisions:
  - "Used `python -m ai_service.main` as the single runtime path for Docker and compose so bind-mounted development matches the packaged image."
  - "Normalized `postgresql+asyncpg://` and `postgresql+psycopg://` URLs before psycopg usage so the AI service can share the repo-wide DATABASE_URL contract without custom env forks."
patterns-established:
  - "AI runtime manifests should launch the package module, not flat `main:app` imports."
  - "psycopg consumers in the AI service must normalize SQLAlchemy-style PostgreSQL URLs before opening sync connections."
requirements-completed: [AI-01, AI-02, AI-03, AI-04, AI-05]
duration: 25 min
completed: 2026-04-26
---

# Phase 05 Plan 07: Runtime Alignment Summary

**Packaged AI-service startup with Docker/compose parity, passing runtime regressions, and a healthy live `/health` endpoint in the rebuilt langchain-service container.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-04-26T00:35:00Z
- **Completed:** 2026-04-26T01:00:00Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added a focused runtime regression suite that locks package import, preserved routes, compose command, bind mount, and DSN normalization behavior.
- Switched the AI service image and compose service to the shared `python -m ai_service.main` entrypoint and package-safe `/app/ai_service` mount.
- Restored live container health by fixing the Docker build context copy path and normalizing shared PostgreSQL URLs for psycopg consumers.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add focused regressions for the AI runtime entrypoint gap** - `876e4ca` (test)
2. **Task 2: Repair the AI-service package startup path without changing chat behavior** - `9b8e8d8` (fix)

## Files Created/Modified

- `ai_service/tests/test_runtime_entrypoint.py` - regression coverage for import-safe routes, runtime manifests, and DSN normalization.
- `ai_service/main.py` - adds the package runner used by Docker and compose.
- `ai_service/Dockerfile` - aligns build-context copies and runtime startup to the packaged module entrypoint.
- `docker-compose.yml` - mounts the AI package at `/app/ai_service` and starts it with `python -m ai_service.main`.
- `ai_service/database.py` - normalizes shared DATABASE_URL values before psycopg pool creation.
- `ai_service/ingest.py` - reuses the normalized psycopg DSN contract for knowledge-base ingest.

## Decisions Made

- Reused a module-level `main()` wrapper in `ai_service/main.py` instead of changing the FastAPI app object, preserving the existing `/chat` and `/health` surface while fixing startup alignment.
- Extended the runtime repair to psycopg DSN normalization because the packaged container still could not become healthy with the repo's shared `postgresql+asyncpg://` setting.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Corrected the AI image build-context copy paths**
- **Found during:** Task 2 (Repair the AI-service package startup path without changing chat behavior)
- **Issue:** `docker compose up --build` failed because `ai_service/Dockerfile` used `COPY ai_service/...` while the build context was already `./ai_service`.
- **Fix:** Updated the Dockerfile to copy `requirements.txt` from the build root and copy the build context into `/app/ai_service`.
- **Files modified:** `ai_service/Dockerfile`
- **Verification:** `docker compose up -d --build postgres langchain-service`
- **Committed in:** `9b8e8d8`

**2. [Rule 3 - Blocking] Normalized shared PostgreSQL URLs for psycopg consumers**
- **Found during:** Task 2 (Repair the AI-service package startup path without changing chat behavior)
- **Issue:** The rebuilt service booted but `/health` returned 503 because psycopg could not open the shared `postgresql+asyncpg://...` DATABASE_URL.
- **Fix:** Added `normalize_psycopg_dsn(...)` for the AI service pool and ingest settings, plus regression coverage for the compatibility contract.
- **Files modified:** `ai_service/database.py`, `ai_service/ingest.py`, `ai_service/tests/test_runtime_entrypoint.py`
- **Verification:** `python -m pytest ai_service/tests/test_runtime_entrypoint.py -q`; `curl -sf http://localhost:8001/health`
- **Committed in:** `9b8e8d8`

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Both fixes were required to complete the planned runtime recovery. No scope creep beyond making the AI service boot and stay healthy in Docker.

## Issues Encountered

- An already staged legacy planning file was unintentionally included in the Task 1 commit because the working tree contained pre-existing staged changes from earlier Phase 05 work.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 05 runtime verification now passes again, and `langchain-service` serves `/health` successfully in Docker.
- Phase 06 can rely on the packaged AI container path and the normalized psycopg DATABASE_URL contract.

## Self-Check: PASSED

- Found summary file: `.planning/phases/05-ai-service/05-07-SUMMARY.md`
- Found commit: `876e4ca`
- Found commit: `9b8e8d8`
