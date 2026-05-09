# Phase 5: AI Service - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-04-22
**Phase:** 05-ai-service
**Areas discussed:** MCP tool binding strategy, Conversation memory approach, RAG integration with agent, Knowledge base ingest script, Agent confirmation behavior

---

## MCP Tool Binding Strategy

### Q1: How should the LangChain agent connect to the MCP server's 16 tools?

| Option | Description | Selected |
|--------|-------------|----------|
| langchain-mcp-adapters (Recommended) | Official LangChain library that auto-discovers MCP tools, converts them to LangChain-compatible tools, handles streamable-http transport | ✓ |
| Manual httpx tool wrappers | Write a Python function for each MCP tool that calls the MCP server via httpx. Full control, no extra dependency | |
| You decide | Let the agent/researcher investigate | |

**User's choice:** langchain-mcp-adapters
**Notes:** None

### Q2: Should the AI service pass any per-request metadata to MCP beyond X-Chat-Session-ID?

| Option | Description | Selected |
|--------|-------------|----------|
| Only X-Chat-Session-ID (Recommended) | Keep it minimal. MCP resolves student_id from chat_sessions | ✓ |
| Also pass reasoning/chain-of-thought | Send agent reasoning via custom header for mcp_action_logs.reasoning | |
| You decide | Let researcher investigate streamable-http metadata support | |

**User's choice:** Only X-Chat-Session-ID
**Notes:** None

### Q3: Should the AI service expose its endpoint as a FastAPI app or simpler framework?

| Option | Description | Selected |
|--------|-------------|----------|
| FastAPI (Recommended) | Consistent with rest of project, async-native, easy healthcheck | ✓ |
| Plain ASGI / lightweight | Minimal server (Starlette or bare uvicorn) | |
| You decide | Agent's discretion | |

**User's choice:** FastAPI
**Notes:** None

### Q4: How should the AI service handle agent execution limits?

| Option | Description | Selected |
|--------|-------------|----------|
| max_iterations=5, max_time=30s | As specified in ROADMAP Plan 5.4 | |
| Higher limits (10 iterations, 45s) | Enrollment flows can involve 3-4 tool calls in sequence | ✓ |
| You decide | Agent's discretion | |

**User's choice:** Higher limits (10 iterations, 45s)
**Notes:** Enrollment flows may chain get_enrollment_period -> get_available_courses -> enroll_courses -> confirm_enrollment

### Q5: Tool discovery -- cache at startup or rediscover per request?

| Option | Description | Selected |
|--------|-------------|----------|
| Cache at startup (Recommended) | Discover tools once when service starts. Requires restart if MCP adds tools | ✓ |
| Rediscover per request | Query MCP for tool list on every invocation | |
| You decide | Agent's discretion | |

**User's choice:** Cache at startup
**Notes:** None

### Q6: How to inject X-Chat-Session-ID into MCP calls via langchain-mcp-adapters?

| Option | Description | Selected |
|--------|-------------|----------|
| Custom transport/headers config | Configure langchain-mcp-adapters to include the header | |
| You decide | Let researcher investigate | ✓ |

**User's choice:** You decide (agent's discretion)
**Notes:** Researcher should investigate exact mechanism for per-request header injection

### Q7: System prompt -- hardcoded, file-based, or env var?

| Option | Description | Selected |
|--------|-------------|----------|
| File-based (Recommended) | Load from prompts/system_prompt.txt. Easy to iterate | ✓ |
| Hardcoded in Python | String constant in code | |
| Environment variable | Env var, flexible but unwieldy for multi-line | |

**User's choice:** File-based
**Notes:** None

### Q8: Validate chat_session_id in AI service or trust FastAPI caller?

| Option | Description | Selected |
|--------|-------------|----------|
| Trust the caller (Recommended) | FastAPI validates session before calling AI service | ✓ |
| Validate in AI service too | Defense in depth, adds DB query per request | |

**User's choice:** Trust the caller
**Notes:** None

---

## Conversation Memory Approach

### Q1: How should conversation history be loaded for the agent on each request?

| Option | Description | Selected |
|--------|-------------|----------|
| Query DB per invocation (Recommended) | Each request queries chat_messages for last 20 messages. Fully stateless | ✓ |
| In-memory cache with DB fallback | Keep recent sessions in memory for speed | |

**User's choice:** Query DB per invocation
**Notes:** None

### Q2: Should the AI service write the assistant's response to chat_messages?

| Option | Description | Selected |
|--------|-------------|----------|
| AI service writes (Recommended) | Service owns full lifecycle: load history, run agent, save response | ✓ |
| FastAPI writes | AI service returns response to FastAPI, which saves it | |

**User's choice:** AI service writes
**Notes:** None

### Q3: PostgreSQL driver for LangChain service?

| Option | Description | Selected |
|--------|-------------|----------|
| psycopg3 sync (Recommended) | STATE.md specifies psycopg3. Sync avoids issues with LangChain's sync internals | ✓ |
| psycopg3 async | Async aligns with project approach but requires careful LangChain integration | |
| You decide | Let researcher investigate sync vs async compatibility | |

**User's choice:** psycopg3 sync
**Notes:** None

---

## RAG Integration with Agent

### Q1: How should RAG retrieval integrate with the ReAct agent?

| Option | Description | Selected |
|--------|-------------|----------|
| RAG as a tool (Recommended) | RAG retriever registered as a LangChain tool the agent calls explicitly | ✓ |
| Auto-inject RAG context before agent | Every message triggers RAG query first, injected into prompt | |
| Hybrid | Auto-inject + tool for follow-up queries | |

**User's choice:** RAG as a tool
**Notes:** Agent decides when to search docs vs call MCP tools

