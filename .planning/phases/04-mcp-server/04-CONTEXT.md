# Phase 4: MCP Server - Context

**Gathered:** 2026-04-20
**Status:** Ready for planning

<domain>
## Phase Boundary

MCP Server exposes all 16 tools documented in `docs/mcp.md` over streamable-http transport, injects `student_id` from session context (never from the LangChain agent), and logs every tool call to `mcp_action_logs` with full metadata (params, result, latency, retry status, reasoning). The server authenticates all internal API calls via `X-Service-Token` with constant-time comparison.

</domain>

<decisions>
## Implementation Decisions

### Framework & Transport
- **D-01:** Use FastMCP (official high-level Python SDK) as the MCP framework. Declarative API with decorators. Not the low-level `mcp.server.Server` shown in `docs/mcp.md` examples.
- **D-02:** Transport: streamable-http. Stateless per-request, runs on port 8002 as defined in Docker topology. Compatible with container-to-container communication.
- **D-03:** FastMCP standalone application. No FastAPI wrapper — the MCP server is a pure MCP server process. Healthcheck endpoint provided by FastMCP's built-in capabilities or a minimal side-channel.

### Session Context & student_id Injection
- **D-04:** AI Service passes `X-Chat-Session-ID` header (UUID) in each HTTP request to the MCP Server.
- **D-05:** MCP Server resolves `student_id` by querying `chat_sessions` table using the `X-Chat-Session-ID` value. This lookup happens before every tool call that requires student context.
- **D-06:** `student_id` never travels on the wire between services — only `chat_session_id` is transmitted. The MCP Server is the sole resolver of the actual student identity.
- **D-07:** If the session is invalid, expired, or `student_id` cannot be resolved, the tool call is rejected with a clear error message to the agent: "Sessao invalida, nao foi possivel identificar o aluno." Fail-safe behavior.

### Tool Response Format
- **D-08:** Success responses: return raw JSON from the FastAPI response directly to the LangChain agent. No transformation or simplification. LLMs handle JSON well and this avoids adding formatting logic in the MCP layer.
- **D-09:** Error responses (4xx from API): convert to human-readable Portuguese text message before passing to the agent. Example: API returns `{"error": {"code": "PERIODO_MATRICULA_FECHADO"}}` → MCP passes "Erro: periodo de matricula encerrado" to the agent. Agent communicates naturally to the student.

### Logging & Reasoning Capture
- **D-10:** MCP Server owns all `mcp_action_logs` writes. A decorator/middleware intercepts every tool call, measures latency, handles retry, and writes the full log record (tool_name, input_params without student_id, output_result, latency_ms, retry, status).
- **D-11:** `reasoning` field capture mechanism is at the agent's discretion. Options include: AI Service sending reasoning via a custom header, or MCP logging `reasoning` as null and AI Service updating it post-facto. The researcher/planner should investigate what FastMCP + streamable-http support for passing per-request metadata.
- **D-12:** `chat_session_id` is included in the log record to associate tool calls with specific chat sessions.

### Tool Code Organization
- **D-13:** Tools organized by domain in separate modules: `student_tools.py`, `enrollment_tools.py`, `grade_tools.py`, `document_tools.py`, `scheduling_tools.py`, `curriculum_tools.py`. Each module registers its tools on the shared FastMCP app instance.

### Database Access
- **D-14:** asyncpg direct (no SQLAlchemy). The MCP Server only needs 2 types of queries: (1) resolve `student_id` from `chat_sessions`, (2) insert into `mcp_action_logs`. Plain SQL with asyncpg is sufficient and keeps the service lightweight.
- **D-15:** Connection pool initialized at application startup, shared across all tool invocations.

### HTTP Client Configuration
- **D-16:** httpx.AsyncClient initialized once at startup with connection pooling.
- **D-17:** Base URL from environment variable: `FASTAPI_BASE_URL` (default: `http://fastapi-app:8000/api/v1`).
- **D-18:** Timeout: 10 seconds per request. With one retry on 5xx/timeout, maximum total time per tool call is ~20 seconds.
- **D-19:** Default headers: `X-Service-Token` from `MCP_SERVICE_TOKEN` env var, `Content-Type: application/json`.

