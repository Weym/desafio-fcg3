"""Central model registry for Alembic discovery."""

try:
    from infrastructure.database import Base
    from features.auth.models import FcmToken, Session, Staff, Student, VerificationCode
    from features.chat.models import ChatMessage, ChatSession, McpActionLog
    from features.courses.models import Course, Curriculum, CurriculumCourse, Prerequisite
    from features.documents.models import Document
    from features.enrollment.models import Enrollment, EnrollmentCourse, EnrollmentPeriod
    from features.knowledge_base.models import KnowledgeBaseChunk
    from features.scheduling.models import Appointment, Resource, SchedulingSlot
    from features.students.models import Grade
except ModuleNotFoundError:  # pragma: no cover
    from src.features.auth.models import FcmToken, Session, Staff, Student, VerificationCode
    from src.features.chat.models import ChatMessage, ChatSession, McpActionLog
    from src.features.courses.models import Course, Curriculum, CurriculumCourse, Prerequisite
    from src.features.documents.models import Document
    from src.features.enrollment.models import Enrollment, EnrollmentCourse, EnrollmentPeriod
    from src.features.knowledge_base.models import KnowledgeBaseChunk
    from src.features.scheduling.models import Appointment, Resource, SchedulingSlot
    from src.features.students.models import Grade
    from src.infrastructure.database import Base


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
