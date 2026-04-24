---
phase: 02-authentication
generated: 2026-04-24
asvs_level: 1
threats_total: 24
threats_closed: 24
threats_open: 0
---

# Phase 2 — Authentication: Security Audit

**Phase:** 02 — Authentication  
**ASVS Level:** 1  
**Threats Closed:** 24/24  
**Audited:** 2026-04-24

---

## Threat Verification

| Threat ID | Category | Disposition | Status | Evidence |
|-----------|----------|-------------|--------|----------|
| T-02-01-01 | I — Information Disclosure | mitigate | ✅ CLOSED | `otp_service.py:10` imports `hashlib`; `otp_service.py:37` hashes with `hashlib.sha256`. No `log.*` call references `plaintext`. Column stored is `code_hash` + `code_salt` only. |
| T-02-01-02 | T — Tampering | mitigate | ✅ CLOSED | `otp_service.py:42` — `secrets.randbelow(10**6)` (CSPRNG). `random` module never imported. |
| T-02-01-03 | I — Information Disclosure | mitigate | ✅ CLOSED | `config.py:71` — `class Settings(BaseSettings)`. All secrets (`jwt_secret`, `mcp_service_token`, `resend_api_key`, `whatsapp_*`) declared as `Field()` with no `default=`, making them mandatory env-only. No inline `os.getenv()` in service or route files. |
| T-02-01-04 | S — Spoofing | mitigate | ✅ CLOSED | `otp_service.py:63-78` — generate + hash + persist runs unconditionally before `user_exists` check at line 80. Timing parity documented inline at line 91. |
| T-02-01-05 | T — Tampering | accept | ✅ CLOSED | Accepted risk — see Accepted Risks table below. |
| T-02-02-01 | S — Spoofing | mitigate | ✅ CLOSED | `routes.py:73` — identical `RequestCodeResponse(message="Codigo enviado", ...)` returned for all emails regardless of registration status. |
| T-02-02-02 | D — Denial of Service | mitigate | ✅ CLOSED | `routes.py:60-61` — dual `@limiter.limit` decorators: per-email (D-13) and per-IP (D-14). `rate_limit.py:8` — `Limiter(key_func=get_remote_address)` singleton; `rate_limit.py:11-22` — canonical 429 handler. |
| T-02-02-03 | S — Spoofing | mitigate | ✅ CLOSED | `routes.py:109-116` — `row.attempts >= settings.otp_max_attempts` triggers `row.used = True` and auto-resends new code. `settings.otp_max_attempts` defaults to 3 (`config.py:149`). |
| T-02-02-04 | R — Repudiation | mitigate | ✅ CLOSED | `routes.py:142` — `session_service.create_session_pair` called on every successful login. `session_service.py:26-46` — two rows (access + refresh) each with distinct UUID `jti`. |
| T-02-02-05 | T — Tampering | mitigate | ✅ CLOSED | `jwt_service.py:36` — `jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)`. Algorithm defaults to `"HS256"` (`config.py:100`). `jwt_secret` has `min_length=16` enforced by Pydantic (`config.py:96`). |
| T-02-02-06 | E — Elevation of Privilege | mitigate | ✅ CLOSED | `routes.py:126-134` — role derived exclusively from DB table hit (Student → `"student"`, Staff → `"staff"`). No user-supplied role field accepted. |
| T-02-02-07 | T — Tampering | mitigate | ✅ CLOSED | `routes.py:104-105` — expired code returns 401 immediately before the `attempts` increment block (line 109). Expiry check does not mutate `row.attempts`. |
| T-02-03-01 | S — Spoofing | mitigate | ✅ CLOSED | `auth.py:58-61` — `jwt_service.decode()` raises `jose.JWTError` on invalid signature or expiry; caught and re-raised as 401 `"invalid_token"`. Decode uses HS256 + `settings.jwt_secret` (`jwt_service.py:42`). |
| T-02-03-02 | R — Repudiation | mitigate | ✅ CLOSED | `auth.py:74` — `session_service.is_active(db, jti)` called on every authenticated request. `session_service.py:54-61` — query checks `used == False AND expires_at > datetime.now(timezone.utc)`. |
| T-02-03-03 | E — Elevation of Privilege | mitigate | ✅ CLOSED | `auth.py:63-65` — `claims.get("typ") == "refresh"` raises 401 `"Refresh token cannot be used for authentication"` before any user lookup. |
| T-02-03-04 | E — Elevation of Privilege | mitigate | ✅ CLOSED | `auth.py:86-98` — `require_role(role)` dependency raises 403 when `current_user.role != role`. |
| T-02-03-05 | S — Spoofing | mitigate | ✅ CLOSED | `auth.py:116-119` — `hmac.compare_digest(x_service_token.encode("utf-8"), expected.encode("utf-8"))` — constant-time comparison, preventing timing oracle. |
| T-02-03-06 | I — Information Disclosure | mitigate | ✅ CLOSED | `auth.py:110` — missing header → error code `"missing_service_token"`. `auth.py:121` — wrong value → error code `"invalid_service_token"`. Two distinct codes; neither leaks the expected token value. |
| T-02-04-01 | E — Elevation of Privilege | mitigate | ✅ CLOSED | `routes.py:158` — `session_service.revoke(db, current_user.jti)` — revokes exactly one jti. `session_service.py:64-68` — `UPDATE sessions SET used=True WHERE jti = ?`. No wildcard revocation. |
| T-02-04-02 | R — Repudiation | mitigate | ✅ CLOSED | `session_service.py:90-103` — `SELECT … FOR UPDATE` on old refresh row; `old.used` check raises `ValueError("rotation_lost")` if already consumed, forcing 401 at `routes.py:220-222`. |
| T-02-04-03 | T — Tampering | mitigate | ✅ CLOSED | `session_service.py:94` — `.with_for_update()` on `rotate_refresh` SELECT serializes concurrent refresh requests at DB level. |
| T-02-04-04 | E — Elevation of Privilege | mitigate | ✅ CLOSED | `routes.py:194-195` — `claims.get("typ") != "refresh"` → 401 `"Not a refresh token"`. Access tokens (no `typ` claim) are explicitly rejected at `/auth/refresh`. |
| T-02-04-05 | T — Tampering | mitigate | ✅ CLOSED | `session_service.py:105-115` — sibling access row located via `old.parent_jti` and set `used = True` during refresh rotation, forcing re-authentication on old access token. |
| T-02-04-06 | I — Information Disclosure | accept | ✅ CLOSED | Accepted risk — see Accepted Risks table below. |

