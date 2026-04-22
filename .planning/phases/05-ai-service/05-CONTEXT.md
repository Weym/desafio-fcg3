# Phase 5: AI Service - Context

**Gathered:** 2026-04-22
**Status:** Ready for planning

<domain>
## Phase Boundary

LangChain ReAct agent that answers student academic questions in Portuguese, using MCP tools for live data and PGVector RAG for regulation and policy, with any LLM provider configurable by environment variable. Includes: service scaffold, knowledge base ingest script, RAG pipeline, ReAct agent with MCP tool binding, and HTTP endpoint for message processing. WhatsApp webhook integration is Phase 6.

</domain>

<decisions>
## Implementation Decisions

### MCP Tool Binding
- **D-01:** Use `langchain-mcp-adapters` library to auto-discover and bind MCP tools from the Phase 4 MCP server (streamable-http on port 8002). No manual httpx wrappers for each of the 16 tools.
- **D-02:** Tool discovery cached at service startup. MCP tools are loaded once when the AI service starts and reused across all requests. Container restart required if MCP adds new tools (acceptable since both services deploy together).
- **D-03:** Only `X-Chat-Session-ID` header passed per request to MCP. No reasoning or chain-of-thought metadata. MCP resolves `student_id` from session. Exact mechanism for per-request header injection into langchain-mcp-adapters left to agent's discretion (researcher should investigate streamable-http custom headers support).
- **D-04:** AI service trusts the caller (FastAPI backend) for session validity. No redundant session validation in the AI service -- FastAPI validates the session before calling the AI service.

### Service Framework & Configuration
- **D-05:** FastAPI for the AI service HTTP endpoint. Consistent with the rest of the project. Async-native, easy healthcheck, dependency injection.
- **D-06:** System prompt loaded from a file (`prompts/system_prompt.txt`). Easy to iterate on prompt engineering without code changes. File baked into Docker image. Canonical system prompt defined in `docs/chatbot.md`.
- **D-07:** Agent execution limits: `max_iterations=10`, `max_execution_time=45.0` seconds. Higher than ROADMAP defaults because enrollment flows can involve 3-4 sequential tool calls. Agent returns a fallback message on limit/timeout.

### Conversation Memory
- **D-08:** Fully stateless per request. Each invocation queries `chat_messages` table for the last 20 messages of the session, builds the LangChain message history, and passes it to the agent. No in-memory caching. Container restarts lose nothing.
- **D-09:** AI service writes the assistant's response to `chat_messages` after generating it. The service owns the full lifecycle: load history -> run agent -> save response.
- **D-10:** `psycopg3` synchronous driver for PostgreSQL. LangChain's ReAct internals are largely sync; mixing async can cause issues. Researcher should confirm correct `RunnableWithMessageHistory` or equivalent pattern for LangChain 0.3+.

### RAG Integration
- **D-11:** RAG as an explicit LangChain tool (`search_knowledge_base`). The agent decides when to search the knowledge base vs when to call MCP API tools. Clean separation -- agent reasons about doc lookup vs live data.
- **D-12:** Agent formulates the search query. The RAG tool accepts a `search_query` parameter; the agent refines the user's message into a precise search rather than passing raw text.
- **D-13:** Top 3 chunks above the 0.75 cosine similarity threshold. Keeps context concise for the LLM while covering focused academic policy questions.
- **D-14:** When RAG returns no relevant chunks (all below 0.75), empty context is returned. The agent decides how to respond -- uses MCP tools, or falls back to the system prompt's guidance ("nao encontrei na base de conhecimento").
- **D-15:** `langchain-postgres` PGVectorStore for RAG retrieval. Uses the psycopg3 connection. Handles embedding, similarity search, and threshold filtering.
- **D-16:** Same embedding model (`text-embedding-3-small`) for both ingest and query. Single `OPENAI_API_KEY` env var. No separate configuration -- mismatch would break similarity search.
- **D-17:** Fresh embedding per query, no caching. Embedding calls are fast (~100ms) and query volume in MVP doesn't justify cache complexity.

### Knowledge Base Ingest Script
- **D-18:** Ingest script at `scripts/ingest.py` inside the AI service container. Always re-embeds all 5 documents on every run, using delete-then-insert per source file. For each file: delete all existing chunks for that source, then insert fresh chunks. Guarantees no orphaned/stale chunks when documents shrink.
- **D-19:** Explicit filename-to-category mapping hardcoded in the script: `{'matricula.md': 'regras_matricula', 'regulamento.pdf': 'regulamento', 'faq.md': 'faq', 'calendario.md': 'agendamento', 'curriculo.md': 'curriculo'}`. New files need a mapping entry.
- **D-20:** PDF handling via LangChain's built-in document loaders (PyPDFLoader or equivalent). Integrates naturally with the LangChain chunking pipeline.
- **D-21:** Console report + DB log after ingestion. Prints to stdout: documents processed, total chunks generated, chunks per category, execution time. Also logs a summary record to the database for audit trail.
- **D-22:** Knowledge base source files live at `ai_service/knowledge/`. Baked into the Docker image. AI service owns its knowledge base.

