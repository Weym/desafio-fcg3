"""Courses & Curriculum feature route registration.

Exposes two routers for inclusion in the main FastAPI app:
- courses_router: /courses endpoints (COURSE-01, COURSE-02, COURSE-03)
- curriculum_router: /curriculum endpoints (CURR-01, CURR-02)

All route handlers are defined in controllers.py.
"""

from src.features.courses.controllers import courses_router, curriculum_router

__all__ = ["courses_router", "curriculum_router"]
