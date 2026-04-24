"""Grades feature route registration.

Exposes the grades_router for inclusion in the main FastAPI app.
All route handlers are defined in controllers.py.
"""

from src.features.grades.controllers import router as grades_router

__all__ = ["grades_router"]
