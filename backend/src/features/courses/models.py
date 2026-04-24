from __future__ import annotations

import uuid
from datetime import datetime

from sqlalchemy import Boolean, ForeignKey, Integer, String, Text, UniqueConstraint, func, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

try:
    from infrastructure.database import Base
except ModuleNotFoundError:  # pragma: no cover
    from src.infrastructure.database import Base


class Course(Base):
    __tablename__ = "courses"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    code: Mapped[str] = mapped_column(String(10), nullable=False, unique=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    credits: Mapped[int] = mapped_column(Integer, nullable=False)
    workload_hours: Mapped[int] = mapped_column(Integer, nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(nullable=False, server_default=func.now())

    curriculum_courses: Mapped[list["CurriculumCourse"]] = relationship(back_populates="course")
    enrollment_courses: Mapped[list["EnrollmentCourse"]] = relationship(back_populates="course")
    grades: Mapped[list["Grade"]] = relationship(back_populates="course")
    prerequisites: Mapped[list["Prerequisite"]] = relationship(
        back_populates="course",
        foreign_keys="Prerequisite.course_id",
    )
    required_for: Mapped[list["Prerequisite"]] = relationship(
        back_populates="prerequisite",
        foreign_keys="Prerequisite.prerequisite_id",
    )


class Prerequisite(Base):
    __tablename__ = "prerequisites"
    __table_args__ = (
        UniqueConstraint("course_id", "prerequisite_id", name="uq_prerequisites_course_prerequisite"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    course_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("courses.id"), nullable=False)
    prerequisite_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("courses.id"), nullable=False)

    course: Mapped[Course] = relationship(back_populates="prerequisites", foreign_keys=[course_id])
    prerequisite: Mapped[Course] = relationship(back_populates="required_for", foreign_keys=[prerequisite_id])


class Curriculum(Base):
    __tablename__ = "curriculum"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    year: Mapped[int] = mapped_column(Integer, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))
    created_at: Mapped[datetime] = mapped_column(nullable=False, server_default=func.now())

    curriculum_courses: Mapped[list["CurriculumCourse"]] = relationship(back_populates="curriculum")


class CurriculumCourse(Base):
    __tablename__ = "curriculum_courses"
    __table_args__ = (
        UniqueConstraint("curriculum_id", "course_id", name="uq_curriculum_courses_curriculum_course"),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    curriculum_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("curriculum.id"), nullable=False)
    course_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("courses.id"), nullable=False)
    semester: Mapped[int] = mapped_column(Integer, nullable=False)
    is_required: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))

    curriculum: Mapped[Curriculum] = relationship(back_populates="curriculum_courses")
    course: Mapped[Course] = relationship(back_populates="curriculum_courses")
