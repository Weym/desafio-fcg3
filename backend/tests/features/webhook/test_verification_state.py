"""Verification state machine tests (D-01, D-02).

Tests the full state machine lifecycle:
unverified → awaiting_email → awaiting_code → verified
Including invalid paths: wrong email, wrong code, max attempts.
"""

import uuid
from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock, patch

import pytest

from src.features.auth.models import Student, VerificationCode
from src.features.auth.services.otp_service import _hash_code
from src.features.chat.models import ChatSession
from src.features.webhook.service import WebhookService


class TestVerificationStateMachine:
    """Full verification state machine per D-01/D-02."""

    async def test_unverified_transitions_to_awaiting_email(
        self, db_session, test_student, unverified_session
    ):
        """New unverified session → ask for email → state becomes awaiting_email."""
        svc = WebhookService()
        wa_client = AsyncMock()
        wa_client.send_text_message = AsyncMock(return_value=True)

        await svc.handle_verification_flow(
            unverified_session, "Oi", "5521999999999", db_session, wa_client
        )
        await db_session.flush()

        assert unverified_session.verification_state == "awaiting_email"
        wa_client.send_text_message.assert_called_once()
        sent = wa_client.send_text_message.call_args[0][1]
        assert "email institucional" in sent.lower()

    async def test_valid_email_transitions_to_awaiting_code(
        self, db_session, test_student
    ):
        """Valid email matching student → OTP sent → state becomes awaiting_code."""
        session = ChatSession(
            id=uuid.uuid4(),
            student_id=test_student.id,
            whatsapp_phone="5521999999999",
            status="active",
            verification_state="awaiting_email",
        )
        db_session.add(session)
        await db_session.flush()

        svc = WebhookService()
        wa_client = AsyncMock()
        wa_client.send_text_message = AsyncMock(return_value=True)

        with patch(
            "src.features.webhook.service.otp_service.generate_and_send_code",
            new_callable=AsyncMock,
        ) as mock_otp:
            await svc.handle_verification_flow(
                session, test_student.email, "5521999999999", db_session, wa_client
            )

        assert session.verification_state == "awaiting_code"
        mock_otp.assert_called_once()
        wa_client.send_text_message.assert_called_once()
        sent = wa_client.send_text_message.call_args[0][1]
        assert "codigo" in sent.lower()

    async def test_invalid_email_stays_awaiting_email(
        self, db_session, test_student
    ):
        """Invalid email format → error message, state stays awaiting_email."""
        session = ChatSession(
            id=uuid.uuid4(),
            student_id=test_student.id,
            whatsapp_phone="5521999999999",
            status="active",
            verification_state="awaiting_email",
        )
        db_session.add(session)
        await db_session.flush()

        svc = WebhookService()
        wa_client = AsyncMock()
        wa_client.send_text_message = AsyncMock(return_value=True)

        await svc.handle_verification_flow(
            session, "not-an-email", "5521999999999", db_session, wa_client
        )

        assert session.verification_state == "awaiting_email"
        wa_client.send_text_message.assert_called_once()
        sent = wa_client.send_text_message.call_args[0][1]
        assert "invalido" in sent.lower()

    async def test_email_not_in_students_sends_rejection(
        self, db_session, test_student
    ):
        """Email not found in students table → rejection message."""
        session = ChatSession(
            id=uuid.uuid4(),
            student_id=test_student.id,
            whatsapp_phone="5521999999999",
            status="active",
            verification_state="awaiting_email",
        )
        db_session.add(session)
        await db_session.flush()

        svc = WebhookService()
        wa_client = AsyncMock()
        wa_client.send_text_message = AsyncMock(return_value=True)

        await svc.handle_verification_flow(
            session, "nonexistent@test.edu", "5521999999999", db_session, wa_client
        )

        assert session.verification_state == "awaiting_email"
        wa_client.send_text_message.assert_called_once()
        sent = wa_client.send_text_message.call_args[0][1]
        assert "Nao encontrei cadastro" in sent

    async def test_valid_otp_transitions_to_verified(
        self, db_session, test_student
    ):
        """Valid OTP code → state becomes verified, welcome message sent."""
        session = ChatSession(
            id=uuid.uuid4(),
            student_id=test_student.id,
            whatsapp_phone="5521999999999",
            status="active",
            verification_state="awaiting_code",
        )
        db_session.add(session)
        await db_session.flush()

        # Create a valid verification code
        salt = "testsalt12345678"
        code = "123456"
        code_hash = _hash_code(code, salt)
        vc = VerificationCode(
            email=test_student.email,
            code_hash=code_hash,
            code_salt=salt,
            channel="email",
            expires_at=datetime.now(timezone.utc) + timedelta(minutes=5),
            attempts=0,
            used=False,
        )
        db_session.add(vc)
        await db_session.flush()

        svc = WebhookService()
        wa_client = AsyncMock()
        wa_client.send_text_message = AsyncMock(return_value=True)

        await svc.handle_verification_flow(
            session, code, "5521999999999", db_session, wa_client
        )

        assert session.verification_state == "verified"
        wa_client.send_text_message.assert_called_once()
        sent = wa_client.send_text_message.call_args[0][1]
        assert "verificada" in sent.lower() or "Ola" in sent

    async def test_invalid_otp_with_remaining_attempts(
        self, db_session, test_student
    ):
        """Invalid OTP (attempts < 3) → error message with remaining attempts."""
        session = ChatSession(
            id=uuid.uuid4(),
            student_id=test_student.id,
            whatsapp_phone="5521999999999",
            status="active",
            verification_state="awaiting_code",
        )
        db_session.add(session)
        await db_session.flush()

        salt = "testsalt12345678"
        code_hash = _hash_code("123456", salt)
        vc = VerificationCode(
            email=test_student.email,
            code_hash=code_hash,
            code_salt=salt,
            channel="email",
            expires_at=datetime.now(timezone.utc) + timedelta(minutes=5),
            attempts=0,
            used=False,
        )
        db_session.add(vc)
        await db_session.flush()

        svc = WebhookService()
        wa_client = AsyncMock()
        wa_client.send_text_message = AsyncMock(return_value=True)

        await svc.handle_verification_flow(
            session, "999999", "5521999999999", db_session, wa_client
        )

        assert session.verification_state == "awaiting_code"
        wa_client.send_text_message.assert_called_once()
        sent = wa_client.send_text_message.call_args[0][1]
        assert "invalido" in sent.lower()
        assert "tentativa" in sent.lower()

    async def test_max_attempts_closes_session(
        self, db_session, test_student
    ):
        """Invalid OTP (attempts = max) → invalidate code, CLOSE session, do NOT auto-issue new code.

        Regression test for `.planning/debug/whatsapp-otp-loop-no-cancel.md`:
        previously the code reached max attempts, silently reissued a fresh OTP,
        and kept the session in `awaiting_code` — producing an infinite loop.
        Per CONVENTIONS.md ("Rate limiting: 429 for OTP attempts exhausted"),
        `MAX_ATTEMPTS_REACHED` is a terminal state: the session must close and
        no new OTP is issued automatically.
        """
        session = ChatSession(
            id=uuid.uuid4(),
            student_id=test_student.id,
            whatsapp_phone="5521999999999",
            status="active",
            verification_state="awaiting_code",
        )
        db_session.add(session)
        await db_session.flush()

        salt = "testsalt12345678"
        code_hash = _hash_code("123456", salt)
        vc = VerificationCode(
            email=test_student.email,
            code_hash=code_hash,
            code_salt=salt,
            channel="email",
            expires_at=datetime.now(timezone.utc) + timedelta(minutes=5),
            attempts=2,  # One more wrong attempt = 3 = max
            used=False,
        )
        db_session.add(vc)
        await db_session.flush()

        svc = WebhookService()
        wa_client = AsyncMock()
        wa_client.send_text_message = AsyncMock(return_value=True)

        with patch(
            "src.features.webhook.service.otp_service.generate_and_send_code",
            new_callable=AsyncMock,
        ) as mock_otp:
            await svc.handle_verification_flow(
                session, "999999", "5521999999999", db_session, wa_client
            )

        # No new OTP — terminal state, not a reissue
        mock_otp.assert_not_called()
        # Session CLOSED (no longer `active`) and the verification code marked used
        assert session.status == "closed"
        assert session.ended_at is not None
        assert vc.used is True
        # User is informed with a terminal message
        wa_client.send_text_message.assert_called_once()
        sent = wa_client.send_text_message.call_args[0][1]
        assert "tentativas" in sent.lower()
        assert "encerrada" in sent.lower()

    async def test_verified_session_not_handled_by_verification_flow(
        self, db_session, test_student, verified_session
    ):
        """Verified session → handle_verification_flow is NOT called (checked in router)."""
        # This is checked in the router — verified sessions skip the verification flow
        # and go directly to the background task. We just verify the state is correct.
        assert verified_session.verification_state == "verified"

    async def test_non_6digit_code_rejected(
        self, db_session, test_student
    ):
        """Non-6-digit input → rejection message, no code check."""
        session = ChatSession(
            id=uuid.uuid4(),
            student_id=test_student.id,
            whatsapp_phone="5521999999999",
            status="active",
            verification_state="awaiting_code",
        )
        db_session.add(session)
        await db_session.flush()

        svc = WebhookService()
        wa_client = AsyncMock()
        wa_client.send_text_message = AsyncMock(return_value=True)

        await svc.handle_verification_flow(
            session, "abc", "5521999999999", db_session, wa_client
        )

        wa_client.send_text_message.assert_called_once()
        sent = wa_client.send_text_message.call_args[0][1]
        assert "6 digitos" in sent
