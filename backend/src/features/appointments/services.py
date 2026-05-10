"""Business logic for the Appointments feature slice.

SlotService: slot creation from time range, available slot queries.
AppointmentService: booking with SELECT FOR UPDATE (D-10), cancellation, listing.

Implements APPT-01 through APPT-04 and APPT-STAFF-01 requirements.
"""

from __future__ import annotations

from datetime import date, datetime, time, timedelta, timezone
from typing import Any
from uuid import UUID

from sqlalchemy import and_, select, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import joinedload

from src.features.scheduling.models import Appointment, Resource, SchedulingSlot
from src.features.appointments.schemas import (
    AppointmentCreate,
    AppointmentListItem,
    AppointmentResponse,
    SlotCreate,
    SlotResponse,
    StaffInfo,
)
from src.shared.exceptions import (
    ConflictException,
    ForbiddenException,
    NotFoundException,
    ValidationException,
)
from src.shared.pagination import PaginationParams


def _time_from_str(s: str) -> time:
    """Parse HH:MM string to time object."""
    parts = s.split(":")
    return time(int(parts[0]), int(parts[1]))


def _time_to_str(t: time) -> str:
    """Format time object as HH:MM string."""
    return t.strftime("%H:%M")


def _build_slot_response(slot: SchedulingSlot) -> SlotResponse:
    """Build SlotResponse from a SchedulingSlot with loaded resource.

    Maps DB resource to API "staff" representation (SM-03).
    """
    return SlotResponse(
        id=slot.id,
        staff=StaffInfo(
            id=slot.resource.id,
            name=slot.resource.name,
        ),
        date=slot.date,
        start_time=_time_to_str(slot.start_time),
        end_time=_time_to_str(slot.end_time),
        is_available=slot.is_available,
    )


def _build_appointment_response(appointment: Appointment) -> AppointmentResponse:
    """Build AppointmentResponse from an Appointment with loaded slot+resource."""
    return AppointmentResponse(
        id=appointment.id,
        student_id=appointment.student_id,
        slot=_build_slot_response(appointment.slot),
        reason=appointment.reason,
        status=appointment.status,
        authorization_file_url=appointment.authorization_file_url,
        created_at=appointment.created_at,
    )


def _build_appointment_list_item(appointment: Appointment) -> AppointmentListItem:
    """Build AppointmentListItem from an Appointment with loaded slot+student."""
    student_name = None
    student_ra = None
    resource_name = None

    # Extract student data if relationship loaded
    if hasattr(appointment, "student") and appointment.student is not None:
        student_name = appointment.student.name
        student_ra = appointment.student.registration_number

    # Extract resource data from slot.resource
    if hasattr(appointment, "slot") and appointment.slot is not None:
        if hasattr(appointment.slot, "resource") and appointment.slot.resource is not None:
            resource_name = appointment.slot.resource.name

    return AppointmentListItem(
        id=appointment.id,
        slot_date=appointment.slot.date,
        slot_start_time=_time_to_str(appointment.slot.start_time),
        reason=appointment.reason,
        status=appointment.status,
        authorization_file_url=appointment.authorization_file_url,
        created_at=appointment.created_at,
        student_name=student_name,
        student_ra=student_ra,
        resource_name=resource_name,
    )


# ============================================================================
# SlotService
# ============================================================================

