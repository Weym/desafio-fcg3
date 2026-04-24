"""Integration tests for require_service_token dependency.

Tests: no header (401), wrong token (401), correct token (200),
short/different-length token (401).
"""

import pytest
from src.infrastructure.config import get_settings
from tests.integration._service_token_probe import svc_router


@pytest.fixture
def app_with_svc(app):
    app.include_router(svc_router)
    yield app


@pytest.mark.asyncio
async def test_no_header_rejected(app_with_svc, client):
    r = await client.get("/_test/internal-ping")
    assert r.status_code == 401
    assert r.json()["detail"]["error"]["code"] == "missing_service_token"


@pytest.mark.asyncio
async def test_wrong_token_rejected(app_with_svc, client):
    r = await client.get("/_test/internal-ping", headers={"X-Service-Token": "wrong-token"})
    assert r.status_code == 401
    assert r.json()["detail"]["error"]["code"] == "invalid_service_token"


@pytest.mark.asyncio
async def test_correct_token_allowed(app_with_svc, client):
    settings = get_settings()
    r = await client.get("/_test/internal-ping", headers={"X-Service-Token": settings.mcp_service_token})
    assert r.status_code == 200
    assert r.json() == {"pong": True}


@pytest.mark.asyncio
async def test_different_length_token_rejected_safely(app_with_svc, client):
    # hmac.compare_digest handles differing lengths without leaking via exception
    r = await client.get("/_test/internal-ping", headers={"X-Service-Token": "x"})
    assert r.status_code == 401
    assert r.json()["detail"]["error"]["code"] == "invalid_service_token"
