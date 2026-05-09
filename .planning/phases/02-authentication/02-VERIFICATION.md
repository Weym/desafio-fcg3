---
phase: 02-authentication
verified: 2026-04-24T18:30:00Z
status: human_needed
score: 5/5 must-haves verified
overrides_applied: 0
human_verification:
  - test: "Run full Phase 2 test suite against SQLite"
    expected: "All 47 tests pass (11 unit + 36 integration)"
    why_human: "Cannot run pytest in this verification session — requires Python environment with all dependencies installed"
  - test: "Run Alembic migration 007a round-trip against PostgreSQL"
    expected: "alembic upgrade head succeeds, alembic downgrade -1 && alembic upgrade head round-trips cleanly"
    why_human: "Requires running PostgreSQL instance with Phase 1 migrations already applied"
  - test: "Verify rate limit behavior in live request sequence"
    expected: "6th request per email returns 429; 21st request per IP returns 429"
    why_human: "Rate limiting behavior depends on in-memory state and timing that can't be verified statically"
  - test: "Verify D-08 enumeration timing parity under realistic conditions"
    expected: "Response time for registered vs unregistered emails within ±15%"
    why_human: "Timing tests unreliable in unit test (mocked Resend ~0ms), need production-like latency"
---

# Phase 2: Authentication Verification Report

