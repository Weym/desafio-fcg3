# Phase 4: MCP Server — Research

**Date:** 2026-04-23
**Level:** 2 — Standard Research
**Focus:** FastMCP 3.x API patterns for streamable-http, dependency injection, middleware, lifespan, and session context

---

## Key Findings

### 1. FastMCP 3.2.4 (latest stable)

**Framework:** `fastmcp>=3.2.0` — the actively maintained standalone MCP SDK by Prefect. Python >=3.10 compatible. Apache-2.0 license.

**Core API:**
```python
from fastmcp import FastMCP

mcp = FastMCP("academic-mcp")

@mcp.tool
async def get_grades(semester_year: str | None = None) -> dict:
    """Consulta notas do aluno autenticado."""
    ...

if __name__ == "__main__":
    mcp.run(transport="http", host="0.0.0.0", port=8002)
```

### 2. Transport: Streamable HTTP

- `mcp.run(transport="http", host="0.0.0.0", port=8002)` starts HTTP transport
- MCP endpoint available at `http://host:port/mcp`
- Full bidirectional communication, supports multiple concurrent clients
- Stateless per-request — fits Docker container topology
- Custom routes via `@mcp.custom_route("/health", methods=["GET"])` — ideal for healthcheck

### 3. Dependency Injection (student_id Injection Pattern)

**Critical finding:** FastMCP's `Depends()` automatically **hides** injected parameters from the MCP tool schema. This solves the core requirement.

```python
from fastmcp.dependencies import Depends
from starlette.requests import Request
from fastmcp.dependencies import CurrentRequest

async def resolve_student_id(request: Request = CurrentRequest()) -> str:
    """Resolve student_id from X-Chat-Session-ID header via DB lookup."""
    session_id = request.headers.get("x-chat-session-id")
    if not session_id:
        raise ToolError("Sessao invalida, nao foi possivel identificar o aluno.")
    student_id = await db_pool.fetchval(
        "SELECT student_id FROM chat_sessions WHERE id = $1 AND status = 'active'",
        session_id
    )
    if not student_id:
        raise ToolError("Sessao invalida, nao foi possivel identificar o aluno.")
    return str(student_id)

@mcp.tool
async def get_grades(
    semester_year: str | None = None,
    student_id: str = Depends(resolve_student_id),  # HIDDEN from schema
) -> dict:
    ...
```

**Key insight:** `Depends()` parameters are automatically excluded from the MCP schema — clients and LLMs never see them. This is exactly what D-04/D-05/D-06 require.

**Alternative: `CurrentHeaders()`** — For even simpler header access:
```python
from fastmcp.dependencies import CurrentHeaders

async def get_session_id(headers: dict = CurrentHeaders()) -> str:
    return headers.get("x-chat-session-id", "")
```

### 4. Middleware (Tool Call Logging)

FastMCP provides a full middleware system with `on_call_tool` hook — perfect for the `execute_tool_with_middleware` pattern from `docs/mcp.md`.

```python
from fastmcp.server.middleware import Middleware, MiddlewareContext
import time

class ToolLoggingMiddleware(Middleware):
    def __init__(self, db_pool):
        self.db_pool = db_pool

    async def on_call_tool(self, context: MiddlewareContext, call_next):
        tool_name = context.message.name
        input_params = context.message.arguments
        start = time.monotonic()
        retry = False
        status = "success"

        try:
            result = await call_next(context)
        except Exception as e:
            status = "error"
            latency_ms = int((time.monotonic() - start) * 1000)
            await self._log(tool_name, input_params, None, latency_ms, retry, status, context)
            raise

        latency_ms = int((time.monotonic() - start) * 1000)
        await self._log(tool_name, input_params, result, latency_ms, retry, status, context)
        return result
```

**`on_call_tool`** fires for every tool invocation — tool_name and arguments are available via `context.message.name` and `context.message.arguments`.

### 5. Lifespan (Resource Management)

FastMCP 3.x lifespans run code once at server start/stop. Ideal for asyncpg pool and httpx client initialization:

```python
from fastmcp.server.lifespan import lifespan

@lifespan
async def app_lifespan(server):
    import asyncpg
    import httpx

    pool = await asyncpg.create_pool(dsn=settings.DATABASE_URL, min_size=2, max_size=10)
    client = httpx.AsyncClient(
        base_url=settings.FASTAPI_BASE_URL,
        timeout=10.0,
        headers={"X-Service-Token": settings.MCP_SERVICE_TOKEN}
    )
    try:
        yield {"db_pool": pool, "http_client": client}
    finally:
        await client.aclose()
        await pool.close()

mcp = FastMCP("academic-mcp", lifespan=app_lifespan)
```

Access in tools via `ctx.lifespan_context["db_pool"]` or via custom `Depends()`.

### 6. Custom Routes for Healthcheck

```python
from starlette.requests import Request
from starlette.responses import JSONResponse

@mcp.custom_route("/health", methods=["GET"])
async def healthcheck(request: Request) -> JSONResponse:
    # Check DB + API reachability
    ...
```

### 7. Retry Logic (httpx)

The retry pattern from `docs/mcp.md` fits naturally inside each tool or in a shared utility. Since FastMCP middleware's `on_call_tool` wraps the entire tool, the retry should be inside the tool's httpx call, not at the middleware level:

```python
async def call_api(client: httpx.AsyncClient, method: str, url: str, **kwargs) -> httpx.Response:
    """Single API call with one retry on 5xx/timeout."""
    try:
        response = await client.request(method, url, **kwargs)
        response.raise_for_status()
        return response
    except (httpx.HTTPStatusError, httpx.TimeoutException) as e:
        if isinstance(e, httpx.HTTPStatusError) and e.response.status_code < 500:
            raise  # 4xx — no retry
        # One immediate retry
        response = await client.request(method, url, **kwargs)
        response.raise_for_status()
        return response
```

### 8. Error Handling

FastMCP's `ToolError` class sends error messages directly to the client LLM:
```python
from fastmcp.exceptions import ToolError

raise ToolError("Erro: periodo de matricula encerrado")
```

For 4xx API errors → parse the error JSON → translate to Portuguese text → raise `ToolError`. For 5xx → retry once → if still fails → raise `ToolError` with generic message.

### 9. reasoning Field (D-11)

The reasoning field is captured on the AI Service side (Phase 5) via LangChain's `BaseCallbackHandler.on_agent_action`. The MCP server cannot access the agent's chain-of-thought directly.

**Recommendation:** MCP logs `reasoning` as `NULL`. AI Service updates the record post-facto via a direct DB query or a dedicated internal endpoint. This is the simplest approach and aligns with D-11 "agent's discretion" for reasoning capture.

**Alternative:** AI Service sends reasoning via `X-Agent-Reasoning` header per-request. MCP middleware reads this header and stores it. This is cleaner but requires Phase 5 to implement the header.

**Decision for planning:** Log `reasoning` as NULL in Phase 4. Document that Phase 5 will populate it. No complex header mechanism needed now.

---

## Architecture Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| `student_id` injection | `Depends(resolve_student_id)` using `CurrentRequest()` | Hidden from schema automatically; per-request resolution |
| Tool logging | Custom `Middleware` with `on_call_tool` hook | Clean separation; access to tool_name + args + result |
| Resource init | `@lifespan` yielding `{db_pool, http_client}` | One-time setup, proper cleanup |
| Healthcheck | `@mcp.custom_route("/health")` | FastMCP native, no side-channel HTTP server needed |
| Error to agent | `ToolError("message in Portuguese")` | FastMCP native, sent directly to LLM |
| Retry | Utility function wrapping httpx calls | Inside tool execution, not at middleware level |
| reasoning | NULL in Phase 4, populated by Phase 5 | Simplest; avoids unnecessary coupling |

## Dependencies

```
fastmcp>=3.2.0
httpx>=0.27.0
asyncpg>=0.29.0
```

No need for: `sqlalchemy`, `alembic`, `langchain`, `pydantic-settings` (use a simple dataclass or os.environ for 3 env vars).

## Risks

1. **FastMCP session management with streamable-http:** Verify that `CurrentRequest()` correctly provides the Starlette Request object in streamable-http transport. The docs confirm this works for HTTP transports.
2. **asyncpg pool in lifespan:** Must be created inside an async context. The `@lifespan` decorator provides this.
3. **Tool schema generation:** Verify that all 16 tool schemas match `docs/mcp.md` exactly. `Depends()` parameters are excluded, standard parameters with type hints are included.

---

*Research completed: 2026-04-23*
