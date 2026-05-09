# Phase 5: AI Service — Research

**Date:** 2026-04-23
**Level:** 2 — Standard Research
**Focus:** LangChain 0.3+ agent patterns, langchain-mcp-adapters, langchain-postgres PGVectorStore, provider-agnostic LLM, conversation memory

---

## Key Findings

### 1. langchain-mcp-adapters 0.2.2 (latest stable)

**Library:** `langchain-mcp-adapters>=0.2.0` — Official LangChain library for MCP tool integration. MIT license.

**Critical finding: `MultiServerMCPClient` with streamable-http + custom headers:**

```python
from langchain_mcp_adapters.client import MultiServerMCPClient
from langchain.agents import create_agent

client = MultiServerMCPClient(
    {
        "academic-mcp": {
            "transport": "http",
            "url": "http://mcp-server:8002/mcp",
            "headers": {
                "X-Chat-Session-ID": session_id,  # per-request
            },
        }
    }
)
tools = await client.get_tools()
```

**Per-request header injection:** The `headers` dict in `MultiServerMCPClient` config is set at client creation time. For per-request `X-Chat-Session-ID`, the client must be instantiated per request (with the specific session_id in headers). This is acceptable since D-02 caches tool *discovery* at startup, not the client connection itself.

**Pattern for Phase 5:**
1. At startup: discover tool schemas once (cache tool definitions).
2. Per request: create `MultiServerMCPClient` with session-specific `X-Chat-Session-ID` header → get tools → pass to agent.

**Alternative pattern:** Use `load_mcp_tools(session)` with `streamablehttp_client`:
```python
from mcp.client.streamable_http import streamablehttp_client
from mcp import ClientSession
from langchain_mcp_adapters.tools import load_mcp_tools

async with streamablehttp_client("http://mcp-server:8002/mcp") as (read, write, _):
    async with ClientSession(read, write) as session:
        await session.initialize()
        tools = await load_mcp_tools(session)
```

This opens a new session per invocation. The `MultiServerMCPClient` approach is simpler and handles connection lifecycle.

### 2. LangChain `create_agent` (LangChain 0.3+)

**Critical finding:** LangChain 0.3+ introduces `create_agent` as the primary agent factory:

```python
from langchain.agents import create_agent

agent = create_agent(
    model="openai:gpt-4o",  # provider:model format
    tools=tools,
    system_prompt="...",
)

result = agent.invoke({"messages": [...]})
```

**Provider-agnostic model string format:**
- OpenAI: `"openai:gpt-4o"` (requires `langchain[openai]`)
- Google Gemini: `"google_genai:gemini-2.5-flash-lite"` (requires `langchain[google-genai]`)

**This replaces the old `init_chat_model` + `create_react_agent` pattern.** The `create_agent` function is built on LangGraph internally and handles tool calling natively.

