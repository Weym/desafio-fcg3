# Roadmap — Desafio FCG3

**Milestone:** M1 — Backend + AI Service + MCP Server
**Granularity:** Standard
**Coverage:** 69/69 requirements mapped
**Last Updated:** 2026-04-15

---

## Phases

- [ ] **Phase 1: Infrastructure & Schema** — Docker Compose running, all 17 tables migrated, seed data loaded
- [ ] **Phase 2: Authentication** — OTP email flow, JWT with roles, session revocation, auth middleware
- [ ] **Phase 3: Business Feature Slices** — All FastAPI feature endpoints (students, courses, enrollment, grades, documents, appointments, staff dashboard)
- [ ] **Phase 4: MCP Server** — 16 tools over streamable-http, student_id injection, mcp_action_logs
- [ ] **Phase 5: AI Service** — LangChain ReAct agent, RAG pipeline, provider-agnostic LLM, knowledge base ingest
- [ ] **Phase 6: WhatsApp Webhook & Integration** — End-to-end chatbot flow, webhook hardening, chat visibility, test suite

---

## Phase Details

### Phase 1: Infrastructure & Schema

**Goal:** The four-service Docker stack starts cleanly and every application table exists in the database, seeded with curriculum data ready for testing.
**Depends on:** None
**Requirements:** INFRA-01, INFRA-02, INFRA-03, INFRA-04

