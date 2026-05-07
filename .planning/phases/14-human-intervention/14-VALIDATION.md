---
phase: 14
slug: human-intervention
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-07
---

# Phase 14 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework (Backend)** | pytest 8.x (asyncio_mode="auto") |
| **Framework (Flutter)** | flutter_test (SDK) |
| **Config file (Backend)** | `backend/pyproject.toml` |
| **Config file (Flutter)** | `mobile/pubspec.yaml` |
| **Quick run command** | `cd backend && python -m pytest tests/features/chat/ -v` |
| **Full suite command** | `cd backend && python -m pytest tests/ -v && cd ../mobile && flutter test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd backend && python -m pytest tests/features/chat/ tests/features/webhook/ -v`
- **After every plan wave:** Run `cd backend && python -m pytest tests/ -v`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 14-01-T1 | 01 | 1 | HI-10 | — | Model supports 4 status values + intervention fields | unit | `cd backend && python -m pytest tests/features/chat/test_escalation_detection.py::TestChatSessionModelFields -v` | ✅ | ✅ green |
| 14-01-T2a | 01 | 1 | HI-01 | T-14-05 | Keyword detection triggers escalation before AI | unit | `cd backend && python -m pytest tests/features/chat/test_escalation_detection.py::TestKeywordEscalationDetection -v` | ✅ | ✅ green |
| 14-01-T2b | 01 | 1 | HI-02 | — | AI response phrases trigger post-AI escalation | unit | `cd backend && python -m pytest tests/features/chat/test_escalation_detection.py::TestAIResponseEscalationDetection -v` | ✅ | ✅ green |
| 14-01-T2c | 01 | 1 | HI-03 | — | Webhook skips AI for human_needed/human_active sessions | integration | `cd backend && python -m pytest tests/features/webhook/test_ai_skip_gate.py -v` | ✅ | ✅ green |
| 14-01-T3a | 01 | 1 | HI-04 | T-14-01 | Staff-only assign (human_needed → human_active) | integration | `cd backend && python -m pytest tests/features/chat/test_human_intervention.py::TestAssignSession -v` | ✅ | ✅ green |
| 14-01-T3b | 01 | 1 | HI-05 | T-14-06 | Staff reply saves message + sends WhatsApp | integration | `cd backend && python -m pytest tests/features/chat/test_human_intervention.py::TestStaffReply -v` | ✅ | ✅ green |
| 14-01-T3c | 01 | 1 | HI-06 | T-14-03 | Resolve closes session (human_active → closed) | integration | `cd backend && python -m pytest tests/features/chat/test_human_intervention.py::TestResolveSession -v` | ✅ | ✅ green |
| 14-01-T3d | 01 | 1 | HI-07 | T-14-04 | List interventions: pending + staff's active only | integration | `cd backend && python -m pytest tests/features/chat/test_human_intervention.py::TestListInterventionSessions -v` | ✅ | ✅ green |
| 14-01-T3e | 01 | 1 | HI-08 | T-14-03 | 409 on invalid state transition | integration | `cd backend && python -m pytest tests/features/chat/test_human_intervention.py::TestInvalidStateTransitions -v` | ✅ | ✅ green |
| 14-01-T3f | 01 | 1 | HI-09 | T-14-02 | 403 on ownership mismatch (reply/resolve) | integration | `cd backend && python -m pytest tests/features/chat/test_human_intervention.py::TestOwnershipMismatch -v` | ✅ | ✅ green |
| 14-02-T2a | 02 | 2 | HI-12 | — | Intervention screen renders session cards | widget | `cd mobile && flutter test test/staff_intervention_test.dart` | ✅ | ✅ green |
| 14-02-T2b | 02 | 2 | HI-13 | — | Card shows student name, RA, status badge, elapsed | widget | `cd mobile && flutter test test/staff_intervention_test.dart` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. No new framework install needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Staff shell shows "Intervencao" as 6th tab | HI-11 | Navigation shell requires full app runtime | Launch app, log in as staff, verify 6th tab icon (support_agent) and label |
| Assign button calls POST /assign and opens chat | HI-14 | End-to-end integration requiring backend + WhatsApp mock | Create human_needed session in DB, tap "Assumir Conversa", verify status changes to human_active |
| Chat detail shows reply input + sends via API | HI-15 | E2E integration requiring live backend | Assign session, type message, tap send, verify message saved + WhatsApp delivery |
| Resolve button closes session and returns to list | HI-16 | E2E integration requiring state in backend | In active intervention, tap "Resolver", confirm dialog, verify status = closed |

---

## Validation Audit 2026-05-07

| Metric | Count |
|--------|-------|
| Gaps found | 16 |
| Resolved (automated) | 12 |
| Manual-only | 4 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 15s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-05-07
