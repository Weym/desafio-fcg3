"""Idle timeout monitor for WhatsApp chat sessions.

D-02 Layer 3: Short-term idle detection.
- 5 min idle after agent response (that didn't ask a question) -> send follow-up
- 5 min more silence -> send goodbye + close session

D-03: Follow-up only after 2+ turns of idle silence, NOT after every action.

Implementation: asyncio background task that checks session activity.
Runs as a periodic checker triggered after each message processing.
Timer resets on each new student message (schedule_idle_check called again).
"""

from __future__ import annotations

import asyncio
import logging
from datetime import datetime, timezone, timedelta
from uuid import UUID

from sqlalchemy import select

from src.infrastructure.database import async_session
from src.infrastructure.whatsapp_client import WhatsAppClient

logger = logging.getLogger(__name__)

# Configurable timeouts (within D-02's 5-10 min range)
IDLE_FOLLOWUP_SECONDS = 300  # 5 minutes
IDLE_CLOSE_SECONDS = 600  # 10 minutes total (5 min followup + 5 min more)

FOLLOWUP_MESSAGE = "Oi! Precisa de mais alguma coisa? Estou aqui se precisar."
GOODBYE_MESSAGE = (
    "Parece que voce esta ocupado(a). Vou encerrar por aqui. "
    "Se precisar, e so mandar mensagem! Ate mais!"
)

# Track active idle timers per session
_idle_timers: dict[str, asyncio.Task] = {}


async def _idle_check(
    session_id: UUID,
    phone: str,
    wa_client: WhatsAppClient,
    student_name: str | None = None,
) -> None:
    """Background task: wait for idle timeout, then follow up or close.

    Flow:
    1. Wait 5 minutes
    2. Check if session had new activity -> if yes, cancel
    3. If still idle -> send follow-up message
    4. Wait 5 more minutes
    5. Check again -> if still idle -> send goodbye + close session
    """
    from src.features.chat.models import ChatSession, ChatMessage

    try:
        # Phase 1: Wait for initial idle period
        await asyncio.sleep(IDLE_FOLLOWUP_SECONDS)

        # Check if new messages arrived during wait
        async with async_session() as db:
            result = await db.execute(
                select(ChatMessage)
                .where(
                    ChatMessage.chat_session_id == session_id,
                    ChatMessage.role == "user",
                    ChatMessage.created_at
                    > datetime.now(timezone.utc) - timedelta(seconds=IDLE_FOLLOWUP_SECONDS),
                )
                .limit(1)
            )
            recent_msg = result.scalar_one_or_none()
            if recent_msg:
                return  # Student sent a message — not idle

            # Check session still active
            sess_result = await db.execute(
                select(ChatSession).where(ChatSession.id == session_id)
            )
            session = sess_result.scalar_one_or_none()
            if not session or session.status != "active":
                return

        # Send follow-up (D-03: only after idle period)
        followup = FOLLOWUP_MESSAGE
        if student_name:
            followup = f"Oi, {student_name}! Precisa de mais alguma coisa?"
        await wa_client.send_text_message(phone, followup)

        # Save follow-up as assistant message
        async with async_session() as db:
            from src.features.webhook.service import WebhookService

            webhook_service = WebhookService()
            await webhook_service.save_message(
                session_id=session_id,
                role="assistant",
                content=followup,
                media_type=None,
                wamid=None,
                db=db,
            )
            await db.commit()

        # Phase 2: Wait for second idle period
        await asyncio.sleep(IDLE_FOLLOWUP_SECONDS)

        # Check again for new activity
        async with async_session() as db:
            result = await db.execute(
                select(ChatMessage)
                .where(
                    ChatMessage.chat_session_id == session_id,
                    ChatMessage.role == "user",
                    ChatMessage.created_at
                    > datetime.now(timezone.utc) - timedelta(seconds=IDLE_FOLLOWUP_SECONDS),
                )
                .limit(1)
            )
            recent_msg = result.scalar_one_or_none()
            if recent_msg:
                return  # Student responded

            # Close session (D-04: always send goodbye)
            sess_result = await db.execute(
                select(ChatSession).where(ChatSession.id == session_id)
            )
            session = sess_result.scalar_one_or_none()
            if not session or session.status != "active":
                return

            goodbye = GOODBYE_MESSAGE
            if student_name:
                goodbye = f"Ate mais, {student_name}! Se precisar, e so mandar mensagem."

            from src.features.webhook.service import WebhookService

            webhook_service = WebhookService()
            await webhook_service.save_message(
                session_id=session_id,
                role="assistant",
                content=goodbye,
                media_type=None,
                wamid=None,
                db=db,
            )
            await webhook_service.close_session(session, db)
            await db.commit()

        await wa_client.send_text_message(phone, goodbye)
        logger.info("Session %s closed by idle timeout", session_id)

    except asyncio.CancelledError:
        pass  # Timer cancelled because student sent a message
    except Exception as exc:
        logger.error("Idle monitor error for session %s: %s", session_id, exc)
    finally:
        _idle_timers.pop(str(session_id), None)


def schedule_idle_check(
    session_id: UUID,
    phone: str,
    wa_client: WhatsAppClient,
    student_name: str | None = None,
) -> None:
    """Schedule (or reset) an idle check for a session.

    Called after every message processing. Resets the timer on each new message.
    D-03: Follow-up only fires after genuine idle periods, not after every action.
    """
    key = str(session_id)

    # Cancel existing timer for this session (reset on new activity)
    existing = _idle_timers.get(key)
    if existing and not existing.done():
        existing.cancel()

    # Schedule new idle check
    task = asyncio.create_task(
        _idle_check(session_id, phone, wa_client, student_name)
    )
    task.add_done_callback(lambda t: t.exception() if not t.cancelled() else None)
    _idle_timers[key] = task


def cancel_idle_check(session_id: UUID) -> None:
    """Cancel idle check for a session (e.g., on explicit session close).

    Called when farewell is detected or session is closed by other means.
    Prevents the timer from firing after the session is already closed.
    T-20-15 mitigation: timer cleaned up from dict in finally block of _idle_check,
    and explicitly removed here on cancel.
    """
    key = str(session_id)
    existing = _idle_timers.pop(key, None)
    if existing and not existing.done():
        existing.cancel()
