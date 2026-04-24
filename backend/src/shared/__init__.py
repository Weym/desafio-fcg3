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
from src.shared.pagination import PaginationParams, paginated_response
from src.shared.responses import ErrorBody, ErrorDetail, ErrorResponse, PaginationMeta

__all__ = [
    "AppException",
    "ConflictException",
    "ErrorBody",
    "ErrorDetail",
    "ErrorResponse",
    "ForbiddenException",
    "NotFoundException",
    "PaginationMeta",
    "PaginationParams",
    "ValidationException",
    "paginated_response",
]
