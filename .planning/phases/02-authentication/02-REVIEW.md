---
phase: 02-authentication
reviewed: 2026-04-24T18:30:00Z
depth: standard
files_reviewed: 22
files_reviewed_list:
  - backend/src/infrastructure/config.py
  - backend/src/features/auth/models.py
  - backend/src/features/auth/schemas.py
  - backend/src/features/auth/deps.py
  - backend/src/features/auth/routes.py
  - backend/src/features/auth/services/__init__.py
  - backend/src/features/auth/services/otp_service.py
  - backend/src/features/auth/services/jwt_service.py
  - backend/src/features/auth/services/session_service.py
  - backend/src/shared/rate_limit.py
  - backend/src/shared/auth.py
  - backend/src/main.py
  - backend/alembic/versions/007_auth_phase2_extensions.py
  - backend/pyproject.toml
  - backend/tests/conftest.py
  - backend/tests/unit/test_settings.py
  - backend/tests/unit/test_otp_service.py
  - backend/tests/unit/test_jwt_service.py
  - backend/tests/integration/test_auth_request_code.py
  - backend/tests/integration/test_auth_otp_flow.py
  - backend/tests/integration/test_auth_rate_limits.py
  - backend/tests/integration/test_auth_enumeration.py
  - backend/tests/integration/test_auth_logout.py
  - backend/tests/integration/test_auth_me.py
  - backend/tests/integration/test_auth_refresh_rotation.py
  - backend/tests/integration/test_role_guard.py
  - backend/tests/integration/test_service_token.py
  - backend/tests/integration/_role_guard_probe.py
  - backend/tests/integration/_service_token_probe.py
  - .env.example
findings:
  critical: 2
  warning: 5
  info: 5
  total: 12
status: issues_found
---

# Phase 02: Code Review Report

**Reviewed:** 2026-04-24T18:30:00Z
**Depth:** standard
**Files Reviewed:** 22 source files + 7 test files
**Status:** issues_found

## Summary

Phase 02 implements a solid OTP-based authentication system with JWT access/refresh token pairs, session management with jti-based revocation, role-based access control, and MCP service token authentication. The architecture is well-structured with proper separation of concerns across services, dependencies, and routes.

**Strengths:** SHA-256+salt OTP hashing, constant-time service token comparison (hmac.compare_digest), refresh token rotation with replay detection, enumeration protection via timing parity, proper CSPRNG usage, and comprehensive test coverage (47 tests).

**Key concerns:** Two critical issues — inconsistent error response shapes between routes and auth dependencies (will cause client-side parsing failures), and a module-level `get_settings()` call that will fail at import time in certain deployment configurations. Five warnings around missing error handling, OTP hash comparison not using constant-time comparison, and a session data leak pattern.

## Critical Issues

### CR-01: Inconsistent Error Response Shape — Routes vs Auth Dependencies

**File:** `backend/src/features/auth/routes.py:47-52` vs `backend/src/shared/auth.py:37-41`
**Issue:** Routes use `JSONResponse` producing `{"error": {"code": ..., "message": ...}}` (the canonical shape per CONVENTIONS.md), but auth dependencies (`get_current_user`, `require_role`, `require_service_token`) use `HTTPException(detail={"error": {...}})` which FastAPI wraps as `{"detail": {"error": {...}}}`. This means:
- `POST /auth/verify-code` errors → `resp.json()["error"]["code"]`
- `GET /auth/me` 401 errors → `resp.json()["detail"]["error"]["code"]`
- `POST /auth/refresh` errors → `resp.json()["detail"]["error"]["code"]` (uses HTTPException)

The test files confirm this inconsistency — integration tests for routes check `resp.json()["error"]` while tests for dependency-guarded endpoints check `resp.json()["detail"]["error"]`. A client consuming these endpoints must handle two different error shapes from the same API surface.

**Fix:** Standardize `shared/auth.py` to return `JSONResponse` instead of `HTTPException`, or add a global exception handler that normalizes `HTTPException` detail into the canonical `{"error": {...}}` shape:

```python
# Option A: In shared/auth.py, use JSONResponse (matches routes.py pattern)
# BUT: FastAPI dependencies cannot return JSONResponse — they must raise.
# So Option B is better:

# Option B: Add to main.py — a global HTTPException handler that unwraps detail
from fastapi import Request
from fastapi.exceptions import HTTPException

@app.exception_handler(HTTPException)
async def normalize_http_exception(request: Request, exc: HTTPException):
    body = exc.detail
    # If detail is already our canonical shape, use it directly
    if isinstance(body, dict) and "error" in body:
        return JSONResponse(status_code=exc.status_code, content=body)
    # Otherwise wrap it
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": {"code": "error", "message": str(body)}},
    )
```

