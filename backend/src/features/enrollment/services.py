"""Business logic for the Enrollment feature slice.

EnrollmentPeriodService: CRUD for enrollment periods (ENROLL-STAFF-01/02/03, ENROLL-01).
EnrollmentService: Full enrollment lifecycle — create with prerequisite validation,
    confirm, update courses, drop (draft only per D-12), lock (two levels per D-11),
    and list with IDOR-safe filters (ENROLL-02 through ENROLL-08).
"""

from __future__ import annotations

from datetime import date, datetime, timezone
from typing import Any
from uuid import UUID

from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from src.features.courses.models import Course, Prerequisite
from src.features.enrollment.models import (
    Enrollment,
    EnrollmentCourse,
    EnrollmentPeriod,
)
from src.features.enrollment.schemas import (
    EnrollmentCourseItem,
    EnrollmentCreate,
    EnrollmentListItem,
    EnrollmentPeriodCreate,
    EnrollmentPeriodUpdate,
    EnrollmentResponse,
)
from src.features.students.models import Grade
from src.shared.base_service import BaseService
from src.shared.exceptions import (
    ConflictException,
    NotFoundException,
    ValidationException,
)
from src.shared.pagination import PaginationParams


# ============================================================================
# EnrollmentPeriodService
# ============================================================================

class EnrollmentPeriodService(BaseService[EnrollmentPeriod]):
    """Service layer for ENROLL-STAFF-* and ENROLL-01 requirements."""

    def __init__(self) -> None:
        super().__init__(EnrollmentPeriod)

    async def _deactivate_other_active_periods(
        self,
        db: AsyncSession,
        exclude_id: UUID | None = None,
    ) -> None:
        """Ensure only one enrollment period stays active at a time."""
        query = select(EnrollmentPeriod).where(EnrollmentPeriod.is_active.is_(True))
        if exclude_id is not None:
            query = query.where(EnrollmentPeriod.id != exclude_id)

        result = await db.execute(query)
        for active_period in result.scalars().all():
            active_period.is_active = False

    # ------------------------------------------------------------------
    # ENROLL-01: Get current (active) enrollment period
    # ------------------------------------------------------------------

    async def get_current_period(
        self,
        db: AsyncSession,
    ) -> EnrollmentPeriod | None:
        """Return the active enrollment period, or None if none is active.

        Active means: is_active=True AND start_date <= today <= end_date.
        Returns None rather than 404 — the chatbot needs this to display
        "no active period" rather than raising an error.
        """
        today = date.today()
        result = await db.execute(
            select(EnrollmentPeriod).where(
                and_(
                    EnrollmentPeriod.is_active == True,  # noqa: E712
                    EnrollmentPeriod.start_date <= today,
                    EnrollmentPeriod.end_date >= today,
                )
            )
        )
        return result.scalar_one_or_none()

    # ------------------------------------------------------------------
    # ENROLL-STAFF-03: List all enrollment periods
    # ------------------------------------------------------------------

    async def list_periods(
        self,
        db: AsyncSession,
        params: PaginationParams,
    ) -> tuple[list[EnrollmentPeriod], int]:
        """List all enrollment periods with pagination."""
        return await self.list(db, params)

    # ------------------------------------------------------------------
    # ENROLL-STAFF-01: Create enrollment period
    # ------------------------------------------------------------------

    async def create_period(
        self,
        db: AsyncSession,
        data: EnrollmentPeriodCreate,
    ) -> EnrollmentPeriod:
        """Create enrollment period. Validates start_date < end_date."""
        if data.start_date >= data.end_date:
            raise ValidationException(
                message="Data de inicio deve ser anterior a data de termino",
                details=[
                    {"field": "start_date", "message": "start_date deve ser menor que end_date"}
                ],
            )

        if data.is_active:
            await self._deactivate_other_active_periods(db)

        return await self.create(db, data.model_dump())

    # ------------------------------------------------------------------
    # ENROLL-STAFF-02: Update enrollment period
    # ------------------------------------------------------------------

    async def update_period(
        self,
        db: AsyncSession,
        period_id: UUID,
        data: EnrollmentPeriodUpdate,
    ) -> EnrollmentPeriod:
        """Update enrollment period, including toggle is_active."""
        period = await self.get_or_404(db, period_id, "enrollment_period")
        update_data = data.model_dump(exclude_unset=True)

        # Validate dates if both are being set or one is being updated
        new_start = update_data.get("start_date", period.start_date)
        new_end = update_data.get("end_date", period.end_date)
        if new_start >= new_end:
            raise ValidationException(
                message="Data de inicio deve ser anterior a data de termino",
                details=[
                    {"field": "start_date", "message": "start_date deve ser menor que end_date"}
                ],
            )

        if update_data.get("is_active") is True:
            await self._deactivate_other_active_periods(db, exclude_id=period.id)

        return await self.update(db, period, update_data)


