"""ReAct agent factory and invocation helpers for the AI service."""

from __future__ import annotations

import asyncio
import logging
from typing import Any

from langchain.agents import create_agent
from langchain.agents.middleware import wrap_tool_call
from langchain_core.messages import AIMessage, HumanMessage, SystemMessage, ToolMessage

from ai_service.database import load_chat_history
from ai_service.embedding_factory import create_embeddings
from ai_service.llm_factory import create_llm
from ai_service.mcp_tools import load_mcp_tools
from ai_service.rag import create_rag_tool
from ai_service.security import sanitize_input, filter_output

logger = logging.getLogger(__name__)

FALLBACK_MESSAGE = (
    "Desculpe, estou com dificuldades tecnicas para processar sua solicitacao. "
    "Tente novamente em alguns minutos ou procure a secretaria."
)


@wrap_tool_call
async def _tolerate_tool_errors(request, handler):
    """Catch any exception raised by a tool and surface it to the LLM.

    The default LangGraph ``_default_handle_tool_errors`` only catches
    ``ToolInvocationError``; ``ToolException`` (raised by
    ``langchain_mcp_adapters`` when the MCP server returns an error) is
    re-raised and kills the agent loop. That causes the whole ``/chat``
    call to fall back to the generic "Desculpe, estou com dificuldades
    tecnicas" message even when another tool (including the RAG) could
    have answered.

    This middleware converts any tool exception into a ``ToolMessage`` so
    the LLM can reason about the failure and either retry or pick another
    tool. We use the async variant because every tool wired into this
    agent (MCP tools via ``langchain-mcp-adapters`` and the RAG tool)
    executes through the async path.
    """

    try:
        return await handler(request)
    except Exception as exc:
        logger.warning(
            "Tool '%s' raised %s; surfacing error to the LLM instead of aborting.",
            request.tool_call.get("name", "?"),
            type(exc).__name__,
        )
        return ToolMessage(
            content=f"Tool error: {exc}",
            tool_call_id=request.tool_call["id"],
        )


def create_chat_agent(settings: Any, tools: list[Any], system_prompt: str) -> Any:
    """Create a provider-agnostic LangChain ReAct agent."""

    llm = create_llm(settings)
    return create_agent(
        model=llm,
        tools=tools,
        system_prompt=system_prompt,
        middleware=[_tolerate_tool_errors],
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
    is_new_session: bool = False,
    student_name: str = "",
) -> str:
    """Process one student message through the LangChain agent.

    The agent is rebuilt on every request because the MCP tool client needs a
    session-specific ``X-Chat-Session-ID`` header. Conversation history is
    loaded fresh from PostgreSQL on every invocation to preserve the stateless
    service design for the AI container.

    When is_new_session=True and no prior history exists, a welcome instruction
    is injected so the agent generates a personalized greeting (D-01, LANG-01).
    """

    # Layer 2: Input sanitization (D-05)
    sanitized_message, injection_detected = sanitize_input(user_message)

    # If injection detected, prepend a context note for the agent (D-06)
    if injection_detected:
        logger.warning("Injection attempt detected for session %s", session_id)
        # The agent's system prompt instructs it to warn the student (## Seguranca section)
        # We use the sanitized message so the agent still sees context
        user_message = sanitized_message

    mcp_tools = await load_mcp_tools(settings.MCP_SERVER_URL, session_id)
    embeddings = create_embeddings(settings)
    rag_tool = create_rag_tool(
        db_pool,
        embeddings,
        similarity_threshold=settings.RAG_SIMILARITY_THRESHOLD,
        session_id=session_id,
    )
    agent = create_chat_agent(settings, [*mcp_tools, rag_tool], system_prompt)

    history_messages = load_chat_history(
        db_pool,
        session_id,
        k=settings.CHAT_HISTORY_K,
    )

    # D-01, LANG-01: Inject welcome generation instruction on new sessions
    if is_new_session:
        name_part = f" o aluno {student_name}" if student_name else " o aluno"
        welcome_instruction = SystemMessage(
            content=(
                f"Este e o inicio de uma nova conversa. Cumprimente{name_part} pelo nome "
                "de forma calorosa e breve, apresente-se como Alpha, e pergunte como "
                "pode ajudar. Em seguida, responda a mensagem do aluno."
            )
        )
        all_messages = [welcome_instruction, *history_messages, HumanMessage(content=user_message)]
    else:
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

    response_text = _extract_response_text(result)

    # Layer 4: Output filtering (D-05)
    filtered_response, was_filtered = filter_output(response_text)
    if was_filtered:
        logger.warning("Output filter triggered for session %s", session_id)
    response_text = filtered_response

    return response_text