**Phase Goal:** Students and staff can authenticate via email OTP, receive role-bearing JWTs, and the auth middleware is ready to protect all downstream endpoints.
**Verified:** 2026-04-24T18:30:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User can request a 6-digit OTP to their email and receive it within seconds via Resend; the code expires after 5 minutes | ✓ VERIFIED | `POST /auth/request-code` registered in routes.py:55, calls `otp_service.generate_and_send_code` which uses `resend.Emails.send_async`, OTP_EXPIRY_SECONDS=300 in settings, 5 integration tests in test_auth_request_code.py |
| 2 | User can submit the OTP and receive a JWT containing `role` (student\|staff) and a unique `jti`; the verification code is marked used and cannot be reused | ✓ VERIFIED | `POST /auth/verify-code` in routes.py:71, issues JWT with sub/role/jti/name/email/exp/iat via jwt_service.issue_token_pair, creates session pair (access+refresh), marks code row used=True; 4 integration tests in test_auth_otp_flow.py verify happy path + role assignment |
| 3 | System automatically invalidates a code and issues a new one after 3 failed attempts; expired codes do not count toward the attempt limit | ✓ VERIFIED | routes.py:97-106 implements 3-strike with `otp_max_attempts` check, auto-resend on max attempts, expired code path (line 92) returns error without incrementing; test_auth_otp_flow.py `test_wrong_code_three_times_triggers_auto_resend` and `test_expired_code_returns_invalid_without_incrementing_attempts` verify both behaviors |
| 4 | Authenticated user can call `POST /auth/logout` and subsequent requests with the same JWT are rejected (jti revoked in sessions table) | ✓ VERIFIED | routes.py:140-148 `/auth/logout` calls `session_service.revoke(db, current_user.jti)`, test_auth_logout.py verifies multi-session scope (only current jti revoked), post-logout /auth/me returns 401 token_revoked |
| 5 | Authenticated user can call `GET /auth/me` and receive their own profile data | ✓ VERIFIED | routes.py:151-159 `/auth/me` returns MeResponse from JWT claims (id, email, name, role), test_auth_me.py verifies happy path, no-auth 401, refresh-token rejection |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `backend/src/features/auth/routes.py` | All 5 endpoints (request-code, verify-code, logout, me, refresh) | ✓ VERIFIED | 212 lines, all 5 endpoints present: POST /request-code (L55), POST /verify-code (L71), POST /logout (L140), GET /me (L151), POST /refresh (L162) |
| `backend/src/features/auth/deps.py` | body_parser + email_key_func + BodyCacheMiddleware | ✓ VERIFIED | 59 lines, contains BodyCacheMiddleware (L15), async body_parser (L33), sync email_key_func (L49), request.state.parsed_body caching pattern |
| `backend/src/features/auth/services/otp_service.py` | OTP generation, hashing, Resend dispatch | ✓ VERIFIED | 98 lines, hashlib.sha256 (L36), secrets.randbelow(10**6) (L41), resend.Emails.send_async (L90), timing parity (always persist), no plaintext logging |
| `backend/src/features/auth/services/jwt_service.py` | JWT encode/decode, issue access + refresh | ✓ VERIFIED | 84 lines, HS256 signing (L36,42), enriched access payload (sub,role,jti,name,email,exp,iat), refresh with typ="refresh" (L73), issue_token_pair (L80) |
| `backend/src/features/auth/services/session_service.py` | Session creation, revocation, rotation | ✓ VERIFIED | 117 lines, create_session_pair (L17), is_active with tz-aware check (L50), revoke (L64), rotate_refresh with SELECT FOR UPDATE (L90-94) + sibling invalidation (L106-115) |
| `backend/src/shared/auth.py` | get_current_user, require_role, require_service_token, CurrentUser | ✓ VERIFIED | 121 lines, get_current_user with JWT decode + jti check + refresh rejection (L44-83), require_role with 403 (L86-98), require_service_token with hmac.compare_digest (L101-121), CurrentUser dataclass (L28-34) |
| `backend/src/shared/rate_limit.py` | slowapi Limiter singleton + reset() + 429 handler | ✓ VERIFIED | 40 lines, Limiter(key_func=get_remote_address) (L8), rate_limit_exceeded_handler with canonical error shape (L11-22), reset() helper (L25-40) |
| `backend/src/infrastructure/config.py` | Settings with all auth env vars | ✓ VERIFIED | 245 lines, jwt_secret (L95), jwt_algorithm=HS256 (L99), jwt_access_expiry_seconds=3600 (L103), jwt_refresh_expiry_seconds=2592000 (L107), mcp_service_token (L112), resend_api_key (L135), resend_from (L139), otp_expiry_seconds=300 (L144), otp_max_attempts=3 (L148), rate_limit_email="5/15 minutes" (L153), rate_limit_ip="20/15 minutes" (L157) |
| `backend/src/features/auth/models.py` | ORM models with code_hash, code_salt, token_type, parent_jti, used | ✓ VERIFIED | 133 lines, VerificationCode with code_hash (L78), code_salt (L79), no plaintext code column; Session with token_type (L112), parent_jti (L113), used (L114), check constraint ck_sessions_token_type (L98-100) |
| `backend/src/features/auth/schemas.py` | Pydantic request/response models | ✓ VERIFIED | 34 lines, RequestCodePayload, RequestCodeResponse, VerifyCodePayload, TokenPair, RefreshPayload, MeResponse all present |
| `backend/alembic/versions/007_auth_phase2_extensions.py` | Migration for OTP hashing + refresh tokens | ✓ VERIFIED | 90 lines, revision="007a", down_revision="006a", adds code_hash/code_salt to verification_codes, drops plaintext code, adds token_type/parent_jti/used to sessions, creates index + check constraint, clean downgrade |
| `backend/src/main.py` | Router registration, limiter, middleware | ✓ VERIFIED | 25 lines, BodyCacheMiddleware (L13), app.state.limiter (L16), RateLimitExceeded handler (L17), include_router(auth_router) (L20) |
| `.env.example` | All auth env vars documented | ✓ VERIFIED | 85 lines, JWT_SECRET (L23), JWT_ALGORITHM (L25), JWT_ACCESS_EXPIRY_SECONDS (L27), JWT_REFRESH_EXPIRY_SECONDS (L29), MCP_SERVICE_TOKEN (L33), RESEND_API_KEY (L45), RESEND_FROM (L47), OTP_EXPIRY_SECONDS (L50), OTP_MAX_ATTEMPTS (L52), RATE_LIMIT_EMAIL (L55), RATE_LIMIT_IP (L57), "openssl rand -hex 32" hints (L22,L31) |
| `backend/tests/conftest.py` | 6 fixtures: db_session, app, client, mock_resend, reset_limiter, seed_users | ✓ VERIFIED | 208 lines, env-preload block (L1-15), SQLite test engine with ForUpdateArg hook, all 6 fixtures present (db_session L88, app L124, client L131, mock_resend L147, reset_limiter L169, seed_users L185) |
| `backend/pyproject.toml` | pytest config with asyncio_mode=auto | ✓ VERIFIED (from SUMMARY) | Created in Plan 01 |
| `backend/tests/unit/test_settings.py` | Real tests for settings contract | ✓ VERIFIED | 41 lines, 2 tests: test_settings_all_auth_vars_declared, test_settings_requires_jwt_secret |
| `backend/tests/unit/test_otp_service.py` | Real tests for OTP service | ✓ VERIFIED | 65 lines, 4 tests: 6-digit generation, deterministic hash, roundtrip verify, no-plaintext-in-logs |
| `backend/tests/unit/test_jwt_service.py` | Real tests for JWT service | ✓ VERIFIED | 50 lines, 5 tests: access payload claims, refresh typ, tampered signature, distinct jtis, decode |
| `backend/tests/integration/test_auth_request_code.py` | Real integration tests for request-code | ✓ VERIFIED | 75 lines, 5 tests covering 200 response, DB row, no plaintext leak, Resend call, D-08 unregistered |
| `backend/tests/integration/test_auth_otp_flow.py` | Real integration tests for full OTP flow | ✓ VERIFIED | 162 lines, 4 tests: happy path, AUTH-03 3-strike auto-resend, expired code, staff login role |
| `backend/tests/integration/test_auth_logout.py` | Real integration tests for logout | ✓ VERIFIED | 60 lines, 3 tests: multi-session scope (D-11), post-logout 401, no-token 401 |
| `backend/tests/integration/test_auth_me.py` | Real integration tests for /me | ✓ VERIFIED | 45 lines, 3 tests: profile from claims, no-auth 401, refresh-token rejection |
| `backend/tests/integration/test_auth_refresh_rotation.py` | Real integration tests for refresh rotation | ✓ VERIFIED | 79 lines, 4 tests: rotation + invalidation, replay 401, access-token rejection, concurrent race |
| `backend/tests/integration/test_auth_rate_limits.py` | Real integration tests for rate limits | ✓ VERIFIED | 46 lines, 3 tests: email limit (429 on 6th), IP limit (429 on 21st), reset verification |
| `backend/tests/integration/test_auth_enumeration.py` | Real integration tests for enumeration protection | ✓ VERIFIED | 87 lines, 3 tests: body identity, code path parity, email-only dispatch |
| `backend/tests/integration/test_role_guard.py` | Real integration tests for role guard | ✓ VERIFIED | 108 lines, 7 tests: wrong-role 403, right-role staff 200, right-role student 200, missing header 401, revoked jti 401, tampered sig 401, refresh rejection 401 |
| `backend/tests/integration/test_service_token.py` | Real integration tests for service token | ✓ VERIFIED | 45 lines, 4 tests: no header 401, wrong token 401, correct token 200, short token 401 |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| routes.py | otp_service.py | `generate_and_send_code`, `verify_code_hash` calls | ✓ WIRED | routes.py:66 calls generate_and_send_code, routes.py:96 calls verify_code_hash, routes.py:102 calls generate_and_send_code (auto-resend) |
| routes.py | jwt_service.py | `issue_token_pair`, `decode` calls | ✓ WIRED | routes.py:129 calls issue_token_pair (verify-code), routes.py:170 calls decode (refresh), routes.py:198 calls issue_token_pair (refresh) |
| routes.py | session_service.py | `create_session_pair`, `revoke`, `rotate_refresh` | ✓ WIRED | routes.py:130 create_session_pair, routes.py:146 revoke, routes.py:201 rotate_refresh |
| routes.py | rate_limit.py | `@limiter.limit` decorators | ✓ WIRED | routes.py:56 @limiter.limit(settings.rate_limit_email, key_func=email_key_func), routes.py:57 @limiter.limit(settings.rate_limit_ip) |
| routes.py | shared/auth.py | `Depends(get_current_user)` on logout and me | ✓ WIRED | routes.py:142 Depends(get_current_user) on logout, routes.py:152 Depends(get_current_user) on me |
| main.py | routes.py | `include_router(auth_router)` | ✓ WIRED | main.py:20 app.include_router(auth_router) |
| main.py | rate_limit.py | `app.state.limiter` + exception handler | ✓ WIRED | main.py:16 app.state.limiter = limiter, main.py:17 add_exception_handler(RateLimitExceeded, ...) |
| shared/auth.py | jwt_service.py | imports decode() | ✓ WIRED | auth.py:22 imports jwt_service, auth.py:59 calls jwt_service.decode |
| shared/auth.py | session_service.py | imports is_active() | ✓ WIRED | auth.py:22 imports session_service, auth.py:74 calls session_service.is_active |
| shared/auth.py | config.py | imports get_settings for MCP_SERVICE_TOKEN | ✓ WIRED | auth.py:20 imports get_settings, auth.py:112 calls get_settings() for mcp_service_token |
| otp_service.py | config.py | imports get_settings for RESEND_API_KEY, OTP_EXPIRY_SECONDS | ✓ WIRED | otp_service.py:21 imports get_settings, otp_service.py:60 calls get_settings() |
| otp_service.py | models.py | writes VerificationCode rows | ✓ WIRED | otp_service.py:20 imports VerificationCode, Student, Staff, otp_service.py:68-78 creates row |
| migration 007a | verification_codes, sessions tables | op.add_column calls | ✓ WIRED | Migration adds code_hash, code_salt, drops code; adds token_type, parent_jti, used |
| session_service.py | models.py | SELECT FOR UPDATE on Session rows | ✓ WIRED | session_service.py:90-94 select(SessionModel).with_for_update() in rotate_refresh |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| routes.py /auth/request-code | otp_service.generate_and_send_code | DB write (VerificationCode) + Resend email | Yes — creates DB row, sends email via Resend | ✓ FLOWING |
| routes.py /auth/verify-code | jwt_service.issue_token_pair | OTP verification → JWT issuance → session creation | Yes — queries Student/Staff table, issues real JWT, creates session rows | ✓ FLOWING |
| routes.py /auth/me | CurrentUser from JWT claims | get_current_user dependency (JWT decode + session check) | Yes — real JWT claims extracted in auth.py:59 | ✓ FLOWING |
| routes.py /auth/logout | session_service.revoke | DB update (set used=True) | Yes — updates sessions table | ✓ FLOWING |
| routes.py /auth/refresh | session_service.rotate_refresh | DB query + update + insert | Yes — SELECT FOR UPDATE + mark used + create new pair | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Auth module imports cleanly | Static analysis of import chain | All imports use `src.` prefix, no circular deps visible | ? SKIP — requires Python runtime |
| Test suite passes | `cd backend && pytest -x -q` | Cannot run without Python env | ? SKIP — needs runtime |
| All 5 endpoints registered | Check routes in main.py + routes.py | main.py includes auth_router; routes.py has all 5 `@router.{method}` decorators | ✓ PASS (static) |

