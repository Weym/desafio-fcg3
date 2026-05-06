#!/usr/bin/env python3
"""Conditional seed script for the FCG3 development database.

On first boot, seeds the database with development fixtures. On subsequent
boots, detects existing data and exits cleanly (idempotent).

Use --force to truncate and re-create all development data.

Run with:
  docker compose exec fastapi-app python -m scripts.seed
  docker compose exec fastapi-app python -m scripts.seed --force
  python -m scripts.seed
"""

from __future__ import annotations

import argparse
import asyncio
import sys
from dataclasses import dataclass
from datetime import UTC, date, datetime, time, timedelta
from decimal import Decimal
from pathlib import Path

from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession

PROJECT_ROOT = Path(__file__).resolve().parent.parent
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from src.features.auth.models import Staff, Student
from src.features.chat.models import ChatMessage, ChatSession, McpActionLog
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


@dataclass(frozen=True)
class GradeRecord:
    code: str
    semester_year: str
    grade_1: Decimal | None
    grade_2: Decimal | None
    status: str


@dataclass(frozen=True)
class StudentSeed:
    name: str
    email: str
    phone: str
    registration_number: str
    semester: int
    enrollment_year: int
    status: str
    history: tuple[GradeRecord, ...]


STUDENTS_DATA = (
    StudentSeed(
        name="Ana Silva",
        email="ana.silva@usp.br",
        phone="5511987654321",
        registration_number="20250001",
        semester=2,
        enrollment_year=2025,
        status="active",
        history=(
            GradeRecord("SCC0101", "2025.1", Decimal("8.50"), Decimal("7.00"), "approved"),
            GradeRecord("SCC0102", "2025.1", Decimal("6.00"), Decimal("4.50"), "failed"),
            GradeRecord("SMA0300", "2025.1", Decimal("7.50"), Decimal("8.00"), "approved"),
            GradeRecord("SMA0354", "2025.1", Decimal("7.00"), Decimal("7.50"), "approved"),
            GradeRecord("SCC0103", "2025.1", Decimal("9.00"), Decimal("8.50"), "approved"),
        ),
    ),
    StudentSeed(
        name="Bruno Santos",
        email="bruno.santos@usp.br",
        phone="5511987654322",
        registration_number="20240002",
        semester=4,
        enrollment_year=2024,
        status="active",
        history=(
            GradeRecord("SCC0101", "2024.1", Decimal("9.00"), Decimal("8.50"), "approved"),
            GradeRecord("SCC0102", "2024.1", Decimal("7.50"), Decimal("8.00"), "approved"),
            GradeRecord("SMA0300", "2024.1", Decimal("6.50"), Decimal("7.00"), "approved"),
            GradeRecord("SMA0354", "2024.1", Decimal("8.00"), Decimal("7.50"), "approved"),
            GradeRecord("SCC0103", "2024.1", Decimal("7.50"), Decimal("8.00"), "approved"),
            GradeRecord("SCC0201", "2024.2", Decimal("5.00"), Decimal("6.50"), "approved"),
            GradeRecord("SMA0301", "2024.2", Decimal("4.00"), Decimal("5.50"), "failed"),
            GradeRecord("SSC0101", "2024.2", Decimal("7.00"), Decimal("7.50"), "approved"),
            GradeRecord("SCC0202", "2024.2", Decimal("8.00"), Decimal("7.50"), "approved"),
            GradeRecord("SMA0355", "2024.2", Decimal("6.50"), Decimal("7.00"), "approved"),
            GradeRecord("SCC0210", "2025.1", Decimal("8.00"), Decimal("7.50"), "approved"),
            GradeRecord("SCC0212", "2025.1", Decimal("6.50"), Decimal("7.00"), "approved"),
            GradeRecord("SMA0356", "2025.1", Decimal("7.00"), Decimal("7.50"), "approved"),
            GradeRecord("SSC0301", "2025.1", Decimal("7.50"), Decimal("8.00"), "approved"),
        ),
    ),
    StudentSeed(
        name="Carla Oliveira",
        email="carla.oliveira@usp.br",
        phone="5511987654323",
        registration_number="20230003",
        semester=6,
        enrollment_year=2023,
        status="active",
        history=(
            GradeRecord("SCC0101", "2023.1", Decimal("8.00"), Decimal("7.50"), "approved"),
            GradeRecord("SCC0102", "2023.1", Decimal("7.00"), Decimal("7.50"), "approved"),
            GradeRecord("SMA0300", "2023.1", Decimal("6.50"), Decimal("7.00"), "approved"),
            GradeRecord("SCC0201", "2023.2", Decimal("8.50"), Decimal("9.00"), "approved"),
            GradeRecord("SMA0301", "2023.2", Decimal("7.50"), Decimal("8.00"), "approved"),
            GradeRecord("SSC0101", "2023.2", Decimal("7.00"), Decimal("7.00"), "approved"),
            GradeRecord("SCC0210", "2024.1", Decimal("7.50"), Decimal("8.00"), "approved"),
            GradeRecord("SCC0303", "2024.1", Decimal("9.00"), Decimal("8.50"), "approved"),
            GradeRecord("SCC0302", "2024.2", Decimal("6.00"), Decimal("7.50"), "approved"),
            GradeRecord("SSC0302", "2024.2", Decimal("7.00"), Decimal("6.50"), "approved"),
            GradeRecord("SCC0401", "2025.1", Decimal("5.50"), Decimal("6.00"), "approved"),
            GradeRecord("SCC0403", "2025.1", Decimal("8.00"), Decimal("7.50"), "approved"),
            GradeRecord("SCC0501", "2025.2", Decimal("7.00"), None, "in_progress"),
            GradeRecord("SCC0503", "2025.2", Decimal("8.50"), None, "in_progress"),
        ),
    ),
    StudentSeed(
        name="Daniel Costa",
        email="daniel.costa@usp.br",
        phone="5511987654324",
        registration_number="20220004",
        semester=8,
        enrollment_year=2022,
        status="active",
        history=(
            GradeRecord("SCC0101", "2022.1", Decimal("9.00"), Decimal("8.50"), "approved"),
            GradeRecord("SCC0102", "2022.1", Decimal("8.00"), Decimal("8.50"), "approved"),
            GradeRecord("SCC0201", "2022.2", Decimal("7.50"), Decimal("8.00"), "approved"),
            GradeRecord("SCC0210", "2023.1", Decimal("8.00"), Decimal("7.50"), "approved"),
            GradeRecord("SCC0302", "2023.2", Decimal("7.00"), Decimal("7.50"), "approved"),
            GradeRecord("SCC0303", "2023.2", Decimal("8.50"), Decimal("9.00"), "approved"),
            GradeRecord("SCC0401", "2024.1", Decimal("7.50"), Decimal("7.00"), "approved"),
            GradeRecord("SCC0403", "2024.1", Decimal("8.00"), Decimal("8.50"), "approved"),
            GradeRecord("SCC0501", "2024.2", Decimal("9.00"), Decimal("8.50"), "approved"),
            GradeRecord("SCC0503", "2024.2", Decimal("7.50"), Decimal("8.00"), "approved"),
            GradeRecord("SCC0602", "2025.1", Decimal("8.00"), Decimal("7.50"), "approved"),
            GradeRecord("SCC0603", "2025.1", Decimal("7.00"), Decimal("7.50"), "approved"),
            GradeRecord("SCC0701", "2025.2", Decimal("8.50"), None, "in_progress"),
            GradeRecord("SCC0702", "2025.2", None, None, "in_progress"),
        ),
    ),
    StudentSeed(
        name="Eva Martins",
        email="eva.martins@usp.br",
        phone="5511987654325",
        registration_number="20250005",
        semester=2,
        enrollment_year=2025,
        status="inactive",
        history=(
            GradeRecord("SCC0101", "2025.1", Decimal("5.50"), Decimal("6.00"), "approved"),
            GradeRecord("SMA0300", "2025.1", Decimal("4.50"), Decimal("5.50"), "failed"),
        ),
    ),
)


