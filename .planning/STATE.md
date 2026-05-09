---
gsd_state_version: 1.0
milestone: v3.0
milestone_name: Correções, Melhorias & Features
status: executing
last_updated: "2026-05-09T01:56:23.165Z"
last_activity: 2026-05-09
progress:
  total_phases: 7
  completed_phases: 0
  total_plans: 5
  completed_plans: 4
  percent: 80
---

# Project State

## Current Position

Phase: 18 (Student UX Corrections) — EXECUTING
Plan: 5 of 5
Status: Ready to execute
Last activity: 2026-05-09

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-08)

**Core value:** Aluno envia mensagem no WhatsApp e recebe resposta precisa sobre sua situação acadêmica — com ações concretas executadas em tempo real.
**Current focus:** Phase 18 — Student UX Corrections

## Milestones Shipped

| Milestone | Phases | Plans | Shipped |
|-----------|--------|-------|---------|
| v1.0 Backend + AI + MCP | 1-6 | 47 | 2026-05-04 |
| v2.0 Flutter Frontend | 7-17 | 30 | 2026-05-07 |

## v3.0 Phase Overview

| Phase | Name | Group | Parallel With |
|-------|------|-------|---------------|
| 18 | Student UX Corrections | Corrections | Phase 19 |
| 19 | Staff UX Corrections | Corrections | Phase 18 |
| 20 | LangChain Workflow | Improvements | Phases 21, 22 |
| 21 | Roles & Auth Expansion | Improvements | Phases 20, 22 |
| 22 | FCM Push Notifications | Improvements | Phases 20, 21 |
| 23 | New Features | Features | — |
| 24 | UI Polish & Integration | Polish | — (depends on all) |

## Architecture Constraints (non-negotiable)

- `student_id` is NEVER exposed to the LangChain agent — always injected by MCP Server
- `MCP_SERVICE_TOKEN` only in environment variables, never in source code
- JWT stored in `flutter_secure_storage` — never in plain SharedPreferences
- Role-based route guards — student cannot access staff screens and vice versa
- All API calls use `Authorization: Bearer {token}` header
- Two separate PostgreSQL drivers: `asyncpg` for FastAPI + MCP; `psycopg3` for LangChain service

## Accumulated Context

- v1.0 + v2.0 shipped: 17 phases, 77 plans, ~35,907 LOC
- Flutter uses Riverpod + GoRouter + Dio with QueuedInterceptor
- Glassmorphism UI (Alpha Connect) with Plus Jakarta Sans + Inter
- Docker 5-service stack (fastapi:8000, langchain:8001, mcp:8002, postgres:5432, flutter-web:3000)
- DEV_MASTER_OTP bypass available for dev/testing
- v3.0 phases designed for maximum parallel execution within groups
- **18-01:** StateProvider pattern for cross-screen drawer auto-open (documentAutoOpenDrawerProvider)
- **18-01:** AppBarActions contains support + notifications icons in header (support_agent_outlined, notifications_outlined)
- **18-01:** Bottom nav reduced to 4 items (Início, Chat, Docs, Recursos) — Avisos moved to header
- **18-02:** Chat sessions: rename via long-press, filter tabs (Todas/Ativas/Inativas), date ordering label
- **18-02:** GlassCard now supports onLongPress for contextual actions
- **18-02:** ChatFilterNotifier pattern for client-side filtering (no extra API call)
- **18-03:** Document cards show date+time (DD/MM/YYYY HH:MM), tap opens detail bottom sheet
- **18-03:** showDocumentDetailSheet pattern with _DetailRow for key-value display in sheets
- **18-04:** Notifications: read/unread state via client-side Set<String> (ReadNotificationIds provider)
- **18-04:** Filter tabs (Todas/Não lidas/Lidas) and "Visualizar todos" bulk mark-as-read
- **18-04:** Individual notification marked as read only on direct tap (not on scroll/view)

## Session Continuity

To resume work: read this file, then `.planning/ROADMAP.md` for phase details.

**Parallel execution guidance:**

- Group 1 (Phases 18-19): Start with `/gsd-plan-phase 18` or `/gsd-plan-phase 19` — both are independent
- Group 2 (Phases 20-22): After Group 1, any of these can start in any order
- Group 3 (Phase 23): After Group 2, plan and execute new features
- Group 4 (Phase 24): Only after all above are complete
