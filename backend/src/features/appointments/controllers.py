"""Route handlers for the Appointments feature slice.

5 endpoints covering all APPT-* requirements:

Scheduling (dual-auth for MCP access):
- GET /scheduling/slots — available slots with date/resource filters (APPT-01)
- POST /scheduling/slots — staff creates slots from time range (APPT-STAFF-01)

Appointments (dual-auth for MCP access):
- POST /appointments — book a slot with SELECT FOR UPDATE (APPT-02)
- GET /appointments — list appointments with status filter (APPT-04)
- PUT /appointments/{id}/cancel — cancel appointment (APPT-03)
- POST /appointments/{id}/authorization — upload authorization file
"""

from __future__ import annotations

import asyncio
import os
import uuid as uuid_mod
from datetime import date
from uuid import UUID

from fastapi import APIRouter, Depends, Query, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession

from src.infrastructure.database import get_db_session
from src.features.notifications.services import notification_service
from src.shared.dependencies import (
    UserContext,
    get_current_user_or_service,
    require_staff,
)
from src.shared.exceptions import (
    ForbiddenException,
    NotFoundException,
    ValidationException,
)
from src.shared.pagination import PaginationParams, paginated_response

from src.features.appointments.schemas import (
    AppointmentCreate,
    AppointmentListItem,
    AppointmentResponse,
    SlotCreate,
    SlotResponse,
)
from src.features.appointments.services import appointment_service, slot_service


# ---------------------------------------------------------------------------
# Scheduling router (slots)
# ---------------------------------------------------------------------------

scheduling_router = APIRouter(
    prefix="/scheduling",
    tags=["scheduling"],
)


# ------------------------------------------------------------------
# APPT-01: GET /scheduling/slots — MCP-accessible
# ------------------------------------------------------------------

