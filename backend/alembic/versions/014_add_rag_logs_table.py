"""Add rag_logs table for RAG observability.

Revision ID: 014a
Revises: 013a
Create Date: 2026-05-09 03:32:00

Stores per-invocation RAG metadata (query, retrieved chunks with scores,
threshold result) with FK to chat_messages.id for staff debugging.
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID, JSONB

# revision identifiers, used by Alembic.
revision = "014a"
down_revision = "013a"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "rag_logs",
        sa.Column(
            "id",
            UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "chat_message_id",
            UUID(as_uuid=True),
            sa.ForeignKey("chat_messages.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("query", sa.Text(), nullable=False),
        sa.Column(
            "chunks_retrieved",
            JSONB(),
            nullable=False,
            server_default=sa.text("'[]'::jsonb"),
        ),
        sa.Column("threshold_met", sa.Boolean(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("NOW()"),
            nullable=False,
        ),
    )
    op.create_index("ix_rag_logs_chat_message_id", "rag_logs", ["chat_message_id"])


def downgrade() -> None:
    op.drop_index("ix_rag_logs_chat_message_id")
    op.drop_table("rag_logs")
