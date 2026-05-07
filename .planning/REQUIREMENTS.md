# Requirements — Desafio FCG3

**Version:** 2.1
**Milestone:** M2 — Flutter Frontend
**Date:** 2026-05-07
**Coverage:** 47/47 requirements mapped

---

## v2 Requirements

### Flutter Infrastructure & Auth

- [x] **UI-INFRA-01**: App inicia com navegação baseada em perfil — Client e Provider/Staff veem rotas dedicadas
- [x] **UI-INFRA-02**: Fluxo de autenticação (OTP email → JWT) integrado com backend FastAPI existente
- [x] **UI-INFRA-03**: JWT armazenado via flutter_secure_storage com detecção de expiração/revogação e redirecionamento para login

---

### Client Screens

- [x] **UI-C01**: Cliente visualiza dashboard home com resumo das ações e agendamentos realizados via WhatsApp
- [x] **UI-C02**: Cliente consulta histórico de chats/atendimentos com status das solicitações abertas
- [x] **UI-C03**: Cliente solicita envio ou emissão de novos documentos pela interface
- [x] **UI-C04**: Cliente acessa mural de documentos para visualização, download e gerenciamento de documentos emitidos ou recebidos
- [x] **UI-C05**: Cliente recebe e consulta central de notificações com alertas, lembretes de agendamento e atualizações de status
- [x] **UI-C06**: Cliente acessa canal direto de suporte e contato técnico/administrativo

---

### Staff/Provider Screens

- [x] **UI-F01**: Fornecedor consulta dashboard de gestão com métricas e visões gerais sobre o negócio, atendimentos e interações do bot
- [x] **UI-F02**: Fornecedor gerencia, aprova, reagenda ou cancela compromissos gerados via WhatsApp
- [x] **UI-F03**: Fornecedor visualiza dados estruturados, resumos e insights extraídos pela IA a partir das conversas
- [x] **UI-F04**: Fornecedor envia documentos para o mural dos clientes e gerencia solicitações pendentes

---

### Non-Functional

- [x] **UI-NFR-01**: Interface intuitiva priorizando clareza para o cliente
- [x] **UI-NFR-02**: Aplicação Flutter adaptável a smartphones, tablets e web
- [x] **UI-NFR-03**: Autenticação com separação rigorosa de permissões e rotas entre Cliente e Fornecedor
- [x] **UI-NFR-04**: Sincronização eficiente dos dados do WhatsApp/IA com latência percebida < 2s para dados cacheados

---

### Resource Allocation (Phase 13)

- [x] **RES-01**: Backend suporta 6 tipos de recurso (room, lab, equipment, auditorium, study_room, sports_court) com campo description
- [x] **RES-02**: Recursos possuem flag requires_authorization (boolean)
- [x] **RES-03**: Staff CRUD de recursos via API REST (create, read, update, soft-delete)
- [x] **RES-04**: Upload de autorização para agendamentos (PDF/JPG/PNG, limite 5MB)
- [x] **RES-05**: Seed data com recursos diversos de todos os 6 tipos
- [x] **RES-06**: Staff visualiza lista de todos os recursos na tela dedicada "Recursos"
- [x] **RES-07**: Staff cria novo recurso com nome, tipo, capacidade, localização, descrição e flag de autorização
- [x] **RES-08**: Staff edita propriedades de recursos existentes
- [x] **RES-09**: Staff desativa (soft-delete) recurso
- [x] **RES-10**: Aluno visualiza recursos disponíveis com filtro por tipo
- [x] **RES-11**: Badge visual indicando recurso que exige autorização
- [x] **RES-12**: Aluno seleciona recurso, horário e agenda (upload obrigatório quando requer autorização)
- [x] **RES-13**: Aluno visualiza seus agendamentos
- [x] **RES-14**: Aluno cancela agendamentos futuros

---

### Human Intervention (Phase 14)

- [x] **HI-01**: chat_sessions.status suporta 4 valores (active, closed, human_needed, human_active)
- [x] **HI-02**: chat_sessions possui assigned_staff_id FK para staff
- [x] **HI-03**: Escalação automática por keywords ("atendente", "humano") ou resposta contendo "procurar a secretaria"
- [x] **HI-04**: Aluno recebe mensagem de confirmação ao escalar para humano
- [x] **HI-05**: Webhook não processa AI quando sessão está em human_needed/human_active
- [x] **HI-06**: Staff assume sessão via POST /chat-sessions/{id}/assign
- [x] **HI-07**: Staff envia mensagem via POST /chat-sessions/{id}/reply (salva no DB + envia WhatsApp)
- [x] **HI-08**: Staff resolve sessão via PUT /chat-sessions/{id}/resolve
- [x] **HI-09**: Validação: sessão deve estar em human_active com assigned_staff_id == current_user
- [x] **HI-10**: Mensagem do aluno durante human_active é salva mas não aciona AI
- [x] **HI-11**: Tab "Intervenção" no staff shell com contagem de sessões pendentes
- [x] **HI-12**: Lista de sessões human_needed e human_active na tela de intervenção
- [x] **HI-13**: Cards mostram nome do aluno, RA, última mensagem antes de escalar, status badge, tempo decorrido
- [x] **HI-14**: Botão "Assumir Conversa" chama POST /assign e abre chat detail
- [x] **HI-15**: Chat detail com histórico completo + campo de resposta (POST /reply)
- [x] **HI-16**: Botão "Resolver" chama PUT /resolve e retorna à lista

