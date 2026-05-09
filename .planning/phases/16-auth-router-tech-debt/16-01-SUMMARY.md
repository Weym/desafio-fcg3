---
plan: 16-01
phase: 16-auth-router-tech-debt
status: complete
type: verification
started: 2026-05-07
completed: 2026-05-07
---

# Summary: Verify Auth & Router Tech Debt Fixes

## Objective

Confirm that all 4 M2 audit tech debt items (CR-01, CR-02, CR-03, debugLogDiagnostics) are already correctly implemented in the codebase.

## Result

All 4 fixes verified as **already applied** — no code changes needed.

## Verification Details

### CR-01: Auth Interceptor onRequest (async void fix)

- `auth_interceptor.dart` line 7: `class AuthInterceptor extends QueuedInterceptor`
- `auth_interceptor.dart` line 21: `Future<void> onRequest(...)  async`
- `auth_interceptor.dart` line 23: `await _storage.read(key: _accessTokenKey)` before `handler.next`
- No fire-and-forget pattern — token is attached before request proceeds

### CR-02: Auth Interceptor onError (async void fix)

- `auth_interceptor.dart` line 31: `Future<void> onError(...) async`
- All operations properly awaited: refresh token read (L36), post refresh (L39), storage writes (L55-56), retry fetch (L63)
- QueuedInterceptor serializes concurrent 401 handling

### CR-03: Router GlobalKey removal

- `app_router.dart` line 33-34: `@riverpod GoRouter appRouter(Ref ref)`
- No module-level `GlobalKey<NavigatorState>` (0 matches confirmed by grep)
- Uses `ValueNotifier<AuthState>` + `ref.listen` + `refreshListenable` pattern
- Prevents router recreation crashes on auth state changes

### debugLogDiagnostics guard

- `app_router.dart` line 46: `debugLogDiagnostics: kDebugMode`
- `app_router.dart` line 1: `import 'package:flutter/foundation.dart'`
- Debug route logging only appears in debug builds

## Test Suite

- **236 tests passing** (out of 244 total)
- **8 pre-existing failures**: All in `staff_dashboard_screen_test.dart` — RenderFlex overflow in `_KpiCard` widget (layout issue unrelated to auth/router)
- No regressions introduced

## Key Files

### key-files.verified

- `mobile/lib/core/network/auth_interceptor.dart` — QueuedInterceptor with proper async handlers
- `mobile/lib/core/router/app_router.dart` — Riverpod-managed GoRouter without GlobalKey

## Deviations

None — all fixes were already applied as expected from code review.

## Self-Check: PASSED