@scheduling_router.get("/slots", response_model=list[SlotResponse])
async def get_available_slots(
    date_from: date | None = Query(default=None, description="Start date filter (default: today)"),
    date_to: date | None = Query(default=None, description="End date filter (default: today + 7 days)"),
    staff_id: UUID | None = Query(default=None, description="Filter by staff/resource ID"),
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> list[SlotResponse]:
    """Get available scheduling slots.

    Per docs/api.md: ?date_from, ?date_to, ?staff_id. Defaults: today → today+7.
    staff_id maps to resource_id in DB (SM-03).
    """
    return await slot_service.get_available_slots(
        db,
        date_from=date_from,
        date_to=date_to,
        resource_id=staff_id,  # API uses staff_id, DB uses resource_id
    )


# ------------------------------------------------------------------
# APPT-STAFF-01: POST /scheduling/slots — staff only
# ------------------------------------------------------------------

@scheduling_router.post("/slots", response_model=list[SlotResponse], status_code=201)
async def create_slots(
    data: SlotCreate,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> list[SlotResponse]:
    """Create scheduling slots from time range and duration.

    T-03-29: require_staff prevents students from creating slots.
    Staff provides resource_id, date, start_time, end_time, slot_duration_minutes.
    """
    require_staff(user)

    slots = await slot_service.create_slots(db, data=data)
    await db.commit()
    return slots


# ---------------------------------------------------------------------------
# Appointments router
# ---------------------------------------------------------------------------

appointments_router = APIRouter(
    prefix="/appointments",
    tags=["appointments"],
)


# ------------------------------------------------------------------
# APPT-02: POST /appointments — MCP-accessible
# ------------------------------------------------------------------

@appointments_router.post("", response_model=AppointmentResponse, status_code=201)
async def book_appointment(
    data: AppointmentCreate,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> AppointmentResponse:
    """Book an appointment with pessimistic locking (D-10).

    T-03-27: SELECT FOR UPDATE prevents double-booking.
    student_id from authenticated user context (never from request body).
    """
    result = await appointment_service.book_appointment(
        db, student_id=user.id, data=data,
    )
    await db.commit()

    # FCM: Notify student that appointment was confirmed/booked
    async def _send_notification():
        async for fresh_db in get_db_session():
            try:
                await notification_service.notify_appointment_confirmed(
                    fresh_db, user.id, result.id
                )
            finally:
                await fresh_db.close()

    asyncio.create_task(_send_notification())

    return result


# ------------------------------------------------------------------
# APPT-04: GET /appointments — dual-auth
# ------------------------------------------------------------------

@appointments_router.get("", response_model=None)
async def list_appointments(
    params: PaginationParams = Depends(),
    student_id: UUID | None = Query(default=None, description="Filter by student ID"),
    status: str | None = Query(default=None, description="Filter by status"),
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> dict:
    """List appointments with pagination and filters (APPT-04).

    Students are auto-filtered to their own appointments (IDOR-safe).
    Staff can view all or filter by student_id.
    """
    # IDOR-safe: force students/service to see only their own appointments
    effective_student_id = student_id
    if user.role != "staff":
        effective_student_id = user.id

    items, total = await appointment_service.list_appointments(
        db,
        params,
        student_id=effective_student_id,
        status=status,
    )

    data = [item.model_dump() for item in items]
    return paginated_response(data, total, params)


# ------------------------------------------------------------------
# APPT-03: PUT /appointments/{id}/cancel — MCP-accessible
# ------------------------------------------------------------------

@appointments_router.put("/{appointment_id}/cancel", response_model=AppointmentResponse)
async def cancel_appointment(
    appointment_id: UUID,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> AppointmentResponse:
    """Cancel an appointment and release the slot.

    T-03-28: check_ownership — student can only cancel own appointments.
    Accepts X-Service-Token for MCP access.
    """
    result = await appointment_service.cancel_appointment(
        db,
        appointment_id=appointment_id,
        user_id=user.id,
        user_role=user.role,
    )
    await db.commit()
    return result


# ------------------------------------------------------------------
# POST /appointments/{id}/authorization — upload authorization file
# ------------------------------------------------------------------

ALLOWED_CONTENT_TYPES = {
    "application/pdf",
    "image/jpeg",
    "image/png",
}
MAX_FILE_SIZE = 5 * 1024 * 1024  # 5MB


@appointments_router.post("/{appointment_id}/authorization", response_model=AppointmentResponse)
async def upload_authorization(
    appointment_id: UUID,
    file: UploadFile = File(..., description="Authorization file (PDF, JPG, or PNG, max 5MB)"),
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> AppointmentResponse:
    """Upload an authorization file for an appointment.

    IDOR check: student can only upload to own appointment.
    Validates file type (PDF/JPG/PNG) and size (max 5MB).
    Saves to uploads/authorizations/{uuid}_{filename}.
    """
    # Validate content type
    if file.content_type not in ALLOWED_CONTENT_TYPES:
        raise ValidationException(
            message="Tipo de arquivo nao permitido. Envie PDF, JPG ou PNG.",
            details=[
                {
                    "field": "file",
                    "message": f"Content-Type '{file.content_type}' nao aceito. "
                    "Tipos permitidos: application/pdf, image/jpeg, image/png",
                }
            ],
        )

    # Read file content and validate size
    content = await file.read()
    if len(content) > MAX_FILE_SIZE:
        raise ValidationException(
            message="Arquivo excede o tamanho maximo de 5MB.",
            details=[
                {
                    "field": "file",
                    "message": f"Tamanho do arquivo: {len(content)} bytes. Maximo permitido: {MAX_FILE_SIZE} bytes",
                }
            ],
        )

    # Load appointment and check ownership (IDOR)
    result = await appointment_service.get_appointment_for_upload(
        db, appointment_id=appointment_id,
    )

    if result is None:
        raise NotFoundException("appointment", appointment_id)

    # IDOR check: student can only upload to own appointment
    if user.role != "staff" and result.student_id != user.id:
        raise ForbiddenException(
            "Voce nao tem permissao para enviar arquivos para este agendamento",
        )

    # Save file to disk
    upload_dir = "uploads/authorizations"
    os.makedirs(upload_dir, exist_ok=True)

    safe_filename = f"{uuid_mod.uuid4()}_{file.filename}"
    file_path = os.path.join(upload_dir, safe_filename)

    with open(file_path, "wb") as f:
        f.write(content)

    # Update appointment with file URL
    file_url = f"/uploads/authorizations/{safe_filename}"
    appointment_response = await appointment_service.set_authorization_file(
        db, appointment_id=appointment_id, file_url=file_url,
    )
    await db.commit()
    return appointment_response
