"""Response schemas for chat visibility endpoints (CHAT-03).

Staff-only schemas for listing sessions, messages, and MCP action logs.
All schemas use from_attributes=True for ORM compatibility with SQLAlchemy models.
"""

from __future__ import annotations

from datetime import datetime
from typing import Any, Optional
from uuid import UUID

from pydantic import BaseModel


class ChatSessionResponse(BaseModel):
    id: UUID
    student_id: UUID
    whatsapp_phone: str
    status: str
    verification_state: str
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
