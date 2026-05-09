"""Route handlers for the Enrollment feature slice.

10 endpoints covering all ENROLL-* requirements:

Student-facing:
- GET /enrollment-periods/current — dual-auth (MCP), active period or null (ENROLL-01)
- POST /enrollments — dual-auth (MCP), create draft enrollment (ENROLL-02)
- POST /enrollments/{id}/confirm — dual-auth (MCP), confirm enrollment (ENROLL-03)
- PUT /enrollments/{id} — student only, modify courses (ENROLL-04)
- DELETE /enrollments/{id}/courses/{course_id} — dual-auth (MCP), drop course (ENROLL-05)
- POST /enrollments/{id}/lock — dual-auth (MCP), lock enrollment (ENROLL-06)
- GET /enrollments — dual-auth, list with filters (ENROLL-07)

Staff:
- GET /staff/enrollment-periods — staff only, list all periods (ENROLL-STAFF-03)
- POST /staff/enrollment-periods — staff only, create period (ENROLL-STAFF-01)
- PUT /staff/enrollment-periods/{id} — staff only, update period (ENROLL-STAFF-02)
"""

from __future__ import annotations

import asyncio
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from src.infrastructure.database import get_db_session
from src.features.notifications.services import notification_service
from src.shared.dependencies import (
    UserContext,
    check_ownership,
    get_current_user_or_service,
    require_staff,
)
from src.shared.pagination import PaginationParams, paginated_response

from src.features.enrollment.schemas import (
    EnrollmentCreate,
    EnrollmentPeriodCreate,
    EnrollmentPeriodResponse,
    EnrollmentPeriodUpdate,
    EnrollmentResponse,
    EnrollmentUpdate,
)
from src.features.enrollment.services import (
    enrollment_period_service,
    enrollment_service,
)


# ---------------------------------------------------------------------------
# Enrollment period endpoints (student-facing)
# ---------------------------------------------------------------------------

enrollment_periods_router = APIRouter(
    prefix="/enrollment-periods",
    tags=["enrollment-periods"],
)


# ------------------------------------------------------------------
# ENROLL-01: GET /enrollment-periods/current — MCP-accessible
# ------------------------------------------------------------------

