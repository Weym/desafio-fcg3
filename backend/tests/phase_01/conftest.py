from __future__ import annotations

import os
import subprocess
import sys
from collections.abc import Sequence
from pathlib import Path
from urllib.parse import quote_plus

import pytest


REPO_ROOT = Path(__file__).resolve().parents[3]
BACKEND_ROOT = REPO_ROOT / "backend"


def get_postgres_setting(key: str, default: str) -> str:
    return os.environ.get(key, default)


def build_database_url(*, driver: str = "asyncpg", host: str = "localhost") -> str:
    postgres_user = get_postgres_setting("POSTGRES_USER", "fcg3")
    postgres_password = get_postgres_setting(
        "POSTGRES_PASSWORD",
        "change_me_in_production",
    )
    postgres_db = get_postgres_setting("POSTGRES_DB", "fcg3")
    postgres_port = get_postgres_setting("POSTGRES_PORT", "5432")
    scheme = "postgresql" if driver == "sync" else f"postgresql+{driver}"
    return (
        f"{scheme}://{quote_plus(postgres_user)}:{quote_plus(postgres_password)}"
        f"@{host}:{postgres_port}/{quote_plus(postgres_db)}"
    )


def run_command(
    args: Sequence[str],
    *,
    cwd: Path = REPO_ROOT,
    env: dict[str, str] | None = None,
    timeout: int = 120,
) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        list(args),
        cwd=cwd,
        env=env,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=timeout,
        check=False,
    )


def assert_success(result: subprocess.CompletedProcess[str]) -> str:
    if result.returncode != 0:
        raise AssertionError(
            "Command failed\n"
            f"exit={result.returncode}\n"
            f"stdout:\n{result.stdout}\n"
            f"stderr:\n{result.stderr}"
        )
    return result.stdout.strip()


def query_postgres(sql: str) -> str:
    result = run_command(
        [
            "docker",
            "compose",
            "exec",
            "-T",
            "postgres",
            "psql",
            "-U",
            get_postgres_setting("POSTGRES_USER", "fcg3"),
            "-d",
            get_postgres_setting("POSTGRES_DB", "fcg3"),
            "-t",
            "-A",
            "-c",
            sql,
        ]
    )
    return assert_success(result).strip()


def backend_python_env(*, include_settings: bool) -> dict[str, str]:
    env = os.environ.copy()
    env["PYTHONPATH"] = str(BACKEND_ROOT)
    env["PYTHONIOENCODING"] = "utf-8"

    for key in [
        "DATABASE_URL",
        "ALEMBIC_DATABASE_URL",
        "DATABASE_URL_AI",
        "DATABASE_URL_MCP",
        "JWT_SECRET",
        "MCP_SERVICE_TOKEN",
        "WHATSAPP_TOKEN",
        "WHATSAPP_PHONE_NUMBER_ID",
        "WHATSAPP_WEBHOOK_VERIFY_TOKEN",
        "WHATSAPP_APP_SECRET",
        "RESEND_API_KEY",
        "LLM_PROVIDER",
        "OPENAI_API_KEY",
        "GEMINI_API_KEY",
        "FASTAPI_URL",
        "FCM_CREDENTIALS_PATH",
    ]:
        env.pop(key, None)

    if include_settings:
        env.update(
            {
                "DATABASE_URL": build_database_url(driver="asyncpg", host="localhost"),
                "JWT_SECRET": "x" * 32,
                "MCP_SERVICE_TOKEN": "y" * 32,
                "WHATSAPP_TOKEN": "placeholder-whatsapp-token",
                "WHATSAPP_PHONE_NUMBER_ID": "123456",
                "WHATSAPP_WEBHOOK_VERIFY_TOKEN": "verify-token",
                "RESEND_API_KEY": "re_test_key",
            }
        )

    return env


def run_fastapi_container_command(*args: str) -> subprocess.CompletedProcess[str]:
    return run_command(
        ["docker", "compose", "exec", "-T", "fastapi-app", *args],
        cwd=REPO_ROOT,
        timeout=180,
    )


def run_alembic_upgrade_head() -> subprocess.CompletedProcess[str]:
    return run_fastapi_container_command("alembic", "upgrade", "head")


def run_alembic_check() -> subprocess.CompletedProcess[str]:
    return run_fastapi_container_command("alembic", "check")


def run_seed() -> subprocess.CompletedProcess[str]:
    return run_fastapi_container_command("python", "-m", "scripts.seed")


@pytest.fixture(scope="session", autouse=True)
def require_docker_healthy():
    """Pre-flight check: verify Docker containers are running before phase_01 tests.

    Phase_01 tests execute commands inside shared Docker containers (postgres, fastapi-app).
    If containers are not running, tests fail with cryptic subprocess errors.
    This fixture fails fast with a clear diagnostic message instead.
    """
    result = subprocess.run(
        ["docker", "compose", "ps", "--status", "running", "--format", "{{.Service}}"],
        capture_output=True,
        text=True,
        timeout=30,
    )
    running_services = set(result.stdout.strip().splitlines())
    required = {"postgres", "fastapi-app"}
    missing = required - running_services

    if missing:
        pytest.fail(
            f"Docker pre-flight check failed: containers not running: {', '.join(sorted(missing))}.\n"
            f"Running services: {running_services or '(none)'}.\n"
            f"Run 'docker compose up -d' before executing phase_01 tests."
        )
