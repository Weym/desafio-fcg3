"""WhatsApp Business Cloud API client.

Encapsulates all Graph API interactions: sending messages and validating
webhook signatures. Retry logic per D-07: one immediate retry on failure.
"""

import hashlib
import hmac
import logging

import httpx

logger = logging.getLogger(__name__)


class WhatsAppClient:
    """Encapsulates all WhatsApp Business Cloud API interactions."""

    def __init__(self, settings) -> None:
        self.phone_number_id = settings.whatsapp_phone_number_id
        self.token = settings.whatsapp_token
        self.api_version = settings.whatsapp_api_version
        self.base_url = (
            f"https://graph.facebook.com/{self.api_version}"
            f"/{self.phone_number_id}/messages"
        )
        self._client = httpx.AsyncClient(
            timeout=httpx.Timeout(10.0, connect=5.0),
            headers={
                "Authorization": f"Bearer {self.token}",
                "Content-Type": "application/json",
            },
        )

    async def send_text_message(self, to: str, body: str) -> bool:
        """Send a text message via WhatsApp. Retries once on failure per D-07."""
        payload = {
            "messaging_product": "whatsapp",
            "to": to,
            "type": "text",
            "text": {"body": body},
        }
        for attempt in range(2):  # one retry per D-07
            try:
                response = await self._client.post(self.base_url, json=payload)
                if response.status_code == 200:
                    return True
                logger.warning(
                    "WhatsApp send attempt %d failed: %s %s",
                    attempt + 1,
                    response.status_code,
                    response.text,
                )
            except httpx.HTTPError as e:
                logger.warning(
                    "WhatsApp send attempt %d error: %s", attempt + 1, e
                )
        logger.error("WhatsApp send failed after 2 attempts to %s", to)
        return False  # Message still saved in chat_messages for audit per D-07

    async def close(self) -> None:
        """Close the underlying HTTP client."""
        await self._client.aclose()


def validate_signature(
    raw_body: bytes, signature_header: str, app_secret: str
) -> bool:
    """Validate X-Hub-Signature-256 header.

    Must be called BEFORE any JSON parsing (CRITICAL-1).
    Uses hmac.compare_digest for timing-safe comparison.
    """
    if not signature_header or not signature_header.startswith("sha256="):
        return False
    expected = "sha256=" + hmac.new(
        app_secret.encode(), raw_body, hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(signature_header, expected)
