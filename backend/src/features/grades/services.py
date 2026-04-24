"""Business logic for the Grades feature slice.

GradeService provides:
- get_student_grades: grades per student filtered by semester_year (GRADES-01)
- get_transcript: full academic transcript with CRA (GRADES-02)
- calculate_cra: credit-weighted average (GRADES-03, D-07, D-08)
- update_grade: staff posts/updates grades with auto-calculated final (GRADES-04)
- compute_final_grade: (grade_1 + grade_2) / 2 (pure helper)
- compute_status: approved/failed/in_progress based on grade_final (pure helper)
"""

from __future__ import annotations

from decimal import Decimal, ROUND_HALF_UP
from typing import Any
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload

from src.features.courses.models import Course
from src.features.students.models import Grade
from src.features.grades.schemas import (
    CourseInfo,
    GradeResponse,
    GradeUpdate,
    TranscriptEntry,
    TranscriptResponse,
)
from src.shared.exceptions import NotFoundException


# Passing threshold (configurable)
PASSING_THRESHOLD = Decimal("5.00")


class GradeService:
    """Service layer for all GRADES-* requirements."""

    # ------------------------------------------------------------------
    # GRADES-03, D-07, D-08: CRA calculation (pure Python, no DB)
    # ------------------------------------------------------------------

    @staticmethod
    def calculate_cra(
        grades_with_credits: list[tuple[Decimal | float | None, int]],
    ) -> Decimal:
        """Calculate CRA (credit-weighted average).

        Pure Python function (D-07): no database access, fully testable.

        Args:
            grades_with_credits: list of (grade_final, credits) tuples.
                grade_final may be None (in-progress) — these are excluded (D-08).
                grade_final may be float or Decimal for compatibility.

        Returns:
            Decimal CRA rounded to 2 decimal places.
            Returns Decimal("0.00") if no valid grades (division-by-zero guard).
        """
        total_weighted = Decimal("0")
        total_credits = Decimal("0")

        for grade_final, credits in grades_with_credits:
            # D-08: exclude entries where grade_final is None
            if grade_final is None:
                continue

            # Convert to Decimal for precision (P-07)
            grade_dec = (
                grade_final
                if isinstance(grade_final, Decimal)
                else Decimal(str(grade_final))
            )
            credits_dec = Decimal(str(credits))

            total_weighted += grade_dec * credits_dec
            total_credits += credits_dec

        # Division by zero guard
        if total_credits == 0:
            return Decimal("0.00")

        cra = total_weighted / total_credits
        return cra.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)

    # ------------------------------------------------------------------
    # Pure helpers for grade computation
    # ------------------------------------------------------------------

    @staticmethod
    def compute_final_grade(
        grade_1: Decimal | None,
        grade_2: Decimal | None,
    ) -> Decimal | None:
        """Auto-calculate grade_final from grade_1 and grade_2.

        Returns (grade_1 + grade_2) / 2 if both are set, None otherwise.
        """
        if grade_1 is None or grade_2 is None:
            return None
        return ((grade_1 + grade_2) / 2).quantize(
            Decimal("0.01"), rounding=ROUND_HALF_UP
        )

    @staticmethod
    def compute_status(grade_final: Decimal | None) -> str:
        """Determine grade status based on final grade.

        - grade_final is None → 'in_progress'
        - grade_final >= 5.0  → 'approved'
        - grade_final < 5.0   → 'failed'
        """
        if grade_final is None:
            return "in_progress"
        return "approved" if grade_final >= PASSING_THRESHOLD else "failed"

    # ------------------------------------------------------------------
    # GRADES-01: Get student grades (with optional semester filter)
    # ------------------------------------------------------------------

    async def get_student_grades(
        self,
        db: AsyncSession,
        student_id: UUID,
        semester_year: str | None = None,
    ) -> list[GradeResponse]:
        """Query grades for a student, join courses for code/name.

        Filter by semester_year if provided.
        """
        query = (
            select(Grade, Course)
            .join(Course, Grade.course_id == Course.id)
            .where(Grade.student_id == student_id)
        )

        if semester_year is not None:
            query = query.where(Grade.semester_year == semester_year)

        query = query.order_by(Grade.semester_year.desc(), Course.code.asc())

        result = await db.execute(query)
        rows = result.all()

        return [
            GradeResponse(
                id=grade.id,
                course=CourseInfo(code=course.code, name=course.name),
                semester_year=grade.semester_year,
                grade_1=float(grade.grade_1) if grade.grade_1 is not None else None,
                grade_2=float(grade.grade_2) if grade.grade_2 is not None else None,
                grade_final=float(grade.grade_final) if grade.grade_final is not None else None,
                status=grade.status,
            )
            for grade, course in rows
        ]

    # ------------------------------------------------------------------
    # GRADES-02: Get transcript (full history with CRA)
    # ------------------------------------------------------------------

    async def get_transcript(
        self,
        db: AsyncSession,
        student_id: UUID,
    ) -> TranscriptResponse:
        """Query ALL grades for student with course info, compute CRA."""
        # Get student name
        from src.features.auth.models import Student

        student_result = await db.execute(
            select(Student).where(Student.id == student_id)
        )
        student = student_result.scalar_one_or_none()
        if student is None:
            raise NotFoundException("student", student_id)

        # Get all grades with course info
        query = (
            select(Grade, Course)
            .join(Course, Grade.course_id == Course.id)
            .where(Grade.student_id == student_id)
            .order_by(Grade.semester_year.asc(), Course.code.asc())
        )
        result = await db.execute(query)
        rows = result.all()

        # Build entries and CRA input
        entries: list[TranscriptEntry] = []
        cra_input: list[tuple[Decimal | None, int]] = []

        for grade, course in rows:
            entries.append(
                TranscriptEntry(
                    course_code=course.code,
                    course_name=course.name,
                    semester_year=grade.semester_year,
                    grade_final=float(grade.grade_final) if grade.grade_final is not None else None,
                    status=grade.status,
                    credits=course.credits,
                )
            )
            # Only include non-locked grades in CRA (D-08)
            if grade.status != "locked":
                cra_input.append((grade.grade_final, course.credits))

        cra = self.calculate_cra(cra_input)

        return TranscriptResponse(
            student_id=student.id,
            student_name=student.name,
            entries=entries,
            cra=float(cra),
        )

    # ------------------------------------------------------------------
    # GRADES-04: Update grade (staff only)
    # ------------------------------------------------------------------

    async def update_grade(
        self,
        db: AsyncSession,
        grade_id: UUID,
        data: GradeUpdate,
    ) -> Grade:
        """Update grade_1 and/or grade_2, auto-calculate grade_final and status.

        T-03-22: grade_final is calculated server-side, not settable by API.
        """
        result = await db.execute(
            select(Grade).where(Grade.id == grade_id)
        )
        grade = result.scalar_one_or_none()
        if grade is None:
            raise NotFoundException("grade", grade_id)

        # Update grade_1 and/or grade_2
        if data.grade_1 is not None:
            grade.grade_1 = Decimal(str(data.grade_1))
        if data.grade_2 is not None:
            grade.grade_2 = Decimal(str(data.grade_2))

        # Auto-calculate grade_final if both grades are set
        grade.grade_final = self.compute_final_grade(grade.grade_1, grade.grade_2)

        # Auto-set status based on grade_final
        grade.status = self.compute_status(grade.grade_final)

        await db.flush()
        await db.refresh(grade)
        return grade

    # ------------------------------------------------------------------
    # CRA for academic summary (used by StudentService)
    # ------------------------------------------------------------------

    async def get_cra_for_student(
        self,
        db: AsyncSession,
        student_id: UUID,
    ) -> float:
        """Calculate CRA for a student. Used by get_academic_summary.

        Queries grades with course credits, filters per D-08 rules,
        then delegates to calculate_cra.
        """
        query = (
            select(Grade.grade_final, Course.credits)
            .join(Course, Grade.course_id == Course.id)
            .where(Grade.student_id == student_id)
            .where(Grade.status != "locked")
        )
        result = await db.execute(query)
        rows = result.all()

        cra_input = [(row[0], row[1]) for row in rows]
        cra = self.calculate_cra(cra_input)
        return float(cra)


# Module-level singleton for convenience
grade_service = GradeService()
