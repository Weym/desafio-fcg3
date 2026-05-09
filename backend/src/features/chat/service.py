"""Chat visibility service — read-only queries for staff monitoring (CHAT-03)
and human intervention actions (HI-01: assign, reply, resolve).

Provides paginated session listing with optional filters (student_id, status),
message retrieval per session, MCP action log retrieval per session,
and staff intervention workflow (assign, reply, resolve, list interventions).
"""

from __future__ import annotations

from datetime import datetime, timezone
from uuid import UUID
from typing import Optional

from fastapi import HTTPException
from sqlalchemy import select, func, or_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.features.chat.models import ChatSession, ChatMessage, McpActionLog


class ChatService:
    """Service for chat visibility and human intervention endpoints."""

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

    # --- Human Intervention Methods (HI-01) ---

    async def list_intervention_sessions(
        self, db: AsyncSession, staff_id: UUID | None = None
    ) -> list[ChatSession]:
        """List sessions pending or active in human intervention.

        Staff sees all 'human_needed' sessions + their own 'human_active' (T-14-04).
        Ordered by escalated_at ASC (oldest first — FIFO).
        Eagerly loads student relationship for display.
        """
        query = select(ChatSession).options(selectinload(ChatSession.student))

        if staff_id:
            # Staff sees: all pending + only their own active
            query = query.where(
                or_(
                    ChatSession.status == "human_needed",
                    (ChatSession.status == "human_active") & (ChatSession.assigned_staff_id == staff_id),
                )
            )
        else:
            query = query.where(
                ChatSession.status.in_(["human_needed", "human_active"])
            )

        query = query.order_by(ChatSession.escalated_at.asc())

        result = await db.execute(query)
        return list(result.scalars().all())

    async def assign_session(
        self, session_id: UUID, staff_id: UUID, db: AsyncSession
    ) -> ChatSession:
        """Assign a session to a staff member (human_needed → human_active).

        T-14-03: Validates session is in 'human_needed' status.
        """
        session = await self.get_session(session_id, db)
        if session is None:
            raise HTTPException(
                status_code=404,
                detail={"error": {"code": "SESSAO_NAO_ENCONTRADA", "message": "Chat session not found"}},
            )
        if session.status != "human_needed":
            raise HTTPException(
                status_code=409,
                detail={"error": {"code": "INVALID_SESSION_STATUS", "message": "Session is not in human_needed status"}},
            )

        session.status = "human_active"
        session.assigned_staff_id = staff_id
        session.updated_at = datetime.now(timezone.utc)
        await db.flush()
        return session

    async def staff_reply(
        self, session_id: UUID, staff_id: UUID, content: str, db: AsyncSession
    ) -> ChatMessage:
        """Staff sends a reply message in human-active session.

        T-14-02: Validates session is 'human_active' and assigned to this staff.
        T-14-03: Returns 409 on invalid status.
        """
        session = await self.get_session(session_id, db)
        if session is None:
            raise HTTPException(
                status_code=404,
                detail={"error": {"code": "SESSAO_NAO_ENCONTRADA", "message": "Chat session not found"}},
            )
        if session.status != "human_active":
            raise HTTPException(
                status_code=409,
                detail={"error": {"code": "INVALID_SESSION_STATUS", "message": "Session is not in human_active status"}},
            )
        if session.assigned_staff_id != staff_id:
            raise HTTPException(
                status_code=403,
                detail={"error": {"code": "SEM_PERMISSAO", "message": "You are not assigned to this session"}},
            )

        msg = ChatMessage(
            chat_session_id=session_id,
            role="assistant",
            content=content,
        )
        db.add(msg)
        session.updated_at = datetime.now(timezone.utc)
        await db.flush()
        return msg

    async def resolve_session(
        self, session_id: UUID, staff_id: UUID, db: AsyncSession
    ) -> ChatSession:
        """Resolve (close) a human-active session.

        T-14-02: Validates assigned_staff_id matches.
        T-14-03: Validates status is 'human_active'.
        """
        session = await self.get_session(session_id, db)
        if session is None:
            raise HTTPException(
                status_code=404,
                detail={"error": {"code": "SESSAO_NAO_ENCONTRADA", "message": "Chat session not found"}},
            )
        if session.status != "human_active":
            raise HTTPException(
                status_code=409,
                detail={"error": {"code": "INVALID_SESSION_STATUS", "message": "Session is not in human_active status"}},
            )
        if session.assigned_staff_id != staff_id:
            raise HTTPException(
                status_code=403,
                detail={"error": {"code": "SEM_PERMISSAO", "message": "You are not assigned to this session"}},
            )

        session.status = "closed"
        session.ended_at = datetime.now(timezone.utc)
        session.updated_at = datetime.now(timezone.utc)
        await db.flush()
        return session
