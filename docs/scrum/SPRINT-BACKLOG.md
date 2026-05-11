# Sprint Backlog — Desafio FCG3

**Projeto:** Plataforma Academica com Chatbot WhatsApp  
**Scrum Master:** [Nome]  
**Equipe:** 6 membros  
**Sprints:** 4 (Planejamento + Execucao + Demonstracao + Polimento)  
**Periodo total:** 08/04/2026 a 14/05/2026  
**Ultima atualizacao:** 2026-05-11  
**Total geral de tarefas:** 210+ | **Total SP geral:** 375 SP | 341 entregues (91%) | 34 SP maximo (Phases 23-24)  

---

## Sprint 1 — Planejamento (Retroativa)

**Periodo:** 08/04/2026 a 23/04/2026 (16 dias)  
**Sprint Goal:** Definir escopo, requisitos, arquitetura e planos de execucao detalhados para todas as 6 fases do backend + AI + MCP.  
**Velocidade realizada:** 0 SP (planning sprint — no code delivered)  
**Status:** Concluida

### Tarefas Sprint 1

| # | Tarefa | Responsavel | Status |
|---|--------|-------------|--------|
| T-001 | Pesquisa de ecossistema e dominio | Equipe | Done |
| T-002 | Definicao de 69 requisitos (REQUIREMENTS.md) | Equipe | Done |
| T-003 | Roadmap com 6 fases (ROADMAP.md) | Equipe | Done |
| T-004 | 44 planos de execucao detalhados | Tech Lead | Done |
| T-005 | Validacao de arquitetura e threat models | Tech Lead | Done |
| T-006 | Contexto das 6 fases capturado | Equipe | Done |

**Total Sprint 1:** 6 entregas de planejamento | 0 SP entregues

---

## Sprint 2 — Execucao (Retroativa)

**Periodo:** 23/04/2026 a 30/04/2026 (8 dias)  
**Sprint Goal:** Implementar todo o backend (API REST, MCP Server, AI Service, WhatsApp Webhook) com o fluxo end-to-end funcional em ambiente Docker local.  
**Velocidade realizada:** 193 SP em 8 dias = 24.1 SP/dia  
**Equipe ativa:** 1 membro (Tech Lead)  
**Status:** Concluida (com 1 gap remanescente no RAG threshold)

### Tarefas Sprint 2