def calculate_grade_final(grade_1: Decimal | None, grade_2: Decimal | None) -> Decimal | None:
    if grade_1 is not None and grade_2 is not None:
        return ((grade_1 + grade_2) / Decimal("2")).quantize(Decimal("0.01"))
    if grade_1 is not None:
        return grade_1
    return None


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


def period_dates(semester_year: str) -> tuple[date, date]:
    year_text, term_text = semester_year.split(".")
    year = int(year_text)
    term = int(term_text)
    if term == 1:
        return date(year, 1, 15), date(year, 3, 15)
    return date(year, 8, 1), date(year, 9, 15)


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


async def seed_periods(session: AsyncSession) -> dict[str, EnrollmentPeriod]:
    semester_years = sorted(
        {grade.semester_year for student in STUDENTS_DATA for grade in student.history}
    )
    periods: dict[str, EnrollmentPeriod] = {}
    for semester_year in semester_years:
        start_date, end_date = period_dates(semester_year)
        period = EnrollmentPeriod(
            name=f"{semester_year} - Histórico",
            type="enrollment",
            start_date=start_date,
            end_date=end_date,
            semester_year=semester_year,
            is_active=False,
        )
        session.add(period)
        await session.flush()
        periods[semester_year] = period

    today = date.today()
    active_period = EnrollmentPeriod(
        name="2026.1 - Matrícula",
        type="enrollment",
        start_date=today - timedelta(days=15),
        end_date=today + timedelta(days=15),
        semester_year="2026.1",
        is_active=True,
    )
    session.add(active_period)
    await session.commit()
    periods[active_period.semester_year] = active_period
    return periods


