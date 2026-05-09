"""Staff feature route registration.

Exposes staff_router for inclusion in the main FastAPI app:
- staff_router: /staff endpoints (STAFF-01: dashboard)

All route handlers are defined in controllers.py.
"""

from src.features.staff.controllers import staff_router

__all__ = ["staff_router"]
