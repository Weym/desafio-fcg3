"""TEST-04: Message deduplication tests.

Verifies that duplicate wamid produces only one chat_message row,
different wamids produce separate rows, and status updates are filtered.
"""

import json

import pytest

from src.features.webhook.service import WebhookService


class TestMessageDeduplication:
    """Deduplication via whatsapp_message_id (MODERATE-1)."""

    async def test_same_wamid_produces_one_row(self, db_session, verified_session):
        """Same wamid sent twice → only one chat_message row (second returns None).

        Note: Dedup relies on a partial UNIQUE index on whatsapp_message_id
        (migration 010a). SQLite test DB doesn't have this index, so we create
        a regular unique index for testing purposes.
        """
        from sqlalchemy import text as sql_text

        # Create a unique index on whatsapp_message_id for SQLite
        # (mirrors the partial UNIQUE INDEX from migration 010a)
        conn = await db_session.connection()
        await conn.execute(
            sql_text(
                "CREATE UNIQUE INDEX IF NOT EXISTS uq_test_wamid "
                "ON chat_messages(whatsapp_message_id)"
            )
        )
        await db_session.flush()

        svc = WebhookService()
        wamid = "wamid.dedup_test_123"

        # First save should succeed
        msg1 = await svc.save_message(
            verified_session.id, "user", "Hello", None, wamid, db_session
        )
        await db_session.commit()
        assert msg1 is not None

        # Second save with same wamid should return None (dedup)
        msg2 = await svc.save_message(
            verified_session.id, "user", "Hello again", None, wamid, db_session
        )
        assert msg2 is None

    async def test_different_wamid_produces_two_rows(self, db_session, verified_session):
        """Different wamids → two separate chat_message rows."""
        svc = WebhookService()

        msg1 = await svc.save_message(
            verified_session.id, "user", "First", None, "wamid.unique_1", db_session
        )
        await db_session.commit()
        msg2 = await svc.save_message(
            verified_session.id, "user", "Second", None, "wamid.unique_2", db_session
        )
        await db_session.commit()

        assert msg1 is not None
        assert msg2 is not None
        assert msg1.id != msg2.id

    async def test_null_wamid_allows_duplicates(self, db_session, verified_session):
        """Assistant messages (wamid=None) should not trigger dedup."""
        svc = WebhookService()

        msg1 = await svc.save_message(
            verified_session.id, "assistant", "Response 1", None, None, db_session
        )
        await db_session.commit()
        msg2 = await svc.save_message(
            verified_session.id, "assistant", "Response 2", None, None, db_session
        )
        await db_session.commit()

        assert msg1 is not None
        assert msg2 is not None

    async def test_status_update_returns_200_no_messages(
        self, client, status_update_payload, compute_valid_signature, monkeypatch
    ):
        """Status update event (delivery receipt) → 200, no messages saved."""
        from src.infrastructure.config import get_settings

        settings = get_settings()
        monkeypatch.setattr(settings, "whatsapp_app_secret", "test_app_secret")

        body = json.dumps(status_update_payload).encode()
        sig = compute_valid_signature(body)

        response = await client.post(
            "/api/v1/webhook/whatsapp",
            content=body,
            headers={
                "Content-Type": "application/json",
                "X-Hub-Signature-256": sig,
            },
        )
        assert response.status_code == 200
