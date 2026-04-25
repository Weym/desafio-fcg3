from __future__ import annotations

import sys

from conftest import (
    BACKEND_ROOT,
    assert_success,
    query_postgres,
    run_alembic_check,
    run_alembic_upgrade_head,
    run_seed,
)

sys.path.insert(0, str(BACKEND_ROOT))

from src.infrastructure.models import Base  # noqa: E402


def test_schema_metadata_and_live_database_expose_21_application_tables() -> None:
    assert len(Base.metadata.tables) == 21
    assert "knowledge_base_chunks" in Base.metadata.tables
    assert "mcp_action_logs" in Base.metadata.tables

    application_table_count = query_postgres(
        "SELECT count(*) FROM information_schema.tables "
        "WHERE table_schema='public' AND table_type='BASE TABLE' AND table_name <> 'alembic_version';"
    )
    alembic_head = query_postgres("SELECT version_num FROM alembic_version;")

    assert application_table_count == "21"
    assert alembic_head


def test_alembic_model_state_has_no_pending_upgrade_operations() -> None:
    upgrade_result = run_alembic_upgrade_head()
    assert_success(upgrade_result)

    check_result = run_alembic_check()
    combined_output = f"{check_result.stdout}\n{check_result.stderr}"

    assert check_result.returncode == 0, combined_output
    assert "No new upgrade operations detected." in combined_output


def test_seed_command_is_repeatable_and_preserves_expected_phase_one_fixtures() -> None:
    first_run = run_seed()
    assert_success(first_run)
    first_snapshot = {
        "courses": query_postgres("SELECT count(*) FROM courses;"),
        "semesters": query_postgres("SELECT count(DISTINCT semester) FROM curriculum_courses;"),
        "students": query_postgres("SELECT count(*) FROM students;"),
        "staff": query_postgres("SELECT count(*) FROM staff;"),
        "inactive_students": query_postgres("SELECT count(*) FROM students WHERE status='inactive';"),
        "failed_grades": query_postgres("SELECT count(*) FROM grades WHERE status='failed';"),
        "in_progress_grades": query_postgres("SELECT count(*) FROM grades WHERE status='in_progress';"),
        "resources": query_postgres("SELECT count(*) FROM resources;"),
        "scheduling_slots": query_postgres("SELECT count(*) FROM scheduling_slots;"),
        "active_periods": query_postgres("SELECT count(*) FROM enrollment_periods WHERE is_active = true;"),
        "prereq_chain": query_postgres(
            "SELECT p.code FROM prerequisites pr "
            "JOIN courses c ON c.id = pr.course_id "
            "JOIN courses p ON p.id = pr.prerequisite_id "
            "WHERE c.code = 'SCC0201';"
        ),
    }

    second_run = run_seed()
    assert_success(second_run)
    second_snapshot = {
        key: query_postgres(sql)
        for key, sql in {
            "courses": "SELECT count(*) FROM courses;",
            "semesters": "SELECT count(DISTINCT semester) FROM curriculum_courses;",
            "students": "SELECT count(*) FROM students;",
            "staff": "SELECT count(*) FROM staff;",
            "inactive_students": "SELECT count(*) FROM students WHERE status='inactive';",
            "failed_grades": "SELECT count(*) FROM grades WHERE status='failed';",
            "in_progress_grades": "SELECT count(*) FROM grades WHERE status='in_progress';",
            "resources": "SELECT count(*) FROM resources;",
            "scheduling_slots": "SELECT count(*) FROM scheduling_slots;",
            "active_periods": "SELECT count(*) FROM enrollment_periods WHERE is_active = true;",
            "prereq_chain": (
                "SELECT p.code FROM prerequisites pr "
                "JOIN courses c ON c.id = pr.course_id "
                "JOIN courses p ON p.id = pr.prerequisite_id "
                "WHERE c.code = 'SCC0201';"
            ),
        }.items()
    }

    assert first_snapshot == second_snapshot
    assert second_snapshot == {
        "courses": "40",
        "semesters": "8",
        "students": "5",
        "staff": "2",
        "inactive_students": "1",
        "failed_grades": "3",
        "in_progress_grades": "4",
        "resources": "1",
        "scheduling_slots": "5",
        "active_periods": "1",
        "prereq_chain": "SCC0102",
    }
