from __future__ import annotations

from typing import Any

from fastmcp import FastMCP
from starlette.requests import Request
from starlette.responses import JSONResponse


def _get_lifespan_resources(request: Request) -> dict[str, Any]:
    fastmcp_server = request.app.state.fastmcp_server
    return getattr(fastmcp_server, "_lifespan_result", {}) or {}


async def register_healthcheck(mcp: FastMCP) -> None:
    @mcp.custom_route("/health", methods=["GET"])
    async def healthcheck(request: Request) -> JSONResponse:
        resources = _get_lifespan_resources(request)
        pool = resources.get("db_pool")
        client = resources.get("http_client")
        details: dict[str, str] = {}

        try:
            await pool.fetchval("SELECT 1")
        except Exception as exc:
            details["database"] = str(exc)

        try:
            response = await client.get("/health")
            response.raise_for_status()
        except Exception as exc:
            details["api"] = str(exc)

        if details:
            return JSONResponse(
                {"status": "unhealthy", "details": details},
                status_code=503,
            )

        return JSONResponse({"status": "healthy"})
