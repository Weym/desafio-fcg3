"""Generic base CRUD service for all feature slices.

BaseService[T] provides reusable async methods: list, get_by_id, get_or_404,
create, update. All methods receive AsyncSession as parameter (session-per-request
pattern — no session stored on self).

Sorting validates sort_by against model columns (T-03-03: prevents SQL injection).
"""

from __future__ import annotations

from typing import Any, Generic, TypeVar
from uuid import UUID

from sqlalchemy import asc, desc, func, inspect, select
from sqlalchemy.ext.asyncio import AsyncSession

from src.shared.exceptions import NotFoundException
from src.shared.pagination import PaginationParams

T = TypeVar("T")


class BaseService(Generic[T]):
    """Generic CRUD service parameterized by SQLAlchemy model class.

    Usage:
        class StudentService(BaseService[Student]):
            def __init__(self):
                super().__init__(Student)
    """

    def __init__(self, model: type[T]) -> None:
        self.model = model

    def _get_valid_columns(self) -> set[str]:
        """Return set of valid column names for the model."""
        mapper = inspect(self.model)
        return {col.key for col in mapper.column_attrs}

    def _get_sort_column(self, sort_by: str) -> Any:
        """Validate sort_by against model columns (T-03-03).

        If sort_by is not a valid column, fall back to 'created_at'.
        If 'created_at' doesn't exist either, use the primary key.
        """
        valid_columns = self._get_valid_columns()

        if sort_by in valid_columns:
            return getattr(self.model, sort_by)

        # Fallback to created_at
        if "created_at" in valid_columns:
            return getattr(self.model, "created_at")

        # Last resort: use primary key
        mapper = inspect(self.model)
        pk_cols = mapper.primary_key
        if pk_cols:
            return pk_cols[0]

        # Should never happen — every model has a PK
        return getattr(self.model, sort_by, None)

    async def list(
        self,
        db: AsyncSession,
        params: PaginationParams,
        filters: dict[str, Any] | None = None,
    ) -> tuple[list[T], int]:
        """List entities with pagination, sorting, and optional filters.

        Args:
            db: Async database session.
            params: Pagination parameters (page, per_page, sort_by, order).
            filters: Optional dict of {column_name: value} equality filters.

        Returns:
            Tuple of (items, total_count).
        """
        query = select(self.model)
        count_query = select(func.count()).select_from(self.model)

        # Apply filters
        if filters:
            valid_columns = self._get_valid_columns()
            for col_name, value in filters.items():
                if col_name in valid_columns and value is not None:
                    column = getattr(self.model, col_name)
                    query = query.where(column == value)
                    count_query = count_query.where(column == value)

        # Get total count
        total_result = await db.execute(count_query)
        total = total_result.scalar_one()

        # Apply sorting
        sort_column = self._get_sort_column(params.sort_by)
        order_func = asc if params.order == "asc" else desc
        query = query.order_by(order_func(sort_column))

        # Apply pagination
        query = query.offset(params.offset).limit(params.limit)

        result = await db.execute(query)
        items = list(result.scalars().all())

        return items, total

    async def get_by_id(self, db: AsyncSession, id: UUID) -> T | None:
        """Get a single entity by primary key, or None if not found."""
        result = await db.execute(
            select(self.model).where(self.model.id == id)
        )
        return result.scalar_one_or_none()

    async def get_or_404(
        self,
        db: AsyncSession,
        id: UUID,
        resource_name: str,
    ) -> T:
        """Get a single entity by primary key, or raise NotFoundException.

        Args:
            db: Async database session.
            id: Primary key UUID.
            resource_name: Resource name for the Portuguese error message
                           (e.g., "student", "enrollment").
        """
        instance = await self.get_by_id(db, id)
        if instance is None:
            raise NotFoundException(resource_name, id)
        return instance

    async def create(self, db: AsyncSession, data: dict[str, Any]) -> T:
        """Create a new entity from a data dict.

        Calls db.flush() to get generated fields (id, created_at), then
        db.refresh() to populate the instance with DB-generated values.
        """
        instance = self.model(**data)
        db.add(instance)
        await db.flush()
        await db.refresh(instance)
        return instance

    async def update(
        self,
        db: AsyncSession,
        instance: T,
        data: dict[str, Any],
    ) -> T:
        """Update entity fields from data dict.

        Sets all provided values, including None. Calls db.flush() +
        db.refresh() to persist changes and reload DB-generated values
        (updated_at).
        """
        for key, value in data.items():
            if hasattr(instance, key):
                setattr(instance, key, value)
        await db.flush()
        await db.refresh(instance)
        return instance
