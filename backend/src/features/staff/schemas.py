"""Pydantic response models for the Staff Dashboard feature slice.

Shapes match docs/api.md Staff/CRM section exactly.
"""

from __future__ import annotations

from pydantic import BaseModel


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