| # | Tarefa | User Story | Responsavel | Estimativa (h) | Real (h) | Status |
|---|--------|-----------|-------------|---------------|---------|--------|
| T-001 | Definir docker-compose.yml com 4 servicos e healthchecks | US-001 | Tech Lead | 4 | 3 | Done |
| T-002 | Configurar redes app-network e data-network | US-001 | Tech Lead | 2 | 1 | Done |
| T-003 | Criar hot-reload com bind mounts para desenvolvimento | US-001 | Tech Lead | 2 | 2 | Done |
| T-004 | Configurar Alembic com async engine | US-002 | Tech Lead | 4 | 3 | Done |
| T-005 | Migration #001: extensao pgvector | US-002 | Tech Lead | 1 | 0.5 | Done |
| T-006 | Migrations #002-#009: todas as tabelas da aplicacao | US-002 | Tech Lead | 8 | 6 | Done |
| T-007 | Criar index HNSW em knowledge_base_chunks.embedding | US-002 | Tech Lead | 1 | 0.5 | Done |
| T-008 | Documentar variaveis de ambiente em .env.example | US-003 | Tech Lead | 2 | 2 | Done |
| T-009 | Criar settings.py com Pydantic BaseSettings | US-003 | Tech Lead | 2 | 2 | Done |
| T-010 | Implementar script seed destrutivo (curriculo + fixtures) | US-004 | Tech Lead | 4 | 3 | Done |
| T-011 | Criar endpoint POST /auth/request-code | US-005 | Tech Lead | 3 | 2 | Done |
| T-012 | Integrar Resend SDK para envio de email OTP | US-005 | Tech Lead | 2 | 2 | Done |
| T-013 | Implementar rate limiting com SlowAPI | US-005 | Tech Lead | 2 | 2 | Done |
| T-014 | Criar endpoint POST /auth/verify-code | US-006 | Tech Lead | 4 | 3 | Done |
| T-015 | Implementar logica de tentativas (3 max + invalidacao) | US-006 | Tech Lead | 3 | 2 | Done |
| T-016 | Gerar JWT com role + jti + sessao no banco | US-006 | Tech Lead | 3 | 2 | Done |
| T-017 | Criar endpoint POST /auth/logout + revogacao por jti | US-007 | Tech Lead | 2 | 1.5 | Done |
| T-018 | Criar endpoint GET /auth/me | US-008 | Tech Lead | 1 | 0.5 | Done |
| T-019 | Implementar middleware get_current_user + require_role | US-009 | Tech Lead | 3 | 2 | Done |
| T-020 | Implementar dependency require_service_token | US-009 | Tech Lead | 2 | 1 | Done |
| T-021 | CRUD de alunos (list, create, update, soft-delete) | US-010 | Tech Lead | 6 | 5 | Done |
| T-022 | Endpoint resumo academico com calculo de CRA | US-011 | Tech Lead | 4 | 4 | Done |
| T-023 | Endpoint disciplinas disponiveis com filtro de pre-requisitos | US-012 | Tech Lead | 4 | 3 | Done |
| T-024 | Listagem de disciplinas + detalhe + arvore CTE recursiva | US-013 | Tech Lead | 6 | 5 | Done |
| T-025 | Corrigir bug de ciclo na arvore de pre-requisitos | US-013 | Tech Lead | 3 | 2 | Done |
| T-026 | Fluxo completo de matricula (draft -> confirm -> lock) | US-014 | Tech Lead | 8 | 7 | Done |
| T-027 | Validacoes: periodo ativo, pre-requisitos, duplicatas | US-014 | Tech Lead | 4 | 3 | Done |
| T-028 | Check constraint migration para status 'locked' | US-014 | Tech Lead | 2 | 2 | Done |
| T-029 | CRUD periodos de matricula (staff) | US-015 | Tech Lead | 3 | 2 | Done |
| T-030 | Endpoints de notas por disciplina/periodo + historico | US-016 | Tech Lead | 4 | 3 | Done |
| T-031 | Endpoint staff lancar/atualizar notas | US-017 | Tech Lead | 3 | 2 | Done |
| T-032 | Endpoints documentos: solicitar, listar, detalhe | US-018 | Tech Lead | 4 | 3 | Done |
| T-033 | Endpoint staff atualizar status documento | US-019 | Tech Lead | 2 | 1.5 | Done |
| T-034 | Endpoints agendamento: slots, booking (SELECT FOR UPDATE), cancel | US-020 | Tech Lead | 6 | 5 | Done |
| T-035 | Endpoint staff criar slots | US-021 | Tech Lead | 2 | 1.5 | Done |
| T-036 | Dashboard staff com KPIs agregados | US-022 | Tech Lead | 3 | 2 | Done |
| T-037 | Scaffold MCP Server com FastMCP | US-023 | Tech Lead | 4 | 3 | Done |
| T-038 | Implementar 7 tools read-only (Group A) | US-023 | Tech Lead | 6 | 4 | Done |
| T-039 | Implementar 9 tools write/action (Group B) | US-023 | Tech Lead | 8 | 6 | Done |
| T-040 | Implementar injecao de student_id por sessao | US-024 | Tech Lead | 4 | 3 | Done |
| T-041 | Implementar middleware de logging (mcp_action_logs) | US-025 | Tech Lead | 3 | 2 | Done |
| T-042 | Validacao X-Service-Token no MCP | US-026 | Tech Lead | 2 | 1 | Done |
| T-043 | Logica de retry (1x para 5xx, nenhum para 4xx) | US-027 | Tech Lead | 2 | 1.5 | Done |
| T-044 | Scaffold AI Service (FastAPI + config + LLM factory) | US-028 | Tech Lead | 4 | 3 | Done |
| T-045 | Implementar agente ReAct com MCP tool binding | US-028 | Tech Lead | 6 | 5 | Done |
| T-046 | Endpoint /chat com persistencia de mensagens | US-028 | Tech Lead | 4 | 3 | Done |
| T-047 | Implementar memoria de conversa (k=20) do banco | US-029 | Tech Lead | 3 | 2 | Done |
| T-048 | Implementar RAG pipeline com PGVector | US-030 | Tech Lead | 4 | 3 | Done |
| T-049 | Script de ingest (chunking + embeddings) | US-031 | Tech Lead | 4 | 3 | Done |
| T-050 | Webhook GET (challenge verification) | US-033 | Tech Lead | 1 | 0.5 | Done |
| T-051 | Webhook POST (HMAC validation + message parsing) | US-033 | Tech Lead | 4 | 3 | Done |
| T-052 | Background task com asyncio.create_task + done_callback | US-034 | Tech Lead | 3 | 2 | Done |
| T-053 | Per-session lock + retry + fallback response | US-034 | Tech Lead | 3 | 2 | Done |
| T-054 | Handler de mensagens de midia (resposta padrao) | US-035 | Tech Lead | 2 | 1 | Done |
| T-055 | Deduplicacao por whatsapp_message_id + indice parcial | US-036 | Tech Lead | 2 | 1.5 | Done |
| T-056 | Endpoints staff: chat sessions, messages, MCP logs | US-037 | Tech Lead | 4 | 3 | Done |
| T-057 | Testes automatizados webhook (HMAC, dedup, midia) | US-047 | Tech Lead | 4 | 3 | Done |
| T-058 | Testes automatizados service token e IDOR | US-047 | Tech Lead | 3 | 2 | Done |
| T-059 | Gap closures diversos (imports, Docker, credentials) | — | Tech Lead | 12 | 12 | Done |

