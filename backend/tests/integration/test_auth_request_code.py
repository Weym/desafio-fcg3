"""Integration tests for POST /auth/request-code endpoint.

V-01 partial: basic request-code behavior, response shape, DB row creation, email dispatch.
"""

import pytest
from sqlalchemy import select, func

from src.features.auth.models import VerificationCode


@pytest.mark.asyncio
async def test_request_code_returns_200_with_correct_body(client, db_session, mock_resend, seed_users, reset_limiter):
    """POST /auth/request-code for registered email returns 200 with expected body."""
    response = await client.post("/auth/request-code", json={"email": "student@test.edu"})
    assert response.status_code == 200
    body = response.json()
    assert body["message"] == "Codigo enviado"
    assert body["expires_in"] == 300


@pytest.mark.asyncio
async def test_request_code_creates_verification_row(client, db_session, mock_resend, seed_users, reset_limiter):
    """A verification_codes row is created with non-empty code_hash/code_salt and used=False."""
    await client.post("/auth/request-code", json={"email": "student@test.edu"})

    q = await db_session.execute(
        select(VerificationCode).where(VerificationCode.email == "student@test.edu")
    )
    row = q.scalar_one()
    assert row.code_hash and len(row.code_hash) == 64  # SHA-256 hex
    assert row.code_salt and len(row.code_salt) == 32  # hex(16)
    assert row.used is False
    assert row.attempts == 0


@pytest.mark.asyncio
async def test_request_code_does_not_leak_plaintext_in_response(client, db_session, mock_resend, seed_users, reset_limiter):
    """The plaintext code must NOT appear in the response body or headers."""
    response = await client.post("/auth/request-code", json={"email": "student@test.edu"})
    body_text = response.text
    # Get the code from the email mock
    assert mock_resend.call_count == 1
    email_html = mock_resend.call_args[0][0]["html"]
    # Extract code from HTML: <strong>123456</strong>
    import re
    match = re.search(r"<strong>(\d{6})</strong>", email_html)
    assert match, "Code should be in the email HTML"
    plaintext_code = match.group(1)
    assert plaintext_code not in body_text
    # Also check no code in headers
    for header_value in response.headers.values():
        assert plaintext_code not in header_value


@pytest.mark.asyncio
async def test_request_code_calls_resend_for_registered_email(client, db_session, mock_resend, seed_users, reset_limiter):
    """mock_resend should be called exactly once for a registered email."""
    await client.post("/auth/request-code", json={"email": "student@test.edu"})
    assert mock_resend.call_count == 1
    call_params = mock_resend.call_args[0][0]
    assert call_params["to"] == ["student@test.edu"]
    assert "codigo" in call_params["subject"].lower() or "verificacao" in call_params["subject"].lower()


@pytest.mark.asyncio
async def test_request_code_unregistered_returns_200_same_body(client, db_session, mock_resend, seed_users, reset_limiter):
    """D-08: unregistered email also returns 200 with the same body (no enumeration leak)."""
    response = await client.post("/auth/request-code", json={"email": "unknown@test.edu"})
    assert response.status_code == 200
    body = response.json()
    assert body["message"] == "Codigo enviado"
    assert body["expires_in"] == 300
    # But resend should NOT have been called for unregistered email
    assert mock_resend.call_count == 0
