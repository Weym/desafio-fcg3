# Architecture

**Analysis Date:** 2026-04-15

## Pattern Overview

**Overall:** Multi-service monorepo with Vertical Slice Architecture (VSA) in the backend

**Key Characteristics:**
- Three independent services: Flutter mobile app, Python FastAPI backend, Python LangChain AI service
- Backend organized as vertical slices — each feature owns its own controllers, services, and routes
- AI service uses a LangChain ReAct agent with RAG + MCP tool calling
- Pseudo-async webhook processing: FastAPI returns 200 OK immediately and dispatches AI processing via `asyncio.create_task` to avoid WhatsApp's ~5s timeout
- Single PostgreSQL instance serves both relational data and vector embeddings (PGVector extension)

---

## System Layers

**Mobile Frontend (Flutter):**
- Purpose: Client-facing app (student) and staff/admin CRM interface
- Location: `mobile/lib/`
- Contains: Screens, components, shared utilities, core config
- Depends on: FastAPI REST API via HTTPS + JWT
- Used by: End users (students and staff)
- State: Not yet implemented — planned as Provider, Riverpod, or Bloc
- Auth: JWT stored in `flutter_secure_storage`, sent as `Authorization: Bearer {token}`

**Backend API (FastAPI):**
- Purpose: Central REST API — orchestrates AI calls, persists data, dispatches FCM push notifications
- Location: `backend/src/`
- Contains: Feature slices, infrastructure config, shared utilities
- Depends on: PostgreSQL + PGVector, LangChain AI service (internal HTTP), Firebase FCM, WhatsApp Cloud API
- Used by: Mobile app (JWT), MCP server (Service Token), WhatsApp webhooks (signature validation)

**AI Service (LangChain):**
- Purpose: LangChain ReAct agent that processes chat messages and calls MCP tools
- Location: Planned in project root (not yet created as `ai_service/`)
- Contains: LangChain agent, RAG pipeline, conversation memory
- Depends on: PostgreSQL + PGVector (similarity search), MCP server (tool calls)
- Memory: `ConversationBufferWindowMemory` with k=20 (last 20 messages retained)

**MCP Server:**
- Purpose: Dual-purpose — tool calling proxy and action logger
- Location: Planned in project root (not yet created as `mcp_server/`)
- Contains: Tool schemas (without `student_id`), API call proxy, action logging to `mcp_action_logs`
- Auth: `X-Service-Token` header validated by FastAPI middleware
- Security: `student_id` is never exposed to the LangChain agent — MCP injects it from session context to prevent IDOR

**Data Layer (PostgreSQL + PGVector):**
- Purpose: Unified relational + vector database
- Contains: All business entities + RAG embeddings (`knowledge_base_chunks` table with `vector(1536)`)
- Vector index: HNSW (`vector_cosine_ops`) with m=16, ef_construction=64
- Embedding model assumed: `text-embedding-3-small` (OpenAI, 1536 dimensions)

---

## Data Flow

**WhatsApp Message Processing (Pseudo-Async):**

1. Student sends text to WhatsApp Business Cloud API
2. WhatsApp POSTs to `POST /webhook/whatsapp` — FastAPI validates `X-Hub-Signature-256`
3. FastAPI saves `chat_message` (role: user) to PostgreSQL
4. FastAPI calls `asyncio.create_task(process_message)` — returns `200 OK` immediately
5. Background task passes message + session context to LangChain agent
6. Agent performs similarity search via PGVector (threshold: 0.75 cosine similarity)
7. Agent calls MCP tools as needed — MCP injects `student_id`, calls FastAPI with `X-Service-Token`
8. MCP logs every tool call to `mcp_action_logs` (params, result, latency, retry flag)
9. Agent response is saved as `chat_message` (role: assistant)
10. FastAPI POSTs response back to WhatsApp Cloud API (`graph.facebook.com`)

**Mobile App Auth Flow:**

1. User submits email → `POST /auth/request-code` generates a 6-digit code (expires 5 min)
2. Code is sent via email or SMS
3. User submits code → `POST /auth/verify-code` validates, creates session, returns JWT
4. JWT payload includes `jti` (UUID) — session stored in `sessions` table for revocation
5. Max 3 attempts; on exhaustion, current code is invalidated and new code is sent

**FCM Push Notifications:**

1. Backend event occurs (document ready, enrollment confirmed, chat reply, etc.)
2. FastAPI calls `POST /send` on Firebase Cloud Messaging with `student_fcm_token`
3. FCM delivers push notification to Flutter app in < 2 seconds
4. App fetches updated resource from API after notification receipt

