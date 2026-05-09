# FEATURES.md — Plataforma Academica com Chatbot WhatsApp

**Project:** Desafio FCG3
**Mode:** Brownfield / Ecosystem research (Features dimension)
**Sources:** PROJECT.md, docs/api.md, docs/chatbot.md, docs/mcp.md, docs/database.md
**Confidence:** HIGH — all findings grounded directly in project spec docs
**Date:** 2026-04-15

---

## 1. Table Stakes

Features without which the system fails its stated purpose ("aluno envia mensagem no WhatsApp e recebe resposta precisa"). Each item maps to one or more endpoints and/or components already specified in the project docs.

### 1.1 Authentication — OTP via Email

**What it does:** A passwordless login flow using 6-digit time-limited codes delivered by Resend. Applies to both students and staff. Platform field (`whatsapp` | `app`) in the JWT determines session context.

**Endpoints:** `POST /auth/request-code`, `POST /auth/verify-code`, `POST /auth/logout`, `GET /auth/me`

**Key behaviors:**
- Code expires in 5 minutes
- 3 failed attempts → current code invalidated + new code sent automatically (no manual re-request required)
- Rate limiting on `/auth/request-code` to prevent email flooding
- JWT payload carries `role` (`student` | `staff`) and `jti` for revocation
- Sessions table stores `jti` only — not the full token — so revocation is a cheap UUID lookup

**DB tables:** `verification_codes`, `sessions`

---

### 1.2 Grades and Academic Performance (CRA)

**What it does:** Provides per-semester and full-history grade views. The `academic-summary` endpoint surfaces the CRA (Coeficiente de Rendimento Academico) — the weighted GPA used in Brazilian academic regulation.

**Endpoints:** `GET /students/{id}/grades`, `GET /students/{id}/transcript`, `GET /students/{id}/academic-summary`

**Key behaviors:**
- Grades stored as `grade_1`, `grade_2`, `grade_final` (DECIMAL 4,2)
- `status` per grade row: `in_progress`, `approved`, `failed`, `locked`
- CRA surface in `academic-summary.gpa` — see edge cases section for correct calculation

**DB tables:** `grades`, `enrollment_courses`

---

### 1.3 Enrollment (Matricula) with Draft-Confirm Flow

**What it does:** Students select courses during an active enrollment period. The two-step draft → confirm flow prevents accidental enrollment while keeping the WhatsApp conversation context intact across multiple turns.

**Endpoints:** `POST /enrollments`, `POST /enrollments/{id}/confirm`, `PUT /enrollments/{id}`, `DELETE /enrollments/{id}/courses/{course_id}`, `POST /enrollments/{id}/lock`, `GET /enrollment-periods/current`

**Key behaviors:**
- Draft created → agent shows summary → student confirms → `confirm_enrollment` called
- Draft not confirmed when period closes → status set to `cancelled` automatically
- Prerequisite check runs at `create_enrollment` time (not at display time)
- Lock enrollment (`trancamento`) is a separate action from cancelling a course
- Only one active enrollment per student per enrollment period

**DB tables:** `enrollments`, `enrollment_courses`, `enrollment_periods`

---

### 1.4 Document Request and Retrieval

**What it does:** Students request official academic documents (transcript, enrollment proof, declaration, certificate). Staff process requests and upload the file; students get a signed URL when ready.

**Endpoints:** `POST /documents`, `GET /documents`, `GET /documents/{id}`, `PUT /documents/{id}/status`

**Document types:** `transcript`, `enrollment_proof`, `declaration`, `certificate`

**Status lifecycle:** `requested` → `processing` → `ready` → `delivered`

**DB tables:** `documents`

---

### 1.5 Appointment Scheduling

**What it does:** Staff create time slots; students book one-on-one appointments with professors or coordinators via WhatsApp or the app. Cancellation is supported by both parties.

**Endpoints:** `GET /scheduling/slots`, `POST /scheduling/slots`, `POST /appointments`, `GET /appointments`, `PUT /appointments/{id}/cancel`

**Key behaviors:**
- Slot has `is_available` boolean — set to false when booked
- Default query window: today to +7 days
- Appointment reasons stored as free text (`TEXT NOT NULL`)
- Status lifecycle: `scheduled` → `completed` | `cancelled` | `no_show`

