# Phase 12: Frontend-Backend Integration - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-06
**Phase:** 12-frontend-backend-integration
**Areas discussed:** Contratos API, Docker Compose setup, Auth OTP em dev local, Escopo dos testes E2E, Config de rede

---

## Contratos API (Payloads)

### Validação

| Option | Description | Selected |
|--------|-------------|----------|
| Validar manualmente com backend real | Rodar backend, chamar endpoints, comparar JSON com models Dart | |
| Testes automáticos de contrato | Testes que comparam response shapes com models Dart | |
| Manual + automatizado | Validação manual primeiro, depois automatizar | ✓ |

**User's choice:** Manual + automatizado (Recomendado)
**Notes:** Nenhuma nota adicional.

### Fonte de verdade

| Option | Description | Selected |
|--------|-------------|----------|
| Frontend se adapta ao backend | Models Dart se ajustam ao que backend retorna | |
| Backend se adapta ao frontend | Backend muda para atender o frontend | |
| Docs são a fonte de verdade | Caso a caso conforme documentação | |

**User's choice:** Backend é prioridade. Tudo que existe no backend deve ser implementado no frontend. Sempre perguntar antes de implementar, explicando o que será feito. Manter docs atualizados.
**Notes:** Resposta customizada do usuário — backend como fonte de verdade mas com confirmação explícita antes de cada mudança.

---

## Docker Compose Setup

### Stack

| Option | Description | Selected |
|--------|-------------|----------|
| Stack completo (4 serviços) | fastapi, langchain, mcp, postgres | |
| Stack mínimo (2 serviços) | fastapi + postgres apenas | |
| Stack completo + Flutter web | 5 serviços incluindo Flutter web | ✓ |

**User's choice:** Stack completo + Flutter web
**Notes:** Nenhuma nota adicional.

### Seed

| Option | Description | Selected |
|--------|-------------|----------|
| Seed automático no boot | Roda automaticamente no startup | |
| Seed manual via comando | Comando separado para executar | |
| Seed condicional | Automático no primeiro boot, pula depois | ✓ |

**User's choice:** Seed condicional (Recomendado)
**Notes:** Nenhuma nota adicional.

---

## Auth OTP em Dev Local

| Option | Description | Selected |
|--------|-------------|----------|
| Email real (Resend) | Configura Resend com API key real | |
| Código fixo em dev (bypass) | Aceita 000000 sem enviar email | ✓ |
| OTP no console | Loga código no console, não envia email | |
| Console + email opcional | Console log + email se key configurada | |

**User's choice:** Código fixo em dev (bypass)
**Notes:** Sem envio de email em desenvolvimento. Código fixo `000000`.

---

## Escopo dos Testes E2E

### Fluxos

| Option | Description | Selected |
|--------|-------------|----------|
| Fluxo básico (auth + navegação) | Login → navegação por role → dashboard | ✓ |
| Fluxo de documentos | Auth → listar → solicitar → ver status | ✓ |
| Fluxo de chat | Auth → sessões → mensagens → action logs | ✓ |
| Fluxo de staff | Auth → KPIs → agenda → documentos | ✓ |
| Todos os fluxos críticos | Cobertura completa | ✓ |

**User's choice:** Todos os fluxos críticos
**Notes:** Nenhuma nota adicional.

### Tipo de teste

| Option | Description | Selected |
|--------|-------------|----------|
| Manual (checklist) | Passos manuais documentados | |
| Automatizado (integration_test) | Flutter integration_test contra backend real | ✓ |
| Manual agora + automatizar depois | Checklist agora, automação futura | |

**User's choice:** Automatizado (integration_test)
**Notes:** Testes automatizados desde o início.

---

## Config de Rede (CORS/Proxy)

### Comunicação

| Option | Description | Selected |
|--------|-------------|----------|
| Portas separadas + CORS | Flutter :3000, backend :8000, CORS configurado | ✓ |
| Reverse proxy (Nginx/Caddy) | Proxy na frente de tudo | |
| Nginx no compose | Container nginx serve Flutter e faz proxy | |

**User's choice:** Portas separadas + CORS (atual)
**Notes:** Manter o setup atual.

### Base URL

| Option | Description | Selected |
|--------|-------------|----------|
| Env var (manter atual) | Variável de ambiente via EnvConfig | ✓ |
| Hardcoded | URL fixa no código | |

**User's choice:** Env var (manter atual)
**Notes:** Já implementado, apenas manter.

---

## Agent's Discretion

- Implementação interna do seed condicional
- Estrutura dos testes de integração
- Ordem de validação dos endpoints

## Deferred Ideas

- Deploy em servidor (Render, Railway) — fase futura
- Reverse proxy (Nginx) — quando migrar para servidor
- Push notifications FCM — out of scope
- Testes de carga — pós-MVP
