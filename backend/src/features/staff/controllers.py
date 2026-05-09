"""Route handlers for the Staff feature slice.

Endpoints:
- GET /staff/dashboard — staff only, returns KPI aggregation (STAFF-01)
- GET /staff/members — provider only, paginated staff list (ROLE-03)
- GET /staff/members/{staff_id} — provider only, staff detail (ROLE-03)
- POST /staff/members — provider only, create staff (ROLE-07)
- PUT /staff/members/{staff_id} — provider only, update staff (ROLE-03)
- DELETE /staff/members/{staff_id} — provider only, soft-delete (ROLE-03)
"""

from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from src.infrastructure.database import get_db_session
from src.shared.dependencies import (
    UserContext,
    get_current_user_or_service,
    require_provider,
    require_staff,
)
from src.shared.pagination import PaginationParams, paginated_response
from src.features.staff.schemas import (
    DashboardResponse,
    StaffCreate,
    StaffDetail,
    StaffListItem,
    StaffUpdate,
)
from src.features.staff.services import dashboard_service, staff_management_service


staff_router = APIRouter(
    prefix="/staff",
    tags=["staff"],
)


# ------------------------------------------------------------------
# STAFF-01: GET /staff/dashboard — staff only
# ------------------------------------------------------------------

@staff_router.get("/dashboard", response_model=DashboardResponse)
async def get_dashboard(
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> DashboardResponse:
    """Staff dashboard with KPIs aggregated from all feature domains.

    Returns total_students, active_enrollments, pending_documents,
    upcoming_appointments, active_chat_sessions, and enrollment_period
    summary. Staff-only access enforced (T-03-31).
    """
    require_staff(user)

    return await dashboard_service.get_dashboard(db)


# ------------------------------------------------------------------
# ROLE-03: GET /staff/members — provider only, paginated list
# ------------------------------------------------------------------

@staff_router.get("/members", response_model=None)
async def list_staff_members(
    params: PaginationParams = Depends(),
    search: str | None = Query(default=None, description="Search by name or email (ILIKE)"),
    status: str | None = Query(default=None, description="Filter by status (active/inactive)"),
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> dict:
    """List staff members (provider only). Hides provider from results (D-17)."""
    require_provider(user)
    items, total = await staff_management_service.list_staff(db, params, search=search, status=status)
    data = [StaffListItem.model_validate(item).model_dump() for item in items]
    return paginated_response(data, total, params)


# ------------------------------------------------------------------
# ROLE-03: GET /staff/members/{staff_id} — provider only, detail
# ------------------------------------------------------------------

@staff_router.get("/members/{staff_id}", response_model=StaffDetail)
async def get_staff_member(
    staff_id: UUID,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> StaffDetail:
    """Get staff member detail. Provider only."""
    require_provider(user)
    member = await staff_management_service.get_staff_member(db, staff_id)
    return StaffDetail.model_validate(member)


# ------------------------------------------------------------------
# ROLE-07: POST /staff/members — provider only, create
# ------------------------------------------------------------------

@staff_router.post("/members", response_model=StaffDetail, status_code=201)
async def create_staff_member(
    data: StaffCreate,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> StaffDetail:
    """Create a new staff member. Provider only (ROLE-03, ROLE-07)."""
    require_provider(user)
    member = await staff_management_service.create_staff(db, data)
    await db.commit()
    return StaffDetail.model_validate(member)


# ------------------------------------------------------------------
# ROLE-03: PUT /staff/members/{staff_id} — provider only, update
# ------------------------------------------------------------------

@staff_router.put("/members/{staff_id}", response_model=StaffDetail)
async def update_staff_member(
    staff_id: UUID,
    data: StaffUpdate,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> StaffDetail:
    """Update staff member. Provider only. Cannot edit own record (D-21)."""
    require_provider(user)
    member = await staff_management_service.update_staff(db, staff_id, data, current_user_id=user.id)
    await db.commit()
    return StaffDetail.model_validate(member)


# ------------------------------------------------------------------
# ROLE-03: DELETE /staff/members/{staff_id} — provider only, soft-delete
# ------------------------------------------------------------------

@staff_router.delete("/members/{staff_id}", status_code=200)
async def delete_staff_member(
    staff_id: UUID,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> dict:
    """Soft-delete (deactivate) staff member. Provider only. Cannot deactivate self (D-21)."""
    require_provider(user)
    await staff_management_service.soft_delete_staff(db, staff_id, current_user_id=user.id)
    await db.commit()
    return {"message": "Staff desativado com sucesso"}
