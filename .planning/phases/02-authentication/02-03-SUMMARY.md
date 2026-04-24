---
phase: 02-authentication
plan: 03
subsystem: auth
tags: [jwt, fastapi, hmac, rbac, service-token, dependencies]

# Dependency graph
requires:
  - phase: 02-authentication plan 01
    provides: "settings, database, models (Session, Student, Staff)"
  - phase: 02-authentication plan 02
    provides: "jwt_service (decode, issue_access, issue_refresh), session_service (is_active)"
provides:
  - "get_current_user dependency — JWT validation + jti revocation check"
  - "require_role(role) dependency — role-based access guard"
  - "require_service_token dependency — MCP internal auth via constant-time comparison"
  - "CurrentUser dataclass (id, role, email, name, jti)"
affects: [03-business-feature-slices, 04-mcp-server, 05-ai-service, 06-whatsapp-webhook]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "FastAPI Depends() chain: HTTPBearer → get_current_user → require_role"
    - "Constant-time token comparison via hmac.compare_digest"
    - "Test probe routers in tests/integration/_*_probe.py (not in production code)"

key-files:
  created:
    - backend/src/shared/auth.py
    - backend/tests/integration/_role_guard_probe.py
    - backend/tests/integration/test_role_guard.py
    - backend/tests/integration/_service_token_probe.py
    - backend/tests/integration/test_service_token.py
  modified: []

key-decisions:
  - "Used get_settings() lazy call in require_service_token instead of module-level settings import — avoids import-time env var validation issues in tests"
  - "Refresh tokens (typ='refresh') explicitly rejected in get_current_user — prevents token type confusion"
  - "Test probe routers placed under tests/integration/ to avoid polluting src/main.py"

patterns-established:
  - "Depends(require_role('staff')) pattern for role-gated endpoints"
  - "Depends(require_service_token) as route dependency for MCP-only endpoints"
  - "Probe routers for integration-testing FastAPI dependencies without touching production routes"

requirements-completed: [AUTH-02]

# Metrics
duration: 3min
completed: 2026-04-24
---

# Phase 02 Plan 03: Auth Dependencies Summary

**Three reusable FastAPI dependencies (get_current_user, require_role, require_service_token) with 11 green integration tests covering JWT validation, role-based access, jti revocation, and constant-time service token comparison.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-24T17:05:38Z
- **Completed:** 2026-04-24T17:08:27Z
- **Tasks:** 3
- **Files created:** 5

## Accomplishments

- `get_current_user` dependency validates JWT tokens, rejects refresh tokens on non-refresh routes, and checks jti against sessions table for revocation
- `require_role(role)` returns 403 with canonical error shape for wrong-role callers
- `require_service_token` validates X-Service-Token via `hmac.compare_digest` for constant-time comparison (prevents timing oracle)
- 11 integration tests covering all threat model mitigations (T-02-03-01 through T-02-03-06)

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement shared auth dependencies** - `6b1ba8f` (feat)
2. **Task 2: Integration test — require_role guard** - `f84ed2c` (test)
3. **Task 3: Integration test — X-Service-Token** - `a7746c8` (test)

## Files Created/Modified

- `backend/src/shared/auth.py` — Three FastAPI dependencies + CurrentUser dataclass (121 lines)
- `backend/tests/integration/_role_guard_probe.py` — Test-only probe router with staff-only and student-only routes
- `backend/tests/integration/test_role_guard.py` — 7 tests: wrong-role, right-role (staff+student), missing header, revoked jti, tampered signature, refresh token rejection
- `backend/tests/integration/_service_token_probe.py` — Test-only probe router with internal-ping endpoint
- `backend/tests/integration/test_service_token.py` — 4 tests: no header, wrong token, correct token, different-length token

## Decisions Made

- **get_settings() lazy call:** Used `get_settings()` inside `require_service_token` instead of module-level `settings = get_settings()` to avoid import-time env var validation issues during test collection
- **Refresh token rejection:** Explicitly check `claims.get("typ") == "refresh"` in `get_current_user` to prevent refresh tokens from being used for API authentication
- **Probe routers in tests/:** Placed test probe routers at `tests/integration/_*_probe.py` to avoid any production code changes

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- All downstream phases (3–6) can now use `Depends(get_current_user)` and `Depends(require_role('staff'))` to gate endpoints
- Phase 4 (MCP Server) can use `Depends(require_service_token)` for internal auth
- No regressions: all 19 pre-existing tests (unit + integration from Plans 01–02) pass

## Self-Check: PASSED

- All 5 created files verified present on disk
- All 3 task commits verified in git log (6b1ba8f, f84ed2c, a7746c8)

---
*Phase: 02-authentication*
*Completed: 2026-04-24*
