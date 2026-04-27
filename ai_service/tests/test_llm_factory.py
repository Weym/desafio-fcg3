"""Behavioral coverage for provider switching in the LLM factory."""

from __future__ import annotations

import sys
from types import ModuleType, SimpleNamespace

import pytest

from ai_service.llm_factory import create_llm, get_model_string


def test_model_string_changes_with_provider_without_code_changes() -> None:
    openai_settings = SimpleNamespace(LLM_PROVIDER="openai", LLM_MODEL="gpt-4o")
    gemini_settings = SimpleNamespace(LLM_PROVIDER="gemini", LLM_MODEL="gemini-2.5-flash")
    openrouter_settings = SimpleNamespace(LLM_PROVIDER="openrouter", LLM_MODEL="moonshotai/kimi-k2.6")

    assert get_model_string(openai_settings) == "openai:gpt-4o"
    assert get_model_string(gemini_settings) == "google_genai:gemini-2.5-flash"
    assert get_model_string(openrouter_settings) == "openai:moonshotai/kimi-k2.6"


def test_create_llm_builds_openai_client(monkeypatch: pytest.MonkeyPatch) -> None:
    fake_module = ModuleType("langchain_openai")

    class FakeChatOpenAI:
        def __init__(self, **kwargs):
            self.kwargs = kwargs

    fake_module.ChatOpenAI = FakeChatOpenAI
    monkeypatch.setitem(sys.modules, "langchain_openai", fake_module)

    settings = SimpleNamespace(
        LLM_PROVIDER="openai",
        LLM_MODEL="gpt-4o-mini",
        OPENAI_API_KEY="openai-key",
    )

    llm = create_llm(settings)

    assert isinstance(llm, FakeChatOpenAI)
    assert llm.kwargs == {"model": "gpt-4o-mini", "api_key": "openai-key"}


def test_create_llm_builds_gemini_client(monkeypatch: pytest.MonkeyPatch) -> None:
    fake_module = ModuleType("langchain_google_genai")

    class FakeChatGoogleGenerativeAI:
        def __init__(self, **kwargs):
            self.kwargs = kwargs

    fake_module.ChatGoogleGenerativeAI = FakeChatGoogleGenerativeAI
    monkeypatch.setitem(sys.modules, "langchain_google_genai", fake_module)

    settings = SimpleNamespace(
        LLM_PROVIDER="gemini",
        LLM_MODEL="gemini-2.5-flash",
        GEMINI_API_KEY="gemini-key",
    )

    llm = create_llm(settings)

    assert isinstance(llm, FakeChatGoogleGenerativeAI)
    assert llm.kwargs == {
        "model": "gemini-2.5-flash",
        "google_api_key": "gemini-key",
    }


def test_create_llm_builds_openrouter_client(monkeypatch: pytest.MonkeyPatch) -> None:
    fake_module = ModuleType("langchain_openai")

    class FakeChatOpenAI:
        def __init__(self, **kwargs):
            self.kwargs = kwargs

    fake_module.ChatOpenAI = FakeChatOpenAI
    monkeypatch.setitem(sys.modules, "langchain_openai", fake_module)

    settings = SimpleNamespace(
        LLM_PROVIDER="openrouter",
        LLM_MODEL="moonshotai/kimi-k2.6",
        OPENROUTER_API_KEY="openrouter-key",
    )

    llm = create_llm(settings)

    assert isinstance(llm, FakeChatOpenAI)
    assert llm.kwargs == {
        "model": "moonshotai/kimi-k2.6",
        "api_key": "openrouter-key",
        "base_url": "https://openrouter.ai/api/v1",
    }


def test_unsupported_provider_raises_clear_error() -> None:
    settings = SimpleNamespace(LLM_PROVIDER="anthropic", LLM_MODEL="claude")

    with pytest.raises(ValueError, match="Unsupported LLM provider"):
        get_model_string(settings)
