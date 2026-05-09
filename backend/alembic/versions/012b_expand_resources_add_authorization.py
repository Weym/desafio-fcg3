"""expand resources with new types, description, requires_authorization; add authorization_file_url to appointments

Revision ID: 012b
Revises: 012a
Create Date: 2026-05-06 10:00:00

NOTE: Originally authored as revision "012a" on the feat/human-intervention
branch. Renumbered to "012b" during merge into development because revision
"012a" was already taken by 012_fix_pg_cron_session_autoclose_quoting.py
(which had been merged earlier and applied to environments). The two 012s
touch independent subsystems (pg_cron job vs. resource columns), so a linear
chain (011a → 012a → 012b → 013a) is preferred over a merge migration.

Expands the resource allocation system:
- Adds description (Text, nullable) to resources
- Adds requires_authorization (Boolean, NOT NULL, default false) to resources
- Adds authorization_file_url (String(500), nullable) to appointments
- Expands resource_type CHECK constraint to 6 values:
  'room', 'lab', 'equipment', 'auditorium', 'study_room', 'sports_court'
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "012b"
down_revision = "012a"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Add new columns to resources
    op.add_column("resources", sa.Column("description", sa.Text(), nullable=True))
    op.add_column(
        "resources",
        sa.Column(
            "requires_authorization",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
    )

    # Add authorization_file_url to appointments
    op.add_column(
        "appointments",
        sa.Column("authorization_file_url", sa.String(500), nullable=True),
    )

    # Drop old CHECK constraint and recreate with 6 values
    op.drop_constraint("ck_resources_resource_type", "resources", type_="check")
    op.create_check_constraint(
        "ck_resources_resource_type",
        "resources",
        "resource_type IN ('room', 'lab', 'equipment', 'auditorium', 'study_room', 'sports_court')",
    )


def downgrade() -> None:
    # Revert CHECK constraint to original 3 values
    op.drop_constraint("ck_resources_resource_type", "resources", type_="check")
    op.create_check_constraint(
        "ck_resources_resource_type",
        "resources",
        "resource_type IN ('room', 'lab', 'equipment')",
    )

    # Remove added columns
    op.drop_column("appointments", "authorization_file_url")
    op.drop_column("resources", "requires_authorization")
    op.drop_column("resources", "description")
