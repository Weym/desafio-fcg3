"""Embedding factory helpers for provider-agnostic embedding configuration."""

from __future__ import annotations

from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from langchain_core.embeddings import Embeddings


def create_embeddings(settings: Any) -> "Embeddings":
    """Create an embeddings instance for the configured provider.

    Follows the same pattern as ``llm_factory.py`` — imports are lazily
    resolved inside each branch so unused providers never need to be
    installed.
    """

    if settings.EMBEDDING_PROVIDER == "openai":
        from langchain_openai import OpenAIEmbeddings

        return OpenAIEmbeddings(
            model=settings.EMBEDDING_MODEL,
            api_key=settings.OPENAI_API_KEY,
        )

    if settings.EMBEDDING_PROVIDER == "openrouter":
        from langchain_openai import OpenAIEmbeddings

        return OpenAIEmbeddings(
            model=settings.EMBEDDING_MODEL,
            api_key=settings.OPENROUTER_API_KEY,
            base_url="https://openrouter.ai/api/v1",
        )

    raise ValueError(
        f"Unsupported embedding provider: {settings.EMBEDDING_PROVIDER}. "
        "Use 'openai' or 'openrouter'."
    )


def get_embedding_api_key(settings: Any) -> str:
    """Return the correct API key for the configured embedding provider.

    Used by ``ingest.py`` which needs the raw key for its
    ``IngestSettings`` dataclass.

    Raises ``RuntimeError`` if the required key is missing.
    """

    provider = settings.EMBEDDING_PROVIDER

    if provider == "openai":
        key = settings.OPENAI_API_KEY
        if not key:
            raise RuntimeError(
                "Missing required environment variable: OPENAI_API_KEY "
                "(needed for EMBEDDING_PROVIDER=openai)"
            )
        return key

    if provider == "openrouter":
        key = settings.OPENROUTER_API_KEY
        if not key:
            raise RuntimeError(
                "Missing required environment variable: OPENROUTER_API_KEY "
                "(needed for EMBEDDING_PROVIDER=openrouter)"
            )
        return key

    raise RuntimeError(
        f"Unsupported embedding provider: {provider}. "
        "Use 'openai' or 'openrouter'."
    )
