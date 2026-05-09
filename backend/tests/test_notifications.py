"""Unit tests for FCM notification service and event trigger integration.

Tests cover:
- send_push behavior: multi-token delivery, invalid token cleanup, error tolerance
- Event helpers: correct title/body/data payload construction
- Edge cases: no tokens registered, Firebase not initialized (graceful no-op)

Mock strategy: patch firebase_admin.messaging.send directly (not asyncio.to_thread)
since patching asyncio.to_thread breaks the event loop's await machinery.
"""

from __future__ import annotations

import uuid
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from src.features.notifications.schemas import NotificationEvent


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_fcm_token(token_str: str = "fake-token-123", student_id=None):
    """Create a mock FcmToken object."""
    mock = MagicMock()
    mock.id = uuid.uuid4()
    mock.student_id = student_id or uuid.uuid4()
    mock.token = token_str
    mock.device_name = "Test Device"
    return mock


def _mock_db_with_tokens(tokens: list):
    """Create a mock DB session that returns given tokens from select query."""
    db = MagicMock()
    result_mock = MagicMock()
    result_mock.scalars.return_value.all.return_value = tokens
    db.execute = AsyncMock(return_value=result_mock)
    db.commit = AsyncMock()
    return db


# ---------------------------------------------------------------------------
# Test 1: send_push sends message for each registered FCM token
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
@patch("src.features.notifications.services._firebase_initialized", True)
@patch("firebase_admin.messaging.send", return_value="projects/test/messages/123")
async def test_send_push_sends_to_each_token(mock_send):
    """send_push should call messaging.send for each registered token."""
    from src.features.notifications.services import NotificationService

    student_id = uuid.uuid4()
    token1 = _make_fcm_token("token-aaa", student_id)
    token2 = _make_fcm_token("token-bbb", student_id)
    db = _mock_db_with_tokens([token1, token2])

    service = NotificationService()
    await service.send_push(
        db=db,
        student_id=student_id,
        event=NotificationEvent.document_ready,
        title="Test Title",
        body="Test Body",
        data={"key": "value"},
    )

    assert mock_send.call_count == 2


# ---------------------------------------------------------------------------
# Test 2: send_push removes token from DB on UnregisteredError
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
@patch("src.features.notifications.services._firebase_initialized", True)
async def test_send_push_removes_token_on_unregistered_error():
    """send_push should delete token from DB when Firebase returns UnregisteredError."""
    from firebase_admin import messaging
    from src.features.notifications.services import NotificationService

    student_id = uuid.uuid4()
    token1 = _make_fcm_token("invalid-token", student_id)
    db = _mock_db_with_tokens([token1])

    with patch("firebase_admin.messaging.send", side_effect=messaging.UnregisteredError("Token not registered")):
        service = NotificationService()
        await service.send_push(
            db=db,
            student_id=student_id,
            event=NotificationEvent.document_ready,
            title="Test",
            body="Test",
        )

    # Should have called db.execute to delete the token (1 select + 1 delete)
    assert db.execute.call_count == 2
    assert db.commit.call_count == 1


# ---------------------------------------------------------------------------
# Test 3: send_push logs error but continues on generic exception
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
@patch("src.features.notifications.services._firebase_initialized", True)
async def test_send_push_continues_on_generic_error():
    """send_push should catch generic errors and continue to next token."""
    from src.features.notifications.services import NotificationService

    student_id = uuid.uuid4()
    token1 = _make_fcm_token("token-fail", student_id)
    token2 = _make_fcm_token("token-ok", student_id)
    db = _mock_db_with_tokens([token1, token2])

    call_count = {"value": 0}

    def _side_effect(message):
        call_count["value"] += 1
        if call_count["value"] == 1:
            raise RuntimeError("Network timeout")
        return "projects/test/messages/456"

    with patch("firebase_admin.messaging.send", side_effect=_side_effect):
        service = NotificationService()
        # Should NOT raise — fire and forget
        await service.send_push(
            db=db,
            student_id=student_id,
            event=NotificationEvent.document_ready,
            title="Test",
            body="Test",
        )

    # Both tokens were attempted
    assert call_count["value"] == 2


