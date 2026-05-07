---
phase: 08
slug: client-interface
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-07
---

# Phase 08 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (unit/widget) + `integration_test` SDK |
| **Config file** | `mobile/pubspec.yaml` (dev_dependencies: flutter_test, integration_test) |
| **Quick run command** | `flutter test` |
| **Full suite command** | `flutter test && flutter test integration_test/` |
| **Estimated runtime** | ~15 seconds (unit/widget); integration requires device/emulator |

---

## Sampling Rate

- **After every task commit:** Run `flutter test`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 08-01-01 | 01 | 1 | UI-C01 | T-08-01 | Models don't expose sensitive data in toJson | unit | `flutter test test/client_models_test.dart` | ✅ | ✅ green |
| 08-01-02 | 01 | 1 | UI-C01 | T-08-02 | Services pass auth headers via DioClient | unit | `flutter test test/client_services_test.dart` | ✅ | ✅ green |
| 08-01-03 | 01 | 1 | UI-C01, UI-NFR-01 | — | N/A | unit | `flutter test test/client_models_test.dart` | ✅ | ✅ green |
| 08-02-01 | 02 | 2 | UI-C01 | — | N/A | widget | `flutter test test/client_home_screen_test.dart` | ✅ | ✅ green |
| 08-02-02 | 02 | 2 | UI-C06 | — | N/A | widget | `flutter test test/client_support_screen_test.dart` | ✅ | ✅ green |
| 08-03-01 | 03 | 2 | UI-C03, UI-C04 | T-08-05, T-08-06 | Type restricted to 4 values; download gated by isDownloadable | integration | `flutter test integration_test/documents_flow_test.dart` | ✅ | ✅ green |
| 08-04-01 | 04 | 2 | UI-C02 | — | N/A | integration | `flutter test integration_test/chat_flow_test.dart` | ✅ | ✅ green |
| 08-05-01 | 05 | 3 | UI-C05 | T-08-10 | Time-bounded queries prevent unbounded list | unit | `flutter test test/notification_provider_test.dart` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements.

- [x] `flutter_test` already present in dev_dependencies
- [x] `integration_test` already present in dev_dependencies
- [x] No additional framework install needed

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Dashboard shows real API data from 3 providers | UI-C01 | Requires running app with live backend + seeded database | Open app as student, verify 3 cards load with real data, pull-to-refresh reloads all |
| Chat message bubbles display with correct layout | UI-C02 | Visual alignment/colors can only be verified visually | Navigate to Chat, tap session, verify user messages right-aligned (primary), bot left-aligned (grey) |
| Document request submits to live API | UI-C03 | Full form flow needs live API interaction | Navigate to Documents, tap FAB, fill form, submit — verify new document appears |

---

## Validation Audit 2026-05-07

| Metric | Count |
|--------|-------|
| Gaps found | 5 |
| Resolved | 5 |
| Escalated | 0 |

### Tests Generated

| # | File | Type | Tests | Command |
|---|------|------|-------|---------|
| 1 | `mobile/test/client_models_test.dart` | Unit | 15 | `flutter test test/client_models_test.dart` |
| 2 | `mobile/test/client_services_test.dart` | Unit | 13 | `flutter test test/client_services_test.dart` |
| 3 | `mobile/test/client_home_screen_test.dart` | Widget | 5 | `flutter test test/client_home_screen_test.dart` |
| 4 | `mobile/test/notification_provider_test.dart` | Unit | 7 | `flutter test test/notification_provider_test.dart` |
| 5 | `mobile/test/client_support_screen_test.dart` | Widget | 7 | `flutter test test/client_support_screen_test.dart` |

**Total: 47 tests, all green**

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 15s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-07
