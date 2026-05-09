# Project Research Summary

**Project:** Desafio FCG3 — Plataforma Academica com Chatbot WhatsApp
**Domain:** Multi-service academic platform (FastAPI + LangChain ReAct + MCP Server + PostgreSQL/PGVector + WhatsApp Business Cloud API)
**Researched:** 2026-04-15
**Confidence:** MEDIUM-HIGH

---

## Executive Summary

This is a multi-service backend platform centered on a WhatsApp chatbot that handles student academic operations — grades, enrollment, documents, and appointments — via natural language. The system is built on four coordinated services: a FastAPI REST backend, a LangChain AI service, a Model Context Protocol (MCP) server acting as a security proxy between the agent and the backend, and PostgreSQL with PGVector for relational data and semantic search. The architecture is well-specified in project docs and follows established patterns for each technology, but the integration layer between LangChain and MCP is the least-documented seam and carries the highest implementation risk.

The recommended build order is strictly bottom-up: infrastructure and schema first, then authentication, then the six business feature slices in parallel, then the MCP server (which depends on all API endpoints existing), then the AI service (which depends on MCP), and finally the WhatsApp webhook layer. This ordering is non-negotiable because every layer depends on the one below it — the chatbot cannot be demonstrated until all six prior levels are complete. The critical path for a minimal end-to-end demo is: schema → auth → grades endpoint → MCP `get_grades` tool → LangChain agent → webhook → WhatsApp identity verification.

The top risks are architectural, not feature-level. Silent background task failures (the `asyncio.create_task` pattern swallows exceptions by default), IDOR vulnerabilities on resource endpoints (every mutating endpoint must verify resource ownership, not just authenticate the caller), and the double-driver requirement for PostgreSQL (asyncpg for FastAPI/MCP, psycopg3 for LangChain) are the three issues most likely to cause production incidents if not addressed at the infrastructure phase. The MCP `student_id` injection pattern — where the LLM never sees or controls the `student_id` parameter — is the single most important security design decision in the system and must be preserved throughout implementation.

---

## Key Findings

### Recommended Stack

The stack is fully specified and largely determined by the existing project requirements. FastAPI with SQLAlchemy async (asyncpg driver) handles the REST backend and background webhook processing. LangChain with `langchain-postgres` (psycopg3 driver, NOT the deprecated `langchain-community` PGVector) handles the RAG pipeline and ReAct agent. The MCP server uses `mcp[cli]>=1.2.0` with `FastMCP` and **must** use `streamable-http` transport — stdio transport cannot cross Docker container boundaries. PostgreSQL runs via the `pgvector/pgvector:pg16` Docker image with the `vector` extension enabled as migration #001.

The two-driver PostgreSQL split is the most unusual stack constraint: asyncpg for the FastAPI app and MCP server, psycopg3 (via `psycopg[binary]`) for the LangChain service because `langchain-postgres` mandates psycopg3. These are separate `requirements.txt` files in separate service directories. Mixing them in one service is not supported.

**Core technologies:**
- `fastapi` + `uvicorn[standard]`: REST API and webhook receiver — project-mandated, no alternative considered
- `sqlalchemy[asyncio]>=2.0` + `asyncpg>=0.29`: async ORM for FastAPI and MCP services — required by async architecture; `expire_on_commit=False` is mandatory
- `alembic>=1.13`: schema migrations — async-configured; HNSW index must be hand-written (autogenerate ignores it)
- `mcp[cli]>=1.2.0` with `FastMCP`: MCP server — `streamable-http` transport required for Docker networking
- `langchain>=0.3` + `langchain-postgres>=0.0.9`: AI agent and vector store — psycopg3 mandated by langchain-postgres
- `langchain-openai` or `langchain-google-genai`: LLM provider — configurable via `LLM_PROVIDER` env var; both supported
- `pgvector/pgvector:pg16`: PostgreSQL with vector extension — single Docker image covers both relational and vector storage
- `pyjwt`: JWT issuance and validation — standard choice; sessions table stores only `jti` for cheap revocation
- `resend`: email OTP delivery — project-mandated transactional email provider