**Total Sprint 2:** 59 tarefas | Estimado: 207h | Real: ~163h

---

## Sprint 3 — Demonstracao

**Periodo:** 01/05/2026 a 06/05/2026 (6 dias)  
**Sprint Goal:** Tornar o sistema demonstravel — fix do RAG, frontend minimo, deploy no servidor, guardrails do chatbot, e todos os artefatos Scrum completos para apresentacao do dia 06/05.  
**Capacidade estimada:** 40 SP / 6 membros / 5 dias = ~6.5 SP/membro  
**Story Points:** 40 SP planejados / 40 SP entregues (100%)  
**Status:** Concluida

### Tarefas Sprint 3

| # | Tarefa | User Story | Responsavel | Estimativa (h) | Status | Dia |
|---|--------|-----------|-------------|---------------|--------|-----|
| **RAG + MCP Fix (Tech Lead)** |
| T-060 | Adicionar RAG_SIMILARITY_THRESHOLD ao config.py (default 0.45) | US-030 | Tech Lead | 1 | Done | 1 |
| T-061 | Refatorar rag.py para aceitar threshold como parametro | US-030 | Tech Lead | 1 | Done | 1 |
| T-062 | Passar settings.RAG_SIMILARITY_THRESHOLD no agent.py | US-030 | Tech Lead | 0.5 | Done | 1 |
| T-063 | Atualizar/criar testes do RAG threshold | US-030 | Tech Lead | 1 | Done | 1 |
| T-064 | Adicionar gen_random_uuid() no INSERT de mcp_action_logs | US-032 | Tech Lead | 0.5 | Done | 1 |
| T-065 | Atualizar testes do middleware MCP | US-032 | Tech Lead | 0.5 | Done | 1 |
| T-066 | Testar RAG end-to-end (ingest + query) | US-030 | Tech Lead | 1 | Done | 1 |
| **Deploy (Tech Lead)** |
| T-067 | Instalar Docker e Docker Compose no servidor | US-043 | Tech Lead | 2 | Done | 1-2 |
| T-068 | Clonar repo e configurar .env no servidor | US-043 | Tech Lead | 1 | Done | 2 |
| T-069 | Executar docker compose up no servidor | US-043 | Tech Lead | 2 | Done | 2 |
| T-070 | Configurar DNS/ngrok para webhook WhatsApp | US-043 | Tech Lead | 3 | Done | 3-4 |
| T-071 | Rodar alembic upgrade + seed + ingest no servidor | US-043 | Tech Lead | 1 | Done | 2 |
| T-072 | Teste end-to-end WhatsApp -> servidor -> resposta | US-044 | Tech Lead | 2 | Done | 4-5 |
| **Frontend Login (Membro 1)** |
| T-073 | Criar tela de input de email (UI) | US-038 | Membro 1 | 3 | Done | 1 |
| T-074 | Implementar chamada POST /auth/request-code | US-038 | Membro 1 | 2 | Done | 1-2 |
| T-075 | Criar tela de input de OTP (6 digitos) | US-038 | Membro 1 | 3 | Done | 2 |
| T-076 | Implementar chamada POST /auth/verify-code | US-038 | Membro 1 | 2 | Done | 2-3 |
| T-077 | Armazenar JWT (flutter_secure_storage) | US-038 | Membro 1 | 2 | Done | 3 |
| T-078 | Navegacao pos-login para Dashboard | US-038 | Membro 1 | 1 | Done | 3 |
| T-079 | Tratamento de erros (codigo invalido, expirado) | US-038 | Membro 1 | 2 | Done | 4 |
| T-080 | Loading states e feedback visual | US-040 | Membro 1 | 2 | Done | 4-5 |
| **Frontend Dashboard (Membro 2)** |
| T-081 | Criar tela Dashboard com layout (AppBar + body) | US-039 | Membro 2 | 3 | Done | 1 |
| T-082 | Implementar chamada GET /students/{id}/academic-summary | US-039 | Membro 2 | 2 | Done | 1-2 |
| T-083 | Card de resumo academico (semestre, CRA, status) | US-039 | Membro 2 | 2 | Done | 2 |
| T-084 | Lista de disciplinas disponiveis (GET /students/{id}/available-courses) | US-039 | Membro 2 | 3 | Done | 2-3 |
| T-085 | Lista de notas (GET /students/{id}/grades) | US-039 | Membro 2 | 3 | Done | 3 |
| T-086 | Botao de logout (POST /auth/logout + limpar storage) | US-039 | Membro 2 | 1 | Done | 3 |
| T-087 | Tratamento de erros e token expirado (redirect login) | US-040 | Membro 2 | 2 | Done | 4 |
| T-088 | Loading states e pull-to-refresh | US-040 | Membro 2 | 2 | Done | 4-5 |
| **Knowledge Base (Membro 3)** |
| T-089 | Escrever/revisar matricula.md (regras reais do curso) | US-031 | Membro 3 | 3 | Done | 1 |
| T-090 | Escrever/revisar faq.md (15-20 perguntas) | US-031 | Membro 3 | 3 | Done | 1-2 |
| T-091 | Escrever/revisar calendario.md (datas academicas) | US-031 | Membro 3 | 2 | Done | 2 |
| T-092 | Escrever/revisar curriculo.md (grade completa) | US-031 | Membro 3 | 2 | Done | 2-3 |
| T-093 | Rodar ingest e validar que chunks foram criados | US-031 | Membro 3 | 1 | Done | 3 |
| T-094 | Testar 10 queries no RAG e documentar resultados | US-030 | Membro 3 | 3 | Done | 3-4 |
| T-095 | Testar privacidade: aluno A nao acessa dados de B | US-042 | Membro 3 | 2 | Done | 4 |
| T-096 | Documentar score de similaridade por query (planilha) | US-030 | Membro 3 | 2 | Done | 4-5 |
| **Prompt Engineering (Membro 4)** |
| T-097 | Revisar system prompt atual do agente | US-041 | Membro 4 | 2 | Done | 1 |
| T-098 | Adicionar instrucoes anti-injection no system prompt | US-041 | Membro 4 | 3 | Done | 1-2 |
| T-099 | Adicionar instrucoes de escopo (so academico) | US-041 | Membro 4 | 2 | Done | 2 |
| T-100 | Testar 10 cenarios de prompt injection | US-041 | Membro 4 | 3 | Done | 2-3 |
| T-101 | Testar tom e linguagem (PT-BR institucional) | US-041 | Membro 4 | 2 | Done | 3 |
| T-102 | Testar cenarios de privacidade via prompt | US-042 | Membro 4 | 2 | Done | 3-4 |
| T-103 | Documentar limitacoes conhecidas do chatbot | US-041 | Membro 4 | 2 | Done | 4 |
| T-104 | Criar "perguntas seguras" para demo (roteiro) | US-041 | Membro 4 | 1 | Done | 5 |
| **Scrum + Apresentacao (Membro 5)** |
| T-105 | Montar Product Backlog visual (Trello/Notion) | — | Membro 5 | 3 | Done | 1 |
| T-106 | Montar Sprint Backlog visual com horas | — | Membro 5 | 2 | Done | 1 |
| T-107 | Criar Kanban Board com todas as tarefas | — | Membro 5 | 2 | Done | 1-2 |
| T-108 | Criar Burndown Chart (retroativo + sprint 3) | — | Membro 5 | 3 | Done | 2 |
| T-109 | Escrever Definition of Done formal | — | Membro 5 | 1 | Done | 2 |
| T-110 | Montar slides da apresentacao | — | Membro 5 | 4 | Done | 3-4 |
| T-111 | Escrever roteiro da demo (passo a passo) | — | Membro 5 | 2 | Done | 4 |
| T-112 | Ensaio da apresentacao com o time | — | Membro 5 | 2 | Done | 5 |

