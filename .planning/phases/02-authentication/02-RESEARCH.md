# Phase 2: Authentication — Research

**Researched:** 2026-04-23
**Depth:** Level 1 (quick verification) — domain is well-understood (email OTP + JWT); CONTEXT.md already locks 16 decisions (D-01..D-16). This document verifies library APIs and records a Validation Architecture for Nyquist Dimension 8.

---

## Library Decisions (verified via Context7)

### JWT — `python-jose[cryptography]` (>= 3.3.0)
- **Why:** Pure-Python, mature, well-known API (`jose.jwt.encode/decode`); first-class `HS256` support (D-04); actively maintained.
- **Alternatives considered:** `PyJWT` (also fine) — jose picked for `jti`/`exp` claim handling clarity.
- **Confidence:** HIGH
- **Usage pattern:**
  ```python
  from jose import jwt, JWTError
  payload = {"sub": str(user.id), "role": user.role, "jti": str(uuid4()),
             "name": user.name, "email": user.email,
             "exp": int(exp.timestamp()), "iat": int(now.timestamp())}
  token = jwt.encode(payload, settings.JWT_SECRET, algorithm="HS256")
  # Decode:
  try:
      claims = jwt.decode(token, settings.JWT_SECRET, algorithms=["HS256"])
  except JWTError:
      raise HTTPException(401, "invalid_token")
  ```

### Password-grade hashing not required, but OTP hashing IS — `passlib[bcrypt]` (>= 1.7.4) OR `hashlib.sha256 + per-code salt`
- **Decision:** Use `hashlib.sha256(code + per-row salt)` stored alongside code. Codes are 6-digit, 5-minute TTL — full bcrypt is overkill and slow. The `verification_codes.code` column stays `VARCHAR(6)` per D-15's principle of minimal schema change; we add a `code_hash` column (VARCHAR(64)) and a `code_salt` column (VARCHAR(32)). Store only `code_hash`; discard the plaintext after send.
- **Alternative considered:** Keep plaintext (simpler). Rejected — DB dump would expose all active codes.
- **Confidence:** HIGH

### Email delivery — `resend` (>= 2.0.0)
- **Why:** Locked by PROJECT.md constraint. Has async API (`resend.Emails.send_async`) which plays nicely with FastAPI.
- **Pattern (verified via Context7 /resend/resend-python):**
  ```python
  import resend
  resend.api_key = settings.RESEND_API_KEY
  params: resend.Emails.SendParams = {
      "from": settings.RESEND_FROM,
      "to": [email],
      "subject": "Seu código de verificação",
      "html": f"<p>Seu código é <strong>{code}</strong>. Válido por 5 minutos.</p>",
  }
  await resend.Emails.send_async(params)
  ```
- **Confidence:** HIGH

### Rate limiting — `slowapi` (>= 0.1.9)
- **Why:** D-12 mandates in-memory rate limiting; slowapi is the de-facto FastAPI adapter.
- **Key approach:** Two separate `@limiter.limit(...)` decorators on `POST /auth/request-code` — one keyed by email (from request body), one by IP. slowapi supports multiple decorators and a custom `key_func` per decorator.
- **Pattern (verified via Context7 /laurents/slowapi):**
  ```python
  from slowapi import Limiter
  from slowapi.util import get_remote_address

  limiter = Limiter(key_func=get_remote_address)

  async def email_key_func(request: Request) -> str:
      body = await request.json()  # cached by Starlette after first read
      return f"email:{body.get('email', 'unknown')}"

  @router.post("/auth/request-code")
  @limiter.limit("5/15minutes", key_func=email_key_func)
  @limiter.limit("20/15minutes")  # default key_func = IP
  async def request_code(request: Request, payload: RequestCodePayload):
      ...
  ```
- **Gotcha (CRITICAL):** slowapi's `key_func` receives `Request`, not the parsed body. Reading `request.json()` inside a key_func is possible but mutates state — safer pattern is to use a `Depends(...)` that reads and caches the body in `request.state.parsed_body` before the decorator fires. The planner MUST instruct this pattern.
- **Confidence:** MEDIUM (gotcha above documented)

### Crypto — stdlib `hmac.compare_digest` for Service Token
- **Why:** `docs/mcp.md` mandates constant-time comparison. No library needed.
- **Confidence:** HIGH

---

## Schema Extensions (Phase 1 scope)