### Expected Features

All features are fully specified in project documentation. There are no ambiguous requirements — all 16 MCP tools, all API endpoints, and all DB tables are named and described in the source docs.

**Must have (table stakes) — 9 features:**
- OTP authentication via email (Resend) — passwordless, roles `student`/`staff`, rate-limited, in-band WhatsApp identity verification
- Grades and CRA (weighted GPA) — weighted average with credit join; excludes `in_progress` and `locked` statuses
- Enrollment with draft-confirm flow — two-step to handle regulatory consequences; prerequisite check at create time (recursive CTE)
- Document requests — four types, four-status lifecycle, signed URL delivery
- Appointment scheduling — slot booking with `SELECT FOR UPDATE` concurrency control
- WhatsApp webhook with 5-second constraint — HMAC-SHA256 validation; `asyncio.create_task` with done callback
- WhatsApp identity verification — conversational OTP flow within WhatsApp thread before agent access
- MCP server with 16 tools — student_id injected by MCP, never passed from agent; full call logging to `mcp_action_logs`
- LangChain ReAct agent with RAG — `ConversationBufferWindowMemory` k=20 rebuilt from DB on each invocation; PGVector cosine threshold 0.75

**Should have (differentiators — already in spec):**
- Prerequisite-aware course listing — traverses full prerequisite tree, not just immediate parents
- IDOR-proof tool schemas — `student_id` absent from all tool definitions exposed to the LLM
- Full agent reasoning audit trail — `on_agent_action` callback writes chain-of-thought to `mcp_action_logs.reasoning`
- Academic regulation RAG — domain-specific knowledge base (matricula, regulamento, FAQ, calendario, curriculo)

**Defer to v2+:**
- Whisper audio transcription — adds cost and complexity; text-only sufficient for MVP
- Redis cache for conversation sessions — PostgreSQL sufficient for MVP concurrency
- FCM push notifications — `fcm_tokens` table scaffolded but sending out of scope
- Knowledge base admin UI — staff run `ingest.py` via `docker exec` for MVP
- pg_cron automated cleanup — manual SQL scripts sufficient for MVP
- Grade dispute workflow — requires separate approval state machine and legal document storage
- Sentry / external error monitoring — add before production launch, not during MVP

### Architecture Approach

The system uses a Vertical Slice Architecture (VSA) inside the FastAPI service, with one directory per feature (`auth/`, `enrollment/`, `grades/`, `documents/`, `appointments/`, `students/`, `webhook/`) each containing `router.py`, `service.py`, `models.py`, `schemas.py`, and `dependencies.py`. Shared concerns (DB session, JWT dependency, error envelope, service token validation) live in `shared/` and `infrastructure/`. The MCP server is a separate Python service that acts as the sole caller of the FastAPI internal API, using a `X-Service-Token` header — this token dependency is applied per-router as a FastAPI dependency, not as global middleware, so it doesn't interfere with JWT-authenticated student/staff routes.

**Major components:**
1. `fastapi-app` (port 8000) — REST API, webhook receiver, OTP/JWT auth, all business logic, WhatsApp Graph API client
2. `langchain-service` (port 8001) — ReAct agent, PGVector RAG pipeline, conversation memory reconstruction from DB
3. `mcp-server` (port 8002) — 16 MCP tools, student_id injection, mcp_action_logs, one-retry policy on 5xx
4. `postgres` (port 5432) — PostgreSQL 16 with pgvector extension; 17 tables + HNSW index on `knowledge_base_chunks.embedding`

### Critical Pitfalls

1. **HMAC body consumed before validation** — FastAPI's `request.json()` consumes the raw bytes; call `await request.body()` first, then `json.loads()`. Never use the Pydantic body parameter in the webhook handler.

2. **asyncio.create_task silently swallows exceptions** — add `task.add_done_callback(_handle_task_result)` immediately after every `create_task` call. The callback must log the exception. Without this, failed agent invocations produce no error, no log, and no student reply.

