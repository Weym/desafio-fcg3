from __future__ import annotations

import asyncio
import inspect

from mcp_server.main import mcp


EXPECTED_TOOL_NAMES = {
    "get_student_info",
    "get_grades",
    "get_transcript",
    "get_available_courses",
    "create_enrollment",
    "confirm_enrollment",
    "drop_course",
    "lock_enrollment",
    "request_document",
    "get_document_status",
    "get_available_slots",
    "book_appointment",
    "cancel_appointment",
    "get_curriculum",
    "get_course_prerequisites",
    "get_enrollment_period",
}

STUDENT_SCOPED_TOOLS = {
    "get_student_info",
    "get_grades",
    "get_transcript",
    "get_available_courses",
    "create_enrollment",
    "request_document",
    "book_appointment",
}


def test_registered_tool_names_match_docs_table():
    tools = asyncio.run(mcp.list_tools())

    assert {tool.name for tool in tools} == EXPECTED_TOOL_NAMES


def test_student_id_is_hidden_from_all_tool_input_schemas():
    tools = asyncio.run(mcp.list_tools())

    for tool in tools:
        schema = tool.model_dump()["parameters"]
        assert "student_id" not in schema.get("properties", {})


def test_student_scoped_tools_keep_student_id_as_hidden_dependency():
    tools = asyncio.run(mcp.list_tools())

    for tool in tools:
        signature = inspect.signature(tool.fn)
        if tool.name in STUDENT_SCOPED_TOOLS:
            dependency = signature.parameters["student_id"].default
            assert dependency.__class__.__name__ == "_Depends"
        else:
            assert "student_id" not in signature.parameters
