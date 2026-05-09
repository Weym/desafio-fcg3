# Phase 2: Authentication - Context

**Gathered:** 2026-04-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver email OTP authentication, JWT issuance with roles (student | staff), refresh token mechanism, session revocation, and the auth middleware (JWT Bearer + X-Service-Token) that all downstream phases depend on. Endpoints: `POST /auth/request-code`, `POST /auth/verify-code`, `POST /auth/refresh`, `POST /auth/logout`, `GET /auth/me`.

</domain>

<decisions>
## Implementation Decisions

### JWT Token Lifetime & Refresh
- **D-01:** Access token expires in 1 hour. Refresh token expires in 30 days.
- **D-02:** Refresh token with silent renewal — app renovates automatically via `POST /auth/refresh` without user interaction.
- **D-03:** Refresh token rotation on every use — each refresh issues a new refresh token and invalidates the old one. Stolen refresh tokens work at most once.
- **D-04:** Signing algorithm: HS256 with a single `JWT_SECRET` environment variable. Symmetric signing is sufficient since only the FastAPI backend validates tokens.

### JWT Payload Contents
- **D-05:** Enriched JWT payload: `sub` (user_id UUID), `role` (student | staff), `jti` (unique token ID), `name`, `email`, `exp`, `iat`. The `/auth/me` endpoint can return basic data directly from the token without a database query.
- **D-06:** `sub` field contains the user_id UUID directly (not a composite like `student:uuid`).

### User Registration Flow
- **D-07:** Only emails already registered in `students` or `staff` tables can request an OTP. Staff must create the student record first (STU-02) before the student can authenticate.
- **D-08:** Generic response for unregistered emails — the endpoint responds "Codigo enviado" regardless of whether the email exists, to prevent user enumeration attacks.
- **D-09:** User lookup queries both `students` and `staff` tables by email. The `role` in the JWT is determined by which table the user was found in.

### Multi-Session Policy
- **D-10:** Multiple simultaneous sessions are allowed. A user can be logged in on the app and WhatsApp at the same time — sessions on different platforms coexist.
- **D-11:** `POST /auth/logout` revokes only the current session (by the `jti` in the token sent). Other active sessions remain valid.

### Rate Limiting on OTP
- **D-12:** In-memory rate limiting (e.g., slowapi). No Redis in MVP. Rate limit state resets if the container restarts — acceptable for MVP.
- **D-13:** Limit per email: 5 requests per 15-minute window.
- **D-14:** Limit per IP: 20 requests per 15-minute window. Combined with per-email limit, prevents both targeted abuse and broad enumeration attempts.

### Refresh Token Storage
- **D-15:** Refresh tokens stored in the same `sessions` table, adding a `token_type` column (access | refresh) or a `refresh_jti` field alongside the existing `jti`. Each login creates entries for both access and refresh tokens.
- **D-16:** `POST /auth/refresh` is a dedicated endpoint. Receives the refresh token in the request body, validates it, rotates it (invalidates old, issues new), and returns a fresh access token + new refresh token.

### Agent's Discretion
- OTP code generation approach (random vs cryptographic) and whether codes are stored hashed or plaintext — agent decides based on security best practices for 6-digit short-lived codes.
- Exact slowapi configuration and cache backend choice for rate limiting.
- Whether `POST /auth/refresh` uses the refresh token in the body, a cookie, or a header.
- SMS channel support — `docs/api.md` shows `channel: email | sms` but requirements only specify email via Resend. Agent may implement email-only and leave SMS as a stub for future.
- X-Service-Token middleware implementation details (separate middleware vs FastAPI dependency).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Auth API Contract
- `docs/api.md` -- Auth endpoint specifications (POST /auth/request-code, POST /auth/verify-code, POST /auth/logout, GET /auth/me). Request/response shapes, error codes (INVALID_CODE, MAX_ATTEMPTS_REACHED), HTTP status mappings. Note: POST /auth/refresh is a new endpoint not yet in this doc -- implement following the same patterns.

### Database Schema (Auth Tables)
- `docs/database.md` -- Authoritative schema for `students`, `staff`, `verification_codes`, `sessions`, `fcm_tokens` tables. The `sessions` table will need extension for refresh token support (D-15).

### Architecture & Service Communication
- `docs/architecture.md` -- C4 diagrams, Docker topology, async patterns. Auth middleware serves both JWT Bearer (external) and X-Service-Token (internal MCP calls).

### MCP Service Token Pattern
- `docs/mcp.md` -- X-Service-Token validation pattern (constant-time comparison via `hmac.compare_digest`), middleware code snippet. Phase 2 must implement this middleware so MCP endpoints in Phase 3+ can use it.

### Phase 1 Context (dependency)
- `.planning/phases/01-infrastructure-schema/01-CONTEXT.md` -- D-09: Migration #002 creates auth tables. D-11: Models organized per-feature in `features/auth/models.py`. D-01: Seed includes sample students and staff for testing auth.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- No existing Python code to reuse — all backend directories contain only `.gitkeep` scaffolding (confirmed in Phase 1 context).
- `backend/src/features/auth/` directory already scaffolded — ready for implementation.
- `backend/src/shared/` directory scaffolded — middleware and dependencies go here.
- `backend/src/infrastructure/` scaffolded — settings and DB session factory go here.

### Established Patterns
- Vertical slice architecture: auth feature owns `controllers/`, `services/`, `routes.py` under `backend/src/features/auth/`.
- SQLAlchemy ORM models as single source of truth for schema (D-10 from Phase 1).
- Settings accessed via a `settings` object (Pydantic BaseSettings) — never inline `os.getenv()`.
- Async-first: all FastAPI route handlers must be `async def`.
- Error response shape: `{"error": {"code": "...", "message": "...", "details": [...]}}`.

### Integration Points
- `backend/src/main.py` — FastAPI app entry point where auth routes and middleware are registered.
- `backend/src/infrastructure/` — DB session factory (async SQLAlchemy with asyncpg) and settings config.
- `backend/src/shared/` — Auth middleware (`get_current_user`, `require_role`) used by all downstream feature slices in Phase 3+.
- Migration #002 (auth tables) from Phase 1 provides the database schema this phase builds on.

</code_context>

<specifics>
## Specific Ideas

- Generic response for unregistered emails is a security best practice — prevents attackers from discovering which emails are in the system.
- Refresh token rotation follows the OAuth 2.0 security best practice for mobile/SPA clients — each refresh invalidates the previous token, limiting the damage window of a stolen token.
- The sessions table extension for refresh tokens should be minimal — avoid a full redesign of the Phase 1 schema. A `token_type` or `refresh_jti` column addition is preferred over a new table.

</specifics>

<deferred>
## Deferred Ideas

- SMS OTP channel — `docs/api.md` lists `channel: sms` but no SMS provider is specified in requirements. Consider adding Twilio/equivalent in a future phase if needed.
- `POST /auth/logout-all` (revoke all user sessions globally) — not needed for MVP, could be added later.
- Redis-backed rate limiting for multi-instance deployments — deferred per PROJECT.md (Redis is post-MVP).

</deferred>

---

*Phase: 02-authentication*
*Context gathered: 2026-04-20*
