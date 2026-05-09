"""add notes column to documents table

Revision ID: 008a
Revises: 007a
Create Date: 2026-04-24 22:00:00

SM-02: docs/api.md POST /documents includes 'notes' field but docs/database.md
documents table had no 'notes' column. This migration resolves the mismatch.
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa

revision = "008a"
down_revision = "007a"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("documents", sa.Column("notes", sa.Text(), nullable=True))


def downgrade() -> None:
    op.drop_column("documents", "notes")
