"""Auth endpoints: POST /auth/request-code and POST /auth/verify-code.

Rate limiting: D-13 (5/email/15min), D-14 (20/IP/15min) via slowapi.
Enumeration protection: D-08 — identical response for registered and unregistered emails.
"""

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.infrastructure.config import get_settings
from src.infrastructure.database import get_db_session
from src.shared.rate_limit import limiter
from src.features.auth.schemas import (
    RequestCodePayload,
    RequestCodeResponse,
    VerifyCodePayload,
    TokenPair,
)
from src.features.auth.models import VerificationCode, Student, Staff
from src.features.auth.services import otp_service, jwt_service, session_service
from src.features.auth.deps import body_parser, email_key_func

router = APIRouter(prefix="/auth", tags=["auth"])

settings = get_settings()


@router.post("/request-code", response_model=RequestCodeResponse, status_code=200)
@limiter.limit(settings.rate_limit_email, key_func=email_key_func)  # D-13: 5/email/15min
@limiter.limit(settings.rate_limit_ip)  # D-14: 20/IP/15min, default IP key
async def request_code(
    request: Request,
    _body: dict = Depends(body_parser),  # caches body for key_func
    db: AsyncSession = Depends(get_db_session),
) -> RequestCodeResponse:
    # Parse the cached body into the schema (validates email format)
    payload = RequestCodePayload.model_validate(_body)
    # D-08: always generate + hash + persist for timing parity; only send if registered
    await otp_service.generate_and_send_code(db, payload.email)
    await db.commit()
    return RequestCodeResponse(message="Codigo enviado", expires_in=settings.otp_expiry_seconds)


@router.post("/verify-code", response_model=TokenPair, status_code=200)
async def verify_code(
    payload: VerifyCodePayload,
    db: AsyncSession = Depends(get_db_session),
) -> TokenPair:
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
        raise HTTPException(401, {"error": {"code": "INVALID_CODE", "message": "Invalid or expired code"}})

    # 2. Expired? (don't count attempt)
    # IMPORTANT: tz-aware comparison — expires_at is tz-aware so now() must be too
    if row.expires_at < datetime.now(timezone.utc):
        raise HTTPException(401, {"error": {"code": "INVALID_CODE", "message": "Invalid or expired code"}})

    # 3. Hash match?
    if not otp_service.verify_code_hash(payload.code, row.code_hash, row.code_salt):
        row.attempts += 1
        if row.attempts >= settings.otp_max_attempts:
            row.used = True
            await db.flush()
            # Auto-resend — AUTH-03
            await otp_service.generate_and_send_code(db, payload.email)
            await db.commit()
            raise HTTPException(
                401,
                {"error": {"code": "MAX_ATTEMPTS_REACHED",
                           "message": "Too many attempts. A new code was sent."}},
            )
        await db.commit()
        raise HTTPException(401, {"error": {"code": "INVALID_CODE", "message": "Invalid or expired code"}})

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
            user, role = staff, "staff"

    if user is None:
        # Should be unreachable if D-07 holds, but be defensive
        await db.commit()
        raise HTTPException(401, {"error": {"code": "INVALID_CODE", "message": "Invalid or expired code"}})

    pair = jwt_service.issue_token_pair(user.id, role, user.name, user.email)
    await session_service.create_session_pair(db, user.id, pair, user_type=role)
    await db.commit()
    return TokenPair(
        access_token=pair.access.token,
        refresh_token=pair.refresh.token,
        token_type="bearer",
        expires_in=settings.jwt_access_expiry_seconds,
    )
