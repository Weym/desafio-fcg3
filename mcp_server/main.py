from __future__ import annotations

import asyncio

from fastmcp import FastMCP

from mcp_server.healthcheck import register_healthcheck
from mcp_server.lifespan import app_lifespan
from mcp_server.middleware import ToolLoggingMiddleware


mcp = FastMCP("academic-mcp", lifespan=app_lifespan)
mcp.add_middleware(ToolLoggingMiddleware())
asyncio.run(register_healthcheck(mcp))

# TODO: register tool modules in Plans 02/03.


if __name__ == "__main__":
    mcp.run(transport="http", host="0.0.0.0", port=8002)
