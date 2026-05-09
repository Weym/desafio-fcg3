"""Input sanitization layer — strips known injection patterns before reaching the agent.

Layer 2 of defense-in-depth (D-05). Regex-based pattern matching.
"""

from __future__ import annotations

import logging
import re

logger = logging.getLogger(__name__)

# Patterns that indicate prompt injection attempts
INJECTION_PATTERNS: list[re.Pattern] = [
    # Role change attempts
    re.compile(r"(?i)(ignore|forget|disregard)\s+(all\s+)?(previous|prior|above)\s+(instructions?|rules?|prompts?)"),
    re.compile(r"(?i)(you\s+are\s+now|act\s+as|pretend\s+(to\s+be|you\s+are)|your\s+new\s+role)"),
    re.compile(r"(?i)(system\s*prompt|instruc[oõ]es?\s+do\s+sistema|suas?\s+instruc[oõ]es)"),
    # Prompt extraction attempts
    re.compile(r"(?i)(repeat|show|display|print|reveal|tell\s+me)\s+(your\s+)?(system\s*prompt|instructions?|rules?|initial\s+prompt)"),
    re.compile(r"(?i)(what\s+are\s+your|show\s+me\s+your|reveal\s+your)\s+(instructions?|rules?|prompt|guidelines)"),
    # Portuguese variants
    re.compile(r"(?i)(mostre|revele|exiba|repita|diga)\s+(seu\s+)?(prompt|instruc[oõ]es|regras|diretrizes)"),
    re.compile(r"(?i)(voce\s+agora\s+e|finja\s+ser|aja\s+como|seu\s+novo\s+papel)"),
    re.compile(r"(?i)(ignore|esqueca|desconsidere)\s+(todas?\s+)?(instruc[oõ]es|regras|restricoes)"),
    # DAN/jailbreak patterns
    re.compile(r"(?i)\bDAN\b.*mode"),
    re.compile(r"(?i)jailbreak"),
    # Delimiter injection (trying to close system prompt context)
    re.compile(r"```\s*(system|assistant|user)\s*```"),
    re.compile(r"<\|?(system|im_start|im_end)\|?>"),
]


def detect_injection(message: str) -> bool:
    """Return True if the message matches known injection patterns."""
    return any(pattern.search(message) for pattern in INJECTION_PATTERNS)


def sanitize_input(message: str) -> tuple[str, bool]:
    """Sanitize user input, stripping injection patterns.

    Returns:
        Tuple of (sanitized_message, was_injection_detected).
        If injection is detected, the sanitized message has dangerous patterns
        stripped but the remaining content is preserved for the agent to respond
        with the warning per D-06.
    """
    injection_detected = detect_injection(message)

    if not injection_detected:
        return message, False

    logger.warning("Injection pattern detected in message: %s", message[:100])

    # Strip the injection patterns but keep the rest (student may have mixed intent)
    sanitized = message
    for pattern in INJECTION_PATTERNS:
        sanitized = pattern.sub("", sanitized)

    sanitized = sanitized.strip()

    # If nothing meaningful remains after stripping, return a marker
    if not sanitized or len(sanitized) < 3:
        sanitized = "[mensagem com conteudo fora do padrao detectado]"

    return sanitized, True
