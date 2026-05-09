"""create pgvector extension

Revision ID: 001a
Revises:
Create Date: 2026-04-24 00:00:00
"""

from __future__ import annotations

from alembic import op

revision = "001a"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("CREATE EXTENSION IF NOT EXISTS vector")


def downgrade() -> None:
    op.execute("DROP EXTENSION IF EXISTS vector")