async def seed_users_and_history(
    session: AsyncSession,
    curriculum: Curriculum,
    courses_by_code: dict[str, Course],
    periods_by_semester: dict[str, EnrollmentPeriod],
) -> None:
    session.add_all(
        [
            Staff(name="Prof. Roberto Almeida", email="roberto@icmc.usp.br", role="coordinator"),
            Staff(name="Maria Secretária", email="maria@icmc.usp.br", role="secretary"),
        ]
    )
    await session.flush()

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

        enrollments_by_semester: dict[str, Enrollment] = {}
        for grade_record in student_seed.history:
            if grade_record.semester_year not in enrollments_by_semester:
                period = periods_by_semester[grade_record.semester_year]
                enrollment = Enrollment(
                    student_id=student.id,
                    enrollment_period_id=period.id,
                    status="confirmed",
                    confirmed_at=datetime.now(UTC),
                )
                session.add(enrollment)
                await session.flush()
                enrollments_by_semester[grade_record.semester_year] = enrollment

            course = courses_by_code[grade_record.code]
            enrollment_course = EnrollmentCourse(
                enrollment_id=enrollments_by_semester[grade_record.semester_year].id,
                course_id=course.id,
                status="enrolled",
            )
            session.add(enrollment_course)
            await session.flush()

            session.add(
                Grade(
                    student_id=student.id,
                    course_id=course.id,
                    enrollment_course_id=enrollment_course.id,
                    semester_year=grade_record.semester_year,
                    grade_1=grade_record.grade_1,
                    grade_2=grade_record.grade_2,
                    grade_final=calculate_grade_final(grade_record.grade_1, grade_record.grade_2),
                    status=grade_record.status,
                )
            )

    await session.commit()


