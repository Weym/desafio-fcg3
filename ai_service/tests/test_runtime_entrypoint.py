"""Regression coverage for the AI runtime entrypoint gap."""

from __future__ import annotations

from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]


def test_import_preserves_health_and_chat_routes() -> None:
    from ai_service.main import app

    route_paths = {route.path for route in app.routes}

    assert "/health" in route_paths
    assert "/chat" in route_paths


def test_database_urls_are_normalized_for_psycopg() -> None:
    from ai_service.database import normalize_psycopg_dsn

    assert (
        normalize_psycopg_dsn("postgresql+asyncpg://user:pass@db:5432/app")
        == "postgresql://user:pass@db:5432/app"
    )


def test_dockerfile_uses_package_entrypoint() -> None:
    dockerfile = (REPO_ROOT / "ai_service" / "Dockerfile").read_text(encoding="utf-8")

    assert 'CMD ["python", "-m", "ai_service.main"]' in dockerfile
    assert "uvicorn main:app" not in dockerfile


def test_compose_uses_package_entrypoint_and_bind_mount() -> None:
    compose_text = (REPO_ROOT / "docker-compose.yml").read_text(encoding="utf-8")
    service_section = compose_text.split("\n  langchain-service:\n", 1)[1].split(
        "\n  mcp-server:\n", 1
    )[0]
    mcp_section = compose_text.split("\n  mcp-server:\n", 1)[1].split(
        "\nnetworks:\n", 1
    )[0]

    assert "command: python -m ai_service.main" in service_section
    assert "- ./ai_service:/app/ai_service" in service_section
    assert "- ./ai_service:/app\n" not in service_section
    assert "uvicorn main:app" not in service_section
    assert "ports:" not in service_section
    assert "ports:" not in mcp_section


def test_compose_limits_ai_service_env_to_runtime_dependencies() -> None:
    compose_text = (REPO_ROOT / "docker-compose.yml").read_text(encoding="utf-8")
    service_section = compose_text.split("\n  langchain-service:\n", 1)[1].split(
        "\n  mcp-server:\n", 1
    )[0]

    # Plan 08 replaced explicit DATABASE_URL with POSTGRES_* component vars
    # to prevent credential drift (ai_service config.py builds URL at runtime)
    assert "POSTGRES_DB: ${POSTGRES_DB}" in service_section
    assert "POSTGRES_USER: ${POSTGRES_USER}" in service_section
    assert "POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}" in service_section
    assert "POSTGRES_HOST: postgres" in service_section
    assert "POSTGRES_PORT: 5432" in service_section
    assert "MCP_SERVICE_TOKEN: ${MCP_SERVICE_TOKEN}" in service_section
    assert "LLM_PROVIDER: ${LLM_PROVIDER}" in service_section
    assert "LLM_MODEL: ${LLM_MODEL}" in service_section
    assert "OPENAI_API_KEY: ${OPENAI_API_KEY}" in service_section
    assert "GEMINI_API_KEY: ${GEMINI_API_KEY}" in service_section
    assert "OPENROUTER_API_KEY: ${OPENROUTER_API_KEY}" in service_section
    assert "MCP_SERVER_URL: http://mcp-server:8002/mcp" in service_section
    assert "JWT_SECRET:" not in service_section
    assert "WHATSAPP_TOKEN:" not in service_section
    assert "RESEND_API_KEY:" not in service_section
    assert "FASTAPI_URL:" not in service_section
    assert "DATABASE_URL:" not in service_section  # Replaced by POSTGRES_* component vars
