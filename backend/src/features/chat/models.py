from __future__ import annotations

import uuid
from datetime import datetime
from typing import Any

from sqlalchemy import Boolean, CheckConstraint, DateTime, ForeignKey, Index, Integer, String, Text, func, text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

try:
    from infrastructure.database import Base
except ModuleNotFoundError:  # pragma: no cover
    from src.infrastructure.database import Base


class ChatSession(Base):
    __tablename__ = "chat_sessions"
    __table_args__ = (
        CheckConstraint(
            "status IN ('active', 'closed')",
            name="ck_chat_sessions_status",
        ),
        Index("idx_chat_sessions_student", "student_id", "status"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("students.id"), nullable=False)
    whatsapp_phone: Mapped[str] = mapped_column(String(20), nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False, server_default=text("'active'"))
    verification_state: Mapped[str] = mapped_column(String(20), nullable=False, server_default=text("'unverified'"))
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=func.now())
    ended_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=func.now())

    student: Mapped["Student"] = relationship(back_populates="chat_sessions")
    chat_messages: Mapped[list["ChatMessage"]] = relationship(back_populates="chat_session")
    mcp_action_logs: Mapped[list["McpActionLog"]] = relationship(back_populates="chat_session")


class ChatMessage(Base):
    __tablename__ = "chat_messages"
    __table_args__ = (
        CheckConstraint(
            "role IN ('user', 'assistant', 'system')",
            name="ck_chat_messages_role",
        ),
        CheckConstraint(
            "media_type IS NULL OR media_type IN ('audio', 'image', 'document', 'video', 'sticker')",
            name="ck_chat_messages_media_type",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    chat_session_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("chat_sessions.id"), nullable=False)
    role: Mapped[str] = mapped_column(String(10), nullable=False)
    content: Mapped[str] = mapped_column(Text, nullable=False)
    media_type: Mapped[str | None] = mapped_column(String(20))
    whatsapp_message_id: Mapped[str | None] = mapped_column(String(100))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=func.now())

    chat_session: Mapped[ChatSession] = relationship(back_populates="chat_messages")


class McpActionLog(Base):
    __tablename__ = "mcp_action_logs"
    __table_args__ = (
        CheckConstraint(
            "status IN ('success', 'error', 'retry_success')",
            name="ck_mcp_action_logs_status",
        ),
        Index("idx_mcp_logs_session", "chat_session_id", "created_at"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    chat_session_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("chat_sessions.id"), nullable=False)
    tool_name: Mapped[str] = mapped_column(String(100), nullable=False)
    input_params: Mapped[dict[str, Any]] = mapped_column(JSONB, nullable=False, default=dict)
    output_result: Mapped[dict[str, Any] | None] = mapped_column(JSONB)
    reasoning: Mapped[str | None] = mapped_column(Text)
    latency_ms: Mapped[int | None] = mapped_column(Integer)
    retry: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("false"))
    status: Mapped[str] = mapped_column(String(20), nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=func.now())

    chat_session: Mapped[ChatSession] = relationship(back_populates="mcp_action_logs")
