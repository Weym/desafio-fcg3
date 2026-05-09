# Desafio FCG3 — Plataforma Acadêmica com Chatbot WhatsApp

## What This Is

Plataforma completa para alunos do curso de Ciência da Computação interagirem com serviços acadêmicos via API REST, WhatsApp e app mobile Flutter. O backend em FastAPI centraliza dados e lógica de negócio; um agente LangChain com RAG processa mensagens do WhatsApp e executa ações via MCP Server; o app Flutter ("Alpha Connect") oferece interface visual para alunos e staff com autenticação OTP, glassmorphism UI, e funcionalidades de gestão acadêmica.

## Core Value

Aluno envia mensagem no WhatsApp e recebe resposta precisa sobre sua situação acadêmica (notas, matrículas, documentos) — com ações concretas executadas em tempo real. Alternativamente, acessa o app mobile para visualizar e gerenciar sua situação acadêmica diretamente.

## Requirements

### Validated

**v1.0 — Backend + AI + MCP:**
- ✓ Docker Compose com 4 serviços, healthchecks e hot reload local — v1.0
- ✓ Alembic configurado com migrations para schema + pgvector/HNSW — v1.0
- ✓ Auth: OTP por email via Resend + JWT com campo role (student | staff) — v1.0
- ✓ Middleware: JWT, Service Token (MCP), rate limiting — v1.0
- ✓ 7 feature slices, 35 REST endpoints, IDOR protection — v1.0
- ✓ MCP Server: 16 tools, student_id injection, action logging — v1.0
- ✓ AI Service: ReAct agent, RAG pipeline, provider-agnostic LLM — v1.0
- ✓ WhatsApp webhook, end-to-end chatbot flow — v1.0

**v2.0 — Flutter Frontend:**
- ✓ Flutter scaffold com navegação baseada em perfil (Client/Staff) — v2.0
- ✓ OTP auth integrado com backend FastAPI — v2.0
- ✓ JWT em flutter_secure_storage com detecção de expiração — v2.0
- ✓ 6 telas Client (Dashboard, Chat, Documents, Notifications, Support, Resources) — v2.0
- ✓ 5 telas Staff (Dashboard KPIs, Schedule, AI Data, Documents, Resources, Intervention) — v2.0
- ✓ Cross-platform (phone, tablet, web) com dark mode — v2.0
- ✓ Alpha Connect visual identity (glassmorphism, Plus Jakarta Sans + Inter) — v2.0
- ✓ Docker Compose full-stack 5 services — v2.0
- ✓ Resource allocation com upload de autorização — v2.0
- ✓ Human intervention (escalação bot → staff assume via WhatsApp) — v2.0
- ✓ 244 Flutter tests + E2E integration tests — v2.0

### Active

- [ ] Webhook WhatsApp: validação HMAC-SHA256 end-to-end (parcial)
- [ ] Push notifications via FCM (registro de token, envio por tipo de evento)
- [ ] Testes: cobertura dos fluxos críticos (matrícula, webhook, middleware IDOR)

### Out of Scope

- Whisper API (transcrição de áudio) — pós-MVP
- GPT-4o Vision (análise de imagens) — pós-MVP
- Redis cache para sessões de conversa — pós-MVP
- pg_cron para limpeza automática — pós-MVP
- Sentry / monitoramento externo — pós-MVP
- Offline-first / local caching strategy — pós-MVP

## Context

- **Monorepo:** `backend/` (FastAPI), `mobile/` (Flutter), `mcp_server/`, `ai_service/`
- **Banco:** PostgreSQL 16 + PGVector (17 tabelas, HNSW index, 1536-dim embeddings)
- **Flutter:** 3.41.6, Dart ^3.11.4, Riverpod + GoRouter + Dio
- **Backend:** Python 3.12, FastAPI, SQLAlchemy + Alembic, 35+ endpoints
- **AI:** LangChain ReAct, MCP 16 tools, RAG with configurable threshold
- **Docker:** 5 services (fastapi:8000, langchain:8001, mcp:8002, postgres:5432, flutter-web:3000)
- **LOC:** ~19,238 Dart + ~16,669 Python = ~35,907 total
- **Tests:** 244 Flutter unit tests + E2E integration tests

## Constraints

- **Tech Stack**: Python 3.12, FastAPI, SQLAlchemy + Alembic, LangChain, MCP — não negociável
- **Segurança**: `student_id` nunca exposto ao agente LangChain; sempre injetado pelo MCP Server
- **Segurança**: `MCP_SERVICE_TOKEN` nunca em código-fonte — apenas variável de ambiente
- **Performance**: Webhook deve retornar 200 OK em < 5s (limite do WhatsApp)
- **LLM Provider**: Decisão de terceiro — implementar agnóstico de provider
- **Email OTP**: Resend como provider

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Python / FastAPI (não TypeScript) | Documentação técnica especifica Python | ✓ Validated v1.0 |
| SQLAlchemy + Alembic | ORM maduro, controle total SQL | ✓ Validated v1.0 |
| JWT com campo role (student \| staff) | Um único fluxo de auth | ✓ Validated v1.0 |
| asyncio.create_task para background processing | Atende limite 5s WhatsApp | ✓ Validated v1.0 |
| Resend para envio de OTP | SDK Python, tier gratuito 3k emails/mês | ✓ Validated v1.0 |
| student_id injetado pelo MCP (IDOR prevention) | Agente não pode forjar student_id | ✓ Validated v1.0 |
| Riverpod + GoRouter (não Bloc) | Simplicity, code generation, type safety | ✓ Validated v2.0 |
| QueuedInterceptor para auth token | Serializa concurrent 401 handling | ✓ Validated v2.0 |
| Glassmorphism UI (Alpha Connect) | Visual identity alignment com prototype React | ✓ Validated v2.0 |
| Docker multi-stage Flutter web build | Uniform dev experience, single compose up | ✓ Validated v2.0 |
| DEV_MASTER_OTP bypass | Dev/testing sem dependência Resend | ✓ Validated v2.0 |
| Derived notifications (no backend endpoint) | Aggregates from documents + appointments | ✓ Validated v2.0 |

## Current State

**Both milestones delivered:**
- v1.0 (Backend + AI + MCP): 6 phases, 47 plans — shipped 2026-05-04
- v2.0 (Flutter Frontend): 11 phases, 30 plans — shipped 2026-05-07

**Total:** 17 phases, 77 plans, ~557 commits across 30 days.

Project is feature-complete for the desafio scope. No active milestone.

---

_Last updated: 2026-05-07 after v2.0 milestone_
