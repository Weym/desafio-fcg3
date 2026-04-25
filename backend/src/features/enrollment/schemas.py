"""Pydantic request/response models for the Enrollment feature slice.

Shapes match docs/api.md exactly. All fields use snake_case per conventions.
"""

from __future__ import annotations

from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field


# ---------------------------------------------------------------------------
# Enrollment Period schemas
# ---------------------------------------------------------------------------

class EnrollmentPeriodCreate(BaseModel):
    """POST /staff/enrollment-periods — staff creates a period (ENROLL-STAFF-01)."""

    name: str = Field(..., min_length=1, max_length=100)
    type: str = Field(..., pattern=r"^(enrollment|re_enrollment)$")
    start_date: date
    end_date: date
    semester_year: str = Field(..., min_length=1, max_length=10)
    is_active: bool = False


class EnrollmentPeriodUpdate(BaseModel):
    """PUT /staff/enrollment-periods/{id} — staff updates a period (ENROLL-STAFF-02)."""

    name: str | None = Field(default=None, min_length=1, max_length=100)
    type: str | None = Field(default=None, pattern=r"^(enrollment|re_enrollment)$")
    start_date: date | None = None
    end_date: date | None = None
    semester_year: str | None = Field(default=None, min_length=1, max_length=10)
    is_active: bool | None = None


class EnrollmentPeriodResponse(BaseModel):
    """Response for enrollment period endpoints."""

    id: UUID
    name: str
    type: str
    start_date: date
    end_date: date
    semester_year: str
    is_active: bool

    model_config = {"from_attributes": True}


# ---------------------------------------------------------------------------
# Enrollment schemas
# ---------------------------------------------------------------------------

class EnrollmentCreate(BaseModel):
    """POST /enrollments — student creates enrollment (ENROLL-02)."""

    enrollment_period_id: UUID
    course_ids: list[UUID] = Field(..., min_length=1)


class EnrollmentUpdate(BaseModel):
    """PUT /enrollments/{id} — student modifies courses (ENROLL-04)."""

    course_ids: list[UUID] = Field(..., min_length=1)


class EnrollmentCourseItem(BaseModel):
    """Course within an enrollment response."""

    id: UUID
    course_id: UUID
    code: str
    name: str
    status: str

    model_config = {"from_attributes": True}


class EnrollmentResponse(BaseModel):
    """Response for enrollment create/detail/confirm."""

    id: UUID
    status: str
    courses: list[EnrollmentCourseItem]
    created_at: datetime
    confirmed_at: datetime | None = None

    model_config = {"from_attributes": True}


class EnrollmentListItem(BaseModel):
    """Item in GET /enrollments paginated list (ENROLL-07)."""

    id: UUID
    status: str
    semester_year: str
    course_count: int
    created_at: datetime

    model_config = {"from_attributes": True}
