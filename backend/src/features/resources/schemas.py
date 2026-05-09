"""Pydantic request/response models for the Resources feature slice.

Covers CRUD operations on resources (rooms, labs, equipment, auditoriums,
study rooms, sports courts). Staff can manage; students can list available.
"""

from __future__ import annotations

from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, Field


# ---------------------------------------------------------------------------
# Request schemas
# ---------------------------------------------------------------------------

RESOURCE_TYPES = Literal["room", "lab", "equipment", "auditorium", "study_room", "sports_court"]


class ResourceCreate(BaseModel):
    """POST /resources — staff creates a new resource."""

    name: str = Field(min_length=1, max_length=100, description="Resource name")
    resource_type: RESOURCE_TYPES = Field(description="Type of resource")
    description: str | None = Field(default=None, max_length=2000, description="Resource description")
    capacity: int | None = Field(default=None, ge=1, description="Maximum capacity")
    location: str | None = Field(default=None, max_length=255, description="Physical location")
    is_available: bool = Field(default=True, description="Whether the resource is available for booking")
    requires_authorization: bool = Field(default=False, description="Whether booking requires authorization file")


class ResourceUpdate(BaseModel):
    """PUT /resources/{id} — staff updates a resource."""

    name: str | None = Field(default=None, min_length=1, max_length=100)
    resource_type: RESOURCE_TYPES | None = Field(default=None)
    description: str | None = Field(default=None, max_length=2000)
    capacity: int | None = Field(default=None, ge=1)
    location: str | None = Field(default=None, max_length=255)
    is_available: bool | None = Field(default=None)
    requires_authorization: bool | None = Field(default=None)


# ---------------------------------------------------------------------------
# Response schemas
# ---------------------------------------------------------------------------

class ResourceResponse(BaseModel):
    """Single resource detail response."""

    id: UUID
    name: str
    resource_type: str
    description: str | None
    capacity: int | None
    location: str | None
    is_available: bool
    requires_authorization: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class ResourceListResponse(BaseModel):
    """Paginated list of resources."""

    data: list[ResourceResponse]
    pagination: dict
