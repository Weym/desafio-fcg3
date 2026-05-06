# Requirements — Desafio FCG3

**Version:** 2.0
**Milestone:** M2 — Flutter Frontend
**Date:** 2026-05-04

---

## v2 Requirements

### Flutter Infrastructure & Auth

- [ ] **UI-INFRA-01**: App inicia com navegação baseada em perfil — Client e Provider/Staff veem rotas dedicadas
- [x] **UI-INFRA-02**: Fluxo de autenticação (OTP email → JWT) integrado com backend FastAPI existente
- [ ] **UI-INFRA-03**: JWT armazenado via flutter_secure_storage com detecção de expiração/revogação e redirecionamento para login

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

*Mapeamento de requisitos para fases do roadmap — gerado em 2026-05-04.*

| REQ-ID | Phase | Status |
|--------|-------|--------|
| UI-INFRA-01 | Phase 7: Flutter Scaffold & Auth | Pending |
| UI-INFRA-02 | Phase 7: Flutter Scaffold & Auth | Complete |
| UI-INFRA-03 | Phase 7: Flutter Scaffold & Auth | Pending |
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
