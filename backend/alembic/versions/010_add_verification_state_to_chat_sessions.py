"""add verification_state to chat_sessions

Revision ID: 010a
Revises: 009a
Create Date: 2026-04-30 16:35:00

Per D-01: Add verification_state column to chat_sessions with values:
unverified, awaiting_email, awaiting_code, verified.
Default is 'unverified' for new sessions.
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


def downgrade() -> None:
    op.drop_constraint(
        "ck_chat_sessions_verification_state", "chat_sessions", type_="check"
    )
    op.drop_column("chat_sessions", "verification_state")