**DB tables:** `scheduling_slots`, `appointments`

---

### 1.6 WhatsApp Webhook with 5-Second Constraint

**What it does:** Receives and validates inbound WhatsApp Business Cloud API messages. Returns 200 OK within 5 seconds by dispatching the actual processing asynchronously via `asyncio.create_task`.

**Endpoints:** `POST /webhook/whatsapp` (receive), `GET /webhook/whatsapp` (challenge verification)

**Key behaviors:**
- HMAC-SHA256 validation of `X-Hub-Signature-256` header before any processing
- Saves `chat_message` (role: user) to DB immediately upon receipt
- `asyncio.create_task` dispatches agent processing; task must catch and log all exceptions internally (silent failures are the main risk of this pattern)
- Media messages receive a canned response without touching the LangChain agent
- Message deduplication via `whatsapp_message_id` field in `chat_messages`

**DB tables:** `chat_sessions`, `chat_messages`

---

### 1.7 WhatsApp Identity Verification (OTP in Chat)

**What it does:** Before the LangChain agent handles any request, the system checks whether the inbound phone number has an active authenticated session. If not, a conversational OTP flow runs in-band within the WhatsApp thread.

**Flow:**
1. Message arrives → check `chat_sessions` for active session linked to phone
2. No session → bot asks for institutional email
3. Calls `POST /auth/request-code` → Resend sends OTP
4. Bot collects code from next message → calls `POST /auth/verify-code`
5. On success → JWT stored, session linked to `student_id`, normal flow resumes
6. On failure → up to 3 attempts; on 3rd failure, new code sent automatically

**DB tables:** `chat_sessions`, `verification_codes`, `sessions`

---

### 1.8 MCP Server with 16 Tools

**What it does:** Acts as a security-aware proxy between the LangChain agent and the FastAPI backend. Injects `student_id` from session context so the agent never handles identity directly. Logs every tool call with full params, result, latency, and agent reasoning.

**All 16 tools (with API mapping):**

| Tool | Method | Endpoint |
|------|--------|----------|
| `get_student_info` | GET | `/students/{id}/academic-summary` |
| `get_grades` | GET | `/students/{id}/grades` |
| `get_transcript` | GET | `/students/{id}/transcript` |
| `get_available_courses` | GET | `/students/{id}/available-courses` |
| `create_enrollment` | POST | `/enrollments` |
| `confirm_enrollment` | POST | `/enrollments/{id}/confirm` |
| `drop_course` | DELETE | `/enrollments/{id}/courses/{cid}` |
| `lock_enrollment` | POST | `/enrollments/{id}/lock` |
| `request_document` | POST | `/documents` |
| `get_document_status` | GET | `/documents/{id}` |
| `get_available_slots` | GET | `/scheduling/slots` |
| `book_appointment` | POST | `/appointments` |
| `cancel_appointment` | PUT | `/appointments/{id}/cancel` |
| `get_curriculum` | GET | `/curriculum/active` |
| `get_course_prerequisites` | GET | `/courses/{id}/prerequisites` |
| `get_enrollment_period` | GET | `/enrollment-periods/current` |

**Security model:**
- All MCP→API calls use `X-Service-Token` header (`MCP_SERVICE_TOKEN` env var, never in source)
- `student_id` omitted from all tool schemas exposed to the agent — injected by MCP from session context
- Retry: one immediate retry on 5xx/timeout; 4xx errors do not retry

**Logging:** Every call writes to `mcp_action_logs` with `tool_name`, `input_params` (without `student_id`), `output_result`, `reasoning` (nullable), `latency_ms`, `status`, `retry`

**DB tables:** `mcp_action_logs`

---

### 1.9 LangChain ReAct Agent with RAG

**What it does:** Orchestrates the chatbot response. Uses a sliding window conversation memory (k=20) so multi-turn enrollment flows (8–12 turns) retain full context. Retrieves academic regulation documents via PGVector before generating a response.

**Components:**