3. **IDOR on resource endpoints** — every mutating endpoint that accepts a resource ID (enrollment_id, appointment_id, document_id) must add `AND student_id = current_user.id` to the query. The MCP server cannot enforce this — only the endpoint can.

4. **SQLAlchemy session passed into background task** — the FastAPI-injected `AsyncSession` is closed when the request ends, before the background task runs. Every background task must open its own session with `async with async_session_maker() as db`.

5. **SQLAlchemy lazy loading raises MissingGreenlet in async context** — declare `lazy="raise"` on all relationships at model definition time, then use `selectinload()` explicitly in every query that needs related data. This converts silent runtime errors into loud definition-time failures.

6. **PGVector extension must be migration #001** — any table with a `vector` column will fail if `CREATE EXTENSION IF NOT EXISTS vector` has not run first. The HNSW index must be hand-written with `op.execute()` since Alembic autogenerate ignores it.

---

## Implications for Roadmap

Based on the feature dependency graph and architectural constraints, 7 phases are recommended. The first three phases have no parallelism — each strictly gates the next. Phases 4 and 5 can proceed in parallel once Phase 3 is stable.

### Phase 1: Infrastructure and Schema
**Rationale:** Everything else depends on Docker networking and the database schema existing. The MCP transport choice (streamable-http), the two-driver PostgreSQL split, and the `service_healthy` depends_on condition must all be established before any application code is written. The pgvector extension migration must be #001.
**Delivers:** Running four-service Docker Compose stack with all 17 tables migrated and confirmed accessible from each service.
**Addresses:** All features (schema is shared infrastructure)
**Avoids:** MODERATE-4 (pgvector extension order), CRITICAL-4 (session lifecycle — infrastructure decision), Docker startup race conditions

### Phase 2: Authentication
**Rationale:** Auth gates every other feature. JWT middleware, `get_current_user`, `require_role`, and the `X-Service-Token` dependency must all exist before any business slice can be secured. OTP race conditions and the in-band WhatsApp verification flow both require the auth foundation to be stable and tested.
**Delivers:** Working OTP email flow, JWT issuance with role field, session jti revocation, rate limiting, and `require_role` dependency ready for use by all downstream slices.
**Addresses:** Table stakes 1.1 (OTP Auth), partial 1.7 (WhatsApp identity verification)
**Avoids:** MODERATE-5 (JWT role not asserted), OTP race conditions (edge cases 4.2 and 4.3), CRITICAL-2 (IDOR — sets up the ownership model)

### Phase 3: Business Feature Slices (REST API)
**Rationale:** All six slices (students, grades, enrollment, documents, appointments, courses/curriculum) can be built in parallel once auth is ready. The MCP server in Phase 4 depends on all 16 API endpoints existing and being testable via HTTP. The CRA calculation, prerequisite recursive CTE, and `SELECT FOR UPDATE` slot booking are the correctness-critical implementations in this phase.
**Delivers:** All FastAPI endpoints operational and integration-tested. Staff and student access correctly role-gated. CRA calculation correct per the credit-weighted formula.
**Addresses:** Table stakes 1.2 (Grades/CRA), 1.3 (Enrollment), 1.4 (Documents), 1.5 (Appointments); differentiator 2.1 (prerequisite-aware course listing)
**Avoids:** CRITICAL-2 (IDOR — ownership checks on every mutating endpoint), MODERATE-5 (role gating), edge case 4.1 (CRA calculation), edge case 4.2 (prerequisite tree), edge case 4.4 (slot race condition)

