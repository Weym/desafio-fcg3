from __future__ import annotations

import asyncio
import importlib
import sys
from pathlib import Path


EXPECTED_TOOL_NAMES = {
    "get_student_info",
    "get_grades",
    "get_transcript",
    "get_available_courses",
    "create_enrollment",
    "confirm_enrollment",
    "drop_course",
    "lock_enrollment",
    "request_document",
    "get_document_status",
    "get_available_slots",
    "book_appointment",
    "cancel_appointment",
    "get_curriculum",
    "get_course_prerequisites",
    "get_enrollment_period",
}


def _reload_main_module():
    sys.modules.pop("mcp_server.main", None)
    return importlib.import_module("mcp_server.main")


def test_import_is_safe_inside_active_event_loop():
    async def import_module():
        return _reload_main_module()

    module = asyncio.run(import_module())

    assert module.mcp is not None


def test_runtime_preserves_tools_and_health_route():
    module = _reload_main_module()

    tools = asyncio.run(module.mcp.list_tools())

    assert {tool.name for tool in tools} == EXPECTED_TOOL_NAMES
    assert "/health" in [route.path for route in module.mcp._additional_http_routes]


def test_dockerfile_uses_package_entrypoint():
    dockerfile = Path("mcp_server/Dockerfile").read_text(encoding="utf-8")

    assert "COPY . /app/mcp_server" in dockerfile
    assert 'CMD ["python", "-m", "mcp_server.main"]' in dockerfile
    assert "uvicorn" not in dockerfile


def test_compose_uses_package_entrypoint():
    compose = Path("docker-compose.yml").read_text(encoding="utf-8")
    mcp_server_section = compose.split("mcp-server:", maxsplit=1)[1]

    assert "python -m mcp_server.main" in mcp_server_section
    assert "uvicorn main:app" not in mcp_server_section
