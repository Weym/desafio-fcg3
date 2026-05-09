"""fix pg_cron session auto-close job quoting

Revision ID: 012a
Revises: 011a
Create Date: 2026-05-06 00:10:00

Migration 011 stored a pg_cron command with an invalid mix of dollar-quoting
(`$$...$$`) AND classic SQL single-quote escaping (`''closed''`). Because
dollar-quoted bodies are literal, the `''` escapes became literal doubled
single quotes in the stored cron.job.command, producing at every hourly run:

    ERROR: syntax error at or near "closed"

Result: `chat_sessions.status` never transitioned from 'active' to 'closed',
and `ended_at` was never set. Sessions accumulated indefinitely.

This migration:
  1. Unschedules the broken job (idempotent — no-op if absent).
  2. Re-schedules it with correct single-quote syntax inside `$$...$$`.

Mirrors 011's SAVEPOINT pattern so the migration is safe on environments
without pg_cron installed.
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa


revision = "012a"
down_revision = "011a"
branch_labels = None
depends_on = None


# Correct command: single quotes are literal inside $$...$$, so do NOT escape
# them as ''. Keep this string aligned with migration 011's upgrade() so a
# fresh database and a migrated database end up with identical cron.job rows.
_SCHEDULE_SQL = (
    "SELECT cron.schedule("
    "'close-inactive-chat-sessions', "
    "'0 * * * *', "
    "$$UPDATE chat_sessions "
    "SET status = 'closed', ended_at = NOW() "
    "WHERE updated_at < NOW() - INTERVAL '24 hours' "
    "AND status = 'active'$$"
    ")"
)


def upgrade() -> None:
    conn = op.get_bind()
    nested = conn.begin_nested()
    try:
        # Unschedule the broken job if it exists. `cron.unschedule` raises if
        # the named job is absent, so guard with a SAVEPOINT first.
        inner = conn.begin_nested()
        try:
            conn.execute(
                sa.text("SELECT cron.unschedule('close-inactive-chat-sessions')")
            )
            inner.commit()
        except Exception:
            inner.rollback()  # job not present — fine, continue to re-schedule

        # Re-schedule with correct quoting.
        conn.execute(sa.text(_SCHEDULE_SQL))
        nested.commit()
    except Exception:
        nested.rollback()
        # pg_cron not available — same graceful skip as migration 011.
        import warnings
        warnings.warn(
            "pg_cron extension not available — session auto-close job NOT re-scheduled. "
            "Install pg_cron in PostgreSQL for production use.",
            stacklevel=1,
        )


def downgrade() -> None:
    # Downgrade reverts to the broken-quoting command that 011 originally
    # installed, so alembic downgrades remain symmetric with the migration
    # that owns the job definition.
    conn = op.get_bind()
    nested = conn.begin_nested()
    try:
        inner = conn.begin_nested()
        try:
            conn.execute(
                sa.text("SELECT cron.unschedule('close-inactive-chat-sessions')")
            )
            inner.commit()
        except Exception:
            inner.rollback()

        conn.execute(
            sa.text(
                "SELECT cron.schedule("
                "'close-inactive-chat-sessions', "
                "'0 * * * *', "
                "$$UPDATE chat_sessions "
                "SET status = ''closed'', ended_at = NOW() "
                "WHERE updated_at < NOW() - INTERVAL ''24 hours'' "
                "AND status = ''active''$$"
                ")"
            )
        )
        nested.commit()
    except Exception:
        nested.rollback()
