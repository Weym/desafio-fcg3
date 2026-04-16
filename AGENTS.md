<!-- GSD:project-start source:PROJECT.md -->
## Project

**Desafio FCG3 — Plataforma Acadêmica com Chatbot WhatsApp**

Plataforma para alunos do curso de Ciência da Computação interagirem com serviços acadêmicos via API REST e WhatsApp. O backend em FastAPI centraliza dados e lógica de negócio; um agente LangChain com RAG processa mensagens do WhatsApp e executa ações via MCP Server; um MCP Server atua como proxy entre o agente e a API, injetando contexto de segurança.

**Core Value:** Aluno envia mensagem no WhatsApp e recebe resposta precisa sobre sua situação acadêmica (notas, matrículas, documentos) — com ações concretas executadas em tempo real.

### Constraints

- **Tech Stack**: Python 3.12, FastAPI, SQLAlchemy + Alembic, LangChain, MCP — não negociável
- **Segurança**: `student_id` nunca exposto ao agente LangChain; sempre injetado pelo MCP Server
- **Segurança**: `MCP_SERVICE_TOKEN` nunca em código-fonte — apenas variável de ambiente
- **Performance**: Webhook deve retornar 200 OK em < 5s (limite do WhatsApp)
- **LLM Provider**: Decisão de terceiro — implementar agnóstico de provider
- **Email OTP**: Resend como provider
<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->
## Technology Stack

## Languages
- Python 3.12 - Backend API (FastAPI), AI/LangChain service, MCP server
- Dart 3.11.4+ - Flutter mobile/web frontend
- SQL - PostgreSQL queries and schema management (pgvector HNSW indexes, pg_cron planned)
## Runtime
- Python 3.12 (FastAPI, LangChain service, MCP server)
- Dart SDK ^3.11.4 (Flutter 3.41.6)
- Python: pip (requirements.txt per service — file not yet present, structure planned per `docs/architecture.md`)
- Flutter/Dart: pub (lockfile: `mobile/pubspec.lock` — Flutter managed)
- Lockfile: present for Flutter; Python lockfile not yet present (early project state)
## Frameworks
- FastAPI (Python) - Central REST API at `:8000`, async webhook processing via `asyncio.create_task`
- LangChain - AI orchestration service at `:8001`, ReAct agent with `ConversationBufferWindowMemory(k=20)`
- MCP (Model Context Protocol) - Tool calling + logging server at `:8002`, stdio/SSE transport
- Flutter 3.41.6 - Cross-platform mobile/web app (iOS, Android, Linux, Web, macOS, Windows)
- `flutter_test` SDK - Flutter unit/widget tests (`mobile/test/`)
- `flutter_lints` ^6.0.0 - Dart linting rules
- Docker Compose - Multi-container orchestration (`docker-compose.yml` present, empty — not yet written)
- FVM (Flutter Version Manager) - Flutter version pinning via `.fvmrc` (`flutter: 3.41.6`)
## Key Dependencies
- `langchain` - LangChain agent framework for ReAct pattern, ConversationBufferWindowMemory, BaseCallbackHandler
- `pgvector` extension for PostgreSQL - Vector similarity search (HNSW index, cosine ops, `vector(1536)`)
- `httpx` - Async HTTP client used in MCP server for internal API calls with retry logic
- `cupertino_icons` ^1.0.8 - Flutter iOS-style icons
- `flutter_secure_storage` (planned) - JWT token storage on Flutter client
- `postgres:16 + pgvector/pgvector:pg16` - Single database image with PGVector extension pre-installed
- `python:3.12` Docker base image - Used for all three backend services (fastapi-app, langchain-service, mcp-server)
## Configuration
- Configured via environment variables (no `.env` files present yet)
- Critical vars: `MCP_SERVICE_TOKEN` (internal service auth), `WHATSAPP_TOKEN`, `DATABASE_URL`, embedding model config
- `MCP_SERVICE_TOKEN` is never committed to source — env-only per `docs/mcp.md`
- `.gitignore` files present on root `.gitignore`
- `.fvmrc` — Flutter version pinning (`flutter: 3.41.6`)
- `mobile/pubspec.yaml` — Flutter package manifest
- Docker Compose at `docker-compose.yml` (currently empty, to be written)
## Platform Requirements
- Python 3.12+
- Flutter 3.41.6 / Dart SDK ^3.11.4
- Docker + Docker Compose
- FVM for Flutter version management
- PostgreSQL 16 with pgvector extension
- Docker containerization
- 4 containers: `fastapi-app:8000`, `langchain-service:8001`, `mcp-server:8002`, `postgres:5432`
- Networks: `app-network` (API + AI services) and `data-network` (postgres)
- Embedding model: `text-embedding-3-small` (OpenAI) — vector dimension 1536
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