class SlotService:
    """Service layer for scheduling slot operations (APPT-01, APPT-STAFF-01)."""

    # ------------------------------------------------------------------
    # APPT-01: Get available slots
    # ------------------------------------------------------------------

    async def get_available_slots(
        self,
        db: AsyncSession,
        date_from: date | None = None,
        date_to: date | None = None,
        resource_id: UUID | None = None,
    ) -> list[SlotResponse]:
        """Query available scheduling slots with date and resource filters.

        Default: date_from=today, date_to=today+7 days (per docs/api.md).
        Joins resources table for staff/resource name in response.
        """
        today = date.today()
        if date_from is None:
            date_from = today
        if date_to is None:
            date_to = today + timedelta(days=7)

        query = (
            select(SchedulingSlot)
            .options(joinedload(SchedulingSlot.resource))
            .where(
                and_(
                    SchedulingSlot.is_available.is_(True),
                    SchedulingSlot.date >= date_from,
                    SchedulingSlot.date <= date_to,
                )
            )
            .order_by(SchedulingSlot.date, SchedulingSlot.start_time)
        )

        if resource_id is not None:
            query = query.where(SchedulingSlot.resource_id == resource_id)

        result = await db.execute(query)
        slots = list(result.scalars().unique().all())

        return [_build_slot_response(slot) for slot in slots]

    # ------------------------------------------------------------------
    # APPT-STAFF-01: Create scheduling slots from time range
    # ------------------------------------------------------------------

    async def create_slots(
        self,
        db: AsyncSession,
        data: SlotCreate,
    ) -> list[SlotResponse]:
        """Generate individual slots from time range and duration.

        Verifies resource exists. Checks for overlapping existing slots
        (P-08 from 03-RESEARCH.md). Generates slots from start_time to
        end_time with slot_duration_minutes intervals.

        Example: start=08:00, end=12:00, duration=30min → 8 slots
        (08:00-08:30, 08:30-09:00, ..., 11:30-12:00).
        """
        # Lock the resource row so concurrent slot creation requests for the
        # same resource cannot both pass the overlap check before insert.
        resource_result = await db.execute(
            select(Resource).where(Resource.id == data.resource_id).with_for_update()
        )
        resource = resource_result.scalar_one_or_none()
        if resource is None:
            raise NotFoundException("resource", data.resource_id)

        start = _time_from_str(data.start_time)
        end = _time_from_str(data.end_time)

        if start >= end:
            raise ValidationException(
                message="start_time deve ser anterior a end_time",
                details=[
                    {"field": "start_time", "message": "Horario de inicio deve ser anterior ao horario de fim"}
                ],
            )

        # P-08: Check for overlapping existing slots on same resource+date
        existing_result = await db.execute(
            select(SchedulingSlot).where(
                and_(
                    SchedulingSlot.resource_id == data.resource_id,
                    SchedulingSlot.date == data.date,
                    SchedulingSlot.start_time < end,
                    SchedulingSlot.end_time > start,
                )
            )
        )
        existing_slots = list(existing_result.scalars().all())
        if existing_slots:
            raise ConflictException(
                code="HORARIO_CONFLITANTE",
                message=(
                    f"Ja existem {len(existing_slots)} slot(s) no intervalo "
                    f"{data.start_time}-{data.end_time} para este recurso na data {data.date}. "
                    "Remova os slots existentes ou escolha outro intervalo."
                ),
            )

        # Generate individual slots
        duration = timedelta(minutes=data.slot_duration_minutes)
        created_slots: list[SchedulingSlot] = []
        current_dt = datetime.combine(data.date, start)
        end_dt = datetime.combine(data.date, end)

        if current_dt + duration > end_dt:
            raise ValidationException(
                message="Intervalo informado nao comporta nenhum slot",
                details=[
                    {
                        "field": "slot_duration_minutes",
                        "message": "A duracao precisa caber no intervalo informado",
                    }
                ],
            )

        while current_dt + duration <= end_dt:
            slot_start = current_dt.time()
            slot_end = (current_dt + duration).time()

            slot = SchedulingSlot(
                resource_id=data.resource_id,
                date=data.date,
                start_time=slot_start,
                end_time=slot_end,
                is_available=True,
            )
            db.add(slot)
            created_slots.append(slot)
            current_dt += duration

        await db.flush()

        # Refresh to get DB-generated fields and load resource relationship
        for slot in created_slots:
            await db.refresh(slot)

        # Build responses — resource is already known, attach manually
        responses: list[SlotResponse] = []
        for slot in created_slots:
            responses.append(SlotResponse(
                id=slot.id,
                staff=StaffInfo(id=resource.id, name=resource.name),
                date=slot.date,
                start_time=_time_to_str(slot.start_time),
                end_time=_time_to_str(slot.end_time),
                is_available=slot.is_available,
            ))

        return responses