Step 7b: SKIPPED for runtime behavioral checks (no Python runtime available). Static analysis confirms all wiring and artifact completeness.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| AUTH-01 | Plan 01, 02 | Aluno ou staff pode solicitar código OTP de 6 dígitos enviado por email via Resend (expira em 5 minutos) | ✓ SATISFIED | POST /auth/request-code exists, calls otp_service (SHA-256 hashed, 6-digit via secrets.randbelow), Resend dispatch, OTP_EXPIRY_SECONDS=300; 5 integration tests verify behavior |
| AUTH-02 | Plan 02, 03, 04 | Aluno ou staff pode verificar código e receber JWT com campo `role` (student\|staff) e `jti` único | ✓ SATISFIED | POST /auth/verify-code issues JWT with role + jti via jwt_service.issue_token_pair, creates session pair; get_current_user validates JWTs; 4 OTP flow tests + 7 role guard tests verify |
| AUTH-03 | Plan 01, 02 | Sistema invalida o código após 3 tentativas incorretas e envia novo código automaticamente; códigos expirados não incrementam o contador | ✓ SATISFIED | routes.py:97-106 implements 3-strike + auto-resend; expired code path (line 92) doesn't increment; test_auth_otp_flow.py verifies both behaviors |
| AUTH-04 | Plan 04 | Usuário autenticado pode encerrar sessão (JWT revogado por `jti` na tabela `sessions`) | ✓ SATISFIED | POST /auth/logout calls session_service.revoke; test_auth_logout.py verifies multi-session scope (D-11), post-logout token rejection |
| AUTH-05 | Plan 04 | Usuário autenticado pode consultar seus próprios dados (`GET /auth/me`) | ✓ SATISFIED | GET /auth/me returns MeResponse from JWT claims (id, email, name, role); test_auth_me.py verifies profile data, auth requirements, refresh rejection |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | No anti-patterns detected | — | — |

