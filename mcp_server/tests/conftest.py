from __future__ import annotations

from collections.abc import Iterator
from types import SimpleNamespace
from unittest.mock import AsyncMock

import pytest
from starlette.requests import Request


def _build_request(headers: dict[str, str] | None = None) -> Request:
    scope = {
        "type": "http",
        "method": "GET",
        "path": "/mcp",
        "headers": [
            (key.lower().encode("latin-1"), value.encode("latin-1"))
            for key, value in (headers or {}).items()
        ],
    }
    return Request(scope)


@pytest.fixture
def mock_db_pool() -> AsyncMock:
    pool = AsyncMock()
    pool.fetchrow = AsyncMock()
    pool.execute = AsyncMock()
    return pool


@pytest.fixture
def mock_http_client() -> AsyncMock:
    return AsyncMock()


@pytest.fixture
def mock_request() -> Request:
    return _build_request(
        {"x-chat-session-id": "11111111-1111-1111-1111-111111111111"}
    )


@pytest.fixture
def mock_context(mock_db_pool: AsyncMock, mock_http_client: AsyncMock) -> SimpleNamespace:
    context = SimpleNamespace(
        lifespan_context={"db_pool": mock_db_pool, "http_client": mock_http_client},
    )
    context.get_state = AsyncMock(return_value=False)
    context.set_state = AsyncMock()
    return context


@pytest.fixture
def request_factory() -> Iterator[callable]:
    yield _build_request
