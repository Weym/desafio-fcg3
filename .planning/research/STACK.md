# Stack Research — Desafio FCG3

**Domain:** Python/FastAPI academic platform with WhatsApp chatbot
**Mode:** Brownfield / Subsequent milestone
**Date:** 2026-04-15
**Sources:** Official docs — FastAPI, MCP Python SDK (modelcontextprotocol.io), LangChain, SQLAlchemy

---

## Core Stack Decisions

### MCP Server — Transport: Streamable HTTP (NOT stdio)

**Decision:** Use `mcp[cli]>=1.2.0` with `FastMCP` and `mcp.run(transport="streamable-http")`

- **Why:** stdio transport requires subprocess spawning — impossible across Docker containers. Streamable HTTP works over the network between containers.
- **Transport URL:** `http://mcp-server:8002/sse` (SSE endpoint)
- **Confidence:** HIGH — confirmed in official MCP docs

```python
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("academic-tools")

@mcp.tool()
async def get_grades(semester: str) -> dict:
    ...

if __name__ == "__main__":
    mcp.run(transport="streamable-http")
```

---

### PostgreSQL Drivers — Two Drivers Required

**Service split:**
- `fastapi-app` + `mcp-server`: use `asyncpg` (SQLAlchemy async engine)
- `langchain-service`: use `psycopg[binary]` (psycopg3) — **mandated by `langchain-postgres`**

```
# FastAPI / MCP requirements
sqlalchemy[asyncio]>=2.0
asyncpg>=0.29
alembic>=1.13

# AI Service requirements  
psycopg[binary]>=3.1
langchain-postgres>=0.0.9
langchain>=0.3
langchain-openai>=0.2  # or langchain-google-genai — configurable via env
```

**Confidence:** MEDIUM — langchain-postgres mandates psycopg3

---

### PGVector — Use `langchain-postgres`, NOT `langchain-community`

**Decision:** `langchain-postgres` replaces the deprecated community integration

- `langchain-community` PGVector uses sync psycopg2 — broken in async context
- `langchain-postgres` provides `PGVector` class with psycopg3 + JSONB metadata support

```python
from langchain_postgres import PGVector

vector_store = PGVector(
    embeddings=embeddings,
    collection_name="knowledge_base",
    connection=DATABASE_URL_PSYCOPG3,
    use_jsonb=True,
)
```

**Confidence:** MEDIUM

---

### SQLAlchemy Async — Critical Patterns

**1. Async engine setup:**

```python
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession

engine = create_async_engine(
    DATABASE_URL,  # postgresql+asyncpg://...
    pool_size=10,
    max_overflow=20,
    echo=False,
)

async_session_maker = async_sessionmaker(
    engine,
    expire_on_commit=False,  # MANDATORY — prevents lazy-load errors after commit
    class_=AsyncSession,
)
```

**2. `expire_on_commit=False` is MANDATORY** — without it, accessing attributes after `session.commit()` triggers lazy SQL loads that fail silently in async context.

**3. FastAPI dependency for request-scoped sessions:**

```python
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_maker() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
```

**4. Background tasks must open their own sessions** — never pass a FastAPI-scoped `db` session into `asyncio.create_task`. The request session closes before the task runs.

```python
async def process_whatsapp_message(message_id: str):
    async with async_session_maker() as db:  # own session
        ...
```

---

### Alembic — Async Configuration

**`alembic/env.py` pattern for async:**

```python
from sqlalchemy.ext.asyncio import async_engine_from_config

async def run_async_migrations():
    connectable = async_engine_from_config(config.get_section(config.config_ini_section))
    async with connectable.connect() as connection:
        await connection.run_sync(do_run_migrations)

def run_migrations_online():
    asyncio.run(run_async_migrations())
```

**PGVector extension — must be migration #001:**

```python
def upgrade():
    op.execute("CREATE EXTENSION IF NOT EXISTS vector")
```

