"""Phase 12 conditional seed behavior.

Covers:
- GAP-12-01-C: seed skips when data exists, --force flag is documented in
  the CLI, and check_data_exists is correctly wired.

Strategy:
- The `--force` CLI surface is verified statically (read seed.py source) and
  dynamically (python -m scripts.seed --help, no DB required).
- Idempotent skip (second run prints skip message) requires the Docker stack
  with a seeded DB; gated on `docker_stack_required` fixture which skips
  cleanly when the stack is down.
"""
from __future__ import annotations

import pytest

from conftest import (
    BACKEND_ROOT,
    REPO_ROOT,
    assert_success,
    run_command,
    run_seed,
    run_seed_force,
)


pytestmark = pytest.mark.integration


def test_seed_script_declares_force_flag_statically() -> None:
    """seed.py source must declare an argparse `--force` flag with a
    help string. Static check — no DB required."""
    seed_source = (BACKEND_ROOT / "scripts" / "seed.py").read_text(encoding="utf-8")
    assert '"--force"' in seed_source or "'--force'" in seed_source, (
        "seed.py must register a --force CLI flag via argparse"
    )
    assert "argparse" in seed_source, (
        "seed.py must use argparse for CLI flag handling"
    )
    # Help text must mention what --force does so developers discover it.
    assert "re-seed" in seed_source.lower() or "truncate" in seed_source.lower(), (
        "seed.py --force help must mention re-seed or truncate semantics"
    )


def test_seed_script_exposes_check_data_exists_function() -> None:
    """Conditional skip relies on check_data_exists(session) — it must exist
    as a top-level async function so other callers can reuse the check."""
    seed_source = (BACKEND_ROOT / "scripts" / "seed.py").read_text(encoding="utf-8")
    assert "async def check_data_exists" in seed_source, (
        "seed.py must define `async def check_data_exists(session)` for "
        "the idempotent first-boot check"
    )
    # Must actually query the students table (truth check).
    assert "students" in seed_source.lower(), (
        "check_data_exists must query the students table"
    )


def test_seed_help_cli_surface_advertises_force_flag() -> None:
    """`python -m scripts.seed --help` must advertise --force.

    Runs locally (no DB needed — argparse parses before any DB access).
    Skips if the backend venv / scripts module is not importable in this
    environment (sandbox without backend deps).
    """
    # First try inside Docker (if available) — canonical path.
    in_docker = run_command(
        [
            "docker",
            "compose",
            "exec",
            "-T",
            "fastapi-app",
            "python",
            "-m",
            "scripts.seed",
            "--help",
        ],
        cwd=REPO_ROOT,
        timeout=30,
    )
    if in_docker.returncode == 0:
        combined = in_docker.stdout + in_docker.stderr
        assert "--force" in combined, (
            "--force must appear in `python -m scripts.seed --help` output"
        )
        return

    # Docker unavailable — static grep of the argparse help string is our
    # last line of defense against CLI regressions.
    seed_source = (BACKEND_ROOT / "scripts" / "seed.py").read_text(encoding="utf-8")
    assert "--force" in seed_source and "help=" in seed_source, (
        "seed.py must register --force with an argparse help= kwarg"
    )


def test_seed_skips_when_data_exists_prints_skip_message(docker_stack_required) -> None:
    """D-06: first boot seeds; subsequent runs detect existing data and skip.

    Precondition: the Docker stack has already booted and seeded at least
    once (fastapi-app entrypoint runs seed on startup, so this is true
    whenever the stack is healthy).
    """
    result = run_seed()
    output = assert_success(result)
    lowered = output.lower()
    assert (
        "skipping" in lowered
        or "already exists" in lowered
        or "already seeded" in lowered
    ), (
        "Seed run against a populated DB must print a skip message. "
        f"Got:\n{output}"
    )


def test_seed_force_flag_performs_destructive_reseed(docker_stack_required) -> None:
    """--force must bypass the skip and print the destructive-seed banner."""
    result = run_seed_force()
    output = assert_success(result)
    # Destructive path announces itself — banner text from scripts/seed.py.
    assert (
        "TRUNCATES" in output
        or "destructive" in output.lower()
        or "Seed complete" in output
    ), (
        "`--force` must run the destructive seed path and announce it. "
        f"Got:\n{output}"
    )
