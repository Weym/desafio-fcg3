# Phase 04 MCP Cold Start / Health Debug

## Symptom

Phase 04 UAT Test 1 failed during a cold start. The `mcp-server` container first crashed with `ModuleNotFoundError: No module named 'fastmcp'`, and after rebuilding the image it still failed the `/health` check.

## Root Cause

The missing `fastmcp` error came from a stale local Docker image and disappeared after rebuilding `mcp-server`.

The real code-level blockers were:

1. `mcp_server/lifespan.py` passed the SQLAlchemy-style `DATABASE_URL` (`postgresql+asyncpg://...`) directly into `asyncpg.create_pool(...)`, but `asyncpg` only accepts `postgresql://` or `postgres://`.
2. `mcp_server/healthcheck.py` reused the API-versioned FastAPI base URL for the backend health probe, which turned the check into `http://fastapi-app:8000/api/v1/health` even though the backend health endpoint lives at `/health`.

## Fix Applied

- Added DSN normalization in `mcp_server/settings.py` and consumed it from `mcp_server/lifespan.py`.
- Added a dedicated backend health URL in `mcp_server/settings.py` and updated `mcp_server/healthcheck.py` to probe the root `/health` endpoint.
- Extended MCP regression coverage in `mcp_server/tests/test_service_token.py` and `mcp_server/tests/test_healthcheck.py`.

## Verification

- `python -m pytest mcp_server/tests -q` -> `53 passed`
- `python -m pytest backend/tests/integration/test_service_token.py -q` -> `4 passed`
- `docker compose build mcp-server`
- `docker compose up -d mcp-server`
- `curl.exe -sf http://localhost:8002/health` -> `{"status":"healthy"}`
