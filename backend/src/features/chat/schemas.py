"""Response schemas for chat visibility endpoints (CHAT-03) and human intervention (HI-01).

Staff-only schemas for listing sessions, messages, MCP action logs,
and human intervention actions (assign, reply, resolve).
All schemas use from_attributes=True for ORM compatibility with SQLAlchemy models.
"""

from __future__ import annotations

from datetime import datetime
from typing import Any, Optional
from uuid import UUID

from pydantic import BaseModel, Field


class ChatSessionResponse(BaseModel):
    id: UUID
    student_id: UUID
    whatsapp_phone: str
    status: str
    verification_state: str
    assigned_staff_id: UUID | None = None
    escalated_at: datetime | None = None
    started_at: datetime
    ended_at: Optional[datetime] = None
    updated_at: datetime

    model_config = {"from_attributes": True}


class ChatMessageResponse(BaseModel):
    id: UUID
    chat_session_id: UUID
    role: str
    content: str
    media_type: Optional[str] = None
    whatsapp_message_id: Optional[str] = None
    created_at: datetime

    model_config = {"from_attributes": True}


class MCPActionLogResponse(BaseModel):
    id: UUID
    chat_session_id: UUID
    tool_name: str
    input_params: dict[str, Any]
    output_result: Optional[dict[str, Any]] = None
    reasoning: Optional[str] = None
    latency_ms: Optional[int] = None
    retry: bool
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}


class ChatSessionListResponse(BaseModel):
    data: list[ChatSessionResponse]
    pagination: dict[str, int]  # {page, per_page, total}


class ChatMessageListResponse(BaseModel):
    data: list[ChatMessageResponse]


class MCPActionLogListResponse(BaseModel):
    data: list[MCPActionLogResponse]


# --- Human Intervention Schemas (HI-01) ---


class StaffReplyRequest(BaseModel):
    """Request body for staff reply to a human-intervention session."""
    content: str = Field(..., min_length=1, max_length=4000)


class StaffReplyResponse(BaseModel):
    """Response after staff sends a reply message."""
    message_id: UUID
    sent_at: datetime


class SessionActionResponse(BaseModel):
    """Response for assign/resolve session actions."""
    id: UUID
    status: str
    assigned_staff_id: UUID | None = None
