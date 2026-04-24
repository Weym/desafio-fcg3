"""Integration tests for rate limiting on POST /auth/request-code.

V-04: 5 requests per email per 15 minutes (D-13), 20 per IP per 15 minutes (D-14).
"""

import pytest


@pytest.mark.asyncio
async def test_email_rate_limit_blocks_6th_request(client, db_session, mock_resend, seed_users, reset_limiter):
    """D-13: 5 consecutive POST /auth/request-code for same email -> 6th returns 429."""
    email = "student@test.edu"

    for i in range(5):
        resp = await client.post("/auth/request-code", json={"email": email})
        assert resp.status_code == 200, f"Request {i+1} should succeed"

    # 6th request — should be rate limited
    resp6 = await client.post("/auth/request-code", json={"email": email})
    assert resp6.status_code == 429
    body = resp6.json()
    assert body["error"]["code"] == "MAX_ATTEMPTS_REACHED"


@pytest.mark.asyncio
async def test_ip_rate_limit_blocks_21st_request(client, db_session, mock_resend, seed_users, reset_limiter):
    """D-14: 20 consecutive POST /auth/request-code from same IP but different emails -> 21st returns 429."""
    for i in range(20):
        email = f"user{i}@test.edu"
        resp = await client.post("/auth/request-code", json={"email": email})
        assert resp.status_code == 200, f"Request {i+1} should succeed"

    # 21st request — should be rate limited by IP
    resp21 = await client.post("/auth/request-code", json={"email": "user_overflow@test.edu"})
    assert resp21.status_code == 429
    body = resp21.json()
    assert body["error"]["code"] == "MAX_ATTEMPTS_REACHED"


@pytest.mark.asyncio
async def test_reset_limiter_clears_counters(client, db_session, mock_resend, seed_users, reset_limiter):
    """Verify reset_limiter fixture clears rate limit counters between tests."""
    # This test runs after the above; if reset_limiter didn't clear counters,
    # even the first request would be blocked. Verify it works.
    resp = await client.post("/auth/request-code", json={"email": "student@test.edu"})
    assert resp.status_code == 200