## Project State
## Language and Runtime
- **Language:** Python 3.12
- **Framework:** FastAPI
- **Style source:** Inline snippets in `docs/mcp.md` and `docs/api.md` define
## Naming Patterns
- Use `snake_case` for all Python files: `main.py`, `ingest.py`
- Feature directories use `snake_case`: `features/auth/`, `features/enrollment/`
- Shared utilities live in `src/shared/`
- Infrastructure (DB clients, HTTP clients) lives in `src/infrastructure/`
- Use `snake_case`: `verify_service_token`, `execute_tool_with_middleware`,
- Async functions must use `async def` — the entire FastAPI surface is async
- Background tasks use `asyncio.create_task(...)` pattern
- `snake_case` throughout
- Boolean flags: descriptive names — `retry`, `is_active`, `is_available`,
- UUID identifiers always named `*_id` suffix: `student_id`, `enrollment_id`,
- `PascalCase`: `MCPLoggingHandler`, `BaseCallbackHandler`
- SCREAMING_SNAKE_CASE for settings and env vars: `MCP_SERVICE_TOKEN`,
- Settings accessed via a `settings` object — never inline `os.getenv()` in
## API and Endpoint Conventions
- `GET` — read, returns `200`
- `POST` — create, returns `201`; action endpoints return `200`
- `PUT` — full update or action (e.g., cancel, confirm), returns `200`
- `DELETE` — remove a sub-resource, returns `200`
- Lowercase kebab-case path segments: `/enrollment-periods/current`,
- Resource IDs as path params: `/students/{id}/grades`
- Sub-actions as path suffixes: `/enrollments/{id}/confirm`,
- Query params use `snake_case`: `page`, `per_page`, `sort_by`, `order`,
## Error Handling
- `VALIDATION_ERROR`, `INVALID_CODE`, `MAX_ATTEMPTS_REACHED`,
| Code | Use |
|------|-----|
| 200 | Success |
| 201 | Created |
| 400 | Validation error |
| 401 | Unauthenticated |
| 403 | Forbidden |
| 404 | Not found |
| 409 | Conflict (e.g., duplicate enrollment) |
| 422 | Unprocessable entity |
| 429 | Rate limit reached |
| 500 | Internal server error |
- 5xx errors and timeouts: one immediate retry, no wait
- 4xx errors: no retry — logic failures are not retried
## Authentication Conventions
| Type | Header | Used by |
|------|--------|---------|
| JWT Bearer | `Authorization: Bearer {token}` | App Flutter, students, staff |
| Service Token | `X-Service-Token: {MCP_SERVICE_TOKEN}` | MCP Server (internal calls only) |
## Async Patterns
- All FastAPI route handlers must be `async def`
- Background processing uses `asyncio.create_task(...)` — the webhook handler
- Background tasks must not block the HTTP response cycle
## MCP Tool Schema Conventions
- `student_id` is NEVER a parameter in tool input schemas exposed to the LLM
- The MCP server injects `student_id` from session context internally
- Tools that operate on a specific resource (enrollment, document) receive the
- All schemas use JSON Schema format with `type: "object"` and `properties`
## Data Conventions
- All primary keys are UUIDs
- FK references named with `_id` suffix
- `created_at` and `updated_at` on all mutable tables, `DEFAULT NOW()`
- Event-specific timestamps: `confirmed_at`, `requested_at`, `completed_at`,
- `VARCHAR(20)` — use lowercase string literals
- Pattern: `draft -> confirmed -> cancelled` (enrollments)
- Pattern: `requested -> processing -> ready -> delivered` (documents)
- Pattern: `active -> closed` (chat sessions)
- Students use `status = 'inactive'` — no physical delete
## Code Style
- Follow PEP 8
- Indent with 4 spaces (standard Python convention)
- Line length: no explicit constraint defined — follow PEP 8 default (79-99)
## Logging
- Structured logging via MCP action logs table (`mcp_action_logs`)
- Every MCP tool call must be logged with: `tool_name`, `input_params`,
- `reasoning` is nullable — models that don't expose chain-of-thought produce
- `student_id` is never logged in `input_params` — it is injected internally
## Comments
- Document non-obvious decisions — example from `docs/mcp.md`: explain why
- Code snippets in docs are the canonical reference — maintain alignment
## Module Design
- Each domain feature gets its own directory under `src/features/`
- Current feature directories: `src/features/auth/`, `src/features/enrollment/`
- Shared cross-feature code lives in `src/shared/`
- Infrastructure (DB connections, HTTP clients, settings) lives in
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

