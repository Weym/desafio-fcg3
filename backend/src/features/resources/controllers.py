"""Route handlers for the Resources feature slice.

CRUD endpoints for managing resources (rooms, labs, equipment, auditoriums,
study rooms, sports courts).

- GET /resources — list resources (students see only available)
- GET /resources/{id} — get resource detail
- POST /resources — create resource (staff only)
- PUT /resources/{id} — update resource (staff only)
- DELETE /resources/{id} — soft-delete resource (staff only)
"""

from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, Query, Response
from sqlalchemy.ext.asyncio import AsyncSession

from src.infrastructure.database import get_db_session
from src.shared.dependencies import (
    UserContext,
    get_current_user_or_service,
    require_staff,
)
from src.shared.pagination import PaginationParams, paginated_response

from src.features.resources.schemas import (
    ResourceCreate,
    ResourceResponse,
    ResourceUpdate,
)
from src.features.resources.services import resource_service


resources_router = APIRouter(
    prefix="/resources",
    tags=["resources"],
)


# ------------------------------------------------------------------
# GET /resources — list with filters
# ------------------------------------------------------------------

@resources_router.get("", response_model=None)
async def list_resources(
    params: PaginationParams = Depends(),
    resource_type: str | None = Query(default=None, description="Filter by resource type"),
    is_available: bool | None = Query(default=None, description="Filter by availability (staff only)"),
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> dict:
    """List resources with pagination and filters.

    Students are auto-filtered to is_available=True resources.
    Staff can filter by type and availability.
    """
    items, total = await resource_service.list_resources(
        db,
        params,
        resource_type=resource_type,
        is_available=is_available,
        user_role=user.role,
    )

    data = [item.model_dump() for item in items]
    return paginated_response(data, total, params)


# ------------------------------------------------------------------
# GET /resources/{id} — resource detail
# ------------------------------------------------------------------

@resources_router.get("/{resource_id}", response_model=ResourceResponse)
async def get_resource(
    resource_id: UUID,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> ResourceResponse:
    """Get a single resource by ID."""
    return await resource_service.get_resource(db, resource_id)


# ------------------------------------------------------------------
# POST /resources — create (staff only)
# ------------------------------------------------------------------

@resources_router.post("", response_model=ResourceResponse, status_code=201)
async def create_resource(
    data: ResourceCreate,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> ResourceResponse:
    """Create a new resource (staff only)."""
    require_staff(user)

    result = await resource_service.create_resource(db, data)
    await db.commit()
    return result


# ------------------------------------------------------------------
# PUT /resources/{id} — update (staff only)
# ------------------------------------------------------------------

@resources_router.put("/{resource_id}", response_model=ResourceResponse)
async def update_resource(
    resource_id: UUID,
    data: ResourceUpdate,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> ResourceResponse:
    """Update a resource (staff only)."""
    require_staff(user)

    result = await resource_service.update_resource(db, resource_id, data)
    await db.commit()
    return result


# ------------------------------------------------------------------
# DELETE /resources/{id} — soft-delete (staff only)
# ------------------------------------------------------------------

@resources_router.delete("/{resource_id}", status_code=204)
async def delete_resource(
    resource_id: UUID,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> Response:
    """Soft-delete a resource by marking is_deleted=True (staff only)."""
    require_staff(user)

    await resource_service.soft_delete_resource(db, resource_id)
    await db.commit()
    return Response(status_code=204)
