---
phase: 09
slug: staff-interface
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-07
---

# Phase 09 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework (Flutter)** | flutter_test SDK (built-in) |
| **Framework (Backend)** | pytest |
| **Config file (Flutter)** | mobile/pubspec.yaml (flutter_test in dev_dependencies) |
| **Config file (Backend)** | backend/pyproject.toml |
| **Quick run command (Flutter)** | `cd mobile && flutter test test/staff/` |
| **Quick run command (Backend)** | `cd backend && python -m pytest tests/features/documents/ -v` |
| **Full suite command** | `cd mobile && flutter test && cd ../backend && python -m pytest` |
| **Estimated runtime** | ~30 seconds (Flutter) + ~10 seconds (Backend) |

---

## Sampling Rate

- **After every task commit:** Run `cd mobile && flutter test test/staff/`
- **After every plan wave:** Run full suite
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 40 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 09-01-T1 | 01 | 1 | UI-F01-F04 | — | N/A | unit | `cd mobile && flutter test test/staff/models/staff_models_test.dart` | ✅ | ✅ green |
| 09-01-T2 | 01 | 1 | UI-F01-F04 | — | Services call correct API endpoints | unit | `cd mobile && flutter test test/staff/services/staff_services_test.dart` | ✅ | ✅ green |
| 09-02-T1 | 02 | 2 | UI-F01 | — | Dashboard renders 5 KPIs with correct values | widget | `cd mobile && flutter test test/staff/screens/staff_dashboard_screen_test.dart` | ✅ | ✅ green |
| 09-02-T2 | 02 | 2 | UI-F02 | T-09-04 | Confirmation dialog with barrierDismissible: false | widget | `cd mobile && flutter test test/staff/screens/staff_schedule_screen_test.dart` | ✅ | ✅ green |
| 09-03-T1 | 03 | 2 | UI-F03 | T-09-06, T-09-07 | Staff-only data access via providers | widget | `cd mobile && flutter test test/staff/screens/staff_ai_screen_test.dart` | ✅ | ✅ green |
| 09-03-T2 | 03 | 2 | UI-F03 | T-09-06 | Action logs displayed read-only | widget | `cd mobile && flutter test test/staff/screens/staff_chat_detail_test.dart` | ✅ | ✅ green |
| 09-04-T1 | 04 | 2 | UI-F04 | T-09-08, T-09-09 | File type/size validation, UUID prefix prevents path traversal | integration | `cd backend && python -m pytest tests/features/documents/test_upload_endpoint.py -v` | ✅ | ✅ green |
| 09-04-T2 | 04 | 2 | UI-F04 | T-09-11 | Document cards with correct status colors | widget | `cd mobile && flutter test test/staff/screens/staff_documents_screen_test.dart` | ✅ | ✅ green |
| 09-05-T2 | 05 | 3 | UI-F01-F04 | T-09-12 | All routes resolve to real screens (no placeholders) | unit | `cd mobile && flutter test test/staff/router/staff_routes_test.dart` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements:
- Flutter: `flutter_test` SDK already in dev_dependencies
- Backend: pytest already configured in pyproject.toml
- No new framework installation required

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Full staff navigation flow with real API data | UI-F01-F04 | Requires running app + backend | Log in as staff, navigate all 4 tabs, verify screens render data from API |
| KPI card tap navigation | UI-F01 | GoRouter flow requires running app | Tap Docs/Appointments/Chats KPI cards, verify correct tab opens |
| Create scheduling slot flow | UI-F02 | Interactive form with date/time pickers | FAB → fill date/time/duration → submit → verify slot created |
| File upload via Update Status sheet | UI-F04 | File picker requires device interaction | Set status to 'ready' → pick PDF → submit → verify upload+status update |

*4 behaviors require human verification — all documented in `09-VERIFICATION.md` human_verification section.*

---

## Test Files Summary

| File | Test Cases | Coverage |
|------|-----------|----------|
| `mobile/test/staff/models/staff_models_test.dart` | 14 | Model JSON serialization (fromJson/toJson roundtrip) |
| `mobile/test/staff/services/staff_services_test.dart` | 17 | All 4 services verify correct API endpoints/methods/params |
| `mobile/test/staff/screens/staff_dashboard_screen_test.dart` | 5 | Dashboard KPIs, enrollment banner, AppBar |
| `mobile/test/staff/screens/staff_schedule_screen_test.dart` | 5 | Filter chips, appointment cards, FAB, empty state |
| `mobile/test/staff/screens/staff_ai_screen_test.dart` | 5 | Tabs, session cards, statistics counters, empty state |
| `mobile/test/staff/screens/staff_chat_detail_test.dart` | 6 | Message bubbles, action logs, tabs, empty states |
| `mobile/test/staff/screens/staff_documents_screen_test.dart` | 5 | Filter chips, document cards, FAB, empty state |
| `mobile/test/staff/router/staff_routes_test.dart` | 8 | Route constants, paths, parameters, no placeholders |
| `backend/tests/features/documents/test_upload_endpoint.py` | 9 | File type/size validation, save, auth |
| **Total** | **74** | |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 40s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-07

---

## Validation Audit 2026-05-07

| Metric | Count |
|--------|-------|
| Gaps found | 9 |
| Resolved | 9 |
| Escalated | 0 |

---

*Phase: 09-staff-interface*
*Validated: 2026-05-07*
