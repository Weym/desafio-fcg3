"""Behavioral coverage for conversation memory rebuilding."""

from __future__ import annotations

from types import SimpleNamespace

import pytest
from langchain_core.messages import AIMessage, HumanMessage, SystemMessage

from ai_service.agent import invoke_agent


class _FakeCursor:
    def __init__(self, rows):
        self.rows = rows
        self.executed = []

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False

    def execute(self, query, params):
        self.executed.append((query, params))

    def fetchall(self):
        return self.rows


class _FakeConnection:
    def __init__(self, cursor):
        self._cursor = cursor

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False

    def cursor(self):
        return self._cursor


class _FakePool:
    def __init__(self, cursor):
        self._cursor = cursor

    def connection(self):
        return _FakeConnection(self._cursor)


@pytest.mark.asyncio
async def test_agent_rebuilds_last_twenty_messages_in_chronological_order(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    latest_twenty_desc = []
    expected_contents = []
    role_cycle = ["assistant", "user", "system"]
    for index in range(25, 5, -1):
        role = role_cycle[index % 3]
        content = f"mensagem-{index}"
        latest_twenty_desc.append((role, content))
    for role, content in reversed(latest_twenty_desc):
        if role in {"assistant", "user", "system"}:
            expected_contents.append(content)

    cursor = _FakeCursor(latest_twenty_desc)
    pool = _FakePool(cursor)
    captured_messages = []

    async def fake_load_mcp_tools(*_args, **_kwargs):
        return []

    def fake_create_embeddings(*_args, **_kwargs):
        return SimpleNamespace(name="fake_embeddings")

    def fake_create_rag_tool(*_args, **_kwargs):
        return SimpleNamespace(name="search_knowledge_base")

    def fake_create_chat_agent(*_args, **_kwargs):
        class FakeAgent:
            async def ainvoke(self, payload, config):
                captured_messages.extend(payload["messages"])
                return {"messages": [AIMessage(content="Resposta final")]} 

        return FakeAgent()

    monkeypatch.setattr("ai_service.agent.load_mcp_tools", fake_load_mcp_tools)
    monkeypatch.setattr("ai_service.agent.create_embeddings", fake_create_embeddings)
    monkeypatch.setattr("ai_service.agent.create_rag_tool", fake_create_rag_tool)
    monkeypatch.setattr("ai_service.agent.create_chat_agent", fake_create_chat_agent)

    settings = SimpleNamespace(
        MCP_SERVER_URL="http://mcp-server:8002/mcp",
        OPENAI_API_KEY="test-key",
        EMBEDDING_PROVIDER="openai",
        EMBEDDING_MODEL="text-embedding-3-small",
        CHAT_HISTORY_K=20,
        MAX_AGENT_ITERATIONS=10,
        MAX_AGENT_EXECUTION_TIME=45.0,
        RAG_SIMILARITY_THRESHOLD=0.45,
    )

    response = await invoke_agent(
        settings=settings,
        db_pool=pool,
        system_prompt="prompt",
        session_id="session-memory",
        user_message="mensagem-atual",
    )

    assert response == "Resposta final"
    assert cursor.executed[0][1] == ("session-memory", 20)
    assert [message.content for message in captured_messages[:-1]] == expected_contents
    assert isinstance(captured_messages[0], (AIMessage, HumanMessage, SystemMessage))
    assert captured_messages[-1].content == "mensagem-atual"
