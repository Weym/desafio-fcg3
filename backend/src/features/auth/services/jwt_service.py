"""JWT token issuance (access + refresh pairs), decoding, and validation.

Signing: HS256 via python-jose. Secret + TTLs from settings.
D-05: enriched payload (sub, role, jti, name, email, exp, iat).
D-06: sub = UUID string (never composite).
"""

from datetime import datetime, timedelta, timezone
from dataclasses import dataclass
from uuid import UUID, uuid4

from jose import jwt, JWTError  # noqa: F401

from src.infrastructure.config import get_settings


@dataclass
class IssuedToken:
    token: str
    jti: UUID
    expires_at: datetime


@dataclass
class TokenPairResult:
    access: IssuedToken
    refresh: IssuedToken


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _encode(payload: dict) -> str:
    settings = get_settings()
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def decode(token: str) -> dict:
    """Raises jose.JWTError on invalid signature or expiry. Caller must catch."""
    settings = get_settings()
    return jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])


def issue_access(user_id: UUID, role: str, name: str, email: str, jti: UUID | None = None) -> IssuedToken:
    """D-05: enriched payload. D-06: sub = UUID string."""
    settings = get_settings()
    jti = jti or uuid4()
    now = _now()
    exp = now + timedelta(seconds=settings.jwt_access_expiry_seconds)
    payload = {
        "sub": str(user_id),
        "role": role,
        "jti": str(jti),
        "name": name,
        "email": email,
        "exp": int(exp.timestamp()),
        "iat": int(now.timestamp()),
    }
    return IssuedToken(token=_encode(payload), jti=jti, expires_at=exp)


def issue_refresh(user_id: UUID, role: str, jti: UUID | None = None) -> IssuedToken:
    """Minimal payload for refresh — only what /auth/refresh needs."""
    settings = get_settings()
    jti = jti or uuid4()
    now = _now()
    exp = now + timedelta(seconds=settings.jwt_refresh_expiry_seconds)
    payload = {
        "sub": str(user_id),
        "role": role,
        "jti": str(jti),
        "typ": "refresh",
        "exp": int(exp.timestamp()),
        "iat": int(now.timestamp()),
    }
    return IssuedToken(token=_encode(payload), jti=jti, expires_at=exp)


def issue_token_pair(user_id: UUID, role: str, name: str, email: str) -> TokenPairResult:
    return TokenPairResult(
        access=issue_access(user_id, role, name, email),
        refresh=issue_refresh(user_id, role),
    )
