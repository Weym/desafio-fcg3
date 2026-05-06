"""Resources feature route registration.

Exposes:
- resources_router: /resources endpoints (CRUD)

All route handlers are defined in controllers.py.
"""

from src.features.resources.controllers import resources_router

__all__ = ["resources_router"]
