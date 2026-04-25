from __future__ import annotations

from unittest.mock import AsyncMock

import pytest
from fastmcp.exceptions import ToolError

from mcp_server import dependencies


pytestmark = pytest.mark.asyncio


async def test_resolve_chat_session_id_returns_header_value(mock_request):
    session_id = await dependencies.resolve_chat_session_id(mock_request)

    assert session_id == "11111111-1111-1111-1111-111111111111"


async def test_resolve_student_id_returns_student_id_for_active_session(
    mock_request,
    mock_context,
    monkeypatch: pytest.MonkeyPatch,
):
    mock_context.lifespan_context["db_pool"].fetchrow.return_value = {
        "student_id": "22222222-2222-2222-2222-222222222222"
    }
    monkeypatch.setattr(dependencies, "get_context", lambda: mock_context)

    student_id = await dependencies.resolve_student_id(mock_request)

    assert student_id == "22222222-2222-2222-2222-222222222222"


async def test_resolve_student_id_rejects_missing_header(request_factory):
    request = request_factory({})

    with pytest.raises(ToolError, match="Sessao invalida"):
        await dependencies.resolve_student_id(request)


async def test_resolve_student_id_rejects_unknown_session(
    mock_request,
    mock_context,
    monkeypatch: pytest.MonkeyPatch,
):
    mock_context.lifespan_context["db_pool"].fetchrow.return_value = None
    monkeypatch.setattr(dependencies, "get_context", lambda: mock_context)

    with pytest.raises(ToolError, match="Sessao invalida"):
        await dependencies.resolve_student_id(mock_request)


async def test_resolve_student_id_rejects_inactive_session(
    mock_request,
    mock_context,
    monkeypatch: pytest.MonkeyPatch,
):
    db_pool: AsyncMock = mock_context.lifespan_context["db_pool"]
    db_pool.fetchrow.return_value = None
    monkeypatch.setattr(dependencies, "get_context", lambda: mock_context)

    with pytest.raises(ToolError, match="Sessao invalida"):
        await dependencies.resolve_student_id(mock_request)

    query, session_uuid = db_pool.fetchrow.await_args.args
    assert "status = 'active'" in query
    assert str(session_uuid) == "11111111-1111-1111-1111-111111111111"
