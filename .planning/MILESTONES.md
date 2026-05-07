# Milestones — Desafio FCG3

## v2.0 — Flutter Frontend

**Shipped:** 2026-05-07
**Phases:** 7-17 (11 phases, 30 plans)
**Timeline:** 30 days (2026-04-08 → 2026-05-07)
**LOC:** ~35,907 (19,238 Dart + 16,669 Python)

### Delivered

Complete Flutter mobile/web application ("Alpha Connect") with role-based navigation, OTP authentication, 10+ screens consuming the FastAPI REST API, glassmorphism visual identity, Docker Compose full-stack integration, resource allocation system, human intervention system, and comprehensive test coverage.

### Key Accomplishments

1. Flutter scaffold with OTP auth, role-based GoRouter navigation, secure JWT storage
2. 6 client screens + 5 staff screens consuming real REST API data
3. Alpha Connect glassmorphism visual identity with dark mode support
4. Docker Compose 5-service full stack (fastapi, langchain, mcp, postgres, flutter-web)
5. Resource allocation with authorization file uploads
6. Human intervention system (bot escalation, staff assumes/resolves via WhatsApp)

### Archive

- [v2.0-ROADMAP.md](./milestones/v2.0-ROADMAP.md) — Full phase details
- [v2.0-REQUIREMENTS.md](./milestones/v2.0-REQUIREMENTS.md) — 47/47 requirements complete

---

## v1.0 — Backend + AI Service + MCP Server

**Shipped:** 2026-05-04
**Phases:** 1-6 (6 phases, 47 plans)

### Delivered

FastAPI REST API with 35+ endpoints, OTP/JWT authentication, LangChain ReAct agent with RAG pipeline, MCP Server with 16 tools, WhatsApp webhook integration, Docker Compose 4-service stack.

### Key Accomplishments

1. Docker stack (4 services), Alembic schema, seed data
2. OTP/email auth (Resend), JWT with roles, middleware
3. 7 feature slices, 35 REST endpoints, IDOR protection
4. MCP Server, 16 tools, student_id injection, action logging
5. LangChain ReAct agent, RAG pipeline, provider-agnostic LLM
6. WhatsApp webhook, end-to-end chatbot flow

---
