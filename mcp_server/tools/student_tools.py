from __future__ import annotations

from typing import Any

from fastmcp import Context, FastMCP
from fastmcp.dependencies import CurrentContext, Depends

from mcp_server.api_client import call_api
from mcp_server.dependencies import resolve_student_id


def register_student_tools(mcp: FastMCP) -> None:
    @mcp.tool(
        name="get_student_info",
        description="Retorna o resumo academico do aluno autenticado: nome, periodo, disciplinas concluidas, CRA e status.",
        annotations={"readOnlyHint": True},
    )
    async def get_student_info(
        student_id: str = Depends(resolve_student_id),
        ctx: Context = CurrentContext(),
    ) -> dict[str, Any]:
        client = ctx.lifespan_context["http_client"]
        data, _ = await call_api(
            client,
            "GET",
            f"/students/{student_id}/academic-summary",
            student_id=student_id,
        )
        return data

    @mcp.tool(
        name="get_available_courses",
        description="Lista disciplinas disponiveis para matricula do aluno, considerando pre-requisitos.",
        annotations={"readOnlyHint": True},
    )
    async def get_available_courses(
        student_id: str = Depends(resolve_student_id),
        ctx: Context = CurrentContext(),
    ) -> dict[str, Any]:
        client = ctx.lifespan_context["http_client"]
        data, _ = await call_api(
            client,
            "GET",
            f"/students/{student_id}/available-courses",
            student_id=student_id,
        )
        return data
