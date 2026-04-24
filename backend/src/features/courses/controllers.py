"""Route handlers for the Courses & Curriculum feature slice.

5 endpoints covering all COURSE-* and CURR-* requirements:
- GET /courses — authenticated, paginated with search/semester filters (COURSE-01)
- GET /courses/{id} — authenticated, course detail with prerequisites (COURSE-02)
- GET /courses/{id}/prerequisites — dual-auth (MCP), recursive tree (COURSE-03)
- GET /curriculum/active — dual-auth (MCP), active curriculum by semester (CURR-01)
- GET /curriculum/{id} — authenticated, specific curriculum (CURR-02)
"""

from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from src.infrastructure.database import get_db_session
from src.shared.dependencies import (
    UserContext,
    get_current_user_or_service,
)
from src.shared.pagination import PaginationParams, paginated_response

from src.features.courses.schemas import (
    CourseDetail,
    CourseListItem,
    CurriculumResponse,
    PrerequisiteTreeNode,
)
from src.features.courses.services import course_service


# ---------------------------------------------------------------------------
# Course endpoints
# ---------------------------------------------------------------------------

courses_router = APIRouter(prefix="/courses", tags=["courses"])


# ------------------------------------------------------------------
# COURSE-01: GET /courses — authenticated, paginated list
# ------------------------------------------------------------------

@courses_router.get("", response_model=None)
async def list_courses(
    params: PaginationParams = Depends(),
    search: str | None = Query(default=None, description="Search by name or code (ILIKE)"),
    semester: int | None = Query(default=None, ge=1, description="Filter by semester"),
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> dict:
    """List courses with pagination and optional filters. Any authenticated user."""
    items, total = await course_service.list_courses(
        db, params, search=search, semester=semester,
    )

    data = [CourseListItem.model_validate(item).model_dump() for item in items]
    return paginated_response(data, total, params)


# ------------------------------------------------------------------
# COURSE-02: GET /courses/{id} — authenticated, detail
# ------------------------------------------------------------------

@courses_router.get("/{course_id}", response_model=CourseDetail)
async def get_course_detail(
    course_id: UUID,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> CourseDetail:
    """Get course detail with direct prerequisites. Any authenticated user."""
    return await course_service.get_course_detail(db, course_id)


# ------------------------------------------------------------------
# COURSE-03: GET /courses/{id}/prerequisites — dual-auth (MCP)
# ------------------------------------------------------------------

@courses_router.get(
    "/{course_id}/prerequisites",
    response_model=PrerequisiteTreeNode,
)
async def get_prerequisite_tree(
    course_id: UUID,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> PrerequisiteTreeNode:
    """Full recursive prerequisite tree. Accepts X-Service-Token for MCP."""
    return await course_service.get_prerequisite_tree(db, course_id)


# ---------------------------------------------------------------------------
# Curriculum endpoints
# ---------------------------------------------------------------------------

curriculum_router = APIRouter(prefix="/curriculum", tags=["curriculum"])


# ------------------------------------------------------------------
# CURR-01: GET /curriculum/active — dual-auth (MCP)
# ------------------------------------------------------------------

@curriculum_router.get("/active", response_model=CurriculumResponse)
async def get_active_curriculum(
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> CurriculumResponse:
    """Active curriculum with courses grouped by semester. Accepts X-Service-Token for MCP."""
    return await course_service.get_active_curriculum(db)


# ------------------------------------------------------------------
# CURR-02: GET /curriculum/{id} — authenticated
# ------------------------------------------------------------------

@curriculum_router.get("/{curriculum_id}", response_model=CurriculumResponse)
async def get_curriculum_by_id(
    curriculum_id: UUID,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> CurriculumResponse:
    """Specific curriculum by ID. Any authenticated user."""
    return await course_service.get_curriculum_by_id(db, curriculum_id)
