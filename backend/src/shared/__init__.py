"""Shared infrastructure layer — reusable across all feature slices.

Exports pagination, exception handling, response schemas, and auth dependencies
so feature slices can import from `src.shared` directly.
"""

from src.shared.exceptions import (
    AppException,
    ConflictException,
    ForbiddenException,
    NotFoundException,
    ValidationException,
)
from src.shared.base_service import BaseService
from src.shared.dependencies import (
    UserContext,
    check_ownership,
    get_current_user_or_service,
    require_staff,
)
from src.shared.pagination import PaginationParams, paginated_response
from src.shared.responses import ErrorBody, ErrorDetail, ErrorResponse, PaginationMeta

__all__ = [
    "AppException",
    "BaseService",
    "ConflictException",
    "ErrorBody",
    "ErrorDetail",
    "ErrorResponse",
    "ForbiddenException",
    "NotFoundException",
    "PaginationMeta",
    "PaginationParams",
    "UserContext",
    "ValidationException",
    "check_ownership",
    "get_current_user_or_service",
    "paginated_response",
    "require_staff",
]
