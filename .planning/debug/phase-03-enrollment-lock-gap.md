---
status: resolved
trigger: "Diagnose the Phase 03 UAT gap below. Find root cause only; do not fix code.

Gap truth:
The PostgreSQL-backed enrollment lock flow persists `status='locked'` successfully in the running stack.

Observed failure:
`docker compose exec -T fastapi-app sh -lc \"cd /app && python -m scripts.verify_enrollment_lock_gap\"` failed with `CheckViolationError` because the running database still rejects `locked` for `enrollments.status`.

Context:
- This was discovered during Phase 03 verification on the live Docker stack.
- `alembic current` inside `fastapi-app` returned `008a (head)`.
- `SELECT version_num FROM alembic_version;` in Postgres returned `008a`.
- `backend/alembic/versions/009_add_locked_status_to_enrollments.py` exists in the repo and upgrades the constraint to include `locked`."
created: 2026-04-25T00:00:00Z
updated: 2026-05-02T00:00:00Z
---

## Current Focus

hypothesis: Confirmed runtime drift: the live fastapi-app container was built before migration 009a existed, and because compose does not bind-mount `backend/alembic`, the container still sees 008a as its head.
test: Finalize the diagnosis from container filesystem + compose mount rules + database revision state.
expecting: These three observations should explain why the DB still enforces the old check constraint even though the repo contains 009a.
next_action: Session complete — root cause confirmed and fix already applied.

## Symptoms

expected: The PostgreSQL-backed enrollment lock flow should persist `status='locked'` successfully when running the dedicated runtime verifier.
actual: `python -m scripts.verify_enrollment_lock_gap` fails with `CheckViolationError` because the running database still rejects `locked` for `enrollments.status`.
errors: `CheckViolationError`, `ck_enrollments_status` rejects `locked`, `alembic current` shows `008a (head)`
reproduction: Run `docker compose exec -T fastapi-app sh -lc "cd /app && python -m scripts.verify_enrollment_lock_gap"` on the live Docker stack.
started: Discovered during Phase 03 verification on the live Docker stack.

## Eliminated

## Evidence

- timestamp: 2026-04-25T00:04:00Z
  checked: .planning/debug/knowledge-base.md
  found: File does not exist.
  implication: No prior resolved debug pattern is available to seed hypotheses.

- timestamp: 2026-04-25T00:04:30Z
  checked: common-bug-patterns reference at repo-root src/backend/.opencode/... path
  found: Referenced file path does not exist at that location.
  implication: Need to locate the actual reference file before using the pattern catalog.

- timestamp: 2026-04-25T00:07:30Z
  checked: .opencode/get-shit-done/references/common-bug-patterns.md
  found: The symptom maps to the Environment / Config category (works in repo, fails on live Docker runtime).
  implication: Deployment/runtime drift is a primary hypothesis candidate ahead of application-logic bugs.

- timestamp: 2026-04-25T00:09:30Z
  checked: live fastapi-app container `/app/alembic/versions`, `alembic heads`, and `alembic current`
  found: The live container contains migrations only through `008_add_notes_to_documents.py`; Alembic reports `008a (head)` and `008a (head)`.
  implication: The running container does not have revision 009a available, so the database cannot be upgraded to the constraint change from that container.

- timestamp: 2026-04-25T00:10:30Z
  checked: live Postgres `alembic_version`
  found: `SELECT version_num FROM alembic_version;` returns `008a`.
  implication: The database schema is still on the pre-lock migration level, matching the old constraint behavior.

- timestamp: 2026-04-25T00:11:00Z
  checked: repo migration tree plus backend Docker wiring
  found: The repo contains `backend/alembic/versions/009_add_locked_status_to_enrollments.py`, and `backend/Dockerfile` copies `alembic/` into the image at build time, while `docker-compose.yml` bind-mounts only `./backend/src` and `./backend/scripts` into `fastapi-app`.
  implication: New Alembic revisions added on the host do not appear in an already-running container unless the image/container is rebuilt or `alembic/` is mounted too.

## Resolution

root_cause: 
The failure is caused by runtime/image drift, not enrollment logic: the live `fastapi-app` container was started from an image whose baked-in `/app/alembic` tree ends at revision `008a`. Because `docker-compose.yml` only bind-mounts `backend/src` and `backend/scripts` (not `backend/alembic`), the new repo migration `009a` never reached the running container, so Alembic still saw `008a` as head and the database retained the old `ck_enrollments_status` constraint that rejects `locked`.
fix: Two commits applied — (1) `e591719` added Alembic migration 009a to update `ck_enrollments_status` constraint to include `locked`; (2) `de64fbe` bind-mounted `backend/alembic` and `backend/alembic.ini` into the `fastapi-app` Docker container so host-side migrations are visible at runtime without rebuilding the image.
verification: Rebuild container or restart with updated compose mounts, then run `alembic upgrade head` inside the container. Verify `alembic current` shows `009a (head)` and `python -m scripts.verify_enrollment_lock_gap` passes without `CheckViolationError`.
files_changed: [docker-compose.yml, backend/Dockerfile, backend/alembic/versions/009_add_locked_status_to_enrollments.py]
