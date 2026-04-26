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
    service_section = compose_text.split("langchain-service:", 1)[1].split("mcp-server:", 1)[0]
    mcp_section = compose_text.split("mcp-server:", 1)[1].split("networks:", 1)[0]

    assert "command: python -m ai_service.main" in service_section
    assert "- ./ai_service:/app/ai_service" in service_section
    assert "- ./ai_service:/app\n" not in service_section
    assert "uvicorn main:app" not in service_section
    assert "ports:" not in service_section
    assert "ports:" not in mcp_section