### Agent Behavior
- **D-23:** Confirmation before mutating actions (rule #2 from system prompt: "confirme com o aluno antes de executar acoes que alteram dados") is enforced via system prompt only. No code-level tool guards. The LLM handles confirmation naturally in conversation, matching the flows documented in `docs/chatbot.md`.

### Agent's Discretion
- LLM provider factory implementation for `LLM_PROVIDER=openai|gemini` env var switching
- Exact `langchain-mcp-adapters` configuration for streamable-http transport + custom headers
- `RunnableWithMessageHistory` vs alternative pattern for LangChain 0.3+ memory
- Healthcheck implementation for the AI service container (replace Phase 1 stub)
- Agent fallback message wording when execution limits are hit
- `scripts/ingest.py` DB logging schema for ingest audit records
- Chunking parameters: 500 tokens / 50 overlap as defined in `docs/chatbot.md`

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Chatbot Architecture & Agent Design
- `docs/chatbot.md` -- Complete chatbot architecture: system prompt, intent table, conversation flow diagrams, RAG pipeline design, media handling, verification flow, error responses. This is the authoritative source for agent behavior.

### MCP Protocol & Tool Schemas
- `docs/mcp.md` -- 16 MCP tool definitions (input schemas with student_id omitted), endpoint mappings, logging specification, retry behavior. Defines the tools the agent will call via langchain-mcp-adapters.

### API Contract (endpoints MCP proxies)
- `docs/api.md` -- REST endpoints that MCP tools call. Error codes in Portuguese SCREAMING_SNAKE_CASE. Relevant for understanding what data the agent receives back from tool calls.

### Database Schema
- `docs/database.md` -- Schema for `chat_sessions`, `chat_messages` (conversation persistence), `knowledge_base_chunks` (RAG storage with vector(1536) + HNSW index), `mcp_action_logs`.

### Architecture & Docker Topology
- `docs/architecture.md` -- C4 diagrams, Docker topology (langchain-service at port 8001), network layout (app-network), service communication patterns.

### Phase Dependencies
- `.planning/phases/01-infrastructure-schema/01-CONTEXT.md` -- D-06/D-07: AI service has own requirements.txt and Dockerfile. D-08: Healthcheck stub to be replaced. D-09: Migration #006 creates chat_sessions, chat_messages, knowledge_base_chunks tables.
- `.planning/phases/04-mcp-server/04-CONTEXT.md` -- D-01/D-02/D-03: FastMCP on port 8002, streamable-http. D-04/D-05/D-06: X-Chat-Session-ID header for session context, student_id resolved from chat_sessions. D-08/D-09: Raw JSON success responses, Portuguese text error responses.

### Research Summary
- `.planning/research/SUMMARY.md` -- CRITICAL-3: `asyncio.create_task` + `add_done_callback` pattern for Phase 6 (not directly Phase 5, but informs how the AI service is called).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- No existing code in `ai_service/` -- directory does not exist yet (to be created at project root per Phase 1 D-06).
- Phase 1 D-08 created a healthcheck stub in the langchain-service container -- this phase replaces it with the real implementation.
- `docs/chatbot.md` contains the canonical system prompt, intent table, and conversation flow diagrams to implement.

### Established Patterns
- Vertical slice architecture in backend (not directly applicable to AI service, but informs module organization).
- Settings via environment variables (Pydantic BaseSettings pattern in backend; AI service should use similar config approach).
- Error response shape from API: `{"error": {"code": "...", "message": "...", "details": [...]}}` -- relevant for parsing tool call responses.
- psycopg3 driver for this service (STATE.md decision); asyncpg used by FastAPI and MCP.

### Integration Points
- `ai_service/` directory at project root (sibling to `backend/`, `mcp_server/`).
- Docker container `langchain-service` on port 8001, connected to `app-network`.
- Receives HTTP requests from FastAPI backend (message + session_id).
- Calls MCP server on port 8002 via langchain-mcp-adapters (streamable-http).
- Reads/writes `chat_messages` and reads `knowledge_base_chunks` via psycopg3.

</code_context>

<specifics>
## Specific Ideas

- RAG as an explicit tool gives the agent control over when to search docs vs call live APIs. For action-oriented messages like "matricular em X", the agent skips RAG and goes straight to MCP tools. For policy questions like "como funciona o trancamento?", the agent calls the knowledge base tool.
- Delete-then-insert per source file for ingest is effectively a per-file replace -- simpler than true upsert while guaranteeing no stale chunks when documents shrink or are restructured.
- Higher execution limits (10 iterations, 45s) accommodate enrollment flows that chain 3-4 tool calls: get_enrollment_period -> get_available_courses -> enroll_courses -> confirm_enrollment.
- System prompt confirmation behavior follows the conversation patterns already documented in `docs/chatbot.md` -- the LLM naturally asks "Confirmar?" before mutating calls.

</specifics>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope.

</deferred>

---

*Phase: 05-ai-service*
*Context gathered: 2026-04-22*
