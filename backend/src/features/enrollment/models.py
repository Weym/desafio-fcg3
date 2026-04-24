from __future__ import annotations

import uuid
from datetime import date, datetime

from sqlalchemy import CheckConstraint, Date, DateTime, ForeignKey, Index, String, UniqueConstraint, func, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

try:
    from infrastructure.database import Base
except ModuleNotFoundError:  # pragma: no cover
    from src.infrastructure.database import Base


class EnrollmentPeriod(Base):
    __tablename__ = "enrollment_periods"
    __table_args__ = (
        CheckConstraint(
            "type IN ('enrollment', 're_enrollment')",
            name="ck_enrollment_periods_type",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    type: Mapped[str] = mapped_column(String(20), nullable=False)
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date] = mapped_column(Date, nullable=False)
    semester_year: Mapped[str] = mapped_column(String(10), nullable=False)
    is_active: Mapped[bool] = mapped_column(nullable=False, server_default=text("false"))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=func.now())

    enrollments: Mapped[list["Enrollment"]] = relationship(back_populates="enrollment_period")


class Enrollment(Base):
    __tablename__ = "enrollments"
    __table_args__ = (
        CheckConstraint(
            "status IN ('draft', 'confirmed', 'cancelled')",
            name="ck_enrollments_status",
        ),
        Index("idx_enrollments_student", "student_id", "status"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("students.id"), nullable=False)
    enrollment_period_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("enrollment_periods.id"), nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False, server_default=text("'draft'"))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=func.now())
    confirmed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    student: Mapped["Student"] = relationship(back_populates="enrollments")
    enrollment_period: Mapped[EnrollmentPeriod] = relationship(back_populates="enrollments")
    enrollment_courses: Mapped[list["EnrollmentCourse"]] = relationship(back_populates="enrollment")


class EnrollmentCourse(Base):
    __tablename__ = "enrollment_courses"
    __table_args__ = (
        CheckConstraint(
            "status IN ('enrolled', 'dropped', 'locked')",
            name="ck_enrollment_courses_status",
        ),
        UniqueConstraint("enrollment_id", "course_id", name="uq_enrollment_courses_enrollment_course"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    enrollment_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("enrollments.id"), nullable=False)
    course_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("courses.id"), nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False, server_default=text("'enrolled'"))

    enrollment: Mapped[Enrollment] = relationship(back_populates="enrollment_courses")
    course: Mapped["Course"] = relationship(back_populates="enrollment_courses")
    grades: Mapped[list["Grade"]] = relationship(back_populates="enrollment_course")
