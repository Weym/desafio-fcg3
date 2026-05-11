# Desafio FCG3 — Plataforma Acadêmica com Chatbot WhatsApp

## What This Is

Plataforma para alunos do curso de Ciência da Computação interagirem com serviços acadêmicos via API REST e WhatsApp. O backend em FastAPI centraliza dados e lógica de negócio; um agente LangChain com RAG processa mensagens do WhatsApp e executa ações via MCP Server; um MCP Server atua como proxy entre o agente e a API, injetando contexto de segurança.

## Core Value

Aluno envia mensagem no WhatsApp e recebe resposta precisa sobre sua situação acadêmica (notas, matrículas, documentos) — com ações concretas executadas em tempo real.

## Requirements

### Validated

- ✓ Estrutura de diretórios e scaffolding do backend (FastAPI + VSA) — existing
- ✓ Estrutura Flutter mobile (scaffolded) — existing
- ✓ Documentação de arquitetura, API, banco e chatbot em `docs/` — existing
- ✓ Docker Compose presente (vazio, pendente de implementação) — existing
- ✓ Docker Compose com 4 serviços, healthchecks e hot reload local — validated in Phase 1
- ✓ Alembic configurado com migrations para o schema da aplicação + pgvector/HNSW — validated in Phase 1
- ✓ Variáveis de ambiente documentadas em `.env.example` — validated in Phase 1
- ✓ Seed destrutivo de desenvolvimento com currículo, alunos, staff e fixtures acadêmicos — validated in Phase 1
- ✓ Auth: OTP por email via Resend + JWT com campo `role` (student | staff) — validated in Phase 2
- ✓ Middleware: JWT, Service Token (MCP), rate limiting no endpoint de auth — validated in Phase 2
- ✓ Matrículas: consultar, solicitar, confirmar, cancelar (com validação de período e pré-requisitos) — validated in Phase 3
- ✓ Notas e histórico: consulta de notas por disciplina/período, CRA calculado — validated in Phase 3
- ✓ Documentos: listagem, solicitação, detalhe e atualização de status — validated in Phase 3
- ✓ Agendamentos: consultar, solicitar e cancelar horários com SELECT FOR UPDATE — validated in Phase 3
- ✓ Cursos & Currículo: listagem, detalhe, árvore recursiva de pré-requisitos — validated in Phase 3
- ✓ Alunos: CRUD, resumo acadêmico com CRA, cursos disponíveis com filtro de pré-requisitos — validated in Phase 3
- ✓ Staff Dashboard: KPIs agregados de todos os domínios — validated in Phase 3
- ✓ AI Service: agente ReAct em LangChain com MCP tools, resposta em português e regressões de chat/runtime — validated in Phase 5
- ✓ AI Service: pipeline RAG com threshold configurável via `RAG_SIMILARITY_THRESHOLD` (default 0.45, calibrado para embeddings proxied via OpenRouter) e ingest da knowledge base em `ai_service/ingest.py` — validated in Phase 5
- ✓ AI Service: provider agnóstico via `LLM_PROVIDER` (`openai`/`gemini`) — validated in Phase 5

### Active

**Infraestrutura:**

**Backend (FastAPI):**
- [ ] Webhook WhatsApp: validação HMAC-SHA256, save de mensagem, despacho assíncrono
- [ ] Testes: cobertura dos fluxos críticos (matrícula, webhook, middleware IDOR)

**MCP Server:**
- [x] 16 ferramentas documentadas em `docs/mcp.md` implementadas — validated in Phase 4
- [x] Injeção de `student_id` a partir do contexto de sessão (prevenção de IDOR) — validated in Phase 4
- [x] Log de cada chamada de tool em `mcp_action_logs` (params, resultado, latência, retry) — validated in Phase 4
- [x] Validação de `X-Service-Token` em todas as chamadas internas — validated in Phase 4

### Out of Scope

- Push notifications FCM — adiar para ciclo seguinte
- Whisper API (transcrição de áudio) — pós-MVP
- GPT-4o Vision (análise de imagens) — pós-MVP
- Redis cache para sessões de conversa — pós-MVP
- pg_cron para limpeza automática de verification_codes — pós-MVP
- Sentry / monitoramento de erros externo — pós-MVP

## Context

