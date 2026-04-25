from __future__ import annotations

from types import SimpleNamespace
from uuid import UUID

import pytest

from mcp_server.middleware import ToolLoggingMiddleware


pytestmark = pytest.mark.asyncio


def _build_context(mock_context, arguments: dict | None = None) -> SimpleNamespace:
    return SimpleNamespace(
        message=SimpleNamespace(name="get_grades", arguments=arguments or {"semester_year": "2025.1"}),
        fastmcp_context=mock_context,
    )


async def _return_result(_context, result: dict) -> dict:
    return result


async def test_tool_logging_middleware_logs_successful_calls(
    mock_context,
    monkeypatch: pytest.MonkeyPatch,
):
    middleware = ToolLoggingMiddleware()
    context = _build_context(mock_context)
    monkeypatch.setattr(
        "mcp_server.middleware.get_http_headers",
        lambda include=None: {"x-chat-session-id": "11111111-1111-1111-1111-111111111111"},
    )

    result = await middleware.on_call_tool(
        context,
        lambda current: _return_result(current, {"data": ["ok"]}),
    )

    assert result == {"data": ["ok"]}
    query, chat_session_id, tool_name, input_params, output_result, reasoning, latency_ms, retry, status = (
        mock_context.lifespan_context["db_pool"].execute.await_args.args
    )
    assert "INSERT INTO mcp_action_logs" in query
    assert chat_session_id == UUID("11111111-1111-1111-1111-111111111111")
    assert tool_name == "get_grades"
    assert input_params == '{"semester_year": "2025.1"}'
    assert output_result == '{"data": ["ok"]}'
    assert reasoning is None
    assert latency_ms >= 0
    assert retry is False
    assert status == "success"


async def test_tool_logging_middleware_logs_errors_without_output(
    mock_context,
    monkeypatch: pytest.MonkeyPatch,
):
    middleware = ToolLoggingMiddleware()
    context = _build_context(mock_context, {"document_id": "abc"})
    monkeypatch.setattr(
        "mcp_server.middleware.get_http_headers",
        lambda include=None: {"x-chat-session-id": "11111111-1111-1111-1111-111111111111"},
    )

    async def fail(_context):
        raise RuntimeError("boom")

    with pytest.raises(RuntimeError, match="boom"):
        await middleware.on_call_tool(context, fail)

    _, _, _, input_params, output_result, _, _, _, status = (
        mock_context.lifespan_context["db_pool"].execute.await_args.args
    )
    assert input_params == '{"document_id": "abc"}'
    assert output_result is None
    assert status == "error"


async def test_tool_logging_middleware_records_retry_success_and_latency(
    mock_context,
    monkeypatch: pytest.MonkeyPatch,
):
    middleware = ToolLoggingMiddleware()
    context = _build_context(mock_context)
    mock_context.get_state.return_value = True
    monotonic_values = iter([10.0, 10.025])

    def fake_monotonic() -> float:
        try:
            return next(monotonic_values)
        except StopIteration:
            return 10.025
    monkeypatch.setattr(
        "mcp_server.middleware.get_http_headers",
        lambda include=None: {"x-chat-session-id": "11111111-1111-1111-1111-111111111111"},
    )
    monkeypatch.setattr(
        "mcp_server.middleware.time.monotonic",
        fake_monotonic,
    )

    await middleware.on_call_tool(
        context,
        lambda current: _return_result(current, {"ok": True}),
    )

    _, _, _, _, _, _, latency_ms, retry, status = (
        mock_context.lifespan_context["db_pool"].execute.await_args.args
    )
    assert latency_ms == 25
    assert retry is True
    assert status == "retry_success"


async def test_tool_logging_middleware_includes_chat_session_id_from_headers(
    mock_context,
    monkeypatch: pytest.MonkeyPatch,
):
    middleware = ToolLoggingMiddleware()
    context = _build_context(mock_context, {})
    monkeypatch.setattr(
        "mcp_server.middleware.get_http_headers",
        lambda include=None: {"x-chat-session-id": "33333333-3333-3333-3333-333333333333"},
    )

    await middleware.on_call_tool(
        context,
        lambda current: _return_result(current, {"ok": True}),
    )

    chat_session_id = mock_context.lifespan_context["db_pool"].execute.await_args.args[1]
    assert chat_session_id == UUID("33333333-3333-3333-3333-333333333333")
