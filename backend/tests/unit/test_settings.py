# Phase 02, Plan 01, Task 3: Settings contract tests
import pytest


def test_settings_all_auth_vars_declared(monkeypatch):
    """Verify all auth-related env vars are exposed on Settings."""
    monkeypatch.setenv("DATABASE_URL", "postgresql+asyncpg://t:t@localhost/t")
    monkeypatch.setenv("JWT_SECRET", "x" * 64)
    monkeypatch.setenv("RESEND_API_KEY", "re_test")
    monkeypatch.setenv("RESEND_FROM", "Test <t@t.test>")
    monkeypatch.setenv("MCP_SERVICE_TOKEN", "y" * 64)
    monkeypatch.setenv("WHATSAPP_TOKEN", "placeholder")
    monkeypatch.setenv("WHATSAPP_PHONE_NUMBER_ID", "123456")
    monkeypatch.setenv("WHATSAPP_WEBHOOK_VERIFY_TOKEN", "verify-token")

    from src.infrastructure.config import Settings

    s = Settings()
    assert s.jwt_algorithm == "HS256"
    assert s.jwt_access_expiry_seconds == 3600
    assert s.jwt_refresh_expiry_seconds == 2592000
    assert s.otp_expiry_seconds == 300
    assert s.otp_max_attempts == 3
    assert s.rate_limit_email == "5/15 minutes"
    assert s.rate_limit_ip == "20/15 minutes"


def test_settings_requires_jwt_secret(monkeypatch):
    """JWT_SECRET is mandatory — Settings must fail without it."""
    monkeypatch.setenv("DATABASE_URL", "postgresql+asyncpg://t:t@localhost/t")
    monkeypatch.delenv("JWT_SECRET", raising=False)
    monkeypatch.setenv("RESEND_API_KEY", "re_test")
    monkeypatch.setenv("MCP_SERVICE_TOKEN", "y" * 64)
    monkeypatch.setenv("WHATSAPP_TOKEN", "placeholder")
    monkeypatch.setenv("WHATSAPP_PHONE_NUMBER_ID", "123456")
    monkeypatch.setenv("WHATSAPP_WEBHOOK_VERIFY_TOKEN", "verify-token")

    from src.infrastructure.config import Settings

    with pytest.raises(Exception):
        Settings()
