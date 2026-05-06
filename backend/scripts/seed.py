#!/usr/bin/env python3
"""Destructive seed script for the FCG3 development database.

WARNING: this script truncates and recreates development data for curriculum,
users, current-period enrollments, documents, and scheduling fixtures.

Run with:
  docker compose exec fastapi-app python -m scripts.seed
  python -m scripts.seed
"""

from __future__ import annotations

import asyncio
import sys
from dataclasses import dataclass, field
from datetime import UTC, date, datetime, time, timedelta
from decimal import Decimal
from pathlib import Path

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from src.features.auth.models import Staff, Student
# noqa: F401 — chat models must be imported so SQLAlchemy can resolve Student relationships.
from src.features.chat.models import ChatMessage, ChatSession, McpActionLog  # noqa: F401
from src.features.courses.models import Course, Curriculum, CurriculumCourse, Prerequisite
from src.features.documents.models import Document
from src.features.enrollment.models import Enrollment, EnrollmentCourse, EnrollmentPeriod
from src.features.scheduling.models import Appointment, Resource, SchedulingSlot
from src.features.students.models import Grade
from src.infrastructure.database import async_session


WARNING_TABLES = [
    "knowledge_base_chunks",
    "mcp_action_logs",
    "chat_messages",
    "chat_sessions",
    "documents",
    "appointments",
    "grades",
    "enrollment_courses",
    "enrollments",
    "enrollment_periods",
    "scheduling_slots",
    "resources",
    "fcm_tokens",
    "sessions",
    "verification_codes",
    "staff",
    "students",
    "curriculum_courses",
    "prerequisites",
    "courses",
    "curriculum",
]

COURSES_DATA = [
    ("SCC0101", "Introdução à Computação", 4, 60, 1, True),
    ("SCC0102", "Algoritmos e Estruturas de Dados I", 4, 60, 1, True),
    ("SMA0300", "Cálculo I", 4, 60, 1, True),
    ("SMA0354", "Álgebra Linear e Geometria Analítica", 4, 60, 1, True),
    ("SCC0103", "Laboratório de Introdução à Ciência da Computação I", 2, 30, 1, True),
    ("SCC0201", "Algoritmos e Estruturas de Dados II", 4, 60, 2, True),
    ("SCC0202", "Laboratório de Introdução à Ciência da Computação II", 2, 30, 2, True),
    ("SMA0301", "Cálculo II", 4, 60, 2, True),
    ("SMA0355", "Álgebra Linear II", 4, 60, 2, True),
    ("SSC0101", "Organização de Computadores Digitais", 4, 60, 2, True),
    ("SCC0210", "Estruturas de Dados", 4, 60, 3, True),
    ("SCC0211", "Laboratório de Organização e Arquitetura de Computadores", 2, 30, 3, True),
    ("SMA0356", "Probabilidade e Estatística", 4, 60, 3, True),
    ("SSC0301", "Arquitetura de Computadores", 4, 60, 3, True),
    ("SCC0212", "Programação Orientada a Objetos", 4, 60, 3, True),
    ("SCC0301", "Programação Funcional", 4, 60, 4, True),
    ("SCC0302", "Análise e Projeto de Algoritmos", 4, 60, 4, True),
    ("SCC0303", "Bases de Dados", 4, 60, 4, True),
    ("SSC0302", "Sistemas Operacionais I", 4, 60, 4, True),
    ("SCC0304", "Laboratório de Bases de Dados", 2, 30, 4, True),
    ("SCC0401", "Compiladores", 4, 60, 5, True),
    ("SCC0402", "Teoria dos Grafos", 4, 60, 5, True),
    ("SCC0403", "Redes de Computadores", 4, 60, 5, True),
    ("SSC0401", "Sistemas Operacionais II", 4, 60, 5, True),
    ("SCC0404", "Linguagens Formais e Autômatos", 4, 60, 5, True),
    ("SCC0501", "Inteligência Artificial", 4, 60, 6, True),
    ("SCC0502", "Computação Gráfica", 4, 60, 6, True),
    ("SCC0503", "Engenharia de Software I", 4, 60, 6, True),
    ("SSC0501", "Segurança da Computação", 4, 60, 6, True),
    ("SCC0504", "Sistemas Distribuídos I", 4, 60, 6, True),
    ("SCC0601", "Processamento de Linguagem Natural", 4, 60, 7, True),
    ("SCC0602", "Aprendizado de Máquina", 4, 60, 7, True),
    ("SCC0603", "Engenharia de Software II", 4, 60, 7, True),
    ("SCC0604", "Interação Humano-Computador", 4, 60, 7, False),
    ("SCC0605", "Tópicos Avançados em Ciência da Computação", 4, 60, 7, False),
    ("SCC0701", "Trabalho de Conclusão de Curso I", 4, 60, 8, True),
    ("SCC0702", "Trabalho de Conclusão de Curso II", 4, 60, 8, True),
    ("SCC0703", "Estágio Supervisionado", 4, 60, 8, True),
    ("SCC0704", "Empreendedorismo em Software", 4, 60, 8, False),
    ("SCC0705", "Ciência de Dados", 4, 60, 8, False),
]

