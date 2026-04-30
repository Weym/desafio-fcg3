"""Webhook business logic: phone lookup, session management, verification state machine.

This module contains the core webhook processing logic that runs BEFORE any
LangChain agent involvement. The verification state machine gates access to the
agent — unverified students NEVER reach the AI service (D-02).
"""

from __future__ import annotations

import logging
import re
import uuid
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import select, update, and_
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from src.features.auth.models import Student, VerificationCode
from src.features.auth.services import otp_service
from src.features.chat.models import ChatMessage, ChatSession
from src.infrastructure.whatsapp_client import WhatsAppClient

logger = logging.getLogger(__name__)

# Media type responses per docs/chatbot.md — hardcoded, no LLM
MEDIA_RESPONSES: dict[str, str] = {
    "audio": "Nao consigo processar audios ainda. Por favor, descreva sua duvida em texto.",
    "image": "Nao consigo analisar imagens ainda. Por favor, descreva o que precisa em texto.",
    "document": "Recebi um documento, mas nao consigo processa-lo ainda. Descreva sua solicitacao em texto.",
    "sticker": "Por favor, descreva sua duvida em texto para que eu possa te ajudar.",
    "location": "Nao preciso da sua localizacao. Como posso te ajudar? Digite sua duvida.",
    "video": "Nao consigo processar videos. Por favor, descreva sua solicitacao em texto.",
}

# Session close keywords per D-11
SESSION_CLOSE_KEYWORDS = {"sair", "encerrar"}

