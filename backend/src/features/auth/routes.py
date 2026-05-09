"""Auth endpoints: POST /auth/request-code and POST /auth/verify-code.

Rate limiting: D-13 (5/email/15min), D-14 (20/IP/15min) via slowapi.
Enumeration protection: D-08 — identical response for registered and unregistered emails.
"""

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, Request
from fastapi.responses import JSONResponse
from jose import JWTError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.infrastructure.config import get_settings
from src.infrastructure.database import get_db_session
from src.shared.rate_limit import limiter
from src.shared.auth import get_current_user, CurrentUser
from src.features.auth.schemas import (
    MeResponse,
    RefreshPayload,
    RequestCodePayload,
    RequestCodeResponse,
    VerifyCodePayload,
    TokenPair,
)
from src.features.auth.models import VerificationCode, Student, Staff
from src.features.auth.services import otp_service, jwt_service, session_service
from src.features.auth.deps import body_parser, email_key_func

router = APIRouter(prefix="/auth", tags=["auth"])

# Rate-limit strings as defaults — evaluated at import time by @limiter.limit decorators.
# These match the defaults in Settings (config.py). Dynamic overrides via env are applied
# lazily by get_settings() inside each handler, not at decorator evaluation time.
_RATE_LIMIT_EMAIL = "5/15 minutes"   # D-13
_RATE_LIMIT_IP = "20/15 minutes"     # D-14


def _utcnow_comparable(dt: datetime) -> datetime:
    """Ensure a datetime is tz-aware UTC for safe comparisons.

    PostgreSQL returns tz-aware datetimes, SQLite returns naive ones.
    This normalizes both to tz-aware UTC.
    """
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt


def _auth_error(status_code: int, code: str, message: str) -> JSONResponse:
    """Return canonical error shape as JSONResponse (not wrapped in 'detail')."""
    return JSONResponse(
        status_code=status_code,
        content={"error": {"code": code, "message": message}},
    )


@router.post("/request-code", response_model=RequestCodeResponse, status_code=200)
@limiter.limit(_RATE_LIMIT_EMAIL, key_func=email_key_func)  # D-13: 5/email/15min
@limiter.limit(_RATE_LIMIT_IP)  # D-14: 20/IP/15min, default IP key
async def request_code(
    request: Request,
    _body: dict = Depends(body_parser),  # caches body for key_func
    db: AsyncSession = Depends(get_db_session),
) -> RequestCodeResponse:
    settings = get_settings()
    # Parse the cached body into the schema (validates email format)
    payload = RequestCodePayload.model_validate(_body)
    # D-08: always generate + hash + persist for timing parity; only send if registered
    await otp_service.generate_and_send_code(db, payload.email)
    await db.commit()
    return RequestCodeResponse(message="Codigo enviado", expires_in=settings.otp_expiry_seconds)


@router.post(
    "/verify-code",
    response_model=TokenPair,
    status_code=200,
    responses={
        401: {"description": "Invalid or expired code, or max attempts reached"},
    },
)
async def verify_code(
    payload: VerifyCodePayload,
    db: AsyncSession = Depends(get_db_session),
) -> TokenPair | JSONResponse:
    settings = get_settings()
    # AUTH-03: canonical check order from P-05
    # 1. Lock the latest code row for this email
    q = await db.execute(
        select(VerificationCode)
        .where(VerificationCode.email == payload.email, VerificationCode.used == False)  # noqa: E712
        .order_by(VerificationCode.created_at.desc())
        .limit(1)
        .with_for_update()
    )
    row = q.scalar_one_or_none()
    if row is None:
        return _auth_error(401, "INVALID_CODE", "Invalid or expired code")

    # 2. Expired? (don't count attempt)
    # IMPORTANT: tz-aware comparison — _utcnow_comparable handles naive (SQLite) and aware (PostgreSQL)
    if _utcnow_comparable(row.expires_at) < datetime.now(timezone.utc):
        return _auth_error(401, "INVALID_CODE", "Invalid or expired code")

    # 3. Hash match?
    if not otp_service.verify_code_hash(payload.code, row.code_hash, row.code_salt):
        row.attempts += 1
        if row.attempts >= settings.otp_max_attempts:
            row.used = True
            await db.flush()
            # Auto-resend — AUTH-03
            await otp_service.generate_and_send_code(db, payload.email)
            await db.commit()
            return _auth_error(401, "MAX_ATTEMPTS_REACHED", "Too many attempts. A new code was sent.")
        await db.commit()
        return _auth_error(401, "INVALID_CODE", "Invalid or expired code")

    # 4. Match — mark used, find user, issue tokens
    row.used = True

    # D-09: lookup both tables, role from hit
    user = None
    role = None
    qs = await db.execute(select(Student).where(Student.email == payload.email))
    student = qs.scalar_one_or_none()
    if student is not None:
        user, role = student, "student"
    else:
        qst = await db.execute(select(Staff).where(Staff.email == payload.email))
        staff = qst.scalar_one_or_none()
        if staff is not None:
            # D-20: inactive staff cannot log in
            if staff.status == "inactive":
                await db.commit()
                return _auth_error(401, "ACCOUNT_INACTIVE", "Conta desativada")
            # D-03: Provider gets distinct JWT role; other staff.roles map to 'staff'
            jwt_role = "provider" if staff.role == "provider" else "staff"
            user, role = staff, jwt_role

    if user is None:
        # Should be unreachable if D-07 holds, but be defensive
        await db.commit()
        return _auth_error(401, "INVALID_CODE", "Invalid or expired code")

    pair = jwt_service.issue_token_pair(user.id, role, user.name, user.email)
    # D-07: provider uses user_type='staff' in sessions table
    session_user_type = "staff" if role == "provider" else role
    await session_service.create_session_pair(db, user.id, pair, user_type=session_user_type)
    await db.commit()
    return TokenPair(
        access_token=pair.access.token,
        refresh_token=pair.refresh.token,
        token_type="bearer",
        expires_in=settings.jwt_access_expiry_seconds,
    )


