"""Chat visibility router — student (own sessions) + staff monitoring (CHAT-03).

Three GET endpoints per docs/api.md:
- GET /chat-sessions — paginated list
    * staff: may filter by any student_id
    * student: student_id is forced to current_user.id (cannot see other students)
- GET /chat-sessions/{id}/messages — messages for a session
- GET /chat-sessions/{id}/action-logs — MCP action logs for a session

For the per-session endpoints, ownership is enforced:
    * staff: any session
    * student: only their own sessions (403 otherwise)
"""

from __future__ import annotations

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from src.shared.auth import get_current_user, CurrentUser
from src.infrastructure.database import get_db_session
from src.features.chat.service import ChatService
from src.features.chat.schemas import (
    ChatSessionListResponse,
    ChatMessageListResponse,
    MCPActionLogListResponse,
)

router = APIRouter(prefix="/chat-sessions", tags=["chat"])
chat_service = ChatService()


def _forbidden() -> HTTPException:
    return HTTPException(
        status_code=403,
        detail={"error": {"code": "forbidden", "message": "You do not own this chat session"}},
    )


# ------------------------------------------------------------------
# CHAT-03: GET /chat-sessions — staff (any) or student (own only)
# ------------------------------------------------------------------

@router.get(
    "",
    response_model=ChatSessionListResponse,
)
async def list_chat_sessions(
    student_id: Optional[UUID] = Query(None, description="Filter by student ID (ignored for students — always scoped to self)"),
    status: Optional[str] = Query(None, description="Filter by session status (active/closed)"),
    page: int = Query(1, ge=1, description="Page number"),
    per_page: int = Query(20, ge=1, le=100, description="Items per page"),
    db: AsyncSession = Depends(get_db_session),
    current_user: CurrentUser = Depends(get_current_user),
):
    """List chat sessions. Students see only their own; staff can filter by any student_id."""
    # Students are forcibly scoped to their own student_id — IDOR protection
    effective_student_id = current_user.id if current_user.role == "student" else student_id
    sessions, total = await chat_service.list_sessions(db, effective_student_id, status, page, per_page)
    return ChatSessionListResponse(
        data=sessions,
        pagination={"page": page, "per_page": per_page, "total": total},
    )


# ------------------------------------------------------------------
# CHAT-03: GET /chat-sessions/{id}/messages — staff (any) or student (own)
# ------------------------------------------------------------------

@router.get(
    "/{session_id}/messages",
    response_model=ChatMessageListResponse,
)
async def get_session_messages(
    session_id: UUID,
    db: AsyncSession = Depends(get_db_session),
    current_user: CurrentUser = Depends(get_current_user),
):
    """Get messages for a chat session. Students limited to their own sessions."""
    session = await chat_service.get_session(session_id, db)
    if session is None:
        raise HTTPException(status_code=404, detail="Chat session not found")
    if current_user.role == "student" and session.student_id != current_user.id:
        raise _forbidden()
    messages = await chat_service.get_session_messages(session_id, db)
    return ChatMessageListResponse(data=messages)


# ------------------------------------------------------------------
# CHAT-03: GET /chat-sessions/{id}/action-logs — staff (any) or student (own)
# ------------------------------------------------------------------

@router.get(
    "/{session_id}/action-logs",
    response_model=MCPActionLogListResponse,
)
async def get_session_action_logs(
    session_id: UUID,
    db: AsyncSession = Depends(get_db_session),
    current_user: CurrentUser = Depends(get_current_user),
):
    """Get MCP action logs for a chat session. Students limited to their own sessions."""
    session = await chat_service.get_session(session_id, db)
    if session is None:
        raise HTTPException(status_code=404, detail="Chat session not found")
    if current_user.role == "student" and session.student_id != current_user.id:
        raise _forbidden()
    logs = await chat_service.get_session_action_logs(session_id, db)
    return MCPActionLogListResponse(data=logs)
