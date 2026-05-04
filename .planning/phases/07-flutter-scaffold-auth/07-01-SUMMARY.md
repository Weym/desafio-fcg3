---
phase: 07-flutter-scaffold-auth
plan: 01
subsystem: mobile
tags: [flutter, dependencies, dio, auth-service, models, theme, riverpod]
dependency_graph:
  requires: []
  provides: [dio-client, auth-service, user-model, app-theme, folder-structure]
  affects: [mobile/pubspec.yaml, mobile/lib/]
tech_stack:
  added: [flutter_riverpod, riverpod_annotation, go_router, dio, flutter_secure_storage, json_annotation, json_serializable, riverpod_generator, build_runner, custom_lint, riverpod_lint]
  patterns: [feature-first-folders, dio-interceptors, json-serializable-models, service-layer]
key_files:
  created:
    - mobile/lib/core/config/env_config.dart
    - mobile/lib/core/network/dio_client.dart
    - mobile/lib/core/network/api_interceptor.dart
    - mobile/lib/core/network/auth_interceptor.dart
    - mobile/lib/core/models/user_model.dart
    - mobile/lib/core/models/auth_tokens.dart
    - mobile/lib/core/theme/app_colors.dart
    - mobile/lib/core/theme/app_theme.dart
    - mobile/lib/features/auth/services/auth_service.dart
  modified:
    - mobile/pubspec.yaml
    - mobile/analysis_options.yaml
    - mobile/lib/main.dart
decisions:
  - "Removed envied/envied_generator due to analyzer version conflict with riverpod_generator (Rule 3 — blocking dependency). Used AppConfig with String.fromEnvironment as the plan's specified fallback."
metrics:
  duration: "4m 23s"
  completed: "2026-05-04T16:29:03Z"
---

# Phase 07 Plan 01: Project Foundation & Auth Infrastructure Summary

**One-liner:** Flutter project foundation with Dio HTTP client (auto-refresh interceptor), AuthService exposing 4 auth endpoints, UserModel with JSON codegen, and Material 3 theme — all wired via feature-first structure.

## Tasks Completed

| # | Task | Commit | Key Files |
|---|------|--------|-----------|
| 1 | Project dependencies and folder structure | `f623414` | pubspec.yaml, analysis_options.yaml, feature dirs |
| 2 | Environment config, Dio HTTP client, and interceptors | `d72ea24` | env_config.dart, dio_client.dart, api_interceptor.dart, auth_interceptor.dart |
| 3 | Core models, theme, AuthService, and app entry point | `b1c759b` | user_model.dart, auth_tokens.dart, app_theme.dart, auth_service.dart, main.dart |

## Verification Results

- `flutter pub get` — ✅ resolved 92 new packages
- `dart run build_runner build` — ✅ generated 4 outputs (user_model.g.dart, auth_tokens.g.dart)
- `flutter analyze lib/` — ✅ no issues found

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Removed envied/envied_generator packages**

- **Found during:** Task 1 (flutter pub get)
- **Issue:** `envied_generator ^0.5.4+1` requires `analyzer <7.0.0` while `riverpod_generator ^2.6.3` requires `analyzer ^6.7.0 || ^7.0.0`. The `_macros` SDK package doesn't exist in Dart 3.11, making analyzer version negotiation impossible.
- **Fix:** Removed both `envied` and `envied_generator` from pubspec.yaml. Used the plan's specified `AppConfig` fallback class with `String.fromEnvironment` for env config (compile-time dart-define approach). This is functionally equivalent and was explicitly included in the plan as a fallback.
- **Files modified:** mobile/pubspec.yaml
- **Commit:** f623414

## Architecture Notes

- **Feature-first structure:** `lib/features/{auth,client,staff,splash}/` each with `models/`, `services/`, `providers/`, `screens/` subdirs
- **Core layer:** `lib/core/{config,theme,network,models,providers}/` for shared infrastructure
- **Dio dual-instance pattern:** Main Dio has interceptors; separate refresh Dio avoids interceptor loops during token refresh
- **Silent 401 refresh:** AuthInterceptor catches 401, attempts refresh, retries original request — transparent to callers
- **Service layer:** AuthService wraps Dio calls, returns typed models — screens never call Dio directly

## Self-Check: PASSED
