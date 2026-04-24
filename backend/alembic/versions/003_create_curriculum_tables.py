"""create curriculum tables

Revision ID: 003a
Revises: 002a
Create Date: 2026-04-24 00:00:02
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "003a"
down_revision = "002a"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "courses",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("code", sa.String(length=10), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("credits", sa.Integer(), nullable=False),
        sa.Column("workload_hours", sa.Integer(), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("code", name="uq_courses_code"),
    )

    op.create_table(
        "curriculum",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("year", sa.Integer(), nullable=False),
        sa.Column("is_active", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )

    op.create_table(
        "prerequisites",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("course_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("prerequisite_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.ForeignKeyConstraint(["course_id"], ["courses.id"]),
        sa.ForeignKeyConstraint(["prerequisite_id"], ["courses.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("course_id", "prerequisite_id", name="uq_prerequisites_course_prerequisite"),
    )

    op.create_table(
        "curriculum_courses",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("curriculum_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("course_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("semester", sa.Integer(), nullable=False),
        sa.Column("is_required", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.ForeignKeyConstraint(["course_id"], ["courses.id"]),
        sa.ForeignKeyConstraint(["curriculum_id"], ["curriculum.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("curriculum_id", "course_id", name="uq_curriculum_courses_curriculum_course"),
    )

    op.create_foreign_key(
        "fk_students_curriculum_id_curriculum",
        "students",
        "curriculum",
        ["curriculum_id"],
        ["id"],
    )


def downgrade() -> None:
    op.drop_constraint("fk_students_curriculum_id_curriculum", "students", type_="foreignkey")
    op.drop_table("curriculum_courses")
    op.drop_table("prerequisites")
    op.drop_table("curriculum")
    op.drop_table("courses")
