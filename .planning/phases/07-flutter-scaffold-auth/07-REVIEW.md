---
phase: 07
reviewed: 2026-05-04T12:00:00Z
depth: standard
files_reviewed: 22
files_reviewed_list:
  - mobile/lib/core/config/env_config.dart
  - mobile/lib/core/theme/app_theme.dart
  - mobile/lib/core/theme/app_colors.dart
  - mobile/lib/core/network/dio_client.dart
  - mobile/lib/core/network/api_interceptor.dart
  - mobile/lib/core/network/auth_interceptor.dart
  - mobile/lib/core/models/user_model.dart
  - mobile/lib/core/models/auth_tokens.dart
  - mobile/lib/core/providers/storage_provider.dart
  - mobile/lib/core/providers/dio_provider.dart
  - mobile/lib/core/router/app_router.dart
  - mobile/lib/core/router/route_names.dart
  - mobile/lib/features/auth/services/auth_service.dart
  - mobile/lib/features/auth/providers/auth_state.dart
  - mobile/lib/features/auth/providers/auth_provider.dart
  - mobile/lib/features/auth/screens/login_screen.dart
  - mobile/lib/features/splash/screens/splash_screen.dart
  - mobile/lib/features/client/screens/client_shell.dart
  - mobile/lib/features/client/screens/client_home_screen.dart
  - mobile/lib/features/staff/screens/staff_shell.dart
  - mobile/lib/features/staff/screens/staff_home_screen.dart
  - mobile/lib/main.dart
findings:
  critical: 3
  warning: 4
  info: 2
  total: 9
status: issues_found
severity_high: 3
severity_medium: 4
severity_low: 2
findings_count: 9
---

# Phase 07: Code Review Report

**Reviewed:** 2026-05-04T12:00:00Z
**Depth:** standard
**Files Reviewed:** 22
**Status:** issues_found

## Summary

Phase 07 implements the Flutter scaffold with OTP-based auth, Riverpod state management, GoRouter navigation, and Dio networking. The overall architecture is well-structured with proper sealed auth states, secure token storage via `flutter_secure_storage`, and role-based route guards.

However, the review identified **3 critical bugs** in the auth interceptor and router that will cause runtime failures, **4 warnings** around fragile error parsing and router rebuild behavior, and **2 informational** items about architecture and debug flags.

The most urgent issue is the `void`-declared async interceptor methods in `auth_interceptor.dart` — these cause the auth token to never be attached to requests, completely breaking authenticated API calls.

## Critical Issues

### CR-01: AuthInterceptor `onRequest` is `void` but uses `async` — token never attached

**File:** `mobile/lib/core/network/auth_interceptor.dart:18-24`
**Issue:** The `onRequest` method is declared as `void` but performs `async` operations (line 20: `await _storage.read(...)`). In Dio interceptors, when a `void` method contains `await`, the `handler.next(options)` on line 24 executes **synchronously before** the `await` completes. This means the token is never attached to the `Authorization` header — every authenticated request will be sent without a token.

This is a known Dio interceptor pitfall. The method signature must not be `void` if it uses `await`, because Dart treats the `async` annotation on a `void` method as fire-and-forget.

**Fix:**
```dart
@override
Future<void> onRequest(
    RequestOptions options, RequestInterceptorHandler handler) async {
  final token = await _storage.read(key: _accessTokenKey);
  if (token != null) {
    options.headers['Authorization'] = 'Bearer $token';
  }
  handler.next(options);
}
```

Alternatively, use Dio's `QueuedInterceptor` instead of `Interceptor`, which properly serializes async operations:

```dart
class AuthInterceptor extends QueuedInterceptor {
  // ... same code, but QueuedInterceptor handles async correctly
}
```

### CR-02: AuthInterceptor `onError` is `void` but uses `async` — race condition on token refresh

