from __future__ import annotations

import asyncio
import inspect

import pytest

from mcp_server.main import mcp
from mcp_server.tools import (
    curriculum_tools,
    document_tools,
    enrollment_tools,
    grade_tools,
    scheduling_tools,
    student_tools,
)


pytestmark = pytest.mark.asyncio


TOOL_SPECS = [
    {
        "name": "get_student_info",
        "module": student_tools,
        "kwargs": {"student_id": "student-123"},
        "expected": ("GET", "/students/student-123/academic-summary", {"student_id": "student-123"}),
    },
    {
        "name": "get_available_courses",
        "module": student_tools,
        "kwargs": {"student_id": "student-123"},
        "expected": ("GET", "/students/student-123/available-courses", {"student_id": "student-123"}),
    },
    {
        "name": "get_grades",
        "module": grade_tools,
        "kwargs": {"semester_year": "2025.1", "student_id": "student-123"},
        "expected": (
            "GET",
            "/students/student-123/grades",
            {"params": {"semester_year": "2025.1"}, "student_id": "student-123"},
        ),
    },
    {
        "name": "get_transcript",
        "module": grade_tools,
        "kwargs": {"student_id": "student-123"},
        "expected": ("GET", "/students/student-123/transcript", {"student_id": "student-123"}),
    },
    {
        "name": "get_curriculum",
        "module": curriculum_tools,
        "kwargs": {"student_id": "student-123"},
        "expected": ("GET", "/curriculum/active", {"student_id": "student-123"}),
    },
    {
        "name": "get_course_prerequisites",
        "module": curriculum_tools,
        "kwargs": {"course_id": "course-456", "student_id": "student-123"},
        "expected": ("GET", "/courses/course-456/prerequisites", {"student_id": "student-123"}),
    },
    {
        "name": "get_enrollment_period",
        "module": curriculum_tools,
        "kwargs": {"student_id": "student-123"},
        "expected": ("GET", "/enrollment-periods/current", {"student_id": "student-123"}),
    },
    {
        "name": "create_enrollment",
        "module": enrollment_tools,
        "kwargs": {
            "enrollment_period_id": "period-789",
            "course_ids": ["course-a", "course-b"],
            "student_id": "student-123",
        },
        "expected": (
            "POST",
            "/enrollments",
            {
                "json": {
                    "student_id": "student-123",
                    "enrollment_period_id": "period-789",
                    "course_ids": ["course-a", "course-b"],
                },
                "student_id": "student-123",
            },
        ),
    },
    {
        "name": "confirm_enrollment",
        "module": enrollment_tools,
        "kwargs": {"enrollment_id": "enrollment-111", "student_id": "student-123"},
        "expected": ("POST", "/enrollments/enrollment-111/confirm", {"student_id": "student-123"}),
    },
    {
        "name": "drop_course",
        "module": enrollment_tools,
        "kwargs": {"enrollment_id": "enrollment-111", "course_id": "course-456", "student_id": "student-123"},
        "expected": (
            "DELETE",
            "/enrollments/enrollment-111/courses/course-456",
            {"student_id": "student-123"},
        ),
    },
    {
        "name": "lock_enrollment",
        "module": enrollment_tools,
        "kwargs": {"enrollment_id": "enrollment-111", "student_id": "student-123"},
        "expected": ("POST", "/enrollments/enrollment-111/lock", {"student_id": "student-123"}),
    },
    {
        "name": "request_document",
        "module": document_tools,
        "kwargs": {"type": "transcript", "student_id": "student-123"},
        "expected": (
            "POST",
            "/documents",
            {
                "json": {"student_id": "student-123", "type": "transcript"},
                "student_id": "student-123",
            },
        ),
    },
    {
        "name": "get_document_status",
        "module": document_tools,
        "kwargs": {"document_id": "document-222", "student_id": "student-123"},
        "expected": ("GET", "/documents/document-222", {"student_id": "student-123"}),
    },
    {
        "name": "get_available_slots",
        "module": scheduling_tools,
        "kwargs": {"date_from": "2026-04-25", "date_to": "2026-04-30", "student_id": "student-123"},
        "expected": (
            "GET",
            "/scheduling/slots",
            {"params": {"date_from": "2026-04-25", "date_to": "2026-04-30"}, "student_id": "student-123"},
        ),
    },
    {
        "name": "book_appointment",
        "module": scheduling_tools,
        "kwargs": {
            "slot_id": "slot-333",
            "reason": "Emitir documento",
            "student_id": "student-123",
        },
        "expected": (
            "POST",
            "/appointments",
            {
                "json": {
                    "student_id": "student-123",
                    "slot_id": "slot-333",
                    "reason": "Emitir documento",
                },
                "student_id": "student-123",
            },
        ),
    },
    {
        "name": "cancel_appointment",
        "module": scheduling_tools,
        "kwargs": {"appointment_id": "appointment-444", "student_id": "student-123"},
        "expected": ("PUT", "/appointments/appointment-444/cancel", {"student_id": "student-123"}),
    },
]


async def _tool_map():
    return {tool.name: tool for tool in await mcp.list_tools()}


@pytest.mark.parametrize("spec", TOOL_SPECS, ids=[spec["name"] for spec in TOOL_SPECS])
async def test_tools_call_expected_backend_http_contract(
    spec: dict[str, object],
    mock_context,
    monkeypatch: pytest.MonkeyPatch,
):
    tool = (await _tool_map())[spec["name"]]
    recorded: list[tuple[object, str, str, dict]] = []

    async def fake_call_api(client, method, path, **kwargs):
        recorded.append((client, method, path, kwargs))
        return {"tool": spec["name"]}, False

    monkeypatch.setattr(spec["module"], "call_api", fake_call_api)

    result = await tool.fn(ctx=mock_context, **spec["kwargs"])

    assert result == {"tool": spec["name"]}
    assert len(recorded) == 1

    client, method, path, kwargs = recorded[0]
    expected_method, expected_path, expected_kwargs = spec["expected"]
    assert client is mock_context.lifespan_context["http_client"]
    assert method == expected_method
    assert path == expected_path
    assert kwargs == expected_kwargs

    signature = inspect.signature(tool.fn)
    # After gap fix 05-11: every tool passes student_id to call_api for X-Student-Id injection
    if "student_id" in spec["kwargs"]:
        assert "student_id" in signature.parameters
        assert kwargs.get("student_id") == spec["kwargs"]["student_id"]
        if "json" in kwargs:
            if "student_id" in kwargs["json"]:
                assert kwargs["json"]["student_id"] == spec["kwargs"]["student_id"]
        elif spec["kwargs"]["student_id"] in path:
            pass  # student_id used in URL path — also valid
    else:
        assert "student_id" not in signature.parameters
