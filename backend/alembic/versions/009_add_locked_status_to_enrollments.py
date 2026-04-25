"""close UAT Test 6 schema drift for locked enrollments

Revision ID: 009a
Revises: 008a
Create Date: 2026-04-25 00:20:00

UAT Test 6 and the enrollment lock debug diagnosis showed that migrated
PostgreSQL databases still enforce the old ck_enrollments_status constraint
without the `locked` status. This migration updates only that constraint.
"""

from __future__ import annotations

from alembic import op


revision = "009a"
down_revision = "008a"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.drop_constraint("ck_enrollments_status", "enrollments", type_="check")
    op.create_check_constraint(
        "ck_enrollments_status",
        "enrollments",
        "status IN ('draft', 'confirmed', 'cancelled', 'locked')",
    )


def downgrade() -> None:
    op.drop_constraint("ck_enrollments_status", "enrollments", type_="check")
    op.create_check_constraint(
        "ck_enrollments_status",
        "enrollments",
        "status IN ('draft', 'confirmed', 'cancelled')",
    )
