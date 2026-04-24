"""Pydantic request/response models for the Courses & Curriculum feature slice.

Shapes match docs/api.md exactly (Courses & Curriculum section).
"""

from __future__ import annotations

from uuid import UUID

from pydantic import BaseModel


# ---------------------------------------------------------------------------
# Course schemas
# ---------------------------------------------------------------------------

class CourseListItem(BaseModel):
    """Item in GET /courses paginated list."""

    id: UUID
    code: str
    name: str
    credits: int
    workload_hours: int

    model_config = {"from_attributes": True}


class PrerequisiteItem(BaseModel):
    """Direct prerequisite in course detail response."""

    id: UUID
    code: str
    name: str

    model_config = {"from_attributes": True}


class CourseDetail(BaseModel):
    """GET /courses/{id} — course detail with direct prerequisites.

    Matches docs/api.md response shape exactly.
    """

    id: UUID
    code: str
    name: str
    credits: int
    workload_hours: int
    description: str | None
    prerequisites: list[PrerequisiteItem]

    model_config = {"from_attributes": True}


class PrerequisiteTreeNode(BaseModel):
    """Recursive tree node for GET /courses/{id}/prerequisites (COURSE-03).

    Self-referential: each node has its own prerequisites list.
    Uses Pydantic model_rebuild() for forward reference resolution.
    """

    id: UUID
    code: str
    name: str
    prerequisites: list[PrerequisiteTreeNode] = []

    model_config = {"from_attributes": True}


# Resolve self-referential model
PrerequisiteTreeNode.model_rebuild()


# ---------------------------------------------------------------------------
# Curriculum schemas
# ---------------------------------------------------------------------------

class CurriculumCourseItem(BaseModel):
    """Course within a semester group in curriculum response."""

    id: UUID
    code: str
    name: str
    credits: int
    is_required: bool

    model_config = {"from_attributes": True}


class SemesterGroup(BaseModel):
    """Semester grouping with its courses."""

    semester: int
    courses: list[CurriculumCourseItem]


class CurriculumResponse(BaseModel):
    """GET /curriculum/active and GET /curriculum/{id} response.

    Matches docs/api.md response shape exactly.
    """

    id: UUID
    name: str
    year: int
    semesters: list[SemesterGroup]

    model_config = {"from_attributes": True}
