"""Notification schemas and event types for FCM push notifications.

Defines:
- FcmTokenRegister / FcmTokenDelete: request bodies for token CRUD
- NotificationEvent: enum of supported push notification event types
- NotificationPayload: internal payload structure for sending notifications
"""

from __future__ import annotations

from enum import StrEnum

from pydantic import BaseModel, Field


class FcmTokenRegister(BaseModel):
    """Request body for PUT /students/{id}/fcm-token."""

    token: str = Field(..., min_length=1, max_length=255, description="FCM device token")
    device_name: str | None = Field(
        default=None, max_length=100, description="Optional device identifier"
    )


class FcmTokenDelete(BaseModel):
    """Request body for DELETE /students/{id}/fcm-token."""

    token: str = Field(..., min_length=1, max_length=255, description="FCM device token to remove")


class NotificationEvent(StrEnum):
    """Supported FCM push notification event types (D-10: chat_reply excluded)."""

    document_ready = "document_ready"
    enrollment_confirmed = "enrollment_confirmed"
    appointment_confirmed = "appointment_confirmed"


class NotificationPayload(BaseModel):
    """Internal payload structure for building FCM messages."""

    event: NotificationEvent
    title: str
    body: str
    data: dict[str, str] = Field(default_factory=dict)
