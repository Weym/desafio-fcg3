import pytest
from src.features.auth.services import jwt_service
from src.features.auth.models import Session as SessionModel


async def _make_token(db_session, user, role):
    tok = jwt_service.issue_access(user.id, role, user.name, user.email)
    db_session.add(SessionModel(jti=tok.jti, user_id=user.id, token_type="access",
                                user_type=role, platform="app",
                                parent_jti=None, used=False, expires_at=tok.expires_at))
    await db_session.commit()
    return tok


@pytest.mark.asyncio
async def test_me_returns_profile_from_token_claims(client, seed_users, db_session):
    student = seed_users["student"]
    tok = await _make_token(db_session, student, "student")
    r = await client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {tok.token}"})
    assert r.status_code == 200
    body = r.json()
    assert body["id"] == str(student.id)
    assert body["email"] == student.email
    assert body["name"] == student.name
    assert body["role"] == "student"


@pytest.mark.asyncio
async def test_me_returns_401_without_auth(client):
    r = await client.get("/api/v1/auth/me")
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "missing_token"


@pytest.mark.asyncio
async def test_me_rejects_refresh_token(client, seed_users, db_session):
    student = seed_users["student"]
    refresh_tok = jwt_service.issue_refresh(student.id, "student")
    db_session.add(SessionModel(jti=refresh_tok.jti, user_id=student.id, token_type="refresh",
                                user_type="student", platform="app",
                                parent_jti=None, used=False, expires_at=refresh_tok.expires_at))
    await db_session.commit()
    r = await client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {refresh_tok.token}"})
    assert r.status_code == 401
    assert r.json()["error"]["code"] == "invalid_token"
