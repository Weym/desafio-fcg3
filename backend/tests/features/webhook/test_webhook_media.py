"""TEST-04: Media type routing tests.

Verifies each of the 6 media types (audio, image, document, sticker, location, video)
receives the exact Portuguese response from docs/chatbot.md and does NOT trigger
background task (no agent involvement).
"""

import json

import pytest
from unittest.mock import patch, AsyncMock

from src.features.webhook.service import WebhookService, MEDIA_RESPONSES


# ---- Unit tests for get_media_response() ----


class TestGetMediaResponse:
    """Unit tests for WebhookService.get_media_response()."""

    def setup_method(self):
        self.svc = WebhookService()

    def test_audio_response(self):
        assert self.svc.get_media_response("audio") == MEDIA_RESPONSES["audio"]

    def test_image_response(self):
        assert self.svc.get_media_response("image") == MEDIA_RESPONSES["image"]

    def test_document_response(self):
        assert self.svc.get_media_response("document") == MEDIA_RESPONSES["document"]

    def test_sticker_response(self):
        assert self.svc.get_media_response("sticker") == MEDIA_RESPONSES["sticker"]

    def test_location_response(self):
        assert self.svc.get_media_response("location") == MEDIA_RESPONSES["location"]

    def test_video_response(self):
        assert self.svc.get_media_response("video") == MEDIA_RESPONSES["video"]

    def test_unknown_media_type_returns_default(self):
        """Unknown media type → default text response."""
        result = self.svc.get_media_response("contacts")
        assert "descreva sua duvida em texto" in result

    def test_exact_portuguese_strings(self):
        """Verify exact hardcoded Portuguese strings per docs/chatbot.md."""
        assert "Nao consigo processar audios ainda" in MEDIA_RESPONSES["audio"]
        assert "Nao consigo analisar imagens ainda" in MEDIA_RESPONSES["image"]
        assert "Recebi um documento, mas" in MEDIA_RESPONSES["document"]
        assert "descreva sua duvida em texto" in MEDIA_RESPONSES["sticker"]
        assert "Nao preciso da sua localizacao" in MEDIA_RESPONSES["location"]
        assert "Nao consigo processar videos" in MEDIA_RESPONSES["video"]


# ---- Integration tests: media through webhook endpoint ----


class TestMediaWebhookIntegration:
    """Integration tests for media messages via the webhook endpoint."""

    @pytest.fixture(autouse=True)
    def _patch_settings(self, whatsapp_secret, monkeypatch):
        """Override WhatsApp settings."""
        from src.infrastructure.config import get_settings
        settings = get_settings()
        monkeypatch.setattr(settings, "whatsapp_app_secret", whatsapp_secret)

    @pytest.mark.parametrize("media_type,expected_fragment", [
        ("audio", "Nao consigo processar audios"),
        ("image", "Nao consigo analisar imagens"),
        ("document", "Recebi um documento"),
        ("sticker", "descreva sua duvida em texto"),
        ("location", "Nao preciso da sua localizacao"),
        ("video", "Nao consigo processar videos"),
    ])
    async def test_media_type_sends_correct_response(
        self,
        client,
        valid_media_payload,
        compute_valid_signature,
        test_student,
        patch_webhook_db,
        media_type,
        expected_fragment,
    ):
        """Media message → correct Portuguese response sent, no background task."""
        payload = valid_media_payload(media_type)
        body = json.dumps(payload).encode()
        sig = compute_valid_signature(body)

        mock_wa_client = AsyncMock()
        mock_wa_client.send_text_message = AsyncMock(return_value=True)

        with patch(
            "src.features.webhook.router.get_whatsapp_client",
            return_value=mock_wa_client,
        ), patch(
            "src.features.webhook.router.asyncio"
        ) as mock_asyncio:
            response = await client.post(
                "/api/v1/webhook/whatsapp",
                content=body,
                headers={
                    "Content-Type": "application/json",
                    "X-Hub-Signature-256": sig,
                },
            )

        assert response.status_code == 200
        # Verify media response was sent via WhatsApp
        mock_wa_client.send_text_message.assert_called_once()
        sent_message = mock_wa_client.send_text_message.call_args[0][1]
        assert expected_fragment in sent_message

        # Verify asyncio.create_task was NOT called (no agent for media)
        mock_asyncio.create_task.assert_not_called()
