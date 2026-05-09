"""Staff feature services (STAFF-01, ROLE-03, ROLE-07).

Contains:
- DashboardService: KPI aggregation for GET /staff/dashboard
- StaffManagementService: CRUD operations for staff members (provider only)
"""

from __future__ import annotations

import re
from datetime import date
from uuid import UUID

from sqlalchemy import and_, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from src.features.auth.models import Staff, Student
from src.features.chat.models import ChatSession
from src.features.documents.models import Document
from src.features.enrollment.models import Enrollment, EnrollmentPeriod
from src.features.scheduling.models import Appointment, SchedulingSlot
from src.features.staff.schemas import DashboardResponse, EnrollmentPeriodSummary, StaffCreate, StaffUpdate
from src.shared.base_service import BaseService
from src.shared.exceptions import ConflictException, ForbiddenException, NotFoundException
from src.shared.pagination import PaginationParams


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
            select(EnrollmentPeriod)
            .where(
                and_(
                    EnrollmentPeriod.is_active.is_(True),
                    EnrollmentPeriod.start_date <= today,
                    EnrollmentPeriod.end_date >= today,
                ),
            )
            .limit(1),
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


# ---------------------------------------------------------------------------
# ROLE-03, ROLE-07: Staff Management CRUD (provider only)
# ---------------------------------------------------------------------------


def _escape_like(value: str) -> str:
    """Escape SQL LIKE wildcards for literal matching."""
    return re.sub(r"([%_\\])", r"\\\1", value)


class StaffManagementService(BaseService[Staff]):
    """Service layer for staff CRUD operations (ROLE-03, ROLE-07).

    All methods are called by provider-only endpoints.
    Provider record is hidden from list results (D-17).
    Self-operation is blocked on update and delete (D-21).
    """

    def __init__(self) -> None:
        super().__init__(Staff)

    # ------------------------------------------------------------------
    # List staff (D-16, D-17)
    # ------------------------------------------------------------------

    async def list_staff(
        self,
        db: AsyncSession,
        params: PaginationParams,
        search: str | None = None,
        status: str | None = None,
    ) -> tuple[list[Staff], int]:
        """List staff members with pagination, search, and status filter.

        Always filters WHERE role != 'provider' (D-17 — provider hidden from list).
        Search: ILIKE on name OR email columns.
        """
        from sqlalchemy import asc, desc

        # Base queries — always exclude provider from results (D-17)
        query = select(Staff).where(Staff.role != "provider")
        count_query = select(func.count()).select_from(Staff).where(Staff.role != "provider")

        # Apply search filter (ILIKE on name OR email)
        if search:
            search_pattern = f"%{_escape_like(search)}%"
            search_filter = or_(
                Staff.name.ilike(search_pattern),
                Staff.email.ilike(search_pattern),
            )
            query = query.where(search_filter)
            count_query = count_query.where(search_filter)

        # Apply status equality filter
        if status is not None:
            query = query.where(Staff.status == status)
            count_query = count_query.where(Staff.status == status)

        # Total count
        total_result = await db.execute(count_query)
        total = total_result.scalar_one()

        # Sorting (validated by BaseService)
        sort_column = self._get_sort_column(params.sort_by)
        order_func = asc if params.order == "asc" else desc
        query = query.order_by(order_func(sort_column))

        # Pagination
        query = query.offset(params.offset).limit(params.limit)

        result = await db.execute(query)
        items = list(result.scalars().all())

        return items, total

    # ------------------------------------------------------------------
    # Get staff member (D-16)
    # ------------------------------------------------------------------

    async def get_staff_member(self, db: AsyncSession, staff_id: UUID) -> Staff:
        """Get staff member by ID or raise 404.

        Hides provider records (D-17) — consistent with list filtering.
        """
        staff = await self.get_or_404(db, staff_id, "staff")
        if staff.role == "provider":
            raise NotFoundException("staff", staff_id)
        return staff

    # ------------------------------------------------------------------
    # Create staff (D-18, D-19)
    # ------------------------------------------------------------------

    async def create_staff(
        self,
        db: AsyncSession,
        data: StaffCreate,
    ) -> Staff:
        """Create a new staff member.

        - Email uniqueness enforced (T-21-10)
        - Role restricted to staff/coordinator/secretary by schema (T-21-06)
        - Status defaults to 'active'
        - Per D-19: email in staff table = can do OTP login immediately
        """
        # Check email uniqueness
        existing = await db.execute(
            select(Staff.id).where(Staff.email == data.email)
        )
        if existing.scalar_one_or_none() is not None:
            raise ConflictException(
                code="EMAIL_JA_CADASTRADO",
                message="Email ja esta em uso",
            )

        # Build staff data — status defaults to 'active'
        staff_data = data.model_dump()
        staff_data["status"] = "active"

        return await self.create(db, staff_data)

    # ------------------------------------------------------------------
    # Update staff (D-16, D-21)
    # ------------------------------------------------------------------

    async def update_staff(
        self,
        db: AsyncSession,
        staff_id: UUID,
        data: StaffUpdate,
        current_user_id: UUID,
    ) -> Staff:
        """Update staff member fields (partial).

        Blocks self-edit (D-21, T-21-08).
        Checks email uniqueness if email is changed (T-21-10).
        """
        # D-21: Provider cannot edit own record
        if staff_id == current_user_id:
            raise ForbiddenException(
                "Provider nao pode editar o proprio registro",
            )

        staff = await self.get_or_404(db, staff_id, "staff")
        update_data = data.model_dump(exclude_unset=True)

        # Check email uniqueness if email is being changed
        if "email" in update_data and update_data["email"] is not None:
            existing = await db.execute(
                select(Staff.id).where(
                    Staff.email == update_data["email"],
                    Staff.id != staff_id,
                )
            )
            if existing.scalar_one_or_none() is not None:
                raise ConflictException(
                    code="EMAIL_JA_CADASTRADO",
                    message="Email ja esta em uso",
                )

        return await self.update(db, staff, update_data)

    # ------------------------------------------------------------------
    # Soft delete staff (D-20, D-21)
    # ------------------------------------------------------------------

    async def soft_delete_staff(
        self,
        db: AsyncSession,
        staff_id: UUID,
        current_user_id: UUID,
    ) -> None:
        """Soft-delete (deactivate) a staff member.

        Sets status='inactive'. Blocks self-deactivation (D-21, T-21-08).
        """
        # D-21: Provider cannot deactivate own record
        if staff_id == current_user_id:
            raise ForbiddenException(
                "Provider nao pode desativar o proprio registro",
            )

        staff = await self.get_or_404(db, staff_id, "staff")
        staff.status = "inactive"
        await db.flush()


staff_management_service = StaffManagementService()
