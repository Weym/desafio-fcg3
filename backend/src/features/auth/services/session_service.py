"""Session row creation for access + refresh tokens; revocation helpers.

D-15: one row per token (access + refresh), same user_id, linked via parent_jti.
D-11: logout sets used=True; get_current_user calls is_active on every request.
"""

from datetime import datetime, timezone
from uuid import UUID

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from src.features.auth.models import Session as SessionModel
from src.features.auth.services.jwt_service import TokenPairResult


async def create_session_pair(
    db: AsyncSession,
    user_id: UUID,
    pair: TokenPairResult,
    *,
    user_type: str = "student",
    platform: str = "app",
) -> None:
    """D-15: one row per token (access + refresh), same user_id, linked via parent_jti."""
    access_row = SessionModel(
        jti=pair.access.jti,
        user_id=user_id,
        user_type=user_type,
        platform=platform,
        token_type="access",
        parent_jti=None,
        used=False,
        expires_at=pair.access.expires_at,
    )
    refresh_row = SessionModel(
        jti=pair.refresh.jti,
        user_id=user_id,
        user_type=user_type,
        platform=platform,
        token_type="refresh",
        parent_jti=pair.access.jti,  # audit link: refresh minted alongside this access
        used=False,
        expires_at=pair.refresh.expires_at,
    )
    db.add_all([access_row, refresh_row])
    await db.flush()


async def is_active(db: AsyncSession, jti: UUID) -> bool:
    """D-11: logout sets used=True; get_current_user calls this on every request."""
    # IMPORTANT: use timezone-aware now() — expires_at columns are tz-aware.
    # datetime.utcnow() (naive) vs tz-aware raises TypeError and is deprecated in Py3.12+.
    q = await db.execute(
        select(SessionModel).where(
            SessionModel.jti == jti,
            SessionModel.used == False,  # noqa: E712  (explicit for clarity)
            SessionModel.expires_at > datetime.now(timezone.utc),
        )
    )
    return q.scalar_one_or_none() is not None


async def revoke(db: AsyncSession, jti: UUID) -> None:
    """D-11: revoke exactly one jti (current session only)."""
    await db.execute(
        update(SessionModel).where(SessionModel.jti == jti).values(used=True)
    )


async def rotate_refresh(
    db: AsyncSession,
    old_refresh_jti: UUID,
    new_pair: TokenPairResult,
    user_id: UUID,
) -> None:
    """D-03: rotate refresh token. Called by POST /auth/refresh.

    P-03 mitigation: SELECT ... FOR UPDATE on the old row. If already used OR missing,
    the caller receives ValueError and must return 401.

    Behavior when called:
    - Lock the old refresh row FOR UPDATE
    - If already used or expired -> raise ValueError('rotation_lost')
    - Mark old refresh row used=True
    - Also mark the sibling access row (linked via parent_jti) used=True — this forces
      callers holding the old access token to re-authenticate via /auth/refresh as well
    - Insert two new rows for the new pair (create_session_pair semantics)
    """
    q = await db.execute(
        select(SessionModel).where(
            SessionModel.jti == old_refresh_jti,
            SessionModel.token_type == "refresh",
        ).with_for_update()
    )
    old = q.scalar_one_or_none()
    # tz-aware comparison — normalize for both tz-aware (PostgreSQL) and naive (SQLite) datetimes
    now_utc = datetime.now(timezone.utc)
    if old is None or old.used:
        raise ValueError("rotation_lost")
    expires_at = old.expires_at if old.expires_at.tzinfo is not None else old.expires_at.replace(tzinfo=timezone.utc)
    if expires_at < now_utc:
        raise ValueError("rotation_lost")
    old.used = True
    # Also invalidate the sibling access token (old.parent_jti points AT the access jti)
    if old.parent_jti is not None:
        sib = await db.execute(
            select(SessionModel).where(
                SessionModel.jti == old.parent_jti,
                SessionModel.token_type == "access",
            )
        )
        sib_row = sib.scalar_one_or_none()
        if sib_row is not None:
            sib_row.used = True
    # Create the new pair
    await create_session_pair(db, user_id, new_pair)
