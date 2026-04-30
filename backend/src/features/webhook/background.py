"""Background task for AI service integration with retry, fallback, and per-session locking.

CRITICAL-3: _handle_task_result logs exceptions from background tasks.
CRITICAL-4: Opens its OWN DB session via async_session_maker — never request-scoped.
D-06: Retry once on AI service failure, then send fallback message.
D-09: Per-session asyncio.Lock prevents concurrent processing for same student.
"""

from __future__ import annotations

import asyncio
import logging
from uuid import UUID

import httpx

from src.infrastructure.config import get_settings
from src.infrastructure.database import async_session
from src.infrastructure.whatsapp_client import WhatsAppClient

logger = logging.getLogger(__name__)

# Per-session locks to prevent concurrent processing (D-09, MINOR-3)
_session_locks: dict[str, asyncio.Lock] = {}

FALLBACK_MESSAGE = (
    "Desculpe, estou com dificuldades tecnicas. "
    "Tente novamente em alguns minutos."
)


def _handle_task_result(task: asyncio.Task) -> None:
    """Done callback for background tasks.

    Logs exceptions that would be silently swallowed (CRITICAL-3).
    """
    try:
        exc = task.exception()
        if exc is not None:
            logger.error(
                "Background task failed with unhandled exception: %s: %s",
                type(exc).__name__,
                exc,
                exc_info=exc,
            )
    except asyncio.CancelledError:
        logger.warning("Background message processing task was cancelled")


async def process_verified_message(
    session_id: UUID,
    message_text: str,
    phone: str,
    wa_client: WhatsAppClient,
) -> None:
    """Process a verified student's text message.

    1. Acquire per-session lock (D-09)
    2. Call AI service with message + session_id
    3. On failure: retry once, then send fallback (D-06)
    4. Save assistant response to chat_messages
    5. Send response via WhatsApp

    CRITICAL-4: Opens its OWN DB session — never uses the request-scoped one.
    """
    settings = get_settings()
    lock_key = str(session_id)
    lock = _session_locks.setdefault(lock_key, asyncio.Lock())

    async with lock:
        agent_response: str | None = None

        # Call AI service with one retry on failure (D-06)
        for attempt in range(2):
            try:
                async with httpx.AsyncClient(
                    timeout=httpx.Timeout(50.0, connect=5.0)
                ) as http:
                    response = await http.post(
                        f"{settings.ai_service_url}/chat",
                        json={
                            "session_id": str(session_id),
                            "message": message_text,
                        },
                    )
                    if response.status_code == 200:
                        data = response.json()
                        agent_response = data.get("response", FALLBACK_MESSAGE)
                        break
                    else:
                        logger.warning(
                            "AI service returned %d on attempt %d",
                            response.status_code,
                            attempt + 1,
                        )
            except (httpx.HTTPError, Exception) as e:
                logger.warning(
                    "AI service call attempt %d failed: %s", attempt + 1, e
                )

        # If both attempts failed, use fallback (D-06)
        if agent_response is None:
            agent_response = FALLBACK_MESSAGE
            logger.error(
                "AI service unavailable for session %s, sending fallback",
                session_id,
            )

        # Save assistant response to chat_messages (CRITICAL-4: own session)
        async with async_session() as db:
            from src.features.webhook.service import WebhookService

            webhook_service = WebhookService()
            await webhook_service.save_message(
                session_id=session_id,
                role="assistant",
                content=agent_response,
                media_type=None,
                wamid=None,
                db=db,
            )
            await db.commit()

        # Send response via WhatsApp (D-07: WhatsApp client already handles retry)
        await wa_client.send_text_message(phone, agent_response)

    # Clean up lock if no other coroutine is waiting on it (prevent memory leak)
    if not lock.locked():
        _session_locks.pop(lock_key, None)
