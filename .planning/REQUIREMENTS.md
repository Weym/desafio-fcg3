# Requirements — Desafio FCG3

**Version:** 1.0
**Milestone:** M1 — Backend + AI Service + MCP Server
**Date:** 2026-04-15

---

## v1 Requirements

### Infraestrutura

- [x] **INFRA-01**: Sistema pode ser iniciado com `docker compose up` — 4 containers sobem com healthchecks (postgres+pgvector, fastapi-app, langchain-service, mcp-server)
- [x] **INFRA-02**: Schema completo do banco (17 tabelas + HNSW index) é criado via Alembic migrations (migration #001: extensão pgvector)
- [ ] **INFRA-03**: `.env.example` documenta todas as variáveis de ambiente necessárias (DATABASE_URL, MCP_SERVICE_TOKEN, WHATSAPP_TOKEN, WHATSAPP_APP_SECRET, RESEND_API_KEY, LLM_PROVIDER, LLM_MODEL, OPENAI_API_KEY)
- [x] **INFRA-04**: Seed data do currículo de Ciência da Computação (8 períodos, ~40 disciplinas com pré-requisitos) está disponível e pode ser executado via script

---

### Autenticação

- [ ] **AUTH-01**: Aluno ou staff pode solicitar código OTP de 6 dígitos enviado por email via Resend (expira em 5 minutos)
- [ ] **AUTH-02**: Aluno ou staff pode verificar código e receber JWT com campo `role` (student | staff) e `jti` único
- [ ] **AUTH-03**: Sistema invalida o código após 3 tentativas incorretas e envia novo código automaticamente; códigos expirados não incrementam o contador
- [ ] **AUTH-04**: Usuário autenticado pode encerrar sessão (JWT revogado por `jti` na tabela `sessions`)
- [ ] **AUTH-05**: Usuário autenticado pode consultar seus próprios dados (`GET /auth/me`)

---

### Students (Alunos)

- [ ] **STU-01**: Staff pode listar alunos com paginação e filtros (busca por nome, semestre, status)
- [ ] **STU-02**: Staff pode criar aluno (nome, email, telefone, número de matrícula, currículo)
- [ ] **STU-03**: Staff pode atualizar dados de um aluno
- [ ] **STU-04**: Staff pode desativar aluno (soft delete — status: inactive)
- [ ] **STU-05**: Aluno ou staff pode consultar detalhe de um aluno
- [ ] **STU-06**: Sistema retorna resumo acadêmico do aluno (semestre, disciplinas concluídas, CRA, status, documentos pendentes, próximo agendamento) — endpoint usado pelo MCP `get_student_info`
- [ ] **STU-07**: Sistema retorna disciplinas disponíveis para matrícula do aluno respeitando pré-requisitos — endpoint usado pelo MCP `get_available_courses`

---

### Courses & Curriculum (Disciplinas e Currículo)

- [ ] **COURSE-01**: Usuário autenticado pode listar disciplinas com filtro por nome e período
- [ ] **COURSE-02**: Usuário autenticado pode consultar detalhes de uma disciplina incluindo créditos, carga horária e pré-requisitos diretos
- [ ] **COURSE-03**: Sistema retorna árvore completa de pré-requisitos de uma disciplina (recursivo via CTE) — endpoint usado pelo MCP `get_course_prerequisites`
- [ ] **CURR-01**: Sistema retorna currículo ativo com disciplinas organizadas por período — endpoint usado pelo MCP `get_curriculum`
- [ ] **CURR-02**: Usuário autenticado pode consultar um currículo específico por ID

---

### Enrollment (Matrículas)

- [ ] **ENROLL-01**: Sistema retorna período de matrícula ativo (datas, semestre letivo, status) — endpoint usado pelo MCP `get_enrollment_period`
- [ ] **ENROLL-02**: Aluno pode criar matrícula em rascunho com uma ou mais disciplinas durante período ativo
- [ ] **ENROLL-03**: Aluno pode confirmar matrícula (draft → confirmed) durante período ativo
- [ ] **ENROLL-04**: Aluno pode modificar disciplinas de uma matrícula enquanto em draft
- [ ] **ENROLL-05**: Aluno pode remover disciplina individual de uma matrícula — endpoint usado pelo MCP `drop_course`
- [ ] **ENROLL-06**: Aluno pode trancar a matrícula inteira do período — endpoint usado pelo MCP `lock_enrollment`
- [ ] **ENROLL-07**: Aluno pode listar suas matrículas com filtro por semestre e status
- [ ] **ENROLL-08**: Sistema bloqueia criação de matrícula fora do período ativo, com disciplinas cujos pré-requisitos não foram cumpridos, ou com disciplinas duplicadas
- [ ] **ENROLL-STAFF-01**: Staff pode criar período de matrícula (nome, tipo, datas de início/fim, semestre letivo)
- [ ] **ENROLL-STAFF-02**: Staff pode atualizar período de matrícula (incluindo ativar/desativar)
- [ ] **ENROLL-STAFF-03**: Staff pode listar todos os períodos de matrícula

---

### Grades (Notas)

- [ ] **GRADES-01**: Aluno pode consultar suas notas por disciplina e período letivo
- [ ] **GRADES-02**: Aluno pode consultar histórico escolar completo com todas as disciplinas e notas
- [ ] **GRADES-03**: Sistema calcula e retorna CRA ponderado por créditos (exclui disciplinas em andamento e trancadas; protegido contra divisão por zero)
- [ ] **GRADES-04**: Staff pode lançar ou atualizar notas (N1, N2) de um aluno em uma disciplina; nota final é calculada automaticamente

---

### Documents (Documentos)

- [ ] **DOCS-01**: Aluno pode listar seus documentos com filtro por tipo e status
- [ ] **DOCS-02**: Aluno pode consultar detalhe de um documento, incluindo URL de download quando status=ready
- [ ] **DOCS-03**: Aluno pode solicitar emissão de documento (transcript, enrollment_proof, declaration, certificate) — endpoint usado pelo MCP `request_document`
- [ ] **DOCS-04**: Staff pode atualizar status de um documento e vincular a URL do arquivo gerado

---

### Scheduling (Agendamentos)

- [ ] **APPT-01**: Aluno pode consultar slots de atendimento disponíveis com filtro por data e responsável — endpoint usado pelo MCP `get_available_slots`
- [ ] **APPT-02**: Aluno pode agendar atendimento em um slot disponível com motivo (SELECT FOR UPDATE no slot para evitar race condition) — endpoint usado pelo MCP `book_appointment`
- [ ] **APPT-03**: Aluno pode cancelar um agendamento próprio — endpoint usado pelo MCP `cancel_appointment`
- [ ] **APPT-04**: Aluno ou staff pode listar agendamentos com filtro por status
- [ ] **APPT-STAFF-01**: Staff pode criar slots de atendimento (data, horário início/fim, duração por slot em minutos)

---

### Staff Dashboard & CRM

- [ ] **STAFF-01**: Staff pode consultar dashboard com KPIs: total de alunos, matrículas ativas, documentos pendentes, agendamentos futuros, sessões de chat ativas, status do período de matrícula

---

### Webhook & Chat (WhatsApp)

- [ ] **WH-01**: Sistema recebe mensagens do WhatsApp e valida assinatura HMAC-SHA256 (`X-Hub-Signature-256`) antes de qualquer processamento
- [ ] **WH-02**: Sistema responde 200 OK em < 5 segundos e despacha processamento da mensagem em background com `asyncio.create_task` + `add_done_callback` para visibilidade de falhas
- [ ] **WH-03**: Sistema trata mensagens de mídia (áudio, imagem, vídeo, documento, sticker, localização) com resposta padrão sem passar pelo agente; tipo de mídia é registrado em `chat_messages`
- [ ] **WH-04**: Sistema deduplica mensagens por `whatsapp_message_id` — mensagem com ID já existente é ignorada
- [ ] **WH-05**: Sistema responde ao challenge de verificação do webhook WhatsApp (`GET /webhook/whatsapp` com `hub.challenge`)
- [ ] **CHAT-01**: Staff pode listar sessões de chat com filtro por aluno e status
- [ ] **CHAT-02**: Usuário autenticado pode listar mensagens de uma sessão de chat
- [ ] **CHAT-03**: Staff pode consultar logs MCP de uma sessão de chat (tool_name, params, resultado, reasoning, latência)

---

### MCP Server

- [ ] **MCP-01**: MCP Server implementa as 16 ferramentas documentadas em `docs/mcp.md` via Streamable HTTP transport
- [ ] **MCP-02**: MCP Server injeta `student_id` do contexto da sessão ativa em todas as tools que operam sobre dados do aluno — `student_id` nunca aparece nos schemas das tools
- [ ] **MCP-03**: Cada chamada de tool gera registro em `mcp_action_logs` com tool_name, input_params (sem student_id), output_result, reasoning, latency_ms, retry e status
- [ ] **MCP-04**: Chamadas internas à API são autenticadas via `X-Service-Token`; comparação usa `hmac.compare_digest` (constant-time)
- [ ] **MCP-05**: Em caso de falha 5xx ou timeout, MCP realiza uma única retentativa imediata; erros 4xx não geram retry

---

### AI Service (LangChain)

- [ ] **AI-01**: Agente ReAct processa mensagens de texto, decide quais MCP tools chamar e gera resposta em português
- [ ] **AI-02**: Memória de conversa é reconstruída do banco a cada invocação (últimas 20 mensagens da sessão) — não depende de estado em memória
- [ ] **AI-03**: RAG busca chunks relevantes no PGVector com threshold de distância coseno calibrado (baseline: ≤ 0.25 de distância = ≥ 0.75 de similaridade)
- [ ] **AI-04**: LLM provider é configurável via variável de ambiente `LLM_PROVIDER` (valores: `openai`, `gemini`) — troca de provider não requer alteração de código
- [ ] **AI-05**: Script `scripts/ingest.py` ingere documentos da knowledge base (`matricula.md`, `regulamento.pdf`, `faq.md`, `calendario.md`, `curriculo.md`) gerando embeddings e armazenando chunks no PGVector

---

### Testes

- [ ] **TEST-01**: Testes de integração cobrem fluxo de auth completo (OTP → JWT → logout → token revogado; esgotamento de tentativas → novo código enviado)
- [ ] **TEST-02**: Testes de integração cobrem matrícula (draft-confirm, pré-requisito não cumprido, período fechado, ownership check / prevenção de IDOR)
- [ ] **TEST-03**: Testes unitários cobrem cálculo de CRA (ponderação por créditos, exclusão de em andamento, divisão por zero)
- [ ] **TEST-04**: Testes de integração cobrem webhook (HMAC válido, HMAC inválido → 403, deduplicação por wamid, rota de mídia)
- [ ] **TEST-05**: Testes de integração cobrem middleware X-Service-Token (token ausente → 401, token inválido → 401) e prevenção de IDOR nos endpoints MCP

---

## v2 Requirements (Deferred)

- Push notifications via FCM (registro de token, envio de notificação)
- Cache de sessões de conversa em Redis (sessões ativas não precisam recarregar do banco)
- Limpeza automática de verification_codes e sessions expiradas via pg_cron
- Transcrição de áudio via Whisper API
- Análise de imagens via GPT-4o Vision
- URL de download de documentos com expiração (signed URLs)

---

## Out of Scope

- Flutter mobile app — foco deste ciclo é backend + AI + MCP
- Staff não recebe push notifications no MVP
- Administração da knowledge base via UI — ingestão via script apenas
- Progressão automática de semestre dos alunos — atualização manual via staff
- Waiver de pré-requisitos — sistema não permite exceções no MVP
- Monitoramento externo (Sentry, Datadog) — logging estruturado via stdout

---

## Traceability

*Mapeamento de requisitos para fases do roadmap — gerado pelo roadmapper em 2026-04-15.*

| REQ-ID | Fase | Status |
|--------|------|--------|
| INFRA-01 | Phase 1: Infrastructure & Schema | Complete |
| INFRA-02 | Phase 1: Infrastructure & Schema | Complete |
| INFRA-03 | Phase 1: Infrastructure & Schema | Pending |
| INFRA-04 | Phase 1: Infrastructure & Schema | Complete |
| AUTH-01 | Phase 2: Authentication | Pending |
| AUTH-02 | Phase 2: Authentication | Pending |
| AUTH-03 | Phase 2: Authentication | Pending |
| AUTH-04 | Phase 2: Authentication | Pending |
| AUTH-05 | Phase 2: Authentication | Pending |
| STU-01 | Phase 3: Business Feature Slices | Pending |
| STU-02 | Phase 3: Business Feature Slices | Pending |
| STU-03 | Phase 3: Business Feature Slices | Pending |
| STU-04 | Phase 3: Business Feature Slices | Pending |
| STU-05 | Phase 3: Business Feature Slices | Pending |
| STU-06 | Phase 3: Business Feature Slices | Pending |
| STU-07 | Phase 3: Business Feature Slices | Pending |
| COURSE-01 | Phase 3: Business Feature Slices | Pending |
| COURSE-02 | Phase 3: Business Feature Slices | Pending |
| COURSE-03 | Phase 3: Business Feature Slices | Pending |
| CURR-01 | Phase 3: Business Feature Slices | Pending |
| CURR-02 | Phase 3: Business Feature Slices | Pending |
| ENROLL-01 | Phase 3: Business Feature Slices | Pending |
| ENROLL-02 | Phase 3: Business Feature Slices | Pending |
| ENROLL-03 | Phase 3: Business Feature Slices | Pending |
| ENROLL-04 | Phase 3: Business Feature Slices | Pending |
| ENROLL-05 | Phase 3: Business Feature Slices | Pending |
| ENROLL-06 | Phase 3: Business Feature Slices | Pending |
| ENROLL-07 | Phase 3: Business Feature Slices | Pending |
| ENROLL-08 | Phase 3: Business Feature Slices | Pending |
| ENROLL-STAFF-01 | Phase 3: Business Feature Slices | Pending |
| ENROLL-STAFF-02 | Phase 3: Business Feature Slices | Pending |
| ENROLL-STAFF-03 | Phase 3: Business Feature Slices | Pending |
| GRADES-01 | Phase 3: Business Feature Slices | Pending |
| GRADES-02 | Phase 3: Business Feature Slices | Pending |
| GRADES-03 | Phase 3: Business Feature Slices | Pending |
| GRADES-04 | Phase 3: Business Feature Slices | Pending |
| DOCS-01 | Phase 3: Business Feature Slices | Pending |
| DOCS-02 | Phase 3: Business Feature Slices | Pending |
| DOCS-03 | Phase 3: Business Feature Slices | Pending |
| DOCS-04 | Phase 3: Business Feature Slices | Pending |
| APPT-01 | Phase 3: Business Feature Slices | Pending |
| APPT-02 | Phase 3: Business Feature Slices | Pending |
| APPT-03 | Phase 3: Business Feature Slices | Pending |
| APPT-04 | Phase 3: Business Feature Slices | Pending |
| APPT-STAFF-01 | Phase 3: Business Feature Slices | Pending |
| STAFF-01 | Phase 3: Business Feature Slices | Pending |
| MCP-01 | Phase 4: MCP Server | Pending |
| MCP-02 | Phase 4: MCP Server | Pending |
| MCP-03 | Phase 4: MCP Server | Pending |
| MCP-04 | Phase 4: MCP Server | Pending |
| MCP-05 | Phase 4: MCP Server | Pending |
| AI-01 | Phase 5: AI Service | Pending |
| AI-02 | Phase 5: AI Service | Pending |
| AI-03 | Phase 5: AI Service | Pending |
| AI-04 | Phase 5: AI Service | Pending |
| AI-05 | Phase 5: AI Service | Pending |
| WH-01 | Phase 6: WhatsApp Webhook & Integration | Pending |
| WH-02 | Phase 6: WhatsApp Webhook & Integration | Pending |
| WH-03 | Phase 6: WhatsApp Webhook & Integration | Pending |
| WH-04 | Phase 6: WhatsApp Webhook & Integration | Pending |
| WH-05 | Phase 6: WhatsApp Webhook & Integration | Pending |
| CHAT-01 | Phase 6: WhatsApp Webhook & Integration | Pending |
| CHAT-02 | Phase 6: WhatsApp Webhook & Integration | Pending |
| CHAT-03 | Phase 6: WhatsApp Webhook & Integration | Pending |
| TEST-01 | Phase 6: WhatsApp Webhook & Integration | Pending |
| TEST-02 | Phase 6: WhatsApp Webhook & Integration | Pending |
| TEST-03 | Phase 6: WhatsApp Webhook & Integration | Pending |
| TEST-04 | Phase 6: WhatsApp Webhook & Integration | Pending |
| TEST-05 | Phase 6: WhatsApp Webhook & Integration | Pending |
