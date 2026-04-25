from __future__ import annotations

from typing import Any

from fastmcp import Context, FastMCP
from fastmcp.dependencies import CurrentContext, Depends

from mcp_server.api_client import call_api
from mcp_server.dependencies import resolve_student_id


def register_document_tools(mcp: FastMCP) -> None:
    @mcp.tool(
        name="request_document",
        description="Solicita a emissao de um documento academico. Tipos: transcript, enrollment_proof, declaration, certificate.",
    )
    async def request_document(
        type: str,
        student_id: str = Depends(resolve_student_id),
        ctx: Context = CurrentContext(),
    ) -> dict[str, Any]:
        client = ctx.lifespan_context["http_client"]
        data, _ = await call_api(
            client,
            "POST",
            "/documents",
            json={"student_id": student_id, "type": type},
        )
        return data

    @mcp.tool(
        name="get_document_status",
        description="Verifica o status de um documento solicitado.",
        annotations={"readOnlyHint": True},
    )
    async def get_document_status(
        document_id: str,
        ctx: Context = CurrentContext(),
    ) -> dict[str, Any]:
        client = ctx.lifespan_context["http_client"]
        data, _ = await call_api(client, "GET", f"/documents/{document_id}")
        return data
