"""TEST-04: HMAC-SHA256 webhook signature validation tests.

Tests that unsigned and wrong-signature requests are rejected (403),
valid signatures pass (200), and validate_signature() unit function works.

Threat mitigation: T-06-16 (spoofing).
"""

import hashlib
import hmac
import json

import pytest
from unittest.mock import patch, AsyncMock

from src.infrastructure.whatsapp_client import validate_signature


# ---- Unit tests for validate_signature() function ----


class TestValidateSignatureUnit:
    """Pure unit tests for the validate_signature function."""

    def test_valid_signature_returns_true(self):
        """Known input/output: compute HMAC and verify."""
        secret = "my_secret"
        body = b'{"test": "data"}'
        expected_sig = "sha256=" + hmac.new(
            secret.encode(), body, hashlib.sha256
        ).hexdigest()
        assert validate_signature(body, expected_sig, secret) is True

    def test_wrong_signature_returns_false(self):
        """Wrong signature → False."""
        assert validate_signature(b"body", "sha256=badhex", "secret") is False

    def test_missing_signature_returns_false(self):
        """Empty signature header → False."""
        assert validate_signature(b"body", "", "secret") is False

    def test_no_sha256_prefix_returns_false(self):
        """Signature without sha256= prefix → False."""
        assert validate_signature(b"body", "md5=abc", "secret") is False

    def test_none_signature_returns_false(self):
        """None signature → False."""
        assert validate_signature(b"body", None, "secret") is False

    def test_timing_safe_comparison(self):
        """validate_signature uses hmac.compare_digest (timing-safe)."""
        import inspect
        source = inspect.getsource(validate_signature)
        assert "compare_digest" in source


# ---- Integration tests for POST /webhook/whatsapp ----


class TestWebhookHMACIntegration:
    """Integration tests for HMAC validation in the webhook endpoint."""

    @pytest.fixture(autouse=True)
    def _patch_settings(self, whatsapp_secret, monkeypatch):
        """Override WhatsApp settings for all tests in this class."""
        from src.infrastructure.config import get_settings

        settings = get_settings()
        monkeypatch.setattr(settings, "whatsapp_app_secret", whatsapp_secret)

    async def test_missing_signature_returns_403(self, client, valid_text_payload):
        """POST without X-Hub-Signature-256 → 403."""
        body = json.dumps(valid_text_payload).encode()
        response = await client.post(
            "/api/v1/webhook/whatsapp",
            content=body,
            headers={"Content-Type": "application/json"},
        )
        assert response.status_code == 403

    async def test_wrong_signature_returns_403(self, client, valid_text_payload):
        """POST with invalid signature → 403."""
        body = json.dumps(valid_text_payload).encode()
        response = await client.post(
            "/api/v1/webhook/whatsapp",
            content=body,
            headers={
                "Content-Type": "application/json",
                "X-Hub-Signature-256": "sha256=deadbeef",
            },
        )
        assert response.status_code == 403

    async def test_valid_signature_returns_200(
        self, client, valid_text_payload, compute_valid_signature, patch_webhook_db
    ):
        """POST with valid HMAC signature → 200.

        Uses patch_webhook_db to redirect webhook's async_session to test DB.
        Patches the WhatsApp client to avoid real API calls.
        """
        body = json.dumps(valid_text_payload).encode()
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

    async def test_empty_entry_list_returns_200(
        self, client, compute_valid_signature
    ):
        """POST with valid signature + empty entry list → 200 (no processing)."""
        payload = {"object": "whatsapp_business_account", "entry": []}
        body = json.dumps(payload).encode()
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
