"""Regression guard for the pg_cron session auto-close quoting bug.

History: Migration 011 originally nested SQL ``''single-quote''`` escapes inside
a ``$$...$$`` dollar-quoted block. Dollar-quoting already treats the body as a
literal, so the escape doubled the quotes in the stored ``cron.job.command`` —
every hourly run then failed with:

    ERROR: syntax error at or near "closed"

…leaving chat_sessions stuck in ``status='active'`` forever.

Migration 012 re-schedules the job with correct single-quote syntax. These
tests assert that the ``upgrade()`` body of each migration that installs the
cron job embeds the SQL with literal single quotes, not doubled ones, so a
future well-intentioned "style fix" cannot silently re-break it.

We deliberately do NOT try to parse the ``$$...$$`` block out of the Python
source — the module docstring / comments contain ``$$...$$`` and ``''`` tokens
for pedagogical reasons. Instead we extract the SQL *argument to*
``sa.text(...)`` directly, which is what actually reaches the database.
"""

from __future__ import annotations

import ast
from pathlib import Path
from typing import Iterable

import pytest


ALEMBIC_VERSIONS = Path(__file__).resolve().parents[2] / "alembic" / "versions"

MIGRATIONS_UNDER_TEST = (
    "011_add_pg_cron_session_autoclose.py",
    "012_fix_pg_cron_session_autoclose_quoting.py",
)


def _collect_module_string_constants(tree: ast.Module) -> dict[str, str]:
    """Gather ``NAME = "..."`` assignments at module scope where the value is
    a string literal (possibly built by adjacent-string-literal concatenation).
    """
    constants: dict[str, str] = {}
    for node in tree.body:
        if isinstance(node, ast.Assign) and isinstance(node.value, ast.Constant) \
                and isinstance(node.value.value, str):
            for target in node.targets:
                if isinstance(target, ast.Name):
                    constants[target.id] = node.value.value
    return constants


def _sa_text_literals_in(func_name: str, source: str) -> list[str]:
    """Return every string argument passed to ``sa.text(...)`` inside the
    named top-level function of ``source``, resolving references to
    module-level string constants as well.

    Python auto-concatenates adjacent string literals, so ``sa.text("a" "b")``
    yields ``"ab"`` in the AST — which is exactly what we want to scan.
    """
    tree = ast.parse(source)
    target = next(
        (n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == func_name),
        None,
    )
    assert target is not None, f"function {func_name}() not found"

    module_constants = _collect_module_string_constants(tree)
    entries: list[tuple[int, str]] = []
    for node in ast.walk(target):
        if not isinstance(node, ast.Call):
            continue
        callee = node.func
        if (
            isinstance(callee, ast.Attribute)
            and callee.attr == "text"
            and isinstance(callee.value, ast.Name)
            and callee.value.id == "sa"
        ):
            if not node.args:
                continue
            arg = node.args[0]
            lineno = getattr(node, "lineno", 0)
            if isinstance(arg, ast.Constant) and isinstance(arg.value, str):
                entries.append((lineno, arg.value))
            elif isinstance(arg, ast.Name) and arg.id in module_constants:
                entries.append((lineno, module_constants[arg.id]))
    # Sort by source line so callers can reason about order.
    entries.sort(key=lambda e: e[0])
    return [lit for _, lit in entries]


def _cron_schedule_bodies(literals: Iterable[str]) -> list[str]:
    """Keep only SQL literals that invoke ``cron.schedule`` for the auto-close
    job — i.e. the literal that installs the UPDATE body. Skips the companion
    ``cron.unschedule`` calls, which legitimately have no inner SQL tokens.
    """
    return [
        lit
        for lit in literals
        if "cron.schedule" in lit and "close-inactive-chat-sessions" in lit
    ]


@pytest.mark.parametrize("migration_file", MIGRATIONS_UNDER_TEST)
def test_upgrade_cron_sql_uses_single_quotes_not_doubled(migration_file: str) -> None:
    """``upgrade()`` must pass the cron body to ``sa.text()`` with literal
    single quotes around ``'closed'``, ``'active'``, ``'24 hours'`` — never
    doubled (``''closed''`` etc), because the surrounding ``$$...$$`` already
    makes the body literal.
    """
    source = (ALEMBIC_VERSIONS / migration_file).read_text(encoding="utf-8")
    literals = _sa_text_literals_in("upgrade", source)
    cron_bodies = _cron_schedule_bodies(literals)
    assert cron_bodies, (
        f"{migration_file}: no sa.text(...) call scheduling "
        f"'close-inactive-chat-sessions' found in upgrade()"
    )

    for body in cron_bodies:
        for token in ("closed", "active", "24 hours"):
            bad = f"''{token}''"
            assert bad not in body, (
                f"{migration_file} upgrade(): found doubled-quoted `{bad}` in the "
                f"cron.schedule SQL — this reintroduces the pg_cron syntax-error bug. "
                f"Use single quotes."
            )
            good = f"'{token}'"
            assert good in body, (
                f"{migration_file} upgrade(): expected single-quoted `{good}` in the "
                f"cron.schedule SQL but it is missing."
            )


def test_migration_012_unschedules_before_rescheduling() -> None:
    """Migration 012 must drop the broken cron.job before installing the fixed
    one, otherwise the old ``jobid`` keeps firing the bad command."""
    source = (
        ALEMBIC_VERSIONS / "012_fix_pg_cron_session_autoclose_quoting.py"
    ).read_text(encoding="utf-8")
    literals = _sa_text_literals_in("upgrade", source)

    unschedule_idx = next(
        (i for i, lit in enumerate(literals) if "cron.unschedule" in lit),
        None,
    )
    schedule_idx = next(
        (i for i, lit in enumerate(literals)
         if "cron.schedule" in lit and "close-inactive-chat-sessions" in lit),
        None,
    )

    assert unschedule_idx is not None, (
        "012 upgrade(): missing sa.text() call that unschedules the broken job"
    )
    assert schedule_idx is not None, (
        "012 upgrade(): missing sa.text() call that reschedules the fixed job"
    )
    assert unschedule_idx < schedule_idx, (
        "012 upgrade(): must unschedule the broken job before rescheduling"
    )
