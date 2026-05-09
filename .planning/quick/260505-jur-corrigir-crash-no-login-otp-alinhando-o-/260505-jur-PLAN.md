---
phase: quick-260505-jur
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - mobile/lib/core/models/auth_tokens.dart
  - mobile/lib/core/models/auth_tokens.g.dart
  - mobile/lib/core/models/user_model.dart
  - mobile/lib/core/models/user_model.g.dart
  - mobile/lib/features/auth/services/auth_service.dart
  - mobile/lib/features/auth/providers/auth_provider.dart
  - mobile/lib/core/network/auth_interceptor.dart
  - mobile/test/auth_tokens_test.dart
  - mobile/test/auth_login_flow_test.dart
autonomous: true
requirements:
  - QUICK-260505-jur
must_haves:
  truths:
    - "OTP verification no longer crashes when backend returns TokenPair: access_token, refresh_token, token_type, expires_in."
    - "Flutter stores access_token before calling /auth/me, so AuthInterceptor sends Authorization: Bearer {access_token}."
    - "Authenticated state is built from /auth/me user payload after token storage, not from the /auth/verify-code payload."
    - "Silent refresh reads access_token from /auth/refresh TokenPair response instead of the obsolete token field."
  artifacts:
    - path: "mobile/lib/core/models/auth_tokens.dart"
      provides: "TokenPair-aligned auth token model"
      contains: "accessToken"
    - path: "mobile/lib/features/auth/providers/auth_provider.dart"
      provides: "OTP verification flow that stores tokens then fetches /auth/me"
      contains: "getMe()"
    - path: "mobile/lib/core/network/auth_interceptor.dart"
      provides: "Bearer header and refresh-token rotation using backend TokenPair contract"
      contains: "access_token"
    - path: "mobile/test/auth_tokens_test.dart"
      provides: "Regression coverage for TokenPair JSON parsing"
    - path: "mobile/test/auth_login_flow_test.dart"
      provides: "Regression coverage for verify-code token storage before /auth/me"
  key_links:
    - from: "backend/src/features/auth/schemas.py TokenPair"
      to: "mobile/lib/core/models/auth_tokens.dart"
      via: "JsonKey mappings for access_token, refresh_token, token_type, expires_in"
      pattern: "access_token"
    - from: "mobile/lib/features/auth/providers/auth_provider.dart"
      to: "mobile/lib/features/auth/services/auth_service.dart getMe"
      via: "store access token before /auth/me"
      pattern: "storage.write.*access_token"
    - from: "mobile/lib/core/network/auth_interceptor.dart"
      to: "backend /auth/refresh TokenPair"
      via: "read access_token and refresh_token from refresh response"
      pattern: "data\['access_token'\]"
---

<objective>
Fix the Flutter OTP login crash by aligning the frontend auth response contract to the backend `TokenPair` returned by `POST /auth/verify-code` and `POST /auth/refresh`.

Purpose: Preserve the backend FastAPI contract and make the Flutter flow authenticate by saving tokens first, then calling `/auth/me` with the freshly stored access token.
Output: Updated Flutter auth token model, login provider flow, refresh interceptor behavior, generated JSON code, and focused regression tests.
</objective>

<execution_context>
@./desafio-fcg3/.opencode/get-shit-done/workflows/execute-plan.md
@./desafio-fcg3/.opencode/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@./AGENTS.md
@backend/src/features/auth/schemas.py
@backend/src/features/auth/routes.py
@mobile/lib/core/models/auth_tokens.dart
@mobile/lib/core/models/auth_tokens.g.dart
@mobile/lib/core/models/user_model.dart
@mobile/lib/features/auth/services/auth_service.dart
@mobile/lib/features/auth/providers/auth_provider.dart
@mobile/lib/core/network/auth_interceptor.dart

<interfaces>
Backend contract to preserve:

```python
class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
```

`POST /auth/verify-code` returns only `TokenPair`, not `{token, user, expires_at}`. `GET /auth/me` returns:

```python
class MeResponse(BaseModel):
    id: str
    email: EmailStr
    name: str
    role: str
```

Current frontend mismatch to fix:

- `AuthResponse` expects `token`, `user`, and `expires_at`, causing JSON parsing crash when backend returns `access_token`.
- `AuthProvider.verifyCode` uses `response.user`, but user data must come from `/auth/me` after storing `access_token`.
- `AuthInterceptor.onError` refresh path reads `data['token']`, but backend `/auth/refresh` returns `access_token`.
- `UserModel` currently maps role from JSON key `type`; `/auth/me` returns `role`, so align parsing without breaking existing consumers if practical.
  </interfaces>
  </context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Replace obsolete auth response shape with TokenPair model</name>
  <files>mobile/lib/core/models/auth_tokens.dart, mobile/lib/core/models/auth_tokens.g.dart, mobile/lib/core/models/user_model.dart, mobile/lib/core/models/user_model.g.dart, mobile/test/auth_tokens_test.dart</files>
  <behavior>
    - `TokenPair.fromJson({'access_token':'a','refresh_token':'r','token_type':'bearer','expires_in':900})` parses without requiring `user`, `token`, or `expires_at`.
    - `TokenPair.toJson()` emits backend snake_case keys: `access_token`, `refresh_token`, `token_type`, `expires_in`.
    - `UserModel.fromJson({'id':'1','name':'Ana','email':'ana@example.com','role':'student'})` sets `role == 'student'`; if existing app payloads still use `type`, preserve fallback support if feasible.
  </behavior>
  <action>Update `mobile/lib/core/models/auth_tokens.dart` so the verify/refresh response model represents backend `TokenPair`: fields `accessToken`, `refreshToken`, `tokenType`, `expiresIn` with `@JsonKey` mappings to `access_token`, `refresh_token`, `token_type`, `expires_in`. Keep the public class name `AuthResponse` only if minimizing call-site churn is cleaner, but remove `user`, `token`, and `expiresAt` requirements because they are not in the backend contract. Update `UserModel` JSON mapping so `/auth/me` key `role` populates the existing `role` field; do not change backend routes or schemas. Add focused model tests, then regenerate `.g.dart` files with build_runner rather than hand-editing generated code.</action>
  <verify>
    <automated>cd mobile; dart run build_runner build --delete-conflicting-outputs</automated>
    <automated>cd mobile; flutter test test/auth_tokens_test.dart</automated>
  </verify>
  <done>Frontend token parsing matches backend `TokenPair`, `/auth/me` user parsing handles `role`, generated serializers are current, and model regression tests pass.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Store tokens before fetching authenticated user</name>
  <files>mobile/lib/features/auth/services/auth_service.dart, mobile/lib/features/auth/providers/auth_provider.dart, mobile/test/auth_login_flow_test.dart</files>
  <behavior>
    - `AuthService.verifyCode` posts only the backend-supported OTP payload (`email`, `code`) and returns the TokenPair/AuthResponse model.
    - On successful verify-code, `AuthProvider.verifyCode` writes `access_token` and `refresh_token` to `flutter_secure_storage` before invoking `getMe()`.
    - After `getMe()` succeeds, state becomes `AuthAuthenticated(user: fetchedUser)`; no code reads user data from the verify-code response.
    - If `/auth/me` fails after token storage, provider clears both tokens and returns a non-success result/state instead of leaving a half-authenticated session.
  </behavior>
  <action>Change `AuthService.verifyCode` documentation and parsing to reflect `TokenPair` from `/auth/verify-code`; remove the unsupported `platform` request field unless another existing backend endpoint accepts it. In `AuthProvider.verifyCode`, write `_accessTokenKey` from `response.accessToken` and `_refreshTokenKey` from `response.refreshToken`, then call `_authService.getMe()` and set `AuthAuthenticated` from that returned `UserModel`. Preserve current 401/429 user-facing error behavior. Add a provider/service test with fakes or mocks proving storage happens before `/auth/me` and that no `response.user` access remains.</action>
  <verify>
    <automated>cd mobile; flutter test test/auth_login_flow_test.dart</automated>
    <automated>cd mobile; flutter analyze</automated>
  </verify>
  <done>OTP login succeeds against backend TokenPair, authenticated user comes from `/auth/me`, tokens are stored securely before the profile request, and analyzer reports no stale `token/user/expiresAt` references.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 3: Align silent refresh with backend TokenPair keys</name>
  <files>mobile/lib/core/network/auth_interceptor.dart, mobile/test/auth_login_flow_test.dart</files>
  <behavior>
    - Refresh success reads `access_token` and `refresh_token` from `/auth/refresh` response.
    - The retried request uses `Authorization: Bearer {newAccessToken}` where `{newAccessToken}` is the refreshed `access_token` value.
    - If refresh response is malformed or missing either token, interceptor does not retry with null/old tokens and lets the original 401 propagate after clearing tokens where appropriate.
  </behavior>
  <action>Update `AuthInterceptor.onError` to read `data['access_token']` instead of `data['token']`, keeping `refresh_token` unchanged. Keep the separate refresh Dio to avoid interceptor loops and keep `QueuedInterceptor` serialization. Add or extend tests to cover refresh response parsing with backend TokenPair keys and guard against regression to the obsolete `token` key.</action>
  <verify>
    <automated>cd mobile; flutter test test/auth_login_flow_test.dart</automated>
    <automated>cd mobile; flutter test</automated>
  </verify>
  <done>Refresh rotation remains functional with backend `TokenPair`, retry Authorization header uses the new access token, and the full Flutter test suite passes.</done>
