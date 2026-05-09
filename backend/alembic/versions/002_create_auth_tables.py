"""create auth tables

Revision ID: 002a
Revises: 001a
Create Date: 2026-04-24 00:00:01
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "002a"
down_revision = "001a"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "students",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("phone", sa.String(length=20), nullable=True),
        sa.Column("registration_number", sa.String(length=20), nullable=False),
        sa.Column("semester", sa.Integer(), server_default=sa.text("1"), nullable=False),
        sa.Column("status", sa.String(length=20), server_default=sa.text("'active'"), nullable=False),
        sa.Column("enrollment_year", sa.Integer(), nullable=False),
        sa.Column("curriculum_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint("status IN ('active', 'inactive', 'graduated', 'locked')", name="ck_students_status"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("email", name="uq_students_email"),
        sa.UniqueConstraint("phone", name="uq_students_phone"),
        sa.UniqueConstraint("registration_number", name="uq_students_registration_number"),
    )
    op.create_index("idx_students_email", "students", ["email"], unique=False)
    op.create_index("idx_students_phone", "students", ["phone"], unique=False)
    op.create_index("idx_students_registration", "students", ["registration_number"], unique=False)

    op.create_table(
        "staff",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("phone", sa.String(length=20), nullable=True),
        sa.Column("role", sa.String(length=50), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint("role IN ('staff', 'coordinator', 'secretary')", name="ck_staff_role"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("email", name="uq_staff_email"),
    )

    op.create_table(
        "verification_codes",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("code", sa.String(length=6), nullable=False),
        sa.Column("channel", sa.String(length=10), nullable=False),
        sa.Column("attempts", sa.Integer(), server_default=sa.text("0"), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("used", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint("channel IN ('email', 'sms')", name="ck_verification_codes_channel"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_verification_codes_email", "verification_codes", ["email", "used", "expires_at"], unique=False)

    op.create_table(
        "sessions",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("user_type", sa.String(length=10), nullable=False),
        sa.Column("jti", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("platform", sa.String(length=20), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.CheckConstraint("platform IN ('whatsapp', 'app')", name="ck_sessions_platform"),
        sa.CheckConstraint("user_type IN ('student', 'staff')", name="ck_sessions_user_type"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("idx_sessions_jti", "sessions", ["jti"], unique=True)
    op.create_index("idx_sessions_user", "sessions", ["user_id", "expires_at"], unique=False)

    op.create_table(
        "fcm_tokens",
        sa.Column("id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("student_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("token", sa.String(length=255), nullable=False),
        sa.Column("device_name", sa.String(length=100), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["student_id"], ["students.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("student_id", "token", name="uq_fcm_tokens_student_token"),
    )
    op.create_index("idx_fcm_tokens_student", "fcm_tokens", ["student_id"], unique=False)


def downgrade() -> None:
    op.drop_index("idx_fcm_tokens_student", table_name="fcm_tokens")
    op.drop_table("fcm_tokens")
    op.drop_index("idx_sessions_user", table_name="sessions")
    op.drop_index("idx_sessions_jti", table_name="sessions")
    op.drop_table("sessions")
    op.drop_index("idx_verification_codes_email", table_name="verification_codes")
    op.drop_table("verification_codes")
    op.drop_table("staff")
    op.drop_index("idx_students_registration", table_name="students")
    op.drop_index("idx_students_phone", table_name="students")
    op.drop_index("idx_students_email", table_name="students")
    op.drop_table("students")
