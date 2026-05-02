from __future__ import annotations

from typing import Any

from fastmcp import Context, FastMCP
from fastmcp.dependencies import CurrentContext, Depends

from mcp_server.api_client import call_api
from mcp_server.dependencies import resolve_student_id


def register_enrollment_tools(mcp: FastMCP) -> None:
    @mcp.tool(
        name="create_enrollment",
        description="Cria uma matricula (rascunho) com as disciplinas selecionadas. O aluno deve confirmar com confirm_enrollment depois.",
    )
    async def create_enrollment(
        enrollment_period_id: str,
        course_ids: list[str],
        student_id: str = Depends(resolve_student_id),
        ctx: Context = CurrentContext(),
    ) -> dict[str, Any]:
        client = ctx.lifespan_context["http_client"]
        data, _ = await call_api(
            client,
            "POST",
            "/enrollments",
            json={
                "student_id": student_id,
                "enrollment_period_id": enrollment_period_id,
                "course_ids": course_ids,
            },
            student_id=student_id,
        )
        return data

    @mcp.tool(
        name="confirm_enrollment",
        description="Confirma definitivamente uma matricula em rascunho. Deve ser chamada apos create_enrollment e confirmacao explicita do aluno.",
    )
    async def confirm_enrollment(
        enrollment_id: str,
        student_id: str = Depends(resolve_student_id),
        ctx: Context = CurrentContext(),
    ) -> dict[str, Any]:
        client = ctx.lifespan_context["http_client"]
        data, _ = await call_api(
            client,
            "POST",
            f"/enrollments/{enrollment_id}/confirm",
            student_id=student_id,
        )
        return data

    @mcp.tool(
        name="drop_course",
        description="Remove uma disciplina da matricula do aluno.",
    )
    async def drop_course(
        enrollment_id: str,
        course_id: str,
        student_id: str = Depends(resolve_student_id),
        ctx: Context = CurrentContext(),
    ) -> dict[str, Any]:
        client = ctx.lifespan_context["http_client"]
        data, _ = await call_api(
            client,
            "DELETE",
            f"/enrollments/{enrollment_id}/courses/{course_id}",
            student_id=student_id,
        )
        return data

    @mcp.tool(
        name="lock_enrollment",
        description="Tranca a matricula inteira do aluno no periodo.",
    )
    async def lock_enrollment(
        enrollment_id: str,
        student_id: str = Depends(resolve_student_id),
        ctx: Context = CurrentContext(),
    ) -> dict[str, Any]:
        client = ctx.lifespan_context["http_client"]
        data, _ = await call_api(
            client,
            "POST",
            f"/enrollments/{enrollment_id}/lock",
            student_id=student_id,
        )
        return data
