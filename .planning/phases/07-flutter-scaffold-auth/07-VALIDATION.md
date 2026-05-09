---
phase: 07
slug: flutter-scaffold-auth
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-07
---

# Phase 07 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (SDK) |
| **Config file** | mobile/pubspec.yaml (`flutter_test: sdk: flutter`) |
| **Quick run command** | `cd mobile && flutter test` |
| **Full suite command** | `cd mobile && flutter test --coverage` |
| **Estimated runtime** | ~19 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd mobile && flutter test`
- **After every plan wave:** Run `cd mobile && flutter test --coverage`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 07-01-01 | 01 | 1 | UI-INFRA-01 | — | Dependencies resolve, folder structure | build | `cd mobile && flutter pub get` | ✅ | ✅ green |
| 07-01-02 | 01 | 1 | UI-INFRA-02 | T-07-01, T-07-03 | Auth interceptor injects Bearer, silent refresh on 401 | unit | `cd mobile && flutter test test/auth_login_flow_test.dart` | ✅ | ✅ green |
| 07-01-03 | 01 | 1 | UI-INFRA-02 | T-07-04 | Models deserialize JSON, theme Material 3 | unit | `cd mobile && flutter test test/auth_tokens_test.dart test/theme_test.dart` | ✅ | ✅ green |
| 07-02-01 | 02 | 2 | UI-INFRA-02, UI-INFRA-03 | T-07-08 | requestCode, checkAuthStatus, logout — state transitions, token persistence | unit | `cd mobile && flutter test test/auth_provider_full_test.dart` | ✅ | ✅ green |
| 07-02-02 | 02 | 2 | UI-INFRA-02, UI-NFR-03 | T-07-05, T-07-07 | Login two-step flow, email validation, OTP entry, error snackbars, resend countdown | widget | `cd mobile && flutter test test/login_screen_test.dart` | ✅ | ✅ green |
| 07-03-01 | 03 | 3 | UI-INFRA-01, UI-NFR-03 | T-07-09 | GoRouter redirect guards: role-based, auth state, cross-role block | widget | `cd mobile && flutter test test/app_router_test.dart` | ✅ | ✅ green |
| 07-03-02 | 03 | 3 | UI-INFRA-01 | T-07-10 | Splash JWT check, ClientShell 5-tab, StaffShell navigation | widget | `cd mobile && flutter test test/navigation_shells_test.dart` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:
- `flutter_test` already in dev_dependencies
- Test utilities (ProviderContainer overrides, FlutterSecureStorage mock) available via existing packages

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Full boot-to-login on device | UI-INFRA-01 | CR-03 GlobalKey reuse may affect runtime | Launch app on emulator with no stored JWT |
| Complete E2E OTP flow | UI-INFRA-02 | Needs live backend for real OTP delivery | Enter email, receive OTP, verify code |
| Token persistence across restart | UI-INFRA-03 | CR-01 void async interceptor runtime behavior | Kill app after login, relaunch |
| Error messages with live backend | UI-INFRA-02 | Backend error codes needed | Enter wrong OTP 3 times |
| Cross-role access on device | UI-NFR-03 | CR-03 router recreation may affect redirect | Student → /staff URL; Staff → /client URL |

*Manual items derive from 07-VERIFICATION.md human_verification section (CR-01/CR-02/CR-03 runtime bugs).*

---

## Test Files Summary

| File | Tests | Covers |
|------|-------|--------|
| `mobile/test/auth_tokens_test.dart` | 4 | AuthResponse + UserModel JSON parsing |
| `mobile/test/auth_login_flow_test.dart` | 4 | AuthProvider verifyCode flow, AuthInterceptor refresh |
| `mobile/test/theme_test.dart` | 14 | AppColors, AppSpacing, AppTheme Material 3 |
| `mobile/test/auth_provider_full_test.dart` | 7 | requestCode, checkAuthStatus, logout |
| `mobile/test/login_screen_test.dart` | 7 | LoginScreen two-step flow, validation, countdown |
| `mobile/test/app_router_test.dart` | 6 | GoRouter redirect guards, role-based routing |
| `mobile/test/navigation_shells_test.dart` | 3 | Splash, ClientShell, StaffShell navigation |
| **Total** | **45** | |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 20s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-07

---

## Validation Audit 2026-05-07

| Metric | Count |
|--------|-------|
| Gaps found | 4 |
| Resolved | 4 |
| Escalated | 0 |
