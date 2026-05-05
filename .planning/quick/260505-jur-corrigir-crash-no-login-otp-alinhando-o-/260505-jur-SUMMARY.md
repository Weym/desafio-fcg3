---
phase: quick-260505-jur
plan: 01
subsystem: auth
tags: [flutter, jwt, otp, dio, json-serializable, secure-storage]
requires:
  - phase: quick-260505-jcm
    provides: Auth API base URL and CORS alignment for Flutter clients
provides:
  - Flutter auth response parsing aligned to backend TokenPair
  - OTP verification flow that stores tokens before fetching /auth/me
  - Silent refresh retry logic using access_token from /auth/refresh
affects: [flutter-auth, mobile-login, auth-refresh]
tech-stack:
  added: []
  patterns:
    - TokenPair JSON mapping with backend snake_case keys
    - Provider authentication state built from /auth/me after secure token storage
key-files:
  created:
    - mobile/test/auth_tokens_test.dart
    - mobile/test/auth_login_flow_test.dart
  modified:
    - mobile/lib/core/models/auth_tokens.dart
    - mobile/lib/core/models/auth_tokens.g.dart
    - mobile/lib/core/models/user_model.dart
    - mobile/lib/core/models/user_model.g.dart
    - mobile/lib/features/auth/services/auth_service.dart
    - mobile/lib/features/auth/providers/auth_provider.dart
    - mobile/lib/core/network/auth_interceptor.dart
key-decisions:
  - "Kept AuthResponse as the public frontend class name to minimize call-site churn while changing its shape to backend TokenPair."
  - "Authenticated Flutter state is now sourced from /auth/me, never from the verify-code token payload."
requirements-completed: [QUICK-260505-jur]
duration: 7min
completed: 2026-05-05
---

# Quick Task 260505-jur: Corrigir crash no login OTP Summary

**Flutter OTP login now consumes backend TokenPair responses, stores access/refresh tokens before `/auth/me`, and refreshes sessions from `access_token`.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-05-05T17:21:07Z
- **Completed:** 2026-05-05T17:28:19Z
- **Tasks:** 3 completed
- **Files modified:** 9 code/test files

## Accomplishments

- Replaced the obsolete `token/user/expires_at` frontend auth response expectation with backend `access_token/refresh_token/token_type/expires_in` parsing.
- Updated OTP verification to store tokens in `flutter_secure_storage` before fetching `/auth/me`, then build authenticated state from that user profile.
- Updated silent refresh to read `access_token` and reject malformed or legacy `token`-only refresh payloads.
- Added regression tests for TokenPair parsing, `/auth/me` role parsing, token-storage ordering, cleanup on profile fetch failure, and refresh retry headers.

## Task Commits

1. **Task 1 RED:** `13832cf` test(quick-260505-jur): add failing TokenPair auth model regression tests
2. **Task 1 GREEN:** `b3eeca7` feat(quick-260505-jur): align auth token models with TokenPair
3. **Task 2/3 RED:** `02be06e` test(quick-260505-jur): add failing auth login and refresh regressions
4. **Task 2 GREEN:** `92c4da0` feat(quick-260505-jur): store TokenPair before fetching auth user
5. **Task 3 GREEN:** `687f418` fix(quick-260505-jur): read access_token during silent refresh
6. **Test alignment:** `5fee628` test(quick-260505-jur): align auth flow regression fakes with OTP payload

_Note: TDD tasks produced separate RED/GREEN commits._

## Files Created/Modified

- `mobile/lib/core/models/auth_tokens.dart` - AuthResponse now maps backend TokenPair fields.
- `mobile/lib/core/models/auth_tokens.g.dart` - Regenerated JSON serialization for TokenPair keys.
- `mobile/lib/core/models/user_model.dart` - Reads role from `/auth/me` `role` key with legacy `type` fallback.
- `mobile/lib/core/models/user_model.g.dart` - Regenerated user serializer/deserializer.
- `mobile/lib/features/auth/services/auth_service.dart` - Sends backend-supported verify-code payload and documents TokenPair return.
- `mobile/lib/features/auth/providers/auth_provider.dart` - Stores tokens, fetches `/auth/me`, clears half-auth sessions on profile failure.
- `mobile/lib/core/network/auth_interceptor.dart` - Reads `access_token` from refresh response before retrying.
- `mobile/test/auth_tokens_test.dart` - Model regression coverage for TokenPair and role parsing.
- `mobile/test/auth_login_flow_test.dart` - Provider and interceptor regression coverage.

## Decisions Made

- Kept `AuthResponse` class name to avoid unnecessary call-site churn while aligning its fields to the backend `TokenPair` contract.
- Removed the unsupported `platform` field from `/auth/verify-code` requests to preserve the backend FastAPI contract.
- Treated `/auth/me` failure after token storage as an unsafe half-session and cleared both secure-storage token keys.

## Deviations from Plan

None - plan executed as written. Generated files outside the auth model scope were produced by `build_runner` during verification and restored before completion.

## Known Stubs

None in files created or modified by this quick task.

## Threat Flags

None - no new network endpoints, auth paths beyond planned Flutter client calls, file access patterns, or schema changes were introduced.

## Verification

- `git merge-base HEAD 735d278a4708f2d0cf10fa7f5c37c5668ea1864d` — passed, worktree based on required commit.
- `cd mobile; flutter test test/auth_tokens_test.dart` — passed.
- `cd mobile; flutter test test/auth_login_flow_test.dart --plain-name "AuthProvider verify-code flow"` — passed during Task 2.
- `cd mobile; flutter test test/auth_login_flow_test.dart` — passed.
- `cd mobile; dart run build_runner build --delete-conflicting-outputs` — passed; unrelated generated outputs were restored.
- `cd mobile; flutter analyze` — failed due pre-existing out-of-scope issues: `lib/core/router/app_router.dart` unnecessary import and `test/widget_test.dart` references missing `MyApp`.
- `cd mobile; flutter test` — auth tests passed, suite failed due pre-existing `test/widget_test.dart` missing `MyApp` constructor.

## Test Limitations

- Manual smoke check against a running backend/OTP email flow was not performed in this execution environment.
- Full suite/analyzer remain blocked by pre-existing unrelated Flutter scaffold issues in `test/widget_test.dart` and `app_router.dart`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Flutter login and refresh flows are ready to exercise against the existing backend TokenPair contract.
- Recommended follow-up: clean or remove stale `test/widget_test.dart` so full `flutter test` and `flutter analyze` can be used as reliable gates.

## Self-Check: PASSED

- Verified all created/modified files listed in this summary exist.
- Verified all task commit hashes are present in git history.

---
*Phase: quick-260505-jur*
*Completed: 2026-05-05*