### CR-02: Module-Level `get_settings()` in routes.py Causes Import-Time Failure

**File:** `backend/src/features/auth/routes.py:33`
**Issue:** `settings = get_settings()` is called at module scope. This executes when the module is first imported, which happens when FastAPI registers the router in `main.py`. If required environment variables (e.g., `JWT_SECRET`, `RESEND_API_KEY`) are not yet set at import time, this will raise a `ValidationError` and crash the application at startup — even if the variables would be available later (e.g., loaded by a process manager or injected after module load).

This is inconsistent with the pattern in `shared/auth.py:112` which correctly uses `get_settings()` lazily inside `require_service_token`. The `get_settings()` function uses `@lru_cache`, so the performance cost of calling it per-request is negligible after the first call.

The `@limiter.limit()` decorators on lines 56-57 also reference this module-level `settings`, making them fail if settings can't be loaded.

**Fix:** Remove the module-level call and use `get_settings()` lazily inside each handler:

```python
# Remove line 33: settings = get_settings()

# Line 56-57: For rate limit decorators, use lambda or a lazy approach
# Option 1: Use string literals directly (simplest, aligned with test env)
@router.post("/request-code", response_model=RequestCodeResponse, status_code=200)
@limiter.limit("5/15 minutes", key_func=email_key_func)  # or load from env directly
@limiter.limit("20/15 minutes")
async def request_code(...):
    settings = get_settings()  # lazy
    ...

# Option 2: Accept the module-level call but document the constraint
# that env vars MUST be set before any import of routes.py
```

Note: The `@limiter.limit(settings.rate_limit_email)` decorator forces an eager evaluation. If dynamic rate limits from settings are important, a custom rate limit key function or middleware approach is needed. If static defaults are acceptable, hardcode them in the decorator and override via config at a higher level.

## Warnings

### WR-01: OTP Hash Comparison Not Using Constant-Time Comparison

**File:** `backend/src/features/auth/services/otp_service.py:98`
**Issue:** `verify_code_hash` uses `==` for string comparison between the submitted hash and stored hash. While timing attacks on a 6-digit OTP with 5-minute TTL and 3-attempt limit are not practically exploitable (the attack surface is extremely constrained), using constant-time comparison is a defense-in-depth best practice for any secret comparison.

**Fix:**
```python
import hmac

def verify_code_hash(submitted: str, stored_hash: str, stored_salt: str) -> bool:
    """Compare submitted code against stored hash using the same salt (constant-time)."""
    computed = _hash_code(submitted, stored_salt)
    return hmac.compare_digest(computed, stored_hash)
```

### WR-02: `/auth/refresh` Endpoint Uses HTTPException Instead of JSONResponse

**File:** `backend/src/features/auth/routes.py:172-177`
**Issue:** The `/auth/refresh` endpoint uses `raise HTTPException(401, {"error": {...}})` while `/auth/verify-code` and `/auth/request-code` use `_auth_error()` which returns `JSONResponse`. Within the same router file, two different error response patterns are used. This will produce `{"detail": {"error": {...}}}` for refresh errors but `{"error": {...}}` for verify-code errors.

**Fix:** Use `_auth_error()` (or return JSONResponse) consistently for all error paths in the refresh endpoint:

```python
# Replace:
raise HTTPException(401, {"error": {"code": "invalid_token", ...}})
# With:
return _auth_error(401, "invalid_token", "Invalid or expired refresh token")
```

Note: When using `return` instead of `raise`, the return type annotation of `refresh()` must accommodate `JSONResponse | TokenPair`.

### WR-03: Resend API Key Set on Module-Level Singleton Every Call

