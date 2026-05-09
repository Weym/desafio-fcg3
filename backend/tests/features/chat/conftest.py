"""Chat visibility test fixtures: staff JWT, seeded sessions."""

import uuid
from datetime import datetime, timezone

import pytest
import pytest_asyncio

from src.features.auth.models import Student, Staff
from src.features.chat.models import ChatSession, ChatMessage


@pytest_asyncio.fixture
async def chat_test_data(db_session):
    """Seed a student, a staff user, and chat data for visibility tests."""
    student = Student(
        id=uuid.uuid4(),
        name="Chat Student",
        email="chatstudent@test.edu",
        phone="5521888888888",
        registration_number="CHAT01",
        semester=2,
        status="active",
        enrollment_year=2024,
    )
    staff = Staff(
        id=uuid.uuid4(),
        name="Chat Staff",
        email="chatstaff@test.edu",
        phone="5511777777777",
        role="staff",
    )
    db_session.add(student)
    db_session.add(staff)
    await db_session.flush()

    # Create active and closed sessions
    active_session = ChatSession(
        id=uuid.uuid4(),
        student_id=student.id,
        whatsapp_phone="5521888888888",
        status="active",
        verification_state="verified",
    )
    closed_session = ChatSession(
        id=uuid.uuid4(),
        student_id=student.id,
        whatsapp_phone="5521888888888",
        status="closed",
        verification_state="verified",
        ended_at=datetime.now(timezone.utc),
    )
    db_session.add(active_session)
    db_session.add(closed_session)
    await db_session.flush()

    # Add messages to active session
    msg1 = ChatMessage(
        id=uuid.uuid4(),
        chat_session_id=active_session.id,
        role="user",
        content="Quais minhas notas?",
    )
    msg2 = ChatMessage(
        id=uuid.uuid4(),
        chat_session_id=active_session.id,
        role="assistant",
        content="Suas notas sao...",
    )
    db_session.add(msg1)
    db_session.add(msg2)
    await db_session.flush()

    return {
        "student": student,
        "staff": staff,
        "active_session": active_session,
        "closed_session": closed_session,
        "messages": [msg1, msg2],
    }
