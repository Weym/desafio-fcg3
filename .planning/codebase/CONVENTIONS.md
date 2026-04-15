# Coding Conventions

**Analysis Date:** 2026-04-15

## Project State

The backend source code is in early scaffolding. The only source file is
`backend/src/main.py`, which is currently empty. All conventions below are
**prescriptive** — derived from the design documentation, code snippets in
`docs/mcp.md`, and the `biome.json` linter config at the project root.

## Language and Runtime

- **Language:** Python 3.12
- **Framework:** FastAPI
- **Style source:** Inline snippets in `docs/mcp.md` and `docs/api.md` define
  the expected code patterns.

## Naming Patterns

**Files:**
- Use `snake_case` for all Python files: `main.py`, `ingest.py`
- Feature directories use `snake_case`: `features/auth/`, `features/enrollment/`
- Shared utilities live in `src/shared/`
- Infrastructure (DB clients, HTTP clients) lives in `src/infrastructure/`

**Functions and methods:**
- Use `snake_case`: `verify_service_token`, `execute_tool_with_middleware`,
  `get_student_id`
- Async functions must use `async def` — the entire FastAPI surface is async
- Background tasks use `asyncio.create_task(...)` pattern

**Variables:**
- `snake_case` throughout
- Boolean flags: descriptive names — `retry`, `is_active`, `is_available`,
  `prerequisites_met`
- UUID identifiers always named `*_id` suffix: `student_id`, `enrollment_id`,
  `chat_session_id`

**Classes:**
- `PascalCase`: `MCPLoggingHandler`, `BaseCallbackHandler`

**Constants / environment:**
- SCREAMING_SNAKE_CASE for settings and env vars: `MCP_SERVICE_TOKEN`,
  `WHATSAPP_TOKEN`
- Settings accessed via a `settings` object — never inline `os.getenv()` in
  business logic

## API and Endpoint Conventions

**Base URL:** `http://localhost:8000/api/v1`

**HTTP methods and status codes (from `docs/api.md`):**
- `GET` — read, returns `200`
- `POST` — create, returns `201`; action endpoints return `200`
- `PUT` — full update or action (e.g., cancel, confirm), returns `200`
- `DELETE` — remove a sub-resource, returns `200`

**URL structure:**
- Lowercase kebab-case path segments: `/enrollment-periods/current`,
  `/available-courses`, `/academic-summary`
- Resource IDs as path params: `/students/{id}/grades`
- Sub-actions as path suffixes: `/enrollments/{id}/confirm`,
  `/enrollments/{id}/lock`, `/appointments/{id}/cancel`
- Query params use `snake_case`: `page`, `per_page`, `sort_by`, `order`,
  `student_id`, `semester_year`

**Standard pagination query params:**
```
?page=1&per_page=20
?sort_by=created_at&order=desc
```

## Error Handling

**Standard error response shape (from `docs/api.md`):**
```json
{
  "error": {
    "code": "SCREAMING_SNAKE_CASE_CODE",
    "message": "Human readable description",
    "details": [{ "field": "email", "message": "Email invalido" }]
  }
}
```

**Error codes are SCREAMING_SNAKE_CASE strings:**
- `VALIDATION_ERROR`, `INVALID_CODE`, `MAX_ATTEMPTS_REACHED`,
  `ENROLLMENT_NOT_FOUND`, `ENROLLMENT_PERIOD_CLOSED`,
  `ENROLLMENT_ALREADY_CONFIRMED`

**HTTP status code mapping:**
| Code | Use |
|------|-----|
| 200 | Success |
| 201 | Created |
| 400 | Validation error |
| 401 | Unauthenticated |
| 403 | Forbidden |
| 404 | Not found |
| 409 | Conflict (e.g., duplicate enrollment) |
| 422 | Unprocessable entity |
| 429 | Rate limit reached |
| 500 | Internal server error |

**Retry logic (from `docs/mcp.md`):**
- 5xx errors and timeouts: one immediate retry, no wait
- 4xx errors: no retry — logic failures are not retried