| Component | Technology | Detail |
|-----------|------------|--------|
| Agent | LangChain ReAct | Decides tool vs RAG vs direct response |
| LLM | Provider-agnostic | Configured via env var; supports OpenAI and Gemini |
| Memory | ConversationBufferWindowMemory | k=20; persisted to `chat_messages` and restored on session resume |
| RAG retriever | PGVector + LangChain | Cosine similarity threshold: 0.75; below threshold → fallback response |
| Embedding model | `text-embedding-3-small` | Fixed at 1536 dimensions; must match HNSW index |
| RAG ingest | `scripts/ingest.py` | Manual script; chunk size 500 tokens, overlap 50 |

**Knowledge base documents:** `matricula.md`, `regulamento.pdf`, `faq.md`, `calendario.md`, `curriculo.md`

**System prompt rules (abridged):**
- Always respond in Brazilian Portuguese
- Confirm before any mutating action (enrollment, lock, appointment, document request)
- Never fabricate data — only use tool results and RAG context
- If RAG score < 0.75, direct student to secretaria

**DB tables:** `knowledge_base_chunks` (PGVector, HNSW index with `m=16`, `ef_construction=64`)

---

## 2. Differentiators

Features that are table stakes elsewhere but become competitive advantages specifically because they are academic-domain-specific rather than generic.

### 2.1 Prerequisite-Aware Course Listing

`GET /students/{id}/available-courses` does not simply list all catalog courses. It traverses the prerequisite graph and filters to only courses where all prerequisites have been passed. This prevents enrollment errors before they happen — a problem generic scheduling tools do not solve.

The response includes `prerequisites_met: true/false` per course, giving the agent context to explain *why* a student cannot enroll in a specific course.

### 2.2 Two-Confirmation Enrollment Flow

The draft → confirm two-step is academic-domain-specific because enrollment actions have regulatory consequences (grade records are created, institutional reports generated). Generic booking systems use single-step commitment. The draft state also provides a recoverable state if the conversation is interrupted mid-flow.

### 2.3 IDOR-Proof Tool Schemas

The MCP tool schemas deliberately omit `student_id`. An LLM cannot be prompted into accessing another student's data because the parameter does not exist in the tool interface. This is an architectural differentiator — most chatbot implementations pass user identity as a parameter, creating prompt injection attack surfaces.

### 2.4 Full Conversation Audit Trail

Every MCP tool call is logged with the agent's chain-of-thought reasoning (`reasoning` field, captured via `on_agent_action` callback). This means staff can see not only what the bot did but why it decided to do it — critical for academic dispute resolution and regulatory compliance.

### 2.5 Academic Regulation RAG

The RAG knowledge base covers academic-specific content: enrollment rules, academic calendar, grade regulations, jubilamento policy, minimum attendance, document types and turnaround times. Generic chatbot RAG pipelines don't have this domain structure. The threshold (0.75 cosine similarity) is set conservatively to prevent hallucinated academic rules.

---

## 3. Anti-Features (What NOT to Build in v1)

These are explicitly deferred. Each has a rationale. Adding any of these before the table-stakes features are stable would increase complexity without proportional value.

| Anti-Feature | Why Deferred | When to Revisit |
|---|---|---|
| **Whisper audio transcription** | Adds Whisper API dependency, cost, latency, and error surface. Text-only is sufficient for MVP WhatsApp coverage. | Post-MVP; requires Whisper API key and async transcription pipeline |
| **GPT-4o Vision (image analysis)** | Students do not need image analysis for grade/enrollment/document queries. Adds cost and scope. | Post-MVP; only valuable if document upload via WhatsApp is a use case |
| **Redis cache for conversation sessions** | `asyncio.create_task` + PostgreSQL is sufficient for MVP concurrency. Redis adds an infrastructure dependency. | When concurrent sessions exceed PostgreSQL connection pool limits |
| **FCM push notifications** | `fcm_tokens` table is scaffolded but sending is out of scope. Documents and appointments will eventually need push, but staff can manually check. | Next milestone; requires Firebase project setup and FCM SDK |
| **Knowledge base admin UI** | Staff can update the RAG knowledge base by re-running `ingest.py` via `docker exec`. A web UI for uploads adds frontend work. | Post-MVP; route is already noted in chatbot.md as `POST /staff/knowledge-base/upload` |
| **pg_cron for automated cleanup** | Expired `verification_codes` and `sessions` can be cleaned manually via `docker exec` SQL script. pg_cron requires PostgreSQL extension activation. | Next milestone alongside full infrastructure hardening |
| **Automatic semester progression** | `semester` field on student is updated manually by staff or via a separate script. Automating this requires academic calendar integration and business rule validation. | Requires confirmed academic calendar API or trigger |
| **Grade dispute workflow** | Students requesting grade review requires staff workflow, state machine, notifications, and likely legal document storage. Completely out of scope for v1. | Separate feature milestone |
| **Prerequisite waivers** | The system enforces prerequisites strictly. Staff-granted exceptions would require a separate approval flow. | Post-v1 only if institution reports actual need |
| **Sentry / external error monitoring** | Logging to `mcp_action_logs` and standard FastAPI exception handlers is sufficient for MVP. | Next milestone; add before production launch |

