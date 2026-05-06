from __future__ import annotations

import uuid
from datetime import date, datetime, time

from sqlalchemy import Boolean, CheckConstraint, Date, DateTime, ForeignKey, Integer, String, Text, Time, func, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

try:
    from infrastructure.database import Base
except ModuleNotFoundError:  # pragma: no cover
    from src.infrastructure.database import Base


class Resource(Base):
    __tablename__ = "resources"
    __table_args__ = (
        CheckConstraint(
            "resource_type IN ('room', 'lab', 'equipment', 'auditorium', 'study_room', 'sports_court')",
            name="ck_resources_resource_type",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(100), nullable=False)
    resource_type: Mapped[str] = mapped_column(String(20), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    capacity: Mapped[int | None] = mapped_column(Integer)
    location: Mapped[str | None] = mapped_column(String(255))
    is_available: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))
    requires_authorization: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("false"))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=func.now())

    scheduling_slots: Mapped[list["SchedulingSlot"]] = relationship(back_populates="resource")


class SchedulingSlot(Base):
    __tablename__ = "scheduling_slots"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    resource_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("resources.id"), nullable=False)
    date: Mapped[date] = mapped_column(Date, nullable=False)
    start_time: Mapped[time] = mapped_column(Time, nullable=False)
    end_time: Mapped[time] = mapped_column(Time, nullable=False)
    is_available: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text("true"))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=func.now())

    resource: Mapped[Resource] = relationship(back_populates="scheduling_slots")
    appointments: Mapped[list["Appointment"]] = relationship(back_populates="slot")


class Appointment(Base):
    __tablename__ = "appointments"
    __table_args__ = (
        CheckConstraint(
            "status IN ('scheduled', 'completed', 'cancelled', 'no_show')",
            name="ck_appointments_status",
        ),
    )

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    student_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("students.id"), nullable=False)
    slot_id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), ForeignKey("scheduling_slots.id"), nullable=False)
    reason: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False, server_default=text("'scheduled'"))
    authorization_file_url: Mapped[str | None] = mapped_column(String(500))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, server_default=func.now())

    student: Mapped["Student"] = relationship(back_populates="appointments")
    slot: Mapped[SchedulingSlot] = relationship(back_populates="appointments")
