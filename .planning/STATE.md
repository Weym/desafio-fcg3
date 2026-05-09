---
gsd_state_version: 1.0
milestone: v3.0
milestone_name: "Correções, Melhorias & Features"
status: active
last_updated: "2026-05-08T00:00:00.000Z"
last_activity: 2026-05-08 -- Milestone v3.0 started
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: 2026-05-08 — Milestone v3.0 started

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-08)

**Core value:** Aluno envia mensagem no WhatsApp e recebe resposta precisa sobre sua situação acadêmica — com ações concretas executadas em tempo real.
**Current focus:** v3.0 — Correções, Melhorias & Features

## Milestones Shipped

| Milestone | Phases | Plans | Shipped |
|-----------|--------|-------|---------|
| v1.0 Backend + AI + MCP | 1-6 | 47 | 2026-05-04 |
| v2.0 Flutter Frontend | 7-17 | 30 | 2026-05-07 |

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

## Session Continuity

To resume work: read this file, then `.planning/ROADMAP.md` for phase details.