---

## 4. Domain Edge Cases

These are implementation-level correctness issues that are not obvious from the feature list but will produce wrong behavior if not handled explicitly.

### 4.1 CRA Calculation

**Risk:** The `gpa` field in `academic-summary` is calculated at query time. A naive average of `grade_final` values will produce wrong results.

**Correct formula:**
```
CRA = SUM(grade_final * credits) / SUM(credits)
```
where `credits` comes from joining `grades` → `enrollment_courses` → `courses.credits`.

**Exclusions that must apply:**
- Rows with `status = 'in_progress'` must be excluded (grade not yet finalized)
- Rows with `status = 'locked'` (trancamento) must be excluded — locked enrollments do not count toward CRA
- Guard against division by zero when a student has no completed courses (return `null` or `0.0`, not an exception)

**Implementation note:** The DB schema links `grades` to `enrollment_courses` via `enrollment_course_id` (NOT NULL), which in turn links to `courses`. The join is deterministic.

---

### 4.2 Prerequisite Tree Traversal

**Risk:** A naive prerequisite check that only looks at immediate prerequisites will miss multi-level chains (A requires B, B requires C — enrolling in A without C is wrong even if B was passed).

**Correct approach:** At enrollment time, for each requested course, recursively traverse the `prerequisites` table until all leaf nodes are found. Check that each leaf has a corresponding `grades` row with `status = 'approved'`.

**Schema:** `prerequisites(course_id, prerequisite_id)` — self-referential on `courses.id`. A recursive CTE is the standard PostgreSQL approach:

```sql
WITH RECURSIVE prereq_tree AS (
  SELECT prerequisite_id FROM prerequisites WHERE course_id = :target_course_id
  UNION ALL
  SELECT p.prerequisite_id FROM prerequisites p
  JOIN prereq_tree pt ON p.course_id = pt.prerequisite_id
)
SELECT * FROM prereq_tree;
```

**Cycle guard:** The curriculum data should be acyclic, but the recursive CTE should include a depth limit or visited-set guard to prevent infinite loops on corrupt data.

---

### 4.3 OTP Race Conditions

Two distinct race conditions exist in the OTP flow:

**Race A — Concurrent code requests from the same email:**
If a student (or attacker) calls `POST /auth/request-code` twice in rapid succession, two `verification_codes` rows are created. The second code is correct; the first is orphaned but still valid until it expires. Resolution: before inserting a new code, invalidate (set `used = true`) any existing non-expired, non-used codes for the same email.

**Race B — Expired code attempt counter increment:**
If a code expires between the student typing it and the server validating it, the `attempts` counter must NOT be incremented. The check sequence must be: (1) check `expires_at < NOW()` first → return expired error without touching `attempts`, then (2) check code value → if wrong, increment `attempts`.

**Atomicity:** Both operations (validate + mark used / validate + increment attempts) must be atomic. Use a single UPDATE with RETURNING or a SELECT FOR UPDATE to prevent double-validation from concurrent requests.

---

### 4.4 Appointment Slot Race Condition

**Risk:** Two students simultaneously see a slot as available (`is_available = true`) and both attempt to book it. Without concurrency control, both `POST /appointments` calls succeed, creating two appointments for the same slot.

