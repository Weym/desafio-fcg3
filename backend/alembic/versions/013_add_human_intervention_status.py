"""add human intervention status to chat_sessions

Revision ID: 013a
Revises: 012a
Create Date: 2026-05-06 12:00:00

Expands chat_sessions for human intervention:
- Expands status CHECK constraint to 4 values: active, closed, human_needed, human_active
- Adds assigned_staff_id (UUID FK to staff.id, nullable)
- Adds escalated_at (DateTime with timezone, nullable)
- Adds partial index for fast staff queries on intervention statuses
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID

# revision identifiers, used by Alembic.
revision = "013a"
down_revision = "012a"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Drop old 2-value CHECK constraint on chat_sessions.status
    op.drop_constraint("ck_chat_sessions_status", "chat_sessions", type_="check")

    # Re-create with 4 values (D-01)
    op.create_check_constraint(
        "ck_chat_sessions_status",
        "chat_sessions",
        "status IN ('active', 'closed', 'human_needed', 'human_active')",
    )

    # Add assigned_staff_id column (FK to staff.id, nullable) per D-02
    op.add_column(
        "chat_sessions",
        sa.Column("assigned_staff_id", UUID(as_uuid=True), nullable=True),
    )
    op.create_foreign_key(
        "fk_chat_sessions_assigned_staff",
        "chat_sessions",
        "staff",
        ["assigned_staff_id"],
        ["id"],
    )

    # Add escalated_at column (DateTime with timezone, nullable)
    op.add_column(
        "chat_sessions",
        sa.Column("escalated_at", sa.DateTime(timezone=True), nullable=True),
    )

    # Partial index for fast staff queries on intervention statuses
    op.create_index(
        "idx_chat_sessions_human_status",
        "chat_sessions",
        ["status"],
        postgresql_where=sa.text("status IN ('human_needed', 'human_active')"),
    )


def downgrade() -> None:
    # Drop partial index
    op.drop_index("idx_chat_sessions_human_status", table_name="chat_sessions")

    # Drop escalated_at column
    op.drop_column("chat_sessions", "escalated_at")

    # Drop FK and assigned_staff_id column
    op.drop_constraint(
        "fk_chat_sessions_assigned_staff", "chat_sessions", type_="foreignkey"
    )
    op.drop_column("chat_sessions", "assigned_staff_id")

    # Restore original 2-value CHECK constraint
    op.drop_constraint("ck_chat_sessions_status", "chat_sessions", type_="check")
    op.create_check_constraint(
        "ck_chat_sessions_status",
        "chat_sessions",
        "status IN ('active', 'closed')",
    )
