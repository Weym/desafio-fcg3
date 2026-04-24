"""Route handlers for the Documents feature slice.

4 endpoints covering all DOCS-* requirements:

Student-facing (dual-auth for MCP access):
- POST /documents — create document request (DOCS-03)
- GET /documents — list documents with type/status filters (DOCS-01)
- GET /documents/{id} — document detail with file_url (DOCS-02)

Staff:
- PUT /documents/{id}/status — update status and attach file URL (DOCS-04)
"""

from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from src.infrastructure.database import get_db_session
from src.shared.dependencies import (
    UserContext,
    check_ownership,
    get_current_user_or_service,
    require_staff,
)
from src.shared.pagination import PaginationParams, paginated_response

from src.features.documents.schemas import (
    DocumentCreate,
    DocumentResponse,
    DocumentStatusUpdate,
)
from src.features.documents.services import document_service


documents_router = APIRouter(
    prefix="/documents",
    tags=["documents"],
)


# ------------------------------------------------------------------
# DOCS-03: POST /documents — MCP-accessible
# ------------------------------------------------------------------

@documents_router.post("", response_model=DocumentResponse, status_code=201)
async def create_document(
    data: DocumentCreate,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> DocumentResponse:
    """Create document request with status=requested.

    T-03-26: student_id always from authenticated user context,
    never from request body. Accepts X-Service-Token for MCP access.
    """
    document = await document_service.create_document_request(
        db, student_id=user.id, data=data,
    )
    await db.commit()
    return DocumentResponse.model_validate(document)


# ------------------------------------------------------------------
# DOCS-01: GET /documents — dual-auth
# ------------------------------------------------------------------

@documents_router.get("", response_model=None)
async def list_documents(
    params: PaginationParams = Depends(),
    student_id: UUID | None = Query(default=None, description="Filter by student ID"),
    type: str | None = Query(default=None, description="Filter by document type"),
    status: str | None = Query(default=None, description="Filter by status"),
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> dict:
    """List documents with pagination and filters (DOCS-01).

    T-03-24: Students are auto-filtered to their own documents (IDOR-safe).
    Staff can view all or filter by student_id.
    """
    # IDOR-safe: force student/service to see only their own documents
    effective_student_id = student_id
    if user.role != "staff":
        effective_student_id = user.id

    items, total = await document_service.list_documents(
        db,
        params,
        student_id=effective_student_id,
        type=type,
        status=status,
    )

    data = [DocumentResponse.model_validate(item).model_dump() for item in items]
    return paginated_response(data, total, params)


# ------------------------------------------------------------------
# DOCS-02: GET /documents/{id} — MCP-accessible
# ------------------------------------------------------------------

@documents_router.get("/{document_id}", response_model=DocumentResponse)
async def get_document(
    document_id: UUID,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> DocumentResponse:
    """Get document detail with file_url when status=ready (DOCS-02).

    T-03-24: check_ownership for students/service — only own documents.
    Accepts X-Service-Token for MCP access.
    """
    document = await document_service.get_document(db, document_id)
    check_ownership(document.student_id, user)
    return DocumentResponse.model_validate(document)


# ------------------------------------------------------------------
# DOCS-04: PUT /documents/{id}/status — staff only
# ------------------------------------------------------------------

@documents_router.put("/{document_id}/status", response_model=DocumentResponse)
async def update_document_status(
    document_id: UUID,
    data: DocumentStatusUpdate,
    user: UserContext = Depends(get_current_user_or_service),
    db: AsyncSession = Depends(get_db_session),
) -> DocumentResponse:
    """Update document status and optionally attach file URL (DOCS-04).

    T-03-25: Status transition validation prevents backwards movement.
    Staff only — students cannot change document status.
    """
    require_staff(user)

    document = await document_service.update_document_status(
        db, document_id=document_id, data=data,
    )
    await db.commit()
    return DocumentResponse.model_validate(document)
