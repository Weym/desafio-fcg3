from mcp_server.tools.curriculum_tools import register_curriculum_tools
from mcp_server.tools.document_tools import register_document_tools
from mcp_server.tools.enrollment_tools import register_enrollment_tools
from mcp_server.tools.grade_tools import register_grade_tools
from mcp_server.tools.scheduling_tools import register_scheduling_tools
from mcp_server.tools.student_tools import register_student_tools

__all__ = [
    "register_curriculum_tools",
    "register_document_tools",
    "register_enrollment_tools",
    "register_grade_tools",
    "register_scheduling_tools",
    "register_student_tools",
]