**Total Sprint 3:** 53/53 tarefas concluidas (100%) | 40/40 SP entregues | 6 membros | 6 dias

---

## Resumo por Membro (Sprint 3)

| Membro | Tarefas | Horas Estimadas | SP |
|--------|---------|-----------------|-----|
| Tech Lead | 13 tarefas | ~17h | 16 |
| Membro 1 (Flutter Login) | 8 tarefas | ~17h | 8 |
| Membro 2 (Flutter Dashboard) | 8 tarefas | ~18h | 11 |
| Membro 3 (Knowledge Base) | 8 tarefas | ~18h | 8 |
| Membro 4 (Prompt/Guardrails) | 8 tarefas | ~17h | 8 |
| Membro 5 (Scrum/Apresentacao) | 8 tarefas | ~19h | — |

---

## Dependencias Criticas (Sprint 3)

```
T-060/T-064 (RAG fix) ──> T-093 (ingest) ──> T-094 (teste RAG)
                                            ──> T-100 (teste injection)

T-069 (deploy servidor) ──> T-070 (webhook DNS) ──> T-072 (E2E test)

T-078 (nav pos-login) ──> depende de T-081 (dashboard pronto)

T-104 (perguntas demo) ──> T-111 (roteiro demo) ──> T-112 (ensaio)
```

