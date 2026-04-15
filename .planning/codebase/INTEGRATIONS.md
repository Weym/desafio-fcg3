# External Integrations

**Analysis Date:** 2026-04-15

## APIs & External Services

**Messaging:**
- WhatsApp Business Cloud API (Meta) - Incoming chatbot messages and outgoing responses
  - Incoming: `POST /webhook/whatsapp` — validated with `X-Hub-Signature-256` header
  - Outgoing: `POST https://graph.facebook.com/v18.0/{phone_number_id}/messages`
  - Auth: `Authorization: Bearer {WHATSAPP_TOKEN}` (env var)
  - Message types handled: text (processed by AI agent), media types (audio, image, document, sticker, location, video) receive static fallback responses
  - Webhook verification: `GET /webhook/whatsapp` (Meta challenge-response)

**AI / LLM:**
- OpenAI API (planned) - Embedding model `text-embedding-3-small` for RAG knowledge base ingestion
  - Vector dimension: 1536 (matches `knowledge_base_chunks.embedding vector(1536)`)
  - Post-MVP roadmap: Whisper API for audio transcription, GPT-4o Vision for image analysis
- LLM provider for ReAct agent: to be defined per `docs/chatbot.md`

## Data Storage

**Databases:**
- PostgreSQL 16 with PGVector extension
  - Image: `pgvector/pgvector:pg16`
  - Port: `5432`
  - Connection: `DATABASE_URL` (env var)
  - Client: Python async ORM/driver (SQLAlchemy async or asyncpg — not yet specified)
  - HNSW vector index on `knowledge_base_chunks.embedding` (cosine ops, m=16, ef_construction=64)
  - All three backend services connect: FastAPI (CRUD), LangChain service (RAG similarity search), MCP server (action logging)

**File Storage:**
- `documents.file_url VARCHAR(500)` stores external URLs — storage provider not yet specified (placeholder `https://storage.example.com/docs/` in `docs/api.md`)

**Caching:**
- None (not implemented in MVP)

## Authentication & Identity

**Auth Strategy:**
- Passwordless OTP via verification code (6-digit code, 5-minute expiry, 3 attempts max)
  - Channels: email and SMS
  - Flow: `POST /auth/request-code` → delivery → `POST /auth/verify-code` → JWT
  - On 3 failed attempts: current code invalidated, new code auto-sent

**JWT Sessions:**
- Standard Bearer JWT (`Authorization: Bearer {token}`)
- Session revocation via `jti` field (UUID stored in `sessions` table, not the full token)
- Two user types: `student` and `staff` (roles: admin, coordinator, secretary)

**Internal Service Auth:**
- MCP Server authenticates to FastAPI using a static service token: `X-Service-Token: {MCP_SERVICE_TOKEN}`
- Token lives exclusively as env var, never in source code

**Email/SMS Delivery:**
- Provider for sending verification codes: not yet specified (to be implemented)

## Push Notifications

**Firebase Cloud Messaging (FCM):**
- Purpose: Push notifications to Flutter app clients (students only; staff excluded from MVP)
- FastAPI sends via `POST /send` to FCM HTTP API
- Flutter app registers device token via `PUT /students/{id}/fcm-token`
- Multiple tokens per student supported (`fcm_tokens` table with `UNIQUE(student_id, token)`)
- Events that trigger FCM notifications:
  - `document_ready` — document status changed to ready
  - `enrollment_confirmed` — enrollment confirmed
  - `appointment_confirmed` — appointment confirmed
  - `chat_reply` — AI chatbot response processed (async)
  - `action_status` — MCP action log status update
- Target latency: < 2 seconds

## AI/RAG Pipeline

**LangChain Agent:**
- Pattern: ReAct Agent
- Memory: `ConversationBufferWindowMemory(k=20)` — last 20 messages per session
- Memory persistence: `chat_messages` table in PostgreSQL (restored on session resume)
- RAG retriever: PGVector + LangChain with similarity threshold 0.75 (cosine)
  - Score >= 0.75: context injected into agent prompt
  - Score < 0.75: fallback response — no fabrication

**MCP Server:**
- Transport: stdio (local to LangChain agent) or SSE (network)
- Tool calling: 16 tools mapped to FastAPI endpoints (see `docs/mcp.md`)
- All tools inject `student_id` from session context (never passed by agent — IDOR prevention)
- Retry: single immediate retry on 5xx/timeout; 4xx errors are not retried
- Logging: every tool call writes to `mcp_action_logs` with `tool_name`, `input_params`, `output_result`, `reasoning`, `latency_ms`, `status`, `retry`
- `reasoning` captured via `BaseCallbackHandler.on_agent_action` (chain-of-thought, nullable)

**RAG Knowledge Base Ingestion:**
- Script: `scripts/ingest.py` (planned path in langchain-service container)
- Source: `.md` and `.pdf` files from `/knowledge` directory
- Chunk size: 500 tokens, overlap: 50 tokens
- Categories: `regras_matricula`, `faq`, `curriculo`, `documentos`, `agendamento`, `regulamento`

## Webhooks & Callbacks

**Incoming:**
- `POST /webhook/whatsapp` — WhatsApp Business Cloud API messages (HMAC-SHA256 validated via `X-Hub-Signature-256`)
- `GET /webhook/whatsapp` — Meta webhook verification (challenge-response)

**Outgoing:**
- `POST https://graph.facebook.com/v18.0/{phone_number_id}/messages` — Send WhatsApp replies (via FastAPI background task after AI processing)
- FCM HTTP API — Push notifications to student devices

## CI/CD & Deployment

**Hosting:**
- Docker / LXC (Linux containers) on self-managed server

**CI Pipeline:**
- None detected

## Environment Configuration

**Required env vars:**
- `DATABASE_URL` — PostgreSQL connection string
- `WHATSAPP_TOKEN` — Meta WhatsApp Business Cloud API bearer token
- `MCP_SERVICE_TOKEN` — Internal service token for MCP → FastAPI authentication
- OpenAI API key (for `text-embedding-3-small` embeddings — var name not yet defined)
- JWT secret key (var name not yet defined)
- FCM server key / service account (var name not yet defined)

**Secrets location:**
- Environment variables only — no `.env` file committed; secrets injected via Docker Compose env block

---

*Integration audit: 2026-04-15*