## Pattern Overview
- Three independent services: Flutter mobile app, Python FastAPI backend, Python LangChain AI service
- Backend organized as vertical slices — each feature owns its own controllers, services, and routes
- AI service uses a LangChain ReAct agent with RAG + MCP tool calling
- Pseudo-async webhook processing: FastAPI returns 200 OK immediately and dispatches AI processing via `asyncio.create_task` to avoid WhatsApp's ~5s timeout
- Single PostgreSQL instance serves both relational data and vector embeddings (PGVector extension)
## System Layers
- Purpose: Client-facing app (student) and staff CRM interface
- Location: `mobile/lib/`
- Contains: Screens, components, shared utilities, core config
- Depends on: FastAPI REST API via HTTPS + JWT
- Used by: End users (students and staff)
- State: Not yet implemented — planned as Provider, Riverpod, or Bloc
- Auth: JWT stored in `flutter_secure_storage`, sent as `Authorization: Bearer {token}`
- Purpose: Central REST API — orchestrates AI calls, persists data, dispatches FCM push notifications
- Location: `backend/src/`
- Contains: Feature slices, infrastructure config, shared utilities
- Depends on: PostgreSQL + PGVector, LangChain AI service (internal HTTP), Firebase FCM, WhatsApp Cloud API
- Used by: Mobile app (JWT), MCP server (Service Token), WhatsApp webhooks (signature validation)
- Purpose: LangChain ReAct agent that processes chat messages and calls MCP tools
- Location: Planned in project root (not yet created as `ai_service/`)
- Contains: LangChain agent, RAG pipeline, conversation memory
- Depends on: PostgreSQL + PGVector (similarity search), MCP server (tool calls)
- Memory: `ConversationBufferWindowMemory` with k=20 (last 20 messages retained)
- Purpose: Dual-purpose — tool calling proxy and action logger
- Location: Planned in project root (not yet created as `mcp_server/`)
- Contains: Tool schemas (without `student_id`), API call proxy, action logging to `mcp_action_logs`
- Auth: `X-Service-Token` header validated by FastAPI middleware
- Security: `student_id` is never exposed to the LangChain agent — MCP injects it from session context to prevent IDOR
- Purpose: Unified relational + vector database
- Contains: All business entities + RAG embeddings (`knowledge_base_chunks` table with `vector(1536)`)
- Vector index: HNSW (`vector_cosine_ops`) with m=16, ef_construction=64
- Embedding model assumed: `text-embedding-3-small` (OpenAI, 1536 dimensions)
## Data Flow
- JWT session state stored in `sessions` table (jti-based, not full token)
- Chat conversation context stored in `chat_sessions` + `chat_messages` tables
- FCM tokens managed in `fcm_tokens` table (supports multiple devices per student)
## Key Abstractions
- Purpose: Each feature owns its full stack — routes, business logic, and data access
- Planned structure per slice: `controllers/`, `services/`, `routes.ts` (README describes TypeScript, but actual runtime is Python/FastAPI)
- Current slices (empty scaffolding): `backend/src/features/auth/`, `backend/src/features/enrollment/`
- Note: `backend/src/main.py` is the entry point — framework is FastAPI (Python)
- Purpose: Defines the interface LangChain agent uses for tool calls
- Critical rule: `student_id` is always omitted from schemas and injected by MCP from session context
- Tools that reference specific resources (enrollment_id, document_id) receive those IDs normally
- Purpose: Chunked academic documents embedded for semantic retrieval
- Table: `knowledge_base_chunks` with categories: `regras_matricula`, `faq`, `curriculo`, `documentos`, `agendamento`, `regulamento`
- Retrieval threshold: 0.75 cosine similarity score
## Entry Points
- Location: `backend/src/main.py`
- Triggers: HTTP requests from mobile app, WhatsApp webhook, internal MCP calls
- Responsibilities: Route registration, middleware setup, lifespan/startup hooks
- Location: `POST /webhook/whatsapp` and `GET /webhook/whatsapp` (challenge verification)
- Triggers: Incoming messages from WhatsApp Business Cloud API
- Responsibilities: Signature validation, message parsing, async task dispatch
- Location: `mobile/lib/main.dart`
- Triggers: App launch
- Responsibilities: Checks local JWT token validity, routes to Home or Login screen
## Error Handling
- All errors return `{"error": {"code": "ERROR_CODE", "message": "...", "details": [...]}}` shape
- Auth errors: 401 for unauthenticated, 403 for unauthorized role
- Validation: 400 or 422
- Conflict states: 409 (e.g., `ENROLLMENT_ALREADY_CONFIRMED`, `ENROLLMENT_PERIOD_CLOSED`)
- Rate limiting: 429 for OTP attempts exhausted (`MAX_ATTEMPTS_REACHED`)
- MCP tool retry: logged via `retry` boolean + `retry_success` status in `mcp_action_logs`
- Media messages to chatbot: handled with hardcoded default responses per media type (no AI processing in MVP)
## Cross-Cutting Concerns
- Two mechanisms: JWT Bearer (students/staff) and X-Service-Token (MCP internal calls)
- JWT revocation via `jti` lookup in `sessions` table — avoids storing full tokens
- Service token validated in FastAPI middleware before any endpoint processing
- Role-based: `student`, `staff` — enforced per endpoint
- Endpoints accessible by MCP are marked to accept `X-Service-Token` as alternative auth
- `asyncio.create_task` used for WhatsApp webhook background processing to prevent Meta timeout
- No external queue (Celery, RQ) in MVP — raw asyncio tasks only
- Firebase Cloud Messaging (FCM) delivers push notifications with < 2s target latency
- App fetches updated resource data after receiving FCM payload
- 5 defined event types trigger FCM: `document_ready`, `enrollment_confirmed`, `appointment_confirmed`, `chat_reply`, `action_status`
- MCP actions logged to `mcp_action_logs` with full input params, output, latency, reasoning, and retry flag
- Soft deletes on students (`DELETE /students/{id}` described as soft delete)
- MVP: manual SQL scripts to purge expired `verification_codes` and `sessions`
- Post-MVP: `pg_cron` scheduled cleanup
## Docker Topology
| Container | Image | Port | Role |
|-----------|-------|------|------|
| `fastapi-app` | `python:3.12` | 8000 | Main REST API |
| `langchain-service` | `python:3.12` | 8001 | LangChain AI agent |
| `mcp-server` | `python:3.12` | 8002 | MCP tool calling + logging |
| `postgres` | `pgvector/pgvector:pg16` | 5432 | PostgreSQL + PGVector |
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, or `.github/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
