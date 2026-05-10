"""Business logic for the Resources feature slice.

ResourceService: CRUD operations on resources with role-based filtering.
Students only see is_available=True resources; staff see all.
"""

from __future__ import annotations

from uuid import UUID

from sqlalchemy import and_, select, func
from sqlalchemy.ext.asyncio import AsyncSession

from src.features.scheduling.models import Resource
from src.features.resources.schemas import (
    ResourceCreate,
    ResourceResponse,
    ResourceUpdate,
)
from src.shared.exceptions import NotFoundException, ValidationException
from src.shared.pagination import PaginationParams


class ResourceService:
    """Service layer for resource CRUD operations."""

    async def list_resources(
        self,
        db: AsyncSession,
        params: PaginationParams,
        resource_type: str | None = None,
        is_available: bool | None = None,
        user_role: str = "student",
    ) -> tuple[list[ResourceResponse], int]:
        """List resources with filters and pagination.

        Students are auto-filtered to is_available=True only.
        Staff can see all resources regardless of availability.
        """
        query = select(Resource).where(Resource.is_deleted.is_(False))
        count_query = select(func.count()).select_from(Resource).where(Resource.is_deleted.is_(False))

        # Students always see only available resources
        if user_role != "staff":
            query = query.where(Resource.is_available.is_(True))
            count_query = count_query.where(Resource.is_available.is_(True))
        elif is_available is not None:
            query = query.where(Resource.is_available.is_(is_available))
            count_query = count_query.where(Resource.is_available.is_(is_available))

        # Filter by type
        if resource_type is not None:
            query = query.where(Resource.resource_type == resource_type)
            count_query = count_query.where(Resource.resource_type == resource_type)

        # Get total count
        total_result = await db.execute(count_query)
        total = total_result.scalar_one()

        # Apply sorting and pagination
        query = query.order_by(Resource.created_at.desc())
        query = query.offset(params.offset).limit(params.limit)

        result = await db.execute(query)
        resources = list(result.scalars().all())

        items = [ResourceResponse.model_validate(r) for r in resources]
        return items, total

    async def get_resource(
        self,
        db: AsyncSession,
        resource_id: UUID,
    ) -> ResourceResponse:
        """Get a single resource by ID."""
        result = await db.execute(
            select(Resource).where(Resource.id == resource_id)
        )
        resource = result.scalar_one_or_none()

        if resource is None:
            raise NotFoundException("resource", resource_id)

        return ResourceResponse.model_validate(resource)

    async def create_resource(
        self,
        db: AsyncSession,
        data: ResourceCreate,
    ) -> ResourceResponse:
        """Create a new resource (staff only)."""
        resource = Resource(
            name=data.name,
            resource_type=data.resource_type,
            description=data.description,
            capacity=data.capacity,
            location=data.location,
            is_available=data.is_available,
            requires_authorization=data.requires_authorization,
        )
        db.add(resource)
        await db.flush()
        await db.refresh(resource)

        return ResourceResponse.model_validate(resource)

    async def update_resource(
        self,
        db: AsyncSession,
        resource_id: UUID,
        data: ResourceUpdate,
    ) -> ResourceResponse:
        """Update an existing resource (staff only)."""
        result = await db.execute(
            select(Resource).where(Resource.id == resource_id)
        )
        resource = result.scalar_one_or_none()

        if resource is None:
            raise NotFoundException("resource", resource_id)

        # Apply only provided fields
        update_data = data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(resource, field, value)

        await db.flush()
        await db.refresh(resource)

        return ResourceResponse.model_validate(resource)

    async def soft_delete_resource(
        self,
        db: AsyncSession,
        resource_id: UUID,
    ) -> None:
        """Soft-delete a resource by setting is_deleted=True (staff only).

        Distinct from toggling is_available — deleted resources are permanently hidden.
        """
        result = await db.execute(
            select(Resource).where(Resource.id == resource_id)
        )
        resource = result.scalar_one_or_none()

        if resource is None:
            raise NotFoundException("resource", resource_id)

        resource.is_deleted = True
        await db.flush()


# Module-level singleton
resource_service = ResourceService()