# ============================================================================
# AppointmentService
# ============================================================================

class AppointmentService:
    """Service layer for appointment operations (APPT-02 through APPT-04)."""

    # ------------------------------------------------------------------
    # APPT-02: Book appointment with SELECT FOR UPDATE (D-10)
    # ------------------------------------------------------------------

    async def book_appointment(
        self,
        db: AsyncSession,
        student_id: UUID,
        data: AppointmentCreate,
    ) -> AppointmentResponse:
        """Book an appointment with pessimistic locking on the slot.

        D-10: SELECT FOR UPDATE prevents two students from booking the
        same slot simultaneously. The second concurrent request will block
        until the first transaction commits, then see is_available=False
        and get a 409 error.

        T-03-27: Race condition prevention via pessimistic locking.
        """
        # SELECT FOR UPDATE on the slot — pessimistic lock.
        # NOTE: We intentionally do NOT use joinedload here because
        # PostgreSQL forbids FOR UPDATE on the nullable side of an
        # OUTER JOIN.  Load the resource relationship separately after
        # the lock is acquired.
        result = await db.execute(
            select(SchedulingSlot)
            .where(SchedulingSlot.id == data.slot_id)
            .with_for_update()
        )
        slot = result.scalar_one_or_none()

        if slot is None:
            raise NotFoundException("slot", data.slot_id)

        if not slot.is_available:
            raise ConflictException(
                code="SLOT_JA_RESERVADO",
                message="Este horario ja foi reservado por outro aluno.",
            )

        # Eagerly load the resource relationship now (outside the FOR UPDATE)
        await db.refresh(slot, attribute_names=["resource"])

        # Mark slot as unavailable
        slot.is_available = False

        # Create appointment
        appointment = Appointment(
            student_id=student_id,
            slot_id=slot.id,
            reason=data.reason,
            status="scheduled",
        )
        db.add(appointment)
        await db.flush()
        await db.refresh(appointment)

        appointment_result = await db.execute(
            select(Appointment)
            .options(
                joinedload(Appointment.slot).joinedload(SchedulingSlot.resource),
            )
            .where(Appointment.id == appointment.id)
        )
        appointment = appointment_result.scalar_one()

        return _build_appointment_response(appointment)

    # ------------------------------------------------------------------
    # APPT-03: Cancel appointment
    # ------------------------------------------------------------------

    async def cancel_appointment(
        self,
        db: AsyncSession,
        appointment_id: UUID,
        user_id: UUID,
        user_role: str,
    ) -> AppointmentResponse:
        """Cancel an appointment and release the slot back.

        T-03-28: check_ownership — student can only cancel own appointments.
        Staff can cancel any appointment.
        Only appointments with status='scheduled' can be cancelled.
        """
        # Load appointment with slot and resource
        result = await db.execute(
            select(Appointment)
            .options(
                joinedload(Appointment.slot).joinedload(SchedulingSlot.resource),
            )
            .where(Appointment.id == appointment_id)
        )
        appointment = result.scalar_one_or_none()

        if appointment is None:
            raise NotFoundException("appointment", appointment_id)

        # T-03-28: ownership check — students can only cancel own appointments
        if user_role != "staff" and appointment.student_id != user_id:
            raise ForbiddenException(
                "Voce nao tem permissao para cancelar este agendamento",
            )

        # Can only cancel scheduled appointments
        if appointment.status != "scheduled":
            raise ConflictException(
                code="CANCELAMENTO_INVALIDO",
                message=(
                    f"Apenas agendamentos com status 'scheduled' podem ser cancelados. "
                    f"Status atual: '{appointment.status}'."
                ),
            )

        # Cancel appointment and release slot
        appointment.status = "cancelled"
        appointment.slot.is_available = True

        await db.flush()
        await db.refresh(appointment)

        return _build_appointment_response(appointment)

    # ------------------------------------------------------------------
    # Confirm appointment (scheduled → completed)
    # ------------------------------------------------------------------

    async def confirm_appointment(
        self,
        db: AsyncSession,
        appointment_id: UUID,
        user_id: UUID,
        user_role: str,
    ) -> AppointmentResponse:
        """Confirm an appointment (scheduled → completed). Staff only."""
        result = await db.execute(
            select(Appointment)
            .options(
                joinedload(Appointment.slot).joinedload(SchedulingSlot.resource),
            )
            .where(Appointment.id == appointment_id)
        )
        appointment = result.scalar_one_or_none()

        if appointment is None:
            raise NotFoundException("appointment", appointment_id)

        if user_role != "staff":
            raise ForbiddenException(
                "Apenas staff pode confirmar agendamentos",
            )

        if appointment.status != "scheduled":
            raise ConflictException(
                code="CONFIRMACAO_INVALIDA",
                message=(
                    f"Apenas agendamentos com status 'scheduled' podem ser confirmados. "
                    f"Status atual: '{appointment.status}'."
                ),
            )

        appointment.status = "completed"
        await db.flush()
        await db.refresh(appointment)

        return _build_appointment_response(appointment)

    # ------------------------------------------------------------------
    # APPT-04: List appointments
    # ------------------------------------------------------------------

    async def list_appointments(
        self,
        db: AsyncSession,
        params: PaginationParams,
        student_id: UUID | None = None,
        status: str | None = None,
    ) -> tuple[list[AppointmentListItem], int]:
        """List appointments with pagination and filters.

        If student_id is provided, filter by that student.
        Students are forced to their own ID in the controller (IDOR-safe).
        """
        query = (
            select(Appointment)
            .options(
                joinedload(Appointment.slot).joinedload(SchedulingSlot.resource),
                joinedload(Appointment.student),
            )
        )
        count_query = select(func.count()).select_from(Appointment)

        # Apply filters
        if student_id is not None:
            query = query.where(Appointment.student_id == student_id)
            count_query = count_query.where(Appointment.student_id == student_id)

        if status is not None:
            query = query.where(Appointment.status == status)
            count_query = count_query.where(Appointment.status == status)

        # Get total count
        total_result = await db.execute(count_query)
        total = total_result.scalar_one()

        # Apply sorting and pagination
        query = query.order_by(Appointment.created_at.desc())
        query = query.offset(params.offset).limit(params.limit)

        result = await db.execute(query)
        appointments = list(result.scalars().unique().all())

        items = [_build_appointment_list_item(a) for a in appointments]
        return items, total

    # ------------------------------------------------------------------
    # Upload authorization file helpers
    # ------------------------------------------------------------------

    async def get_appointment_for_upload(
        self,
        db: AsyncSession,
        appointment_id: UUID,
    ) -> Appointment | None:
        """Get an appointment by ID for file upload (without full response build)."""
        result = await db.execute(
            select(Appointment).where(Appointment.id == appointment_id)
        )
        return result.scalar_one_or_none()

    async def set_authorization_file(
        self,
        db: AsyncSession,
        appointment_id: UUID,
        file_url: str,
    ) -> AppointmentResponse:
        """Set the authorization_file_url on an appointment and return full response."""
        result = await db.execute(
            select(Appointment)
            .options(
                joinedload(Appointment.slot).joinedload(SchedulingSlot.resource),
            )
            .where(Appointment.id == appointment_id)
        )
        appointment = result.scalar_one()
        appointment.authorization_file_url = file_url
        await db.flush()
        await db.refresh(appointment)

        # Re-load with relationships
        result = await db.execute(
            select(Appointment)
            .options(
                joinedload(Appointment.slot).joinedload(SchedulingSlot.resource),
            )
            .where(Appointment.id == appointment_id)
        )
        appointment = result.scalar_one()
        return _build_appointment_response(appointment)


# Module-level singletons for convenience
slot_service = SlotService()
appointment_service = AppointmentService()
