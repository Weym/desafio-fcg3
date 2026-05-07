"""Phase 12 environment template documentation.

Covers:
- GAP-12-01-D: .env.example must document DEV_MASTER_OTP=000000 with a
  production warning and clear DEV-ONLY demarcation.
"""
from __future__ import annotations

import pytest

from conftest import REPO_ROOT


pytestmark = pytest.mark.integration


def test_env_example_documents_dev_master_otp_with_production_warning() -> None:
    """DEV_MASTER_OTP must be declared with an unambiguous prod warning
    (per plan 12-01 Task 2 and threat-model T-12-01)."""
    env_example_path = REPO_ROOT / ".env.example"
    assert env_example_path.is_file(), f"{env_example_path} must exist"
    content = env_example_path.read_text(encoding="utf-8")

    # Value present with the well-known dev bypass code.
    assert "DEV_MASTER_OTP=000000" in content, (
        ".env.example must declare DEV_MASTER_OTP=000000 as the dev bypass default"
    )

    # Production warning — must be unambiguous about non-dev removal.
    lowered = content.lower()
    assert "must be unset in production" in lowered, (
        ".env.example must warn: 'MUST be unset in production' "
        "(case-insensitive) near DEV_MASTER_OTP"
    )

    # Section demarcation — "DEV ONLY" marker.
    assert "DEV ONLY" in content, (
        ".env.example must mark the dev-only section with a 'DEV ONLY' header"
    )


def test_env_example_dev_master_otp_appears_after_dev_only_section_header() -> None:
    """Ordering: the DEV ONLY section must precede the DEV_MASTER_OTP line
    so future readers see the warning before the value."""
    content = (REPO_ROOT / ".env.example").read_text(encoding="utf-8")
    dev_only_idx = content.find("DEV ONLY")
    otp_idx = content.find("DEV_MASTER_OTP=")
    assert dev_only_idx != -1, "DEV ONLY header missing"
    assert otp_idx != -1, "DEV_MASTER_OTP declaration missing"
    assert dev_only_idx < otp_idx, (
        "DEV ONLY section marker must appear BEFORE DEV_MASTER_OTP declaration"
    )
