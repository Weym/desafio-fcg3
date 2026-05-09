---
phase: 02-authentication
plan: 01
subsystem: auth
tags: [pytest, otp, sha256, resend, pydantic-settings, alembic, slowapi]

# Dependency graph
requires:
  - phase: 01-infrastructure-schema
    provides: "SQLAlchemy models, Alembic migrations 001a-006a, Settings class, database.py session factory"
provides:
  - "Pydantic Settings with all 10 auth env vars (JWT, OTP, rate-limit, Resend)"
  - "Alembic migration 007a: code_hash/code_salt on verification_codes, token_type/parent_jti/used on sessions"
  - "OTP service: generate, hash (SHA-256+salt), persist, dispatch via Resend"
  - "Auth Pydantic schemas: RequestCodePayload, VerifyCodePayload, TokenPair, RefreshPayload, MeResponse"
  - "Wave 0 test infrastructure: conftest with 6 fixtures, 12 integration stubs, pyproject.toml pytest config"
affects: [02-authentication, 03-business-feature-slices, 04-mcp-server]

# Tech tracking
tech-stack:
  added: [slowapi, "pydantic[email]", email-validator, pytest, pytest-asyncio, httpx, pytest-cov, freezegun]
  patterns: ["SHA-256 + per-row salt for OTP hashing", "env-preload block in conftest.py before any backend import", "mock_resend fixture capturing Resend calls"]

key-files:
  created:
    - backend/pyproject.toml
    - backend/requirements-dev.txt
    - backend/tests/conftest.py
    - backend/src/features/auth/services/otp_service.py
    - backend/src/features/auth/schemas.py
    - backend/alembic/versions/007_auth_phase2_extensions.py
    - backend/tests/unit/test_settings.py
    - backend/tests/unit/test_otp_service.py
  modified:
    - backend/requirements.txt
    - backend/src/infrastructure/config.py
    - backend/src/features/auth/models.py
    - .env.example

key-decisions:
  - "Migration numbered 007a (not 003) because Phase 1 already created 003a-006a for curriculum/enrollment/documents/chat tables"
  - "Settings module remains at config.py (Phase 1 location) — plan referenced settings.py which doesn't exist; adapted imports"
  - "OTP hashing uses SHA-256 + per-row salt (not bcrypt) — 6-digit codes with 5-min TTL don't need bcrypt's cost"
  - "Replaced jwt_expiration_hours with jwt_access_expiry_seconds (3600) + jwt_refresh_expiry_seconds (2592000) for access/refresh split"

patterns-established:
  - "conftest.py env-preload: set all required env vars via os.environ.setdefault BEFORE any backend import"
  - "mock_resend fixture: monkeypatch resend.Emails.send_async, capture calls in request.config.mock_resend_calls"
  - "Import src.infrastructure.models in unit tests that instantiate ORM objects to resolve all relationships"

requirements-completed: [AUTH-01, AUTH-03]

# Metrics
duration: 10min
completed: 2026-04-24
---

# Phase 2 Plan 1: Auth Foundation — Settings, OTP Service, and Test Infrastructure

**SHA-256 OTP hashing with per-row salt, Pydantic Settings for 10+ auth env vars, Alembic migration 007a for hash/refresh columns, and pytest Wave 0 scaffolding with 6 fixtures and 24 collectible tests**

## Performance

- **Duration:** 10 min
- **Started:** 2026-04-24T16:30:40Z
- **Completed:** 2026-04-24T16:40:44Z
- **Tasks:** 6/6
- **Files modified:** 26

## Accomplishments

- Pytest infrastructure with 6 reusable fixtures (db_session, app, client, mock_resend, reset_limiter, seed_users) and 24 collectible tests
- Settings module extended with JWT access/refresh expiry, OTP config, rate-limit strings, and Resend sender — all via Pydantic BaseSettings (no os.getenv)
- OTP service using CSPRNG (secrets.randbelow) for generation, SHA-256 + per-row salt for hashing, timing-parity for anti-enumeration
- Alembic migration 007a extending verification_codes (code_hash, code_salt, drop plaintext code) and sessions (token_type, parent_jti, used)
- Pydantic schemas for all auth endpoints ready for Plan 02 routes

