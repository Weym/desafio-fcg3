"""Regression tests for student academic summary appointment semantics."""

from __future__ import annotations

import uuid
from datetime import date, datetime, time, timedelta, timezone
from unittest.mock import AsyncMock

import pytest

from src.features.grades.services import grade_service
from src.features.scheduling.models import Appointment, Resource, SchedulingSlot
from src.features.students.services import student_service


@pytest.mark.asyncio
async def test_academic_summary_uses_earliest_slot_datetime_for_next_appointment(
    db_session,
    seed_users,
    monkeypatch,
):
    """STU-06 returns the earliest scheduled slot datetime, not created_at."""
    student = seed_users["student"]
    monkeypatch.setattr(
        grade_service,
        "get_cra_for_student",
        AsyncMock(return_value=0.0),
    )

    resource = Resource(
        id=uuid.uuid4(),
        name="Atendimento Secretaria",
        resource_type="room",
        capacity=1,
        location="Bloco A",
        is_available=True,
    )

    earlier_slot = SchedulingSlot(
        id=uuid.uuid4(),
        resource_id=resource.id,
        date=date.today() + timedelta(days=1),
        start_time=time(8, 0),
        end_time=time(8, 30),
        is_available=False,
    )
    later_slot = SchedulingSlot(
        id=uuid.uuid4(),
        resource_id=resource.id,
        date=date.today() + timedelta(days=2),
        start_time=time(9, 30),
        end_time=time(10, 0),
        is_available=False,
    )

    later_created_at = datetime(2026, 4, 25, 15, 0, tzinfo=timezone.utc)
    earlier_created_at = datetime(2026, 4, 25, 18, 0, tzinfo=timezone.utc)

    db_session.add_all([
        resource,
        earlier_slot,
        later_slot,
        Appointment(
            id=uuid.uuid4(),
            student_id=student.id,
            slot_id=earlier_slot.id,
            reason="Renovar matricula",
            status="scheduled",
            created_at=earlier_created_at,
        ),
        Appointment(
            id=uuid.uuid4(),
            student_id=student.id,
            slot_id=later_slot.id,
            reason="Atualizar cadastro",
            status="scheduled",
            created_at=later_created_at,
        ),
    ])
    await db_session.commit()

    summary = await student_service.get_academic_summary(db_session, student.id)

    expected_next_appointment = datetime.combine(
        earlier_slot.date,
        earlier_slot.start_time,
        tzinfo=timezone.utc,
    )
    assert summary.next_appointment == expected_next_appointment
    assert summary.next_appointment not in {earlier_created_at, later_created_at}


@pytest.mark.asyncio
async def test_academic_summary_returns_none_when_no_future_scheduled_slot(
    db_session,
    seed_users,
    monkeypatch,
):
    """STU-06 returns None when the student has no upcoming scheduled slot."""
    student = seed_users["student"]
    monkeypatch.setattr(
        grade_service,
        "get_cra_for_student",
        AsyncMock(return_value=0.0),
    )

    summary = await student_service.get_academic_summary(db_session, student.id)

    assert summary.next_appointment is None
