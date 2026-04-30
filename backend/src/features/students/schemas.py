"""Pydantic request/response models for the Students feature slice.

Shapes match docs/api.md exactly. All fields use snake_case per conventions.
"""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field, field_validator


# ---------------------------------------------------------------------------
# Request schemas
# ---------------------------------------------------------------------------

class StudentCreate(BaseModel):
    """POST /students — staff creates a student.

    enrollment_year is auto-calculated from current year (SM-04),
    not exposed in the API.
    """

    name: str = Field(..., min_length=1, max_length=255)
    email: EmailStr = Field(..., max_length=255)
    phone: str | None = Field(default=None, max_length=20)
    registration_number: str = Field(..., min_length=1, max_length=20)
    curriculum_id: UUID | None = None

    @field_validator("phone", mode="before")
    @classmethod
    def normalize_phone(cls, v: str | None) -> str | None:
        """Strip + prefix so phone is always stored without it (D-04)."""
        if v is not None:
            return v.lstrip("+")
        return v


class StudentUpdate(BaseModel):
    """PUT /students/{id} — partial update by staff."""

    name: str | None = Field(default=None, min_length=1, max_length=255)
    email: EmailStr | None = Field(default=None, max_length=255)
    phone: str | None = Field(default=None, max_length=20)
    semester: int | None = Field(default=None, ge=1)
    status: str | None = Field(default=None, pattern=r"^(active|inactive|graduated|locked)$")

    @field_validator("phone", mode="before")
    @classmethod
    def normalize_phone(cls, v: str | None) -> str | None:
        """Strip + prefix so phone is always stored without it (D-04)."""
        if v is not None:
            return v.lstrip("+")
        return v


# ---------------------------------------------------------------------------
# Response schemas
# ---------------------------------------------------------------------------

class StudentListItem(BaseModel):
    """Item in GET /students paginated list (staff only)."""

    id: UUID
    name: str
    email: str
    registration_number: str
    semester: int
    status: str

    model_config = {"from_attributes": True}


class StudentDetail(BaseModel):
    """Full student detail for GET /students/{id}."""

    id: UUID
    name: str
    email: str
    phone: str | None
    registration_number: str
    semester: int
    status: str
    enrollment_year: int
    curriculum_id: UUID | None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}


class AcademicSummaryResponse(BaseModel):
    """GET /students/{id}/academic-summary — matches docs/api.md shape."""

    student_id: UUID
    name: str
    semester: int
    completed_courses: int
    total_courses: int
    gpa: float
    status: str
    pending_documents: int
    next_appointment: datetime | None


class AvailableCourseItem(BaseModel):
    """Item in GET /students/{id}/available-courses list."""

    id: UUID
    code: str
    name: str
    credits: int
    prerequisites_met: bool
    semester: int

    model_config = {"from_attributes": True}