This must run before any table with a `vector` column. Extension creation is tracked in `alembic_version`.

**HNSW index — autogenerate is broken** — must be hand-written:

```python
op.execute(
    "CREATE INDEX knowledge_base_chunks_embedding_idx "
    "ON knowledge_base_chunks USING hnsw (embedding vector_cosine_ops) "
    "WITH (m = 16, ef_construction = 64)"
)
```

---

### Vector Column in SQLAlchemy Models

```python
from pgvector.sqlalchemy import Vector
from sqlalchemy import Column

class KnowledgeBaseChunk(Base):
    __tablename__ = "knowledge_base_chunks"
    embedding = Column(Vector(1536), nullable=False)
```

**Similarity query:**

```python
from pgvector.sqlalchemy import cosine_distance

results = await session.execute(
    select(KnowledgeBaseChunk)
    .where(cosine_distance(KnowledgeBaseChunk.embedding, query_vec) <= 0.25)
    .order_by(cosine_distance(KnowledgeBaseChunk.embedding, query_vec))
    .limit(5)
)
```

> ⚠️ Common error: threshold is DISTANCE (1 - similarity), not similarity. `0.25 distance = 0.75 similarity`

---

### LangChain Agent — Key Config

```python
from langchain.agents import AgentExecutor, create_react_agent
from langchain.memory import ConversationBufferWindowMemory

agent_executor = AgentExecutor(
    agent=agent,
    tools=tools,
    memory=memory,
    max_iterations=5,          # MANDATORY — prevents infinite loops on tool error
    max_execution_time=30.0,   # MANDATORY — prevents hanging on LLM timeout
    handle_parsing_errors=True,
    verbose=False,
)
```

**LLM provider agnostic — configure via env:**

```python
import os
from langchain_openai import ChatOpenAI
from langchain_google_genai import ChatGoogleGenerativeAI

def get_llm():
    provider = os.getenv("LLM_PROVIDER", "openai")
    if provider == "openai":
        return ChatOpenAI(model=os.getenv("LLM_MODEL", "gpt-4o-mini"))
    elif provider == "gemini":
        return ChatGoogleGenerativeAI(model=os.getenv("LLM_MODEL", "gemini-1.5-flash"))
    raise ValueError(f"Unknown LLM provider: {provider}")
```

**Open question (needs phase research):** How does `langchain-mcp-adapters` (or equivalent) inject per-request `student_id` into MCP tool calls? This must be resolved before implementing the AI service phase.

---

### Docker Compose — Service Versions

```yaml
services:
  postgres:
    image: pgvector/pgvector:pg16
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB"]
      interval: 5s
      timeout: 5s
      retries: 5

  fastapi-app:
    image: python:3.12-slim
    depends_on:
      postgres:
        condition: service_healthy

  langchain-service:
    image: python:3.12-slim
    depends_on:
      postgres:
        condition: service_healthy
      mcp-server:
        condition: service_healthy

  mcp-server:
    image: python:3.12-slim
    depends_on:
      postgres:
        condition: service_healthy
```

**`depends_on` with `condition: service_healthy` is required** on postgres — without it, services crash on startup before the DB is ready.

---

## Package Summary

| Service | Key Packages |
|---------|-------------|
| `fastapi-app` | `fastapi`, `uvicorn[standard]`, `sqlalchemy[asyncio]`, `asyncpg`, `alembic`, `pgvector`, `pyjwt`, `httpx`, `resend` |
| `langchain-service` | `langchain>=0.3`, `langchain-postgres`, `langchain-openai` or `langchain-google-genai`, `psycopg[binary]`, `httpx` |
| `mcp-server` | `mcp[cli]>=1.2.0`, `httpx`, `sqlalchemy[asyncio]`, `asyncpg` |
| `postgres` | `pgvector/pgvector:pg16` (Docker image, no pip) |

---

*Research date: 2026-04-15 | Confidence levels noted per finding*