---

## Impedimentos Conhecidos

| # | Impedimento | Impacto | Responsavel | Status |
|---|-------------|---------|-------------|--------|
| IMP-01 | Docker pode nao estar no servidor do Kenji | Bloqueia deploy | Tech Lead | Resolvido |
| IMP-02 | Chave OpenAI para embeddings pode nao funcionar | Bloqueia ingest | Tech Lead | Resolvido |
| IMP-03 | Meta webhook verification pode falhar sem HTTPS | Bloqueia E2E | Tech Lead | Resolvido (ngrok) |

---

## Sprint 4 — v3.0 Correcoes, Melhorias & Features

**Status:** Em andamento (Active)
**Periodo:** 2026-05-07 a 2026-05-14 (8 dias)
**Goal:** Completar milestone v3.0 — UX corrections estudante/staff, AI workflow Alpha, auth expansion, FCM push, novas features (cardapio, perfil, grade)
**Story Points:** 152 SP planejados | 118 SP entregues ate 09/05 | 34 SP em andamento/projecao
**Membros:** 6 (trabalho paralelo por grupos)
**Commits estimados apos merge:** ~737 (559 main + ~178 das branches)

### Fase A — Polimento Final (07/05) — CONCLUIDA

| # | ID | Descricao | Epic | SP | Assignee | Status | Phase |
|---|----|-----------|------|----|----------|--------|-------|
| 1 | T-113 | Verificar rastreabilidade 47/47 requisitos | Docs | 2 | Tech Lead | Done | Phase 15 |
| 2 | T-114 | Atualizar ROADMAP.md com Phase 15 concluida | Docs | 1 | Tech Lead | Done | Phase 15 |
| 3 | T-115 | Verificar CR-01/CR-02: QueuedInterceptor | Frontend | 2 | Tech Lead | Done | Phase 16 |
| 4 | T-116 | Verificar CR-03 + rodar 244 testes | Frontend | 2 | Tech Lead | Done | Phase 16 |
| 5 | T-117 | Criar AppSkeletonChat + 4 testes widget | Frontend | 3 | Tech Lead | Done | Phase 17 |
| 6 | T-118 | Substituir spinners por skeleton nos chat screens | Frontend | 2 | Tech Lead | Done | Phase 17 |

