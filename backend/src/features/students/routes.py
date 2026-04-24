"""Students feature route registration.

Exposes the students router for inclusion in the main FastAPI app.
All route handlers are defined in controllers.py.
"""

from src.features.students.controllers import router

__all__ = ["router"]
