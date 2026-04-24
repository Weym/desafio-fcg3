import pytest
from sqlalchemy import select
from src.features.auth.services import jwt_service
from src.features.auth.models import Session as SessionModel


async def _login_and_get_tokens(client, seed_users, db_session, role="student"):
    user = seed_users[role]
    pair = jwt_service.issue_token_pair(user.id, role, user.name, user.email)
    db_session.add_all([
        SessionModel(jti=pair.access.jti, user_id=user.id, token_type="access",
                     user_type=role, platform="app",
                     parent_jti=None, used=False, expires_at=pair.access.expires_at),
        SessionModel(jti=pair.refresh.jti, user_id=user.id, token_type="refresh",
                     user_type=role, platform="app",
                     parent_jti=pair.access.jti, used=False, expires_at=pair.refresh.expires_at),
    ])
    await db_session.commit()
    return pair


@pytest.mark.asyncio
async def test_logout_revokes_only_current_jti(client, seed_users, db_session):
    pair = await _login_and_get_tokens(client, seed_users, db_session, "student")
    # Second login creates a second session pair
    pair2 = await _login_and_get_tokens(client, seed_users, db_session, "student")

    r = await client.post("/auth/logout",
                          headers={"Authorization": f"Bearer {pair.access.token}"})
    assert r.status_code == 200

    # Access jti #1 revoked, refresh jti #1 untouched, pair #2 untouched — D-11
    q = await db_session.execute(select(SessionModel).where(
        SessionModel.jti.in_([pair.access.jti, pair.refresh.jti,
                              pair2.access.jti, pair2.refresh.jti])
    ))
    rows = {r.jti: r.used for r in q.scalars()}
    assert rows[pair.access.jti] is True        # revoked
    assert rows[pair.refresh.jti] is False      # untouched (D-11: only current session)
    assert rows[pair2.access.jti] is False      # other session untouched
    assert rows[pair2.refresh.jti] is False


@pytest.mark.asyncio
async def test_logout_then_me_returns_401(client, seed_users, db_session):
    pair = await _login_and_get_tokens(client, seed_users, db_session, "staff")
    r = await client.post("/auth/logout",
                          headers={"Authorization": f"Bearer {pair.access.token}"})
    assert r.status_code == 200
    # Subsequent /auth/me with same token -> 401 token_revoked
    r2 = await client.get("/auth/me",
                          headers={"Authorization": f"Bearer {pair.access.token}"})
    assert r2.status_code == 401
    assert r2.json()["detail"]["error"]["code"] == "token_revoked"


@pytest.mark.asyncio
async def test_logout_without_token_rejected(client):
    r = await client.post("/auth/logout")
    assert r.status_code == 401
