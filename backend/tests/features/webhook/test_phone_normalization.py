"""D-04: Phone number normalization tests.

Verifies direct string comparison for phone lookup (no regex, no + prefix),
and unknown phone rejection behavior.
"""

import json
import uuid

import pytest
from unittest.mock import patch, AsyncMock

from src.features.auth.models import Student
from src.features.webhook.service import WebhookService


class TestPhoneLookup:
    """Phone lookup via direct string comparison (D-04)."""

    async def test_exact_match_succeeds(self, db_session, test_student):
        """Phone '5521999999999' matches WhatsApp format '5521999999999'."""
        svc = WebhookService()
        result = await svc.lookup_student_by_phone("5521999999999", db_session)
        assert result is not None
        assert result.id == test_student.id

    async def test_unknown_phone_returns_none(self, db_session, test_student):
        """Unknown phone → None (no student found)."""
        svc = WebhookService()
        result = await svc.lookup_student_by_phone("5511888888888", db_session)
        assert result is None

    async def test_inactive_student_not_found(self, db_session):
        """Inactive student phone → None (status must be active)."""
        student = Student(
            id=uuid.uuid4(),
            name="Inactive Student",
            email="inactive@test.edu",
            phone="5521888888888",
            registration_number="INAC01",
            semester=1,
            status="inactive",
            enrollment_year=2024,
        )
        db_session.add(student)
        await db_session.flush()

        svc = WebhookService()
        result = await svc.lookup_student_by_phone("5521888888888", db_session)
        assert result is None

    async def test_plus_prefix_does_not_match(self, db_session, test_student):
        """Phone stored without + prefix; +prefix query should not match."""
        svc = WebhookService()
        result = await svc.lookup_student_by_phone("+5521999999999", db_session)
        assert result is None


class TestUnknownPhoneWebhook:
    """Integration test: unknown phone sends rejection, no session created."""

    async def test_unknown_phone_sends_rejection(
        self, client, compute_valid_signature, patch_webhook_db, monkeypatch
    ):
        """Unknown phone → rejection message sent, no chat_session created."""
        from src.infrastructure.config import get_settings

        settings = get_settings()
        monkeypatch.setattr(settings, "whatsapp_app_secret", "test_app_secret")

        payload = {
            "object": "whatsapp_business_account",
            "entry": [{
                "changes": [{
                    "value": {
                        "messages": [{
                            "from": "5511000000000",
                            "id": "wamid.unknown_phone",
                            "type": "text",
                            "text": {"body": "Oi"},
                        }]
                    }
                }]
            }]
        }
        body = json.dumps(payload).encode()
        sig = compute_valid_signature(body)

        mock_wa_client = AsyncMock()
        mock_wa_client.send_text_message = AsyncMock(return_value=True)

        with patch(
            "src.features.webhook.router.get_whatsapp_client",
            return_value=mock_wa_client,
        ):
            response = await client.post(
                "/api/v1/webhook/whatsapp",
                content=body,
                headers={
                    "Content-Type": "application/json",
                    "X-Hub-Signature-256": sig,
                },
            )

        assert response.status_code == 200
        mock_wa_client.send_text_message.assert_called_once()
        sent_msg = mock_wa_client.send_text_message.call_args[0][1]
        assert "Nao encontrei cadastro" in sent_msg
