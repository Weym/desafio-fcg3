from __future__ import annotations

import uuid
from datetime import datetime
from decimal import Decimal

from sqlalchemy import CheckConstraint, DateTime, ForeignKey, Index, Numeric, String, func, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

try:
    from infrastructure.database import Base
except ModuleNotFoundError:  # pragma: no cover
    from src.infrastructure.database import Base


class Grade(Base):
    __tablename__ = "grades"
    __table_args__ = (
        CheckConstraint(
            "status IN ('in_progress', 'approved', 'failed', 'locked')",
            name="ck_grades_status",
        ),
        Index("idx_grades_student_semester", "student_id", "semester_year"),
        Index("idx_grades_enrollment_course", "enrollment_course_id"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("students.id"), nullable=False)
    course_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("courses.id"), nullable=False)
    enrollment_course_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("enrollment_courses.id"), nullable=False)
    semester_year: Mapped[str] = mapped_column(String(10), nullable=False)
    grade_1: Mapped[Decimal | None] = mapped_column(Numeric(4, 2))
    grade_2: Mapped[Decimal | None] = mapped_column(Numeric(4, 2))
    grade_final: Mapped[Decimal | None] = mapped_column(Numeric(4, 2))
    status: Mapped[str] = mapped_column(String(20), nullable=False, server_default=text("'in_progress'"))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now())

    student: Mapped["Student"] = relationship(back_populates="grades")
    course: Mapped["Course"] = relationship(back_populates="grades")
    enrollment_course: Mapped["EnrollmentCourse"] = relationship(back_populates="grades")
