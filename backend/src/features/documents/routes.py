"""Documents feature route registration.

Exposes documents_router for inclusion in the main FastAPI app:
- POST /documents — create document request (DOCS-03)
- GET /documents — list documents with filters (DOCS-01)
- GET /documents/{id} — document detail (DOCS-02)
- PUT /documents/{id}/status — staff status update (DOCS-04)

All route handlers are defined in controllers.py.
"""

from src.features.documents.controllers import documents_router

__all__ = ["documents_router"]
