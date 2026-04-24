"""auth phase2 extensions: OTP hashing and refresh token support

Revision ID: 007a
Revises: 006a
Create Date: 2026-04-24 16:30:00
"""

from __future__ import annotations

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision = "007a"
down_revision = "006a"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # --- verification_codes: replace plaintext code with hash + salt ---
    op.add_column(
        "verification_codes",
        sa.Column("code_hash", sa.String(length=64), nullable=False, server_default=""),
    )
    op.alter_column("verification_codes", "code_hash", server_default=None)

    op.add_column(
        "verification_codes",
        sa.Column("code_salt", sa.String(length=32), nullable=False, server_default=""),
    )
    op.alter_column("verification_codes", "code_salt", server_default=None)

    # Drop the plaintext code column — P-04: we do NOT keep plaintext codes
    op.drop_column("verification_codes", "code")

    # --- sessions: refresh token support ---
    # D-15: token_type distinguishes access vs refresh in same table
    op.add_column(
        "sessions",
        sa.Column(
            "token_type",
            sa.String(length=10),
            nullable=False,
            server_default="access",
        ),
    )

    # parent_jti: for refresh rotation audit trail
    op.add_column(
        "sessions",
        sa.Column("parent_jti", postgresql.UUID(as_uuid=True), nullable=True),
    )

    # P-03: used flag for refresh rotation replay detection
    op.add_column(
        "sessions",
        sa.Column(
            "used",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("false"),
        ),
    )

    op.create_index("ix_sessions_token_type", "sessions", ["token_type"])
    op.create_check_constraint(
        "ck_sessions_token_type",
        "sessions",
        "token_type IN ('access', 'refresh')",
    )


def downgrade() -> None:
    # Reverse in inverse order
    op.drop_constraint("ck_sessions_token_type", "sessions", type_="check")
    op.drop_index("ix_sessions_token_type", table_name="sessions")

    op.drop_column("sessions", "used")
    op.drop_column("sessions", "parent_jti")
    op.drop_column("sessions", "token_type")

    # Re-add plaintext code column (downgrade-only, best-effort)
    op.add_column(
        "verification_codes",
        sa.Column("code", sa.String(length=6), nullable=True),
    )

    op.drop_column("verification_codes", "code_salt")
    op.drop_column("verification_codes", "code_hash")
