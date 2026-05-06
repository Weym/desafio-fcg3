---
phase: 14-human-intervention
plan: 01
subsystem: backend-chat-webhook
tags: [human-intervention, escalation, staff-endpoints, whatsapp]
dependency_graph:
  requires: [chat-models, webhook-background, whatsapp-client, staff-auth]
  provides: [human-intervention-api, escalation-detection, ai-skip-gate]
  affects: [chat-sessions, webhook-flow, staff-dashboard]
tech_stack:
  added: []
  patterns: [state-machine-transitions, keyword-detection, staff-assignment]
key_files:
  created:
    - backend/alembic/versions/013_add_human_intervention_status.py
  modified:
    - backend/src/features/chat/models.py
    - backend/src/features/chat/schemas.py
    - backend/src/features/chat/service.py
    - backend/src/features/chat/router.py
    - backend/src/features/webhook/background.py
    - backend/src/features/webhook/router.py
decisions:
  - "Escalation keywords checked before AI call — saves AI service resources"
  - "AI response escalation saves bot message to DB before escalating — staff sees context"
  - "Partial index on status for fast intervention queries"
  - "FIFO ordering by escalated_at for intervention queue"
  - "Staff sees all human_needed + only their own human_active (T-14-04)"
metrics:
  duration: ~8min
  completed: 2026-05-06
---

# Phase 14 Plan 01: Human Intervention Backend Summary

**One-liner:** Full human intervention workflow: escalation detection (keywords + AI response), AI skip gate, and staff assign/reply/resolve endpoints with WhatsApp delivery.

## What Was Built

### Migration (013)
- Expanded `chat_sessions.status` CHECK constraint: `active`, `closed` → + `human_needed`, `human_active`
- Added `assigned_staff_id` (UUID FK → staff.id, nullable) for staff assignment tracking
- Added `escalated_at` (DateTime, nullable) for escalation timestamp
- Added partial index `idx_chat_sessions_human_status` for fast staff queries

### Escalation Detection (background.py)
- **Keyword detection** (before AI): "atendente", "humano", "pessoa", "secretaria", "falar com alguem", "atendimento humano"
- **AI response detection** (after AI): "procurar a secretaria", "secretaria presencialmente", "entrar em contato com a secretaria"
- **Escalation flow**: sets status=`human_needed`, sets `escalated_at`, saves system message, sends ack to student

### AI Skip Gate (webhook router)
- After verification passes and before `asyncio.create_task`, checks `session.status`
- If `human_needed` or `human_active`: message is saved but AI is never invoked

### Staff Endpoints (router.py)
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/chat-sessions/interventions` | GET | List pending + staff's active sessions |
| `/chat-sessions/{id}/assign` | POST | Staff takes ownership (human_needed → human_active) |
| `/chat-sessions/{id}/reply` | POST | Staff sends message (saved + sent via WhatsApp) |
| `/chat-sessions/{id}/resolve` | PUT | Staff closes session |

### Security (Threat Mitigations)
- T-14-01: All intervention endpoints require `role='staff'`
- T-14-02: Reply/resolve validate `assigned_staff_id == current_user.id`
- T-14-03: State transitions validated (409 on invalid status)
- T-14-04: Staff sees all pending + only their own active sessions

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | 4653b61 | Migration + model updates (4-value CHECK, assigned_staff_id, escalated_at) |
| 2 | a9d0ea6 | Escalation detection + AI skip logic |
| 3 | 6fbcabb | Staff endpoints (assign, reply, resolve, list interventions) |

## Deviations from Plan

### Minor Adjustments

**1. [Rule 2 - Enhancement] Added multiple AI escalation phrases**
- **Plan specified:** Only "procurar a secretaria"
- **Implemented:** Also "secretaria presencialmente" and "entrar em contato com a secretaria" per user's Task 2 instructions
- **Rationale:** Covers more natural language variants for escalation

**2. [Rule 2 - Field naming] Used `escalated_at` instead of `escalation_reason`**
- **Plan specified:** `escalation_reason` (Text) field
- **Implemented:** `escalated_at` (DateTime) per PLAN.md frontmatter which specified `escalated_at`
- **Rationale:** PLAN.md Task 1 action explicitly says "Add column escalated_at"; escalation reason is captured in the system message content

## Known Stubs

None — all endpoints are fully wired with real data sources and WhatsApp delivery.

## Threat Flags

None — no new security surface beyond what was planned in the threat model.

## Self-Check: PASSED

All 7 key files verified present. All 3 task commits (4653b61, a9d0ea6, 6fbcabb) verified in git log.
