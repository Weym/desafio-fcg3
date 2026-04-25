from __future__ import annotations

from collections.abc import AsyncIterator

import asyncpg
import httpx
from fastmcp import FastMCP
from fastmcp.server.lifespan import lifespan

from mcp_server.settings import settings


@lifespan
async def app_lifespan(_server: FastMCP) -> AsyncIterator[dict[str, object]]:
    settings.validate_runtime()

    pool = await asyncpg.create_pool(
        dsn=settings.database_url,
        min_size=2,
        max_size=10,
    )
    client = httpx.AsyncClient(
        base_url=settings.fastapi_base_url,
        timeout=10.0,
        headers={
            "X-Service-Token": settings.mcp_service_token,
            "Content-Type": "application/json",
        },
    )

    try:
        yield {
            "db_pool": pool,
            "http_client": client,
        }
    finally:
        await client.aclose()
        await pool.close()