**Fase A total:** 6 tasks | 10 SP | Done

### Fase B — UX Corrections (08-09/05) — CONCLUIDA (branch pendente merge)

**Grupo 1 (Paralelo) — Phase 18: Student UX Corrections**

| # | ID | Descricao | Epic | SP | Assignee | Status |
|---|----|-----------|------|----|----------|--------|
| 7 | T-119 | Fix quick actions home + remove Avisos nav + add notif icon | UX | 2 | Membro 2 | Done |
| 8 | T-120 | Chat rename long-press + filter tabs ativo/inativo + date order | UX | 3 | Membro 2 | Done |
| 9 | T-121 | Document cards com tipo+data; tap abre detail bottom sheet | UX | 3 | Membro 2 | Done |
| 10 | T-122 | Notificacoes read/unread state + filter tabs + bulk mark-as-read | UX | 3 | Membro 3 | Done |
| 11 | T-123 | Appointment detail bottom sheet widget + wire home/notif | UX | 2 | Membro 3 | Done |
| 12 | T-124 | Agendamentos quick action navega p/ /client/resources?tab=1 | UX | 2 | Membro 3 | Done |
| 13 | T-125 | Backend: PUT /chat-sessions/{id} rename + Alembic 014 | Backend | 4 | Membro 2 | Done |

**Grupo 1 (Paralelo) — Phase 19: Staff UX Corrections**

| # | ID | Descricao | Epic | SP | Assignee | Status |
|---|----|-----------|------|----|----------|--------|
| 14 | T-126 | Dashboard KPI navigation + AI rate truncation + Acoes Rapidas | UX | 3 | Membro 1 | Done |
| 15 | T-127 | Appointment cards redesign + StaffSearchBar widget + detail fields | UX | 3 | Membro 1 | Done |
| 16 | T-128 | Unified StaffChatsScreen (4 tabs) + chat detail header | UX | 4 | Membro 4 | Done |
| 17 | T-129 | Documents screen abas corretas + type filter + detail sheet | UX | 3 | Membro 4 | Done |
| 18 | T-130 | Resources: toggle Switch + Deletar popup + confirmation dialog | UX | 2 | Membro 5 | Done |
| 19 | T-131 | StaffCadastroScreen CRUD (model, service, provider, screen, form) | UX | 5 | Membro 5 | Done |
| 20 | T-132 | Backend: AppointmentListItem + student/resource fields + joinedload | Backend | 3 | Membro 1 | Done |
| 21 | T-133 | Backend: ChatSessionResponse student_name/RA; is_deleted on resources + Alembic 015 | Backend | 4 | Membro 1 | Done |
| 22 | T-134 | Backend: StudentListItem + phone field; form field mapping fixes | Backend | 2 | Membro 4 | Done |

**Fases B total:** 16 tasks | 41 SP | Done (branches pendentes merge)

### Fase C — Melhorias AI/Auth/FCM (08-09/05) — CONCLUIDA (branches pendentes merge)

**Grupo 2a — Phase 20: LangChain Workflow**

| # | ID | Descricao | Epic | SP | Assignee | Status |
|---|----|-----------|------|----|----------|--------|
| 23 | T-135 | System prompt Alpha persona + media rejections | AI | 3 | Tech Lead | Done |
| 24 | T-136 | rag_logs table migration + RAG logging + LangSmith tracing | AI | 3 | Tech Lead | Done |
| 25 | T-137 | Entrypoint script RAG ingest on docker-compose up | AI | 2 | Tech Lead | Done |
| 26 | T-138 | Lazy OTP routing + mid-conversation trigger + state machine | AI | 5 | Tech Lead | Done |
| 27 | T-139 | Input sanitizer module (4-layer prompt injection defense) | AI | 8 | Tech Lead | Done |
| 28 | T-140 | Welcome message + farewell detection + idle timeout (5/10min) | AI | 8 | Tech Lead | Done |
| 29 | T-141 | Gap fix: stale OTP reset + accent normalization | AI | 2 | Tech Lead | Done |
| 30 | T-142 | Gap fix: plain-text formatting + personalized welcome name | AI | 2 | Tech Lead | Done |
| 31 | T-143 | Gap fix: farewell detection threshold tiered | AI | 2 | Tech Lead | Done |
| 32 | T-144 | Gap fix: timezone defense in stale OTP check | AI | 1 | Tech Lead | Done |
| 33 | T-145 | Gap fix: MCP verification gate + verification_state E2E | AI | 5 | Tech Lead | Done |

