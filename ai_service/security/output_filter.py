"""Output filtering layer — blocks responses that leak system info before sending to WhatsApp.

Layer 4 of defense-in-depth (D-05). Blocks:
- System prompt verbatim text (D-07)
- Mentions of "system prompt"/"minhas instrucoes" (D-07)
- Internal details: tool names as code identifiers, API URLs, service architecture, DB table names (D-07)
"""

from __future__ import annotations

import logging
import re

logger = logging.getLogger(__name__)

# Canary token from system prompt — if this appears in output, prompt was leaked
CANARY_TOKEN = "CANARY_TOKEN_ALPHA_INTEGRITY_CHECK_DO_NOT_ECHO"

# Patterns that should NEVER appear in output to students
BLOCKED_OUTPUT_PATTERNS: list[re.Pattern] = [
    # System prompt references
    re.compile(r"(?i)(system\s*prompt|meu\s+prompt|minhas\s+instruc[oõ]es|instruc[oõ]es\s+do\s+sistema)"),
    # Internal tool identifiers (code-style, not natural language references)
    re.compile(
        r"\b(search_knowledge_base|get_student_info|get_grades|get_transcript|"
        r"get_available_courses|create_enrollment|confirm_enrollment|drop_course|"
        r"cancel_enrollment|request_document|get_document_status|book_appointment|"
        r"get_appointments|cancel_appointment|get_enrollment_periods|get_enrollment_status)\b"
    ),
    # API URLs
    re.compile(r"(https?://)?(\w+\.)?(localhost|mcp-server|fastapi-app|langchain-service):\d+"),
    re.compile(r"/api/v1/\w+"),
    # Database table names
    re.compile(
        r"\b(chat_sessions|chat_messages|knowledge_base_chunks|mcp_action_logs|"
        r"rag_logs|verification_codes|students|enrollments|enrollment_items|"
        r"enrollment_periods|courses|grades|documents|appointments|fcm_tokens|sessions)\b"
    ),
    # Docker/architecture references
    re.compile(r"\b(docker-compose|container|microservice|fastapi|langchain|mcp.server)\b", re.IGNORECASE),
]

REPLACEMENT_MESSAGE = (
    "Desculpe, tive um problema ao formular a resposta. "
    "Poderia reformular sua pergunta?"
)


def detect_canary_leak(response: str) -> bool:
    """Check if the canary token appears in the agent's response."""
    return CANARY_TOKEN in response


def filter_output(response: str) -> tuple[str, bool]:
    """Filter agent output to block system info leakage.

    Returns:
        Tuple of (filtered_response, was_filtered).
        If canary token is detected, the entire response is replaced.
        If blocked patterns are found, the response is replaced with a safe message.
    """
    # Layer 3 check: canary token leaked = full prompt compromise
    if detect_canary_leak(response):
        logger.critical("CANARY TOKEN LEAKED in agent response — possible prompt extraction!")
        return REPLACEMENT_MESSAGE, True

    # Layer 4 check: blocked patterns
    for pattern in BLOCKED_OUTPUT_PATTERNS:
        if pattern.search(response):
            logger.warning(
                "Output filter triggered by pattern: %s",
                pattern.pattern[:50],
            )
            return REPLACEMENT_MESSAGE, True

    return response, False
