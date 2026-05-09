"""Reusable FastAPI dependencies for authentication and authorization.

Three dependencies for downstream phases:
- get_current_user: JWT validation + jti revocation check (Phases 3-6)
- require_role: role-based access guard (Phases 3-6)
- require_service_token: MCP internal auth via constant-time comparison (Phase 4)

D-11: get_current_user checks jti against sessions on every request.
"""

import hmac
from dataclasses import dataclass
from uuid import UUID

from fastapi import Depends, HTTPException, Header
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError
from sqlalchemy.ext.asyncio import AsyncSession

from src.infrastructure.config import get_settings
from src.infrastructure.database import get_db_session
from src.features.auth.services import jwt_service, session_service

# HTTPBearer with auto_error=False lets us control the 401 response shape.
_bearer = HTTPBearer(auto_error=False)


@dataclass
class CurrentUser:
    id: UUID
    role: str           # 'student' | 'staff'
    email: str
    name: str
    jti: UUID           # token id — used by /auth/logout to revoke exactly this session


def _unauthorized(code: str, message: str) -> HTTPException:
    return HTTPException(
        status_code=401,
        detail={"error": {"code": code, "message": message}},
    )


async def get_current_user(
    creds: HTTPAuthorizationCredentials | None = Depends(_bearer),
    db: AsyncSession = Depends(get_db_session),
) -> CurrentUser:
    """Validate Authorization: Bearer <jwt>.

    - Decodes with HS256 + settings.JWT_SECRET (via jwt_service.decode)
    - Checks jti exists in sessions with used=False AND expires_at > now
    - Returns CurrentUser; otherwise raises 401 with canonical error shape
    - Rejects refresh tokens (typ='refresh') — those only work at /auth/refresh
    """
    if creds is None or creds.scheme.lower() != "bearer" or not creds.credentials:
        raise _unauthorized("missing_token", "Authorization header missing or malformed")

    try:
        claims = jwt_service.decode(creds.credentials)
    except JWTError:
        raise _unauthorized("invalid_token", "Invalid or expired token")

    # Reject refresh tokens on non-refresh routes
    if claims.get("typ") == "refresh":
        raise _unauthorized("invalid_token", "Refresh token cannot be used for authentication")

    try:
        jti = UUID(claims["jti"])
        user_id = UUID(claims["sub"])
    except (KeyError, ValueError):
        raise _unauthorized("invalid_token", "Token payload malformed")

    # D-11: jti revocation check — hits sessions table on every request
    if not await session_service.is_active(db, jti):
        raise _unauthorized("token_revoked", "Session has been revoked or expired")

    return CurrentUser(
        id=user_id,
        role=claims.get("role", ""),
        email=claims.get("email", ""),
        name=claims.get("name", ""),
        jti=jti,
    )


def require_role(role: str):
    """Usage: current_user: CurrentUser = Depends(require_role('staff'))"""

    async def _dep(current_user: CurrentUser = Depends(get_current_user)) -> CurrentUser:
        if current_user.role != role:
            raise HTTPException(
                status_code=403,
                detail={"error": {"code": "forbidden",
                                  "message": f"This endpoint requires role='{role}'"}},
            )
        return current_user

    return _dep


async def require_service_token(
    x_service_token: str | None = Header(default=None, alias="X-Service-Token"),
) -> None:
    """Validate X-Service-Token for MCP -> FastAPI internal calls.

    docs/mcp.md: MCP -> FastAPI internal calls authenticate with X-Service-Token.
    Constant-time comparison via hmac.compare_digest to avoid timing oracle.
    """
    if x_service_token is None:
        raise _unauthorized("missing_service_token", "X-Service-Token header required")

    settings = get_settings()
    expected = settings.mcp_service_token

    # Both sides MUST be bytes for compare_digest — encode defensively
    ok = hmac.compare_digest(
        x_service_token.encode("utf-8"),
        expected.encode("utf-8"),
    )
    if not ok:
        raise _unauthorized("invalid_service_token", "Service token invalid")