</task>

</tasks>

<threat_model>

## Trust Boundaries

| Boundary                                  | Description                                                                                            |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| Flutter app → FastAPI auth API            | Untrusted OTP/login inputs cross from client to backend; this plan does not change backend validation. |
| FastAPI auth API → Flutter secure storage | JWT access/refresh tokens cross into client-side secure storage.                                       |

## STRIDE Threat Register

| Threat ID       | Category | Component                             | Disposition | Mitigation Plan                                                                                                                                          |
| --------------- | -------- | ------------------------------------- | ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| T-260505-jur-01 | I        | `auth_provider.dart` token storage    | mitigate    | Store only in `flutter_secure_storage` using existing `_accessTokenKey`/`_refreshTokenKey`; do not introduce SharedPreferences or logs for tokens.       |
| T-260505-jur-02 | S        | `auth_interceptor.dart` refresh retry | mitigate    | Use backend `access_token` from validated refresh response before retrying; reject malformed refresh payloads instead of retrying with stale/null token. |
| T-260505-jur-03 | T        | Backend auth response contract        | mitigate    | Preserve backend `TokenPair` contract; only adapt Flutter parsing to prevent client-side contract drift.                                                 |

</threat_model>

<verification>
Run all automated checks from the tasks in order:

```powershell
cd mobile; dart run build_runner build --delete-conflicting-outputs
cd mobile; flutter test test/auth_tokens_test.dart
cd mobile; flutter test test/auth_login_flow_test.dart
cd mobile; flutter analyze
cd mobile; flutter test
```

Manual smoke check after automated tests: run the app against the existing backend, request an OTP, submit the valid code, confirm no JSON cast/crash occurs, and confirm authenticated routing uses the user returned by `/auth/me`.
</verification>

<success_criteria>

- No backend source files are modified for this quick fix.
- Flutter `verify-code` parsing accepts the backend `TokenPair` shape exactly.
- Access token is saved before `/auth/me`, enabling `AuthInterceptor` to attach `Authorization: Bearer ...`.
- Auth state uses `/auth/me` user payload and no longer expects user data inside verify-code response.
- Refresh interceptor uses `access_token` from `/auth/refresh`.
- Focused regression tests plus `flutter analyze` and `flutter test` pass.
  </success_criteria>

<output>
After completion, create `.planning/quick/260505-jur-corrigir-crash-no-login-otp-alinhando-o-/260505-jur-SUMMARY.md`.
</output>