### Success Criteria
1. Running `docker compose up` brings all four containers (postgres, fastapi-app, langchain-service, mcp-server) to a healthy state with passing healthchecks.
2. Running `alembic upgrade head` creates all 17 tables (including the pgvector extension as migration #001) and the HNSW index on `knowledge_base_chunks.embedding` — verified by `\dt` in psql.
3. All required environment variables are documented in `.env.example` so the project can be configured from scratch without reading source code.
4. Running the seed script populates the `curriculum`, `curriculum_courses`, and `courses` tables with 8 semesters and ~40 disciplines including prerequisite relationships.

### Plans
- [ ] Plan 1.1: Docker Compose & networking — define four services with `service_healthy` depends_on, app-network and data-network, port mappings
- [ ] Plan 1.2: Alembic async configuration — `env.py` async setup, migration #001 (pgvector extension), full schema migrations for all 17 tables + indexes
- [ ] Plan 1.3: Environment configuration — `.env.example` with all variables; `config.py` / `settings.py` with Pydantic BaseSettings
- [ ] Plan 1.4: Seed script — `scripts/seed.py` loading curriculum, courses, and prerequisites for CC 8-semester program

---

### Phase 2: Authentication

**Goal:** Students and staff can authenticate via email OTP, receive role-bearing JWTs, and the auth middleware is ready to protect all downstream endpoints.
**Depends on:** Phase 1
**Requirements:** AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05

### Success Criteria
1. User can request a 6-digit OTP to their email and receive it within seconds via Resend; the code expires after 5 minutes.
2. User can submit the OTP and receive a JWT containing `role` (student | staff) and a unique `jti`; the verification code is marked used and cannot be reused.
3. System automatically invalidates a code and issues a new one after 3 failed attempts; expired codes do not count toward the attempt limit.
4. Authenticated user can call `POST /auth/logout` and subsequent requests with the same JWT are rejected (jti revoked in `sessions` table).
5. Authenticated user can call `GET /auth/me` and receive their own profile data.

### Plans
- [ ] Plan 2.1: OTP request & email delivery — `POST /auth/request-code`, Resend integration, rate limiting, `verification_codes` table writes
- [ ] Plan 2.2: OTP verification & JWT issuance — `POST /auth/verify-code`, attempt counting, code invalidation, JWT with role + jti, session creation
- [ ] Plan 2.3: Auth middleware & dependencies — `get_current_user`, `require_role`, JWT validation, jti revocation check, `X-Service-Token` dependency for MCP routes
- [ ] Plan 2.4: Session management — `POST /auth/logout`, `GET /auth/me`, integration tests (TEST-01 coverage)

---

### Phase 3: Business Feature Slices

**Goal:** All FastAPI business endpoints are operational, role-gated, and IDOR-safe — providing the complete API surface that the MCP server will proxy in Phase 4.
**Depends on:** Phase 2
**Requirements:** STU-01, STU-02, STU-03, STU-04, STU-05, STU-06, STU-07, COURSE-01, COURSE-02, COURSE-03, CURR-01, CURR-02, ENROLL-01, ENROLL-02, ENROLL-03, ENROLL-04, ENROLL-05, ENROLL-06, ENROLL-07, ENROLL-08, ENROLL-STAFF-01, ENROLL-STAFF-02, ENROLL-STAFF-03, GRADES-01, GRADES-02, GRADES-03, GRADES-04, DOCS-01, DOCS-02, DOCS-03, DOCS-04, APPT-01, APPT-02, APPT-03, APPT-04, APPT-STAFF-01, STAFF-01

### Success Criteria
1. Staff can list, create, update, and soft-delete students; both student and staff can view student detail and academic summary including CRA, with ownership verified on every mutating operation.
2. Authenticated user can browse courses and curriculum; system returns full recursive prerequisite tree for any course; student receives a filtered list of disciplines eligible for enrollment respecting all unmet prerequisites.
3. Student can move an enrollment through the full draft → confirmed lifecycle, drop individual courses or lock the entire enrollment, and the system rejects enrollment outside the active period or with unmet prerequisites.
4. Student can view grades per discipline and full academic history; CRA is calculated correctly (credit-weighted, excluding in-progress and locked statuses, safe against division by zero); staff can post and update grades.
5. Student can request documents and list their statuses; staff can update document status and attach a file URL; student can book, view, and cancel appointments; staff can create scheduling slots.

**Plans:** 8 plans

Plans:
- [ ] 03-01-PLAN.md — Shared infrastructure: pagination, error handling, dual-auth, IDOR protection, base CRUD service
- [ ] 03-02-PLAN.md — Students slice: CRUD, academic summary (STU-06), available courses with prereq filter (STU-07)
- [ ] 03-03-PLAN.md — Courses & curriculum slice: listing, detail, recursive CTE prerequisite tree (COURSE-03), curriculum endpoints
- [ ] 03-04-PLAN.md — Enrollment slice: period management, draft-confirm flow, course drop/lock, prereq+period validation, IDOR checks
- [ ] 03-05-PLAN.md — Grades slice: grades by discipline/period, transcript, CRA calculation (D-07/D-08), staff grade entry
- [ ] 03-06-PLAN.md — Documents slice: student request/listing, staff status update + file URL
- [ ] 03-07-PLAN.md — Appointments slice: slot creation, availability query, SELECT FOR UPDATE booking, cancellation
- [ ] 03-08-PLAN.md — Staff dashboard: KPI aggregation (total students, active enrollments, pending docs, appointments, chat sessions)

---

### Phase 4: MCP Server

**Goal:** The MCP server exposes all 16 tools over streamable-http transport, injects student_id from session context (never from the agent), and logs every tool call to mcp_action_logs.
**Depends on:** Phase 3
**Requirements:** MCP-01, MCP-02, MCP-03, MCP-04, MCP-05

### Success Criteria
1. MCP server starts and is reachable at port 8002; all 16 tools listed in `docs/mcp.md` are registered and callable over streamable-http transport.
2. `student_id` does not appear in any tool's input schema — it is resolved from the active session context inside the MCP server before every API call.
3. Every tool invocation produces a row in `mcp_action_logs` with tool_name, input_params (without student_id), output_result, latency_ms, retry status, and reasoning when available.
4. Requests from MCP to FastAPI without a valid `X-Service-Token` (compared via `hmac.compare_digest`) are rejected with 401.
5. On a 5xx response or timeout from FastAPI, MCP retries exactly once; 4xx responses are not retried.

**Plans:** 4 plans

Plans:
- [ ] 04-01-PLAN.md — MCP scaffold: FastMCP app, settings, asyncpg pool, httpx client, healthcheck, session resolver, tool call middleware (logging + retry)
- [ ] 04-02-PLAN.md — Read-only tools (Group A): get_student_info, get_available_courses, get_grades, get_transcript, get_curriculum, get_course_prerequisites, get_enrollment_period
- [ ] 04-03-PLAN.md — Write/action tools (Group B): create_enrollment, confirm_enrollment, drop_course, lock_enrollment, request_document, get_document_status, get_available_slots, book_appointment, cancel_appointment
- [ ] 04-04-PLAN.md — Integration tests: session resolution, middleware retry/logging, tool schema validation, student_id absence, X-Service-Token verification

---

### Phase 5: AI Service

**Goal:** The LangChain ReAct agent answers student academic questions in Portuguese, using MCP tools for live data and PGVector RAG for regulation and policy, with any LLM provider configurable by environment variable.
**Depends on:** Phase 4
**Requirements:** AI-01, AI-02, AI-03, AI-04, AI-05

### Success Criteria
1. Agent receives a student message, selects appropriate MCP tools, calls them, and generates a coherent Portuguese-language response — observable end-to-end without WhatsApp by directly invoking the service HTTP endpoint.
2. Conversation context is rebuilt from the last 20 messages stored in `chat_messages` on every invocation; restarting the langchain-service container does not lose conversation history.
3. RAG retriever finds relevant policy chunks from the knowledge base with cosine similarity threshold calibrated at ≥ 0.75 (distance ≤ 0.25); irrelevant queries return no RAG context rather than noisy chunks.
4. Setting `LLM_PROVIDER=gemini` in the environment switches the agent to Gemini without any code changes; setting `LLM_PROVIDER=openai` uses OpenAI — both produce valid responses.
5. Running `python scripts/ingest.py` processes all five knowledge base documents (`matricula.md`, `regulamento.pdf`, `faq.md`, `calendario.md`, `curriculo.md`), generates embeddings, and stores chunks in `knowledge_base_chunks`.

**Plans:** 5 plans

Plans:
- [ ] 05-01-PLAN.md — AI service scaffold: FastAPI app, psycopg3 DB layer, LLM factory, system prompt, config
- [ ] 05-02-PLAN.md — Knowledge base ingest: document chunking, text-embedding-3-small embeddings, PGVector storage
- [ ] 05-03-PLAN.md — RAG pipeline: search_knowledge_base tool with pgvector cosine similarity, 0.75 threshold
- [ ] 05-04-PLAN.md — ReAct agent: create_agent with MCP tool binding (langchain-mcp-adapters), conversation memory, provider-agnostic LLM
- [ ] 05-05-PLAN.md — AI service /chat endpoint: receives message + session_id, invokes agent, saves response to chat_messages

---

### Phase 6: WhatsApp Webhook & Integration

**Goal:** A student can send a WhatsApp message and receive an AI-powered response about their academic situation — the end-to-end chatbot flow is operational and hardened against the five-second timeout, signature spoofing, and background task failures.
**Depends on:** Phase 5
**Requirements:** WH-01, WH-02, WH-03, WH-04, WH-05, CHAT-01, CHAT-02, CHAT-03, TEST-01, TEST-02, TEST-03, TEST-04, TEST-05

### Success Criteria
1. WhatsApp webhook challenge (`GET /webhook/whatsapp?hub.challenge=...`) is answered correctly, enabling webhook registration with Meta.
2. A text message sent via WhatsApp arrives at `POST /webhook/whatsapp`, passes HMAC-SHA256 validation, gets saved to `chat_messages`, and returns 200 OK in under 5 seconds — with background agent processing dispatched via `asyncio.create_task` and a `done_callback` that logs any exception.
3. A media message (audio, image, video, document, sticker, location) receives the appropriate standard reply without involving the agent; the media type is recorded in `chat_messages`.
4. Sending the same WhatsApp message ID twice results in only one `chat_messages` row (deduplication by `whatsapp_message_id`).
5. Staff can list chat sessions and view messages for any session; staff can view MCP action logs for a session showing tool calls, parameters, and reasoning.

**Plans:** 4 plans

Plans:
- [ ] 06-01-PLAN.md — Webhook core: WhatsApp client, HMAC validation, GET/POST endpoints, verification state migration, message routing
- [ ] 06-02-PLAN.md — Background processing: AI service integration, retry/fallback, per-session lock, session lifecycle, pg_cron auto-close
- [ ] 06-03-PLAN.md — Chat visibility: staff endpoints for sessions, messages, and MCP action logs
- [ ] 06-04-PLAN.md — Test suite: TEST-04 (HMAC + dedup + media), TEST-05 (service token), verification state, background tasks, chat visibility

---

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Infrastructure & Schema | 0/4 | Not started | - |
| 2. Authentication | 0/4 | Not started | - |
| 3. Business Feature Slices | 0/7 | Not started | - |
| 4. MCP Server | 0/4 | Planned | - |
| 5. AI Service | 0/5 | Planned | - |
| 6. WhatsApp Webhook & Integration | 0/4 | Planned | - |
