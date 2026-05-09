"""Centralized notification service with Firebase Admin SDK integration.

Provides:
- init_firebase(): Called at app startup to initialize Firebase Admin SDK
- NotificationService: Sends push notifications to student devices via FCM
- notification_service: Module-level singleton instance

Design decisions:
- Fire-and-forget (D-12): send failures are logged, never raised
- Invalid token cleanup (D-05): UnregisteredError triggers token deletion
- Graceful degradation: If FCM_CREDENTIALS_PATH is None, all sends are no-op
- All notification content in Portuguese
"""

from __future__ import annotations

import asyncio
import logging
from uuid import UUID

from sqlalchemy import select, delete as sql_delete
from sqlalchemy.ext.asyncio import AsyncSession

from src.features.notifications.schemas import NotificationEvent
from src.infrastructure.config import get_settings

logger = logging.getLogger(__name__)

# Module-level state — set by init_firebase()
_firebase_initialized = False


def init_firebase() -> None:
    """Initialize Firebase Admin SDK from FCM_CREDENTIALS_PATH.

    Called once at app startup (from main.py lifespan).
    If fcm_credentials_path is None or empty, logs a warning and makes all
    send operations no-op (graceful degradation per D-12).
    """
    global _firebase_initialized

    settings = get_settings()
    if not settings.fcm_credentials_path:
        logger.warning(
            "FCM_CREDENTIALS_PATH not set — push notifications disabled. "
            "Set the environment variable to enable FCM."
        )
        return

    try:
        import firebase_admin
        from firebase_admin import credentials

        if not firebase_admin._apps:
            cred = credentials.Certificate(settings.fcm_credentials_path)
            firebase_admin.initialize_app(cred)
            _firebase_initialized = True
            logger.info("Firebase Admin SDK initialized successfully")
        else:
            _firebase_initialized = True
            logger.info("Firebase Admin SDK already initialized")
    except Exception as exc:
        logger.error("Failed to initialize Firebase Admin SDK: %s", exc)
        _firebase_initialized = False


class NotificationService:
    """Centralized FCM push notification service.

    All methods are fire-and-forget — errors are logged but never propagated.
    Invalid tokens are cleaned up automatically on send failure.
    """

    async def send_push(
        self,
        db: AsyncSession,
        student_id: UUID,
        event: NotificationEvent,
        title: str,
        body: str,
        data: dict[str, str] | None = None,
    ) -> None:
        """Dispatch FCM message to all registered tokens for a student.

        Args:
            db: Async database session for token queries and cleanup
            student_id: Target student UUID
            event: Notification event type
            title: Push notification title (displayed in system tray)
            body: Push notification body text
            data: Optional data payload (key-value pairs for client handling)
        """
        if not _firebase_initialized:
            logger.debug(
                "FCM not initialized — skipping push for student %s, event %s",
                student_id,
                event,
            )
            return

        from src.features.auth.models import FcmToken

        # Query all tokens for this student
        result = await db.execute(
            select(FcmToken).where(FcmToken.student_id == student_id)
        )
        tokens = result.scalars().all()

        if not tokens:
            logger.debug(
                "No FCM tokens registered for student %s — skipping push",
                student_id,
            )
            return

        from firebase_admin import messaging

        payload_data = data or {}
        payload_data["event"] = event.value

        for fcm_token in tokens:
            try:
                message = messaging.Message(
                    notification=messaging.Notification(
                        title=title,
                        body=body,
                    ),
                    data=payload_data,
                    token=fcm_token.token,
                )
                # firebase-admin messaging.send() is blocking — run in thread
                await asyncio.to_thread(messaging.send, message)
                logger.info(
                    "FCM push sent: student=%s event=%s token=%s...",
                    student_id,
                    event,
                    fcm_token.token[:20],
                )
            except (
                messaging.UnregisteredError,
                messaging.SenderIdMismatchError,
            ):
                # D-05: Invalid token — remove from database
                logger.warning(
                    "FCM token invalid (unregistered/mismatch), removing: "
                    "student=%s token=%s...",
                    student_id,
                    fcm_token.token[:20],
                )
                await db.execute(
                    sql_delete(FcmToken).where(FcmToken.id == fcm_token.id)
                )
                await db.commit()
            except Exception as exc:
                # D-12: Fire-and-forget — log error, continue to next token
                logger.error(
                    "FCM send failed: student=%s token=%s... error=%s",
                    student_id,
                    fcm_token.token[:20],
                    exc,
                )

    # ------------------------------------------------------------------
    # Event-specific helpers (called by feature services)
    # ------------------------------------------------------------------

    async def notify_document_ready(
        self,
        db: AsyncSession,
        student_id: UUID,
        document_type: str,
        document_id: UUID,
    ) -> None:
        """Notify student that their document is ready for pickup (D-09)."""
        await self.send_push(
            db=db,
            student_id=student_id,
            event=NotificationEvent.document_ready,
            title="Documento pronto",
            body=f"Seu {document_type} está pronto para retirada",
            data={"document_id": str(document_id)},
        )

    async def notify_enrollment_confirmed(
        self,
        db: AsyncSession,
        student_id: UUID,
        enrollment_id: UUID,
    ) -> None:
        """Notify student that their enrollment was confirmed."""
        await self.send_push(
            db=db,
            student_id=student_id,
            event=NotificationEvent.enrollment_confirmed,
            title="Matrícula confirmada",
            body="Sua matrícula foi confirmada com sucesso",
            data={"enrollment_id": str(enrollment_id)},
        )

    async def notify_appointment_confirmed(
        self,
        db: AsyncSession,
        student_id: UUID,
        appointment_id: UUID,
    ) -> None:
        """Notify student that their appointment was confirmed."""
        await self.send_push(
            db=db,
            student_id=student_id,
            event=NotificationEvent.appointment_confirmed,
            title="Agendamento confirmado",
            body="Seu agendamento foi confirmado",
            data={"appointment_id": str(appointment_id)},
        )


# Module-level singleton
notification_service = NotificationService()