```python
# Pattern from docs/mcp.md
async def execute_tool_with_middleware(tool_name: str, func, *args, **kwargs):
    start = time.monotonic()
    retry = False
    try:
        result = await func(*args, **kwargs)
    except (httpx.HTTPStatusError, httpx.TimeoutException) as e:
        if isinstance(e, httpx.HTTPStatusError) and e.response.status_code < 500:
            raise  # 4xx — no retry
        retry = True
        result = await func(*args, **kwargs)  # single immediate retry
    latency_ms = int((time.monotonic() - start) * 1000)
    await log_action(tool_name, args, result, latency_ms, retry=retry)
    return result
```

## Authentication Conventions

Two auth mechanisms, never mixed:

| Type | Header | Used by |
|------|--------|---------|
| JWT Bearer | `Authorization: Bearer {token}` | App Flutter, students, staff |
| Service Token | `X-Service-Token: {MCP_SERVICE_TOKEN}` | MCP Server (internal calls only) |

**Middleware pattern for service token validation (from `docs/mcp.md`):**
```python
async def verify_service_token(request: Request, call_next):
    service_token = request.headers.get("X-Service-Token")
    if service_token != settings.MCP_SERVICE_TOKEN:
        return JSONResponse(status_code=401, content={"detail": "Unauthorized"})
    return await call_next(request)
```

**Security rule:** `MCP_SERVICE_TOKEN` lives only in environment variables.
Never hardcode it. Never expose it in tool schemas.

## Async Patterns

- All FastAPI route handlers must be `async def`
- Background processing uses `asyncio.create_task(...)` — the webhook handler
  must return `200 OK` immediately and dispatch processing in background
- Background tasks must not block the HTTP response cycle

## MCP Tool Schema Conventions

- `student_id` is NEVER a parameter in tool input schemas exposed to the LLM
- The MCP server injects `student_id` from session context internally
- Tools that operate on a specific resource (enrollment, document) receive the
  resource ID explicitly (e.g., `enrollment_id`, `document_id`)
- All schemas use JSON Schema format with `type: "object"` and `properties`

## Data Conventions

**UUIDs:**
- All primary keys are UUIDs
- FK references named with `_id` suffix

**Timestamps:**
- `created_at` and `updated_at` on all mutable tables, `DEFAULT NOW()`
- Event-specific timestamps: `confirmed_at`, `requested_at`, `completed_at`,
  `expires_at`, `started_at`, `ended_at`

**Status fields:**
- `VARCHAR(20)` — use lowercase string literals
- Pattern: `draft -> confirmed -> cancelled` (enrollments)
- Pattern: `requested -> processing -> ready -> delivered` (documents)
- Pattern: `active -> closed` (chat sessions)

**Soft deletes:**
- Students use `status = 'inactive'` — no physical delete

## Code Style (biome.json at `/biome.json`)

The `biome.json` is configured for the project root and applies to
JavaScript/TypeScript (tooling scripts, if any). Python code style is not
covered by Biome.

For Python:
- Follow PEP 8
- Indent with 4 spaces (standard Python convention)
- Line length: no explicit constraint defined — follow PEP 8 default (79-99)

## Logging

- Structured logging via MCP action logs table (`mcp_action_logs`)
- Every MCP tool call must be logged with: `tool_name`, `input_params`,
  `output_result`, `reasoning`, `latency_ms`, `retry`, `status`
- `reasoning` is nullable — models that don't expose chain-of-thought produce
  `null`, which is expected behavior
- `student_id` is never logged in `input_params` — it is injected internally
  and not persisted as an input parameter

## Comments

- Document non-obvious decisions — example from `docs/mcp.md`: explain why
  `jti` is stored instead of the full JWT token
- Code snippets in docs are the canonical reference — maintain alignment
  between doc snippets and actual implementation

## Module Design

**Feature structure pattern (from `backend/src/features/`):**
- Each domain feature gets its own directory under `src/features/`
- Current feature directories: `src/features/auth/`, `src/features/enrollment/`
- Shared cross-feature code lives in `src/shared/`
- Infrastructure (DB connections, HTTP clients, settings) lives in
  `src/infrastructure/`

---

*Convention analysis: 2026-04-15*