PREREQUISITE_DATA = [
    ("SCC0201", "SCC0102"),
    ("SCC0202", "SCC0103"),
    ("SMA0301", "SMA0300"),
    ("SMA0355", "SMA0354"),
    ("SSC0301", "SSC0101"),
    ("SCC0210", "SCC0201"),
    ("SCC0211", "SSC0101"),
    ("SCC0212", "SCC0201"),
    ("SCC0301", "SCC0212"),
    ("SCC0302", "SCC0210"),
    ("SCC0303", "SCC0201"),
    ("SSC0302", "SSC0301"),
    ("SCC0304", "SCC0303"),
    ("SCC0401", "SCC0302"),
    ("SCC0402", "SCC0210"),
    ("SCC0403", "SSC0301"),
    ("SSC0401", "SSC0302"),
    ("SCC0404", "SCC0302"),
    ("SCC0501", "SCC0402"),
    ("SCC0502", "SCC0212"),
    ("SCC0503", "SCC0303"),
    ("SSC0501", "SSC0401"),
    ("SCC0504", "SCC0403"),
    ("SCC0601", "SCC0501"),
    ("SCC0602", "SCC0501"),
    ("SCC0603", "SCC0503"),
    ("SCC0701", "SCC0603"),
    ("SCC0702", "SCC0701"),
    ("SCC0703", "SCC0503"),
    ("SCC0705", "SCC0602"),
]

ACTIVE_PERIOD_SEMESTER_YEAR = "2026.1"


@dataclass(frozen=True)
class EnrolledCourseSeed:
    """Course enrolled for the active period. grade_1 is optional (only for confirmed enrollments)."""

    code: str
    grade_1: Decimal | None = None


@dataclass(frozen=True)
class DocumentSeed:
    type: str  # transcript | enrollment_proof | declaration | certificate
    status: str  # requested | processing | ready | delivered
    file_url: str | None = None
    notes: str | None = None
    requested_days_ago: int = 1
    completed_days_ago: int | None = None


@dataclass(frozen=True)
class AppointmentSeed:
    slot_index: int  # index into the list of slots generated by seed_scheduling
    reason: str
    status: str = "scheduled"


@dataclass(frozen=True)
class StudentSeed:
    name: str
    email: str
    phone: str
    registration_number: str
    semester: int
    enrollment_year: int
    status: str
    enrollment_status: str  # draft | confirmed
    courses: tuple[EnrolledCourseSeed, ...] = field(default_factory=tuple)
    documents: tuple[DocumentSeed, ...] = field(default_factory=tuple)
    appointments: tuple[AppointmentSeed, ...] = field(default_factory=tuple)


