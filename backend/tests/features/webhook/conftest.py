"""Webhook test fixtures: HMAC computation, payload factories, mock WhatsApp client.

Shared across all webhook test modules (HMAC, dedup, media, phone, verification,
background, session lifecycle).
"""

import hashlib
import hmac
import json
import uuid
from contextlib import asynccontextmanager

import pytest
import pytest_asyncio
from unittest.mock import AsyncMock, patch

from src.features.auth.models import Student
from src.features.chat.models import ChatSession


@pytest.fixture
def whatsapp_secret():
    """WhatsApp app secret used for HMAC validation tests."""
    return "test_app_secret"


@pytest.fixture
def compute_valid_signature(whatsapp_secret):
    """Return a function that computes valid SHA-256 HMAC for a raw body."""
    def _compute(body: bytes) -> str:
        return "sha256=" + hmac.new(
            whatsapp_secret.encode(), body, hashlib.sha256
        ).hexdigest()
    return _compute


@pytest.fixture
def patch_webhook_db(db_session):
    """Monkeypatch async_session used in webhook router to return the test session.

    The webhook handler calls `async with async_session() as db:` directly
    (not through FastAPI DI), so we must patch it to use the test SQLite session.
    """
    @asynccontextmanager
    async def _fake_session():
        yield db_session

    with patch("src.features.webhook.router.async_session", _fake_session):
        yield


@pytest.fixture
def valid_text_payload():
    """Standard WhatsApp text message payload."""
    return {
        "object": "whatsapp_business_account",
        "entry": [{
            "changes": [{
                "value": {
                    "messages": [{
                        "from": "5521999999999",
                        "id": "wamid.test123",
                        "type": "text",
                        "text": {"body": "Quais minhas notas?"},
                    }]
                }
            }]
        }]
    }


@pytest.fixture
def valid_media_payload():
    """Factory for WhatsApp media message payloads."""
    def _create(media_type: str, wamid: str | None = None):
        return {
            "object": "whatsapp_business_account",
            "entry": [{
                "changes": [{
                    "value": {
                        "messages": [{
                            "from": "5521999999999",
                            "id": wamid or f"wamid.media_{media_type}",
                            "type": media_type,
                        }]
                    }
                }]
            }]
        }
    return _create


@pytest.fixture
def status_update_payload():
    """WhatsApp delivery receipt — should be filtered out (no message processing)."""
    return {
        "object": "whatsapp_business_account",
        "entry": [{
            "changes": [{
                "value": {
                    "statuses": [{
                        "id": "wamid.test123",
                        "status": "delivered",
                        "timestamp": "1234567890",
                    }]
                }
            }]
        }]
    }


@pytest.fixture
def mock_whatsapp_client():
    """Fully mocked WhatsAppClient — captures send_text_message calls."""
    client = AsyncMock()
    client.send_text_message = AsyncMock(return_value=True)
    client.close = AsyncMock()
    return client


@pytest_asyncio.fixture
async def test_student(db_session):
    """Seeded student with WhatsApp-format phone number for webhook tests."""
    student = Student(
        id=uuid.uuid4(),
        name="Webhook Student",
        email="webhook@test.edu",
        phone="5521999999999",
        registration_number="WH001",
        semester=3,
        status="active",
        enrollment_year=2024,
    )
    db_session.add(student)
    await db_session.flush()
    return student


@pytest_asyncio.fixture
async def verified_session(db_session, test_student):
    """Active, verified chat session for the test student."""
    session = ChatSession(
        id=uuid.uuid4(),
        student_id=test_student.id,
        whatsapp_phone="5521999999999",
        status="active",
        verification_state="verified",
    )
    db_session.add(session)
    await db_session.flush()
    return session


@pytest_asyncio.fixture
async def unverified_session(db_session, test_student):
    """Active, unverified chat session for the test student."""
    session = ChatSession(
        id=uuid.uuid4(),
        student_id=test_student.id,
        whatsapp_phone="5521999999999",
        status="active",
        verification_state="unverified",
    )
    db_session.add(session)
    await db_session.flush()
    return session
