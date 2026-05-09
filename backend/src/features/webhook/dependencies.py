"""Webhook dependencies: WhatsApp client and service singletons."""

from __future__ import annotations

from src.features.webhook.service import WebhookService
from src.infrastructure.config import get_settings
from src.infrastructure.whatsapp_client import WhatsAppClient

_whatsapp_client: WhatsAppClient | None = None
_webhook_service: WebhookService | None = None


def get_whatsapp_client() -> WhatsAppClient:
    """Return singleton WhatsAppClient instance."""
    global _whatsapp_client
    if _whatsapp_client is None:
        settings = get_settings()
        _whatsapp_client = WhatsAppClient(settings)
    return _whatsapp_client


def get_webhook_service() -> WebhookService:
    """Return singleton WebhookService instance."""
    global _webhook_service
    if _webhook_service is None:
        _webhook_service = WebhookService()
    return _webhook_service
