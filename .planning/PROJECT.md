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

### Active

**Infraestrutura:**

**Backend (FastAPI):**
- [ ] Matrículas: consultar, solicitar, confirmar, cancelar (com validação de período e pré-requisitos)
- [ ] Notas e histórico: consulta de notas por disciplina/período, IRA calculado
- [ ] Documentos: listagem e URL assinada para download
- [ ] Agendamentos: consultar, solicitar e cancelar horários com professores/coordenadores
- [ ] Webhook WhatsApp: validação HMAC-SHA256, save de mensagem, despacho assíncrono
- [ ] Testes: cobertura dos fluxos críticos (matrícula, webhook, middleware IDOR)

**AI Service (LangChain):**
- [ ] ReAct agent com ConversationBufferWindowMemory (k=20)
- [ ] RAG pipeline: PGVector retriever com threshold 0.75 cosine similarity
- [ ] LLM provider agnóstico — configurado via variável de ambiente (suporte a OpenAI e Gemini)
- [ ] Script de ingestão de knowledge base (`scripts/ingest.py`)
- [ ] Knowledge base inicial: `matricula.md`, `regulamento.pdf`, `faq.md`, `calendario.md`, `curriculo.md`
- [ ] Tratamento de mensagens de mídia (resposta padrão sem processar pelo agente)

**MCP Server:**
- [ ] 16 ferramentas documentadas em `docs/mcp.md` implementadas
- [ ] Injeção de `student_id` a partir do contexto de sessão (prevenção de IDOR)
- [ ] Log de cada chamada de tool em `mcp_action_logs` (params, resultado, latência, retry)
- [ ] Validação de `X-Service-Token` em todas as chamadas internas

### Out of Scope

- Flutter mobile (app) — fora deste ciclo; foco é backend + AI + MCP
- Push notifications FCM — adiar para ciclo seguinte
- Whisper API (transcrição de áudio) — pós-MVP
- GPT-4o Vision (análise de imagens) — pós-MVP
- Redis cache para sessões de conversa — pós-MVP
- pg_cron para limpeza automática de verification_codes — pós-MVP
- Sentry / monitoramento de erros externo — pós-MVP

## Context

- Monorepo: `backend/` (FastAPI), `mobile/` (Flutter), `ai_service/` e `mcp_server/` ainda não criados
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
| `student_id` injetado pelo MCP (nunca exposto ao agente) | Prevenção de IDOR — o agente não pode forjar student_id | — Pending |
| Agendamentos incluídos neste ciclo | Requisito confirmado pelo usuário | — Pending |

## Current State

- Phase 1 concluída: stack Docker de 4 serviços sobe localmente, schema da aplicação está migrado, e a base possui seed de desenvolvimento com currículo e fixtures acadêmicos.
- Phase 2 concluída: autenticação completa via OTP/email (Resend), JWT com roles (student/staff), refresh-token rotation com SELECT FOR UPDATE, middleware de auth (get_current_user, require_role, require_service_token), rate limiting via SlowAPI, 47 testes passando. Gap conhecido: D-08 enumeration timing (documentado em HUMAN-UAT).
- Próximo foco: Phase 3 (Business Feature Slices) — matrículas, notas, documentos, agendamentos.

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
*Last updated: 2026-04-24 after Phase 2 completion*
