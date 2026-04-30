"""Chat visibility endpoint tests (CHAT-03).

Tests staff-only access, student rejection, session listing, message retrieval,
and action log retrieval for staff monitoring.
"""

import uuid
from unittest.mock import patch

import pytest

from src.features.auth.services import jwt_service
from src.features.auth.models import Session as SessionModel


async def _make_jwt(db_session, user_id, role, email, name="Test"):
    """Helper: create a JWT token with a valid session in DB."""
    issued = jwt_service.issue_access(
        user_id=user_id, role=role, email=email, name=name,
    )
    # Create session in DB for jti check
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


class TestChatVisibilityStaffAccess:
    """Staff-only endpoint access control."""

    async def test_list_sessions_with_staff_jwt_returns_200(
        self, client, db_session, chat_test_data
    ):
        """GET /chat-sessions with staff JWT → 200."""
        token = await _make_jwt(
            db_session, chat_test_data["staff"].id, "staff", "chatstaff@test.edu"
        )
        response = await client.get(
            "/api/v1/chat-sessions",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 200
        data = response.json()
        assert "data" in data
        assert "pagination" in data

    async def test_list_sessions_with_student_jwt_returns_403(
        self, client, db_session, chat_test_data
    ):
        """GET /chat-sessions with student JWT → 403."""
        token = await _make_jwt(
            db_session, chat_test_data["student"].id, "student", "chatstudent@test.edu"
        )
        response = await client.get(
            "/api/v1/chat-sessions",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 403

    async def test_filter_by_status_active(
        self, client, db_session, chat_test_data
    ):
        """GET /chat-sessions?status=active → only active sessions."""
        token = await _make_jwt(
            db_session, chat_test_data["staff"].id, "staff", "chatstaff@test.edu"
        )
        response = await client.get(
            "/api/v1/chat-sessions?status=active",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 200
        data = response.json()
        for session in data["data"]:
            assert session["status"] == "active"

    async def test_messages_endpoint_returns_ordered(
        self, client, db_session, chat_test_data
    ):
        """GET /chat-sessions/{id}/messages → ordered messages."""
        token = await _make_jwt(
            db_session, chat_test_data["staff"].id, "staff", "chatstaff@test.edu"
        )
        session_id = str(chat_test_data["active_session"].id)
        response = await client.get(
            f"/api/v1/chat-sessions/{session_id}/messages",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 200
        data = response.json()
        assert len(data["data"]) == 2
        # Verify ordering
        assert data["data"][0]["role"] == "user"
        assert data["data"][1]["role"] == "assistant"

    async def test_nonexistent_session_messages_returns_404(
        self, client, db_session, chat_test_data
    ):
        """GET /chat-sessions/{nonexistent}/messages → 404."""
        token = await _make_jwt(
            db_session, chat_test_data["staff"].id, "staff", "chatstaff@test.edu"
        )
        fake_id = str(uuid.uuid4())
        response = await client.get(
            f"/api/v1/chat-sessions/{fake_id}/messages",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 404

    async def test_action_logs_endpoint(
        self, client, db_session, chat_test_data
    ):
        """GET /chat-sessions/{id}/action-logs → MCP logs (empty if no logs)."""
        token = await _make_jwt(
            db_session, chat_test_data["staff"].id, "staff", "chatstaff@test.edu"
        )
        session_id = str(chat_test_data["active_session"].id)

        # mcp_action_logs table is not in SQLite, so we mock the service method
        with patch(
            "src.features.chat.router.chat_service.session_exists",
            return_value=True,
        ), patch(
            "src.features.chat.router.chat_service.get_session_action_logs",
            return_value=[],
        ):
            response = await client.get(
                f"/api/v1/chat-sessions/{session_id}/action-logs",
                headers={"Authorization": f"Bearer {token}"},
            )
        assert response.status_code == 200
        assert response.json()["data"] == []

    async def test_student_cannot_access_messages(
        self, client, db_session, chat_test_data
    ):
        """GET /chat-sessions/{id}/messages with student JWT → 403."""
        token = await _make_jwt(
            db_session, chat_test_data["student"].id, "student", "chatstudent@test.edu"
        )
        session_id = str(chat_test_data["active_session"].id)
        response = await client.get(
            f"/api/v1/chat-sessions/{session_id}/messages",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 403

    async def test_student_cannot_access_action_logs(
        self, client, db_session, chat_test_data
    ):
        """GET /chat-sessions/{id}/action-logs with student JWT → 403."""
        token = await _make_jwt(
            db_session, chat_test_data["student"].id, "student", "chatstudent@test.edu"
        )
        session_id = str(chat_test_data["active_session"].id)
        response = await client.get(
            f"/api/v1/chat-sessions/{session_id}/action-logs",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 403
