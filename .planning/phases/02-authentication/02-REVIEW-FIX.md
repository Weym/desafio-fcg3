---
phase: 02-authentication
fixed_at: 2026-04-24T19:15:00Z
review_path: .planning/phases/02-authentication/02-REVIEW.md
iteration: 1
findings_in_scope: 7
fixed: 7
skipped: 0
status: all_fixed
---

# Phase 02: Code Review Fix Report

**Fixed at:** 2026-04-24T19:15:00Z
**Source review:** .planning/phases/02-authentication/02-REVIEW.md
**Iteration:** 1

**Summary:**

- Findings in scope: 7 (2 Critical + 5 Warning)
- Fixed: 7
- Skipped: 0

## Fixed Issues

### CR-01: Inconsistent Error Response Shape — Routes vs Auth Dependencies

**Files modified:** `backend/src/main.py`, `backend/tests/integration/test_auth_refresh_rotation.py`, `backend/tests/integration/test_auth_me.py`, `backend/tests/integration/test_auth_logout.py`, `backend/tests/integration/test_service_token.py`, `backend/tests/integration/test_role_guard.py`
**Commit:** 52cebd0
**Applied fix:** Added global `HTTPException` handler in `main.py` that unwraps `detail` into the canonical `{"error": {"code": ..., "message": ...}}` shape. Also added `RequestValidationError` handler (WR-04) in the same commit since both handlers belong in `main.py`. Updated 13 test assertions across 5 test files from `resp.json()["detail"]["error"]` to `resp.json()["error"]` to match the normalized response shape.

### CR-02: Module-Level `get_settings()` in routes.py Causes Import-Time Failure

**Files modified:** `backend/src/features/auth/routes.py`
**Commit:** c22b0a7
**Applied fix:** Removed `settings = get_settings()` at module scope (line 33). Replaced `settings.rate_limit_email` and `settings.rate_limit_ip` in `@limiter.limit()` decorators with module-level string constants `_RATE_LIMIT_EMAIL = "5/15 minutes"` and `_RATE_LIMIT_IP = "20/15 minutes"` (matching Settings defaults). Added lazy `settings = get_settings()` calls inside `request_code()` and ensured `verify_code()` and `refresh()` already had lazy calls.

### WR-01: OTP Hash Comparison Not Using Constant-Time Comparison

**Files modified:** `backend/src/features/auth/services/otp_service.py`
**Commit:** d18b4a9
**Applied fix:** Replaced `==` string comparison with `hmac.compare_digest()` in `verify_code_hash()`. Added `import hmac` at module top. This is defense-in-depth — while timing attacks on a 6-digit OTP with TTL and attempt limits are impractical, constant-time comparison is a security best practice for any secret comparison.

### WR-02: `/auth/refresh` Endpoint Uses HTTPException Instead of JSONResponse

**Files modified:** `backend/src/features/auth/routes.py`
**Commit:** 7dd955a
**Applied fix:** Replaced all 5 `raise HTTPException(401, ...)` calls in the `refresh()` function with `return _auth_error(401, ...)` calls, matching the pattern used by `verify_code()` and `request_code()`. Updated return type annotation to `TokenPair | JSONResponse`. Removed now-unused `HTTPException` from the file's imports.

### WR-03: Resend API Key Set on Every OTP Call

**Files modified:** `backend/src/main.py`, `backend/src/features/auth/services/otp_service.py`
**Commit:** 78c005b, 5e5494d
**Applied fix:** Removed `resend.api_key = settings.resend_api_key` from `generate_and_send_code()`. Added application startup hook to set `resend.api_key` once. Initially used `@app.on_event("startup")` (78c005b), then refactored to modern `@asynccontextmanager` lifespan pattern (5e5494d) to eliminate FastAPI deprecation warning.

### WR-04: `request_code` Route Parses Body Twice (Validation Error Shape)

**Files modified:** `backend/src/main.py`
**Commit:** 52cebd0 (included with CR-01)
**Applied fix:** Added global `RequestValidationError` handler in `main.py` that returns the canonical `{"error": {"code": "VALIDATION_ERROR", "message": ..., "details": [...]}}` shape instead of FastAPI's default `{"detail": [...]}`. This ensures that Pydantic validation errors from `RequestCodePayload.model_validate(_body)` produce the same error shape as all other endpoints.

### WR-05: Return Type Annotations Don't Match Actual Returns

**Files modified:** `backend/src/features/auth/routes.py`
**Commit:** bf2b998
**Applied fix:** Added `responses={401: {"description": ...}}` parameter to `@router.post("/verify-code", ...)` and `@router.post("/refresh", ...)` decorators. This documents error responses in the OpenAPI schema so API documentation consumers see the full response surface, not just the success model.

## Skipped Issues

None — all findings were fixed.

---

_Fixed: 2026-04-24T19:15:00Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