**For the LLM_PROVIDER env var pattern (D-06 agent's discretion):**
```python
import os

PROVIDER_MAP = {
    "openai": "openai:{model}",
    "gemini": "google_genai:{model}",
}

def get_model_string():
    provider = os.environ.get("LLM_PROVIDER", "openai")
    model = os.environ.get("LLM_MODEL", "gpt-4o")
    prefix = PROVIDER_MAP.get(provider, f"{provider}:")
    return prefix.format(model=model) if "{model}" in prefix else f"{prefix}{model}"
```

### 3. langchain-postgres PGVectorStore (v0.0.14+)

**Library:** `langchain-postgres>=0.0.14` — PGVectorStore (NOT deprecated PGVector class).

**Connection pattern with psycopg3:**
```python
from langchain_postgres import PGEngine, PGVectorStore
from langchain_openai import OpenAIEmbeddings

CONNECTION_STRING = "postgresql+psycopg://user:pass@host:5432/db"
engine = PGEngine.from_connection_string(url=CONNECTION_STRING)

embedding = OpenAIEmbeddings(model="text-embedding-3-small")

store = PGVectorStore.create_sync(
    engine=engine,
    table_name="knowledge_base_chunks",
    embedding_service=embedding,
)
```

**Similarity search with score:**
```python
results = store.similarity_search_with_score(query="...", k=3)
# Returns list of (Document, score) tuples
# Filter by score >= 0.75 in application code
```

**As retriever:**
```python
retriever = store.as_retriever(search_type="similarity", search_kwargs={"k": 3})
```

**Important:** `PGVectorStore` expects its own table schema. Since Phase 1 already created `knowledge_base_chunks` with a specific schema, the ingest script should use the PGVectorStore's `add_documents` method for embeddings OR use raw psycopg3 SQL for direct inserts matching the existing schema. The safer approach: use raw psycopg3 for ingest (matching the existing schema exactly) and PGVectorStore for retrieval (read-only).

**Revised approach for existing schema compatibility:** Since `knowledge_base_chunks` was created by Alembic with specific columns (`content`, `embedding`, `source`, `category`, `chunk_index`), using raw SQL for both ingest and retrieval may be simpler. Use `OpenAIEmbeddings` directly for embedding generation, then raw SQL for insert and similarity search. This avoids schema conflicts with PGVectorStore's expected schema.

### 4. PostgresChatMessageHistory (langchain-postgres)

**Critical finding:** `langchain-postgres` provides `PostgresChatMessageHistory` with psycopg3:

```python
from langchain_postgres import PostgresChatMessageHistory
import psycopg

conn = psycopg.connect("postgresql://...")
chat_history = PostgresChatMessageHistory(
    table_name="chat_history",
    session_id=session_id,
    sync_connection=conn,
)
messages = chat_history.messages  # Returns List[BaseMessage]
```

**However:** D-08 specifies loading the last 20 messages from `chat_messages` table (existing schema). The `PostgresChatMessageHistory` creates its own table schema. Since `chat_messages` already exists with a specific schema from Phase 1, we should use **raw psycopg3 queries** to load messages and convert to LangChain message types:

```python
from langchain_core.messages import HumanMessage, AIMessage, SystemMessage

def load_chat_history(conn, session_id: str, k: int = 20):
    rows = conn.execute(
        "SELECT role, content FROM chat_messages WHERE chat_session_id = %s ORDER BY created_at DESC LIMIT %s",
        [session_id, k]
    ).fetchall()
    messages = []
    for role, content in reversed(rows):
        if role == "user":
            messages.append(HumanMessage(content=content))
        elif role == "assistant":
            messages.append(AIMessage(content=content))
        elif role == "system":
            messages.append(SystemMessage(content=content))
    return messages
```

### 5. Conversation Memory with create_agent

`create_agent` accepts `{"messages": [...]}` as input. To inject conversation history:

```python
from langchain_core.messages import HumanMessage

history_messages = load_chat_history(conn, session_id, k=20)
all_messages = history_messages + [HumanMessage(content=user_message)]

result = agent.invoke({"messages": all_messages})
assistant_response = result["messages"][-1].content
```

No need for `RunnableWithMessageHistory` or `ConversationBufferWindowMemory` — the stateless per-request approach (D-08) simply loads history, appends the new message, and passes to the agent.

### 6. RAG as a Tool

The RAG tool is a custom LangChain tool that the agent calls explicitly (D-11):

```python
from langchain_core.tools import tool

@tool
def search_knowledge_base(search_query: str) -> str:
    """Pesquisa a base de conhecimento academica para responder duvidas sobre regras, regulamentos, prazos e politicas."""
    # Generate embedding for query
    # Run cosine similarity search against knowledge_base_chunks
    # Filter by score >= 0.75
    # Return top 3 chunks as formatted text
    ...
```

### 7. Knowledge Base Ingest Script

**Document loaders:**
- Markdown: `langchain_community.document_loaders.TextLoader` or `UnstructuredMarkdownLoader`
- PDF: `langchain_community.document_loaders.PyPDFLoader`

**Text splitter:**
```python
from langchain_text_splitters import RecursiveCharacterTextSplitter

splitter = RecursiveCharacterTextSplitter(
    chunk_size=500,
    chunk_overlap=50,
    length_function=len,  # character-based; token-based needs tiktoken
)
```

**Note:** `docs/chatbot.md` says "500 tokens, overlap 50 tokens". Using `RecursiveCharacterTextSplitter` with character count (~500 chars ≈ 100-125 tokens). For true token-based splitting, use `RecursiveCharacterTextSplitter.from_tiktoken_encoder(chunk_size=500, chunk_overlap=50)`.

### 8. OpenAI Embeddings

```python
from langchain_openai import OpenAIEmbeddings

embeddings = OpenAIEmbeddings(model="text-embedding-3-small")
# Requires OPENAI_API_KEY env var
# Returns 1536-dimensional vectors
```

---

## Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| MCP tool binding | `MultiServerMCPClient` per-request with session headers | Only way to inject per-request X-Chat-Session-ID; tool schemas cacheable at startup |
| Agent framework | `create_agent` (LangChain 0.3+) | Modern API, built on LangGraph, provider-agnostic model string |
| LLM provider switching | `LLM_PROVIDER` → model string format (`openai:gpt-4o`, `google_genai:gemini-2.5-flash`) | `create_agent` natively supports provider:model format |
| Conversation memory | Raw psycopg3 query → LangChain message types → agent input | Existing `chat_messages` schema; no need for PostgresChatMessageHistory's own table |
| RAG retrieval | Raw psycopg3 with pgvector cosine similarity | Existing `knowledge_base_chunks` schema; avoids PGVectorStore schema conflicts |
| RAG tool | Custom `@tool` function | Agent decides when to search (D-11); clean separation from MCP tools |
| Ingest | Raw psycopg3 inserts with OpenAIEmbeddings for vector generation | Matches existing schema exactly; delete-then-insert per source file (D-18) |
| Text splitting | `RecursiveCharacterTextSplitter.from_tiktoken_encoder(chunk_size=500, chunk_overlap=50)` | Token-based per docs/chatbot.md spec |

## Dependencies

```
langchain>=0.3
langchain-mcp-adapters>=0.2.0
langchain-openai>=0.3.0
langchain-google-genai>=2.0.0
langchain-community>=0.3.0
langchain-text-splitters>=0.3.0
psycopg[binary]>=3.1
tiktoken>=0.7.0
pypdf>=4.0
fastapi>=0.115.0
uvicorn>=0.30.0
```

## Risks

1. **Per-request MultiServerMCPClient:** Creating a new client per request adds overhead. Profile to ensure it stays within the 45s agent execution limit. Mitigation: the MCP server is on the same Docker network, connection overhead is minimal.
2. **Existing schema compatibility:** `knowledge_base_chunks` and `chat_messages` have Phase 1 schemas. Using raw SQL instead of LangChain abstractions for these ensures compatibility but loses some convenience.
3. **Token-based chunking:** Requires `tiktoken` dependency. If chunk sizes don't match expected retrieval quality, the 0.75 threshold may need calibration.
4. **LangChain 0.3+ API stability:** `create_agent` is relatively new. Pin version in requirements.txt.

---

*Research completed: 2026-04-23*
