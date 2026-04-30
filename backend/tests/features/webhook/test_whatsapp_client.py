"""WhatsApp client unit tests.

Tests per D-07, D-08: send retry logic, validate_signature function.
All HTTP calls are mocked via httpx (D-17).
"""

import hashlib
import hmac
from unittest.mock import AsyncMock, patch, MagicMock

import pytest
import httpx

from src.infrastructure.whatsapp_client import WhatsAppClient, validate_signature


class TestWhatsAppClientSend:
    """Tests for WhatsAppClient.send_text_message retry logic."""

    def _make_client(self):
        """Create a WhatsAppClient with mocked settings."""
        settings = MagicMock()
        settings.whatsapp_phone_number_id = "123456"
        settings.whatsapp_token = "test-token"
        settings.whatsapp_api_version = "v18.0"
        return WhatsAppClient(settings)

    async def test_successful_send_returns_true(self):
        """First attempt succeeds → returns True."""
        client = self._make_client()
        mock_response = MagicMock()
        mock_response.status_code = 200

        with patch.object(client._client, "post", new_callable=AsyncMock) as mock_post:
            mock_post.return_value = mock_response
            result = await client.send_text_message("5521999999999", "Hello")

        assert result is True
        mock_post.assert_called_once()

    async def test_retry_on_first_failure(self):
        """First attempt fails, second succeeds → returns True (D-07)."""
        client = self._make_client()

        fail_response = MagicMock()
        fail_response.status_code = 500
        fail_response.text = "Internal Server Error"

        ok_response = MagicMock()
        ok_response.status_code = 200

        with patch.object(client._client, "post", new_callable=AsyncMock) as mock_post:
            mock_post.side_effect = [fail_response, ok_response]
            result = await client.send_text_message("5521999999999", "Hello")

        assert result is True
        assert mock_post.call_count == 2

    async def test_both_attempts_fail_returns_false(self):
        """Both attempts fail → returns False, error logged (D-07)."""
        client = self._make_client()

        fail_response = MagicMock()
        fail_response.status_code = 500
        fail_response.text = "Internal Server Error"

        with patch.object(client._client, "post", new_callable=AsyncMock) as mock_post:
            mock_post.return_value = fail_response
            result = await client.send_text_message("5521999999999", "Hello")

        assert result is False
        assert mock_post.call_count == 2

    async def test_http_error_retried(self):
        """httpx.HTTPError on first attempt → retry, second succeeds."""
        client = self._make_client()

        ok_response = MagicMock()
        ok_response.status_code = 200

        with patch.object(client._client, "post", new_callable=AsyncMock) as mock_post:
            mock_post.side_effect = [httpx.ConnectError("Connection refused"), ok_response]
            result = await client.send_text_message("5521999999999", "Hello")

        assert result is True
        assert mock_post.call_count == 2

    async def test_http_error_both_attempts_returns_false(self):
        """httpx.HTTPError on both attempts → returns False."""
        client = self._make_client()

        with patch.object(client._client, "post", new_callable=AsyncMock) as mock_post:
            mock_post.side_effect = httpx.ConnectError("Connection refused")
            result = await client.send_text_message("5521999999999", "Hello")

        assert result is False
        assert mock_post.call_count == 2


class TestValidateSignatureAdditional:
    """Additional validate_signature tests (complements test_webhook_hmac.py)."""

    def test_known_hmac_computation(self):
        """Compute HMAC with known values and verify match."""
        secret = "whatsapp_secret_key"
        body = b'{"object":"whatsapp_business_account"}'
        expected_hex = hmac.new(
            secret.encode(), body, hashlib.sha256
        ).hexdigest()
        sig = f"sha256={expected_hex}"

        assert validate_signature(body, sig, secret) is True

    def test_different_body_does_not_match(self):
        """HMAC for different body should not match."""
        secret = "test_secret"
        body1 = b'{"a": 1}'
        body2 = b'{"a": 2}'
        sig = "sha256=" + hmac.new(
            secret.encode(), body1, hashlib.sha256
        ).hexdigest()

        assert validate_signature(body2, sig, secret) is False
