from __future__ import annotations

import json
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock

import pytest
from fastmcp import FastMCP
from starlette.requests import Request

from mcp_server.healthcheck import register_healthcheck


pytestmark = pytest.mark.asyncio


def _build_healthcheck_request(resources: dict[str, object]) -> Request:
    app = SimpleNamespace(
        state=SimpleNamespace(
            fastmcp_server=SimpleNamespace(_lifespan_result=resources)
        )
    )
    scope = {
        "type": "http",
        "method": "GET",
        "path": "/health",
        "headers": [],
        "app": app,
    }
    return Request(scope)


def _get_healthcheck_endpoint():
    mcp = FastMCP("test-health")
    register_healthcheck(mcp)
    return mcp._additional_http_routes[0].endpoint


async def test_healthcheck_returns_healthy_when_db_and_api_checks_pass():
    endpoint = _get_healthcheck_endpoint()
    pool = AsyncMock()
    api_response = MagicMock()
    api_response.raise_for_status.return_value = None
    client = AsyncMock()
    client.get.return_value = api_response

    response = await endpoint(
        _build_healthcheck_request({"db_pool": pool, "http_client": client})
    )

    assert response.status_code == 200
    assert json.loads(response.body) == {"status": "healthy"}
    pool.fetchval.assert_awaited_once_with("SELECT 1")
    client.get.assert_awaited_once_with("/health")
    api_response.raise_for_status.assert_called_once_with()


@pytest.mark.parametrize(
    ("resources", "expected_details"),
    [
        (
            {
                "db_pool": AsyncMock(fetchval=AsyncMock(side_effect=RuntimeError("db down"))),
                "http_client": AsyncMock(
                    get=AsyncMock(
                        return_value=MagicMock(
                            raise_for_status=MagicMock(return_value=None)
                        )
                    )
                ),
            },
            {"database": "db down"},
        ),
        (
            {
                "db_pool": AsyncMock(),
                "http_client": AsyncMock(
                    get=AsyncMock(
                        return_value=MagicMock(
                            raise_for_status=MagicMock(
                                side_effect=RuntimeError("api down")
                            )
                        )
                    )
                ),
            },
            {"api": "api down"},
        ),
    ],
)
async def test_healthcheck_returns_503_with_failure_details(
    resources: dict[str, object],
    expected_details: dict[str, str],
):
    endpoint = _get_healthcheck_endpoint()

    response = await endpoint(_build_healthcheck_request(resources))

    assert response.status_code == 503
    assert json.loads(response.body) == {
        "status": "unhealthy",
        "details": expected_details,
    }
