"""Test-only probe router for require_service_token integration tests.

Lives under tests/ — never imported by production code.
"""

from fastapi import APIRouter, Depends
from src.shared.auth import require_service_token

svc_router = APIRouter(prefix="/_test")


@svc_router.get("/internal-ping", dependencies=[Depends(require_service_token)])
async def internal_ping():
    return {"pong": True}