---

## Accepted Risks

| Threat ID | Risk | Justification |
|-----------|------|---------------|
| T-02-01-05 | Alembic downgrade re-adds plaintext `code` column as nullable | Dev-workflow only. Downgrade is an explicit operator action. In production, downgrade scripts are not executed. Risk accepted for MVP; post-MVP: remove downgrade path or enforce nullable-only with migration guard. |
| T-02-04-06 | `/auth/me` returns profile data from JWT claims without a DB round-trip; stale data possible within the access token TTL | Accepted for MVP. Access tokens have a 1-hour TTL (`config.py:103-105`), limiting the stale window. Post-MVP: evaluate adding a lightweight DB fetch for critical profile fields (e.g., `is_active` status). |

---

## Unregistered Flags

None — no executor threat flags recorded in any SUMMARY.md files for Phase 2.

---

## Open Threats

None — all 24 registered threats are closed.

---

## Notes

### Overall Security Posture

Phase 2 authentication implementation is **clean against all 24 registered threats** at ASVS Level 1. Key observations:

1. **OTP Hashing** — The plaintext OTP code is never persisted or logged at any point in the execution path. The `GeneratedCode` dataclass holds the plaintext only in memory for the duration of the `generate_and_send_code` call and for delivery to Resend. SHA-256 + per-row 16-byte random salt (stored as 32-char hex) is the only form at rest.

2. **Timing Parity** — `generate_and_send_code` unconditionally runs the full generate→hash→persist pipeline before branching on `user_exists`. This prevents email enumeration via response timing differences. The dummy row for unregistered emails is a genuine DB write, not a simulated delay.

3. **Refresh Token Rotation** — `rotate_refresh` correctly uses `SELECT … FOR UPDATE` to prevent concurrent rotation races. The sibling access token invalidation (T-02-04-05) is properly implemented via `parent_jti` linkage, ensuring that a rotated refresh token also invalidates its paired access token.

4. **Service Token** — `hmac.compare_digest` is used correctly with `bytes` on both sides (explicit `.encode("utf-8")` calls), preventing Python's short-circuit string equality from creating a timing oracle.

5. **One Minor Observation (not a registered threat)** — `config.py` contains `DEFAULT_POSTGRES_PASSWORD = "change_me_in_production"` as a module-level constant used as a build-time fallback when no `POSTGRES_PASSWORD` env var is set. This is a dev ergonomics choice and does not affect the security of production secrets managed via `Settings` fields. However, it is worth noting that this constant will appear in source-code searches for credentials. Consider replacing with an empty string or removing the fallback in a future hardening pass.

6. **Rate Limiter Storage** — `slowapi` is configured with in-memory storage (`rate_limit.py:8`). This means rate limits are not shared across multiple `fastapi-app` replicas. Acceptable for MVP (single container). Post-MVP horizontal scaling requires a Redis-backed `slowapi` storage backend.
