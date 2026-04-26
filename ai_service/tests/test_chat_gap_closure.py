"""Regression coverage for Phase 05 AI service gap closure."""

from __future__ import annotations

from types import SimpleNamespace

import pytest
from langchain_core.messages import AIMessage, HumanMessage, ToolMessage

from ai_service.agent import _extract_response_text
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
async def test_chat_persists_user_before_agent_and_assistant_after_success(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    saved_messages: list[tuple[str, str]] = []

    def fake_save_chat_message(*, pool, session_id, role, content) -> None:
        saved_messages.append((role, content))

    async def fake_invoke_agent(*, settings, db_pool, system_prompt, session_id, user_message) -> str:
        assert saved_messages == [("user", "Oi")]
        assert db_pool is app.state.db_pool
        assert system_prompt == app.state.system_prompt
        assert session_id == "session-123"
        assert user_message == "Oi"
        return "Resposta final"

    monkeypatch.setattr("ai_service.main.save_chat_message", fake_save_chat_message)
    monkeypatch.setattr("ai_service.main.invoke_agent", fake_invoke_agent)

    app.state.db_pool = object()
    app.state.system_prompt = "prompt"

    response = await chat(ChatRequest(session_id="session-123", message="Oi"))

    assert response.response == "Resposta final"
    assert response.session_id == "session-123"
    assert saved_messages == [
        ("user", "Oi"),
        ("assistant", "Resposta final"),
    ]


@pytest.mark.asyncio
async def test_chat_persists_fallback_after_agent_error(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    saved_messages: list[tuple[str, str]] = []

    def fake_save_chat_message(*, pool, session_id, role, content) -> None:
        saved_messages.append((role, content))

    async def fake_invoke_agent(*, settings, db_pool, system_prompt, session_id, user_message) -> str:
        raise RuntimeError("boom")

    monkeypatch.setattr("ai_service.main.save_chat_message", fake_save_chat_message)
    monkeypatch.setattr("ai_service.main.invoke_agent", fake_invoke_agent)

    app.state.db_pool = object()
    app.state.system_prompt = "prompt"

    response = await chat(ChatRequest(session_id="session-456", message="Preciso do historico"))

    assert response.session_id == "session-456"
    assert response.response == (
        "Desculpe, estou com dificuldades tecnicas. "
        "Tente novamente em alguns minutos."
    )
    assert saved_messages == [
        ("user", "Preciso do historico"),
        (
            "assistant",
            "Desculpe, estou com dificuldades tecnicas. "
            "Tente novamente em alguns minutos.",
        ),
    ]
