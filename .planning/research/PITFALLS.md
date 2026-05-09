# Pitfalls Research — Desafio FCG3

**Domain:** FastAPI + LangChain + MCP Server + WhatsApp + PostgreSQL/PGVector
**Mode:** Brownfield / Subsequent milestone
**Date:** 2026-04-15

---

## Critical (data loss, security breach, or silent system failure)

### CRITICAL-1: HMAC Signature Validation After Body Consumed

**What goes wrong:** Reading `request.body()` after `request.json()` in FastAPI yields an empty bytes object. WhatsApp HMAC-SHA256 validation will always fail because the raw bytes have been consumed.

**Warning sign:** Signature validation passes in isolation but always fails with real webhook calls.

**Prevention:**
```python
@router.post("/webhook/whatsapp")
async def whatsapp_webhook(request: Request):
    raw_body = await request.body()          # read raw bytes FIRST
    payload = json.loads(raw_body)           # then parse manually
    
    signature = request.headers.get("X-Hub-Signature-256", "")
    expected = "sha256=" + hmac.new(
        WHATSAPP_APP_SECRET.encode(),
        raw_body,
        hashlib.sha256,
    ).hexdigest()
    if not hmac.compare_digest(signature, expected):
        raise HTTPException(status_code=403)
```

**Phase:** Webhook implementation — must be first thing written in the webhook handler.

---

### CRITICAL-2: IDOR on Resource Endpoints Without Ownership Check

**What goes wrong:** MCP passes resource IDs (enrollment_id, appointment_id) to FastAPI endpoints. If the endpoint doesn't verify the resource belongs to the requesting student, any student can manipulate another student's data by guessing IDs.

**The MCP cannot prevent this** — only the FastAPI endpoint can verify ownership.

**Warning sign:** Any mutating endpoint that accepts a resource ID without a WHERE clause that filters by `student_id`.

**Prevention:**
```python
# WRONG
enrollment = await session.get(Enrollment, enrollment_id)

# CORRECT — verify ownership explicitly
enrollment = await session.execute(
    select(Enrollment).where(
        Enrollment.id == enrollment_id,
        Enrollment.student_id == current_user.id,  # ownership check
    )
)
if not enrollment:
    raise HTTPException(status_code=404)
```

**Phase:** Every feature slice that handles mutations. Must be in integration tests.

---

### CRITICAL-3: `asyncio.create_task` Swallows All Exceptions Silently

**What goes wrong:** If the background processing task raises any exception (LLM error, DB error, WhatsApp API error), the student simply never receives a reply. No log, no error, no indication of failure.

**Warning sign:** Messages go unanswered intermittently with no trace in logs.

**Prevention:**
```python
def _handle_task_result(task: asyncio.Task) -> None:
    if not task.cancelled() and task.exception() is not None:
        logger.error(
            "Background task failed with unhandled exception",
            exc_info=task.exception(),
        )

task = asyncio.create_task(process_message(phone, wamid, message))
task.add_done_callback(_handle_task_result)
```

**Phase:** Infrastructure setup — implement before writing any background task logic.

---

### CRITICAL-4: SQLAlchemy Session Leak on Background Tasks

**What goes wrong:** Passing the FastAPI request-scoped `AsyncSession` (from `get_db`) into `asyncio.create_task` will fail because FastAPI closes the session when the request ends — before the background task runs. Any DB operation in the task raises `async with closed session`.

**Warning sign:** `sqlalchemy.exc.InvalidRequestError: This session is closed` in background task logs.

**Prevention:**
```python
# WRONG — db is closed before this runs
async def webhook_handler(request, db: AsyncSession = Depends(get_db)):
    asyncio.create_task(process_message(phone, db))  # ← db will be closed

# CORRECT — task opens its own session
async def process_message(phone: str, message: str):
    async with async_session_maker() as db:  # own lifecycle
        ...
```

**Phase:** Infrastructure setup — before implementing any background task.

---

### CRITICAL-5: Lazy Loading Raises `MissingGreenlet` in Async SQLAlchemy

**What goes wrong:** By default, SQLAlchemy ORM relationships are lazy-loaded. In async context, accessing a relationship attribute (e.g., `enrollment.course`) outside `await` raises `sqlalchemy.exc.MissingGreenlet: greenlet_spawn has not been called`.

**Warning sign:** `MissingGreenlet` errors when accessing related objects after a query.

**Prevention:**
```python
# In model definition — fail fast if accessed lazily
class Enrollment(Base):
    course = relationship("Course", lazy="raise")

# In queries — load explicitly
from sqlalchemy.orm import selectinload

result = await session.execute(
    select(Enrollment)
    .options(selectinload(Enrollment.course))
    .where(Enrollment.id == enrollment_id)
)
```

**Phase:** Database model definition — apply `lazy="raise"` at model definition time, then fix query by query.

---

## Moderate (degraded behavior or security weakness)

### MODERATE-1: WhatsApp Duplicate Message Processing

**What goes wrong:** WhatsApp resends webhook deliveries if it doesn't receive a 200 OK within 5 seconds, or on transient network failures. The same `wamid` can arrive multiple times.

**Prevention:** Deduplication by `whatsapp_message_id` — insert with unique constraint, catch `IntegrityError`.
Also: filter out WhatsApp status update events (delivery receipts) — they match the webhook structure but have `statuses` key instead of `messages`.