### Phase 4: MCP Server
**Rationale:** The MCP server is a pure proxy over the Phase 3 API. It cannot be implemented until all 16 target endpoints exist. This phase establishes the `student_id` injection pattern and the `mcp_action_logs` audit trail.
**Delivers:** All 16 MCP tools operational over `streamable-http` transport, `student_id` never in tool schemas, full logging to `mcp_action_logs`, one-retry policy on 5xx.
**Uses:** `mcp[cli]>=1.2.0`, `FastMCP`, `X-Service-Token` from settings, `asyncpg` for action log writes
**Avoids:** MODERATE-7 (timing-safe service token comparison), MINOR-1 (tool schema examples for list fields), IDOR by design (student_id omitted from all tool schemas)
**Research flag:** How `langchain-mcp-adapters` (or equivalent) injects per-request `student_id` into the `MCPClient` instance — this is the open question identified in STACK.md and must be resolved before this phase begins.

### Phase 5: AI Service (LangChain ReAct + RAG)
**Rationale:** Depends on MCP server being operational. The LangChain service connects to MCP over HTTP, uses `langchain-postgres` (psycopg3) for PGVector, and reconstructs conversation memory from DB on every invocation. The RAG threshold calibration is a required step after knowledge base ingest.
**Delivers:** Working ReAct agent that answers academic questions using tools and RAG, with `ConversationBufferWindowMemory` rebuilt from DB, LLM provider configurable via env var.
**Uses:** `langchain>=0.3`, `langchain-postgres>=0.0.9`, `psycopg[binary]>=3.1`, `langchain-openai` or `langchain-google-genai`, `text-embedding-3-small` at 1536 dimensions
**Avoids:** MODERATE-2 (ReAct infinite loop — `max_iterations=5`, `max_execution_time=30.0`), MODERATE-3 (RAG threshold calibration — run 20-30 sample queries), MODERATE-6 (memory lost on restart — always rebuild from DB)

### Phase 6: WhatsApp Webhook and Integration
**Rationale:** The final integration layer. All backend services must be fully operational before the webhook is meaningful. The 5-second constraint, HMAC validation, message deduplication, and conversational OTP flow all come together here. The `asyncio.create_task` infrastructure must be hardened before this phase begins.
**Delivers:** End-to-end working chatbot: student sends WhatsApp message → identity verified → agent invoked → MCP tool called → FastAPI responds → LangChain generates reply → WhatsApp Graph API sends response.
**Addresses:** Table stakes 1.6 (webhook), 1.7 (WhatsApp identity verification), 2.3 (IDOR-proof MCP), 2.4 (audit trail)
**Avoids:** CRITICAL-1 (HMAC body consumption order), CRITICAL-3 (create_task done callback), MODERATE-1 (message deduplication by wamid), MINOR-2 (Graph API version via env var), MINOR-3 (per-session async lock for rapid messages), edge case 4.5 (verification state machine gap — graceful re-prompt), edge case 4.6 (background task exception logging)

### Phase Ordering Rationale

- Phases 1–3 are strictly sequential: each is a hard dependency for the next. No phase can begin until its predecessor is integration-tested.
- Phases 4 and 5 have a soft dependency: MCP must exist before the AI service can connect to it, but Phase 5 RAG pipeline work (knowledge base ingest, embedding setup, threshold calibration) can begin in parallel with Phase 4 development.
- Phase 6 is the final integration phase — it has zero novel business logic; its entire complexity is in wiring the existing pieces together correctly under WhatsApp's constraints.
- The feature dependency graph in FEATURES.md (6 levels) maps directly onto Phases 1–6 here.

### Research Flags

Phases requiring `/gsd-research-phase` during planning:

- **Phase 4 (MCP Server):** The open question from STACK.md — how `langchain-mcp-adapters` (or an equivalent mechanism) injects per-request `student_id` into MCP tool calls from the LangChain side — is unresolved. This is the single highest-risk unknown in the project. The MCP Python SDK docs and LangChain docs address the general pattern but the per-request context injection mechanism needs a concrete working example before implementation begins.
- **Phase 5 (AI Service):** The interaction between `ConversationBufferWindowMemory` and LangChain's newer `RunnableWithMessageHistory` API (LangChain 0.3+) may have changed. Confirm the correct memory pattern for ReAct agents in LangChain 0.3 before implementation.

Phases with well-established patterns (skip research-phase):