**Anti-pattern scan results:**
- No TODO/FIXME/PLACEHOLDER in auth source files
- No `os.getenv` / `os.environ` in auth service files (all use Pydantic Settings)
- No `random.randint` / `random.choice` (only `secrets.randbelow`)
- No `datetime.utcnow()` (only in comments warning against it)
- No empty implementations or return-null stubs
- All test files contain real assertions (no placeholder stubs remaining)

### Human Verification Required

#### 1. Full Test Suite Execution
**Test:** Run `cd backend && pytest -x -q` in a Python 3.12 environment with all dependencies installed
**Expected:** All 47 tests pass (11 unit + 36 integration) — as claimed by 02-04-SUMMARY.md
**Why human:** Requires active Python environment with pytest, SQLite+aiosqlite, and all backend dependencies. Cannot execute in verification session.

#### 2. Alembic Migration Round-Trip
**Test:** Run `alembic upgrade head && alembic downgrade -1 && alembic upgrade head` against PostgreSQL with Phase 1 migrations (001a-006a) applied
**Expected:** Migration 007a upgrades and downgrades cleanly; `\d verification_codes` shows code_hash + code_salt (no plaintext code); `\d sessions` shows token_type, parent_jti, used
**Why human:** Requires running PostgreSQL instance (Docker Compose) — not available in static verification.

