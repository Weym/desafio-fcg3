"""Standard response schemas matching docs/api.md format.

Used as OpenAPI response_model for consistent documentation:
  - ErrorResponse: {"error": {"code": "...", "message": "...", "details": [...]}}
  - PaginationMeta: {"page": 1, "per_page": 20, "total": 150}
"""

from __future__ import annotations

from pydantic import BaseModel


class ErrorDetail(BaseModel):
    """Single field-level error detail."""

    field: str
    message: str


class ErrorBody(BaseModel):
    """Error body inside the standard envelope."""

    code: str
    message: str
    details: list[ErrorDetail] | None = None


class ErrorResponse(BaseModel):
    """Standard error response envelope: {"error": {...}}."""

    error: ErrorBody


class PaginationMeta(BaseModel):
    """Pagination metadata returned alongside paginated data."""

    page: int
    per_page: int
    total: int
