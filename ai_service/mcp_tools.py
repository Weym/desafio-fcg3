"""Helpers for loading MCP tools for a chat session."""

from __future__ import annotations

from typing import Any

from langchain_mcp_adapters.client import MultiServerMCPClient


async def load_mcp_tools(mcp_server_url: str, session_id: str) -> list[Any]:
    """Load MCP tools from the academic MCP server for one chat session.

    A new client is created for each invocation because the MCP adapter binds
    request headers at client construction time. The MCP server resolves the
    authenticated student context from ``X-Chat-Session-ID`` internally, so the
    LangChain agent never receives or sends ``student_id`` directly.
    """

    client = MultiServerMCPClient(
        {
            "academic-mcp": {
                "transport": "http",
                "url": mcp_server_url,
                "headers": {
                    "X-Chat-Session-ID": session_id,
                },
            }
        }
    )
    return await client.get_tools()