STUDENTS_DATA: tuple[StudentSeed, ...] = (
    StudentSeed(
        name="Henry Gabriel Andrade Oliveira",
        email="henrygabrielandradeoliveira@gmail.com",
        phone="5583998257544",
        registration_number="20260001",
        semester=1,
        enrollment_year=2026,
        status="active",
        enrollment_status="confirmed",
        courses=(
            EnrolledCourseSeed("SCC0101", Decimal("8.50")),
            EnrolledCourseSeed("SCC0102", Decimal("7.80")),
            EnrolledCourseSeed("SCC0103", Decimal("9.20")),
            EnrolledCourseSeed("SMA0300", Decimal("6.50")),
            EnrolledCourseSeed("SMA0354", Decimal("7.00")),
        ),
        documents=(
            DocumentSeed(
                type="enrollment_proof",
                status="processing",
                notes="Algum comprovante ai",
                requested_days_ago=3,
            ),
            DocumentSeed(
                type="enrollment_proof",
                status="requested",
                requested_days_ago=1,
            ),
        ),
        appointments=(
            AppointmentSeed(slot_index=0, reason="Dúvidas sobre plano de estudos"),
        ),
    ),
    StudentSeed(
        name="Ricardo Felix Rossi",
        email="ricardofelixrossi@gmail.com",
        phone="5512981255104",
        registration_number="20260002",
        semester=1,
        enrollment_year=2026,
        status="active",
        enrollment_status="confirmed",
        courses=(
            EnrolledCourseSeed("SCC0101", Decimal("9.00")),
            EnrolledCourseSeed("SCC0102", Decimal("8.50")),
            EnrolledCourseSeed("SMA0300", Decimal("7.20")),
            EnrolledCourseSeed("SMA0354", Decimal("8.00")),
        ),
        documents=(
            DocumentSeed(
                type="declaration",
                status="processing",
                notes="Declaração de vínculo para estágio",
                requested_days_ago=2,
            ),
        ),
    ),
    StudentSeed(
        name="Carol Cabral",
        email="carolcabralmm@gmail.com",
        phone="5521991227253",
        registration_number="20260003",
        semester=1,
        enrollment_year=2026,
        status="active",
        enrollment_status="confirmed",
        courses=(
            EnrolledCourseSeed("SCC0101", Decimal("7.50")),
            EnrolledCourseSeed("SCC0102", Decimal("8.00")),
            EnrolledCourseSeed("SMA0300", Decimal("6.00")),
        ),
        documents=(
            DocumentSeed(type="enrollment_proof", status="requested", requested_days_ago=2),
            DocumentSeed(type="transcript", status="requested", requested_days_ago=1),
        ),
        appointments=(
            AppointmentSeed(
                slot_index=1,
                reason="Orientação sobre aproveitamento de disciplinas",
            ),
        ),
    ),
    StudentSeed(
        name="Felipe Mello",
        email="felipemello29@gmail.com",
        phone="557184281661",
        registration_number="20260004",
        semester=1,
        enrollment_year=2026,
        status="active",
        enrollment_status="draft",
        courses=(
            EnrolledCourseSeed("SCC0101"),
            EnrolledCourseSeed("SCC0102"),
            EnrolledCourseSeed("SCC0103"),
            EnrolledCourseSeed("SMA0300"),
            EnrolledCourseSeed("SMA0354"),
        ),
        documents=(
            DocumentSeed(
                type="enrollment_proof",
                status="ready",
                file_url="https://storage.example.com/docs/felipe_comprovante_2026_1.pdf",
                requested_days_ago=4,
                completed_days_ago=1,
            ),
        ),
    ),
    StudentSeed(
        name="G. Rezende",
        email="grezende310@gmail.com",
        phone="5511983422765",
        registration_number="20260005",
        semester=1,
        enrollment_year=2026,
        status="active",
        enrollment_status="confirmed",
        courses=(
            EnrolledCourseSeed("SCC0101", Decimal("8.80")),
            EnrolledCourseSeed("SCC0102", Decimal("9.50")),
            EnrolledCourseSeed("SCC0103", Decimal("9.00")),
            EnrolledCourseSeed("SMA0300", Decimal("7.50")),
        ),
        documents=(
            DocumentSeed(
                type="transcript",
                status="requested",
                notes="Para processo seletivo de monitoria",
                requested_days_ago=1,
            ),
        ),
    ),
    StudentSeed(
        name="Weydson Marinho",
        email="weydsonmarinho@gmail.com",
        phone="558198421266",
        registration_number="20260006",
        semester=1,
        enrollment_year=2026,
        status="active",
        enrollment_status="draft",
        courses=(
            EnrolledCourseSeed("SCC0101"),
            EnrolledCourseSeed("SMA0300"),
            EnrolledCourseSeed("SMA0354"),
        ),
        documents=(
            DocumentSeed(
                type="enrollment_proof",
                status="ready",
                file_url="https://storage.example.com/docs/weydson_comprovante_2026_1.pdf",
                requested_days_ago=6,
                completed_days_ago=2,
            ),
        ),
        appointments=(
            AppointmentSeed(slot_index=2, reason="Dúvidas sobre matrícula 2026.1"),
        ),
    ),
)


STAFF_DATA = (
    {
        "name": "Henry (Staff)",
        "email": "universalblackout1@gmail.com",
        "role": "secretary",
    },
)


