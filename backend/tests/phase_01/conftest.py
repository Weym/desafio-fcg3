from __future__ import annotations

import os
import subprocess
import sys
from collections.abc import Sequence
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
BACKEND_ROOT = REPO_ROOT / "backend"
LOCAL_DATABASE_URL = "postgresql+asyncpg://fcg3:changeme@localhost:5432/fcg3"


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
            "fcg3",
            "-d",
            "fcg3",
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
                "DATABASE_URL": LOCAL_DATABASE_URL,
                "JWT_SECRET": "x" * 32,
                "MCP_SERVICE_TOKEN": "y" * 32,
                "WHATSAPP_TOKEN": "placeholder-whatsapp-token",
                "WHATSAPP_PHONE_NUMBER_ID": "123456",
                "WHATSAPP_WEBHOOK_VERIFY_TOKEN": "verify-token",
                "RESEND_API_KEY": "re_test_key",
            }
        )

    return env


def run_seed() -> subprocess.CompletedProcess[str]:
    env = os.environ.copy()
    env["DATABASE_URL"] = LOCAL_DATABASE_URL
    env["PYTHONIOENCODING"] = "utf-8"
    return run_command(
        [sys.executable, "-X", "utf8", "-m", "scripts.seed"],
        cwd=BACKEND_ROOT,
        env=env,
        timeout=180,
    )
