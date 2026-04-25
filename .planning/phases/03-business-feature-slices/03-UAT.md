---
status: diagnosed
phase: 03-business-feature-slices
source: [03-01-SUMMARY.md, 03-02-SUMMARY.md, 03-03-SUMMARY.md, 03-04-SUMMARY.md, 03-05-SUMMARY.md, 03-06-SUMMARY.md, 03-07-SUMMARY.md, 03-08-SUMMARY.md, 03-09-SUMMARY.md, 03-10-SUMMARY.md, 03-11-SUMMARY.md]
started: 2026-04-25T11:11:25.4601430-03:00
updated: 2026-04-25T11:11:25.4601430-03:00
---

## Current Test

[testing complete]

## Tests

### 1. Backend Feature Slice Smoke
expected: The Phase 3 backend should stay healthy on the running Docker stack and answer a primary API probe successfully.
result: pass
reported: "`curl -sf http://localhost:8000/health` returned `{\"status\":\"ok\"}` and all Phase 3 containers were healthy in `docker compose ps`."

### 2. Enrollment Lock Runtime Verification
expected: The PostgreSQL-backed enrollment lock flow should persist `status='locked'` successfully when running the dedicated runtime verifier.
result: issue
reported: "`docker compose exec -T fastapi-app sh -lc \"cd /app && python -m scripts.verify_enrollment_lock_gap\"` failed with `CheckViolationError` because `ck_enrollments_status` in the running database still rejects `locked`."
severity: blocker

### 3. Automated Phase 3 Regression Commands
expected: The backend container used for verification should be able to run the documented Phase 3 pytest regression commands.
result: issue
reported: "Both `docker compose exec -T fastapi-app sh -lc \"cd /app && pytest tests -q\"` and `python -m pytest tests -q` failed because `pytest` is not installed in the `fastapi-app` container image."
severity: major

## Summary

total: 3
passed: 1
issues: 2
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "The PostgreSQL-backed enrollment lock flow persists `status='locked'` successfully in the running stack."
  status: failed
  reason: "User reported: `python -m scripts.verify_enrollment_lock_gap` failed with `CheckViolationError` because the running database still enforces the pre-locked enrollment status constraint."
  severity: blocker
  test: 2
  root_cause: "The live Docker stack is using a stale `fastapi-app` image whose baked-in `/app/alembic` tree stops at `008a`. Because compose hot-mounts only `src/` and `scripts/`, the repo migration `009a` never reached the running container, so Alembic and Postgres both stay at `008a` and the old constraint still rejects `locked`."
  artifacts:
    - path: "backend/alembic/versions/009_add_locked_status_to_enrollments.py"
      issue: "Migration `009a` exists in the repo but is absent from the running container's Alembic tree."
    - path: "backend/Dockerfile"
      issue: "Alembic files are baked into the image at build time."
    - path: "docker-compose.yml"
      issue: "`fastapi-app` mounts `src/` and `scripts/` only, so `/app/alembic` stays stale until rebuild/recreate."
    - path: "backend/scripts/verify_enrollment_lock_gap.py"
      issue: "Runtime verifier exposes the stale-schema failure when persisting `status='locked'`."
  missing:
    - "Rebuild/recreate `fastapi-app` so the running container includes Alembic revision `009a`."
    - "Re-run Alembic upgrades against the live database until `alembic current` and `alembic_version` both report `009a`."
    - "Consider mounting or otherwise synchronizing Alembic revisions in the dev stack so migration files cannot drift from the running container."
  debug_session: ".planning/debug/phase-03-enrollment-lock-gap.md"
- truth: "The backend verification container can run the Phase 03 pytest regression commands documented by verification/UAT artifacts."
  status: failed
  reason: "User reported: `pytest` and `python -m pytest` fail in `fastapi-app` because the image does not include the pytest package."
  severity: major
  test: 3
  root_cause: "`fastapi-app` was built as a runtime-only image, but Phase 03 UAT expects it to act as a verification container. The Dockerfile installs only `requirements.txt`, while pytest tooling lives only in `requirements-dev.txt`, and the container/image setup also omits the `tests/` directory."
  artifacts:
    - path: "backend/Dockerfile"
      issue: "Installs only runtime dependencies and does not copy `tests/` into the image."
    - path: "backend/requirements.txt"
      issue: "Contains runtime dependencies only; no pytest package."
    - path: "backend/requirements-dev.txt"
      issue: "Holds pytest tooling that is never installed into `fastapi-app`."
    - path: "docker-compose.yml"
      issue: "`fastapi-app` mounts only `src/` and `scripts/`, so tests are not available in the running container."
  missing:
    - "Decide whether `fastapi-app` should support in-container verification or whether tests should run in a separate dedicated test environment."
    - "If in-container verification is required, install dev/test dependencies and make the `tests/` tree available to the verification container."
    - "Align UAT/verification docs with the actual supported execution environment for pytest commands."
  debug_session: ".planning/debug/phase-03-pytest-missing.md"
