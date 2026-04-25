from __future__ import annotations

import asyncio

from fastmcp import FastMCP

from mcp_server.healthcheck import register_healthcheck
from mcp_server.lifespan import app_lifespan
from mcp_server.middleware import ToolLoggingMiddleware
from mcp_server.tools import (
    register_curriculum_tools,
    register_grade_tools,
    register_student_tools,
)


mcp = FastMCP("academic-mcp", lifespan=app_lifespan)
mcp.add_middleware(ToolLoggingMiddleware())
asyncio.run(register_healthcheck(mcp))
register_student_tools(mcp)
register_grade_tools(mcp)
register_curriculum_tools(mcp)

# Plan 03: Write/action tools.
# register_enrollment_tools(mcp)
# register_document_tools(mcp)
# register_scheduling_tools(mcp)


if __name__ == "__main__":
    mcp.run(transport="http", host="0.0.0.0", port=8002)
