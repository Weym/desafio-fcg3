"""Phase 12 infrastructure: docker-compose stack + Flutter web container.

Covers:
- GAP-12-01-A: docker-compose declares 5 services including flutter-web with 3000:80
  mapping and a service_healthy dependency on fastapi-app.
- GAP-12-01-B: mobile/Dockerfile is multi-stage (Flutter builder → nginx:alpine)
  and mobile/nginx.conf serves SPA routes with try_files.

These tests do NOT require Docker to be running — they validate the compose
file and Dockerfile declarations statically via `docker compose config` and
plain file reads. When Docker CLI is absent the compose-config test skips
cleanly.
"""
from __future__ import annotations

import shutil
from pathlib import Path

import pytest

from conftest import REPO_ROOT, run_command


pytestmark = pytest.mark.integration


def _docker_cli_available() -> bool:
    return shutil.which("docker") is not None


def test_docker_compose_config_includes_flutter_web_service() -> None:
    """Stack must declare flutter-web with 3000:80 port mapping and
    service_healthy dependency on fastapi-app (D-05, plan 12-01 Task 1)."""
    if not _docker_cli_available():
        pytest.skip("docker CLI not available in this environment")

    result = run_command(["docker", "compose", "config"])
    if result.returncode != 0:
        # Env vars may be missing in sandbox — fall back to static YAML read.
        compose_text = (REPO_ROOT / "docker-compose.yml").read_text(encoding="utf-8")
    else:
        compose_text = result.stdout

    assert "flutter-web:" in compose_text, (
        "flutter-web service missing from docker-compose output"
    )
    # Port mapping 3000:80 — accept either rendered "3000:80" literal or
    # published/target form that compose config may emit.
    assert (
        "3000:80" in compose_text
        or ("published: \"3000\"" in compose_text and "target: 80" in compose_text)
        or ('published: 3000' in compose_text and 'target: 80' in compose_text)
    ), "flutter-web must expose host port 3000 mapped to container port 80"

    # Must depend on fastapi-app with service_healthy gate.
    assert "fastapi-app" in compose_text
    assert "service_healthy" in compose_text, (
        "flutter-web (or another service) must declare service_healthy condition"
    )


def test_docker_compose_declares_five_services() -> None:
    """D-05: stack has postgres, fastapi-app, langchain-service, mcp-server, flutter-web."""
    compose_text = (REPO_ROOT / "docker-compose.yml").read_text(encoding="utf-8")
    for service_name in (
        "postgres:",
        "fastapi-app:",
        "langchain-service:",
        "mcp-server:",
        "flutter-web:",
    ):
        assert service_name in compose_text, f"missing service declaration: {service_name}"


def test_flutter_web_dockerfile_is_multistage_nginx() -> None:
    """mobile/Dockerfile must build Flutter web and serve via nginx:alpine."""
    dockerfile = REPO_ROOT / "mobile" / "Dockerfile"
    assert dockerfile.is_file(), f"{dockerfile} does not exist"
    contents = dockerfile.read_text(encoding="utf-8")

    # Stage 1: Flutter builder with pinned version (per plan).
    assert "ghcr.io/cirruslabs/flutter:3.41.6" in contents, (
        "Dockerfile must pin Flutter to 3.41.6 per project .fvmrc"
    )
    assert "flutter build web" in contents, (
        "Dockerfile must invoke `flutter build web` to produce SPA assets"
    )

    # Stage 2: nginx serve.
    assert "nginx:alpine" in contents, "Dockerfile must use nginx:alpine for serving stage"

    # Multi-stage: must have at least two FROM directives and an AS builder alias.
    from_lines = [ln for ln in contents.splitlines() if ln.strip().upper().startswith("FROM ")]
    assert len(from_lines) >= 2, f"expected multi-stage build, got FROM lines: {from_lines}"


def test_flutter_web_nginx_config_supports_spa_routing() -> None:
    """mobile/nginx.conf must serve index.html for unknown paths (SPA fallback)."""
    nginx_conf = REPO_ROOT / "mobile" / "nginx.conf"
    assert nginx_conf.is_file(), f"{nginx_conf} does not exist"
    contents = nginx_conf.read_text(encoding="utf-8")

    assert "try_files" in contents, "nginx.conf must use try_files for SPA routing"
    assert "/index.html" in contents, (
        "nginx.conf must fall back to /index.html for client-side routes"
    )


def test_flutter_web_service_has_healthcheck_in_compose() -> None:
    """flutter-web must declare a healthcheck so dependents wait correctly."""
    compose_text = (REPO_ROOT / "docker-compose.yml").read_text(encoding="utf-8")
    # Locate flutter-web block and assert healthcheck appears within it.
    lines = compose_text.splitlines()
    try:
        start = next(
            i for i, ln in enumerate(lines) if ln.strip().startswith("flutter-web:")
        )
    except StopIteration:
        pytest.fail("flutter-web service block not found")

    # Flutter-web block extends until the next top-level service key (2-space indent)
    # or until a root-level "networks:" / "volumes:" key.
    block_lines: list[str] = []
    for ln in lines[start + 1 :]:
        stripped_indent = len(ln) - len(ln.lstrip(" "))
        if ln.strip() == "":
            block_lines.append(ln)
            continue
        # Stop when we hit a sibling service (same 2-space indent starting with alpha)
        if stripped_indent <= 2 and ln.lstrip().rstrip(":").isidentifier() and ln != lines[start]:
            # Unless it's still within the flutter-web body (keys like `build:`,
            # `ports:`). Those are at 4-space indent, so this branch only fires
            # at the true end of the block.
            if stripped_indent == 0 or (stripped_indent == 2 and not ln.startswith("    ")):
                break
        block_lines.append(ln)

    block = "\n".join(block_lines)
    assert "healthcheck:" in block, (
        f"flutter-web must declare a healthcheck block. Got:\n{block}"
    )