def validate_seed_shapes() -> None:
    semesters = {semester for *_prefix, semester, _required in COURSES_DATA}
    if len(COURSES_DATA) != 40:
        raise ValueError(f"Expected 40 seeded courses, found {len(COURSES_DATA)}")
    if semesters != set(range(1, 9)):
        raise ValueError(f"Expected semesters 1-8, found {sorted(semesters)}")

    adjacency: dict[str, set[str]] = {}
    for course_code, prerequisite_code in PREREQUISITE_DATA:
        adjacency.setdefault(course_code, set()).add(prerequisite_code)
        adjacency.setdefault(prerequisite_code, set())

    visited: set[str] = set()
    active_stack: set[str] = set()

    def visit(node: str) -> None:
        if node in active_stack:
            raise ValueError(f"Prerequisite cycle detected at {node}")
        if node in visited:
            return
        active_stack.add(node)
        for dependency in adjacency.get(node, set()):
            visit(dependency)
        active_stack.remove(node)
        visited.add(node)

    for course_code in adjacency:
        visit(course_code)

    # Confirmed students must have grade_1 for every enrolled course;
    # draft students must not have grades assigned yet.
    for student in STUDENTS_DATA:
        if student.enrollment_status == "confirmed":
            for course in student.courses:
                if course.grade_1 is None:
                    raise ValueError(
                        f"Confirmed enrollment for {student.email} missing grade_1 for {course.code}"
                    )
        elif student.enrollment_status == "draft":
            for course in student.courses:
                if course.grade_1 is not None:
                    raise ValueError(
                        f"Draft enrollment for {student.email} cannot have grade_1 on {course.code}"
                    )
        else:
            raise ValueError(
                f"Unknown enrollment_status={student.enrollment_status!r} for {student.email}"
            )


async def truncate_seed_tables(session: AsyncSession) -> None:
    await session.execute(
        text(
            "TRUNCATE TABLE "
            + ", ".join(WARNING_TABLES)
            + " RESTART IDENTITY CASCADE"
        )
    )
    await session.commit()


async def seed_curriculum(session: AsyncSession) -> tuple[Curriculum, dict[str, Course]]:
    curriculum = Curriculum(name="CC 2026.1", year=2026, is_active=True)
    session.add(curriculum)
    await session.flush()

    courses_by_code: dict[str, Course] = {}
    for code, name, credits, workload_hours, semester, is_required in COURSES_DATA:
        course = Course(
            code=code,
            name=name,
            credits=credits,
            workload_hours=workload_hours,
        )
        session.add(course)
        await session.flush()
        courses_by_code[code] = course
        session.add(
            CurriculumCourse(
                curriculum_id=curriculum.id,
                course_id=course.id,
                semester=semester,
                is_required=is_required,
            )
        )

    for course_code, prerequisite_code in PREREQUISITE_DATA:
        session.add(
            Prerequisite(
                course_id=courses_by_code[course_code].id,
                prerequisite_id=courses_by_code[prerequisite_code].id,
            )
        )

    await session.commit()
    return curriculum, courses_by_code


async def seed_active_period(session: AsyncSession) -> EnrollmentPeriod:
    today = date.today()
    active_period = EnrollmentPeriod(
        name=f"{ACTIVE_PERIOD_SEMESTER_YEAR} - Matrícula",
        type="enrollment",
        start_date=today - timedelta(days=15),
        end_date=today + timedelta(days=15),
        semester_year=ACTIVE_PERIOD_SEMESTER_YEAR,
        is_active=True,
    )
    session.add(active_period)
    await session.commit()
    return active_period


async def seed_scheduling(session: AsyncSession) -> list[SchedulingSlot]:
    resource = Resource(
        name="Sala de Coordenação",
        resource_type="room",
        capacity=10,
        location="Bloco 3, Sala 301",
        is_available=True,
    )
    session.add(resource)
    await session.flush()

    base_day = date.today() + timedelta(days=1)
    slot_specs = [
        (base_day, time(9, 0), time(10, 0)),
        (base_day, time(10, 0), time(11, 0)),
        (base_day + timedelta(days=1), time(14, 0), time(15, 0)),
        (base_day + timedelta(days=2), time(9, 0), time(10, 0)),
        (base_day + timedelta(days=2), time(10, 0), time(11, 0)),
    ]
    slots: list[SchedulingSlot] = []
    for slot_date, start_time, end_time in slot_specs:
        slot = SchedulingSlot(
            resource_id=resource.id,
            date=slot_date,
            start_time=start_time,
            end_time=end_time,
            is_available=True,
        )
        session.add(slot)
        slots.append(slot)

    await session.flush()
    await session.commit()
    return slots


