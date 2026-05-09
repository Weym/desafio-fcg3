"""Phase 12: DEV_MASTER_OTP bypass unit tests.

Covers:
- GAP-12-03-extra: backend/src/features/auth/services/otp_service.py:110
  (`verify_code_hash`) — when settings.dev_master_otp is set and matches the
  submitted code, the hash check is bypassed and a warning is logged.

These tests use monkeypatch on `otp_service.get_settings` so we can inject a
crafted Settings stub without touching the real environment.

Security invariants exercised:
  1. Bypass succeeds only when submitted code EXACTLY matches dev_master_otp.
  2. Wrong code falls through to the real hash check (does not bypass).
  3. When dev_master_otp is None (production), the bypass branch is inert —
     the hash check is the only auth path.
  4. Every successful bypass emits a WARNING log for audit traceability.
"""
from __future__ import annotations

import logging
from dataclasses import dataclass

import pytest

from src.features.auth.services import otp_service


pytestmark = pytest.mark.unit


@dataclass
class _StubSettings:
    """Minimal Settings stand-in — only the fields verify_code_hash reads."""

    dev_master_otp: str | None


def _patch_settings(monkeypatch: pytest.MonkeyPatch, dev_master_otp: str | None) -> None:
    """Replace otp_service.get_settings with a stub returning our fake.

    The real module calls `get_settings()` inline, so patching the module-level
    attribute is sufficient — no cache invalidation needed.
    """
    stub = _StubSettings(dev_master_otp=dev_master_otp)
    monkeypatch.setattr(otp_service, "get_settings", lambda: stub)


def test_dev_master_otp_bypass_succeeds_when_code_matches_env_var(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Submitted code "000000" matching DEV_MASTER_OTP=000000 bypasses hash check.

    Uses a hash/salt that would NOT validate the submitted code under the
    real SHA-256 path — proving the bypass actually fired.
    """
    _patch_settings(monkeypatch, dev_master_otp="000000")

    # Hash + salt intentionally unrelated to "000000" — only the bypass can
    # return True here.
    stored_salt = "unrelated-salt"
    stored_hash = otp_service._hash_code("999999", stored_salt)

    assert otp_service.verify_code_hash("000000", stored_hash, stored_salt) is True


def test_dev_master_otp_bypass_rejects_wrong_code_falls_through_to_hash_check(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Submitted code "111111" ≠ DEV_MASTER_OTP=000000 → bypass does NOT fire;
    verify_code_hash then runs the real hash comparison (which also fails here)."""
    _patch_settings(monkeypatch, dev_master_otp="000000")

    # Stored hash is for "222222" — neither bypass nor hash check match.
    stored_salt = "some-salt"
    stored_hash = otp_service._hash_code("222222", stored_salt)

    assert otp_service.verify_code_hash("111111", stored_hash, stored_salt) is False


def test_dev_master_otp_bypass_falls_through_when_wrong_code_but_hash_matches(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """When submitted != dev_master_otp, the hash check must still decide.
    Submitted "555555" with a matching hash → True (via hash, not bypass)."""
    _patch_settings(monkeypatch, dev_master_otp="000000")

    stored_salt = "salt-b"
    stored_hash = otp_service._hash_code("555555", stored_salt)

    assert otp_service.verify_code_hash("555555", stored_hash, stored_salt) is True


def test_dev_master_otp_disabled_when_setting_none_enforces_hash_check(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Production profile (dev_master_otp=None): the "000000" bypass must be
    inert — only the stored hash decides. Verifies T-12-01 mitigation."""
    _patch_settings(monkeypatch, dev_master_otp=None)

    # Stored hash is for a different code — submitting "000000" must fail.
    stored_salt = "salt-prod"
    stored_hash = otp_service._hash_code("777777", stored_salt)

    assert otp_service.verify_code_hash("000000", stored_hash, stored_salt) is False


def test_dev_master_otp_disabled_when_empty_string(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Empty string is falsy — the bypass guard (`if settings.dev_master_otp`)
    must not fire for empty/unset values. Defense-in-depth against misconfig."""
    _patch_settings(monkeypatch, dev_master_otp="")

    stored_salt = "salt-x"
    stored_hash = otp_service._hash_code("424242", stored_salt)

    assert otp_service.verify_code_hash("000000", stored_hash, stored_salt) is False


def test_dev_master_otp_bypass_logs_warning_when_used(
    monkeypatch: pytest.MonkeyPatch,
    caplog: pytest.LogCaptureFixture,
) -> None:
    """Each successful bypass must emit a WARNING for audit traceability
    (per otp_service.py:111)."""
    _patch_settings(monkeypatch, dev_master_otp="000000")
    caplog.set_level(logging.WARNING, logger=otp_service.__name__)

    stored_salt = "irrelevant"
    stored_hash = otp_service._hash_code("999999", stored_salt)

    result = otp_service.verify_code_hash("000000", stored_hash, stored_salt)
    assert result is True

    warning_records = [r for r in caplog.records if r.levelno == logging.WARNING]
    assert warning_records, "bypass must emit a WARNING log record"
    assert any(
        "DEV_MASTER_OTP" in rec.getMessage() for rec in warning_records
    ), (
        "WARNING message must mention DEV_MASTER_OTP so audit tooling can "
        f"filter for it. Records: {[r.getMessage() for r in warning_records]}"
    )


def test_dev_master_otp_bypass_does_not_log_when_inactive(
    monkeypatch: pytest.MonkeyPatch,
    caplog: pytest.LogCaptureFixture,
) -> None:
    """The hash-only path must stay silent — no spurious DEV_MASTER_OTP
    warnings when the bypass did not fire (avoids log noise in prod)."""
    _patch_settings(monkeypatch, dev_master_otp=None)
    caplog.set_level(logging.WARNING, logger=otp_service.__name__)

    stored_salt = "salt-c"
    stored_hash = otp_service._hash_code("333333", stored_salt)
    otp_service.verify_code_hash("333333", stored_hash, stored_salt)

    for rec in caplog.records:
        assert "DEV_MASTER_OTP" not in rec.getMessage(), (
            "Hash-only success path must not log DEV_MASTER_OTP bypass"
        )