## Task Commits

Each task was committed atomically:

1. **Task 1: Wave 0 test infrastructure and dev dependencies** — `d54a646` (feat)
2. **Task 2: Pin runtime dependencies for auth phase** — `f7351c8` (chore)
3. **Task 3: Extend settings module with auth env vars** — `19c15a5` (feat)
4. **Task 4: Alembic migration 007 — OTP hashing + refresh tokens** — `a853498` (feat)
5. **Task 5: Update SQLAlchemy models and Pydantic schemas** — `7b70d78` (feat)
6. **Task 6: Implement OTP service** — `4779f37` (feat)

## Files Created/Modified

### Created
- `backend/pyproject.toml` — pytest config with asyncio_mode=auto
- `backend/requirements-dev.txt` — test dependencies (pytest, httpx, freezegun)
- `backend/tests/conftest.py` — 6 shared fixtures with env-preload block
- `backend/tests/__init__.py` — package marker
- `backend/tests/unit/__init__.py` — package marker
- `backend/tests/integration/__init__.py` — package marker
- `backend/tests/unit/test_settings.py` — 2 real tests for settings contract
- `backend/tests/unit/test_otp_service.py` — 4 real tests for OTP service
- `backend/tests/unit/test_jwt_service.py` — stub for Plan 03
- `backend/tests/integration/test_auth_*.py` — 9 stub files for Plans 02-04
- `backend/src/features/auth/schemas.py` — 6 Pydantic request/response models
- `backend/src/features/auth/services/__init__.py` — services package marker
- `backend/src/features/auth/services/otp_service.py` — OTP generation, hashing, Resend dispatch
- `backend/alembic/versions/007_auth_phase2_extensions.py` — schema migration for code_hash, token_type, parent_jti, used

### Modified
- `backend/requirements.txt` — added slowapi, upgraded pydantic to pydantic[email]
- `backend/src/infrastructure/config.py` — 7 new auth fields on Settings class
- `backend/src/features/auth/models.py` — VerificationCode: code→code_hash+code_salt; Session: +token_type, parent_jti, used
- `.env.example` — added JWT access/refresh expiry, RESEND_FROM, OTP config, rate-limit vars

## Decisions Made

1. **Migration numbered 007a instead of 003:** Phase 1 already created migrations 003a-006a for curriculum, enrollment, documents, and chat tables. The plan specified `003` with `down_revision = "002"` but that slot was taken. Adapted to `007a` with `down_revision = "006a"` to maintain the chain. (Deviation Rule 3 — blocking)

2. **Settings module at `config.py`, not `settings.py`:** Phase 1 created `backend/src/infrastructure/config.py` with the Settings class and `get_settings()` factory. The plan referenced `settings.py` which doesn't exist. All imports adapted to the actual module path.

3. **Removed `jwt_expiration_hours` in favor of `jwt_access_expiry_seconds` + `jwt_refresh_expiry_seconds`:** Phase 1 had a single `jwt_expiration_hours` field. Phase 2 needs separate access (1h) and refresh (30d) TTLs measured in seconds. The old field was replaced.

4. **Unit test for `generate_and_send_code` uses mock session:** The `db_session` fixture requires a live PostgreSQL connection. For pure unit tests, a mocked AsyncSession avoids the DB dependency while still verifying hash properties and no-log invariant.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Migration revision numbering conflict**
- **Found during:** Task 4 (Alembic migration)
- **Issue:** Plan specified `revision = "003"` / `down_revision = "002"` but Phase 1 already created 003a-006a migrations
- **Fix:** Created `007_auth_phase2_extensions.py` with `revision = "007a"` / `down_revision = "006a"`
- **Files modified:** `backend/alembic/versions/007_auth_phase2_extensions.py`
- **Verification:** Python import validates syntax; revision chain is contiguous
- **Committed in:** a853498

