from __future__ import annotations

import tempfile
import urllib.request
from pathlib import Path

from conftest import BACKEND_ROOT, REPO_ROOT, assert_success, backend_python_env, run_command


def test_phase_one_service_dockerfiles_and_runtime_dependencies_exist() -> None:
    dockerfiles = {
        "backend": REPO_ROOT / "backend" / "Dockerfile",
        "ai_service": REPO_ROOT / "ai_service" / "Dockerfile",
        "mcp_server": REPO_ROOT / "mcp_server" / "Dockerfile",
    }

    for dockerfile in dockerfiles.values():
        contents = dockerfile.read_text(encoding="utf-8")
        assert dockerfile.is_file()
        assert "curl" in contents

    ai_requirements = (REPO_ROOT / "ai_service" / "requirements.txt").read_text(encoding="utf-8")
    assert "langchain" not in ai_requirements.lower()


def test_docker_compose_config_is_valid_for_phase_one_topology() -> None:
    result = run_command(["docker", "compose", "config"])
    output = assert_success(result)

    for expected_fragment in [
        "fastapi-app:",
        "langchain-service:",
        "mcp-server:",
        "postgres:",
        "healthcheck:",
        "app-network:",
        "data-network:",
    ]:
        assert expected_fragment in output


def test_developer_stack_reports_healthy_services_and_health_endpoints() -> None:
    result = run_command(
        ["docker", "compose", "ps", "--format", "{{.Name}}|{{.Status}}|{{.Health}}"]
    )
    output = assert_success(result)

    services = {}
    for line in output.splitlines():
        name, status, health = line.split("|", 2)
        services[name] = {"status": status, "health": health}

    assert set(services) == {"fcg3-postgres", "fcg3-api", "fcg3-ai", "fcg3-mcp"}
    for service in services.values():
        assert "healthy" in service["status"].lower()
        assert service["health"] == "healthy"

    expected_payloads = {
        "http://localhost:8000/health": '{"status":"ok"}',
        "http://localhost:8001/health": '"service":"langchain-service"',
        "http://localhost:8002/health": '"service":"mcp-server"',
    }
    for url, expected_fragment in expected_payloads.items():
        with urllib.request.urlopen(url, timeout=5) as response:
            body = response.read().decode("utf-8")
        assert response.status == 200
        assert expected_fragment in body


def test_backend_bootstrap_is_import_safe_and_settings_validate_on_first_use() -> None:
    with tempfile.TemporaryDirectory() as tmp_dir:
        temp_path = Path(tmp_dir)

        import_only = run_command(
            [
                "python",
                "-c",
                "from src.main import app; print(app.url_path_for('health'))",
            ],
            cwd=temp_path,
            env=backend_python_env(include_settings=False),
        )
        assert assert_success(import_only) == "/health"

        missing_env = run_command(
            [
                "python",
                "-c",
                "from src.infrastructure.config import get_settings; get_settings()",
            ],
            cwd=temp_path,
            env=backend_python_env(include_settings=False),
        )
        assert missing_env.returncode != 0
        assert "validationerror" in missing_env.stderr.lower()

        configured = run_command(
            [
                "python",
                "-c",
                "from src.infrastructure.config import get_settings; print(get_settings().jwt_algorithm)",
            ],
            cwd=temp_path,
            env=backend_python_env(include_settings=True),
        )
        assert assert_success(configured) == "HS256"


def test_environment_template_documents_required_keys_with_placeholder_secrets() -> None:
    env_example = (REPO_ROOT / ".env.example").read_text(encoding="utf-8")
    gitignore = (REPO_ROOT / ".gitignore").read_text(encoding="utf-8")

    for required_key in [
        "DATABASE_URL=postgresql+asyncpg://",
        "DATABASE_URL_AI=postgresql+psycopg://",
        "DATABASE_URL_MCP=postgresql+asyncpg://",
        "MCP_SERVICE_TOKEN=replace_with_a_unique_shared_service_token",
        "JWT_SECRET=replace_with_a_unique_32_plus_char_secret",
        "WHATSAPP_TOKEN=replace_with_whatsapp_business_api_token",
        "RESEND_API_KEY=replace_with_resend_api_key",
        "LLM_PROVIDER=openai",
        "FASTAPI_URL=http://fastapi-app:8000",
    ]:
        assert required_key in env_example

    for non_placeholder_secret in [
        "dev-token-do-not-use-in-production",
        "dev-whatsapp-token",
        "re_dev_key",
    ]:
        assert non_placeholder_secret not in env_example

    assert ".env" in gitignore.splitlines()
