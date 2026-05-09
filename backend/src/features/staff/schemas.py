"""Pydantic request/response models for the Staff feature slice.

Includes:
- Dashboard schemas (STAFF-01)
- Staff CRUD schemas (ROLE-03, ROLE-07)

Shapes match docs/api.md Staff/CRM section exactly.
"""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field


# ---------------------------------------------------------------------------
# Dashboard schemas (existing)
# ---------------------------------------------------------------------------


class EnrollmentPeriodSummary(BaseModel):
    """Nested enrollment period info inside the dashboard response.

    days_remaining is None when no active enrollment period exists.
    """

    name: str
    is_active: bool
    days_remaining: int | None = None


class DashboardResponse(BaseModel):
    """GET /staff/dashboard — KPI aggregation response (STAFF-01).

    Matches the response shape defined in docs/api.md exactly:
    total_students, active_enrollments, pending_documents,
    upcoming_appointments, active_chat_sessions, enrollment_period.
    """

    total_students: int
    active_enrollments: int
    pending_documents: int
    upcoming_appointments: int
    active_chat_sessions: int
    enrollment_period: EnrollmentPeriodSummary | None = None


# ---------------------------------------------------------------------------
# Staff CRUD request schemas (ROLE-03, ROLE-07)
# ---------------------------------------------------------------------------


class StaffCreate(BaseModel):
    """POST /staff/members — provider creates a staff member (ROLE-07).

    role only accepts 'staff', 'coordinator', 'secretary' — never 'provider' (D-18).
    """

    name: str = Field(..., min_length=1, max_length=255)
    email: EmailStr = Field(..., max_length=255)
    phone: str | None = Field(default=None, max_length=20)
    role: str = Field(..., pattern=r"^(staff|coordinator|secretary)$")
    position: str | None = Field(default=None, max_length=100)
    work_schedule: str | None = Field(default=None, max_length=500)


class StaffUpdate(BaseModel):
    """PUT /staff/members/{id} — provider updates a staff member."""

    name: str | None = Field(default=None, min_length=1, max_length=255)
    email: EmailStr | None = Field(default=None, max_length=255)
    phone: str | None = Field(default=None, max_length=20)
    role: str | None = Field(default=None, pattern=r"^(staff|coordinator|secretary)$")
    position: str | None = Field(default=None, max_length=100)
    work_schedule: str | None = Field(default=None, max_length=500)
    status: str | None = Field(default=None, pattern=r"^(active|inactive)$")


# ---------------------------------------------------------------------------
# Staff CRUD response schemas (ROLE-03, ROLE-07)
# ---------------------------------------------------------------------------


class StaffListItem(BaseModel):
    """Item in GET /staff/members paginated list (provider only)."""

    id: UUID
    name: str
    email: str
    phone: str | None
    role: str
    status: str
    position: str | None

    model_config = {"from_attributes": True}


class StaffDetail(BaseModel):
    """Full staff detail for GET /staff/members/{id} and POST/PUT responses."""

    id: UUID
    name: str
    email: str
    phone: str | None
    role: str
    status: str
    position: str | None
    work_schedule: str | None
    created_at: datetime
    updated_at: datetime

    model_config = {"from_attributes": True}
