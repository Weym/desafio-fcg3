"""Business logic for the Courses & Curriculum feature slice.

CourseService extends BaseService[Course] and provides:
- list_courses: paginated with search/semester filters (COURSE-01)
- get_course_detail: detail with direct prerequisites (COURSE-02)
- get_prerequisite_tree: recursive CTE for full tree (COURSE-03)
- get_active_curriculum: active curriculum grouped by semester (CURR-01)
- get_curriculum_by_id: specific curriculum by ID (CURR-02)
"""

from __future__ import annotations

from collections import defaultdict
from typing import Any
from uuid import UUID

from sqlalchemy import and_, func, select, text
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.features.courses.models import (
    Course,
    Curriculum,
    CurriculumCourse,
    Prerequisite,
)
from src.features.courses.schemas import (
    CourseDetail,
    CurriculumCourseItem,
    CurriculumResponse,
    PrerequisiteItem,
    PrerequisiteTreeNode,
    SemesterGroup,
)
from src.shared.base_service import BaseService
from src.shared.exceptions import NotFoundException
from src.shared.pagination import PaginationParams


class CourseService(BaseService[Course]):
    """Service layer for all COURSE-* requirements."""

    def __init__(self) -> None:
        super().__init__(Course)

    # ------------------------------------------------------------------
    # COURSE-01: List courses with search and semester filters
    # ------------------------------------------------------------------

    async def list_courses(
        self,
        db: AsyncSession,
        params: PaginationParams,
        search: str | None = None,
        semester: int | None = None,
    ) -> tuple[list[Course], int]:
        """List courses with pagination and optional filters.

        search: ILIKE on name AND code columns.
        semester: filters via curriculum_courses join (returns courses
                  assigned to the given semester in any active curriculum).
        """
        from sqlalchemy import asc, desc, or_

        query = select(Course)
        count_query = select(func.count()).select_from(Course)

        # Search filter — ILIKE on name OR code (T-03-12: parameterized)
        if search:
            search_pattern = f"%{search}%"
            search_filter = or_(
                Course.name.ilike(search_pattern),
                Course.code.ilike(search_pattern),
            )
            query = query.where(search_filter)
            count_query = count_query.where(search_filter)

        # Semester filter — join curriculum_courses to filter by semester
        if semester is not None:
            query = (
                query
                .join(CurriculumCourse, CurriculumCourse.course_id == Course.id)
                .where(CurriculumCourse.semester == semester)
                .distinct()
            )
            count_query = (
                select(func.count(func.distinct(Course.id)))
                .select_from(Course)
                .join(CurriculumCourse, CurriculumCourse.course_id == Course.id)
                .where(CurriculumCourse.semester == semester)
            )

        # Total count
        total_result = await db.execute(count_query)
        total = total_result.scalar_one()

        # Sorting (validated by BaseService)
        sort_column = self._get_sort_column(params.sort_by)
        order_func = asc if params.order == "asc" else desc
        query = query.order_by(order_func(sort_column))

        # Pagination
        query = query.offset(params.offset).limit(params.limit)

        result = await db.execute(query)
        items = list(result.scalars().all())

        return items, total

    # ------------------------------------------------------------------
    # COURSE-02: Course detail with direct prerequisites
    # ------------------------------------------------------------------

    async def get_course_detail(
        self,
        db: AsyncSession,
        course_id: UUID,
    ) -> CourseDetail:
        """Get course by ID with direct prerequisites.

        Single query with eagerly loaded prerequisites relationship.
        """
        result = await db.execute(
            select(Course)
            .options(selectinload(Course.prerequisites).selectinload(Prerequisite.prerequisite))
            .where(Course.id == course_id)
        )
        course = result.scalar_one_or_none()

        if course is None:
            raise NotFoundException("course", course_id)

        # Build direct prerequisites list
        prereqs = [
            PrerequisiteItem(
                id=p.prerequisite.id,
                code=p.prerequisite.code,
                name=p.prerequisite.name,
            )
            for p in course.prerequisites
        ]

        return CourseDetail(
            id=course.id,
            code=course.code,
            name=course.name,
            credits=course.credits,
            workload_hours=course.workload_hours,
            description=course.description,
            prerequisites=prereqs,
        )

    # ------------------------------------------------------------------
    # COURSE-03: Recursive prerequisite tree via CTE
    # ------------------------------------------------------------------

    async def get_prerequisite_tree(
        self,
        db: AsyncSession,
        course_id: UUID,
    ) -> PrerequisiteTreeNode:
        """Build full recursive prerequisite tree using a CTE (COURSE-03).

        T-03-11: depth limit of 10 prevents runaway queries from circular
        prerequisites. Uses raw SQL via text() for the recursive CTE.
        """
        # First, verify the course exists
        course = await self.get_or_404(db, course_id, "course")

        # Recursive CTE — depth limit of 10 prevents infinite recursion
        cte_sql = text("""
            WITH RECURSIVE prereq_tree AS (
                SELECT
                    p.prerequisite_id AS id,
                    c.code,
                    c.name,
                    p.course_id AS parent_id,
                    1 AS depth
                FROM prerequisites p
                JOIN courses c ON c.id = p.prerequisite_id
                WHERE p.course_id = :course_id
                UNION ALL
                SELECT
                    p.prerequisite_id AS id,
                    c.code,
                    c.name,
                    p.course_id AS parent_id,
                    pt.depth + 1 AS depth
                FROM prerequisites p
                JOIN courses c ON c.id = p.prerequisite_id
                JOIN prereq_tree pt ON p.course_id = pt.id
                WHERE pt.depth < :max_depth
            )
            SELECT id, code, name, parent_id, depth
            FROM prereq_tree
            ORDER BY depth ASC
        """)

        result = await db.execute(cte_sql, {"course_id": str(course_id), "max_depth": 10})
        rows = result.fetchall()

        # Build tree structure from flat CTE results
        tree = self._build_prerequisite_tree(course_id, rows)

        return PrerequisiteTreeNode(
            id=course.id,
            code=course.code,
            name=course.name,
            prerequisites=tree,
        )

    @staticmethod
    def _build_prerequisite_tree(
        root_id: UUID,
        rows: list[Any],
    ) -> list[PrerequisiteTreeNode]:
        """Build nested tree from flat CTE rows.

        Each row has: id, code, name, parent_id, depth.
        Groups children by parent_id, then recursively builds the tree.
        """
        # Group rows by parent_id
        children_map: dict[UUID, list[dict[str, Any]]] = defaultdict(list)
        for row in rows:
            parent_id = row[3]  # parent_id column
            children_map[parent_id].append({
                "id": row[0],
                "code": row[1],
                "name": row[2],
            })

        def _build_children(parent_id: UUID, visited: set[UUID]) -> list[PrerequisiteTreeNode]:
            children = children_map.get(parent_id, [])
            result = []
            for child in children:
                child_id = child["id"]
                # Prevent infinite recursion from circular references
                if child_id in visited:
                    continue
                new_visited = visited | {child_id}
                result.append(
                    PrerequisiteTreeNode(
                        id=child_id,
                        code=child["code"],
                        name=child["name"],
                        prerequisites=_build_children(child_id, new_visited),
                    )
                )
            return result

        return _build_children(root_id, set())

    # ------------------------------------------------------------------
    # CURR-01: Active curriculum grouped by semester
    # ------------------------------------------------------------------

    async def get_active_curriculum(
        self,
        db: AsyncSession,
    ) -> CurriculumResponse:
        """Get the active curriculum with courses organized by semester.

        Joins curriculum_courses and courses tables, groups by semester.
        """
        # Find active curriculum
        result = await db.execute(
            select(Curriculum).where(Curriculum.is_active == True)  # noqa: E712
        )
        curriculum = result.scalar_one_or_none()

        if curriculum is None:
            raise NotFoundException("curriculum")

        return await self._build_curriculum_response(db, curriculum)

    # ------------------------------------------------------------------
    # CURR-02: Specific curriculum by ID
    # ------------------------------------------------------------------

    async def get_curriculum_by_id(
        self,
        db: AsyncSession,
        curriculum_id: UUID,
    ) -> CurriculumResponse:
        """Get a specific curriculum by ID with courses grouped by semester.

        Raises NotFoundException with resource_name='curriculo' if not found.
        """
        result = await db.execute(
            select(Curriculum).where(Curriculum.id == curriculum_id)
        )
        curriculum = result.scalar_one_or_none()

        if curriculum is None:
            raise NotFoundException("curriculum", curriculum_id)

        return await self._build_curriculum_response(db, curriculum)

    # ------------------------------------------------------------------
    # Shared helper: build curriculum response with semester groups
    # ------------------------------------------------------------------

    async def _build_curriculum_response(
        self,
        db: AsyncSession,
        curriculum: Curriculum,
    ) -> CurriculumResponse:
        """Build CurriculumResponse from a Curriculum instance.

        Loads curriculum_courses with eager-loaded courses, groups by semester.
        """
        # Load curriculum courses with course data
        result = await db.execute(
            select(CurriculumCourse, Course)
            .join(Course, CurriculumCourse.course_id == Course.id)
            .where(CurriculumCourse.curriculum_id == curriculum.id)
            .order_by(CurriculumCourse.semester.asc(), Course.code.asc())
        )
        entries = result.all()

        # Group by semester
        semester_map: dict[int, list[CurriculumCourseItem]] = defaultdict(list)
        for cc, course in entries:
            semester_map[cc.semester].append(
                CurriculumCourseItem(
                    id=course.id,
                    code=course.code,
                    name=course.name,
                    credits=course.credits,
                    is_required=cc.is_required,
                )
            )

        # Build sorted semester groups
        semesters = [
            SemesterGroup(semester=sem, courses=courses)
            for sem, courses in sorted(semester_map.items())
        ]

        return CurriculumResponse(
            id=curriculum.id,
            name=curriculum.name,
            year=curriculum.year,
            semesters=semesters,
        )


# Module-level singleton for convenience
course_service = CourseService()
