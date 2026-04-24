"""Pagination utilities for FastAPI endpoints.

PaginationParams: FastAPI dependency that extracts page/per_page/sort_by/order from query params.
paginated_response: builds the standard envelope {data: [...], pagination: {page, per_page, total}}.

Format follows docs/api.md:
  ?page=1&per_page=20&sort_by=created_at&order=desc
"""

from __future__ import annotations

from typing import Any, Literal

from fastapi import Query


class PaginationParams:
    """FastAPI dependency for pagination query parameters.

    Usage:
        @router.get("/items")
        async def list_items(params: PaginationParams = Depends()):
            ...
    """

    def __init__(
        self,
        page: int = Query(default=1, ge=1, description="Page number (1-indexed)"),
        per_page: int = Query(default=20, ge=1, le=100, description="Items per page"),
        sort_by: str = Query(default="created_at", description="Column to sort by"),
        order: Literal["asc", "desc"] = Query(default="desc", description="Sort order"),
    ) -> None:
        self.page = page
        self.per_page = per_page
        self.sort_by = sort_by
        self.order = order

    @property
    def offset(self) -> int:
        """Calculate SQL OFFSET from page and per_page."""
        return (self.page - 1) * self.per_page

    @property
    def limit(self) -> int:
        """Alias for per_page — matches SQL LIMIT semantics."""
        return self.per_page


def paginated_response(
    data: list[Any],
    total: int,
    params: PaginationParams,
) -> dict[str, Any]:
    """Build the standard paginated response envelope.

    Returns:
        {
            "data": [...],
            "pagination": {"page": 1, "per_page": 20, "total": 150}
        }
    """
    return {
        "data": data,
        "pagination": {
            "page": params.page,
            "per_page": params.per_page,
            "total": total,
        },
    }
