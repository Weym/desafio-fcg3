"""Dashboard KPI aggregation service (STAFF-01).

Executes 6 efficient COUNT queries across all domain tables to build
the staff dashboard response. Uses SQLAlchemy ``func.count()`` with
filtered conditions for each KPI.
"""

from __future__ import annotations

from datetime import date

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from src.features.auth.models import Student
from src.features.chat.models import ChatSession
from src.features.documents.models import Document
from src.features.enrollment.models import Enrollment, EnrollmentPeriod
from src.features.scheduling.models import Appointment, SchedulingSlot
from src.features.staff.schemas import DashboardResponse, EnrollmentPeriodSummary


class DashboardService:
    """Aggregates KPIs from all feature domains into a single response."""

    async def get_dashboard(self, db: AsyncSession) -> DashboardResponse:
        """Build the staff dashboard with 6 KPIs (STAFF-01).

        Queries:
        a) total_students — active students
        b) active_enrollments — confirmed enrollments
        c) pending_documents — requested + processing documents
        d) upcoming_appointments — scheduled appointments with future slot date
        e) active_chat_sessions — active chat sessions
        f) enrollment_period — active period with days_remaining calculation
        """
        today = date.today()

        # a) Total active students
        total_students_q = select(func.count()).select_from(Student).where(
            Student.status == "active",
        )

        # b) Active (confirmed) enrollments
        active_enrollments_q = select(func.count()).select_from(Enrollment).where(
            Enrollment.status == "confirmed",
        )

        # c) Pending documents (requested or processing)
        pending_documents_q = select(func.count()).select_from(Document).where(
            Document.status.in_(["requested", "processing"]),
        )

        # d) Upcoming appointments: scheduled + slot date >= today
        upcoming_appointments_q = (
            select(func.count())
            .select_from(Appointment)
            .join(SchedulingSlot, Appointment.slot_id == SchedulingSlot.id)
            .where(
                Appointment.status == "scheduled",
                SchedulingSlot.date >= today,
            )
        )

        # e) Active chat sessions
        active_chat_sessions_q = select(func.count()).select_from(ChatSession).where(
            ChatSession.status == "active",
        )

        # Execute all count queries
        total_students_r = await db.execute(total_students_q)
        active_enrollments_r = await db.execute(active_enrollments_q)
        pending_documents_r = await db.execute(pending_documents_q)
        upcoming_appointments_r = await db.execute(upcoming_appointments_q)
        active_chat_sessions_r = await db.execute(active_chat_sessions_q)

        total_students = total_students_r.scalar_one()
        active_enrollments = active_enrollments_r.scalar_one()
        pending_documents = pending_documents_r.scalar_one()
        upcoming_appointments = upcoming_appointments_r.scalar_one()
        active_chat_sessions = active_chat_sessions_r.scalar_one()

        # f) Enrollment period: get active period, calculate days_remaining
        enrollment_period_summary = await self._get_enrollment_period_summary(db, today)

        return DashboardResponse(
            total_students=total_students,
            active_enrollments=active_enrollments,
            pending_documents=pending_documents,
            upcoming_appointments=upcoming_appointments,
            active_chat_sessions=active_chat_sessions,
            enrollment_period=enrollment_period_summary,
        )

    async def _get_enrollment_period_summary(
        self,
        db: AsyncSession,
        today: date,
    ) -> EnrollmentPeriodSummary | None:
        """Get the active enrollment period with days_remaining.

        Returns None if no active enrollment period exists.
        days_remaining is calculated as (end_date - today).days.
        """
        result = await db.execute(
            select(EnrollmentPeriod).where(EnrollmentPeriod.is_active.is_(True)).limit(1),
        )
        period = result.scalar_one_or_none()

        if period is None:
            return None

        days_remaining = (period.end_date - today).days

        return EnrollmentPeriodSummary(
            name=period.name,
            is_active=True,
            days_remaining=days_remaining,
        )


dashboard_service = DashboardService()
