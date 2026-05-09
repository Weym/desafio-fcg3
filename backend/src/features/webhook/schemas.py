"""Pydantic schemas for WhatsApp webhook payload parsing.

Mirrors the WhatsApp Business Cloud API webhook payload structure.
See docs/api.md and docs/chatbot.md for reference.
"""

from __future__ import annotations

from typing import Optional

from pydantic import BaseModel, Field


class WhatsAppTextBody(BaseModel):
    """Text message body."""

    body: str


class WhatsAppMessage(BaseModel):
    """A single WhatsApp message within the webhook payload."""

    from_: str = Field(alias="from")  # 'from' is a Python keyword
    id: str  # wamid for deduplication
    type: str  # text, audio, image, document, sticker, location, video
    timestamp: Optional[str] = None
    text: Optional[WhatsAppTextBody] = None

    model_config = {"populate_by_name": True}


class WhatsAppContact(BaseModel):
    """Contact info from WhatsApp webhook."""

    wa_id: str
    profile: Optional[dict] = None


class WhatsAppValueChange(BaseModel):
    """Value section containing messages and statuses."""

    messages: list[WhatsAppMessage] = []
    statuses: list[dict] = []  # delivery receipts — filtered out
    contacts: list[WhatsAppContact] = []


class WhatsAppChange(BaseModel):
    """A single change entry."""

    value: WhatsAppValueChange
    field: Optional[str] = None


class WhatsAppEntry(BaseModel):
    """A single entry in the webhook payload."""

    id: Optional[str] = None
    changes: list[WhatsAppChange]


class WhatsAppWebhookPayload(BaseModel):
    """Top-level WhatsApp webhook payload."""

    object: str
    entry: list[WhatsAppEntry]
