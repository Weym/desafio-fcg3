from __future__ import annotations

import httpx
import pytest
from fastmcp.exceptions import ToolError

from mcp_server.api_client import call_api


pytestmark = pytest.mark.asyncio


def _make_response(status_code: int, payload: dict) -> httpx.Response:
    request = httpx.Request("GET", "http://mcp.test/resource")
    return httpx.Response(status_code, json=payload, request=request)


async def test_call_api_returns_payload_on_success(mock_http_client):
    mock_http_client.request.return_value = _make_response(200, {"ok": True})

    data, retried = await call_api(mock_http_client, "GET", "/students")

    assert data == {"ok": True}
    assert retried is False


async def test_call_api_retries_once_after_server_error(mock_http_client):
    mock_http_client.request.side_effect = [
        _make_response(500, {"error": {"code": "SERVER_ERROR"}}),
        _make_response(200, {"data": [1, 2, 3]}),
    ]

    data, retried = await call_api(mock_http_client, "GET", "/grades")

    assert data == {"data": [1, 2, 3]}
    assert retried is True
    assert mock_http_client.request.await_count == 2


async def test_call_api_raises_after_timeout_retry(mock_http_client):
    request = httpx.Request("GET", "http://mcp.test/resource")
    mock_http_client.request.side_effect = [
        httpx.TimeoutException("boom", request=request),
        httpx.TimeoutException("boom", request=request),
    ]

    with pytest.raises(ToolError, match="Erro interno do servidor"):
        await call_api(mock_http_client, "GET", "/grades")

    assert mock_http_client.request.await_count == 2


async def test_call_api_does_not_retry_bad_request(mock_http_client):
    mock_http_client.request.return_value = _make_response(
        400,
        {"error": {"code": "VALIDATION_ERROR"}},
    )

    with pytest.raises(ToolError, match="Erro: validation error"):
        await call_api(mock_http_client, "POST", "/documents")

    assert mock_http_client.request.await_count == 1


async def test_call_api_does_not_retry_not_found(mock_http_client):
    mock_http_client.request.return_value = _make_response(
        404,
        {"error": {"code": "NOT_FOUND"}},
    )

    with pytest.raises(ToolError, match="Erro: not found"):
        await call_api(mock_http_client, "GET", "/documents/missing")

    assert mock_http_client.request.await_count == 1


async def test_call_api_extracts_portuguese_error_message(mock_http_client):
    mock_http_client.request.return_value = _make_response(
        422,
        {"error": {"message": "Periodo de matricula encerrado"}},
    )

    with pytest.raises(ToolError, match="Erro: Periodo de matricula encerrado"):
        await call_api(mock_http_client, "POST", "/enrollments")
