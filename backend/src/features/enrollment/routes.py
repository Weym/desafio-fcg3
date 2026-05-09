"""Enrollment feature route registration.

Exposes three routers for inclusion in the main FastAPI app:
- enrollment_periods_router: /enrollment-periods endpoints (ENROLL-01)
- enrollments_router: /enrollments endpoints (ENROLL-02 through ENROLL-07)
- staff_enrollment_router: /staff/enrollment-periods endpoints (ENROLL-STAFF-01/02/03)

All route handlers are defined in controllers.py.
"""

from src.features.enrollment.controllers import (
    enrollment_periods_router,
    enrollments_router,
    staff_enrollment_router,
)

__all__ = [
    "enrollment_periods_router",
    "enrollments_router",
    "staff_enrollment_router",
]
