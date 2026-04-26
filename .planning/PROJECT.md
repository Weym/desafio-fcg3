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
- ✓ AI Service: pipeline RAG com threshold 0.75 e ingest da knowledge base em `ai_service/ingest.py` — validated in Phase 5
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

- Flutter mobile (app) — fora deste ciclo; foco é backend + AI + MCP
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

## Current State

- Phase 1 concluída: stack Docker de 4 serviços sobe localmente, schema da aplicação está migrado, e a base possui seed de desenvolvimento com currículo e fixtures acadêmicos.
- Phase 2 concluída: autenticação completa via OTP/email (Resend), JWT com roles (student/staff), refresh-token rotation com SELECT FOR UPDATE, middleware de auth (get_current_user, require_role, require_service_token), rate limiting via SlowAPI, 47 testes passando.
- Phase 3 concluída: 7 feature slices (Students, Courses, Enrollment, Grades, Documents, Appointments, Staff Dashboard) com 35 endpoints REST, IDOR protection, dual-auth (JWT + X-Service-Token), state machine enforcement, SELECT FOR UPDATE para booking e enrollment confirmation, CRA calculation, recursive CTE para prerequisite tree. Bug de SELECT FOR UPDATE com outer join corrigido em UAT.
- Phase 4 concluída: MCP Server com as 16 tools documentadas em `docs/mcp.md`, injeção de `student_id` por contexto de sessão, `mcp_action_logs`, gap closures 04-05/04-06 e audit Nyquist concluído em 2026-04-25.
- Phase 5 concluída: AI Service com agente LangChain ReAct, pipeline RAG, provider agnóstico, ingest da base de conhecimento, auditoria Nyquist fechada em `05-VALIDATION.md` e suíte `ai_service/tests` verde com `16 passed`.
- Próximo foco: Phase 6 (WhatsApp Webhook & Integration) — fluxo fim a fim do chatbot, hardening do webhook, visibilidade de chat e suite de integração.

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
*Last updated: 2026-04-26 after Phase 5 Nyquist audit closure*
