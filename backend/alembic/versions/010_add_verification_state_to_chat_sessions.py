"""add verification_state to chat_sessions and whatsapp_message_id unique index

Revision ID: 010a
Revises: 009a
Create Date: 2026-04-30 16:35:00

Per D-01: Add verification_state column to chat_sessions with values:
unverified, awaiting_email, awaiting_code, verified.
Default is 'unverified' for new sessions.

Per MODERATE-1: Add partial unique index on whatsapp_message_id for deduplication.
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa


revision = "010a"
down_revision = "009a"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "chat_sessions",
        sa.Column(
            "verification_state",
            sa.String(20),
            nullable=False,
            server_default="unverified",
        ),
    )
    op.create_check_constraint(
        "ck_chat_sessions_verification_state",
        "chat_sessions",
        "verification_state IN ('unverified', 'awaiting_email', 'awaiting_code', 'verified')",
    )
    # MODERATE-1: Partial unique index for message deduplication by wamid
    op.execute(
        "CREATE UNIQUE INDEX uq_chat_messages_wamid "
        "ON chat_messages (whatsapp_message_id) "
        "WHERE whatsapp_message_id IS NOT NULL"
    )


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS uq_chat_messages_wamid")
    op.drop_constraint(
        "ck_chat_sessions_verification_state", "chat_sessions", type_="check"
    )
    op.drop_column("chat_sessions", "verification_state")
