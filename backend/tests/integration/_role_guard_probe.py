"""Test-only probe router for require_role integration tests.

Lives under tests/ — never imported by production code.
"""

from fastapi import APIRouter, Depends
from src.shared.auth import require_role, CurrentUser

probe_router = APIRouter(prefix="/_test")


@probe_router.get("/staff-only")
async def staff_only(user: CurrentUser = Depends(require_role("staff"))):
    return {"ok": True, "role": user.role}


@probe_router.get("/student-only")
async def student_only(user: CurrentUser = Depends(require_role("student"))):
    return {"ok": True, "role": user.role}