async def seed_users_and_current_period(
    session: AsyncSession,
    curriculum: Curriculum,
    courses_by_code: dict[str, Course],
    active_period: EnrollmentPeriod,
    slots: list[SchedulingSlot],
) -> None:
    # Staff
    for staff_data in STAFF_DATA:
        session.add(Staff(**staff_data))
    await session.flush()

    now = datetime.now(UTC)

    for student_seed in STUDENTS_DATA:
        student = Student(
            name=student_seed.name,
            email=student_seed.email,
            phone=student_seed.phone,
            registration_number=student_seed.registration_number,
            semester=student_seed.semester,
            enrollment_year=student_seed.enrollment_year,
            status=student_seed.status,
            curriculum_id=curriculum.id,
        )
        session.add(student)
        await session.flush()

        # Active-period enrollment
        if student_seed.courses:
            enrollment = Enrollment(
                student_id=student.id,
                enrollment_period_id=active_period.id,
                status=student_seed.enrollment_status,
                confirmed_at=(
                    now - timedelta(days=5)
                    if student_seed.enrollment_status == "confirmed"
                    else None
                ),
            )
            session.add(enrollment)
            await session.flush()

            for course_seed in student_seed.courses:
                course = courses_by_code[course_seed.code]
                enrollment_course = EnrollmentCourse(
                    enrollment_id=enrollment.id,
                    course_id=course.id,
                    status="enrolled",
                )
                session.add(enrollment_course)
                await session.flush()

                if course_seed.grade_1 is not None:
                    session.add(
                        Grade(
                            student_id=student.id,
                            course_id=course.id,
                            enrollment_course_id=enrollment_course.id,
                            semester_year=ACTIVE_PERIOD_SEMESTER_YEAR,
                            grade_1=course_seed.grade_1,
                            grade_2=None,
                            grade_final=None,
                            status="in_progress",
                        )
                    )

        # Documents
        for doc in student_seed.documents:
            requested_at = now - timedelta(days=doc.requested_days_ago)
            completed_at = (
                now - timedelta(days=doc.completed_days_ago)
                if doc.completed_days_ago is not None
                else None
            )
            session.add(
                Document(
                    student_id=student.id,
                    type=doc.type,
                    status=doc.status,
                    file_url=doc.file_url,
                    notes=doc.notes,
                    requested_at=requested_at,
                    completed_at=completed_at,
                )
            )

        # Appointments (mark slot unavailable)
        for appt in student_seed.appointments:
            if appt.slot_index >= len(slots):
                raise ValueError(
                    f"Appointment slot_index={appt.slot_index} out of range "
                    f"for {student_seed.email} (only {len(slots)} slots)"
                )
            slot = slots[appt.slot_index]
            session.add(
                Appointment(
                    student_id=student.id,
                    slot_id=slot.id,
                    reason=appt.reason,
                    status=appt.status,
                )
            )
            slot.is_available = False

    await session.commit()


async def print_summary(session: AsyncSession) -> None:
    summary_queries = {
        "courses": "SELECT count(*) FROM courses",
        "students": "SELECT count(*) FROM students",
        "staff": "SELECT count(*) FROM staff",
        "prerequisites": "SELECT count(*) FROM prerequisites",
        "curriculum_courses": "SELECT count(*) FROM curriculum_courses",
        "enrollments": "SELECT count(*) FROM enrollments",
        "enrollment_courses": "SELECT count(*) FROM enrollment_courses",
        "grades": "SELECT count(*) FROM grades",
        "documents": "SELECT count(*) FROM documents",
        "enrollment_periods": "SELECT count(*) FROM enrollment_periods",
        "resources": "SELECT count(*) FROM resources",
        "scheduling_slots": "SELECT count(*) FROM scheduling_slots",
        "appointments": "SELECT count(*) FROM appointments",
    }
    for label, query in summary_queries.items():
        result = await session.execute(text(query))
        print(f"- {label}: {result.scalar_one()}")


async def main() -> None:
    print("⚠️  WARNING: This script TRUNCATES and recreates development seed data.")
    print("⚠️  Affected tables: " + ", ".join(WARNING_TABLES))
    print("🌱 Starting destructive seed...")
    validate_seed_shapes()

    async with async_session() as session:
        await truncate_seed_tables(session)
        print("🗑️  Existing development data cleared")

        curriculum, courses_by_code = await seed_curriculum(session)
        print(f"📚 Curriculum seeded: {curriculum.name} with {len(courses_by_code)} courses")

        active_period = await seed_active_period(session)
        print(f"🗓️  Active enrollment period seeded: {active_period.semester_year}")

        slots = await seed_scheduling(session)
        print(f"🏫 Scheduling resource and {len(slots)} slots seeded")

        await seed_users_and_current_period(
            session, curriculum, courses_by_code, active_period, slots
        )
        print(
            f"👥 Students seeded: {len(STUDENTS_DATA)} | staff seeded: {len(STAFF_DATA)}"
        )

        print("📊 Final counts:")
        await print_summary(session)

    print("✅ Seed complete")


if __name__ == "__main__":
    asyncio.run(main())