# ============================================================================
# EnrollmentService
# ============================================================================

class EnrollmentService(BaseService[Enrollment]):
    """Service layer for ENROLL-02 through ENROLL-08 requirements."""

    def __init__(self) -> None:
        super().__init__(Enrollment)

    # ------------------------------------------------------------------
    # Helper: build EnrollmentResponse from an Enrollment instance
    # ------------------------------------------------------------------

    async def _build_response(
        self,
        db: AsyncSession,
        enrollment: Enrollment,
    ) -> EnrollmentResponse:
        """Build EnrollmentResponse with course details eagerly loaded."""
        # Reload with courses + course details
        result = await db.execute(
            select(Enrollment)
            .options(
                selectinload(Enrollment.enrollment_courses)
                .selectinload(EnrollmentCourse.course)
            )
            .where(Enrollment.id == enrollment.id)
        )
        enrollment = result.scalar_one()

        courses = [
            EnrollmentCourseItem(
                id=ec.id,
                course_id=ec.course_id,
                code=ec.course.code,
                name=ec.course.name,
                status=ec.status,
            )
            for ec in enrollment.enrollment_courses
        ]

        return EnrollmentResponse(
            id=enrollment.id,
            status=enrollment.status,
            courses=courses,
            created_at=enrollment.created_at,
            confirmed_at=enrollment.confirmed_at,
        )

    # ------------------------------------------------------------------
    # Helper: validate prerequisites for a list of course_ids
    # ------------------------------------------------------------------

    async def _validate_prerequisites(
        self,
        db: AsyncSession,
        student_id: UUID,
        course_ids: list[UUID],
    ) -> None:
        """Check that the student has passed ALL prerequisites for each course.

        Raises 409 PREREQUISITO_NAO_CUMPRIDO if any prerequisite is unmet (ENROLL-08, D-13).
        """
        # 1. Get courses the student has passed
        passed_result = await db.execute(
            select(Grade.course_id).where(
                and_(
                    Grade.student_id == student_id,
                    Grade.status == "approved",
                )
            )
        )
        passed_ids: set[UUID] = {row[0] for row in passed_result.all()}

        # 2. Get all prerequisites for the requested courses
        prereq_result = await db.execute(
            select(Prerequisite).where(
                Prerequisite.course_id.in_(course_ids)
            )
        )
        prereqs = prereq_result.scalars().all()

        # Build mapping: course_id -> set of prerequisite_ids
        prereq_map: dict[UUID, set[UUID]] = {}
        for p in prereqs:
            prereq_map.setdefault(p.course_id, set()).add(p.prerequisite_id)

        # 3. Check each course
        for cid in course_ids:
            required = prereq_map.get(cid, set())
            missing = required - passed_ids
            if missing:
                # Get names of missing prerequisites for error message
                missing_names_result = await db.execute(
                    select(Course.name).where(Course.id.in_(missing))
                )
                missing_names = [row[0] for row in missing_names_result.all()]

                # Get the course name for the error message
                course_result = await db.execute(
                    select(Course.name).where(Course.id == cid)
                )
                course_name = course_result.scalar_one_or_none() or str(cid)

                raise ConflictException(
                    code="PREREQUISITO_NAO_CUMPRIDO",
                    message=(
                        f"Pre-requisitos nao cumpridos para {course_name}: "
                        f"{', '.join(missing_names)}"
                    ),
                )

    # ------------------------------------------------------------------
    # ENROLL-02: Create enrollment (draft)
    # ------------------------------------------------------------------

    async def create_enrollment(
        self,
        db: AsyncSession,
        student_id: UUID,
        data: EnrollmentCreate,
    ) -> EnrollmentResponse:
        """Create draft enrollment with courses.

        Validates:
        - Active period exists (D-13: 409 PERIODO_MATRICULA_FECHADO)
        - enrollment_period_id matches active period
        - No existing draft/confirmed enrollment for student+period (409 MATRICULA_JA_EXISTENTE)
        - Duplicate course_ids deduplication (P-06)
        - All courses exist (404 DISCIPLINA_NAO_ENCONTRADA)
        - All prerequisites met (ENROLL-08, D-13: 409 PREREQUISITO_NAO_CUMPRIDO)
        """
        # 1. Check active period
        today = date.today()
        period_result = await db.execute(
            select(EnrollmentPeriod).where(
                and_(
                    EnrollmentPeriod.id == data.enrollment_period_id,
                    EnrollmentPeriod.is_active == True,  # noqa: E712
                    EnrollmentPeriod.start_date <= today,
                    EnrollmentPeriod.end_date >= today,
                )
            )
        )
        period = period_result.scalar_one_or_none()
        if period is None:
            raise ConflictException(
                code="PERIODO_MATRICULA_FECHADO",
                message="Nao ha periodo de matricula ativo ou o periodo informado nao esta ativo",
            )

        # 2. Check no existing active/locked enrollment for this student+period
        existing_result = await db.execute(
            select(Enrollment).where(
                and_(
                    Enrollment.student_id == student_id,
                    Enrollment.enrollment_period_id == data.enrollment_period_id,
                    Enrollment.status.in_(["draft", "confirmed", "locked"]),
                )
            )
        )
        if existing_result.scalar_one_or_none() is not None:
            raise ConflictException(
                code="MATRICULA_JA_EXISTENTE",
                message="Ja existe uma matricula ativa para este periodo",
            )

        # 3. Deduplicate course_ids (P-06 from 03-RESEARCH.md)
        unique_course_ids = list(dict.fromkeys(data.course_ids))

        # 4. Verify all courses exist
        for cid in unique_course_ids:
            course_result = await db.execute(
                select(Course).where(Course.id == cid)
            )
            if course_result.scalar_one_or_none() is None:
                raise NotFoundException("course", cid)

        # 5. Prerequisite validation (ENROLL-08)
        await self._validate_prerequisites(db, student_id, unique_course_ids)

        # 6. Create enrollment
        enrollment = Enrollment(
            student_id=student_id,
            enrollment_period_id=data.enrollment_period_id,
            status="draft",
        )
        db.add(enrollment)
        await db.flush()

        # 7. Create enrollment_courses
        for cid in unique_course_ids:
            ec = EnrollmentCourse(
                enrollment_id=enrollment.id,
                course_id=cid,
                status="enrolled",
            )
            db.add(ec)

        await db.flush()
        await db.refresh(enrollment)

        return await self._build_response(db, enrollment)

    # ------------------------------------------------------------------
    # ENROLL-03: Confirm enrollment (draft -> confirmed)
    # ------------------------------------------------------------------

    async def confirm_enrollment(
        self,
        db: AsyncSession,
        enrollment_id: UUID,
        student_id: UUID,
    ) -> EnrollmentResponse:
        """Confirm enrollment — changes status from draft to confirmed.

        Uses SELECT FOR UPDATE to prevent race condition (P-03):
        two concurrent confirms could create duplicate grade records.

        Validates:
        - Enrollment exists and belongs to student (IDOR)
        - Status is draft (409 MATRICULA_JA_CONFIRMADA)
        - Period is still active (409 PERIODO_MATRICULA_FECHADO)

        On confirmation, creates grade records for each enrollment_course.
        """
        # SELECT FOR UPDATE to prevent concurrent confirms
        result = await db.execute(
            select(Enrollment)
            .options(selectinload(Enrollment.enrollment_courses))
            .where(Enrollment.id == enrollment_id)
            .with_for_update()
        )
        enrollment = result.scalar_one_or_none()

        if enrollment is None:
            raise NotFoundException("enrollment", enrollment_id)

        # IDOR check
        if enrollment.student_id != student_id:
            raise NotFoundException("enrollment", enrollment_id)

        # Status check
        if enrollment.status != "draft":
            raise ConflictException(
                code="MATRICULA_JA_CONFIRMADA",
                message="Esta matricula ja foi confirmada ou nao esta em rascunho",
            )

        # Period active check
        today = date.today()
        period_result = await db.execute(
            select(EnrollmentPeriod).where(
                and_(
                    EnrollmentPeriod.id == enrollment.enrollment_period_id,
                    EnrollmentPeriod.is_active == True,  # noqa: E712
                    EnrollmentPeriod.start_date <= today,
                    EnrollmentPeriod.end_date >= today,
                )
            )
        )
        if period_result.scalar_one_or_none() is None:
            raise ConflictException(
                code="PERIODO_MATRICULA_FECHADO",
                message="O periodo de matricula nao esta mais ativo",
            )

        # Confirm enrollment
        enrollment.status = "confirmed"
        enrollment.confirmed_at = datetime.now(timezone.utc)

        # Get the period semester_year for grade records
        period = await db.execute(
            select(EnrollmentPeriod).where(
                EnrollmentPeriod.id == enrollment.enrollment_period_id
            )
        )
        enrollment_period = period.scalar_one()

        # Create grade records for each enrolled course
        for ec in enrollment.enrollment_courses:
            if ec.status == "enrolled":
                grade = Grade(
                    student_id=student_id,
                    course_id=ec.course_id,
                    enrollment_course_id=ec.id,
                    semester_year=enrollment_period.semester_year,
                    status="in_progress",
                )
                db.add(grade)

        await db.flush()
        await db.refresh(enrollment)

        return await self._build_response(db, enrollment)

    # ------------------------------------------------------------------
    # ENROLL-04: Update enrollment courses (replace)
    # ------------------------------------------------------------------

    async def update_enrollment_courses(
        self,
        db: AsyncSession,
        enrollment_id: UUID,
        student_id: UUID,
        course_ids: list[UUID],
    ) -> EnrollmentResponse:
        """Replace enrollment courses while enrollment is draft.

        Validates:
        - Enrollment exists and belongs to student
        - Status is draft
        - Prerequisites met for all new courses
        - All courses exist
        """
        enrollment = await self.get_by_id(db, enrollment_id)
        if enrollment is None:
            raise NotFoundException("enrollment", enrollment_id)

        # IDOR check
        if enrollment.student_id != student_id:
            raise NotFoundException("enrollment", enrollment_id)

        # Status check
        if enrollment.status != "draft":
            raise ConflictException(
                code="OPERACAO_NAO_PERMITIDA",
                message="Modificacao de disciplinas so e permitida em matriculas em rascunho",
            )

        # Deduplicate
        unique_course_ids = list(dict.fromkeys(course_ids))

        # Verify all courses exist
        for cid in unique_course_ids:
            course_result = await db.execute(
                select(Course).where(Course.id == cid)
            )
            if course_result.scalar_one_or_none() is None:
                raise NotFoundException("course", cid)

        # Prerequisite validation
        await self._validate_prerequisites(db, student_id, unique_course_ids)

        # Delete existing enrollment_courses
        existing_result = await db.execute(
            select(EnrollmentCourse).where(
                EnrollmentCourse.enrollment_id == enrollment_id
            )
        )
        for ec in existing_result.scalars().all():
            await db.delete(ec)

        # Create new enrollment_courses
        for cid in unique_course_ids:
            ec = EnrollmentCourse(
                enrollment_id=enrollment_id,
                course_id=cid,
                status="enrolled",
            )
            db.add(ec)

        await db.flush()
        await db.refresh(enrollment)

        return await self._build_response(db, enrollment)

    # ------------------------------------------------------------------
    # ENROLL-05: Drop course from enrollment
    # ------------------------------------------------------------------

    async def drop_course(
        self,
        db: AsyncSession,
        enrollment_id: UUID,
        course_id: UUID,
        student_id: UUID,
    ) -> EnrollmentResponse:
        """Drop a course from enrollment. D-12: only allowed in draft status.

        After confirmation, student must use lock (trancamento) instead.
        """
        enrollment = await self.get_by_id(db, enrollment_id)
        if enrollment is None:
            raise NotFoundException("enrollment", enrollment_id)

        # IDOR check
        if enrollment.student_id != student_id:
            raise NotFoundException("enrollment", enrollment_id)

        # D-12: Drop only in draft status
        if enrollment.status != "draft":
            raise ConflictException(
                code="OPERACAO_NAO_PERMITIDA",
                message=(
                    "Remocao de disciplina so e permitida em matriculas em rascunho. "
                    "Utilize trancamento (lock) para matriculas confirmadas."
                ),
            )

        # Find the enrollment_course
        ec_result = await db.execute(
            select(EnrollmentCourse).where(
                and_(
                    EnrollmentCourse.enrollment_id == enrollment_id,
                    EnrollmentCourse.course_id == course_id,
                    EnrollmentCourse.status == "enrolled",
                )
            )
        )
        ec = ec_result.scalar_one_or_none()
        if ec is None:
            raise NotFoundException("course", course_id)

        # Set status to dropped
        ec.status = "dropped"
        await db.flush()

        return await self._build_response(db, enrollment)

    # ------------------------------------------------------------------
    # ENROLL-06: Lock enrollment (D-11 level a: lock entire enrollment)
    # ------------------------------------------------------------------

    async def lock_enrollment(
        self,
        db: AsyncSession,
        enrollment_id: UUID,
        student_id: UUID,
    ) -> EnrollmentResponse:
        """Lock entire enrollment and all courses — irreversible (D-11 level a).

        Can lock from draft or confirmed status. Sets enrollment.status = 'locked'
        and all enrollment_courses.status = 'locked'.
        """
        result = await db.execute(
            select(Enrollment)
            .options(
                selectinload(Enrollment.enrollment_courses).selectinload(
                    EnrollmentCourse.grades,
                ),
            )
            .where(Enrollment.id == enrollment_id)
        )
        enrollment = result.scalar_one_or_none()

        if enrollment is None:
            raise NotFoundException("enrollment", enrollment_id)

        # IDOR check
        if enrollment.student_id != student_id:
            raise NotFoundException("enrollment", enrollment_id)

        # Already locked check
        if enrollment.status == "locked":
            raise ConflictException(
                code="MATRICULA_JA_TRANCADA",
                message="Esta matricula ja esta trancada",
            )

        # Lock enrollment
        enrollment.status = "locked"

        # Lock ALL enrollment_courses (D-11: the entire semester)
        for ec in enrollment.enrollment_courses:
            if ec.status != "dropped":
                ec.status = "locked"
                for grade in ec.grades:
                    grade.status = "locked"

        await db.flush()
        await db.refresh(enrollment)

        return await self._build_response(db, enrollment)

    # ------------------------------------------------------------------
    # ENROLL-07: List enrollments
    # ------------------------------------------------------------------

    async def list_enrollments(
        self,
        db: AsyncSession,
        params: PaginationParams,
        student_id: UUID | None = None,
        semester_year: str | None = None,
        status: str | None = None,
    ) -> tuple[list[EnrollmentListItem], int]:
        """List enrollments with pagination and optional filters.

        If student_id is provided, filter by that student.
        Staff can view all; students are forced to their own ID (IDOR-safe in controller).
        """
        query = (
            select(
                Enrollment.id,
                Enrollment.status,
                EnrollmentPeriod.semester_year,
                func.count(EnrollmentCourse.id).label("course_count"),
                Enrollment.created_at,
            )
            .join(EnrollmentPeriod, Enrollment.enrollment_period_id == EnrollmentPeriod.id)
            .outerjoin(EnrollmentCourse, EnrollmentCourse.enrollment_id == Enrollment.id)
            .group_by(
                Enrollment.id,
                Enrollment.status,
                EnrollmentPeriod.semester_year,
                Enrollment.created_at,
            )
        )

        count_base = select(func.count(func.distinct(Enrollment.id))).select_from(Enrollment)

        # Apply filters
        if student_id is not None:
            query = query.where(Enrollment.student_id == student_id)
            count_base = count_base.where(Enrollment.student_id == student_id)

        if semester_year is not None:
            # EnrollmentPeriod is already joined in the main query
            query = query.where(EnrollmentPeriod.semester_year == semester_year)
            count_base = count_base.join(
                EnrollmentPeriod,
                Enrollment.enrollment_period_id == EnrollmentPeriod.id,
            ).where(EnrollmentPeriod.semester_year == semester_year)

        if status is not None:
            query = query.where(Enrollment.status == status)
            count_base = count_base.where(Enrollment.status == status)

        # Total count
        total_result = await db.execute(count_base)
        total = total_result.scalar_one()

        # Sorting and pagination
        from sqlalchemy import asc, desc

        order_func = asc if params.order == "asc" else desc
        query = query.order_by(order_func(Enrollment.created_at))
        query = query.offset(params.offset).limit(params.limit)

        result = await db.execute(query)
        rows = result.all()

        items = [
            EnrollmentListItem(
                id=row.id,
                status=row.status,
                semester_year=row.semester_year,
                course_count=row.course_count,
                created_at=row.created_at,
            )
            for row in rows
        ]

        return items, total


# Module-level singletons for convenience
enrollment_period_service = EnrollmentPeriodService()
enrollment_service = EnrollmentService()