**File:** `backend/src/features/auth/services/otp_service.py:61`
**Issue:** `resend.api_key = settings.resend_api_key` is set on every call to `generate_and_send_code`. The `resend` module uses a module-level `api_key` variable, so this mutates global state on every OTP request. In a concurrent async context, this is not thread-safe (though Python's GIL mostly protects single-threaded asyncio). More importantly, it's a code smell — configuration should be set once at startup.

**Fix:** Set `resend.api_key` once at application startup (e.g., in `main.py` lifespan) rather than on every call:

```python
# In main.py or a startup hook:
import resend
from src.infrastructure.config import get_settings

@app.on_event("startup")
async def configure_resend():
    resend.api_key = get_settings().resend_api_key
```

### WR-04: `request_code` Route Parses Body Twice (Schema Validation Bypass Risk)

**File:** `backend/src/features/auth/routes.py:58-64`
**Issue:** The route receives `_body: dict = Depends(body_parser)` which returns a raw dict (parsed from JSON, no validation), then on line 64 does `RequestCodePayload.model_validate(_body)` to validate. However, if the JSON body is malformed or the `email` field is invalid, the Pydantic validation error at line 64 will be raised as an unhandled `ValidationError` — FastAPI's default 422 handler will catch it, but the error shape will be FastAPI's default `{"detail": [...]}` rather than the canonical `{"error": {...}}`.

The standard FastAPI pattern (`payload: RequestCodePayload` as a route parameter) would handle this automatically with FastAPI's built-in validation. The current approach exists because `body_parser` is needed for the slowapi `email_key_func`, but the validation path is fragile.

**Fix:** Add explicit try/except around the Pydantic validation or add a global `RequestValidationError` handler:

```python
from fastapi.exceptions import RequestValidationError

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(
        status_code=422,
        content={"error": {"code": "VALIDATION_ERROR", "message": str(exc), "details": exc.errors()}},
    )
```

### WR-05: `verify_code` Return Type Annotation Mismatches Actual Returns

**File:** `backend/src/features/auth/routes.py:75`
**Issue:** The return type annotation is `TokenPair | JSONResponse` but the `response_model=TokenPair` on the decorator (line 71) tells FastAPI to serialize the response as `TokenPair`. When the function returns a `JSONResponse` (error cases), FastAPI passes it through directly (it detects Response subclasses). However, the OpenAPI schema generated will only show `TokenPair` as the response model, hiding the error responses from API documentation consumers. The same pattern applies to `refresh` which annotates `-> TokenPair` but can raise `HTTPException`.

**Fix:** This is a known FastAPI pattern. To improve API docs, add `responses` parameter to the decorator:

```python
@router.post(
    "/verify-code",
    response_model=TokenPair,
    status_code=200,
    responses={401: {"description": "Invalid or expired code"}},
)
```

## Info

### IN-01: Unused Import in jwt_service.py

**File:** `backend/src/features/auth/services/jwt_service.py:12`
**Issue:** `JWTError` is imported on line 12 (`from jose import jwt, JWTError  # noqa: F401`) but never used in this module. The `noqa: F401` comment suppresses the linting warning. `JWTError` is used by callers (`routes.py`, `shared/auth.py`) who import it from `jose` directly.

**Fix:** Remove the unused import or, if the intent was to re-export, document that explicitly:

```python
from jose import jwt  # JWTError imported by callers directly from jose
```

### IN-02: Inline Import in Routes.py `/auth/refresh`

**File:** `backend/src/features/auth/routes.py:179`
**Issue:** `from uuid import UUID as _UUID` is imported inside the `refresh()` function body rather than at module top. While not a bug, inline imports make the dependency graph harder to trace and slightly impact readability.

**Fix:** Move to top-level imports:

```python
from uuid import UUID  # at top of file, alongside other imports
```

### IN-03: `time` and `statistics` Imported But Unused in test_auth_enumeration.py

**File:** `backend/tests/integration/test_auth_enumeration.py:7-8`
**Issue:** `import time` and `import statistics` are imported but never used. These were likely remnants from a timing-based enumeration test that was replaced with code-path parity validation.

**Fix:** Remove unused imports:

```python
# Remove lines 7-8
```

### IN-04: `lru_cache` on `get_settings()` Prevents Runtime Config Reload

**File:** `backend/src/infrastructure/config.py:241-242`
**Issue:** `@lru_cache` on `get_settings()` means settings are frozen after first call. This is intentional for performance but means environment variable changes after startup have no effect. The `lru_cache` also has no `maxsize` parameter, defaulting to 128 entries — though since it takes no arguments, only one entry is ever cached.

This is informational — the pattern is correct for production. Tests that need fresh settings must call `Settings()` directly (as `test_settings.py` does) or clear the cache via `get_settings.cache_clear()`.

**Fix:** No change needed. Document the caching behavior for test authors:

```python
@lru_cache(maxsize=1)  # explicit maxsize for clarity
def get_settings() -> Settings:
    """Lazily load and cache validated application settings.
    
    Call get_settings.cache_clear() in tests that need fresh settings.
    """
    return Settings()
```

### IN-05: `_TEST_DATABASE_URL` Hardcoded as In-Memory SQLite

**File:** `backend/tests/conftest.py:59`
**Issue:** `_TEST_DATABASE_URL = "sqlite+aiosqlite://"` uses in-memory SQLite. This is fine for unit/integration tests but means features relying on PostgreSQL-specific behavior (JSONB, FOR UPDATE, array types, pgvector) cannot be tested. The code already acknowledges this with the `_SQLITE_SAFE_TABLES` filter. This is purely informational — the limitation is well-documented in the summaries.

**Fix:** No change needed for Phase 02. Consider adding a `conftest_pg.py` or CI-specific fixture for PostgreSQL-dependent tests in later phases.

---

_Reviewed: 2026-04-24T18:30:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