**2. [Rule 3 - Blocking] Settings module path mismatch**
- **Found during:** Task 3 (Settings extension)
- **Issue:** Plan referenced `backend/src/infrastructure/settings.py` but Phase 1 created `backend/src/infrastructure/config.py`
- **Fix:** All edits and imports adapted to the actual `config.py` module path
- **Files modified:** `backend/src/infrastructure/config.py`, `backend/tests/unit/test_settings.py`
- **Verification:** `python -c "from src.infrastructure.config import Settings"` succeeds
- **Committed in:** 19c15a5

**3. [Rule 1 - Bug] Unit test required model registry import**
- **Found during:** Task 6 (OTP service unit tests)
- **Issue:** Instantiating `VerificationCode` in tests triggered SQLAlchemy mapper configuration which failed because relationship targets (Enrollment, Grade, etc.) weren't loaded
- **Fix:** Added `import src.infrastructure.models` in test file to trigger full model registry
- **Files modified:** `backend/tests/unit/test_otp_service.py`
- **Verification:** All 4 OTP unit tests pass
- **Committed in:** 4779f37

---

**Total deviations:** 3 auto-fixed (1 Rule 1 bug, 2 Rule 3 blocking)
**Impact on plan:** All fixes necessary for correctness. No scope creep.

## Issues Encountered

- `test_generate_and_send_does_not_log_plaintext` initially used the `db_session` fixture which tried to connect to a live Postgres instance (unavailable outside Docker). Rewrote to use a mocked AsyncSession for true unit-test isolation.

## User Setup Required

None for local testing — all Resend calls are mocked via `mock_resend` fixture. Real email delivery requires Resend API key configuration as documented in the plan's `user_setup` section.

## Known Stubs

| File | Line | Reason |
|------|------|--------|
| `backend/tests/unit/test_jwt_service.py` | 4 | Placeholder — real tests land in Plan 03 Task 2 |
| `backend/tests/integration/test_auth_request_code.py` | 4 | Placeholder — real tests land in Plan 02 Task 2 |
| `backend/tests/integration/test_auth_otp_flow.py` | 4 | Placeholder — real tests land in Plan 02 Task 4 |
| `backend/tests/integration/test_auth_logout.py` | 4 | Placeholder — real tests land in Plan 04 Task 2 |
| `backend/tests/integration/test_auth_me.py` | 4 | Placeholder — real tests land in Plan 04 Task 3 |
| `backend/tests/integration/test_auth_refresh_rotation.py` | 4 | Placeholder — real tests land in Plan 04 Task 5 |
| `backend/tests/integration/test_auth_rate_limits.py` | 4 | Placeholder — real tests land in Plan 02 Task 3 |
| `backend/tests/integration/test_auth_enumeration.py` | 4 | Placeholder — real tests land in Plan 02 Task 5 |
| `backend/tests/integration/test_role_guard.py` | 4 | Placeholder — real tests land in Plan 03 Task 4 |
| `backend/tests/integration/test_service_token.py` | 4 | Placeholder — real tests land in Plan 03 Task 5 |

All stubs are intentional Wave 0 scaffolding — each references the downstream plan/task that will replace it.

## Next Phase Readiness

- Plans 02, 03, 04 can immediately use: settings object, auth models, OTP service, conftest fixtures, and all stub test files
- Alembic migration 007a must be applied against a running DB before integration tests (`docker compose exec fastapi-app alembic upgrade head`)
- The `reset_limiter` fixture has a graceful no-op fallback until Plan 02 creates `src/shared/rate_limit.py`

## Self-Check: PASSED

- All 25 key files verified present
- All 6 task commits verified in git log
- 7 unit tests pass (`pytest tests/unit -x -q`)
- 24 tests collected (`pytest --collect-only -q`)

---
*Phase: 02-authentication*
*Completed: 2026-04-24*