---

## v1 Requirements (Previous Milestone — M1 Backend + AI + MCP)

> M1 requirements are preserved in git history. See `REQUIREMENTS.md` at any commit before 2026-05-04.
> 69/69 M1 requirements were mapped. Key validated items are tracked in PROJECT.md Validated section.

---

## Future Requirements (Deferred)

- Push notifications via FCM (registro de token, envio por tipo de evento)
- Transcrição de áudio via Whisper API
- Análise de imagens via GPT-4o Vision
- Cache de sessões em Redis
- Sentry / monitoramento externo

---

## Out of Scope

- Backend API changes — all endpoints built in M1; frontend consumes as-is
- WhatsApp bot features — complete in M1 Phase 6
- Knowledge base administration via UI — ingest via script only
- Offline-first / local caching strategy — pós-MVP

---

## Traceability

*Mapeamento de requisitos para fases do roadmap — atualizado em 2026-05-07.*

| REQ-ID | Phase | Status |
|--------|-------|--------|
| UI-INFRA-01 | Phase 7: Flutter Scaffold & Auth | Complete |
| UI-INFRA-02 | Phase 7: Flutter Scaffold & Auth | Complete |
| UI-INFRA-03 | Phase 7: Flutter Scaffold & Auth | Complete |
| UI-NFR-03 | Phase 7: Flutter Scaffold & Auth | Complete |
| UI-C01 | Phase 8: Client Interface | Complete |
| UI-C02 | Phase 8: Client Interface | Complete |
| UI-C03 | Phase 8: Client Interface | Complete |
| UI-C04 | Phase 8: Client Interface | Complete |
| UI-C05 | Phase 8: Client Interface | Complete |
| UI-C06 | Phase 8: Client Interface | Complete |
| UI-NFR-01 | Phase 8: Client Interface | Complete |
| UI-F01 | Phase 9: Staff Interface | Complete |
| UI-F02 | Phase 9: Staff Interface | Complete |
| UI-F03 | Phase 9: Staff Interface | Complete |
| UI-F04 | Phase 9: Staff Interface | Complete |
| UI-NFR-02 | Phase 10: Cross-Platform Polish | Complete |
| UI-NFR-04 | Phase 10: Cross-Platform Polish | Complete |
| RES-01 | Phase 13: Resource Allocation | Complete |
| RES-02 | Phase 13: Resource Allocation | Complete |
| RES-03 | Phase 13: Resource Allocation | Complete |
| RES-04 | Phase 13: Resource Allocation | Complete |
| RES-05 | Phase 13: Resource Allocation | Complete |
| RES-06 | Phase 13: Resource Allocation | Complete |
| RES-07 | Phase 13: Resource Allocation | Complete |
| RES-08 | Phase 13: Resource Allocation | Complete |
| RES-09 | Phase 13: Resource Allocation | Complete |
| RES-10 | Phase 13: Resource Allocation | Complete |
| RES-11 | Phase 13: Resource Allocation | Complete |
| RES-12 | Phase 13: Resource Allocation | Complete |
| RES-13 | Phase 13: Resource Allocation | Complete |
| RES-14 | Phase 13: Resource Allocation | Complete |
| HI-01 | Phase 14: Human Intervention | Complete |
| HI-02 | Phase 14: Human Intervention | Complete |
| HI-03 | Phase 14: Human Intervention | Complete |
| HI-04 | Phase 14: Human Intervention | Complete |
| HI-05 | Phase 14: Human Intervention | Complete |
| HI-06 | Phase 14: Human Intervention | Complete |
| HI-07 | Phase 14: Human Intervention | Complete |
| HI-08 | Phase 14: Human Intervention | Complete |
| HI-09 | Phase 14: Human Intervention | Complete |
| HI-10 | Phase 14: Human Intervention | Complete |
| HI-11 | Phase 14: Human Intervention | Complete |
| HI-12 | Phase 14: Human Intervention | Complete |
| HI-13 | Phase 14: Human Intervention | Complete |
| HI-14 | Phase 14: Human Intervention | Complete |
| HI-15 | Phase 14: Human Intervention | Complete |
| HI-16 | Phase 14: Human Intervention | Complete |
