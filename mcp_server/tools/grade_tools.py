from __future__ import annotations

from typing import Any

from fastmcp import Context, FastMCP
from fastmcp.dependencies import CurrentContext, Depends

from mcp_server.api_client import call_api
from mcp_server.dependencies import resolve_student_id


def register_grade_tools(mcp: FastMCP) -> None:
    @mcp.tool(
        name="get_grades",
        description="Consulta notas do aluno. Se semester_year nao for informado, retorna do periodo atual.",
        annotations={"readOnlyHint": True},
    )
    async def get_grades(
        semester_year: str | None = None,
        student_id: str = Depends(resolve_student_id),
        ctx: Context = CurrentContext(),
    ) -> dict[str, Any]:
        client = ctx.lifespan_context["http_client"]
        params = {"semester_year": semester_year} if semester_year else None
        data, _ = await call_api(
            client,
            "GET",
            f"/students/{student_id}/grades",
            params=params,
            student_id=student_id,
        )
        return data

    @mcp.tool(
        name="get_transcript",
        description="Retorna o historico escolar completo do aluno autenticado.",
        annotations={"readOnlyHint": True},
    )
    async def get_transcript(
        student_id: str = Depends(resolve_student_id),
        ctx: Context = CurrentContext(),
    ) -> dict[str, Any]:
        client = ctx.lifespan_context["http_client"]
        data, _ = await call_api(
            client,
            "GET",
            f"/students/{student_id}/transcript",
            student_id=student_id,
        )
        return data