**State Management:**
- JWT session state stored in `sessions` table (jti-based, not full token)
- Chat conversation context stored in `chat_sessions` + `chat_messages` tables
- FCM tokens managed in `fcm_tokens` table (supports multiple devices per student)

---

## Key Abstractions

**Vertical Feature Slice (Backend):**
- Purpose: Each feature owns its full stack — routes, business logic, and data access
- Planned structure per slice: `controllers/`, `services/`, `routes.ts` (README describes TypeScript, but actual runtime is Python/FastAPI)
- Current slices (empty scaffolding): `backend/src/features/auth/`, `backend/src/features/enrollment/`
- Note: `backend/src/main.py` is the entry point — framework is FastAPI (Python), not Express/TypeScript as described in the original README

**MCP Tool Schema:**
- Purpose: Defines the interface LangChain agent uses for tool calls
- Critical rule: `student_id` is always omitted from schemas and injected by MCP from session context
- Tools that reference specific resources (enrollment_id, document_id) receive those IDs normally

**Knowledge Base Chunks (RAG):**
- Purpose: Chunked academic documents embedded for semantic retrieval
- Table: `knowledge_base_chunks` with categories: `regras_matricula`, `faq`, `curriculo`, `documentos`, `agendamento`, `regulamento`
- Retrieval threshold: 0.75 cosine similarity score

---

## Entry Points

**Backend API:**
- Location: `backend/src/main.py`
- Triggers: HTTP requests from mobile app, WhatsApp webhook, internal MCP calls
- Responsibilities: Route registration, middleware setup, lifespan/startup hooks

**WhatsApp Webhook:**
- Location: `POST /webhook/whatsapp` and `GET /webhook/whatsapp` (challenge verification)
- Triggers: Incoming messages from WhatsApp Business Cloud API
- Responsibilities: Signature validation, message parsing, async task dispatch

**Mobile App:**
- Location: `mobile/lib/main.dart`
- Triggers: App launch
- Responsibilities: Checks local JWT token validity, routes to Home or Login screen

---

## Error Handling

**Strategy:** Standardized JSON error envelope across all API responses

**Patterns:**
- All errors return `{"error": {"code": "ERROR_CODE", "message": "...", "details": [...]}}` shape
- Auth errors: 401 for unauthenticated, 403 for unauthorized role
- Validation: 400 or 422
- Conflict states: 409 (e.g., `ENROLLMENT_ALREADY_CONFIRMED`, `ENROLLMENT_PERIOD_CLOSED`)
- Rate limiting: 429 for OTP attempts exhausted (`MAX_ATTEMPTS_REACHED`)
- MCP tool retry: logged via `retry` boolean + `retry_success` status in `mcp_action_logs`
- Media messages to chatbot: handled with hardcoded default responses per media type (no AI processing in MVP)

---

## Cross-Cutting Concerns

**Authentication:**
- Two mechanisms: JWT Bearer (students/staff) and X-Service-Token (MCP internal calls)
- JWT revocation via `jti` lookup in `sessions` table — avoids storing full tokens
- Service token validated in FastAPI middleware before any endpoint processing

**Authorization:**
- Role-based: `student`, `staff`, `admin` — enforced per endpoint
- Endpoints accessible by MCP are marked to accept `X-Service-Token` as alternative auth

**Async Processing:**
- `asyncio.create_task` used for WhatsApp webhook background processing to prevent Meta timeout
- No external queue (Celery, RQ) in MVP — raw asyncio tasks only

**Real-time Updates:**
- Firebase Cloud Messaging (FCM) delivers push notifications with < 2s target latency
- App fetches updated resource data after receiving FCM payload
- 5 defined event types trigger FCM: `document_ready`, `enrollment_confirmed`, `appointment_confirmed`, `chat_reply`, `action_status`

**Logging:**
- MCP actions logged to `mcp_action_logs` with full input params, output, latency, reasoning, and retry flag
- Soft deletes on students (`DELETE /students/{id}` described as soft delete)

**Database Cleanup:**
- MVP: manual SQL scripts to purge expired `verification_codes` and `sessions`
- Post-MVP: `pg_cron` scheduled cleanup

---

## Docker Topology

Four containers in Docker Compose:

| Container | Image | Port | Role |
|-----------|-------|------|------|
| `fastapi-app` | `python:3.12` | 8000 | Main REST API |
| `langchain-service` | `python:3.12` | 8001 | LangChain AI agent |
| `mcp-server` | `python:3.12` | 8002 | MCP tool calling + logging |
| `postgres` | `pgvector/pgvector:pg16` | 5432 | PostgreSQL + PGVector |

Networks: `app-network` (API ↔ AI ↔ MCP) and `data-network` (all services ↔ PostgreSQL).

---

*Architecture analysis: 2026-04-15*
