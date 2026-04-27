"""LLM factory helpers for provider-agnostic model configuration."""

from __future__ import annotations

from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from langchain_core.language_models.chat_models import BaseChatModel


def get_model_string(settings: Any) -> str:
    """Build the provider:model string used by LangChain create_agent."""

    provider = settings.LLM_PROVIDER
    model = settings.LLM_MODEL

    if provider == "openai":
        return f"openai:{model}"
    if provider == "gemini":
        return f"google_genai:{model}"
    if provider == "openrouter":
        return f"openai:{model}"

    raise ValueError(
        f"Unsupported LLM provider: {provider}. Use 'openai', 'gemini', or 'openrouter'."
    )


def create_llm(settings: Any) -> "BaseChatModel":
    """Create a chat model instance for the configured provider."""

    if settings.LLM_PROVIDER == "openai":
        from langchain_openai import ChatOpenAI

        return ChatOpenAI(model=settings.LLM_MODEL, api_key=settings.OPENAI_API_KEY)

    if settings.LLM_PROVIDER == "gemini":
        from langchain_google_genai import ChatGoogleGenerativeAI

        return ChatGoogleGenerativeAI(
            model=settings.LLM_MODEL,
            google_api_key=settings.GEMINI_API_KEY,
        )

    if settings.LLM_PROVIDER == "openrouter":
        from langchain_openai import ChatOpenAI

        return ChatOpenAI(
            model=settings.LLM_MODEL,
            api_key=settings.OPENROUTER_API_KEY,
            base_url="https://openrouter.ai/api/v1",
        )

    raise ValueError(
        f"Unsupported LLM provider: {settings.LLM_PROVIDER}. "
        "Use 'openai', 'gemini', or 'openrouter'."
    )
