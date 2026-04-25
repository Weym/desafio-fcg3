---
status: investigating
trigger: "Diagnose the Phase 03 UAT gap below. Find root cause only; do not fix code."
created: 2026-04-25T00:00:00Z
updated: 2026-04-25T00:00:00Z
---

## Current Focus

hypothesis: The verification commands are unsupported because fastapi-app is built as a runtime-only container: it installs only requirements.txt, excludes requirements-dev.txt, and does not copy or mount the tests directory.
test: Compare Dockerfile, requirements files, and docker-compose mounts against the documented pytest workflow.
expecting: Build/runtime config will show pytest and test files are absent from fastapi-app, so in-container regression commands cannot work.
next_action: Conclude root cause from container build/runtime mismatch with UAT expectations.

## Symptoms

expected: The backend verification container can run the documented Phase 03 pytest regression commands.
actual: Both `docker compose exec -T fastapi-app sh -lc "cd /app && pytest tests -q"` and `python -m pytest tests -q` fail because pytest is unavailable in the container image.
errors: `importlib.util.find_spec('pytest')` returned `None` inside `fastapi-app`.
reproduction: Run either pytest command inside the live `fastapi-app` container on the Phase 03 Docker stack.
started: Discovered during Phase 03 verification on the live Docker stack.

## Eliminated

## Evidence

- timestamp: 2026-04-25T00:00:00Z
  checked: .planning/phases/03-business-feature-slices/03-UAT.md
  found: UAT test 3 explicitly expects the backend verification container to run `pytest tests -q`, and records failure because pytest is missing in `fastapi-app`.
  implication: The gap is specifically about container image/runtime setup, not test behavior.

- timestamp: 2026-04-25T00:00:00Z
  checked: backend/Dockerfile
  found: The image copies only `requirements.txt` before `pip install -r requirements.txt`, then copies `alembic`, `src`, and `scripts`; it never installs `requirements-dev.txt` and never copies `tests/`.
  implication: The built image lacks pytest and also lacks the test suite contents needed for `pytest tests -q`.

- timestamp: 2026-04-25T00:00:00Z
  checked: backend/requirements.txt and backend/requirements-dev.txt
  found: `requirements.txt` contains runtime packages only, while `requirements-dev.txt` is where `pytest`, `pytest-asyncio`, `pytest-cov`, and `freezegun` are declared.
  implication: Installing only `requirements.txt` guarantees pytest is unavailable in the container.

- timestamp: 2026-04-25T00:00:00Z
  checked: docker-compose.yml
  found: `fastapi-app` builds from `./backend` and mounts only `./backend/src:/app/src` and `./backend/scripts:/app/scripts`; there is no mount for `requirements-dev.txt` or `tests/`.
  implication: Even on the live stack, compose does not add test dependencies or test files after build, so the verification commands are not supported by container configuration.

## Resolution

root_cause: The `fastapi-app` container is defined as a runtime-only image, but Phase 03 UAT expects it to double as a verification container. Its build installs only `backend/requirements.txt`, where pytest is absent, and the image/compose setup also excludes the `tests/` tree. That build/runtime mismatch makes the documented in-container pytest regression commands impossible.
fix: 
verification: 
files_changed: []
