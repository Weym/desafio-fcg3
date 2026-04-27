"""ReAct agent factory and invocation helpers for the AI service."""

from __future__ import annotations

import asyncio
import logging
from typing import Any

from langchain.agents import create_agent
from langchain_core.messages import AIMessage, HumanMessage

from ai_service.database import load_chat_history
from ai_service.embedding_factory import create_embeddings
from ai_service.llm_factory import get_model_string
from ai_service.mcp_tools import load_mcp_tools
from ai_service.rag import create_rag_tool

logger = logging.getLogger(__name__)

FALLBACK_MESSAGE = (
    "Desculpe, estou com dificuldades tecnicas para processar sua solicitacao. "
    "Tente novamente em alguns minutos ou procure a secretaria."
)


def create_chat_agent(settings: Any, tools: list[Any], system_prompt: str) -> Any:
    """Create a provider-agnostic LangChain ReAct agent."""

    return create_agent(
        model=get_model_string(settings),
        tools=tools,
        system_prompt=system_prompt,
    )


def _normalize_message_content(content: Any) -> str:
    """Normalize LangChain message content into plain text."""

    if isinstance(content, str):
        return content.strip() or FALLBACK_MESSAGE

    if isinstance(content, list):
        text_parts: list[str] = []
        for item in content:
            if isinstance(item, str):
                text_parts.append(item)
            elif isinstance(item, dict):
                text_value = item.get("text")
                if isinstance(text_value, str):
                    text_parts.append(text_value)
        combined_text = "\n".join(part for part in text_parts if part).strip()
        return combined_text or FALLBACK_MESSAGE

    return str(content).strip() or FALLBACK_MESSAGE


def _extract_response_text(result: dict[str, Any]) -> str:
    """Return the last assistant-authored message as plain text."""

    response_messages = result.get("messages", [])
    if not response_messages:
        return FALLBACK_MESSAGE

    for message in reversed(response_messages):
        if isinstance(message, AIMessage):
            return _normalize_message_content(getattr(message, "content", ""))

    return FALLBACK_MESSAGE


async def invoke_agent(
    settings: Any,
    db_pool: Any,
    system_prompt: str,
    session_id: str,
    user_message: str,
) -> str:
    """Process one student message through the LangChain agent.

    The agent is rebuilt on every request because the MCP tool client needs a
    session-specific ``X-Chat-Session-ID`` header. Conversation history is
    loaded fresh from PostgreSQL on every invocation to preserve the stateless
    service design for the AI container.
    """

    mcp_tools = await load_mcp_tools(settings.MCP_SERVER_URL, session_id)
    embeddings = create_embeddings(settings)
    rag_tool = create_rag_tool(db_pool, embeddings)
    agent = create_chat_agent(settings, [*mcp_tools, rag_tool], system_prompt)

    history_messages = load_chat_history(
        db_pool,
        session_id,
        k=settings.CHAT_HISTORY_K,
    )
    all_messages = [*history_messages, HumanMessage(content=user_message)]

    try:
        result = await asyncio.wait_for(
            agent.ainvoke(
                {"messages": all_messages},
                config={"recursion_limit": settings.MAX_AGENT_ITERATIONS},
            ),
            timeout=settings.MAX_AGENT_EXECUTION_TIME,
        )
    except asyncio.TimeoutError:
        logger.warning("Agent execution timed out for session %s", session_id)
        return FALLBACK_MESSAGE
    except Exception as exc:
        if exc.__class__.__name__ == "GraphRecursionError":
            logger.warning(
                "Agent iteration limit hit for session %s",
                session_id,
            )
            return FALLBACK_MESSAGE

        logger.exception("Agent execution failed for session %s", session_id)
        return FALLBACK_MESSAGE

    return _extract_response_text(result)
