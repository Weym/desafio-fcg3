"""Add is_deleted column to resources table.

Revision ID: 015a
Revises: 014a
Create Date: 2026-05-09

Adds is_deleted boolean column for true soft-delete (distinct from is_available toggle).
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "015a"
down_revision = "014a"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "resources",
        sa.Column("is_deleted", sa.Boolean(), nullable=False, server_default=sa.text("false")),
    )


def downgrade() -> None:
    op.drop_column("resources", "is_deleted")