**Phase:** Webhook implementation.

---

### MODERATE-2: LangChain ReAct Infinite Loop on Tool Error

**What goes wrong:** If an MCP tool returns an error (5xx, schema mismatch), the ReAct agent may loop trying the same tool repeatedly until token budget is exhausted.

**Prevention:**
```python
agent_executor = AgentExecutor(
    ...
    max_iterations=5,           # hard stop
    max_execution_time=30.0,    # hard timeout in seconds
    handle_parsing_errors=True, # don't crash on malformed LLM output
)
```

**Phase:** AI service implementation.

---

### MODERATE-3: RAG Threshold 0.75 Uncalibrated

**What goes wrong:** The threshold in `docs/chatbot.md` (cosine similarity ≥ 0.75) is a placeholder. Without calibration, either too many irrelevant chunks are injected into the agent context (score too low) or valid answers are rejected (score too high).

**Prevention:** After ingesting the knowledge base, run 20–30 sample questions manually. Adjust threshold to the point where relevant chunks are retrieved and irrelevant ones are filtered. Document the calibration run.

**Phase:** Knowledge base ingest + AI service testing.

---

### MODERATE-4: Alembic PGVector Extension Missing Before First Migration

**What goes wrong:** If any migration that creates a `vector` column runs before `CREATE EXTENSION vector`, the migration fails with `type "vector" does not exist`.

**Prevention:** First migration file must be `001_enable_pgvector.py` and must only contain `op.execute("CREATE EXTENSION IF NOT EXISTS vector")`. All table migrations depend on it.

**Phase:** Alembic initialization.

---

### MODERATE-5: JWT Role Not Asserted on Protected Endpoints

**What goes wrong:** If the `require_role()` dependency is not applied to staff-only endpoints, any student with a valid JWT can access grade modification, document approval, and appointment management endpoints.

**Prevention:**
```python
def require_role(*roles: str):
    async def _check(current_user = Depends(get_current_user)):
        if current_user.role not in roles:
            raise HTTPException(status_code=403)
        return current_user
    return _check

# Usage
@router.post("/grades/update", dependencies=[Depends(require_role("staff"))])
async def update_grade(...): ...
```

**Phase:** Auth slice + all feature slices with staff-only operations.

---

### MODERATE-6: `ConversationBufferWindowMemory` Lost on Process Restart

**What goes wrong:** LangChain's in-memory `ConversationBufferWindowMemory` is lost when the container restarts. The agent "forgets" the conversation.

**Prevention:** Always reconstruct memory from DB on every agent invocation:

```python
async def build_memory(session_id: str, db: AsyncSession) -> ConversationBufferWindowMemory:
    messages = await get_last_n_messages(session_id, n=20, db=db)
    memory = ConversationBufferWindowMemory(k=20, return_messages=True)
    for msg in messages:
        if msg.role == "user":
            memory.chat_memory.add_user_message(msg.content)
        else:
            memory.chat_memory.add_ai_message(msg.content)
    return memory
```

**Phase:** AI service implementation.

---

### MODERATE-7: Non-Constant-Time Service Token Comparison

**What goes wrong:** Using `!=` to compare `X-Service-Token` is vulnerable to timing attacks. An attacker can measure response time differences to deduce the correct token character by character.

**Prevention:**
```python
import hmac

def validate_service_token(provided: str) -> bool:
    return hmac.compare_digest(provided, settings.MCP_SERVICE_TOKEN)
```

**Phase:** MCP Server + FastAPI service-token middleware.

---

### MODERATE-8: Alembic HNSW Index Not Detected by Autogenerate

**What goes wrong:** `alembic revision --autogenerate` does not detect HNSW indexes. The index will be silently missing from the generated migration.

**Prevention:** Always add HNSW index creation manually with `op.execute()`. Never rely on autogenerate for PGVector-specific features.

**Phase:** Database schema migration.

---

## Minor (friction and wasted debugging time)

### MINOR-1: LangChain Tool Schema Mismatch

Array fields in JSON tool schemas need explicit examples, otherwise the LLM may send them as strings or miss them entirely.

```python
@tool
def enroll_in_course(course_ids: list[str]) -> dict:
    """
    Enroll the student in one or more courses.
    
    Args:
        course_ids: List of course IDs to enroll in. Example: ["CS101", "CS201"]
    """
```

**Phase:** MCP Server tool definitions.

---

### MINOR-2: WhatsApp Graph API Version Hardcoded

Hardcoding `v18.0` in the URL will break when Meta deprecates the API version.

**Prevention:** `WHATSAPP_API_VERSION=v18.0` as env var. Use `f"https://graph.facebook.com/{settings.WHATSAPP_API_VERSION}/..."`.

**Phase:** WhatsApp client setup in `infrastructure/clients.py`.

---

### MINOR-3: Concurrent Messages Race Condition on Same Session

If a student sends two messages in rapid succession, two background tasks may run simultaneously on the same `chat_session`. The second task may read stale state (e.g., wrong message history).

**Prevention (MVP):** Per-session async lock in the background task:

```python
_session_locks: dict[str, asyncio.Lock] = {}

async def process_message(session_id: str, ...):
    lock = _session_locks.setdefault(session_id, asyncio.Lock())
    async with lock:
        ...
```

**Phase:** Webhook + AI service integration.

---

*Pitfalls audit: 2026-04-15 | All pitfalls specific to this stack and domain*
