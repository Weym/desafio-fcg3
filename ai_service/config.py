"""Configuration for the AI service."""

from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class Settings:
    """Simple environment-backed settings for the AI service."""

    DATABASE_URL: str = os.environ.get(
        "DATABASE_URL",
        "postgresql://postgres:postgres@postgres:5432/desafio_fcg3",
    )
    LLM_PROVIDER: str = os.environ.get("LLM_PROVIDER", "openai")
    LLM_MODEL: str = os.environ.get("LLM_MODEL", "gpt-4o")
    MCP_SERVICE_TOKEN: str | None = os.environ.get("MCP_SERVICE_TOKEN")
    OPENAI_API_KEY: str | None = os.environ.get("OPENAI_API_KEY")
    GEMINI_API_KEY: str | None = os.environ.get("GEMINI_API_KEY")
    MCP_SERVER_URL: str = os.environ.get(
        "MCP_SERVER_URL",
        "http://mcp-server:8002/mcp",
    )
    SYSTEM_PROMPT_PATH: str = os.environ.get(
        "SYSTEM_PROMPT_PATH",
        str(Path("prompts") / "system_prompt.txt"),
    )
    MAX_AGENT_ITERATIONS: int = int(os.environ.get("MAX_AGENT_ITERATIONS", "10"))
    MAX_AGENT_EXECUTION_TIME: float = float(
        os.environ.get("MAX_AGENT_EXECUTION_TIME", "45.0")
    )
    CHAT_HISTORY_K: int = int(os.environ.get("CHAT_HISTORY_K", "20"))


settings = Settings()
