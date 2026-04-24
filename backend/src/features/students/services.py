"""Business logic for the Students feature slice.

StudentService extends BaseService[Student] and adds:
- list_students: paginated with search/semester/status filters (STU-01)
- get_student: detail view (STU-05)
- create_student: unique email + registration_number validation (STU-02)
- update_student: partial update (STU-03)
- soft_delete_student: set status=inactive (STU-04)
- get_academic_summary: aggregated data from multiple tables (STU-06)
- get_available_courses: prerequisite filtering (STU-07)
"""

from __future__ import annotations

from datetime import date, datetime, timezone
from typing import Any
from uuid import UUID

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from src.features.auth.models import Student
from src.features.courses.models import Course, CurriculumCourse, Prerequisite
from src.features.documents.models import Document
from src.features.scheduling.models import Appointment, SchedulingSlot
from src.features.students.models import Grade
from src.features.students.schemas import (
    AcademicSummaryResponse,
    AvailableCourseItem,
    StudentCreate,
    StudentUpdate,
)
from src.shared.base_service import BaseService
from src.shared.exceptions import ConflictException, NotFoundException
from src.shared.pagination import PaginationParams


class StudentService(BaseService[Student]):
    """Service layer for all STU-* requirements."""

    def __init__(self) -> None:
        super().__init__(Student)

    # ------------------------------------------------------------------
    # STU-01: List students (staff only)
    # ------------------------------------------------------------------

    async def list_students(
        self,
        db: AsyncSession,
        params: PaginationParams,
        search: str | None = None,
        semester: int | None = None,
        status: str | None = None,
    ) -> tuple[list[Student], int]:
        """List students with pagination and optional filters.

        search: ILIKE on name column.
        semester, status: equality filters.
        """
        # Build base query and count query
        query = select(Student)
        count_query = select(func.count()).select_from(Student)

        # Apply search filter (ILIKE on name)
        if search:
            search_pattern = f"%{search}%"
            query = query.where(Student.name.ilike(search_pattern))
            count_query = count_query.where(Student.name.ilike(search_pattern))

        # Apply equality filters
        if semester is not None:
            query = query.where(Student.semester == semester)
            count_query = count_query.where(Student.semester == semester)

        if status is not None:
            query = query.where(Student.status == status)
            count_query = count_query.where(Student.status == status)

        # Total count
        total_result = await db.execute(count_query)
        total = total_result.scalar_one()

        # Sorting (validated by BaseService)
        from sqlalchemy import asc, desc

        sort_column = self._get_sort_column(params.sort_by)
        order_func = asc if params.order == "asc" else desc
        query = query.order_by(order_func(sort_column))

        # Pagination
        query = query.offset(params.offset).limit(params.limit)

        result = await db.execute(query)
        items = list(result.scalars().all())

        return items, total

    # ------------------------------------------------------------------
    # STU-05: Get student detail
    # ------------------------------------------------------------------

    async def get_student(self, db: AsyncSession, student_id: UUID) -> Student:
        """Get student by ID or raise 404."""
        return await self.get_or_404(db, student_id, "student")

    # ------------------------------------------------------------------
    # STU-02: Create student (staff only)
    # ------------------------------------------------------------------

    async def create_student(
        self,
        db: AsyncSession,
        data: StudentCreate,
    ) -> Student:
        """Create a student with unique email/registration_number validation.

        enrollment_year is auto-set to current year (SM-04).
        """
        # Check unique email
        existing_email = await db.execute(
            select(Student).where(Student.email == data.email)
        )
        if existing_email.scalar_one_or_none() is not None:
            raise ConflictException(
                code="EMAIL_JA_CADASTRADO",
                message="Ja existe um aluno cadastrado com este email",
            )

        # Check unique registration_number
        existing_reg = await db.execute(
            select(Student).where(
                Student.registration_number == data.registration_number
            )
        )
        if existing_reg.scalar_one_or_none() is not None:
            raise ConflictException(
                code="MATRICULA_JA_CADASTRADA",
                message="Ja existe um aluno cadastrado com este numero de matricula",
            )

        # Build dict — auto-set enrollment_year (SM-04)
        student_data: dict[str, Any] = data.model_dump()
        student_data["enrollment_year"] = datetime.now(timezone.utc).year

        return await self.create(db, student_data)

    # ------------------------------------------------------------------
    # STU-03: Update student (staff only)
    # ------------------------------------------------------------------

    async def update_student(
        self,
        db: AsyncSession,
        student_id: UUID,
        data: StudentUpdate,
    ) -> Student:
        """Update student fields (partial). Only non-None values are applied."""
        student = await self.get_or_404(db, student_id, "student")
        update_data = data.model_dump(exclude_unset=True)
        return await self.update(db, student, update_data)

    # ------------------------------------------------------------------
    # STU-04: Soft delete student (staff only)
    # ------------------------------------------------------------------

    async def soft_delete_student(
        self,
        db: AsyncSession,
        student_id: UUID,
    ) -> Student:
        """Soft delete: set status to 'inactive'."""
        student = await self.get_or_404(db, student_id, "student")
        student.status = "inactive"
        await db.flush()
        await db.refresh(student)
        return student

    # ------------------------------------------------------------------
    # STU-06: Academic summary
    # ------------------------------------------------------------------

    async def get_academic_summary(
        self,
        db: AsyncSession,
        student_id: UUID,
    ) -> AcademicSummaryResponse:
        """Aggregate academic data from multiple tables.

        GPA/CRA: placeholder returning 0.0 — full calculation in Plan 03-05.
        """
        # 1. Student basic info
        student = await self.get_or_404(db, student_id, "student")

        # 2. Completed courses count (grades with status='approved')
        completed_result = await db.execute(
            select(func.count()).select_from(Grade).where(
                and_(
                    Grade.student_id == student_id,
                    Grade.status == "approved",
                )
            )
        )
        completed_courses = completed_result.scalar_one()

        # 3. Total courses in student's curriculum
        total_courses = 0
        if student.curriculum_id is not None:
            total_result = await db.execute(
                select(func.count()).select_from(CurriculumCourse).where(
                    CurriculumCourse.curriculum_id == student.curriculum_id
                )
            )
            total_courses = total_result.scalar_one()

        # 4. GPA/CRA — placeholder (Plan 03-05 will implement full calculation)
        gpa = 0.0

        # 5. Pending documents (status NOT IN ('ready', 'delivered'))
        pending_result = await db.execute(
            select(func.count()).select_from(Document).where(
                and_(
                    Document.student_id == student_id,
                    Document.status.notin_(["ready", "delivered"]),
                )
            )
        )
        pending_documents = pending_result.scalar_one()

        # 6. Next appointment (status='scheduled', date >= today)
        today = date.today()
        next_appt_result = await db.execute(
            select(Appointment)
            .join(SchedulingSlot, Appointment.slot_id == SchedulingSlot.id)
            .where(
                and_(
                    Appointment.student_id == student_id,
                    Appointment.status == "scheduled",
                    SchedulingSlot.date >= today,
                )
            )
            .order_by(SchedulingSlot.date.asc(), SchedulingSlot.start_time.asc())
            .limit(1)
        )
        next_appointment_row = next_appt_result.scalar_one_or_none()
        next_appointment = (
            next_appointment_row.created_at if next_appointment_row else None
        )

        return AcademicSummaryResponse(
            student_id=student.id,
            name=student.name,
            semester=student.semester,
            completed_courses=completed_courses,
            total_courses=total_courses,
            gpa=gpa,
            status=student.status,
            pending_documents=pending_documents,
            next_appointment=next_appointment,
        )

    # ------------------------------------------------------------------
    # STU-07: Available courses with prerequisite filtering
    # ------------------------------------------------------------------

    async def get_available_courses(
        self,
        db: AsyncSession,
        student_id: UUID,
    ) -> list[AvailableCourseItem]:
        """Return courses available for enrollment respecting prerequisites.

        Logic:
        1. Get student's curriculum_id
        2. Get all courses in that curriculum (via curriculum_courses)
        3. Get courses the student has already passed (grades.status='approved')
        4. For each curriculum course, check ALL prerequisites are in passed set
        5. Return only courses where prerequisites_met=True AND not already passed
        """
        student = await self.get_or_404(db, student_id, "student")

        if student.curriculum_id is None:
            return []

        # 1. All courses in the student's curriculum with their semester info
        curriculum_courses_result = await db.execute(
            select(CurriculumCourse, Course)
            .join(Course, CurriculumCourse.course_id == Course.id)
            .where(CurriculumCourse.curriculum_id == student.curriculum_id)
        )
        curriculum_entries = curriculum_courses_result.all()

        # 2. Courses already passed by student
        passed_result = await db.execute(
            select(Grade.course_id).where(
                and_(
                    Grade.student_id == student_id,
                    Grade.status == "approved",
                )
            )
        )
        passed_course_ids: set[UUID] = {row[0] for row in passed_result.all()}

        # 3. All prerequisites (bulk load to avoid N+1)
        all_prereqs_result = await db.execute(select(Prerequisite))
        all_prereqs = all_prereqs_result.scalars().all()

        # Build mapping: course_id -> set of prerequisite_course_ids
        prereq_map: dict[UUID, set[UUID]] = {}
        for prereq in all_prereqs:
            prereq_map.setdefault(prereq.course_id, set()).add(
                prereq.prerequisite_id
            )

        # 4. Filter: not already passed AND all prerequisites met
        available: list[AvailableCourseItem] = []
        for cc, course in curriculum_entries:
            # Skip if already passed
            if course.id in passed_course_ids:
                continue

            # Check prerequisites
            required_prereqs = prereq_map.get(course.id, set())
            prerequisites_met = required_prereqs.issubset(passed_course_ids)

            if prerequisites_met:
                available.append(
                    AvailableCourseItem(
                        id=course.id,
                        code=course.code,
                        name=course.name,
                        credits=course.credits,
                        prerequisites_met=True,
                        semester=cc.semester,
                    )
                )

        return available


# Module-level singleton for convenience
student_service = StudentService()
