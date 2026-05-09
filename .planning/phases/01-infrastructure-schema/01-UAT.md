---
status: complete
phase: 01-infrastructure-schema
source: [01-01-SUMMARY.md, 01-02-SUMMARY.md, 01-03-SUMMARY.md, 01-04-SUMMARY.md, 01-05-SUMMARY.md, 01-06-SUMMARY.md, 01-07-SUMMARY.md]
started: 2026-04-25T04:20:24.1214462Z
updated: 2026-04-25T04:20:24.1214462Z
---

## Current Test

[testing complete]

## Tests

### 1. Cold Start Smoke Test
expected: Starting the project stack from scratch should bring PostgreSQL, backend, AI service, and MCP service up cleanly, and the backend health endpoint should answer successfully.
result: pass
reported: "`python -m pytest backend/tests/phase_01/test_phase_01_stack.py -v` passed 5/5, including Docker topology validation and live health endpoint checks."

### 2. Service Health Endpoints
expected: The backend, AI service, and MCP service health endpoints should respond successfully once the stack is up.
result: pass
reported: "`curl -sf http://localhost:8000/health` -> `{\"status\":\"ok\"}`; `curl -sf http://localhost:8001/health` -> stub AI healthy; `curl -sf http://localhost:8002/health` -> stub MCP healthy."

### 3. Environment Bootstrap
expected: The backend should remain import-safe during startup and the environment template should still document the required keys without leaking real secrets.
result: pass
reported: "Covered by the passing Phase 1 stack suite, including backend bootstrap import safety and environment template checks."

### 4. Database Schema Ready
expected: The live database schema should match the Phase 1 application model and Alembic should report no pending drift.
result: pass
reported: "`python -m pytest backend/tests/phase_01/test_phase_01_schema_seed.py -v` passed the schema metadata and Alembic drift checks."

### 5. Seeded Development Dataset
expected: Running the seed command repeatedly should rebuild the same development dataset, preserving curriculum semesters and prerequisite chains consistently across reruns.
result: issue
reported: "`python -m pytest backend/tests/phase_01/test_phase_01_schema_seed.py -v` failed in `test_seed_command_is_repeatable_and_preserves_expected_phase_one_fixtures`. Snapshot diffs showed seeded data changing between consecutive runs (`prereq_chain` empty on one run vs `SCC0102` on another, and the backend full suite also observed `semesters` changing from `0` to `8`)."
severity: blocker

## Summary

total: 5
passed: 4
issues: 1
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "Running the seed command repeatedly preserves the same curriculum semesters and prerequisite relationships across reruns."
  status: failed
  reason: "Automated verification failed: `test_seed_command_is_repeatable_and_preserves_expected_phase_one_fixtures` observed inconsistent dataset snapshots between consecutive seed runs."
  severity: blocker
  test: 5
  root_cause: ""
  artifacts: []
  missing: []
  debug_session: ""
