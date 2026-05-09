"""Integration tests for require_role guard dependency.

Tests: wrong-role (403), right-role (200), missing-header (401),
revoked jti (401), tampered signature (401).
"""

import pytest
from src.features.auth.services import jwt_service
from src.features.auth.models import Session as SessionModel
from tests.integration._role_guard_probe import probe_router


@pytest.fixture
def app_with_probe(app):
    app.include_router(probe_router)
    yield app


@pytest.mark.asyncio
async def test_student_token_rejected_on_staff_route(app_with_probe, client, seed_users, db_session):
    student = seed_users["student"]
    tok = jwt_service.issue_access(student.id, "student", student.name, student.email)
    db_session.add(SessionModel(
        jti=tok.jti, user_id=student.id, token_type="access",
        user_type="student", platform="app",
        parent_jti=None, used=False, expires_at=tok.expires_at,
    ))
    await db_session.commit()
    r = await client.get("/_test/staff-only", headers={"Authorization": f"Bearer {tok.token}"})
    assert r.status_code == 403
    assert r.json()["error"]["code"] == "forbidden"


@pytest.mark.asyncio
async def test_staff_token_allowed_on_staff_route(app_with_probe, client, seed_users, db_session):
    staff = seed_users["staff"]
    tok = jwt_service.issue_access(staff.id, "staff", staff.name, staff.email)
    db_session.add(SessionModel(
        jti=tok.jti, user_id=staff.id, token_type="access",
        user_type="staff", platform="app",
        parent_jti=None, used=False, expires_at=tok.expires_at,
    ))
    await db_session.commit()
    r = await client.get("/_test/staff-only", headers={"Authorization": f"Bearer {tok.token}"})
    assert r.status_code == 200
    assert r.json()["role"] == "staff"


@pytest.mark.asyncio
async def test_student_token_allowed_on_student_route(app_with_probe, client, seed_users, db_session):
    student = seed_users["student"]
    tok = jwt_service.issue_access(student.id, "student", student.name, student.email)
    db_session.add(SessionModel(
        jti=tok.jti, user_id=student.id, token_type="access",
        user_type="student", platform="app",
        parent_jti=None, used=False, expires_at=tok.expires_at,
    ))
    await db_session.commit()
    r = await client.get("/_test/student-only", headers={"Authorization": f"Bearer {tok.token}"})
    assert r.status_code == 200
    assert r.json()["role"] == "student"


@pytest.mark.asyncio
async def test_missing_authorization_header(app_with_probe, client):
    r = await client.get("/_test/staff-only")
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "missing_token"


@pytest.mark.asyncio
async def test_revoked_jti_rejected(app_with_probe, client, seed_users, db_session):
    staff = seed_users["staff"]
    tok = jwt_service.issue_access(staff.id, "staff", staff.name, staff.email)
    # Insert as used=True to simulate revoked session
    db_session.add(SessionModel(
        jti=tok.jti, user_id=staff.id, token_type="access",
        user_type="staff", platform="app",
        parent_jti=None, used=True, expires_at=tok.expires_at,
    ))
    await db_session.commit()
    r = await client.get("/_test/staff-only", headers={"Authorization": f"Bearer {tok.token}"})
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "token_revoked"


@pytest.mark.asyncio
async def test_tampered_signature_rejected(app_with_probe, client):
    bad = "Bearer eyJhbGciOiJIUzI1NiJ9.tampered.signature"
    r = await client.get("/_test/staff-only", headers={"Authorization": bad})
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "invalid_token"


@pytest.mark.asyncio
async def test_refresh_token_rejected_on_authenticated_route(app_with_probe, client, seed_users, db_session):
    """Refresh tokens with typ='refresh' must not be used for API auth."""
    staff = seed_users["staff"]
    tok = jwt_service.issue_refresh(staff.id, "staff")
    db_session.add(SessionModel(
        jti=tok.jti, user_id=staff.id, token_type="refresh",
        user_type="staff", platform="app",
        parent_jti=None, used=False, expires_at=tok.expires_at,
    ))
    await db_session.commit()
    r = await client.get("/_test/staff-only", headers={"Authorization": f"Bearer {tok.token}"})
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "invalid_token"