#### 3. Rate Limiting Live Verification
**Test:** Send 6 consecutive POST /auth/request-code for same email, then 21 for different emails from same IP
**Expected:** 6th request per email returns 429 MAX_ATTEMPTS_REACHED; 21st per IP returns 429
**Why human:** Rate limiting depends on in-memory slowapi state and real HTTP request timing.

#### 4. Enumeration Timing Parity (D-08)
**Test:** Measure response times for registered vs unregistered emails with real Resend integration (not mocked)
**Expected:** Response time ratio within ±15% — timing-equalized by the "always persist" code path in otp_service
**Why human:** Test infrastructure uses mocked Resend (0ms latency), making timing comparisons meaningless. Need real email delivery latency to validate.

### Gaps Summary

No structural or implementation gaps were found. All 5 roadmap success criteria are met by the codebase artifacts. All 5 requirement IDs (AUTH-01 through AUTH-05) are satisfied with supporting implementation and integration tests.

The only open items are runtime verification needs:
1. Test suite execution (47 tests claimed passing — SUMMARY says `4e6bf9a` is the final commit with all green)
2. Alembic migration round-trip (requires PostgreSQL)
3. Rate limiting behavior (requires live HTTP requests)
4. D-08 timing parity (requires production-like latency)

**Assessment:** The codebase implementation is complete and well-structured. Code quality is high — no anti-patterns, proper security practices (CSPRNG, SHA-256 hashing, hmac.compare_digest, tz-aware datetimes, no plaintext logging), comprehensive test coverage with 47 tests across unit and integration. The only thing preventing a `passed` status is the inability to run the test suite and Alembic migrations in this verification session.

---

_Verified: 2026-04-24T18:30:00Z_
_Verifier: the agent (gsd-verifier)_
