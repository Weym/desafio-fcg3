from __future__ import annotations

from typing import Annotated
from uuid import UUID

from fastmcp.dependencies import CurrentRequest, Depends
from fastmcp.exceptions import ToolError
from fastmcp.server.dependencies import get_context
from starlette.requests import Request


INVALID_SESSION_MESSAGE = "Sessao invalida, nao foi possivel identificar o aluno."


async def resolve_chat_session_id(
    request: Request = CurrentRequest(),
) -> str:
    session_id = request.headers.get("x-chat-session-id", "").strip()
    if not session_id:
        raise ToolError(INVALID_SESSION_MESSAGE)

    try:
        return str(UUID(session_id))
    except ValueError as exc:
        raise ToolError(INVALID_SESSION_MESSAGE) from exc


async def resolve_student_id(
    request: Request = CurrentRequest(),
) -> str:
    session_id = await resolve_chat_session_id(request)
    ctx = get_context()
    db_pool = ctx.lifespan_context["db_pool"]

    row = await db_pool.fetchrow(
        """
        SELECT student_id
        FROM chat_sessions
        WHERE id = $1 AND status = 'active'
        """,
        UUID(session_id),
    )
    if row is None:
        raise ToolError(INVALID_SESSION_MESSAGE)

    return str(row["student_id"])


ChatSessionId = Annotated[str, Depends(resolve_chat_session_id)]
StudentId = Annotated[str, Depends(resolve_student_id)]