# ---------------------------------------------------------------------------
# Test 4: notify_document_ready builds correct title/body/data
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
@patch("src.features.notifications.services._firebase_initialized", True)
@patch("firebase_admin.messaging.send", return_value="ok")
async def test_notify_document_ready_payload(mock_send):
    """notify_document_ready should build Portuguese title/body and document_id in data."""
    from src.features.notifications.services import NotificationService

    student_id = uuid.uuid4()
    document_id = uuid.uuid4()
    token1 = _make_fcm_token("token-123", student_id)
    db = _mock_db_with_tokens([token1])

    service = NotificationService()
    await service.notify_document_ready(
        db=db,
        student_id=student_id,
        document_type="histórico",
        document_id=document_id,
    )

    # Verify Message was constructed correctly
    call_args = mock_send.call_args
    message = call_args[0][0]

    assert message.notification.title == "Documento pronto"
    assert "histórico" in message.notification.body
    assert message.data["document_id"] == str(document_id)
    assert message.data["event"] == "document_ready"


# ---------------------------------------------------------------------------
# Test 5: notify_enrollment_confirmed builds correct payload
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
@patch("src.features.notifications.services._firebase_initialized", True)
@patch("firebase_admin.messaging.send", return_value="ok")
async def test_notify_enrollment_confirmed_payload(mock_send):
    """notify_enrollment_confirmed should build correct Portuguese content."""
    from src.features.notifications.services import NotificationService

    student_id = uuid.uuid4()
    enrollment_id = uuid.uuid4()
    token1 = _make_fcm_token("token-456", student_id)
    db = _mock_db_with_tokens([token1])

    service = NotificationService()
    await service.notify_enrollment_confirmed(
        db=db,
        student_id=student_id,
        enrollment_id=enrollment_id,
    )

    call_args = mock_send.call_args
    message = call_args[0][0]

    assert message.notification.title == "Matrícula confirmada"
    assert "confirmada" in message.notification.body
    assert message.data["enrollment_id"] == str(enrollment_id)
    assert message.data["event"] == "enrollment_confirmed"


# ---------------------------------------------------------------------------
# Test 6: notify_appointment_confirmed builds correct payload
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
@patch("src.features.notifications.services._firebase_initialized", True)
@patch("firebase_admin.messaging.send", return_value="ok")
async def test_notify_appointment_confirmed_payload(mock_send):
    """notify_appointment_confirmed should build correct Portuguese content."""
    from src.features.notifications.services import NotificationService

    student_id = uuid.uuid4()
    appointment_id = uuid.uuid4()
    token1 = _make_fcm_token("token-789", student_id)
    db = _mock_db_with_tokens([token1])

    service = NotificationService()
    await service.notify_appointment_confirmed(
        db=db,
        student_id=student_id,
        appointment_id=appointment_id,
    )

    call_args = mock_send.call_args
    message = call_args[0][0]

    assert message.notification.title == "Agendamento confirmado"
    assert "confirmado" in message.notification.body
    assert message.data["appointment_id"] == str(appointment_id)
    assert message.data["event"] == "appointment_confirmed"


# ---------------------------------------------------------------------------
# Test 7: send_push does nothing when no tokens exist
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
@patch("src.features.notifications.services._firebase_initialized", True)
@patch("firebase_admin.messaging.send", return_value="ok")
async def test_send_push_no_op_when_no_tokens(mock_send):
    """send_push should return immediately when student has no registered tokens."""
    from src.features.notifications.services import NotificationService

    student_id = uuid.uuid4()
    db = _mock_db_with_tokens([])  # No tokens

    service = NotificationService()
    await service.send_push(
        db=db,
        student_id=student_id,
        event=NotificationEvent.document_ready,
        title="Test",
        body="Test",
    )

    # messaging.send should never be called
    mock_send.assert_not_called()


# ---------------------------------------------------------------------------
# Test 8: send_push is no-op when Firebase is not initialized
# ---------------------------------------------------------------------------

@pytest.mark.asyncio
@patch("src.features.notifications.services._firebase_initialized", False)
async def test_send_push_no_op_when_firebase_not_initialized():
    """send_push should skip entirely when Firebase is not initialized."""
    from src.features.notifications.services import NotificationService

    student_id = uuid.uuid4()
    db = AsyncMock()  # Should never be queried

    service = NotificationService()
    await service.send_push(
        db=db,
        student_id=student_id,
        event=NotificationEvent.document_ready,
        title="Test",
        body="Test",
    )

    # DB should never be touched
    db.execute.assert_not_called()
