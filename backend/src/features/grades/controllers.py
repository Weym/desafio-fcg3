"""Route handlers for the Grades feature slice.

PUT /grades/{id} — staff-only grade entry endpoint.

Note: GET /students/{id}/grades and GET /students/{id}/transcript are registered
in students/controllers.py since they live under the /students/{id}/ URL path,
but they delegate business logic to GradeService (GAP-03 resolution).
"""

from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from src.infrastructure.database import get_db_session
from src.shared.dependencies import (
    UserContext,
    get_current_user_or_service,
    require_staff,
)
from src.features.grades.schemas import GradeResponse, GradeUpdate, CourseInfo
from src.features.grades.services import grade_service

router = APIRouter(prefix="/grades", tags=["grades"])


# ------------------------------------------------------------------
# GRADES-04: PUT /grades/{id} — staff only, post/update grades
# ------------------------------------------------------------------

@router.put("/{grade_id}", response_model=GradeResponse)
async def update_grade(
    grade_id: UUID,
    data: GradeUpdate,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> GradeResponse:
    """Post or update grades (N1, N2). Staff only (T-03-20).

    grade_final is auto-calculated server-side from grade_1/grade_2 (T-03-22).
    Status auto-set: approved (>= 5.0) or failed (< 5.0).
    """
    require_staff(user)

    grade = await grade_service.update_grade(db, grade_id, data)
    await db.commit()

    # Eagerly load course for response (may not be loaded from flush/refresh)
    from src.features.courses.models import Course
    from sqlalchemy import select

    course_result = await db.execute(
        select(Course).where(Course.id == grade.course_id)
    )
    course = course_result.scalar_one()

    return GradeResponse(
        id=grade.id,
        course=CourseInfo(code=course.code, name=course.name),
        semester_year=grade.semester_year,
        grade_1=float(grade.grade_1) if grade.grade_1 is not None else None,
        grade_2=float(grade.grade_2) if grade.grade_2 is not None else None,
        grade_final=float(grade.grade_final) if grade.grade_final is not None else None,
        status=grade.status,
    )
