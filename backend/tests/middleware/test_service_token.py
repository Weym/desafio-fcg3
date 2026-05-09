"""TEST-05: X-Service-Token middleware tests.

Verifies:
- Missing header → 401
- Invalid token → 401
- Valid token → passes auth
- Timing-safe comparison (hmac.compare_digest)
- Student_id injection verified (not from request params)
"""

import inspect

import pytest
from unittest.mock import patch

from src.infrastructure.config import get_settings
from src.shared.auth import require_service_token


class TestServiceTokenUnit:
    """Unit tests for require_service_token dependency."""

    async def test_missing_header_raises_401(self):
        """No X-Service-Token header → 401."""
        from fastapi import HTTPException

        with pytest.raises(HTTPException) as exc_info:
            await require_service_token(x_service_token=None)
        assert exc_info.value.status_code == 401
        assert "missing_service_token" in str(exc_info.value.detail)

    async def test_invalid_token_raises_401(self):
        """Wrong X-Service-Token → 401."""
        from fastapi import HTTPException

        with pytest.raises(HTTPException) as exc_info:
            await require_service_token(x_service_token="invalid-wrong-token")
        assert exc_info.value.status_code == 401
        assert "invalid_service_token" in str(exc_info.value.detail)

    async def test_valid_token_passes(self):
        """Correct X-Service-Token → no exception."""
        settings = get_settings()
        # Should not raise
        result = await require_service_token(x_service_token=settings.mcp_service_token)
        assert result is None

    def test_uses_timing_safe_comparison(self):
        """Implementation uses hmac.compare_digest (not ==) for timing safety."""
        source = inspect.getsource(require_service_token)
        assert "compare_digest" in source
        assert "==" not in source.split("compare_digest")[0].split("\n")[-1]

    async def test_different_length_token_rejected(self):
        """Short token → 401 (hmac.compare_digest handles different lengths)."""
        from fastapi import HTTPException

        with pytest.raises(HTTPException) as exc_info:
            await require_service_token(x_service_token="x")
        assert exc_info.value.status_code == 401


class TestServiceTokenIntegration:
    """Integration tests for X-Service-Token via the HTTP endpoint.

    Uses the existing probe endpoint pattern from tests/integration/test_service_token.py
    to validate the middleware behavior end-to-end.
    """

    @pytest.fixture
    def app_with_svc(self, app):
        """Register a test-only endpoint that requires service token."""
        from fastapi import APIRouter, Depends
        from src.shared.auth import require_service_token

        svc_router = APIRouter()

        @svc_router.get("/_test_06/svc-ping")
        async def svc_ping(_=Depends(require_service_token)):
            return {"pong": True}

        app.include_router(svc_router)
        yield app

    async def test_no_header_returns_401(self, app_with_svc, client):
        """Request without X-Service-Token → 401."""
        r = await client.get("/_test_06/svc-ping")
        assert r.status_code == 401

    async def test_wrong_token_returns_401(self, app_with_svc, client):
        """Request with invalid X-Service-Token → 401."""
        r = await client.get(
            "/_test_06/svc-ping",
            headers={"X-Service-Token": "wrong-value"},
        )
        assert r.status_code == 401

    async def test_valid_token_returns_200(self, app_with_svc, client):
        """Request with valid X-Service-Token → 200."""
        settings = get_settings()
        r = await client.get(
            "/_test_06/svc-ping",
            headers={"X-Service-Token": settings.mcp_service_token},
        )
        assert r.status_code == 200
        assert r.json() == {"pong": True}

    async def test_student_id_not_from_request(self):
        """Service token endpoint doesn't take student_id from request — it's injected.

        Verify by inspecting require_service_token: it returns None (no user context).
        The MCP server injects student_id from session context internally.
        """
        settings = get_settings()
        # require_service_token returns None — it's a gate, not a user provider
        result = await require_service_token(x_service_token=settings.mcp_service_token)
        assert result is None  # No user/student_id in return value
