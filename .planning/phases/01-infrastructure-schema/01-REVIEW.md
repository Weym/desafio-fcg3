---
phase: 01-infrastructure-schema
reviewed: 2026-04-24T11:46:02Z
depth: standard
files_reviewed: 33
files_reviewed_list:
  - .env.example
  - docker-compose.yml
  - backend/Dockerfile
  - backend/requirements.txt
  - backend/alembic.ini
  - backend/alembic/env.py
  - backend/alembic/versions/001_create_pgvector.py
  - backend/alembic/versions/002_create_auth_tables.py
  - backend/alembic/versions/003_create_curriculum_tables.py
  - backend/alembic/versions/004_create_enrollment_tables.py
  - backend/alembic/versions/005_create_documents_scheduling_tables.py
  - backend/alembic/versions/006_create_chat_knowledge_tables.py
  - backend/scripts/seed.py
  - backend/src/main.py
  - backend/src/routes.py
  - backend/src/infrastructure/config.py
  - backend/src/infrastructure/database.py
  - backend/src/infrastructure/models.py
  - backend/src/shared/schemas.py
  - backend/src/features/auth/models.py
  - backend/src/features/chat/models.py
  - backend/src/features/courses/models.py
  - backend/src/features/documents/models.py
  - backend/src/features/enrollment/models.py
  - backend/src/features/knowledge_base/models.py
  - backend/src/features/scheduling/models.py
  - backend/src/features/students/models.py
  - ai_service/Dockerfile
  - ai_service/main.py
  - ai_service/requirements.txt
  - mcp_server/Dockerfile
  - mcp_server/main.py
  - mcp_server/requirements.txt
findings:
  critical: 1
  warning: 1
  info: 1
  total: 3
status: issues_found
---

# Phase 01: Code Review Report

**Reviewed:** 2026-04-24T11:46:02Z
**Depth:** standard
**Files Reviewed:** 33
**Status:** issues_found

## Summary

Re-reviewed the current Phase 01 output after gap-closure plan 01-05. The backend import-path regression is fixed, but the phase still has one high-risk destructive-seed safety gap, one remaining ORM/migration drift issue, and no regression tests covering the repaired startup path or destructive seed workflow.

## Critical Issues

### CR-01: Destructive seed can wipe any configured database without an environment safety gate

**File:** `backend/scripts/seed.py:513-520`
**Issue:** The script immediately opens the configured database and truncates every academic/auth/chat table after only printing a warning. There is no runtime guard to ensure the target is a local/development database, so a misconfigured `DATABASE_URL` can cause irreversible data loss.
**Fix:**
```python
import os

from src.infrastructure.database import get_database_url


def assert_safe_seed_target() -> None:
    if os.getenv("ALLOW_DESTRUCTIVE_SEED") != "true":
        raise RuntimeError("Refusing to run destructive seed without ALLOW_DESTRUCTIVE_SEED=true")

    database_url = get_database_url()
    if not any(host in database_url for host in ("@postgres:", "@localhost:", "@127.0.0.1:")):
        raise RuntimeError(f"Refusing to seed non-local database: {database_url}")


async def main() -> None:
    assert_safe_seed_target()
    ...
```

## Warnings

### WR-01: Course ORM timestamps still drift from the migrated schema

**File:** `backend/src/features/courses/models.py:25,61`
**Issue:** `Course.created_at` and `Curriculum.created_at` still omit explicit `DateTime(timezone=True)` while the Alembic migrations create timezone-aware timestamps. This keeps model metadata out of sync with the real schema and can generate incorrect future Alembic diffs.
**Fix:**
```python
created_at: Mapped[datetime] = mapped_column(
    DateTime(timezone=True),
    nullable=False,
    server_default=func.now(),
)
```

## Info

### IN-01: No regression tests cover the repaired startup path or destructive seed workflow

**File:** `backend/src/main.py:1-11`, `backend/scripts/seed.py:513-538`
**Issue:** There are still no backend tests for `import src.main`, compose-style app boot, or the destructive seed safety/shape checks. The earlier import-path bug escaped because this path is only manually verified.
**Fix:** Add smoke tests under `backend/tests/` for package-root app import plus a seed test that asserts the safety gate and seed invariants before truncation runs.

---

_Reviewed: 2026-04-24T11:46:02Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
