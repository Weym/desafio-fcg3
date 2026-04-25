from __future__ import annotations

from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock

import pytest

from mcp_server.lifespan import app_lifespan


pytestmark = pytest.mark.asyncio


async def test_lifespan_creates_http_client_with_service_token_header(
    monkeypatch: pytest.MonkeyPatch,
):
    mock_pool = AsyncMock()
    mock_client = AsyncMock()
    async_client_factory = MagicMock(return_value=mock_client)
    fake_settings = SimpleNamespace(
        validate_runtime=lambda: None,
        database_url="postgresql://postgres:test@localhost:5432/app",
        fastapi_base_url="http://fastapi.test/api/v1",
        mcp_service_token="test-token-123",
    )

    monkeypatch.setattr("mcp_server.lifespan.settings", fake_settings)
    monkeypatch.setattr(
        "mcp_server.lifespan.asyncpg.create_pool",
        AsyncMock(return_value=mock_pool),
    )
    monkeypatch.setattr("mcp_server.lifespan.httpx.AsyncClient", async_client_factory)

    async with app_lifespan(None) as resources:
        assert resources["db_pool"] is mock_pool
        assert resources["http_client"] is mock_client

    headers = async_client_factory.call_args.kwargs["headers"]
    assert headers["X-Service-Token"] == "test-token-123"
    assert async_client_factory.call_args.kwargs["base_url"] == "http://fastapi.test/api/v1"
    mock_client.aclose.assert_awaited_once()
    mock_pool.close.assert_awaited_once()
