"""Custom HTTP exceptions with Portuguese error codes (D-03).

All exceptions return the standard error envelope:
    {"error": {"code": "SCREAMING_SNAKE_CASE", "message": "...", "details": [...]}}

register_exception_handlers(app) registers FastAPI exception handlers for AppException.
"""

from __future__ import annotations

from typing import Any

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse


class AppException(Exception):
    """Base application exception.

    All business-logic exceptions inherit from this class.
    Carries status_code, error code (Portuguese SCREAMING_SNAKE_CASE),
    human-readable message, and optional details list.
    """

    def __init__(
        self,
        status_code: int,
        code: str,
        message: str,
        details: list[dict[str, Any]] | None = None,
    ) -> None:
        self.status_code = status_code
        self.code = code
        self.message = message
        self.details = details
        super().__init__(message)


# -- Resource name -> Portuguese "not found" code mapping --
_NOT_FOUND_CODES: dict[str, str] = {
    "student": "ALUNO_NAO_ENCONTRADO",
    "enrollment": "MATRICULA_NAO_ENCONTRADA",
    "enrollment_period": "PERIODO_MATRICULA_NAO_ENCONTRADO",
    "course": "DISCIPLINA_NAO_ENCONTRADA",
    "document": "DOCUMENTO_NAO_ENCONTRADO",
    "appointment": "AGENDAMENTO_NAO_ENCONTRADO",
    "slot": "HORARIO_NAO_ENCONTRADO",
    "grade": "NOTA_NAO_ENCONTRADA",
    "session": "SESSAO_NAO_ENCONTRADA",
    "curriculum": "CURRICULO_NAO_ENCONTRADO",
    "resource": "RECURSO_NAO_ENCONTRADO",
}


class NotFoundException(AppException):
    """404 — resource not found.

    T-03-04: returns generic "nao encontrado" — does not leak existence info
    for resources the user doesn't own.
    """

    def __init__(self, resource: str, resource_id: Any = None) -> None:
        code = _NOT_FOUND_CODES.get(
            resource.lower(),
            f"{resource.upper()}_NAO_ENCONTRADO",
        )
        message = f"{resource.replace('_', ' ').capitalize()} nao encontrado"
        if resource_id is not None:
            message = f"{message} (id={resource_id})"
        super().__init__(status_code=404, code=code, message=message)


class ConflictException(AppException):
    """409 — business rule violation (e.g., duplicate enrollment, period closed)."""

    def __init__(self, code: str, message: str) -> None:
        super().__init__(status_code=409, code=code, message=message)


class ForbiddenException(AppException):
    """403 — insufficient permissions."""

    def __init__(self, message: str = "Voce nao tem permissao para esta acao") -> None:
        super().__init__(status_code=403, code="SEM_PERMISSAO", message=message)


class ValidationException(AppException):
    """400 — validation error with details."""

    def __init__(
        self,
        message: str = "Erro de validacao",
        details: list[dict[str, Any]] | None = None,
    ) -> None:
        super().__init__(
            status_code=400,
            code="ERRO_VALIDACAO",
            message=message,
            details=details,
        )


def register_exception_handlers(app: FastAPI) -> None:
    """Register a global exception handler for AppException on the FastAPI app.

    Returns the standard error envelope:
        {"error": {"code": "...", "message": "...", "details": [...]}}
    """

    @app.exception_handler(AppException)
    async def _handle_app_exception(
        request: Request,
        exc: AppException,
    ) -> JSONResponse:
        body: dict[str, Any] = {
            "code": exc.code,
            "message": exc.message,
        }
        if exc.details is not None:
            body["details"] = exc.details
        return JSONResponse(
            status_code=exc.status_code,
            content={"error": body},
        )
