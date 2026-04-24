"""Central model registry for Alembic discovery."""

from infrastructure.database import Base
from features.auth.models import FcmToken, Session, Staff, Student, VerificationCode
from features.chat.models import ChatMessage, ChatSession, McpActionLog
from features.courses.models import Course, Curriculum, CurriculumCourse, Prerequisite
from features.documents.models import Document
from features.enrollment.models import Enrollment, EnrollmentCourse, EnrollmentPeriod
from features.knowledge_base.models import KnowledgeBaseChunk
from features.scheduling.models import Appointment, Resource, SchedulingSlot
from features.students.models import Grade


__all__ = [
    "Appointment",
    "Base",
    "ChatMessage",
    "ChatSession",
    "Course",
    "Curriculum",
    "CurriculumCourse",
    "Document",
    "Enrollment",
    "EnrollmentCourse",
    "EnrollmentPeriod",
    "FcmToken",
    "Grade",
    "KnowledgeBaseChunk",
    "McpActionLog",
    "Prerequisite",
    "Resource",
    "SchedulingSlot",
    "Session",
    "Staff",
    "Student",
    "VerificationCode",
]
