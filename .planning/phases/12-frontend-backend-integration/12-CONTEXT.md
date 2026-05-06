# Phase 12: Frontend-Backend Integration - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Conectar o Flutter app (Alpha Connect) ao backend FastAPI real — validar e corrigir contratos de API, configurar Docker Compose funcional com todos os serviços, implementar bypass de OTP para dev, e executar testes E2E automatizados cobrindo todos os fluxos críticos. O resultado final é o stack rodando localmente com dados reais fluindo do banco para as telas.

</domain>

<decisions>
## Implementation Decisions

### Contratos API (Payloads)

- **D-01:** Validação manual primeiro (rodar backend, comparar JSON retornado com models Dart) seguida de testes automatizados de contrato para evitar regressões.
- **D-02:** Backend é a fonte de verdade. Tudo que existe no backend deve ser refletido no frontend, mesmo que não esteja descrito ou presente nas telas.
- **D-03:** Antes de implementar qualquer correção de contrato, perguntar ao usuário explicando exatamente o que será alterado.
- **D-04:** Manter documentos atualizados conforme contratos são corrigidos (docs/api.md, models Dart).

### Docker Compose Setup

- **D-05:** Stack completo com 5 serviços: `fastapi-app:8000`, `langchain-service:8001`, `mcp-server:8002`, `postgres:5432`, `flutter-web:3000`.
- **D-06:** Seed de dados condicional — roda automaticamente no primeiro boot, pula em boots subsequentes (flag de controle).
- **D-07:** Hot reload para serviços Python (volume mounts). Healthchecks em todos os serviços.
- **D-08:** O projeto deve rodar local com Docker. Migração para servidor é futura (fora do escopo desta fase).

### Auth OTP em Dev Local

- **D-09:** Em ambiente `development`, aceitar código fixo `000000` sem enviar email (bypass completo do Resend).
- **D-10:** O bypass é controlado por variável de ambiente (ex: `ENVIRONMENT=development`). Em produção, o fluxo real com Resend é obrigatório.

### Testes E2E

- **D-11:** Cobertura de todos os fluxos críticos: auth + navegação, documentos, chat, staff.
- **D-12:** Testes automatizados usando Flutter `integration_test` rodando contra o backend real (stack Docker).
- **D-13:** Fluxos testados:
  - Login OTP → navegação por role → dashboard com dados reais
  - Auth → listar documentos → solicitar documento → ver status
  - Auth → ver sessões de chat → ver mensagens → ver action logs
  - Auth → dashboard KPIs → agenda → gerenciar documentos

### Config de Rede (CORS/Proxy)

- **D-14:** Portas separadas: Flutter web em `:3000`, backend em `:8000`. CORS já configurado para aceitar localhost.
- **D-15:** Base URL do backend configurável via variável de ambiente (EnvConfig já implementado — manter).
- **D-16:** Sem reverse proxy nesta fase. Comunicação direta entre containers via network Docker.

### Agent's Discretion

- Escolha de como implementar o seed condicional (flag file, tabela no DB, ou env var check)
- Estrutura interna dos testes de integração (organização de arquivos, helpers)
- Ordem de validação dos endpoints (quais primeiro)

</decisions>

<canonical_refs>

## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### API Contracts
- `docs/api.md` — Definição completa de todos os endpoints REST com payloads
- `docs/database.md` — Schema do banco (17 tabelas) — fonte de verdade para tipos de dados

### Architecture
- `docs/architecture.md` — Topologia Docker, comunicação entre serviços, async patterns
- `docs/mcp.md` — MCP tool schemas, student_id injection, logging

### Frontend Models
- `mobile/lib/core/models/` — Models Dart que devem corresponder aos payloads da API
- `mobile/lib/features/client/models/` — Models de domínio client (chat, documents, appointments)
- `mobile/lib/features/staff/models/` — Models de domínio staff (dashboard, scheduling, student summary)

### Configuration
- `mobile/lib/core/config/env_config.dart` — Base URL e configuração do Flutter
- `docker-compose.yml` — Arquivo vazio que será implementado nesta fase
- `.env.example` — Variáveis de ambiente documentadas

### Auth Flow
- `mobile/lib/features/auth/` — Providers, service, e screen de auth no Flutter
- `backend/src/features/auth/` — Endpoints de auth no backend (request-code, verify-code, me, refresh)

</canonical_refs>

<code_context>

## Existing Code Insights

### Reusable Assets

- `DioClient` (mobile/lib/core/network/dio_client.dart) — HTTP client configurado com interceptors
- `AuthInterceptor` (mobile/lib/core/network/auth_interceptor.dart) — Token refresh automático
- `EnvConfig` (mobile/lib/core/config/env_config.dart) — Base URL do backend
- `scripts/seed.py` (backend) — Seed de dados de desenvolvimento existente
- `.env.example` — Template de variáveis de ambiente

### Established Patterns

- Models Dart usam `@JsonSerializable` com codegen (build_runner)
- Services fazem chamadas via `DioClient` injetado por Riverpod
- Providers usam `@riverpod` annotations com cache TTL de 5 min
- Backend segue VSA (Vertical Slice Architecture) em `backend/src/features/`

### Integration Points

- `mobile/lib/features/*/services/*.dart` — Cada service já faz as chamadas HTTP corretas
- `backend/src/main.py` — Entry point FastAPI com registro de routers
- `docker-compose.yml` — Precisa ser escrito do zero (está vazio)
- `backend/src/features/auth/` — Endpoint `/auth/request-code` precisa do bypass OTP

</code_context>

<specifics>
## Specific Ideas

- O usuário quer que o projeto rode 100% local com um único `docker compose up`
- Futuramente migrará para servidor (fora desta fase) — manter configuração preparada para isso
- Remover o "demo mode" do login quando a integração real estiver funcionando (ou mantê-lo como fallback)
- Prioridade é ver dados reais fluindo nas telas, não apenas "não dar erro"

</specifics>

<deferred>
## Deferred Ideas

- Deploy em servidor (Render, Railway, etc) — fase futura após validação local
- Reverse proxy (Nginx) para ambiente prod-like — quando migrar para servidor
- Push notifications FCM — out of scope (PROJECT.md)
- Testes de carga/performance — pós-MVP

</deferred>

---

_Phase: 12-frontend-backend-integration_
_Context gathered: 2026-05-06_
