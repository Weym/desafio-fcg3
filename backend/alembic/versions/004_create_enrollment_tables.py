"""create enrollment and grades tables

Revision ID: 004a
Revises: 003a
Create Date: 2026-04-24 00:00:03
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "004a"
down_revision = "003a"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "enrollment_periods",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("type", sa.String(length=20), nullable=False),
        sa.Column("start_date", sa.Date(), nullable=False),
        sa.Column("end_date", sa.Date(), nullable=False),
        sa.Column("semester_year", sa.String(length=10), nullable=False),
        sa.Column("is_active", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint("type IN ('enrollment', 're_enrollment')", name="ck_enrollment_periods_type"),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "enrollments",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("student_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("enrollment_period_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("status", sa.String(length=20), server_default=sa.text("'draft'"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("confirmed_at", sa.DateTime(timezone=True), nullable=True),
        sa.CheckConstraint("status IN ('draft', 'confirmed', 'cancelled')", name="ck_enrollments_status"),
        sa.ForeignKeyConstraint(["enrollment_period_id"], ["enrollment_periods.id"]),
        sa.ForeignKeyConstraint(["student_id"], ["students.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_enrollments_student", "enrollments", ["student_id", "status"], unique=False)

    op.create_table(
        "enrollment_courses",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("enrollment_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("course_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("status", sa.String(length=20), server_default=sa.text("'enrolled'"), nullable=False),
        sa.CheckConstraint("status IN ('enrolled', 'dropped', 'locked')", name="ck_enrollment_courses_status"),
        sa.ForeignKeyConstraint(["course_id"], ["courses.id"]),
        sa.ForeignKeyConstraint(["enrollment_id"], ["enrollments.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("enrollment_id", "course_id", name="uq_enrollment_courses_enrollment_course"),
    )

    op.create_table(
        "grades",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("student_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("course_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("enrollment_course_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("semester_year", sa.String(length=10), nullable=False),
        sa.Column("grade_1", sa.Numeric(4, 2), nullable=True),
        sa.Column("grade_2", sa.Numeric(4, 2), nullable=True),
        sa.Column("grade_final", sa.Numeric(4, 2), nullable=True),
        sa.Column("status", sa.String(length=20), server_default=sa.text("'in_progress'"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint("status IN ('in_progress', 'approved', 'failed', 'locked')", name="ck_grades_status"),
        sa.ForeignKeyConstraint(["course_id"], ["courses.id"]),
        sa.ForeignKeyConstraint(["enrollment_course_id"], ["enrollment_courses.id"]),
        sa.ForeignKeyConstraint(["student_id"], ["students.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_grades_student_semester", "grades", ["student_id", "semester_year"], unique=False)
    op.create_index("idx_grades_enrollment_course", "grades", ["enrollment_course_id"], unique=False)


def downgrade() -> None:
    op.drop_index("idx_grades_enrollment_course", table_name="grades")
    op.drop_index("idx_grades_student_semester", table_name="grades")
    op.drop_table("grades")
    op.drop_table("enrollment_courses")
    op.drop_index("idx_enrollments_student", table_name="enrollments")
    op.drop_table("enrollments")
    op.drop_table("enrollment_periods")
