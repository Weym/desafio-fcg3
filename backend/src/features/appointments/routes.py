"""Appointments feature route registration.

Exposes two routers for inclusion in the main FastAPI app:
- scheduling_router: /scheduling/slots endpoints (APPT-01, APPT-STAFF-01)
- appointments_router: /appointments endpoints (APPT-02, APPT-03, APPT-04)

All route handlers are defined in controllers.py.
"""

from src.features.appointments.controllers import appointments_router, scheduling_router

__all__ = ["appointments_router", "scheduling_router"]