# Email regex for basic validation
EMAIL_REGEX = re.compile(r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$")


class WebhookService:
    """Webhook business logic encapsulating phone lookup, session management,
    and the verification state machine."""

    async def lookup_student_by_phone(
        self, phone: str, db: AsyncSession
    ) -> Optional[Student]:
        """Look up a student by phone number. Direct string comparison per D-04.

        Phone is stored in international format without + (e.g., '5521999999999').
        WhatsApp sends in this same format.
        """
        result = await db.execute(
            select(Student).where(
                and_(Student.phone == phone, Student.status == "active")
            )
        )
        return result.scalar_one_or_none()

    async def get_or_create_session(
        self, student_id: uuid.UUID, phone: str, db: AsyncSession
    ) -> ChatSession:
        """Reuse active session or create new one per D-10.

        D-10: Reuse active session per phone number.
        D-13: Closed session → new session, verification_state starts unverified.
        Updates updated_at on reuse for pg_cron auto-close tracking.
        """
        result = await db.execute(
            select(ChatSession).where(
                and_(
                    ChatSession.student_id == student_id,
                    ChatSession.status == "active",
                )
            )
        )
        session = result.scalar_one_or_none()
        if session is not None:
            # Touch updated_at for auto-close tracking (D-12)
            session.updated_at = datetime.now(timezone.utc)
            await db.flush()
            return session

        # Create new session — starts unverified (D-13)
        session = ChatSession(
            student_id=student_id,
            whatsapp_phone=phone,
            status="active",
            verification_state="unverified",
        )
        db.add(session)
        await db.flush()
        return session

    async def save_message(
        self,
        session_id: uuid.UUID,
        role: str,
        content: str,
        media_type: Optional[str],
        wamid: Optional[str],
        db: AsyncSession,
    ) -> Optional[ChatMessage]:
        """Save a message with deduplication by whatsapp_message_id.

        On IntegrityError (duplicate wamid per MODERATE-1), returns None
        to signal dedup — caller should skip processing.
        Also touches session.updated_at for pg_cron auto-close tracking.
        """
        msg = ChatMessage(
            chat_session_id=session_id,
            role=role,
            content=content,
            media_type=media_type,
            whatsapp_message_id=wamid,
        )
        db.add(msg)
        try:
            async with db.begin_nested():  # SAVEPOINT — rollback scoped, not full txn
                await db.flush()
                # Touch session updated_at for auto-close tracking (D-12)
                await db.execute(
                    update(ChatSession)
                    .where(ChatSession.id == session_id)
                    .values(updated_at=datetime.now(timezone.utc))
                )
            return msg
        except IntegrityError:
            logger.info("Duplicate wamid detected, skipping: %s", wamid)
            return None

    async def close_session(
        self, session: ChatSession, db: AsyncSession
    ) -> None:
        """Close a chat session per D-11."""
        session.status = "closed"
        session.ended_at = datetime.now(timezone.utc)
        await db.flush()

    async def handle_verification_flow(
        self,
        session: ChatSession,
        message_text: str,
        phone: str,
        db: AsyncSession,
        wa_client: WhatsAppClient,
    ) -> None:
        """Implement the verification state machine per D-02.

        States:
        - unverified: Ask for institutional email
        - awaiting_email: Validate email, send OTP
        - awaiting_code: Validate 6-digit code
        - verified: Message goes to agent (handled in router, not here)
        """
        state = session.verification_state

        if state == "unverified":
            # First message from unverified user — ask for email
            session.verification_state = "awaiting_email"
            await db.flush()
            await wa_client.send_text_message(
                phone,
                "Preciso verificar sua identidade. Qual seu email institucional?",
            )

        elif state == "awaiting_email":
            await self._handle_awaiting_email(
                session, message_text, phone, db, wa_client
            )

        elif state == "awaiting_code":
            await self._handle_awaiting_code(
                session, message_text, phone, db, wa_client
            )

    async def _handle_awaiting_email(
        self,
        session: ChatSession,
        message_text: str,
        phone: str,
        db: AsyncSession,
        wa_client: WhatsAppClient,
    ) -> None:
        """Handle the awaiting_email state: parse email, verify student, send OTP."""
        email = message_text.strip().lower()

        # Basic email format check
        if not EMAIL_REGEX.match(email):
            await wa_client.send_text_message(
                phone,
                "Formato de email invalido. Por favor, informe seu email institucional.",
            )
            return

        # Look up student by email
        result = await db.execute(
            select(Student).where(Student.email == email)
        )
        student = result.scalar_one_or_none()

        if student is None:
            await wa_client.send_text_message(
                phone,
                "Nao encontrei cadastro com esse email. Verifique o email e tente novamente.",
            )
            return

        # Verify the email matches the session's student
        if student.id != session.student_id:
            await wa_client.send_text_message(
                phone,
                "Nao encontrei cadastro com esse email. Verifique o email e tente novamente.",
            )
            return

        # Generate and send OTP code
        await otp_service.generate_and_send_code(db, email)
        session.verification_state = "awaiting_code"
        await db.flush()

        await wa_client.send_text_message(
            phone,
            "Enviei um codigo para seu email. Informe o codigo de 6 digitos.",
        )

    async def _handle_awaiting_code(
        self,
        session: ChatSession,
        message_text: str,
        phone: str,
        db: AsyncSession,
        wa_client: WhatsAppClient,
    ) -> None:
        """Handle the awaiting_code state: validate 6-digit OTP code."""
        from src.infrastructure.config import get_settings

        settings = get_settings()
        code = message_text.strip()

        # Must be exactly 6 digits
        if not re.match(r"^\d{6}$", code):
            await wa_client.send_text_message(
                phone,
                "Por favor, informe o codigo de 6 digitos enviado para seu email.",
            )
            return

        # Look up the student's email for OTP verification
        result = await db.execute(
            select(Student).where(Student.id == session.student_id)
        )
        student = result.scalar_one_or_none()
        if student is None:
            logger.error(
                "Student not found for session %s", session.id
            )
            return

        # Find the latest unused code for this email
        code_result = await db.execute(
            select(VerificationCode)
            .where(
                VerificationCode.email == student.email,
                VerificationCode.used == False,  # noqa: E712
            )
            .order_by(VerificationCode.created_at.desc())
            .limit(1)
        )
        code_row = code_result.scalar_one_or_none()

        if code_row is None:
            await wa_client.send_text_message(
                phone,
                "Codigo expirado. Envie seu email novamente para receber um novo codigo.",
            )
            session.verification_state = "awaiting_email"
            await db.flush()
            return

        # Check expiry
        now = datetime.now(timezone.utc)
        expires_at = code_row.expires_at
        if expires_at.tzinfo is None:
            expires_at = expires_at.replace(tzinfo=timezone.utc)
        if expires_at < now:
            await wa_client.send_text_message(
                phone,
                "Codigo expirado. Envie seu email novamente para receber um novo codigo.",
            )
            session.verification_state = "awaiting_email"
            await db.flush()
            return

        # Verify code hash
        if not otp_service.verify_code_hash(code, code_row.code_hash, code_row.code_salt):
            code_row.attempts += 1
            remaining = settings.otp_max_attempts - code_row.attempts

            if code_row.attempts >= settings.otp_max_attempts:
                # Max attempts — invalidate and send new code
                code_row.used = True
                await db.flush()
                await otp_service.generate_and_send_code(db, student.email)
                await wa_client.send_text_message(
                    phone,
                    "Codigo invalido. Limite atingido. Enviei um novo codigo para seu email.",
                )
            else:
                await db.flush()
                await wa_client.send_text_message(
                    phone,
                    f"Codigo invalido. Tente novamente. ({remaining} tentativa(s) restante(s))",
                )
            return

        # Code is valid — mark as verified
        code_row.used = True
        session.verification_state = "verified"
        await db.flush()

        await wa_client.send_text_message(
            phone,
            f"Identidade verificada! Ola, {student.name}. Como posso ajudar?",
        )

    def get_media_response(self, media_type: str) -> str:
        """Return exact Portuguese response for media type per docs/chatbot.md.

        Hardcoded responses — no LLM involved (per D-02 specifics).
        """
        return MEDIA_RESPONSES.get(
            media_type,
            "Por favor, descreva sua duvida em texto para que eu possa te ajudar.",
        )
