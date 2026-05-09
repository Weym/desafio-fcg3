"""Business logic for the Documents feature slice.

DocumentService: document request, listing, detail, and staff status update.
Implements DOCS-01 through DOCS-04 requirements with status lifecycle
enforcement (requested → processing → ready → delivered).
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any
from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from src.features.documents.models import Document
from src.features.documents.schemas import DocumentCreate, DocumentStatusUpdate
from src.shared.base_service import BaseService
from src.shared.exceptions import ConflictException, ValidationException
from src.shared.pagination import PaginationParams


# Ordered status lifecycle — index determines allowed transitions
_STATUS_ORDER = ["requested", "processing", "ready", "delivered"]


class DocumentService(BaseService[Document]):
    """Service layer for DOCS-01 through DOCS-04 requirements."""

    def __init__(self) -> None:
        super().__init__(Document)

    # ------------------------------------------------------------------
    # DOCS-01: List documents
    # ------------------------------------------------------------------

    async def list_documents(
        self,
        db: AsyncSession,
        params: PaginationParams,
        student_id: UUID | None = None,
        type: str | None = None,
        status: str | None = None,
    ) -> tuple[list[Document], int]:
        """List documents with pagination and optional filters.

        If student_id is provided, filter by that student.
        Students are forced to their own ID in the controller (IDOR-safe).
        """
        filters: dict[str, Any] = {}
        if student_id is not None:
            filters["student_id"] = student_id
        if type is not None:
            filters["type"] = type
        if status is not None:
            filters["status"] = status

        return await self.list(db, params, filters=filters)

    # ------------------------------------------------------------------
    # DOCS-02: Get document detail
    # ------------------------------------------------------------------

    async def get_document(
        self,
        db: AsyncSession,
        document_id: UUID,
    ) -> Document:
        """Get document by ID or raise 404.

        Returns document including file_url (null if not ready).
        """
        return await self.get_or_404(db, document_id, "document")

    # ------------------------------------------------------------------
    # DOCS-03: Create document request
    # ------------------------------------------------------------------

    async def create_document_request(
        self,
        db: AsyncSession,
        student_id: UUID,
        data: DocumentCreate,
    ) -> Document:
        """Create document request with status=requested.

        T-03-26: student_id always from authenticated user context,
        never from request body.
        """
        doc_data = {
            "student_id": student_id,
            "type": data.type,
            "status": "requested",
            "notes": data.notes,
        }
        return await self.create(db, doc_data)

    # ------------------------------------------------------------------
    # DOCS-04: Update document status (staff only)
    # ------------------------------------------------------------------

    async def update_document_status(
        self,
        db: AsyncSession,
        document_id: UUID,
        data: DocumentStatusUpdate,
    ) -> Document:
        """Update document status with lifecycle validation.

        Status transitions (T-03-25):
        - requested → processing → ready → delivered
        - No backwards movement allowed

        When status becomes "ready", file_url should be provided
        and completed_at is set to now().
        """
        document = await self.get_or_404(db, document_id, "document")

        # Validate status transition (T-03-25)
        current_idx = _STATUS_ORDER.index(document.status)
        new_idx = _STATUS_ORDER.index(data.status)

        if new_idx != current_idx + 1:
            raise ConflictException(
                code="TRANSICAO_STATUS_INVALIDA",
                message=(
                    f"Transicao de status invalida: '{document.status}' -> '{data.status}'. "
                    f"Status deve seguir a ordem: {' -> '.join(_STATUS_ORDER)}"
                ),
            )

        # Validate file_url when transitioning to "ready"
        if data.status == "ready" and not data.file_url:
            raise ValidationException(
                message="file_url e obrigatorio quando status e 'ready'",
                details=[
                    {"field": "file_url", "message": "file_url deve ser fornecido para status 'ready'"}
                ],
            )

        # Build update dict
        update_data: dict[str, Any] = {"status": data.status}

        if data.file_url is not None:
            update_data["file_url"] = data.file_url

        if data.status == "ready":
            update_data["completed_at"] = datetime.now(timezone.utc)

        return await self.update(db, document, update_data)


# Module-level singleton for convenience
document_service = DocumentService()
