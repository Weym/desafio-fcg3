"""Pydantic request/response models for the Appointments feature slice.

Shapes match docs/api.md exactly. All fields use snake_case per conventions.

API note: docs/api.md exposes "staff" in slot responses, but the DB uses
"resource". This schema layer maps resource → staff in the API response shape
(SM-03 from 03-RESEARCH.md).
"""

from __future__ import annotations

from datetime import date, datetime, time
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field


# ---------------------------------------------------------------------------
# Nested response models
# ---------------------------------------------------------------------------

class StaffInfo(BaseModel):
    """Nested staff/resource info inside slot responses.

    Maps DB resource to API "staff" representation per SM-03.
    """

    id: UUID
    name: str


# ---------------------------------------------------------------------------
# Request schemas
# ---------------------------------------------------------------------------

class SlotCreate(BaseModel):
    """POST /scheduling/slots — staff creates slots from time range (APPT-STAFF-01).

    Per docs/api.md: staff provides a date, start_time, end_time, and
    slot_duration_minutes. The system generates individual slots.
    resource_id is passed as a query param or body field by the staff.
    """

    resource_id: UUID = Field(description="Resource (staff member) to create slots for")
    date: date
    start_time: str = Field(
        description="Start time in HH:MM format",
        pattern=r"^\d{2}:\d{2}$",
    )
    end_time: str = Field(
        description="End time in HH:MM format",
        pattern=r"^\d{2}:\d{2}$",
    )
    slot_duration_minutes: int = Field(ge=5, le=480, description="Duration of each slot in minutes")


class AppointmentCreate(BaseModel):
    """POST /appointments — student books a slot (APPT-02).

    Per docs/api.md: student provides slot_id and reason.
    student_id comes from authenticated user context (never from body).
    """

    slot_id: UUID
    reason: str = Field(min_length=1, max_length=1000)


# ---------------------------------------------------------------------------
# Response schemas
# ---------------------------------------------------------------------------

class SlotResponse(BaseModel):
    """Response for scheduling slot (APPT-01).

    Per docs/api.md: maps resource to "staff" in API response.
    """

    id: UUID
    staff: StaffInfo
    date: date
    start_time: str
    end_time: str
    is_available: bool

    model_config = {"from_attributes": True}


class AppointmentResponse(BaseModel):
    """Response for appointment detail (APPT-02, APPT-03).

    Includes full slot info for detail views.
    """

    id: UUID
    student_id: UUID
    slot: SlotResponse
    reason: str
    status: str
    authorization_file_url: str | None = None
    created_at: datetime

    model_config = {"from_attributes": True}


class AppointmentListItem(BaseModel):
    """Response for appointment list items (APPT-04).

    Lighter representation for list endpoints — slot info inlined.
    """

    id: UUID
    slot_date: date
    slot_start_time: str
    reason: str
    status: str
    authorization_file_url: str | None = None
    created_at: datetime

    model_config = {"from_attributes": True}
