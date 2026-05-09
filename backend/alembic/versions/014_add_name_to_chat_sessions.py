"""add name column to chat_sessions

Revision ID: 014a
Revises: 013a
Create Date: 2026-05-09 12:00:00

Adds nullable name column to chat_sessions for user-defined session labels.
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "014a"
down_revision = "013a"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "chat_sessions",
        sa.Column("name", sa.String(100), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("chat_sessions", "name")
