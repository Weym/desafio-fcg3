"""Conftest for phase_12 tests.

Mirrors backend/tests/phase_01/conftest.py helpers (run_command, REPO_ROOT,
BACKEND_ROOT, assert_success, query_postgres, run_seed) but is self-contained
— phase directories live outside any package (no __init__.py), so each phase's
conftest.py is independent and importable via `from conftest import ...`.

Docker-dependent tests gracefully skip when the stack is not running instead
of failing with cryptic subprocess errors. This keeps the suite usable in
any environment (CI, local dev, sandbox) while still exercising the contract
when Docker is available.
"""
from __future__ import annotations

import os
import subprocess
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


def run_seed() -> subprocess.CompletedProcess[str]:
    return run_command(
        ["docker", "compose", "exec", "-T", "fastapi-app", "python", "-m", "scripts.seed"],
        cwd=REPO_ROOT,
        timeout=180,
    )


def run_seed_force() -> subprocess.CompletedProcess[str]:
    return run_command(
        [
            "docker",
            "compose",
            "exec",
            "-T",
            "fastapi-app",
            "python",
            "-m",
            "scripts.seed",
            "--force",
        ],
        cwd=REPO_ROOT,
        timeout=180,
    )


def docker_stack_is_running() -> tuple[bool, set[str]]:
    """Return (stack_up, running_services). Never raises."""
    try:
        result = subprocess.run(
            ["docker", "compose", "ps", "--status", "running", "--format", "{{.Service}}"],
            capture_output=True,
            text=True,
            timeout=10,
        )
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return (False, set())
    if result.returncode != 0:
        return (False, set())
    running = {line.strip() for line in result.stdout.splitlines() if line.strip()}
    required = {"postgres", "fastapi-app"}
    return (required.issubset(running), running)


@pytest.fixture
def docker_stack_required():
    """Skip the test cleanly if the Docker stack is not healthy.

    Phase 12 contract tests that exercise live services (seed behavior,
    docker-compose runtime) rely on this fixture so the suite stays green
    even when the stack is down.
    """
    up, running = docker_stack_is_running()
    if not up:
        pytest.skip(
            "Docker stack not running (requires postgres + fastapi-app). "
            f"Currently running: {running or '(none)'}. "
            "Start with `docker compose up -d`."
        )
