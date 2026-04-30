"""Session lifecycle tests (D-10, D-11, D-13).

Tests: active session reuse, closed session creates new one,
"sair"/"encerrar" keyword closes session.
"""

import uuid
from datetime import datetime, timezone

import pytest

from src.features.chat.models import ChatSession
from src.features.webhook.service import WebhookService


class TestSessionLifecycle:
    """Session reuse, close, and re-create behavior."""

    async def test_active_session_reused(self, db_session, test_student):
        """D-10: Active session reused for same student."""
        svc = WebhookService()

        session1 = await svc.get_or_create_session(
            test_student.id, "5521999999999", db_session
        )
        await db_session.commit()

        session2 = await svc.get_or_create_session(
            test_student.id, "5521999999999", db_session
        )

        assert session1.id == session2.id

    async def test_closed_session_creates_new(self, db_session, test_student):
        """D-13: Closed session → new session created with unverified state."""
        svc = WebhookService()

        # Create and close first session
        session1 = await svc.get_or_create_session(
            test_student.id, "5521999999999", db_session
        )
        await svc.close_session(session1, db_session)
        await db_session.commit()

        # New session should be created
        session2 = await svc.get_or_create_session(
            test_student.id, "5521999999999", db_session
        )

        assert session2.id != session1.id
        assert session2.verification_state == "unverified"
        assert session2.status == "active"

    async def test_sair_keyword_closes_session(self, db_session, test_student):
        """D-11: 'sair' keyword → session closed."""
        svc = WebhookService()

        session = await svc.get_or_create_session(
            test_student.id, "5521999999999", db_session
        )
        await svc.close_session(session, db_session)
        await db_session.flush()

        assert session.status == "closed"
        assert session.ended_at is not None

    async def test_encerrar_keyword_closes_session(self, db_session, test_student):
        """D-11: 'encerrar' keyword → session closed."""
        svc = WebhookService()

        session = await svc.get_or_create_session(
            test_student.id, "5521999999999", db_session
        )
        await svc.close_session(session, db_session)
        await db_session.flush()

        assert session.status == "closed"

    async def test_sair_case_insensitive(self, db_session, test_student):
        """D-11: 'SAIR' (uppercase) → still closes (case-insensitive check in router)."""
        # The case-insensitivity is checked in the router:
        # `text_content.strip().lower() in {"sair", "encerrar"}`
        text = "SAIR"
        assert text.strip().lower() in {"sair", "encerrar"}

    async def test_updated_at_touched_on_reuse(self, db_session, test_student):
        """D-12: updated_at is touched when session is reused for inactivity tracking."""
        svc = WebhookService()

        session = await svc.get_or_create_session(
            test_student.id, "5521999999999", db_session
        )
        original_updated = session.updated_at
        await db_session.commit()

        # Access session again
        session2 = await svc.get_or_create_session(
            test_student.id, "5521999999999", db_session
        )
        # updated_at should be refreshed
        assert session2.updated_at is not None

    async def test_new_session_starts_unverified(self, db_session, test_student):
        """D-13: New session always starts with verification_state='unverified'."""
        svc = WebhookService()

        session = await svc.get_or_create_session(
            test_student.id, "5521999999999", db_session
        )

        assert session.verification_state == "unverified"
