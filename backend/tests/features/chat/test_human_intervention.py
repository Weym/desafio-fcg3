"""Human intervention endpoint tests (HI-04 through HI-09).

Tests staff assign, reply, resolve endpoints and their validation:
- POST /chat-sessions/{id}/assign (human_needed → human_active)
- POST /chat-sessions/{id}/reply (saves message + returns message_id)
- PUT /chat-sessions/{id}/resolve (human_active → closed)
- GET /chat-sessions/interventions (lists pending + staff's active)
- 409 on invalid state transitions
- 403 on ownership mismatch
"""

import uuid
from datetime import datetime, timezone
from unittest.mock import AsyncMock, patch

import pytest
import pytest_asyncio

from src.features.auth.models import Student, Staff, Session as SessionModel
from src.features.auth.services import jwt_service
from src.features.chat.models import ChatSession, ChatMessage


async def _make_jwt(db_session, user_id, role, email, name="Test"):
    """Helper: create a JWT token with a valid session in DB."""
    issued = jwt_service.issue_access(
        user_id=user_id, role=role, email=email, name=name,
    )
    sess = SessionModel(
        user_id=user_id,
        user_type=role,
        jti=issued.jti,
        platform="app",
        token_type="access",
        used=False,
        expires_at=issued.expires_at,
    )
    db_session.add(sess)
    await db_session.flush()
    return issued.token


@pytest_asyncio.fixture
async def intervention_data(db_session):
    """Seed student, two staff members, and sessions for intervention tests."""
    student = Student(
        id=uuid.uuid4(),
        name="Escalated Student",
        email="escalated@test.edu",
        phone="5521777777777",
        registration_number="ESC01",
        semester=2,
        status="active",
        enrollment_year=2024,
    )
    staff_a = Staff(
        id=uuid.uuid4(),
        name="Staff A",
        email="staffa@test.edu",
        phone="5511666666666",
        role="staff",
    )
    staff_b = Staff(
        id=uuid.uuid4(),
        name="Staff B",
        email="staffb@test.edu",
        phone="5511555555555",
        role="staff",
    )
    db_session.add(student)
    db_session.add(staff_a)
    db_session.add(staff_b)
    await db_session.flush()

    # Session pending human intervention
    pending_session = ChatSession(
        id=uuid.uuid4(),
        student_id=student.id,
        whatsapp_phone="5521777777777",
        status="human_needed",
        verification_state="verified",
        escalated_at=datetime.now(timezone.utc),
    )
    # Session already assigned to staff_a
    active_session = ChatSession(
        id=uuid.uuid4(),
        student_id=student.id,
        whatsapp_phone="5521777777777",
        status="human_active",
        verification_state="verified",
        assigned_staff_id=staff_a.id,
        escalated_at=datetime.now(timezone.utc),
    )
    # Normal active session (not escalated)
    normal_session = ChatSession(
        id=uuid.uuid4(),
        student_id=student.id,
        whatsapp_phone="5521777777777",
        status="active",
        verification_state="verified",
    )
    db_session.add(pending_session)
    db_session.add(active_session)
    db_session.add(normal_session)
    await db_session.flush()

    return {
        "student": student,
        "staff_a": staff_a,
        "staff_b": staff_b,
        "pending_session": pending_session,
        "active_session": active_session,
        "normal_session": normal_session,
    }