**Grupo 2b — Phase 21: Roles & Auth Expansion**

| # | ID | Descricao | Epic | SP | Assignee | Status |
|---|----|-----------|------|----|----------|--------|
| 34 | T-146 | Alembic 016 (provider role, staff columns) + auth dependencies | Auth | 3 | Membro 6 | Done |
| 35 | T-147 | 5 CRUD endpoints /staff/members + StaffManagementService | Auth | 5 | Membro 6 | Done |
| 36 | T-148 | UserModel isProvider getter + 6th Gestao tab + router guard | Auth | 2 | Membro 6 | Done |
| 37 | T-149 | StaffGestaoScreen + StaffMemberFormScreen + Riverpod provider | Auth | 3 | Membro 6 | Done |

**Grupo 2c — Phase 22: FCM Push Notifications**

| # | ID | Descricao | Epic | SP | Assignee | Status |
|---|----|-----------|------|----|----------|--------|
| 38 | T-150 | NotificationService (send_push, 3 triggers) + FcmToken CRUD | FCM | 4 | Membro 1 | Done |
| 39 | T-151 | Flutter Firebase setup + FcmService provider + auth lifecycle | FCM | 3 | Membro 1 | Done |
| 40 | T-152 | Backend notification triggers (asyncio.create_task) + 8 unit tests | FCM | 3 | Membro 1 | Done |
| 41 | T-153 | Flutter handlers foreground/background/cold-start + deep-link nav | FCM | 3 | Membro 1 | Done |

**Fase C total:** 19 tasks | 67 SP | Done (branches pendentes merge)

### Fase D — Novas Features (10-13/05) — EM ANDAMENTO / PROJECAO

| # | ID | Descricao | Epic | SP | Assignee | Status |
|---|----|-----------|------|----|----------|--------|
| 42 | T-154 | Backend: endpoint /cardapio + modelo + migration | Features | 3 | A definir | To Do |
| 43 | T-155 | Flutter: ClientCardapioScreen + tab no shell | Features | 4 | A definir | To Do |
| 44 | T-156 | Backend: PUT /students/{id}/profile | Features | 2 | A definir | To Do |
| 45 | T-157 | Flutter: ClientPerfilScreen + form de edicao | Features | 5 | A definir | To Do |
| 46 | T-158 | Backend: GET /students/{id}/grade-curricular | Features | 2 | A definir | To Do |
| 47 | T-159 | Flutter: ClientGradeCurricularScreen | Features | 5 | A definir | To Do |

### Fase E — UI Polish v3 (14/05) — PROJECAO

| # | ID | Descricao | Epic | SP | Assignee | Status |
|---|----|-----------|------|----|----------|--------|
| 48 | T-160 | Audit visual completo + correcoes overflow/contraste | Polish | 5 | Tech Lead | To Do |
| 49 | T-161 | Animacoes page transitions + consistencia visual | Polish | 4 | Tech Lead | To Do |
| 50 | T-162 | Testes E2E pos-merge + validacao integracao v3.0 | Polish | 4 | Tech Lead | To Do |

**Fases D+E total:** 9 tasks | 34 SP | To Do (planejado 10-14/Mai)

---

**Sprint 4 Resumo:**

| Fase | Periodo | Tasks | SP | Status |
|------|---------|-------|----|--------|
| A: Polimento | 07/05 | 6 | 10 | Done |
| B: UX Corrections | 08-09/05 | 16 | 41 | Done (branches) |
| C: AI/Auth/FCM | 08-09/05 | 19 | 67 | Done (branches) |
| D+E: Features+Polish | 10-14/05 | 9 | 34 | To Do (projecao) |
| **Total Sprint 4** | **07-14/05** | **50** | **152** | **Em andamento** |
