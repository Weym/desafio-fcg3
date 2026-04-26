"""Behavioral coverage for the agent invocation flow."""

from __future__ import annotations

from types import SimpleNamespace

import pytest
from langchain_core.messages import AIMessage, HumanMessage

from ai_service.agent import invoke_agent


@pytest.mark.asyncio
async def test_student_gets_portuguese_response_with_mcp_and_rag_tools_wired(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    calls: dict[str, object] = {}

    async def fake_load_mcp_tools(mcp_server_url: str, session_id: str):
        calls["mcp"] = (mcp_server_url, session_id)
        return [SimpleNamespace(name="consultar_notas")]

    def fake_create_rag_tool(db_pool, openai_api_key: str):
        calls["rag"] = (db_pool, openai_api_key)
        return SimpleNamespace(name="search_knowledge_base")

    def fake_create_chat_agent(settings, tools, system_prompt: str):
        calls["agent"] = {
            "model": settings.LLM_PROVIDER,
            "tool_names": [tool.name for tool in tools],
            "system_prompt": system_prompt,
        }

        class FakeAgent:
            async def ainvoke(self, payload, config):
                calls["payload"] = payload
                calls["config"] = config
                return {
                    "messages": [
                        HumanMessage(content="Preciso saber minha situacao."),
                        AIMessage(content="Olá! Consultei seus dados e sua matrícula está ativa."),
                    ]
                }

        return FakeAgent()

    monkeypatch.setattr("ai_service.agent.load_mcp_tools", fake_load_mcp_tools)
    monkeypatch.setattr("ai_service.agent.create_rag_tool", fake_create_rag_tool)
    monkeypatch.setattr("ai_service.agent.create_chat_agent", fake_create_chat_agent)
    monkeypatch.setattr(
        "ai_service.agent.load_chat_history",
        lambda pool, session_id, k: [AIMessage(content="Contexto anterior")],
    )

    settings = SimpleNamespace(
        MCP_SERVER_URL="http://mcp-server:8002/mcp",
        OPENAI_API_KEY="test-key",
        CHAT_HISTORY_K=20,
        MAX_AGENT_ITERATIONS=10,
        MAX_AGENT_EXECUTION_TIME=45.0,
        LLM_PROVIDER="openai",
    )

    response = await invoke_agent(
        settings=settings,
        db_pool=object(),
        system_prompt="Sempre responda em portugues brasileiro.",
        session_id="session-pt",
        user_message="Qual é a minha situação acadêmica?",
    )

    assert response == "Olá! Consultei seus dados e sua matrícula está ativa."
    assert calls["mcp"] == ("http://mcp-server:8002/mcp", "session-pt")
    assert calls["rag"][1] == "test-key"
    assert calls["agent"] == {
        "model": "openai",
        "tool_names": ["consultar_notas", "search_knowledge_base"],
        "system_prompt": "Sempre responda em portugues brasileiro.",
    }
    assert calls["config"] == {"recursion_limit": 10}
    assert calls["payload"]["messages"][0].content == "Contexto anterior"
    assert calls["payload"]["messages"][-1].content == "Qual é a minha situação acadêmica?"
