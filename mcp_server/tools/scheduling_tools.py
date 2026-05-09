from __future__ import annotations

from typing import Any

from fastmcp import Context, FastMCP
from fastmcp.dependencies import CurrentContext, Depends

from mcp_server.api_client import call_api
from mcp_server.dependencies import resolve_student_id


def register_scheduling_tools(mcp: FastMCP) -> None:
    @mcp.tool(
        name="get_available_slots",
        description="Lista horarios de atendimento disponiveis na secretaria.",
        annotations={"readOnlyHint": True},
    )
    async def get_available_slots(
        date_from: str | None = None,
        date_to: str | None = None,
        student_id: str = Depends(resolve_student_id),
        ctx: Context = CurrentContext(),
    ) -> dict[str, Any]:
        client = ctx.lifespan_context["http_client"]
        params = {
            key: value
            for key, value in {"date_from": date_from, "date_to": date_to}.items()
            if value is not None
        }
        data, _ = await call_api(
            client,
            "GET",
            "/scheduling/slots",
            params=params or None,
            student_id=student_id,
        )
        return data

    @mcp.tool(
        name="book_appointment",
        description="Agenda um atendimento presencial na secretaria.",
    )
    async def book_appointment(
        slot_id: str,
        reason: str,
        student_id: str = Depends(resolve_student_id),
        ctx: Context = CurrentContext(),
    ) -> dict[str, Any]:
        client = ctx.lifespan_context["http_client"]
        data, _ = await call_api(
            client,
            "POST",
            "/appointments",
            json={"student_id": student_id, "slot_id": slot_id, "reason": reason},
            student_id=student_id,
        )
        return data

    @mcp.tool(
        name="cancel_appointment",
        description="Cancela um agendamento de atendimento.",
    )
    async def cancel_appointment(
        appointment_id: str,
        student_id: str = Depends(resolve_student_id),
        ctx: Context = CurrentContext(),
    ) -> dict[str, Any]:
        client = ctx.lifespan_context["http_client"]
        data, _ = await call_api(
            client,
            "PUT",
            f"/appointments/{appointment_id}/cancel",
            student_id=student_id,
        )
        return data
