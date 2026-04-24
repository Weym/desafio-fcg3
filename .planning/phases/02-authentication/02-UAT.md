---
status: complete
phase: 02-authentication
source: [02-01-SUMMARY.md, 02-02-SUMMARY.md, 02-03-SUMMARY.md, 02-04-SUMMARY.md]
started: 2026-04-24T19:57:21Z
updated: 2026-04-24T19:59:47Z
---

## Current Test

[testing complete]

## Tests

### 1. Cold Start Smoke Test

expected: Kill any running server. Run `python -m pytest tests/unit tests/integration -x -q` from backend/. All 47 tests pass green with no import errors, no missing env var crashes, and no fixture failures.
result: pass

### 2. POST /auth/request-code — Happy Path

expected: Send `POST /auth/request-code` with `{"email": "weydsonmarinho@gmail.com"}` (registered student). Returns 200 with `{"message": "Codigo enviado", "expires_in": 300}`. A `verification_codes` row is created in the DB with `code_hash` and `code_salt` (no plaintext code stored).
result: pass

### 3. POST /auth/request-code — Enumeration Protection (D-08)

expected: Send `POST /auth/request-code` with a non-registered email. Returns the exact same 200 response body as a registered email (`{"message": "Codigo enviado", "expires_in": 300}`). An attacker cannot distinguish registered from unregistered emails by response content.
result: pass

### 4. POST /auth/request-code — Rate Limiting (D-13)

expected: Send 6 rapid requests with the same email. First 5 return 200. The 6th returns 429 with `{"error": {"code": "RATE_LIMITED", ...}}`.
result: pass

### 5. POST /auth/verify-code — Happy Path + JWT Claims

expected: Send `POST /auth/verify-code` with a valid email and correct OTP code. Returns 200 with `{"access_token": "...", "refresh_token": "..."}`. Decoding the access JWT reveals: `sub` (UUID), `role` ("student" or "staff"), `jti` (unique), `name`, `email`, `exp`, `iat`.
result: pass

### 6. POST /auth/verify-code — 3-Strike Auto-Invalidation (AUTH-03)

expected: Submit 3 wrong codes for the same OTP. The code is invalidated. A new code is automatically generated and sent. Subsequent attempts use the new code.
result: pass

### 7. GET /auth/me — Claims-Based Profile

expected: Call `GET /auth/me` with `Authorization: Bearer {access_token}`. Returns 200 with `{"id": "...", "role": "...", "email": "...", "name": "..."}` extracted from JWT claims (no DB query).
result: pass

### 8. GET /auth/me — Unauthenticated Rejection

expected: Call `GET /auth/me` without any Authorization header. Returns 401 with canonical error shape `{"error": {"code": "...", "message": "..."}}`.
result: pass

### 9. POST /auth/logout — Session Revocation (D-11)

expected: Call `POST /auth/logout` with a valid access token. Returns 200. Subsequent requests with the same access token return 401. Other sessions (if any) remain valid.
result: pass

### 10. POST /auth/refresh — Token Rotation (D-03)

expected: Call `POST /auth/refresh` with `{"refresh_token": "..."}`. Returns 200 with new `{access_token, refresh_token}` pair. The old refresh token is invalidated — re-using it returns 401 (replay detection).
result: pass

### 11. Auth Guards — Role Enforcement

expected: A student calling a staff-only guarded endpoint gets 403 `{"error": {"code": "FORBIDDEN", ...}}`. A staff user with correct role gets 200.
result: pass

### 12. Service Token — MCP Internal Auth

expected: Calling an endpoint guarded by `require_service_token` with a valid `X-Service-Token` header returns 200. Missing or wrong token returns 401.
result: pass

## Summary

total: 12
passed: 12
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

[none]