**Correct approach:**
```sql
-- Inside the book_appointment transaction:
SELECT id FROM scheduling_slots WHERE id = :slot_id AND is_available = true FOR UPDATE;
-- If no row returned → slot taken, return 409 Conflict
UPDATE scheduling_slots SET is_available = false WHERE id = :slot_id;
INSERT INTO appointments (...) VALUES (...);
```

The `SELECT FOR UPDATE` acquires a row-level lock. The second concurrent transaction blocks until the first commits, then finds `is_available = false` and returns a 409.

**Agent behavior on 409:** The agent must surface this as "O horario selecionado foi reservado por outro aluno. Escolha outro horario." and re-call `get_available_slots`.

---

### 4.5 WhatsApp Verification State Machine Gap

**Risk:** The `chat_sessions` schema has no `verification_state` column. The OTP flow state ("waiting for email", "waiting for OTP code") is implicit — it must be reconstructed from the conversation history in `chat_messages`.

**Current schema gap:** The system relies on the last bot message content to determine what it was waiting for. This works for normal flows but breaks if:
- The bot crashes mid-verification and `chat_messages` has an incomplete entry
- The student sends an unexpected message type during verification (e.g., a sticker while waiting for the OTP code)

**Mitigation for v1:** The chatbot must handle the unexpected-message case gracefully by re-prompting ("Por favor, informe o codigo de 6 digitos que enviamos para seu email.") rather than crashing or advancing the flow incorrectly.

**Post-v1 fix:** Add `verification_state ENUM('none', 'awaiting_email', 'awaiting_otp') DEFAULT 'none'` to `chat_sessions`. This makes the state machine explicit and eliminates the fragile history-reconstruction pattern.

---

### 4.6 Silent Background Task Failures

**Risk:** The `asyncio.create_task` pattern for webhook processing returns 200 OK immediately and runs agent processing in the background. If the task raises an unhandled exception, it is silently discarded by the Python event loop.

**Required mitigation:** Every `asyncio.create_task` call must wrap the coroutine in an exception handler that logs the error:

```python
async def safe_process_message(session_id, message_id):
    try:
        await process_with_agent(session_id, message_id)
    except Exception as e:
        logger.error(f"Background task failed: session={session_id} error={e}", exc_info=True)
        # Optionally: send fallback WhatsApp message to student

task = asyncio.create_task(safe_process_message(session_id, message_id))
```

Without this, a crashing agent leaves the student with no response and no visible error in logs.

---

## 5. WhatsApp-Specific Constraints

These constraints are unique to the WhatsApp Business Cloud API channel and drive architectural decisions throughout the system.

| Constraint | Value | Impact |
|---|---|---|
| **Webhook response timeout** | 5 seconds | Mandatory `asyncio.create_task` for agent processing; 200 OK must be returned before agent finishes |
| **Message rendering** | Plain text only (in responses) | Do not use Markdown headers, HTML, or rich formatting in bot responses. WhatsApp renders `*bold*` but not `##` or `<br>`. Lists must use plain line breaks and dashes. |
| **Idempotency** | `whatsapp_message_id` stored in `chat_messages` | The WhatsApp API may deliver the same webhook event more than once. Before processing, check if `whatsapp_message_id` already exists in `chat_messages`. If yes, return 200 without reprocessing. |
| **Media handling** | No agent processing | Audio, image, document, sticker, location, video messages receive a canned text response without invoking LangChain. The media type is recorded in `chat_messages.media_type` for audit. |
| **No delivery receipts in MVP** | Status callbacks not handled | WhatsApp sends message delivery status callbacks (sent, delivered, read) to the same webhook. These must be recognized and ignored (return 200) without triggering agent processing. |
| **Phone as primary identifier** | `whatsapp_phone` in `chat_sessions` | Session lookup uses the sender's phone number. Phone must be stored exactly as WhatsApp sends it (E.164 format without `+`, e.g., `5521999999999`). |
| **Response send API** | Graph API v18.0 | `POST https://graph.facebook.com/v18.0/{phone_number_id}/messages` with `WHATSAPP_TOKEN` bearer auth. Failure to send response is a soft failure — the student simply receives no reply; it must be logged. |
| **Webhook challenge verification** | `GET /webhook/whatsapp` | WhatsApp sends a `hub.challenge` query param during webhook registration. The endpoint must echo the challenge value. This is a one-time setup step but must remain active. |

