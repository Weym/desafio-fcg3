# Architecture Research — Desafio FCG3

**Domain:** Multi-service academic platform (FastAPI + LangChain + MCP Server + PostgreSQL+PGVector)
**Mode:** Brownfield / Subsequent milestone
**Date:** 2026-04-15

---

## 1. VSA Directory Structure (FastAPI)

```
backend/src/
├── main.py                     # app factory, lifespan, middleware mount
├── routes.py                   # single aggregator: includes all slice routers
├── features/
│   ├── auth/
│   │   ├── router.py           # APIRouter with prefix="/auth"
│   │   ├── service.py          # business logic (stateless functions / class)
│   │   ├── models.py           # SQLAlchemy ORM models
│   │   ├── schemas.py          # Pydantic request/response schemas
│   │   └── dependencies.py     # slice-specific FastAPI deps (e.g. require_role)
│   ├── enrollment/
│   │   └── ...
│   ├── grades/
│   │   └── ...
│   ├── documents/
│   │   └── ...
│   ├── appointments/
│   │   └── ...
│   ├── students/
│   │   └── ...
│   └── webhook/
│       └── ...
├── infrastructure/
│   ├── database.py             # AsyncEngine, async_session_maker, Base
│   ├── settings.py             # Pydantic BaseSettings (env vars)
│   └── clients.py              # httpx clients for WhatsApp API, Resend
└── shared/
    ├── dependencies.py         # get_db (AsyncSession), get_current_user, require_role
    ├── errors.py               # standard error envelope factory
    └── middleware.py           # JWT middleware, Service Token validation dependency
```

**Router registration in `main.py`:**

```python
from fastapi import FastAPI
from src.features.auth.router import router as auth_router
from src.features.enrollment.router import router as enrollment_router
# ... etc

app = FastAPI()
app.include_router(auth_router, prefix="/api/v1")
app.include_router(enrollment_router, prefix="/api/v1")
```

**X-Service-Token — dependency, not global middleware.** Apply as a FastAPI dependency on the specific endpoints that MCP calls, not as global middleware. This avoids blocking JWT-authenticated routes.

---

## 2. LangChain → MCP → FastAPI Call Chain

```
Student (WhatsApp)
    ↓  POST /webhook/whatsapp
FastAPI (fastapi-app:8000)
    → asyncio.create_task(process_message)
    → 200 OK immediately

Background task:
LangChain Agent (langchain-service:8001)
    → ConversationBufferWindowMemory (k=20 from DB)
    → PGVector RAG query (postgres:5432, cosine distance ≤ 0.25)
    → ReAct: decide tool
    → HTTP to MCP Server (mcp-server:8002/sse)

MCP Server (mcp-server:8002)
    → student_id injected from session context (never from tool schema)
    → HTTP to FastAPI (fastapi-app:8000/api/v1)
    → X-Service-Token header
    → logs call to mcp_action_logs
    → returns result to LangChain

LangChain Agent
    → generates response text
    → saves chat_message (role: assistant) to DB
    → POST to WhatsApp Cloud API (graph.facebook.com)
```

**`student_id` injection:** The `MCPClient` instance is initialized with `student_id` from the WhatsApp session context. Tool schemas never include `student_id` as a parameter — the MCP server adds it before every FastAPI call. This is the IDOR boundary.

**Error propagation:**
- FastAPI 4xx → MCP logs `status=error`, returns structured error to agent
- FastAPI 5xx / timeout → one immediate retry, then log `status=error`
- LLM failure → `try/except` around `agent.invoke()`, send apology message via WhatsApp API

---

## 3. asyncio.create_task Failure Handling

**Problem:** Uncaught exceptions in `create_task` are silently discarded.

**Fix — `add_done_callback` pattern:**

```python
import asyncio
import logging

logger = logging.getLogger(__name__)

def _handle_task_result(task: asyncio.Task) -> None:
    if not task.cancelled() and task.exception() is not None:
        logger.error(
            "Background task failed",
            exc_info=task.exception(),
            extra={"task_name": task.get_name()},
        )
        # Optionally: send apology to WhatsApp

async def process_whatsapp_message(phone: str, message: str, session_id: str):
    # own session — never reuse FastAPI request session
    async with async_session_maker() as db:
        try:
            ...
        except Exception:
            logger.exception("process_message failed", extra={"phone": phone})
            raise

# In webhook handler:
task = asyncio.create_task(
    process_whatsapp_message(phone, message, session_id),
    name=f"process_msg_{wamid}",
)
task.add_done_callback(_handle_task_result)
```

**DB session in background task:** Must use `async with async_session_maker() as db` — never pass the FastAPI-injected `db` session. The request session closes before the task finishes.

---

## 4. PGVector with SQLAlchemy Models

**Model definition:**

