"""Regression coverage for Phase 05 AI service gap closure.

Persistence contract (see
`.planning/debug/resolved/chat-duplicate-messages-flutter.md`):
The AI service MUST NOT write to `chat_messages`. The backend webhook
flow is the single owner of that table. Writing in both services
caused every chat message to appear duplicated in the Flutter UI.
These tests pin that contract.
"""

from __future__ import annotations

from types import SimpleNamespace

import pytest
from fastapi import HTTPException, status
from langchain_core.messages import AIMessage, HumanMessage, ToolMessage

from ai_service.agent import _extract_response_text
from ai_service import main
from ai_service.main import ChatRequest, app, chat


def test_extract_response_text_uses_last_ai_message() -> None:
    result = {
        "messages": [
            HumanMessage(content="Quais disciplinas posso cursar?"),
            AIMessage(content="Vou consultar suas opcoes."),
            ToolMessage(content="{\"courses\": [\"ALG001\"]}", tool_call_id="call-1"),
            AIMessage(content=[{"text": "Voce pode cursar ALG001."}]),
            ToolMessage(content="mensagem final da ferramenta", tool_call_id="call-2"),
        ]
    }

    assert _extract_response_text(result) == "Voce pode cursar ALG001."


@pytest.mark.asyncio
async def test_chat_requires_internal_service_token(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(main, "settings", SimpleNamespace(MCP_SERVICE_TOKEN="shared-token"))

    with pytest.raises(HTTPException) as exc_info:
        await main.require_service_token("wrong-token")

    assert exc_info.value.status_code == status.HTTP_401_UNAUTHORIZED

    with pytest.raises(HTTPException) as missing_exc:
        await main.require_service_token(None)

    assert missing_exc.value.status_code == status.HTTP_401_UNAUTHORIZED

    await main.require_service_token("shared-token")


@pytest.mark.asyncio
async def test_chat_invokes_agent_and_returns_response_without_persisting(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Happy path: the agent runs and its response is returned.

    Regression guard: the AI service must NOT import or invoke
    `save_chat_message`. Persistence is owned by the backend.
    """

    async def fake_invoke_agent(
        *, settings, db_pool, system_prompt, session_id, user_message
    ) -> str:
        assert db_pool is app.state.db_pool
        assert system_prompt == app.state.system_prompt
        assert session_id == "session-123"
        assert user_message == "Oi"
        return "Resposta final"

    monkeypatch.setattr("ai_service.main.invoke_agent", fake_invoke_agent)

    # The AI service must not reference save_chat_message anymore. If some
    # future change reintroduces the import, this assertion will fail.
    assert not hasattr(main, "save_chat_message"), (
        "ai_service.main must not import save_chat_message — persistence "
        "is owned exclusively by the backend."
    )

    app.state.db_pool = object()
    app.state.system_prompt = "prompt"

    response = await chat(ChatRequest(session_id="session-123", message="Oi"))

    assert response.response == "Resposta final"
    assert response.session_id == "session-123"


@pytest.mark.asyncio
async def test_chat_returns_fallback_after_agent_error_without_persisting(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """Failure path: agent raises, endpoint returns the fallback message.

    Regression guard: no persistence happens here either — the backend
    saves whatever response text this endpoint returns.
    """

    async def fake_invoke_agent(
        *, settings, db_pool, system_prompt, session_id, user_message
    ) -> str:
        raise RuntimeError("boom")

    monkeypatch.setattr("ai_service.main.invoke_agent", fake_invoke_agent)

    app.state.db_pool = object()
    app.state.system_prompt = "prompt"

    response = await chat(
        ChatRequest(session_id="session-456", message="Preciso do historico")
    )

    assert response.session_id == "session-456"
    assert response.response == (
        "Desculpe, estou com dificuldades tecnicas. "
        "Tente novamente em alguns minutos."
    )
