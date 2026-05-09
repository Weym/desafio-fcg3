"""Pydantic request/response models for the Grades feature slice.

Shapes match docs/api.md exactly. All fields use snake_case per conventions.
"""

from __future__ import annotations

from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, Field


# ---------------------------------------------------------------------------
# Nested schemas
# ---------------------------------------------------------------------------

class CourseInfo(BaseModel):
    """Nested course info for grade responses (matches docs/api.md shape)."""

    code: str
    name: str


# ---------------------------------------------------------------------------
# Request schemas
# ---------------------------------------------------------------------------

class GradeUpdate(BaseModel):
    """PUT /grades/{id} — staff posts/updates grades (N1, N2).

    grade_final is auto-calculated server-side (T-03-22: not settable by API).
    """

    grade_1: float | None = Field(default=None, ge=0, le=10)
    grade_2: float | None = Field(default=None, ge=0, le=10)


# ---------------------------------------------------------------------------
# Response schemas
# ---------------------------------------------------------------------------

class GradeResponse(BaseModel):
    """Item in GET /students/{id}/grades response — matches docs/api.md."""

    id: UUID
    course: CourseInfo
    semester_year: str
    grade_1: float | None
    grade_2: float | None
    grade_final: float | None
    status: str

    model_config = {"from_attributes": True}


class TranscriptEntry(BaseModel):
    """Single entry in the transcript response."""

    course_code: str
    course_name: str
    semester_year: str
    grade_final: float | None
    status: str
    credits: int


class TranscriptResponse(BaseModel):
    """GET /students/{id}/transcript — full academic history with CRA."""

    student_id: UUID
    student_name: str
    entries: list[TranscriptEntry]
    cra: float
