"""Chat visibility service — read-only queries for staff monitoring (CHAT-03).

Provides paginated session listing with optional filters (student_id, status),
message retrieval per session, and MCP action log retrieval per session.
"""

from __future__ import annotations

from uuid import UUID
from typing import Optional

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from src.features.chat.models import ChatSession, ChatMessage, McpActionLog


class ChatService:
    """Read-only service for chat visibility endpoints."""

    async def list_sessions(
        self,
        db: AsyncSession,
        student_id: Optional[UUID] = None,
        status: Optional[str] = None,
        page: int = 1,
        per_page: int = 20,
    ) -> tuple[list[ChatSession], int]:
        """List chat sessions with optional filters.

        Per docs/api.md: ?student_id=uuid&status=active
        Returns (sessions, total_count) for pagination.
        """
        query = select(ChatSession)
        count_query = select(func.count(ChatSession.id))

        if student_id:
            query = query.where(ChatSession.student_id == student_id)
            count_query = count_query.where(ChatSession.student_id == student_id)
        if status:
            query = query.where(ChatSession.status == status)
            count_query = count_query.where(ChatSession.status == status)

        query = query.order_by(ChatSession.started_at.desc())
        query = query.offset((page - 1) * per_page).limit(per_page)

        result = await db.execute(query)
        sessions = list(result.scalars().all())

        total_result = await db.execute(count_query)
        total = total_result.scalar() or 0

        return sessions, total

    async def get_session_messages(
        self,
        session_id: UUID,
        db: AsyncSession,
    ) -> list[ChatMessage]:
        """Get all messages for a chat session, ordered by created_at ascending."""
        result = await db.execute(
            select(ChatMessage)
            .where(ChatMessage.chat_session_id == session_id)
            .order_by(ChatMessage.created_at.asc())
        )
        return list(result.scalars().all())

    async def get_session_action_logs(
        self,
        session_id: UUID,
        db: AsyncSession,
    ) -> list[McpActionLog]:
        """Get MCP action logs for a chat session, ordered by created_at ascending."""
        result = await db.execute(
            select(McpActionLog)
            .where(McpActionLog.chat_session_id == session_id)
            .order_by(McpActionLog.created_at.asc())
        )
        return list(result.scalars().all())

    async def session_exists(self, session_id: UUID, db: AsyncSession) -> bool:
        """Check if a session exists (for 404 handling)."""
        result = await db.execute(
            select(func.count(ChatSession.id)).where(ChatSession.id == session_id)
        )
        return (result.scalar() or 0) > 0

    async def get_session(self, session_id: UUID, db: AsyncSession) -> Optional[ChatSession]:
        """Fetch a session by id for ownership checks; None if not found."""
        result = await db.execute(
            select(ChatSession).where(ChatSession.id == session_id)
        )
        return result.scalar_one_or_none()
