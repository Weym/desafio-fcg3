"""expand staff table: provider role + status/work_schedule/position columns

Revision ID: 014a
Revises: 013a
Create Date: 2026-05-09 03:30:00

Expands staff table for provider role and management:
- Expands role CHECK constraint to include 'provider'
- Adds status column (VARCHAR(20), NOT NULL, DEFAULT 'active') with CHECK constraint
- Adds work_schedule column (TEXT, nullable)
- Adds position column (VARCHAR(100), nullable)
- Adds indexes on email and status for login and filtered queries
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
    # Drop old 3-value CHECK constraint on staff.role
    op.drop_constraint("ck_staff_role", "staff", type_="check")

    # Re-create with 4 values including 'provider' (D-25)
    op.create_check_constraint(
        "ck_staff_role",
        "staff",
        "role IN ('staff', 'coordinator', 'secretary', 'provider')",
    )

    # Add status column (D-22)
    op.add_column(
        "staff",
        sa.Column(
            "status",
            sa.String(20),
            nullable=False,
            server_default="active",
        ),
    )

    # CHECK constraint for status values
    op.create_check_constraint(
        "ck_staff_status",
        "staff",
        "status IN ('active', 'inactive')",
    )

    # Add work_schedule column (D-23) — TEXT, nullable
    op.add_column(
        "staff",
        sa.Column("work_schedule", sa.Text(), nullable=True),
    )

    # Add position column (D-24) — VARCHAR(100), nullable
    op.add_column(
        "staff",
        sa.Column("position", sa.String(100), nullable=True),
    )

    # Index on staff.email for login lookups
    op.create_index("idx_staff_email", "staff", ["email"])

    # Index on staff.status for filtered list queries
    op.create_index("idx_staff_status", "staff", ["status"])


def downgrade() -> None:
    # Drop indexes
    op.drop_index("idx_staff_status", table_name="staff")
    op.drop_index("idx_staff_email", table_name="staff")

    # Drop position column
    op.drop_column("staff", "position")

    # Drop work_schedule column
    op.drop_column("staff", "work_schedule")

    # Drop status CHECK constraint and column
    op.drop_constraint("ck_staff_status", "staff", type_="check")
    op.drop_column("staff", "status")

    # Restore original 3-value role CHECK constraint
    op.drop_constraint("ck_staff_role", "staff", type_="check")
    op.create_check_constraint(
        "ck_staff_role",
        "staff",
        "role IN ('staff', 'coordinator', 'secretary')",
    )