### Healthcheck
- **D-20:** Real healthcheck validates: (1) PostgreSQL connection is alive, (2) FastAPI `/health` endpoint responds. If either fails, healthcheck returns unhealthy and Docker restarts the container.

### Agent's Discretion
- Exact FastMCP middleware/decorator pattern for tool call interception and logging
- `reasoning` field capture mechanism (header-based vs post-hoc update vs nullable)
- asyncpg connection pool sizing
- Exact error message translations for each API error code
- Whether healthcheck runs on a separate lightweight HTTP server or uses FastMCP's built-in endpoint

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### MCP Protocol & Tool Schemas
- `docs/mcp.md` — Complete MCP tool definitions (16 tools), input schemas (with student_id omitted), endpoint mappings, logging specification, retry behavior, reasoning capture pattern. This is the authoritative source for tool behavior.

### API Contract (endpoints called by MCP)
- `docs/api.md` — REST endpoint specifications that MCP tools proxy. Request/response shapes, error codes, HTTP status mappings. Defines which endpoints accept `X-Service-Token` (marked "Aceita X-Service-Token (MCP)").

### Database Schema
- `docs/database.md` — Schema for `mcp_action_logs` table (log fields, types, constraints), `chat_sessions` table (for student_id resolution via session lookup). Also relevant: `students` table FK reference.

### Architecture & Docker Topology
- `docs/architecture.md` — C4 diagrams, Docker container layout (mcp-server at port 8002), network topology (app-network connects MCP to FastAPI and langchain-service).

### Phase Dependencies
- `.planning/phases/01-infrastructure-schema/01-CONTEXT.md` — D-06/D-07: MCP has own requirements.txt and Dockerfile. D-08: Minimal healthcheck stub exists (to be replaced). D-09: Migration #006 creates mcp_action_logs and chat_sessions tables.
- `.planning/phases/02-authentication/02-CONTEXT.md` — X-Service-Token middleware implemented on FastAPI side. `hmac.compare_digest` for constant-time comparison.
- `.planning/phases/03-business-feature-slices/03-CONTEXT.md` — D-02: Dual-auth `get_current_user_or_service()` dependency. D-03: Error codes in Portuguese SCREAMING_SNAKE_CASE. D-05: Same ownership check for service token requests (defense in depth).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- No existing code in `mcp_server/` — directory does not exist yet (to be created at project root per Phase 1 D-06).
- Phase 1 D-08 created a healthcheck stub — this phase replaces it with the real MCP implementation.
- `docs/mcp.md` contains code snippets for: middleware logging pattern (`execute_tool_with_middleware`), callback handler for reasoning (`MCPLoggingHandler`), service token validation, and tool registration.

### Established Patterns
- Vertical slice architecture in the backend — MCP uses a similar domain-grouped approach for tool organization.
- Settings via environment variables (consistent with backend's Pydantic BaseSettings pattern but MCP uses lighter config since no SQLAlchemy).
- Error response shape from API: `{"error": {"code": "...", "message": "...", "details": [...]}}` — MCP must parse this format for error translation.
- All async: MCP uses asyncpg and httpx.AsyncClient, aligning with the project's async-first approach.

### Integration Points
- `mcp_server/` directory at project root (sibling to `backend/`, `ai_service/`).
- Docker container `mcp-server` on port 8002, connected to `app-network`.
- Calls FastAPI endpoints authenticated via `X-Service-Token` header.
- Receives tool calls from AI Service (Phase 5) via streamable-http transport.
- Reads `chat_sessions` and writes `mcp_action_logs` directly to PostgreSQL via asyncpg.

</code_context>

<specifics>
## Specific Ideas

- The decorator/middleware pattern from `docs/mcp.md` (`execute_tool_with_middleware`) is the canonical reference for how tool logging should work — wrap every tool call, measure timing, handle retry, write log.
- `student_id` isolation is the core security property: it never appears in tool schemas, never travels between AI Service and MCP, and is always resolved server-side from the chat session.
- FastMCP standalone keeps the MCP server lean — only depends on `fastmcp`, `httpx`, and `asyncpg`. No FastAPI, no SQLAlchemy, no LangChain in this service.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 04-mcp-server*
*Context gathered: 2026-04-20*