**File:** `mobile/lib/core/network/auth_interceptor.dart:28-59`
**Issue:** Same root cause as CR-01. The `onError` method is `void` but uses `async` operations (storage reads, refresh API call, retry). The `handler.next(err)` on line 59 fires immediately (synchronously), propagating the original 401 error to the caller. Meanwhile, the refresh logic runs in the background as a detached future. This causes:

1. The caller receives the 401 error immediately (refresh is useless).
2. If the refresh succeeds, the retry response has no receiver — it's lost.
3. If the refresh fails, tokens are silently deleted while the app may still think it has valid auth state.
4. Concurrent 401 responses could trigger multiple simultaneous refresh attempts, causing token rotation conflicts.

**Fix:**
```dart
@override
Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
  if (err.response?.statusCode == 401 &&
      !err.requestOptions.extra.containsKey('isRetry')) {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken != null) {
      try {
        final response = await _dio.post(
          '/auth/refresh',
          data: {'refresh_token': refreshToken},
        );
        final newAccessToken = response.data['token'] as String?;
        final newRefreshToken = response.data['refresh_token'] as String?;
        if (newAccessToken == null || newRefreshToken == null) {
          return handler.next(err);
        }

        await _storage.write(key: _accessTokenKey, value: newAccessToken);
        await _storage.write(key: _refreshTokenKey, value: newRefreshToken);

        final options = err.requestOptions;
        options.headers['Authorization'] = 'Bearer $newAccessToken';
        options.extra['isRetry'] = true;

        final retryResponse = await _dio.fetch(options);
        return handler.resolve(retryResponse);
      } catch (_) {
        await _storage.delete(key: _accessTokenKey);
        await _storage.delete(key: _refreshTokenKey);
      }
    }
  }
  handler.next(err);
}
```

And switch to `QueuedInterceptor` to serialize concurrent refresh attempts:

```dart
class AuthInterceptor extends QueuedInterceptor {
```

### CR-03: GoRouter recreated on every auth state change — GlobalKey reuse causes assertion error

**File:** `mobile/lib/core/router/app_router.dart:17-19, 22-23`
**Issue:** Lines 17-19 declare `GlobalKey<NavigatorState>` instances at module level (outside the provider). On line 23, `ref.watch(authProvider)` causes the `appRouterProvider` to rebuild every time auth state changes. Each rebuild creates a new `GoRouter` instance, but the three `GlobalKey` objects are shared across all instances. Flutter enforces that a `GlobalKey` can only be used by one widget at a time — reusing it in a new router while the old one hasn't been fully disposed causes:

- In debug: `"Multiple widgets used the same GlobalKey"` assertion failure (red screen).
- In release: Undefined behavior, potential navigation crashes.

This will trigger on every login/logout cycle (any auth state transition).

**Fix:** Move the `GlobalKey` instances inside the provider so they are recreated with each `GoRouter`, or better yet, avoid recreating the router entirely by using `ref.listen` with `GoRouter.refreshListenable`:

```dart
@riverpod
GoRouter appRouter(Ref ref) {
  // Create a listenable that fires when auth state changes
  final authNotifier = ValueNotifier<AuthState>(ref.read(authProvider));
  ref.listen(authProvider, (_, next) {
    authNotifier.value = next;
  });
  ref.onDispose(() => authNotifier.dispose());

  return GoRouter(
    refreshListenable: authNotifier,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) {
      final authState = authNotifier.value;
      // ... same redirect logic using authState
    },
    routes: [
      // ... same routes
    ],
  );
}
```

This avoids recreating GoRouter and eliminates the GlobalKey reuse problem entirely.

## Warnings

### WR-01: Unchecked type cast on refresh response data

**File:** `mobile/lib/core/network/auth_interceptor.dart:39-40`
**Issue:** `response.data['token'] as String` and `response.data['refresh_token'] as String` will throw `TypeError` at runtime if the API response doesn't match this exact shape (e.g., key is missing, value is null, or response is not a `Map`). The refresh endpoint might return a different error structure on partial failures.