---

## 6. Feature Dependency Graph

Build order derived from hard dependencies. Features on the same level can be built in parallel.

```
Level 1 — Infrastructure (no dependencies)
├── PostgreSQL schema + Alembic migrations (all 17 tables)
├── Docker Compose (postgres, fastapi, ai_service, mcp_server)
└── Environment configuration (.env.example, MCP_SERVICE_TOKEN, WHATSAPP_TOKEN, RESEND_KEY)

Level 2 — Auth (depends on: schema)
└── OTP auth flow (request-code, verify-code, logout, /me)
    ├── verification_codes table operations
    ├── sessions table (jti-based revocation)
    ├── JWT middleware
    └── Resend email integration

Level 3 — Core API (depends on: auth, schema)
├── Students CRUD (staff-only) + academic-summary endpoint
├── Courses + Curriculum endpoints (read-only for v1)
├── Enrollment periods (staff CRUD + public current-period read)
├── Grades (staff write, student read) + CRA calculation
├── Documents (student request, staff status update, signed URL)
└── Scheduling (staff slot creation, student appointment booking)

Level 4 — MCP Server (depends on: Level 3 API fully operational)
├── Service Token middleware on FastAPI
├── All 16 MCP tools implemented
├── student_id session injection
├── mcp_action_logs write on every call
└── Retry logic (one immediate retry on 5xx/timeout)

Level 5 — AI Service (depends on: MCP server, schema)
├── RAG pipeline: ingest.py + PGVector HNSW index
├── LangChain ReAct agent + ConversationBufferWindowMemory
├── LLM provider abstraction (OpenAI / Gemini via env var)
└── MCP tools bound to agent

Level 6 — WhatsApp Integration (depends on: AI Service, auth)
├── Webhook endpoint (HMAC validation, 200 OK < 5s)
├── asyncio.create_task with exception logging wrapper
├── WhatsApp identity verification OTP flow (in-band)
├── Media type router (canned responses, no agent)
├── whatsapp_message_id idempotency check
└── WhatsApp send response (Graph API client)
```

**Critical path for a working end-to-end demo:**
Schema → Auth → Grades endpoint → MCP `get_grades` → LangChain agent → Webhook → WhatsApp identity verification

This path (6 layers) must be complete before any demo of the WhatsApp chatbot answering a grades query.

---

## 7. Quick Reference: Feature-to-Component Matrix

| Feature | FastAPI | MCP Server | AI Service | DB Tables |
|---------|---------|------------|------------|-----------|
| OTP Auth | `POST /auth/*` | — | — | verification_codes, sessions |
| Grades / CRA | `GET /students/{id}/grades` | get_grades | RAG fallback | grades, enrollment_courses |
| Transcript | `GET /students/{id}/transcript` | get_transcript | — | grades, courses |
| Enrollment | `POST /enrollments*` | create/confirm/drop/lock | create/confirm flow | enrollments, enrollment_courses, enrollment_periods |
| Documents | `POST /documents*` | request_document, get_document_status | request flow | documents |
| Scheduling | `GET|POST /scheduling/*`, `POST /appointments` | get_available_slots, book_appointment, cancel_appointment | booking flow | scheduling_slots, appointments |
| WhatsApp Webhook | `POST /webhook/whatsapp` | — | agent dispatch | chat_sessions, chat_messages |
| WA Identity Verification | `POST /auth/*` (reused) | — | in-band OTP | chat_sessions, verification_codes, sessions |
| MCP Tool Logging | — | all tools | — | mcp_action_logs |
| RAG Knowledge Base | — | — | ingest.py + retriever | knowledge_base_chunks |
| Prerequisite Check | `GET /students/{id}/available-courses` | get_available_courses, get_course_prerequisites | — | prerequisites, grades |
| Staff Dashboard | `GET /staff/dashboard` | — | — | all tables (aggregated) |
