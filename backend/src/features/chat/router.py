"""Chat visibility router — student (own sessions) + staff monitoring (CHAT-03)
and human intervention endpoints (HI-01).

GET endpoints per docs/api.md:
- GET /chat-sessions — paginated list
    * staff: may filter by any student_id
    * student: student_id is forced to current_user.id (cannot see other students)
- GET /chat-sessions/interventions — staff-only, lists pending/active intervention sessions
- GET /chat-sessions/{id}/messages — messages for a session
- GET /chat-sessions/{id}/action-logs — MCP action logs for a session

Human intervention endpoints (HI-01):
- POST /chat-sessions/{id}/assign — staff assigns themselves
- POST /chat-sessions/{id}/reply — staff sends message via WhatsApp
- PUT /chat-sessions/{id}/resolve — staff closes session
"""

from __future__ import annotations

from typing import Optional
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from src.shared.auth import get_current_user, require_role, CurrentUser
from src.infrastructure.database import get_db_session
from src.features.chat.service import ChatService
from src.features.chat.schemas import (
    ChatSessionListResponse,
    ChatSessionResponse,
    ChatMessageListResponse,
    MCPActionLogListResponse,
    StaffReplyRequest,
    StaffReplyResponse,
    SessionActionResponse,
    RenameSessionRequest,
)
from src.features.webhook.dependencies import get_whatsapp_client

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
    session_responses = []
    for s in sessions:
        resp = ChatSessionResponse(
            id=s.id, student_id=s.student_id, whatsapp_phone=s.whatsapp_phone,
            status=s.status, name=s.name, verification_state=s.verification_state,
            assigned_staff_id=s.assigned_staff_id, escalated_at=s.escalated_at,
            started_at=s.started_at, ended_at=s.ended_at, updated_at=s.updated_at,
            student_name=s.student.name if s.student else None,
            student_ra=s.student.registration_number if s.student else None,
        )
        session_responses.append(resp)
    return ChatSessionListResponse(
        data=session_responses,
        pagination={"page": page, "per_page": per_page, "total": total},
    )


# ------------------------------------------------------------------
# PUT /chat-sessions/{id} — rename session (student owns it)
# ------------------------------------------------------------------

@router.put(
    "/{session_id}",
    response_model=ChatSessionResponse,
)
async def rename_session(
    session_id: UUID,
    body: RenameSessionRequest,
    db: AsyncSession = Depends(get_db_session),
    current_user: CurrentUser = Depends(get_current_user),
):
    """Rename a chat session. Students can only rename their own sessions."""
    session = await chat_service.rename_session(session_id, current_user.id, body.name, db)
    await db.commit()
    return session


# ------------------------------------------------------------------
# HI-01: GET /chat-sessions/interventions — staff-only
# NOTE: Must be declared BEFORE /{session_id}/* routes to avoid
#       "interventions" being matched as a session_id UUID.
# ------------------------------------------------------------------

@router.get(
    "/interventions",
    response_model=list[ChatSessionResponse],
)
async def list_intervention_sessions(
    db: AsyncSession = Depends(get_db_session),
    current_user: CurrentUser = Depends(require_role("staff")),
):
    """List sessions pending or active in human intervention (staff-only).

    Returns all 'human_needed' sessions + staff's own 'human_active' + closed sessions (T-14-04).
    """
    sessions = await chat_service.list_intervention_sessions(db, current_user.id)
    session_responses = [
        ChatSessionResponse(
            id=s.id, student_id=s.student_id, whatsapp_phone=s.whatsapp_phone,
            status=s.status, name=s.name, verification_state=s.verification_state,
            assigned_staff_id=s.assigned_staff_id, escalated_at=s.escalated_at,
            started_at=s.started_at, ended_at=s.ended_at, updated_at=s.updated_at,
            student_name=s.student.name if s.student else None,
            student_ra=s.student.registration_number if s.student else None,
        )
        for s in sessions
    ]
    return session_responses


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


# ------------------------------------------------------------------
# HI-01: POST /chat-sessions/{id}/assign — staff assigns themselves
# ------------------------------------------------------------------

@router.post(
    "/{session_id}/assign",
    response_model=SessionActionResponse,
)
async def assign_session(
    session_id: UUID,
    db: AsyncSession = Depends(get_db_session),
    current_user: CurrentUser = Depends(require_role("staff")),
):
    """Assign a human-intervention session to the current staff member.

    T-14-01: Staff-only endpoint.
    T-14-03: Validates session is in 'human_needed' status (409 otherwise).
    """
    session = await chat_service.assign_session(session_id, current_user.id, db)
    await db.commit()
    return SessionActionResponse(
        id=session.id,
        status=session.status,
        assigned_staff_id=session.assigned_staff_id,
    )


# ------------------------------------------------------------------
# HI-01: POST /chat-sessions/{id}/reply — staff sends reply via WhatsApp
# ------------------------------------------------------------------

@router.post(
    "/{session_id}/reply",
    response_model=StaffReplyResponse,
)
async def reply_to_session(
    session_id: UUID,
    body: StaffReplyRequest,
    db: AsyncSession = Depends(get_db_session),
    current_user: CurrentUser = Depends(require_role("staff")),
):
    """Staff sends a reply message to a student via WhatsApp.

    T-14-01: Staff-only endpoint.
    T-14-02: Validates assigned_staff_id matches current user.
    T-14-03: Validates session is in 'human_active' status.
    D-08: Message saved to DB + sent via WhatsApp.
    """
    msg = await chat_service.staff_reply(session_id, current_user.id, body.content, db)
    await db.commit()

    # Send via WhatsApp
    session = await chat_service.get_session(session_id, db)
    wa_client = get_whatsapp_client()
    await wa_client.send_text_message(session.whatsapp_phone, body.content)

    return StaffReplyResponse(
        message_id=msg.id,
        sent_at=msg.created_at,
    )


# ------------------------------------------------------------------
# HI-01: PUT /chat-sessions/{id}/resolve — staff resolves session
# ------------------------------------------------------------------

@router.put(
    "/{session_id}/resolve",
    response_model=SessionActionResponse,
)
async def resolve_session(
    session_id: UUID,
    db: AsyncSession = Depends(get_db_session),
    current_user: CurrentUser = Depends(require_role("staff")),
):
    """Resolve (close) a human-active session.

    T-14-01: Staff-only endpoint.
    T-14-02: Validates assigned_staff_id matches current user.
    T-14-03: Validates session is in 'human_active' status.
    """
    session = await chat_service.resolve_session(session_id, current_user.id, db)
    await db.commit()
    return SessionActionResponse(
        id=session.id,
        status=session.status,
        assigned_staff_id=session.assigned_staff_id,
    )
