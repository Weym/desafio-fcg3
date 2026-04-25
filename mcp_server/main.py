from __future__ import annotations

from fastmcp import FastMCP

from mcp_server.lifespan import app_lifespan


mcp = FastMCP("academic-mcp", lifespan=app_lifespan)

# TODO: add ToolLoggingMiddleware in Task 2.
# TODO: register /health custom route in Task 2.
# TODO: register tool modules in Plans 02/03.


if __name__ == "__main__":
    mcp.run(transport="http", host="0.0.0.0", port=8002)