- **Phase 1 (Infrastructure):** Docker Compose with healthchecks and Alembic async configuration are fully documented patterns. The exact code is in STACK.md and ARCHITECTURE.md.
- **Phase 2 (Auth):** OTP + JWT + FastAPI dependency injection is a standard pattern with no novel elements.
- **Phase 3 (Business Slices):** Standard FastAPI CRUD with SQLAlchemy async. The CRA calculation and prerequisite recursive CTE are specified precisely in FEATURES.md edge cases.
- **Phase 6 (Webhook):** WhatsApp Business Cloud API webhook patterns are well-documented. All constraints are enumerated in FEATURES.md section 5.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM | Core FastAPI/SQLAlchemy/Alembic patterns are HIGH confidence from official docs. The two-driver PostgreSQL split and `langchain-postgres` mandate are MEDIUM — confirmed by library docs but less community validation. |
| Features | HIGH | All features derived directly from project spec docs (PROJECT.md, docs/api.md, docs/chatbot.md, docs/mcp.md, docs/database.md). No inference required. |
| Architecture | HIGH for VSA/Docker/Alembic | MEDIUM for LangChain-MCP integration boundary. VSA, Docker networking, and async Alembic are standard patterns. The per-request `student_id` injection mechanism across the LangChain→MCP boundary is the one unresolved design question. |
| Pitfalls | HIGH | All pitfalls are specific to the exact libraries and patterns in use. The async SQLAlchemy, create_task, and HMAC pitfalls are well-documented failure modes. |

**Overall confidence:** MEDIUM-HIGH

### Gaps to Address

- **LangChain → MCP per-request student_id injection:** How does the `MCPClient` (or `langchain-mcp-adapters` equivalent) pass `student_id` from the WhatsApp session context into each MCP tool invocation? The architecture specifies that MCP injects it, but the mechanism for providing it at tool-call time from the LangChain side is not specified. Resolve before Phase 4 begins. See: STACK.md open question at end of LangChain Agent section.

- **LangChain 0.3 memory API:** `ConversationBufferWindowMemory` may have changed behavior or been superseded in LangChain 0.3+. Confirm the correct pattern for ReAct agents before Phase 5 begins.

- **RAG threshold calibration:** The 0.75 cosine similarity threshold (0.25 distance) is a placeholder. Calibration requires the knowledge base to be ingested and sample queries to be run. This cannot be done until Phase 5. Plan for a calibration step before the AI service is considered complete.

- **WhatsApp verification_state schema gap:** The `chat_sessions` table has no `verification_state` column. The OTP flow state must be inferred from message history, which is fragile. FEATURES.md edge case 4.5 documents this. The MVP mitigation (graceful re-prompt on unexpected input) is sufficient for v1, but the post-v1 fix (`verification_state` enum column) should be added to the backlog immediately.

---

## Sources

### Primary (HIGH confidence)
- Official FastAPI docs — async SQLAlchemy patterns, dependency injection, request lifecycle
- Official MCP Python SDK docs (modelcontextprotocol.io) — FastMCP, streamable-http transport
- Official SQLAlchemy 2.0 async docs — `async_session_maker`, `expire_on_commit`, `selectinload`
- Official Alembic docs — async env.py pattern
- Project spec docs (PROJECT.md, docs/api.md, docs/chatbot.md, docs/mcp.md, docs/database.md) — all feature and schema specifications

### Secondary (MEDIUM confidence)
- `langchain-postgres` PyPI / GitHub — psycopg3 requirement, PGVector class API, JSONB metadata
- `pgvector-python` library docs — Vector column type, `cosine_distance` operator
- LangChain docs — ReAct agent, AgentExecutor config, ConversationBufferWindowMemory
- Docker Compose docs — healthcheck `condition: service_healthy` pattern

### Tertiary (LOW confidence — needs validation)
- `langchain-mcp-adapters` integration pattern for per-request context injection — needs a concrete working example; current understanding is inferential

---

*Research completed: 2026-04-15*
*Ready for roadmap: yes*
