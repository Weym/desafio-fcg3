"""add pg_cron session auto-close job and updated_at column

Revision ID: 011a
Revises: 010a
Create Date: 2026-04-30 16:45:00

Per D-12: pg_cron extension + scheduled job to auto-close inactive sessions.
Adds updated_at column to chat_sessions for inactivity tracking.
Job runs every hour, closing sessions inactive for 24+ hours.

NOTE: Requires custom PostgreSQL Docker image with pg_cron installed
and shared_preload_libraries = 'pg_cron' in postgresql.conf.
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa


revision = "011a"
down_revision = "010a"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Add updated_at to chat_sessions for auto-close tracking
    op.add_column(
        "chat_sessions",
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )

    # Create pg_cron extension (requires pg_cron in shared_preload_libraries)
    op.execute("CREATE EXTENSION IF NOT EXISTS pg_cron")

    # Schedule session auto-close job per D-12
    # Runs every hour, closes sessions inactive for 24+ hours
    op.execute(
        "SELECT cron.schedule("
        "'close-inactive-chat-sessions', "
        "'0 * * * *', "
        "$$UPDATE chat_sessions "
        "SET status = 'closed', ended_at = NOW() "
        "WHERE updated_at < NOW() - INTERVAL '24 hours' "
        "AND status = 'active'$$"
        ")"
    )


def downgrade() -> None:
    op.execute("SELECT cron.unschedule('close-inactive-chat-sessions')")
    op.execute("DROP EXTENSION IF EXISTS pg_cron")
    op.drop_column("chat_sessions", "updated_at")