### Q2: When RAG finds no relevant chunks?

| Option | Description | Selected |
|--------|-------------|----------|
| Empty context + agent decides (Recommended) | RAG returns nothing, agent decides response | ✓ |
| Explicit 'no results' message to agent | RAG returns explicit signal | |

**User's choice:** Empty context + agent decides
**Notes:** None

### Q3: RAG store implementation?

| Option | Description | Selected |
|--------|-------------|----------|
| langchain-postgres PGVectorStore (Recommended) | Official LangChain PGVector integration, psycopg3 | ✓ |
| Raw SQL with psycopg3 | Manual cosine similarity queries | |

**User's choice:** langchain-postgres PGVectorStore
**Notes:** ROADMAP Plan 5.1 already lists langchain-postgres>=0.0.9

### Q4: How many chunks per RAG query?

| Option | Description | Selected |
|--------|-------------|----------|
| Top 3 above threshold | Concise context, sufficient for policy questions | ✓ |
| Top 5 above threshold | More context, higher token usage | |
| You decide | Agent's discretion | |

**User's choice:** Top 3 above threshold
**Notes:** None

### Q5: Embedding model configuration?

| Option | Description | Selected |
|--------|-------------|----------|
| Same model, single config (Recommended) | Both ingest and query use text-embedding-3-small | ✓ |
| Configurable per operation | Separate env vars for ingest and query models | |

**User's choice:** Same model, single config
**Notes:** Mismatch would break similarity search

### Q6: Cache embedding results for repeated queries?

| Option | Description | Selected |
|--------|-------------|----------|
| Fresh each time (Recommended) | No cache, ~100ms per call, simpler | ✓ |
| In-memory LRU cache | Cache recent query embeddings | |
| You decide | Agent's discretion | |

**User's choice:** Fresh each time
**Notes:** None

### Q7: RAG query formulation?

| Option | Description | Selected |
|--------|-------------|----------|
| Agent formulates query (Recommended) | RAG tool accepts search_query, agent refines the search | ✓ |
| Pass original message | RAG receives raw user text | |

**User's choice:** Agent formulates query
**Notes:** Allows agent to extract key terms from conversational messages

---

## Knowledge Base Ingest Script

### Q1: How should the ingest script handle re-runs?

| Option | Description | Selected |
|--------|-------------|----------|
| Full replace (Recommended) | Delete all chunks, re-insert from scratch | |
| Upsert by source+chunk_index | Update existing, insert new | ✓ |

**User's choice:** Upsert by source+chunk_index
**Notes:** Subsequently clarified as delete-then-insert per source file

### Q2: How should category be assigned?

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit filename-to-category mapping (Recommended) | Hardcoded dict in script | ✓ |
| Derive from folder structure | Category = parent folder name | |
| You decide | Agent's discretion | |

**User's choice:** Explicit filename-to-category mapping
**Notes:** None

### Q3: PDF handling library?

| Option | Description | Selected |
|--------|-------------|----------|
| PyMuPDF (fitz) | Fast, reliable text extraction | |
| LangChain document loaders | Built-in PDF loader, integrates with chunking pipeline | ✓ |
| You decide | Agent's discretion | |

**User's choice:** LangChain document loaders
**Notes:** None

### Q4: Ingest report format?

| Option | Description | Selected |
|--------|-------------|----------|
| Console report (Recommended) | Print to stdout: docs, chunks, categories, time | |
| Console + log to DB | Same console report plus DB audit record | ✓ |

**User's choice:** Console + log to DB
**Notes:** None

### Q5: Re-embed scope on re-run?

| Option | Description | Selected |
|--------|-------------|----------|
| Always re-embed all, upsert (Recommended) | Re-embed all 5 docs, upsert. Negligible cost for 5 files | ✓ |
| Detect changes by file hash | Only re-embed changed files | |

**User's choice:** Always re-embed all
**Notes:** None

### Q6: Orphaned chunk cleanup strategy?

| Option | Description | Selected |
|--------|-------------|----------|
| Delete-then-insert per source file | For each file: delete existing chunks, insert fresh | ✓ |
| True upsert + count-based cleanup | Upsert chunks, delete extras | |

**User's choice:** Delete-then-insert per source file
**Notes:** Simpler than true upsert, same no-stale-chunks guarantee

### Q7: Knowledge base source file location?

| Option | Description | Selected |
|--------|-------------|----------|
| ai_service/knowledge/ (Recommended) | Inside AI service directory, baked into Docker image | ✓ |
| Root-level knowledge/ directory | Sibling to backend/, ai_service/ | |
| You decide | Agent's discretion | |

**User's choice:** ai_service/knowledge/
**Notes:** None

---

## Agent Confirmation Behavior

### Q1: How should 'confirm before mutating' behavior work?

| Option | Description | Selected |
|--------|-------------|----------|
| System prompt only (Recommended) | Rely on system prompt instruction, LLM handles confirmation naturally | ✓ |
| Code-level tool guard | Wrapper around mutating tools checks for confirmation signal | |
| Hybrid: prompt + soft guard | System prompt + log warning when mutating tool called without confirmation | |

**User's choice:** System prompt only
**Notes:** Matches conversation flows documented in docs/chatbot.md

---

## Agent's Discretion

- LLM provider factory implementation for LLM_PROVIDER env var switching
- Exact langchain-mcp-adapters configuration for streamable-http + custom headers
- RunnableWithMessageHistory vs alternative memory pattern for LangChain 0.3+
- Healthcheck implementation for AI service container
- Agent fallback message when execution limits hit
- Ingest script DB logging schema for audit records
- Chunking parameters (500 tokens / 50 overlap per docs/chatbot.md)

## Deferred Ideas

None -- discussion stayed within phase scope.
