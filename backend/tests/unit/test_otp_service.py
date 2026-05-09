# Phase 02, Plan 01, Task 6: OTP service unit tests
import pytest
from unittest.mock import AsyncMock, MagicMock

# Import all models so SQLAlchemy relationships can resolve
import src.infrastructure.models  # noqa: F401

from src.features.auth.services import otp_service


def test_generate_code_is_6_digits():
    """Verify _generate_code always produces a 6-digit string."""
    for _ in range(100):
        c = otp_service._generate_code()
        assert len(c) == 6 and c.isdigit()


def test_hash_is_deterministic_per_salt():
    """Same plaintext + salt → same hash; different salt → different hash."""
    h1 = otp_service._hash_code("123456", "salt-a")
    h2 = otp_service._hash_code("123456", "salt-a")
    h3 = otp_service._hash_code("123456", "salt-b")
    assert h1 == h2
    assert h1 != h3
    assert len(h1) == 64  # sha256 hex digest length


def test_verify_code_hash_roundtrip():
    """verify_code_hash returns True for correct code, False for wrong code."""
    salt = "abc"
    h = otp_service._hash_code("999888", salt)
    assert otp_service.verify_code_hash("999888", h, salt) is True
    assert otp_service.verify_code_hash("999887", h, salt) is False


@pytest.mark.asyncio
async def test_generate_and_send_does_not_log_plaintext(caplog, monkeypatch):
    """Plaintext OTP code must never appear in log records."""
    import resend

    caplog.set_level("DEBUG")

    # Create a mock async session
    mock_session = AsyncMock()
    mock_session.add = MagicMock()
    mock_session.flush = AsyncMock()

    # Mock user_exists to return True so email is sent
    monkeypatch.setattr(otp_service, "user_exists", AsyncMock(return_value=True))

    # Mock resend
    monkeypatch.setattr(resend.Emails, "send_async", AsyncMock(return_value={"id": "mock"}))

    gen = await otp_service.generate_and_send_code(mock_session, "student@test.edu")

    # Plaintext must never appear in log records
    for rec in caplog.records:
        assert gen.plaintext not in rec.getMessage()

    # Verify the mock session had a row added (hash, not plaintext)
    assert mock_session.add.called
    added_row = mock_session.add.call_args[0][0]
    assert hasattr(added_row, "code_hash")
    assert len(added_row.code_hash) == 64  # SHA-256 hex
    assert len(added_row.code_salt) == 32  # token_hex(16)