```python
from pgvector.sqlalchemy import Vector
from sqlalchemy import Column, String, Integer, Text
from src.infrastructure.database import Base

class KnowledgeBaseChunk(Base):
    __tablename__ = "knowledge_base_chunks"

    id = Column(Integer, primary_key=True)
    content = Column(Text, nullable=False)
    source = Column(String(255))
    embedding = Column(Vector(1536), nullable=False)
```

**Similarity query (cosine):**

```python
from pgvector.sqlalchemy import cosine_distance

SIMILARITY_THRESHOLD = 0.75
DISTANCE_THRESHOLD = 1 - SIMILARITY_THRESHOLD  # = 0.25

async def similarity_search(query_embedding: list[float], db: AsyncSession, limit: int = 5):
    result = await db.execute(
        select(KnowledgeBaseChunk)
        .where(cosine_distance(KnowledgeBaseChunk.embedding, query_embedding) <= DISTANCE_THRESHOLD)
        .order_by(cosine_distance(KnowledgeBaseChunk.embedding, query_embedding))
        .limit(limit)
    )
    return result.scalars().all()
```

> ⚠️ Common error: `<=> >= 0.75` is WRONG. Cosine distance = 1 - cosine similarity. Use `<= 0.25`.

---

## 5. Docker Service Hostnames and Ports

| From Container | To Container | URL |
|----------------|--------------|-----|
| `fastapi-app` | `postgres` | `postgresql+asyncpg://user:pass@postgres:5432/academic_db` |
| `mcp-server` | `postgres` | `postgresql+asyncpg://user:pass@postgres:5432/academic_db` |
| `langchain-service` | `postgres` | `postgresql+psycopg://user:pass@postgres:5432/academic_db` |
| `langchain-service` | `mcp-server` | `http://mcp-server:8002/sse` |
| `mcp-server` | `fastapi-app` | `http://fastapi-app:8000/api/v1` |
| external | `fastapi-app` | `http://localhost:8000/api/v1` |

**Container service names = DNS hostnames** within the Docker network. `depends_on` with `condition: service_healthy` on postgres is required — services crash on startup without it.

**Two Docker networks:**

```yaml
networks:
  app-network:    # fastapi-app ↔ langchain-service ↔ mcp-server
  data-network:   # all services ↔ postgres (isolate DB from external)
```

---

## 6. Alembic with PGVector

**Migration 001 — must be first:**

```python
# alembic/versions/001_enable_pgvector.py
def upgrade():
    op.execute("CREATE EXTENSION IF NOT EXISTS vector")

def downgrade():
    op.execute("DROP EXTENSION IF EXISTS vector")
```

**HNSW index — hand-written (autogenerate doesn't detect it):**

```python
def upgrade():
    op.execute(
        "CREATE INDEX knowledge_base_chunks_embedding_idx "
        "ON knowledge_base_chunks "
        "USING hnsw (embedding vector_cosine_ops) "
        "WITH (m = 16, ef_construction = 64)"
    )
```

**`alembic/env.py` — async pattern:**

```python
from sqlalchemy.ext.asyncio import async_engine_from_config

async def run_async_migrations():
    config_section = config.get_section(config.config_ini_section)
    connectable = async_engine_from_config(config_section, prefix="sqlalchemy.")
    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)

def run_migrations_online():
    asyncio.run(run_async_migrations())
```

---

## Build Order (for Roadmap)

```
Level 1: Infrastructure
  → Docker Compose (all 4 services + networks + healthchecks)
  → PostgreSQL + PGVector extension
  → Alembic configuration + migration 001 (extension)
  → .env.example + BaseSettings

Level 2: Database Schema
  → All 17 tables (migrations 002–010)
  → HNSW index on knowledge_base_chunks.embedding

Level 3: FastAPI Core
  → main.py app factory
  → JWT middleware + get_current_user dependency
  → X-Service-Token dependency
  → Standard error envelope

Level 4: Auth Feature Slice
  → OTP generation + Resend integration
  → JWT issuance with role field
  → Rate limiting (3 attempts)

Level 5: Business Feature Slices (parallelizable)
  → enrollment/ (draft-confirm flow, prerequisite check)
  → grades/ (CRA calculation)
  → documents/ (signed URL retrieval)
  → appointments/ (slot booking with SELECT FOR UPDATE)
  → students/ (profile endpoints)

Level 6: MCP Server
  → All 16 tools
  → student_id injection from session context
  → mcp_action_logs

Level 7: Webhook + AI Service
  → WhatsApp HMAC validation
  → asyncio.create_task + done_callback
  → LangChain ReAct agent
  → PGVector RAG pipeline
  → knowledge base ingest script
```

The **critical path** for a working end-to-end demo: Level 1 → Level 2 → Level 3 → Level 4 → one business slice (enrollment) → MCP enrollment tool → Webhook → LangChain agent.

---

*Research date: 2026-04-15 | Confidence: HIGH for VSA/Docker/Alembic, MEDIUM for LangChain-MCP integration*
