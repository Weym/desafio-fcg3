"""Route handlers for the Staff Dashboard feature slice.

Endpoints:
- GET /staff/dashboard — staff only, returns KPI aggregation (STAFF-01)
"""

from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from src.infrastructure.database import get_db_session
from src.shared.dependencies import UserContext, get_current_user_or_service, require_staff
from src.features.staff.schemas import DashboardResponse
from src.features.staff.services import dashboard_service


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
