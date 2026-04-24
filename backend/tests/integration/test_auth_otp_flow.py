"""Integration tests for the full OTP authentication flow.

V-01 full flow + AUTH-03: request-code → verify-code → JWT + sessions.
"""

import re
from datetime import datetime, timedelta, timezone

import pytest
from jose import jwt
from sqlalchemy import select, func

from src.features.auth.models import VerificationCode, Session as SessionModel
from src.infrastructure.config import get_settings


def _extract_code_from_mock(mock_resend) -> str:
    """Extract the 6-digit code from the most recent mock_resend call."""
    call_params = mock_resend.call_args[0][0]
    match = re.search(r"<strong>(\d{6})</strong>", call_params["html"])
    assert match, "Expected 6-digit code in email HTML"
    return match.group(1)


@pytest.mark.asyncio
async def test_happy_path_request_and_verify(client, db_session, mock_resend, seed_users, reset_limiter):
    """request-code → verify-code → 200 → TokenPair with correct claims and session rows."""
    settings = get_settings()
    student = seed_users["student"]

    # 1. Request code
    resp1 = await client.post("/auth/request-code", json={"email": "student@test.edu"})
    assert resp1.status_code == 200

    # 2. Extract code from mock
    code = _extract_code_from_mock(mock_resend)

    # 3. Verify code
    resp2 = await client.post("/auth/verify-code", json={"email": "student@test.edu", "code": code})
    assert resp2.status_code == 200
    body = resp2.json()
    assert body["token_type"] == "bearer"
    assert body["expires_in"] == settings.jwt_access_expiry_seconds
    assert body["access_token"]
    assert body["refresh_token"]

    # 4. Decode access token and check claims
    claims = jwt.decode(body["access_token"], settings.jwt_secret, algorithms=["HS256"])
    assert claims["sub"] == str(student.id)
    assert claims["role"] == "student"
    assert claims["name"] == "Test Student"
    assert claims["email"] == "student@test.edu"
    assert "jti" in claims
    assert claims["exp"] > claims["iat"]

    # 5. Check sessions rows: exactly 2 (access + refresh)
    q = await db_session.execute(
        select(SessionModel).where(SessionModel.user_id == student.id)
    )
    sessions = q.scalars().all()
    assert len(sessions) == 2
    types = {s.token_type for s in sessions}
    assert types == {"access", "refresh"}

    # The access token's jti matches one of the sessions
    access_session = next(s for s in sessions if s.token_type == "access")
    assert str(access_session.jti) == claims["jti"]

    # Refresh session links to access via parent_jti
    refresh_session = next(s for s in sessions if s.token_type == "refresh")
    assert refresh_session.parent_jti == access_session.jti

    # 6. Verification code row should be used
    q2 = await db_session.execute(
        select(VerificationCode).where(
            VerificationCode.email == "student@test.edu",
            VerificationCode.used == True,  # noqa: E712
        )
    )
    used_row = q2.scalar_one_or_none()
    assert used_row is not None


@pytest.mark.asyncio
async def test_wrong_code_three_times_triggers_auto_resend(client, db_session, mock_resend, seed_users, reset_limiter):
    """AUTH-03: After 3 wrong attempts, row is invalidated and a new code is sent."""
    # 1. Request code
    await client.post("/auth/request-code", json={"email": "student@test.edu"})
    assert mock_resend.call_count == 1

    # 2. Submit wrong code 3 times
    for i in range(2):
        resp = await client.post("/auth/verify-code", json={"email": "student@test.edu", "code": "000000"})
        assert resp.status_code == 401
        assert resp.json()["error"]["code"] == "INVALID_CODE"

    # 3rd attempt — triggers MAX_ATTEMPTS_REACHED + auto-resend
    resp3 = await client.post("/auth/verify-code", json={"email": "student@test.edu", "code": "000000"})
    assert resp3.status_code == 401
    assert resp3.json()["error"]["code"] == "MAX_ATTEMPTS_REACHED"
    assert "new code" in resp3.json()["error"]["message"].lower()

    # mock_resend called twice total: once on initial request-code, once on auto-resend
    assert mock_resend.call_count == 2

    # DB should have 2 verification_codes rows for this email
    q = await db_session.execute(
        select(VerificationCode).where(VerificationCode.email == "student@test.edu")
    )
    rows = q.scalars().all()
    assert len(rows) == 2

    # Old row: used=True
    old_row = next(r for r in rows if r.used is True)
    assert old_row.attempts >= 3

    # New row: used=False, attempts=0
    new_row = next(r for r in rows if r.used is False)
    assert new_row.attempts == 0


@pytest.mark.asyncio
async def test_expired_code_returns_invalid_without_incrementing_attempts(client, db_session, mock_resend, seed_users, reset_limiter):
    """Expired codes return 401 INVALID_CODE without incrementing attempts."""
    # 1. Request code
    await client.post("/auth/request-code", json={"email": "student@test.edu"})

    # 2. Expire the code row manually
    q = await db_session.execute(
        select(VerificationCode).where(
            VerificationCode.email == "student@test.edu",
            VerificationCode.used == False,  # noqa: E712
        )
    )
    row = q.scalar_one()
    row.expires_at = datetime.now(timezone.utc) - timedelta(seconds=60)
    await db_session.flush()

    # 3. Try to verify — should fail as expired
    resp = await client.post("/auth/verify-code", json={"email": "student@test.edu", "code": "123456"})
    assert resp.status_code == 401
    assert resp.json()["error"]["code"] == "INVALID_CODE"

    # 4. Refresh and check: attempts should still be 0
    await db_session.refresh(row)
    assert row.attempts == 0


@pytest.mark.asyncio
async def test_staff_login_returns_role_staff(client, db_session, mock_resend, seed_users, reset_limiter):
    """Staff email verification returns a token with role='staff'."""
    settings = get_settings()

    await client.post("/auth/request-code", json={"email": "staff@test.edu"})
    code = _extract_code_from_mock(mock_resend)

    resp = await client.post("/auth/verify-code", json={"email": "staff@test.edu", "code": code})
    assert resp.status_code == 200

    claims = jwt.decode(resp.json()["access_token"], settings.jwt_secret, algorithms=["HS256"])
    assert claims["role"] == "staff"
    assert claims["sub"] == str(seed_users["staff"].id)