class TestAssignSession:
    """HI-04: POST /chat-sessions/{id}/assign transitions human_needed → human_active."""

    async def test_assign_session_success(self, client, db_session, intervention_data):
        """Staff assigns pending session → status becomes human_active."""
        staff = intervention_data["staff_a"]
        session = intervention_data["pending_session"]
        token = await _make_jwt(db_session, staff.id, "staff", staff.email, staff.name)

        response = await client.post(
            f"/api/v1/chat-sessions/{session.id}/assign",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "human_active"
        assert data["assigned_staff_id"] == str(staff.id)

    async def test_assign_nonexistent_session_returns_404(self, client, db_session, intervention_data):
        """Assign to nonexistent session → 404."""
        staff = intervention_data["staff_a"]
        token = await _make_jwt(db_session, staff.id, "staff", staff.email)

        fake_id = str(uuid.uuid4())
        response = await client.post(
            f"/api/v1/chat-sessions/{fake_id}/assign",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 404


class TestStaffReply:
    """HI-05: POST /chat-sessions/{id}/reply saves message + returns message_id."""

    async def test_reply_saves_message_and_returns_id(self, client, db_session, intervention_data):
        """Staff replies to human_active session → message saved, message_id returned."""
        staff = intervention_data["staff_a"]
        session = intervention_data["active_session"]
        token = await _make_jwt(db_session, staff.id, "staff", staff.email, staff.name)

        with patch(
            "src.features.chat.router.get_whatsapp_client",
        ) as mock_wa:
            mock_client = AsyncMock()
            mock_client.send_text_message = AsyncMock(return_value=True)
            mock_wa.return_value = mock_client

            response = await client.post(
                f"/api/v1/chat-sessions/{session.id}/reply",
                headers={"Authorization": f"Bearer {token}"},
                json={"content": "Ola aluno, vou verificar sua situacao."},
            )
        assert response.status_code == 200
        data = response.json()
        assert "message_id" in data
        assert "sent_at" in data
        # Validate it's a valid UUID
        uuid.UUID(data["message_id"])


class TestResolveSession:
    """HI-06: PUT /chat-sessions/{id}/resolve closes session (human_active → closed)."""

    async def test_resolve_session_closes_it(self, client, db_session, intervention_data):
        """Resolve human_active session → status becomes closed."""
        staff = intervention_data["staff_a"]
        session = intervention_data["active_session"]
        token = await _make_jwt(db_session, staff.id, "staff", staff.email, staff.name)

        response = await client.put(
            f"/api/v1/chat-sessions/{session.id}/resolve",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "closed"
        assert data["id"] == str(session.id)


class TestListInterventionSessions:
    """HI-07: GET /chat-sessions/interventions lists pending + staff's active sessions only."""

    async def test_list_shows_pending_and_own_active(self, client, db_session, intervention_data):
        """Staff A sees pending sessions + own active session."""
        staff = intervention_data["staff_a"]
        token = await _make_jwt(db_session, staff.id, "staff", staff.email, staff.name)

        response = await client.get(
            "/api/v1/chat-sessions/interventions",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 200
        data = response.json()
        # Should see the pending session + staff_a's active session
        assert len(data) >= 2
        statuses = {s["status"] for s in data}
        assert "human_needed" in statuses
        assert "human_active" in statuses

    async def test_list_excludes_other_staffs_active(self, client, db_session, intervention_data):
        """Staff B sees pending sessions but NOT staff A's active session."""
        staff_b = intervention_data["staff_b"]
        token = await _make_jwt(db_session, staff_b.id, "staff", staff_b.email, staff_b.name)

        response = await client.get(
            "/api/v1/chat-sessions/interventions",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 200
        data = response.json()
        # Staff B should see pending but not Staff A's active session
        for s in data:
            if s["status"] == "human_active":
                assert s["assigned_staff_id"] == str(staff_b.id)

    async def test_student_cannot_access_interventions(self, client, db_session, intervention_data):
        """Student trying to access interventions → 403."""
        student = intervention_data["student"]
        token = await _make_jwt(db_session, student.id, "student", student.email)

        response = await client.get(
            "/api/v1/chat-sessions/interventions",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 403


class TestInvalidStateTransitions:
    """HI-08: 409 on invalid state transition (e.g. assign when not human_needed)."""

    async def test_assign_already_active_returns_409(self, client, db_session, intervention_data):
        """Trying to assign a session already in human_active → 409."""
        staff = intervention_data["staff_a"]
        session = intervention_data["active_session"]
        token = await _make_jwt(db_session, staff.id, "staff", staff.email, staff.name)

        response = await client.post(
            f"/api/v1/chat-sessions/{session.id}/assign",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 409

    async def test_assign_normal_active_returns_409(self, client, db_session, intervention_data):
        """Trying to assign a normal active session (not escalated) → 409."""
        staff = intervention_data["staff_a"]
        session = intervention_data["normal_session"]
        token = await _make_jwt(db_session, staff.id, "staff", staff.email, staff.name)

        response = await client.post(
            f"/api/v1/chat-sessions/{session.id}/assign",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 409

    async def test_resolve_pending_session_returns_409(self, client, db_session, intervention_data):
        """Trying to resolve a pending session (not yet human_active) → 409."""
        staff = intervention_data["staff_a"]
        session = intervention_data["pending_session"]
        token = await _make_jwt(db_session, staff.id, "staff", staff.email, staff.name)

        response = await client.put(
            f"/api/v1/chat-sessions/{session.id}/resolve",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 409

    async def test_reply_to_pending_session_returns_409(self, client, db_session, intervention_data):
        """Trying to reply to a pending session (not yet human_active) → 409."""
        staff = intervention_data["staff_a"]
        session = intervention_data["pending_session"]
        token = await _make_jwt(db_session, staff.id, "staff", staff.email, staff.name)

        response = await client.post(
            f"/api/v1/chat-sessions/{session.id}/reply",
            headers={"Authorization": f"Bearer {token}"},
            json={"content": "Test reply"},
        )
        assert response.status_code == 409


class TestOwnershipMismatch:
    """HI-09: 403 on ownership mismatch (reply/resolve by non-assigned staff)."""

    async def test_reply_by_non_assigned_staff_returns_403(self, client, db_session, intervention_data):
        """Staff B trying to reply to Staff A's session → 403."""
        staff_b = intervention_data["staff_b"]
        session = intervention_data["active_session"]  # assigned to staff_a
        token = await _make_jwt(db_session, staff_b.id, "staff", staff_b.email, staff_b.name)

        response = await client.post(
            f"/api/v1/chat-sessions/{session.id}/reply",
            headers={"Authorization": f"Bearer {token}"},
            json={"content": "I should not be able to reply here."},
        )
        assert response.status_code == 403

    async def test_resolve_by_non_assigned_staff_returns_403(self, client, db_session, intervention_data):
        """Staff B trying to resolve Staff A's session → 403."""
        staff_b = intervention_data["staff_b"]
        session = intervention_data["active_session"]  # assigned to staff_a
        token = await _make_jwt(db_session, staff_b.id, "staff", staff_b.email, staff_b.name)

        response = await client.put(
            f"/api/v1/chat-sessions/{session.id}/resolve",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 403