Phase 1 creates `verification_codes` and `sessions` per `docs/database.md`. Phase 2 needs **incremental schema additions** via a new Alembic migration:

| Table | Column to add | Type | Rationale |
|-------|--------------|------|-----------|
| `verification_codes` | `code_hash` | `VARCHAR(64) NOT NULL` | Store hashed OTP (see hashing above) |
| `verification_codes` | `code_salt` | `VARCHAR(32) NOT NULL` | Per-code salt |
| `sessions` | `token_type` | `VARCHAR(10) NOT NULL DEFAULT 'access'` | D-15: support access vs refresh tokens in same table. Values: `access`, `refresh`. |
| `sessions` | `parent_jti` | `UUID NULL` | For refresh rotation (D-03): links a refresh token to the access token it minted, and a new refresh token to its predecessor (audit trail for stolen-token detection). |

**Migration naming:** `migrations/versions/003_auth_phase2_extensions.py` (follows Phase 1's #001 pgvector, #002 auth tables).

**Note:** The original `code` column stays for backward safety during migration but is nullable and write-disabled after the change. A second migration drops it later. For MVP, we can drop it in the same migration since no data exists yet.

---

## Pitfalls (Phase-specific)

### P-01: slowapi key_func executes BEFORE body parsing
- **Symptom:** `request.json()` inside `email_key_func` intermittently fails with "body already consumed".
- **Mitigation:** Use a `BodyParserDep` dependency that reads `request.body()` once and stores on `request.state`. Both the `key_func` and the route handler read from `request.state.email`.

### P-02: JWT `jti` must be checked against `sessions.jti` on EVERY authenticated request
- **Symptom:** Logout doesn't actually revoke — JWT signature remains valid.
- **Mitigation:** `get_current_user` dependency queries `SELECT 1 FROM sessions WHERE jti = :jti AND expires_at > NOW()`. If no row, 401.

### P-03: Refresh rotation race — two simultaneous refresh calls with the same token
- **Symptom:** Client gets two new refresh tokens; one is immediately invalid; app starts infinite refresh loop.
- **Mitigation:** Wrap rotation in a single transaction with `SELECT ... FOR UPDATE` on the old refresh session row. If the old row's `used` flag is already set (or missing), return 401. Add a boolean `used` column to sessions (or reuse expiry: set `expires_at = NOW()` atomically after rotation).

### P-04: Email enumeration via timing
- **Symptom:** D-08 protects response content, but a fast DB lookup for known emails vs slow branch for unknown ones leaks information via latency.
- **Mitigation:** Always perform the DB lookup + insert path — for unregistered emails, generate & hash a throwaway code but DO NOT send the email. Response time is ~constant.

### P-05: `verification_codes.used` vs `expires_at` vs `attempts` — three states, easy to get wrong
- **Canonical check order in verify-code endpoint:**
  1. `SELECT ... ORDER BY created_at DESC LIMIT 1 FOR UPDATE` (latest code for email, locked)
  2. If `used = true` → 401 `INVALID_CODE`
  3. If `expires_at < NOW()` → 401 `INVALID_CODE` (don't count attempt)
  4. If `hash(submitted, salt) != code_hash` → increment `attempts`; if `attempts >= 3`, invalidate code (`used = true`) AND trigger auto-resend; return 401 `MAX_ATTEMPTS_REACHED` (auto-resend) or `INVALID_CODE`
  5. Match → set `used = true`, issue JWT, create session row.
- All in a single transaction.

---

## Validation Architecture (Nyquist Dimension 8)

### V-01: OTP lifecycle contract test
- **Scope:** `POST /auth/request-code` → receive code (mock Resend, inspect `verification_codes.code_hash`) → `POST /auth/verify-code` with wrong code × 3 → assert auto-resend + new row created → submit correct code from new row → receive JWT with correct `role`, `jti`, `exp` (≈ now + 1h), `sub` = user_id.
- **Command:** `pytest backend/tests/integration/test_auth_otp_flow.py -x`

### V-02: Session revocation
- **Scope:** Login → use JWT to call `GET /auth/me` (expect 200) → `POST /auth/logout` → retry `GET /auth/me` with same JWT (expect 401 `token_revoked`).
- **Command:** `pytest backend/tests/integration/test_auth_logout.py -x`

### V-03: Refresh rotation + replay detection
- **Scope:** Login → receive access+refresh pair → `POST /auth/refresh` with refresh (expect new pair; old refresh row marked used) → retry `POST /auth/refresh` with old refresh (expect 401 `refresh_token_revoked`).
- **Command:** `pytest backend/tests/integration/test_auth_refresh_rotation.py -x`

### V-04: Rate limiting
- **Scope:** 6th request for same email in 15-min window → 429. 21st request from same IP for different emails → 429.
- **Command:** `pytest backend/tests/integration/test_auth_rate_limits.py -x` (uses slowapi's in-memory backend reset between tests).

### V-05: X-Service-Token middleware
- **Scope:** `GET /internal/ping` (test-only route protected by `require_service_token`) → without header → 401. With wrong token → 401. With correct token → 200.
- **Command:** `pytest backend/tests/integration/test_service_token.py -x`

### V-06: Role gate
- **Scope:** Student JWT on `require_role("staff")` route → 403. Staff JWT on same → 200.
- **Command:** `pytest backend/tests/integration/test_role_guard.py -x`

### V-07: Email enumeration protection
- **Scope:** Request code for registered AND unregistered emails; assert identical response body AND response time within ±15% (via statistics over 20 samples).
- **Command:** `pytest backend/tests/integration/test_auth_enumeration.py -x`

### Coverage matrix
| Success Criterion | Validations |
|-------------------|-------------|
| SC-1 (OTP request + expiry 5 min) | V-01 |
| SC-2 (verify-code → JWT with role, jti, used code) | V-01 |
| SC-3 (auto-invalidate after 3 failures + auto-resend; expired don't count) | V-01 |
| SC-4 (logout revokes jti) | V-02 |
| SC-5 (/auth/me) | V-02 |
| D-03 (refresh rotation) | V-03 |
| D-12..14 (rate limits) | V-04 |
| docs/mcp.md (X-Service-Token) | V-05 |
| D-09 (role from lookup table) | V-06 |
| D-08 (enumeration) | V-07 |

---

## Env Vars Required (`backend/src/infrastructure/settings.py`)

| Variable | Example | Source |
|----------|---------|--------|
| `JWT_SECRET` | 64-char random hex | Generated: `openssl rand -hex 32` |
| `JWT_ACCESS_EXPIRY_SECONDS` | `3600` (1h) | D-01 |
| `JWT_REFRESH_EXPIRY_SECONDS` | `2592000` (30d) | D-01 |
| `RESEND_API_KEY` | `re_...` | Resend dashboard |
| `RESEND_FROM` | `Academia <no-reply@desafio-fcg3.edu>` | Resend verified domain |
| `MCP_SERVICE_TOKEN` | 64-char random hex | Generated in Phase 1 (already documented) |
| `OTP_EXPIRY_SECONDS` | `300` (5 min) | SC-1 |
| `OTP_MAX_ATTEMPTS` | `3` | SC-3 |
| `RATE_LIMIT_EMAIL` | `5/15 minutes` | D-13 |
| `RATE_LIMIT_IP` | `20/15 minutes` | D-14 |

All MUST appear in `backend/.env.example` (added by Phase 1 or by this phase — check Phase 1 SUMMARY.md before implementing).

---

## Files the planner will touch (preview for dependency mapping)

- `backend/requirements.txt` — add `python-jose[cryptography]`, `resend`, `slowapi`, `pydantic[email]`
- `backend/src/infrastructure/settings.py` — add auth env vars
- `backend/src/infrastructure/database.py` — re-used from Phase 1 (session factory)
- `backend/alembic/versions/003_auth_phase2_extensions.py` — schema extensions
- `backend/src/features/auth/models.py` — SQLAlchemy models for `VerificationCode`, `Session`, `Student`, `Staff` (the last two may already exist from Phase 1; re-import)
- `backend/src/features/auth/schemas.py` — Pydantic request/response shapes
- `backend/src/features/auth/services/otp_service.py` — generate + hash + store + send
- `backend/src/features/auth/services/jwt_service.py` — issue + decode + rotate
- `backend/src/features/auth/services/session_service.py` — create + revoke + rotate
- `backend/src/features/auth/routes.py` — 5 endpoints
- `backend/src/features/auth/deps.py` — `body_parser`, rate-limit key funcs
- `backend/src/shared/auth.py` — `get_current_user`, `require_role`, `require_service_token`
- `backend/src/shared/rate_limit.py` — `limiter` instance + error handler
- `backend/src/main.py` — register routes, middleware, limiter
- `backend/tests/integration/test_auth_*.py` — V-01..V-07

---

*End of research.*
