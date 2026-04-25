"""Regression test for GET /students/{id}/available-courses response contract."""

from unittest.mock import AsyncMock

import pytest

from src.features.auth.models import Session as SessionModel
from src.features.auth.services import jwt_service
from src.features.students.schemas import AvailableCourseItem
from src.features.students.services import student_service


@pytest.mark.asyncio
async def test_available_courses_returns_raw_list_for_authenticated_student(
    client,
    seed_users,
    db_session,
    monkeypatch,
):
    """STU-07 regression: route must return HTTP 200 with a raw JSON list."""
    student = seed_users["student"]
    token = jwt_service.issue_access(
        student.id,
        "student",
        student.name,
        student.email,
    )
    db_session.add(
        SessionModel(
            jti=token.jti,
            user_id=student.id,
            token_type="access",
            user_type="student",
            platform="app",
            parent_jti=None,
            used=False,
            expires_at=token.expires_at,
        )
    )
    await db_session.commit()

    expected_courses = [
        AvailableCourseItem(
            id=student.id,
            code="CC201",
            name="Estrutura de Dados",
            credits=4,
            prerequisites_met=True,
            semester=2,
        )
    ]
    get_available_courses_mock = AsyncMock(return_value=expected_courses)
    monkeypatch.setattr(
        student_service,
        "get_available_courses",
        get_available_courses_mock,
    )

    response = await client.get(
        f"/api/v1/students/{student.id}/available-courses",
        headers={"Authorization": f"Bearer {token.token}"},
    )

    assert response.status_code == 200
    body = response.json()
    assert isinstance(body, list)
    assert "data" not in body
    assert body == [
        {
            "id": str(student.id),
            "code": "CC201",
            "name": "Estrutura de Dados",
            "credits": 4,
            "prerequisites_met": True,
            "semester": 2,
        }
    ]
    get_available_courses_mock.assert_awaited_once_with(db_session, student.id)
