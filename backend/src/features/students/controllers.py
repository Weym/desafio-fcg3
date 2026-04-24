"""Route handlers for the Students feature slice.

7 endpoints covering all STU-* requirements:
- GET /students — staff only, paginated with search/semester/status filters (STU-01)
- GET /students/{id} — authenticated, IDOR-safe (STU-05)
- POST /students — staff only (STU-02)
- PUT /students/{id} — staff only (STU-03)
- DELETE /students/{id} — staff only, soft delete (STU-04)
- GET /students/{id}/academic-summary — dual-auth, MCP-accessible (STU-06)
- GET /students/{id}/available-courses — dual-auth, MCP-accessible (STU-07)
"""

from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, Query
from fastapi.responses import JSONResponse
from sqlalchemy.ext.asyncio import AsyncSession

from src.infrastructure.database import get_db_session
from src.shared.dependencies import (
    UserContext,
    check_ownership,
    get_current_user_or_service,
    require_staff,
)
from src.shared.pagination import PaginationParams, paginated_response

from src.features.students.schemas import (
    AcademicSummaryResponse,
    AvailableCourseItem,
    StudentCreate,
    StudentDetail,
    StudentListItem,
    StudentUpdate,
)
from src.features.students.services import student_service

router = APIRouter(prefix="/students", tags=["students"])


# ------------------------------------------------------------------
# STU-01: GET /students — staff only, paginated list
# ------------------------------------------------------------------

@router.get("", response_model=None)
async def list_students(
    params: PaginationParams = Depends(),
    search: str | None = Query(default=None, description="Search by name (ILIKE)"),
    semester: int | None = Query(default=None, ge=1, description="Filter by semester"),
    status: str | None = Query(default=None, description="Filter by status"),
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> dict:
    """List students with pagination and optional filters. Staff only (T-03-09)."""
    require_staff(user)

    items, total = await student_service.list_students(
        db, params, search=search, semester=semester, status=status,
    )

    data = [StudentListItem.model_validate(item).model_dump() for item in items]
    return paginated_response(data, total, params)


# ------------------------------------------------------------------
# STU-05: GET /students/{id} — authenticated, IDOR-safe
# ------------------------------------------------------------------

@router.get("/{student_id}", response_model=StudentDetail)
async def get_student(
    student_id: UUID,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> StudentDetail:
    """Get student detail. Students can only view their own data (T-03-06)."""
    # IDOR protection: students can only view own data, staff bypasses
    if user.role != "staff":
        check_ownership(student_id, user)

    student = await student_service.get_student(db, student_id)
    return StudentDetail.model_validate(student)


# ------------------------------------------------------------------
# STU-02: POST /students — staff only
# ------------------------------------------------------------------

@router.post("", response_model=StudentDetail, status_code=201)
async def create_student(
    data: StudentCreate,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> StudentDetail:
    """Create a new student. Staff only (T-03-07)."""
    require_staff(user)

    student = await student_service.create_student(db, data)
    await db.commit()
    return StudentDetail.model_validate(student)


# ------------------------------------------------------------------
# STU-03: PUT /students/{id} — staff only
# ------------------------------------------------------------------

@router.put("/{student_id}", response_model=StudentDetail)
async def update_student(
    student_id: UUID,
    data: StudentUpdate,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> StudentDetail:
    """Update student fields. Staff only (T-03-07)."""
    require_staff(user)

    student = await student_service.update_student(db, student_id, data)
    await db.commit()
    return StudentDetail.model_validate(student)


# ------------------------------------------------------------------
# STU-04: DELETE /students/{id} — staff only, soft delete
# ------------------------------------------------------------------

@router.delete("/{student_id}", status_code=200)
async def delete_student(
    student_id: UUID,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> dict:
    """Soft-delete a student (set status=inactive). Staff only (T-03-07)."""
    require_staff(user)

    await student_service.soft_delete_student(db, student_id)
    await db.commit()
    return {"message": "Aluno desativado com sucesso"}


# ------------------------------------------------------------------
# STU-06: GET /students/{id}/academic-summary — dual-auth (MCP)
# ------------------------------------------------------------------

@router.get(
    "/{student_id}/academic-summary",
    response_model=AcademicSummaryResponse,
)
async def get_academic_summary(
    student_id: UUID,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> AcademicSummaryResponse:
    """Academic summary. Accepts X-Service-Token for MCP (T-03-10)."""
    # IDOR protection — even service token goes through check (D-05)
    if user.role != "staff":
        check_ownership(student_id, user)

    return await student_service.get_academic_summary(db, student_id)


# ------------------------------------------------------------------
# STU-07: GET /students/{id}/available-courses — dual-auth (MCP)
# ------------------------------------------------------------------

@router.get(
    "/{student_id}/available-courses",
    response_model=list[AvailableCourseItem],
)
async def get_available_courses(
    student_id: UUID,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> dict:
    """Available courses with prerequisite filtering. Accepts X-Service-Token (MCP)."""
    # IDOR protection — even service token goes through check (D-05)
    if user.role != "staff":
        check_ownership(student_id, user)

    courses = await student_service.get_available_courses(db, student_id)
    return {"data": [c.model_dump() for c in courses]}