@enrollment_periods_router.get("/current", response_model=None)
async def get_current_enrollment_period(
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> dict:
    """Return the current active enrollment period, or null if none active.

    Accepts X-Service-Token for MCP access.
    Returns {"data": period_object} or {"data": null}.
    """
    period = await enrollment_period_service.get_current_period(db)

    if period is None:
        return {"data": None}

    return {"data": EnrollmentPeriodResponse.model_validate(period).model_dump()}


# ---------------------------------------------------------------------------
# Enrollment endpoints (student-facing)
# ---------------------------------------------------------------------------

enrollments_router = APIRouter(
    prefix="/enrollments",
    tags=["enrollments"],
)


# ------------------------------------------------------------------
# ENROLL-02: POST /enrollments — MCP-accessible
# ------------------------------------------------------------------

@enrollments_router.post("", response_model=EnrollmentResponse, status_code=201)
async def create_enrollment(
    data: EnrollmentCreate,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> EnrollmentResponse:
    """Create draft enrollment with courses.

    Student creates enrollment using their own ID.
    Validates period, prereqs, duplicates (ENROLL-02, ENROLL-08).
    Accepts X-Service-Token for MCP access.
    """
    result = await enrollment_service.create_enrollment(
        db, student_id=user.id, data=data,
    )
    await db.commit()
    return result


# ------------------------------------------------------------------
# ENROLL-03: POST /enrollments/{id}/confirm — MCP-accessible
# ------------------------------------------------------------------

@enrollments_router.post(
    "/{enrollment_id}/confirm",
    response_model=EnrollmentResponse,
)
async def confirm_enrollment(
    enrollment_id: UUID,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> EnrollmentResponse:
    """Confirm enrollment (draft -> confirmed).

    Creates grade records for each enrolled course.
    Accepts X-Service-Token for MCP access.
    """
    result = await enrollment_service.confirm_enrollment(
        db, enrollment_id=enrollment_id, student_id=user.id,
    )
    await db.commit()

    # FCM: Notify student that enrollment was confirmed
    student_id_for_notification = user.id
    enrollment_id_for_notification = enrollment_id

    async def _send_notification():
        async for fresh_db in get_db_session():
            try:
                await notification_service.notify_enrollment_confirmed(
                    fresh_db, student_id_for_notification, enrollment_id_for_notification
                )
            except Exception as exc:
                import logging
                logging.getLogger(__name__).error(
                    "FCM notification failed in background task: %s", exc
                )

    asyncio.create_task(_send_notification())

    return result


# ------------------------------------------------------------------
# ENROLL-04: PUT /enrollments/{id} — student only
# ------------------------------------------------------------------

@enrollments_router.put(
    "/{enrollment_id}",
    response_model=EnrollmentResponse,
)
async def update_enrollment(
    enrollment_id: UUID,
    data: EnrollmentUpdate,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> EnrollmentResponse:
    """Modify courses in a draft enrollment (ENROLL-04).

    Only available for student's own enrollments while in draft status.
    """
    result = await enrollment_service.update_enrollment_courses(
        db,
        enrollment_id=enrollment_id,
        student_id=user.id,
        course_ids=data.course_ids,
    )
    await db.commit()
    return result


# ------------------------------------------------------------------
# ENROLL-05: DELETE /enrollments/{id}/courses/{course_id} — MCP-accessible
# ------------------------------------------------------------------

@enrollments_router.delete(
    "/{enrollment_id}/courses/{course_id}",
    response_model=EnrollmentResponse,
)
async def drop_course(
    enrollment_id: UUID,
    course_id: UUID,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> EnrollmentResponse:
    """Drop a course from enrollment. D-12: only in draft status.

    After confirmation, student must use lock (trancamento) instead.
    Accepts X-Service-Token for MCP access.
    """
    result = await enrollment_service.drop_course(
        db,
        enrollment_id=enrollment_id,
        course_id=course_id,
        student_id=user.id,
    )
    await db.commit()
    return result


# ------------------------------------------------------------------
# ENROLL-06: POST /enrollments/{id}/lock — MCP-accessible
# ------------------------------------------------------------------

@enrollments_router.post(
    "/{enrollment_id}/lock",
    response_model=EnrollmentResponse,
)
async def lock_enrollment(
    enrollment_id: UUID,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> EnrollmentResponse:
    """Lock entire enrollment and all courses — irreversible (D-11).

    Can lock from draft or confirmed status.
    Accepts X-Service-Token for MCP access.
    """
    result = await enrollment_service.lock_enrollment(
        db, enrollment_id=enrollment_id, student_id=user.id,
    )
    await db.commit()
    return result


# ------------------------------------------------------------------
# ENROLL-07: GET /enrollments — dual-auth
# ------------------------------------------------------------------

@enrollments_router.get("", response_model=None)
async def list_enrollments(
    params: PaginationParams = Depends(),
    student_id: UUID | None = Query(default=None, description="Filter by student ID"),
    semester_year: str | None = Query(default=None, description="Filter by semester year"),
    status: str | None = Query(default=None, description="Filter by status"),
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> dict:
    """List enrollments with pagination and filters (ENROLL-07).

    Students are auto-filtered to their own enrollments (IDOR-safe).
    Staff can view all or filter by student_id.
    """
    # IDOR-safe: force student to see only their own enrollments
    effective_student_id = student_id
    if user.role != "staff":
        effective_student_id = user.id

    items, total = await enrollment_service.list_enrollments(
        db,
        params,
        student_id=effective_student_id,
        semester_year=semester_year,
        status=status,
    )

    data = [item.model_dump() for item in items]
    return paginated_response(data, total, params)


# ---------------------------------------------------------------------------
# Staff enrollment period endpoints
# ---------------------------------------------------------------------------

staff_enrollment_router = APIRouter(
    prefix="/staff/enrollment-periods",
    tags=["staff"],
)


# ------------------------------------------------------------------
# ENROLL-STAFF-03: GET /staff/enrollment-periods — staff only
# ------------------------------------------------------------------

@staff_enrollment_router.get("", response_model=None)
async def list_enrollment_periods(
    params: PaginationParams = Depends(),
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> dict:
    """List all enrollment periods. Staff only (ENROLL-STAFF-03)."""
    require_staff(user)

    items, total = await enrollment_period_service.list_periods(db, params)

    data = [
        EnrollmentPeriodResponse.model_validate(item).model_dump()
        for item in items
    ]
    return paginated_response(data, total, params)


# ------------------------------------------------------------------
# ENROLL-STAFF-01: POST /staff/enrollment-periods — staff only
# ------------------------------------------------------------------

@staff_enrollment_router.post(
    "",
    response_model=EnrollmentPeriodResponse,
    status_code=201,
)
async def create_enrollment_period(
    data: EnrollmentPeriodCreate,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> EnrollmentPeriodResponse:
    """Create enrollment period. Staff only (ENROLL-STAFF-01). Returns 201."""
    require_staff(user)

    period = await enrollment_period_service.create_period(db, data)
    await db.commit()
    return EnrollmentPeriodResponse.model_validate(period)


# ------------------------------------------------------------------
# ENROLL-STAFF-02: PUT /staff/enrollment-periods/{id} — staff only
# ------------------------------------------------------------------

@staff_enrollment_router.put(
    "/{period_id}",
    response_model=EnrollmentPeriodResponse,
)
async def update_enrollment_period(
    period_id: UUID,
    data: EnrollmentPeriodUpdate,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> EnrollmentPeriodResponse:
    """Update enrollment period. Staff only (ENROLL-STAFF-02)."""
    require_staff(user)

    period = await enrollment_period_service.update_period(db, period_id, data)
    await db.commit()
    return EnrollmentPeriodResponse.model_validate(period)