async def seed_scheduling(session: AsyncSession) -> None:
    resources_data = [
        {
            "name": "Sala de Coordenação",
            "resource_type": "room",
            "description": "Sala para reuniões com a coordenação do curso",
            "capacity": 10,
            "location": "Bloco 3, Sala 301",
            "is_available": True,
            "requires_authorization": False,
        },
        {
            "name": "Laboratório de Redes",
            "resource_type": "lab",
            "description": "Laboratório equipado com switches, roteadores e ferramentas de análise de rede",
            "capacity": 30,
            "location": "Bloco 5, Sala 102",
            "is_available": True,
            "requires_authorization": False,
        },
        {
            "name": "Projetor Portátil Epson",
            "resource_type": "equipment",
            "description": "Projetor portátil para apresentações e aulas externas",
            "capacity": None,
            "location": "Almoxarifado, Bloco 1",
            "is_available": True,
            "requires_authorization": False,
        },
        {
            "name": "Auditório Principal",
            "resource_type": "auditorium",
            "description": "Auditório com capacidade para eventos e palestras. Requer autorização da direção.",
            "capacity": 200,
            "location": "Bloco Central, Térreo",
            "is_available": True,
            "requires_authorization": True,
        },
        {
            "name": "Sala de Estudos A",
            "resource_type": "study_room",
            "description": "Sala silenciosa para estudo individual ou em grupo",
            "capacity": 8,
            "location": "Biblioteca, 2° andar",
            "is_available": True,
            "requires_authorization": False,
        },
        {
            "name": "Sala de Estudos B",
            "resource_type": "study_room",
            "description": "Sala com quadro branco para trabalhos em grupo",
            "capacity": 12,
            "location": "Biblioteca, 2° andar",
            "is_available": True,
            "requires_authorization": False,
        },
        {
            "name": "Quadra Poliesportiva",
            "resource_type": "sports_court",
            "description": "Quadra coberta para futebol, basquete e vôlei. Requer autorização do setor esportivo.",
            "capacity": 30,
            "location": "Centro Esportivo",
            "is_available": True,
            "requires_authorization": True,
        },
        {
            "name": "Laboratório de IA",
            "resource_type": "lab",
            "description": "Laboratório com GPUs para treinamento de modelos. Requer autorização do professor responsável.",
            "capacity": 15,
            "location": "Bloco 5, Sala 201",
            "is_available": True,
            "requires_authorization": True,
        },
    ]

    created_resources = []
    for res_data in resources_data:
        resource = Resource(**res_data)
        session.add(resource)
        await session.flush()
        created_resources.append(resource)

    # Create scheduling slots only for the first resource (coordination room)
    base_day = date.today() + timedelta(days=1)
    slots = [
        (base_day, time(9, 0), time(10, 0)),
        (base_day, time(10, 0), time(11, 0)),
        (base_day + timedelta(days=1), time(14, 0), time(15, 0)),
        (base_day + timedelta(days=2), time(9, 0), time(10, 0)),
        (base_day + timedelta(days=2), time(10, 0), time(11, 0)),
    ]
    for slot_date, start_time, end_time in slots:
        session.add(
            SchedulingSlot(
                resource_id=created_resources[0].id,
                date=slot_date,
                start_time=start_time,
                end_time=end_time,
                is_available=True,
            )
        )

    await session.commit()


async def print_summary(session: AsyncSession) -> None:
    summary_queries = {
        "courses": "SELECT count(*) FROM courses",
        "students": "SELECT count(*) FROM students",
        "staff": "SELECT count(*) FROM staff",
        "prerequisites": "SELECT count(*) FROM prerequisites",
        "curriculum_courses": "SELECT count(*) FROM curriculum_courses",
        "grades": "SELECT count(*) FROM grades",
        "enrollment_periods": "SELECT count(*) FROM enrollment_periods",
        "resources": "SELECT count(*) FROM resources",
        "scheduling_slots": "SELECT count(*) FROM scheduling_slots",
    }
    for label, query in summary_queries.items():
        result = await session.execute(text(query))
        print(f"- {label}: {result.scalar_one()}")


async def check_data_exists(session: AsyncSession) -> bool:
    """Return True if students table already has data."""
    result = await session.execute(text("SELECT COUNT(*) FROM students"))
    count = result.scalar_one()
    return count > 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="FCG3 development database seeder")
    parser.add_argument(
        "--force",
        action="store_true",
        help="Force re-seed: truncate existing data and recreate from scratch",
    )
    return parser.parse_args()


async def main() -> None:
    args = parse_args()

    async with async_session() as session:
        if not args.force:
            if await check_data_exists(session):
                print("✅ Seed data already exists, skipping. Use --force to re-seed.")
                return

    print("⚠️  WARNING: This script TRUNCATES and recreates development seed data.")
    print("⚠️  Affected tables: " + ", ".join(WARNING_TABLES))
    print("🌱 Starting destructive seed...")
    validate_seed_shapes()

    async with async_session() as session:
        await truncate_seed_tables(session)
        print("🗑️  Existing development data cleared")

        curriculum, courses_by_code = await seed_curriculum(session)
        print(f"📚 Curriculum seeded: {curriculum.name} with {len(courses_by_code)} courses")

        periods_by_semester = await seed_periods(session)
        print(f"🗓️  Enrollment periods seeded: {len(periods_by_semester)}")

        await seed_users_and_history(session, curriculum, courses_by_code, periods_by_semester)
        print(f"👥 Students seeded: {len(STUDENTS_DATA)} | staff seeded: 2")

        await seed_scheduling(session)
        print("🏫 Scheduling resource and slots seeded")

        print("📊 Final counts:")
        await print_summary(session)

    print("✅ Seed complete")


if __name__ == "__main__":
    asyncio.run(main())
