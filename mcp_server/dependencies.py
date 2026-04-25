from __future__ import annotations

from typing import Annotated
from uuid import UUID

from fastmcp.dependencies import CurrentRequest, Depends
from fastmcp.exceptions import ToolError
from fastmcp.server.dependencies import get_context
from starlette.requests import Request


INVALID_SESSION_MESSAGE = "Sessao invalida, nao foi possivel identificar o aluno."
AUDIT_LOG_UNAVAILABLE_MESSAGE = "Infraestrutura de auditoria indisponivel."


def validate_chat_session_id(raw_chat_session_id: str | None) -> UUID:
    session_id = (raw_chat_session_id or "").strip()
    if not session_id:
        raise ToolError(INVALID_SESSION_MESSAGE)

    try:
        return UUID(session_id)
    except ValueError as exc:
        raise ToolError(INVALID_SESSION_MESSAGE) from exc


def get_db_pool(lifespan_context: dict[str, object]) -> object:
    db_pool = lifespan_context.get("db_pool")
    if db_pool is None:
        raise ToolError(AUDIT_LOG_UNAVAILABLE_MESSAGE)
    return db_pool


async def validate_active_chat_session(db_pool: object, chat_session_id: UUID) -> dict:
    row = await db_pool.fetchrow(
        """
        SELECT id, student_id
        FROM chat_sessions
        WHERE id = $1 AND status = 'active'
        """,
        chat_session_id,
    )
    if row is None:
        raise ToolError(INVALID_SESSION_MESSAGE)
    return dict(row)


async def resolve_chat_session_id(
    request: Request = CurrentRequest(),
) -> str:
    return str(validate_chat_session_id(request.headers.get("x-chat-session-id")))


async def resolve_student_id(
    request: Request = CurrentRequest(),
) -> str:
    session_id = validate_chat_session_id(request.headers.get("x-chat-session-id"))
    ctx = get_context()
    db_pool = get_db_pool(ctx.lifespan_context)
    row = await validate_active_chat_session(db_pool, session_id)

    return str(row["student_id"])


ChatSessionId = Annotated[str, Depends(resolve_chat_session_id)]
StudentId = Annotated[str, Depends(resolve_student_id)]
