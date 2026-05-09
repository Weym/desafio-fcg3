---
phase: 07-flutter-scaffold-auth
plan: 02
subsystem: mobile-auth
tags: [riverpod, providers, login-screen, otp, flutter]
dependency_graph:
  requires:
    - 07-01 (auth_service, dio_client, models)
  provides:
    - auth_provider (AuthState management, token persistence)
    - login_screen (LoginScreen widget)
    - storage_provider (FlutterSecureStorage)
    - dio_provider (DioClient + AuthService providers)
  affects:
    - 07-03 (navigation guards consume authProvider)
tech_stack:
  added: []
  patterns:
    - "Riverpod code generation (@riverpod + build_runner)"
    - "Sealed class for state (AuthState hierarchy)"
    - "ConsumerStatefulWidget for stateful Riverpod screens"
    - "AnimatedSwitcher for multi-step flow transitions"
key_files:
  created:
    - mobile/lib/core/providers/storage_provider.dart
    - mobile/lib/core/providers/storage_provider.g.dart
    - mobile/lib/core/providers/dio_provider.dart
    - mobile/lib/core/providers/dio_provider.g.dart
    - mobile/lib/features/auth/providers/auth_state.dart
    - mobile/lib/features/auth/providers/auth_provider.dart
    - mobile/lib/features/auth/providers/auth_provider.g.dart
    - mobile/lib/features/auth/screens/login_screen.dart
  modified: []
decisions:
  - "Used sealed class (not freezed) for AuthState — lightweight, no extra codegen"
  - "Simplified requestCode error handling — caller shows generic snackbar on null return"
  - "Removed unused flutter_riverpod import in auth_provider (riverpod_annotation re-exports Ref)"
metrics:
  duration: "3m 23s"
  completed: "2026-05-04T16:33:58Z"
---

# Phase 07 Plan 02: Auth Providers & Login Screen Summary

Riverpod providers for auth state management with token persistence in FlutterSecureStorage, plus a single-screen two-step login UI (email → OTP) with AnimatedSwitcher, error snackbars, and 60s resend countdown.

## Completed Tasks

| # | Task | Commit | Key Files |
|---|------|--------|-----------|
| 1 | Core providers and auth state model | `29b7a84` | storage_provider.dart, dio_provider.dart, auth_state.dart, auth_provider.dart + .g.dart files |
| 2 | Login screen with two-step OTP flow | `383b99b` | login_screen.dart |

## Implementation Details

### Task 1: Providers & State

- **storage_provider.dart**: `@Riverpod(keepAlive: true)` FlutterSecureStorage with Android encrypted prefs + iOS keychain
- **dio_provider.dart**: DioClient and AuthService providers, both keepAlive for app lifecycle
- **auth_state.dart**: Sealed class hierarchy — AuthInitial, AuthLoading, AuthAuthenticated, AuthUnauthenticated, AuthError (with attemptsRemaining)
- **auth_provider.dart**: `Auth` notifier with:
  - `checkAuthStatus()` — startup token validation via GET /auth/me
  - `requestCode(email)` — OTP request, returns message on success
  - `verifyCode(email, code)` — handles 401 (invalid code + attempts parsing), 429 (max attempts), network errors
  - `logout()` — API call + local token cleanup

### Task 2: Login Screen

- Single screen, two-step flow with AnimatedSwitcher (300ms transition)
- Step 1: Email form with validation (required + @ check)
- Step 2: 6-digit numeric TextField (FilteringTextInputFormatter.digitsOnly)
- Error snackbars: "Codigo invalido (N tentativas restantes)", "Tentativas esgotadas — novo codigo enviado"
- Resend button disabled for 60s with visible countdown
- Loading indicator on buttons during async operations
- Back button in OTP step returns to email step

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed unused import and variable warnings**

- **Found during:** Task 1 verification
- **Issue:** `flutter_riverpod` import unnecessary (riverpod_annotation re-exports needed types); `UserModel` import unused (used via auth_state.dart); unused local variable `error` in catch block
- **Fix:** Removed redundant import, removed unused UserModel import, simplified catch block to `catch (_)`
- **Files modified:** mobile/lib/features/auth/providers/auth_provider.dart
- **Commit:** `29b7a84` (included in task commit)

## Verification Results

```
flutter analyze lib/ → No issues found!
build_runner build → 10 outputs generated successfully
Generated files: storage_provider.g.dart, dio_provider.g.dart, auth_provider.g.dart
```

## Self-Check: PASSED

All 8 created files verified on disk. Both commit hashes (29b7a84, 383b99b) confirmed in git log.