- Monorepo: `backend/` (FastAPI), `mobile/` (Flutter), `mcp_server/` e `ai_service/` implementados no workspace atual
- Banco: PostgreSQL 16 + PGVector. Schema completo documentado em `docs/database.md` (17 tabelas, HNSW index)
- Embedding model: `text-embedding-3-small` (OpenAI, 1536 dimensões) — fixo no schema
- LLM provider: a definir por terceiro — arquitetura deve suportar troca por variável de ambiente
- WhatsApp: webhook valida `X-Hub-Signature-256`, responde em `< 5s` via `asyncio.create_task`
- Documentação de referência em `docs/`: `architecture.md`, `api.md`, `database.md`, `chatbot.md`, `mcp.md`, `app.md`

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
| Python / FastAPI (não TypeScript) | README estava desatualizado; toda a documentação técnica em `docs/` especifica Python | ✓ Python/FastAPI |
| SQLAlchemy + Alembic | ORM maduro com controle total do SQL, integra nativamente com Alembic para migrations | ✓ Validated in Phase 1 |
| JWT com campo `role` (student \| staff) | Um único fluxo de auth, diferenciação por payload | ✓ Validated in Phase 2 |
| asyncio.create_task para background processing | Atende o limite de 5s do WhatsApp no MVP; sem overhead de task queue externo | ⚠️ Revisit (sem visibility de falhas) |
| LLM provider agnóstico | Decisão de provider é de terceiro; embedding fixo em OpenAI `text-embedding-3-small` | — Pending |
| Resend para envio de OTP | SDK Python, tier gratuito 3k emails/mês, API simples | ✓ Validated in Phase 2 |
| `student_id` injetado pelo MCP (nunca exposto ao agente) | Prevenção de IDOR — o agente não pode forjar student_id | ✓ Validated in Phase 4 |
| Agendamentos incluídos neste ciclo | Requisito confirmado pelo usuário | ✓ Validated in Phase 3 |

## Current Milestone: v2.0 Flutter Frontend

**Goal:** Deliver the Flutter mobile/web application with role-based navigation (Client and Provider/Staff), consuming the FastAPI REST API built in M1.

**Target features:**
- Flutter scaffold with role-based navigation and OTP authentication
- 6 client screens: Dashboard, Chat History, Document Requests, Document Board, Notifications, Support
- 4 staff/provider screens: Management Dashboard, Schedule Control, AI Data Interaction, Document Management
- Cross-platform responsiveness (smartphones, tablets, web) and performance polish

## Current State

- M1 (v1.0) complete: Backend + AI Service + MCP Server — 6 phases, 47 plans executed
  - Phase 1: Docker stack (4 services), Alembic schema, seed data
  - Phase 2: OTP/email auth (Resend), JWT with roles, middleware
  - Phase 3: 7 feature slices, 35 REST endpoints, IDOR protection
  - Phase 4: MCP Server, 16 tools, student_id injection, action logging
  - Phase 5: LangChain ReAct agent, RAG pipeline, provider-agnostic LLM
  - Phase 6: WhatsApp webhook, end-to-end chatbot flow, chat visibility
- M2 (v2.0) complete: Flutter Frontend — 4 phases, 16 plans executed
  - Phase 7: Flutter scaffold, OTP auth, role-based navigation, GoRouter + Riverpod
  - Phase 8: 6 client screens (Dashboard, Chat, Documents, Notifications, Support)
  - Phase 9: 4 staff screens (Dashboard KPIs, Schedule, AI Data, Document Management)
  - Phase 10: Cross-platform polish — dark mode, responsive layouts, shared UX widgets, TTL cache, accessibility

## Evolution

Este documento evolui a cada transição de fase e marco de milestone.

**Após cada transição de fase** (via `/gsd-transition`):
1. Requirements invalidados? → Mover para Out of Scope com razão
2. Requirements validados? → Mover para Validated com referência da fase
3. Novos requirements emergiram? → Adicionar em Active
4. Decisões a registrar? → Adicionar em Key Decisions
5. "What This Is" ainda preciso? → Atualizar se driftar

**Após cada milestone** (via `/gsd-complete-milestone`):
1. Revisão completa de todas as seções
2. Core Value check — ainda é a prioridade certa?
3. Auditar Out of Scope — razões ainda válidas?
4. Atualizar Context com estado atual

---
*Last updated: 2026-05-11 — Phase 17 (UI Polish) complete, bottom nav animations fixed (StatefulWidget + AnimationController), light mode glow retuned (neonTealLight #00838F), login logo enlarged to 180px with neon glow*
