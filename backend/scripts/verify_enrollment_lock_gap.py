#!/usr/bin/env python3
"""Verify the confirm -> lock enrollment gap against PostgreSQL.

Run inside the FastAPI runtime container after `alembic upgrade head`:
    python -m scripts.verify_enrollment_lock_gap
"""

from __future__ import annotations

import asyncio
import sys
import uuid
from datetime import date, timedelta
from pathlib import Path

from sqlalchemy import select
from sqlalchemy.orm import selectinload

PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from src.features.auth.models import Student
import src.features.chat.models  # noqa: F401
from src.features.courses.models import Course
import src.features.documents.models  # noqa: F401
from src.features.enrollment.models import Enrollment, EnrollmentCourse, EnrollmentPeriod
import src.features.students.models  # noqa: F401
import src.features.knowledge_base.models  # noqa: F401
import src.features.scheduling.models  # noqa: F401
from src.features.enrollment.services import enrollment_service
from src.infrastructure.database import async_session
from src.shared.exceptions import ConflictException


def assert_true(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


async def seed_runtime_entities() -> tuple[uuid.UUID, uuid.UUID, uuid.UUID]:
    token = uuid.uuid4().hex[:8]
    student_id = uuid.uuid4()
    course_id = uuid.uuid4()
    period_id = uuid.uuid4()
    enrollment_id = uuid.uuid4()

    async with async_session() as session:
        student = Student(
            id=student_id,
            name=f"Lock Gap Student {token}",
            email=f"lock-gap-{token}@test.invalid",
            phone=f"+551199{token[:6]}",
            registration_number=f"LOCK{token[:8].upper()}",
            semester=1,
            enrollment_year=date.today().year,
            status="active",
        )
        course = Course(
            id=course_id,
            code=f"LG{token[:6].upper()}",
            name="Lock Gap Verification Course",
            credits=4,
            workload_hours=60,
        )
        period = EnrollmentPeriod(
            id=period_id,
            name=f"Lock Gap {token}",
            type="enrollment",
            start_date=date.today() - timedelta(days=1),
            end_date=date.today() + timedelta(days=7),
            semester_year=f"{date.today().year}.1",
            is_active=True,
        )
        enrollment = Enrollment(
            id=enrollment_id,
            student_id=student_id,
            enrollment_period_id=period_id,
            status="draft",
        )

        session.add_all([student, course, period])
        session.add(enrollment)
        await session.flush()

        enrollment_course = EnrollmentCourse(
            enrollment_id=enrollment.id,
            course_id=course_id,
            status="enrolled",
        )
        session.add(enrollment_course)
        await session.commit()

        return enrollment_id, student_id, course_id


async def verify_confirm_and_lock(enrollment_id: uuid.UUID, student_id: uuid.UUID) -> None:
    async with async_session() as session:
        confirmed = await enrollment_service.confirm_enrollment(session, enrollment_id, student_id)
        assert_true(confirmed.status == "confirmed", "confirm_enrollment did not return confirmed status")

        locked = await enrollment_service.lock_enrollment(session, enrollment_id, student_id)
        assert_true(locked.status == "locked", "lock_enrollment did not return locked status")
        assert_true(
            all(course.status == "locked" for course in locked.courses),
            "lock_enrollment did not return locked enrollment courses",
        )
        await session.commit()


async def verify_persisted_state(enrollment_id: uuid.UUID, course_id: uuid.UUID) -> None:
    async with async_session() as session:
        result = await session.execute(
            select(Enrollment)
            .options(selectinload(Enrollment.enrollment_courses))
            .where(Enrollment.id == enrollment_id)
        )
        enrollment = result.scalar_one()

        assert_true(enrollment.status == "locked", "database did not persist enrollments.status='locked'")

        course_statuses = {
            enrollment_course.course_id: enrollment_course.status
            for enrollment_course in enrollment.enrollment_courses
        }
        assert_true(course_statuses.get(course_id) == "locked", "database did not persist locked enrollment_course status")


async def verify_drop_rejected(enrollment_id: uuid.UUID, course_id: uuid.UUID, student_id: uuid.UUID) -> None:
    async with async_session() as session:
        try:
            await enrollment_service.drop_course(session, enrollment_id, course_id, student_id)
        except ConflictException as exc:
            assert_true(exc.code == "OPERACAO_NAO_PERMITIDA", "drop_course raised unexpected conflict code")
            assert_true("rascunho" in exc.message.lower(), "drop_course conflict message no longer documents draft-only rule")
            await session.rollback()
            return

        raise AssertionError("drop_course unexpectedly succeeded after lock")


async def main() -> None:
    enrollment_id, student_id, course_id = await seed_runtime_entities()
    await verify_confirm_and_lock(enrollment_id, student_id)
    await verify_persisted_state(enrollment_id, course_id)
    await verify_drop_rejected(enrollment_id, course_id, student_id)

    print(
        "PASS: confirm succeeded, lock persisted status='locked' in PostgreSQL, "
        "and drop_course remained blocked after lock."
    )


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except Exception as exc:  # pragma: no cover - script entrypoint
        print(f"FAIL: {exc}", file=sys.stderr)
        raise SystemExit(1) from exc
