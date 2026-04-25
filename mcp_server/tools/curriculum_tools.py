from __future__ import annotations

from typing import Any

from fastmcp import Context, FastMCP
from fastmcp.dependencies import CurrentContext

from mcp_server.api_client import call_api


def register_curriculum_tools(mcp: FastMCP) -> None:
    @mcp.tool(
        name="get_curriculum",
        description="Retorna a grade curricular vigente do curso de Ciencia da Computacao.",
        annotations={"readOnlyHint": True},
    )
    async def get_curriculum(
        ctx: Context = CurrentContext(),
    ) -> dict[str, Any]:
        client = ctx.lifespan_context["http_client"]
        data, _ = await call_api(client, "GET", "/curriculum/active")
        return data

    @mcp.tool(
        name="get_course_prerequisites",
        description="Retorna os pre-requisitos de uma disciplina.",
        annotations={"readOnlyHint": True},
    )
    async def get_course_prerequisites(
        course_id: str,
        ctx: Context = CurrentContext(),
    ) -> dict[str, Any]:
        client = ctx.lifespan_context["http_client"]
        data, _ = await call_api(client, "GET", f"/courses/{course_id}/prerequisites")
        return data

    @mcp.tool(
        name="get_enrollment_period",
        description="Retorna informacoes sobre o periodo de matricula atual (se houver).",
        annotations={"readOnlyHint": True},
    )
    async def get_enrollment_period(
        ctx: Context = CurrentContext(),
    ) -> dict[str, Any]:
        client = ctx.lifespan_context["http_client"]
        data, _ = await call_api(client, "GET", "/enrollment-periods/current")
        return data