**Fix:**
```dart
final data = response.data;
if (data is! Map<String, dynamic>) {
  return handler.next(err);
}
final newAccessToken = data['token'] as String?;
final newRefreshToken = data['refresh_token'] as String?;
if (newAccessToken == null || newRefreshToken == null) {
  return handler.next(err);
}
```

### WR-02: Fragile error response parsing in verifyCode — potential null dereference

**File:** `mobile/lib/features/auth/providers/auth_provider.dart:78-84`
**Issue:** The parsing chain `(errorData['error'] as Map<String, dynamic>?)?['details']` → `details[0]['message']` has two risks:
1. `details[0]` will throw `RangeError` if `details` is an empty list (only `isNotEmpty` is checked, which is correct), but `details[0]['message']` will throw if `details[0]` is not a `Map`.
2. The entire approach assumes `details[0]['message']` contains a number representing remaining attempts. This is extremely fragile — any backend change to the error shape will break parsing silently or throw.

**Fix:**
```dart
if (errorData is Map<String, dynamic>) {
  try {
    final error = errorData['error'] as Map<String, dynamic>?;
    final details = error?['details'];
    if (details is List && details.isNotEmpty) {
      final firstDetail = details[0];
      if (firstDetail is Map<String, dynamic>) {
        remaining = int.tryParse(firstDetail['message']?.toString() ?? '');
      }
    }
  } catch (_) {
    // Gracefully ignore malformed error responses
  }
}
```

### WR-03: GoRouter rebuilt on every auth state change — loses navigation history

**File:** `mobile/lib/core/router/app_router.dart:23`
**Issue:** `ref.watch(authProvider)` triggers a full `GoRouter` rebuild on every auth state transition (`AuthInitial` → `AuthLoading` → `AuthAuthenticated`). Each rebuild creates a brand new router, which:

1. Discards the current navigation stack entirely.
2. Re-evaluates `initialLocation`, resetting to splash.
3. Combined with CR-03, causes GlobalKey assertion errors.

This is separate from CR-03 (which addresses the crash) — even after fixing the GlobalKey issue, `ref.watch` here is architecturally wrong because it destroys router state.

**Fix:** See CR-03 fix — use `GoRouter.refreshListenable` with `ref.listen` instead of `ref.watch`. The `redirect` callback will be re-evaluated on each refresh without recreating the router.

### WR-04: Email validation too permissive

**File:** `mobile/lib/features/auth/screens/login_screen.dart:207-214`
**Issue:** The email validator only checks for the presence of `@`. Strings like `"@"`, `"user@"`, `"@domain"`, or `"a @b"` all pass validation. While the backend will reject invalid emails, submitting obviously malformed input wastes an API call and provides a poor UX.

**Fix:**
```dart
validator: (value) {
  if (value == null || value.trim().isEmpty) {
    return 'Email obrigatorio';
  }
  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!emailRegex.hasMatch(value.trim())) {
    return 'Email invalido';
  }
  return null;
},
```

## Info

### IN-01: AuthService provider in `core/providers/` breaks vertical slice boundary

**File:** `mobile/lib/core/providers/dio_provider.dart:3, 15-18`
**Issue:** `dio_provider.dart` in `core/providers/` imports and provides `AuthService` from `features/auth/`. This creates a dependency from the core layer into a feature module, violating the vertical slice architecture pattern described in the project conventions. The `AuthService` provider should live in `features/auth/providers/`.

**Fix:** Move the `authServiceProvider` definition to `mobile/lib/features/auth/providers/auth_service_provider.dart` and remove the import from `dio_provider.dart`. The `dio_provider.dart` should only expose `DioClient`.

### IN-02: Debug logging hardcoded in GoRouter

**File:** `mobile/lib/core/router/app_router.dart:28`
**Issue:** `debugLogDiagnostics: true` is unconditionally set. This will log every navigation event in release builds, which is unnecessary overhead and exposes route information.

**Fix:**
```dart
import 'package:flutter/foundation.dart';

// ...
debugLogDiagnostics: kDebugMode,
```

---

_Reviewed: 2026-05-04T12:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
