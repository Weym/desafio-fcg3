"""Chat visibility router — staff-only endpoints for monitoring chat sessions (CHAT-03).

Three GET endpoints per docs/api.md:
- GET /chat-sessions — paginated list with student_id and status filters
- GET /chat-sessions/{id}/messages — all messages ordered by created_at
- GET /chat-sessions/{id}/action-logs — MCP action logs with tool details

All endpoints require staff role authentication (T-06-13).
"""

from __future__ import annotations

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from src.shared.auth import require_role
from src.infrastructure.database import get_db_session
from src.features.chat.service import ChatService
from src.features.chat.schemas import (
    ChatSessionListResponse,
    ChatMessageListResponse,
    MCPActionLogListResponse,
)

router = APIRouter(prefix="/chat-sessions", tags=["chat"])
chat_service = ChatService()


# ------------------------------------------------------------------
# CHAT-03: GET /chat-sessions — staff only, paginated + filterable
# ------------------------------------------------------------------

@router.get(
    "",
    response_model=ChatSessionListResponse,
    dependencies=[Depends(require_role("staff"))],
)
async def list_chat_sessions(
    student_id: Optional[UUID] = Query(None, description="Filter by student ID"),
    status: Optional[str] = Query(None, description="Filter by session status (active/closed)"),
    page: int = Query(1, ge=1, description="Page number"),
    per_page: int = Query(20, ge=1, le=100, description="Items per page"),
    db: AsyncSession = Depends(get_db_session),
):
    """List chat sessions. Staff only. Per docs/api.md: GET /chat-sessions"""
    sessions, total = await chat_service.list_sessions(db, student_id, status, page, per_page)
    return ChatSessionListResponse(
        data=sessions,
        pagination={"page": page, "per_page": per_page, "total": total},
    )


# ------------------------------------------------------------------
# CHAT-03: GET /chat-sessions/{id}/messages — staff only
# ------------------------------------------------------------------

@router.get(
    "/{session_id}/messages",
    response_model=ChatMessageListResponse,
)
async def get_session_messages(
    session_id: UUID,
    db: AsyncSession = Depends(get_db_session),
    _current_user=Depends(require_role("staff")),
):
    """Get messages for a chat session. Staff only. Per docs/api.md: GET /chat-sessions/{id}/messages"""
    if not await chat_service.session_exists(session_id, db):
        raise HTTPException(status_code=404, detail="Chat session not found")
    messages = await chat_service.get_session_messages(session_id, db)
    return ChatMessageListResponse(data=messages)


# ------------------------------------------------------------------
# CHAT-03: GET /chat-sessions/{id}/action-logs — staff only
# ------------------------------------------------------------------

@router.get(
    "/{session_id}/action-logs",
    response_model=MCPActionLogListResponse,
    dependencies=[Depends(require_role("staff"))],
)
async def get_session_action_logs(
    session_id: UUID,
    db: AsyncSession = Depends(get_db_session),
):
    """Get MCP action logs for a chat session. Staff only. Per docs/api.md: GET /chat-sessions/{id}/action-logs"""
    if not await chat_service.session_exists(session_id, db):
        raise HTTPException(status_code=404, detail="Chat session not found")
    logs = await chat_service.get_session_action_logs(session_id, db)
    return MCPActionLogListResponse(data=logs)