@router.post("/logout", status_code=200)
async def logout(
    current_user: CurrentUser = Depends(get_current_user),
    db: AsyncSession = Depends(get_db_session),
) -> dict:
    """D-11: revoke ONLY the current jti. Other active sessions remain valid."""
    await session_service.revoke(db, current_user.jti)
    await db.commit()
    return {"message": "Logged out"}


@router.get("/me", response_model=MeResponse, status_code=200)
async def me(current_user: CurrentUser = Depends(get_current_user)) -> MeResponse:
    """D-05: payload is rich enough that we don't query the DB — token IS the source."""
    return MeResponse(
        id=str(current_user.id),
        email=current_user.email,
        name=current_user.name,
        role=current_user.role,
    )


@router.post(
    "/refresh",
    response_model=TokenPair,
    status_code=200,
    responses={
        401: {"description": "Invalid, expired, or already-used refresh token"},
    },
)
async def refresh(
    payload: RefreshPayload,
    db: AsyncSession = Depends(get_db_session),
) -> TokenPair | JSONResponse:
    """D-02, D-03, D-16: silent renewal with rotation and replay detection."""
    settings = get_settings()
    # 1. Decode + validate signature
    try:
        claims = jwt_service.decode(payload.refresh_token)
    except JWTError:
        return _auth_error(401, "invalid_token", "Invalid or expired refresh token")
    # 2. Only refresh-typed tokens may refresh
    if claims.get("typ") != "refresh":
        return _auth_error(401, "invalid_token", "Not a refresh token")
    # 3. Extract jti, user_id, role
    from uuid import UUID as _UUID
    try:
        old_jti = _UUID(claims["jti"])
        user_id = _UUID(claims["sub"])
    except (KeyError, ValueError):
        return _auth_error(401, "invalid_token", "Payload malformed")
    role = claims.get("role", "")
    # 4. Look up the user (D-09) to rebuild a full enriched access token (D-05)
    user = None
    qs = await db.execute(select(Student).where(Student.id == user_id))
    student = qs.scalar_one_or_none()
    if student is not None:
        user = student
    else:
        qst = await db.execute(select(Staff).where(Staff.id == user_id))
        user = qst.scalar_one_or_none()
    if user is None:
        return _auth_error(401, "invalid_token", "User not found")
    # 5. Issue new pair
    new_pair = jwt_service.issue_token_pair(user_id, role, user.name, user.email)
    # 6. Rotate under SELECT FOR UPDATE (P-03). ValueError -> replay attempt -> 401.
    try:
        await session_service.rotate_refresh(db, old_jti, new_pair, user_id)
    except ValueError:
        await db.rollback()
        return _auth_error(401, "refresh_token_revoked", "Refresh token already used or expired")
    await db.commit()
    return TokenPair(
        access_token=new_pair.access.token,
        refresh_token=new_pair.refresh.token,
        token_type="bearer",
        expires_in=settings.jwt_access_expiry_seconds,
    )
