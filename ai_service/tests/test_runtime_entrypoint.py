"""Regression coverage for the AI runtime entrypoint gap."""

from __future__ import annotations

from pathlib import Path

import yaml


REPO_ROOT = Path(__file__).resolve().parents[2]


def test_import_preserves_health_and_chat_routes() -> None:
    from ai_service.main import app

    route_paths = {route.path for route in app.routes}

    assert "/health" in route_paths
    assert "/chat" in route_paths


def test_dockerfile_uses_package_entrypoint() -> None:
    dockerfile = (REPO_ROOT / "ai_service" / "Dockerfile").read_text(encoding="utf-8")

    assert "python -m ai_service.main" in dockerfile
    assert "uvicorn main:app" not in dockerfile


def test_compose_uses_package_entrypoint_and_bind_mount() -> None:
    compose = yaml.safe_load((REPO_ROOT / "docker-compose.yml").read_text(encoding="utf-8"))
    service = compose["services"]["langchain-service"]

    assert service["command"] == "python -m ai_service.main"
    assert "./ai_service:/app/ai_service" in service["volumes"]
    assert "./ai_service:/app" not in service["volumes"]
    assert service["command"] != "uvicorn main:app --host 0.0.0.0 --port 8001 --reload"
