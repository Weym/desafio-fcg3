"""Dual-auth dependency and ownership checker for all feature slices.

get_current_user_or_service: tries JWT Bearer first, then X-Service-Token (D-02).
check_ownership: IDOR protection — enforces resource.student_id == current_user.id (D-05, D-06).
require_staff: blocks non-staff roles.

UserContext is the unified identity object returned by get_current_user_or_service.
"""

from __future__ import annotations

import hmac
from dataclasses import dataclass
from uuid import UUID

from fastapi import Depends, Header, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.features.auth.models import Student
from src.infrastructure.config import get_settings
from src.infrastructure.database import get_db_session
from src.shared.exceptions import ForbiddenException


# HTTPBearer with auto_error=False — we handle missing token ourselves
_bearer = HTTPBearer(auto_error=False)


@dataclass
class UserContext:
    """Unified identity returned by get_current_user_or_service.

    For JWT auth: id=user_id from token sub, role=student|staff.
    For service token auth: id=student_id from X-Student-Id header, role=service.
    """

    id: UUID
    role: str           # "student" | "staff" | "service"
    name: str | None = None
    email: str | None = None


def _unauthorized(code: str, message: str) -> HTTPException:
    return HTTPException(
        status_code=401,
        detail={"error": {"code": code, "message": message}},
    )


async def get_current_user_or_service(
    creds: HTTPAuthorizationCredentials | None = Depends(_bearer),
    x_service_token: str | None = Header(default=None, alias="X-Service-Token"),
    x_student_id: str | None = Header(default=None, alias="X-Student-Id"),
    db: AsyncSession = Depends(get_db_session),
) -> UserContext:
    """Dual-auth dependency (D-02): tries JWT Bearer first, then X-Service-Token.

    1. If Authorization: Bearer {token} present → validate JWT via Phase 2's
       get_current_user logic (decode + jti revocation check).
    2. If no Bearer token but X-Service-Token present → validate against
       settings.MCP_SERVICE_TOKEN using hmac.compare_digest (T-03-01).
       Extract student_id from X-Student-Id header. Return role="service".
    3. If neither → raise 401.
    """
    # -- Path 1: JWT Bearer --
    if creds is not None and creds.scheme.lower() == "bearer" and creds.credentials:
        # Reuse Phase 2 logic — import here to avoid circular deps at module level
        from src.shared.auth import get_current_user as _get_jwt_user
        from src.shared.auth import CurrentUser

        # Build a fake Depends() call — we already have creds and db
        jwt_user: CurrentUser = await _get_jwt_user(creds=creds, db=db)
        return UserContext(
            id=jwt_user.id,
            role=jwt_user.role,
            name=jwt_user.name,
            email=jwt_user.email,
        )

    # -- Path 2: X-Service-Token --
    if x_service_token is not None:
        settings = get_settings()
        expected = settings.mcp_service_token

        # T-03-01: constant-time comparison to avoid timing oracle
        ok = hmac.compare_digest(
            x_service_token.encode("utf-8"),
            expected.encode("utf-8"),
        )
        if not ok:
            raise _unauthorized(
                "SERVICO_NAO_AUTORIZADO",
                "Token de servico invalido",
            )

        # MCP sends X-Student-Id to identify which student the request is for
        if x_student_id is None:
            raise _unauthorized(
                "IDENTIFICACAO_AUSENTE",
                "Header X-Student-Id obrigatorio para chamadas de servico",
            )

        try:
            student_id = UUID(x_student_id)
        except ValueError:
            raise _unauthorized(
                "IDENTIFICACAO_INVALIDA",
                "X-Student-Id deve ser um UUID valido",
            )

        student_result = await db.execute(
            select(Student.id).where(
                Student.id == student_id,
                Student.status == "active",
            )
        )
        if student_result.scalar_one_or_none() is None:
            raise _unauthorized(
                "IDENTIFICACAO_INVALIDA",
                "Aluno da chamada de servico nao existe ou esta inativo",
            )

        return UserContext(
            id=student_id,
            role="service",
            name=None,
            email=None,
        )

    # -- Path 3: No auth provided --
    raise _unauthorized(
        "NAO_AUTENTICADO",
        "Autenticacao obrigatoria. Envie um token JWT ou X-Service-Token.",
    )


def check_ownership(resource_student_id: UUID, user: UserContext) -> None:
    """IDOR protection (D-05, D-06, T-03-02).

    - Staff role → bypass (can access any student's data)
    - Student or service role → resource.student_id must match user.id
    - Defense in depth (D-05): even service token requests go through this check
    """
    if user.role == "staff":
        return

    if resource_student_id != user.id:
        raise ForbiddenException(
            "Voce nao tem permissao para acessar este recurso",
        )


def require_staff(user: UserContext) -> None:
    """Block non-staff roles. For staff-only endpoints (T-03-05).

    Usage:
        @router.get("/admin/thing")
        async def admin_thing(user: UserContext = Depends(get_current_user_or_service)):
            require_staff(user)
    """
    if user.role != "staff":
        raise ForbiddenException(
            "Esta acao requer permissao de staff",
        )
