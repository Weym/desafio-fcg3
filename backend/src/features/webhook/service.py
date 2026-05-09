"""Webhook business logic: phone lookup, session management, verification state machine.

This module contains the core webhook processing logic that runs BEFORE any
LangChain agent involvement. With lazy OTP (D-13/D-14), unverified students
CAN reach the AI agent for read-only operations — verification is only triggered
mid-conversation when a mutating action is needed (D-15/D-16).

The verification state machine handles OTP flow once initiated (awaiting_email,
awaiting_code states).
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

# Media type responses — hardcoded, no LLM. Tone matches Alpha persona (D-17, D-24).
MEDIA_RESPONSES: dict[str, str] = {
    "audio": "Ainda nao consigo ouvir audios, mas estou aqui para te ajudar! Descreva sua duvida em texto e vou resolver.",
    "image": "Nao tenho como analisar imagens por enquanto. Me conta em texto o que voce precisa e vamos resolver juntos!",
    "document": "Recebi seu documento, mas nao consigo processa-lo diretamente. Me descreva a solicitacao em texto — se precisar enviar documentos oficiais, posso te orientar pelo processo correto.",
    "sticker": "Haha, entendi o sentimento! Mas para te ajudar melhor, me conta em texto o que precisa.",
    "location": "Obrigado pela localizacao, mas nao preciso dela para te ajudar. Me diz: o que posso fazer por voce hoje?",
    "video": "Videos ainda nao estao no meu repertorio. Descreve em texto o que precisa e eu te ajudo!",
}

# Session close keywords per D-11.
# User-friendly variants added per debug session
# `.planning/debug/whatsapp-otp-loop-no-cancel.md`: users naturally reach for
# "cancelar"/"parar"/"stop" when they want to abandon the OTP flow; recognising
# only "sair"/"encerrar" produced an undiscoverable infinite loop during
# verification. Keep lookup case-insensitive via `.strip().lower()`.
SESSION_CLOSE_KEYWORDS = {
    "sair",
    "encerrar",
    "cancelar",
    "cancel",
    "parar",
    "stop",
}

# Email regex for basic validation
EMAIL_REGEX = re.compile(r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$")


def _phone_variants(phone: str) -> list[str]:
    """Return lookup variants for a Brazilian-format phone number.

    Handles the Brazilian "9th digit" quirk: mobile numbers from all DDDs
    officially carry a leading `9` after the area code (13 digits total
    for Country Code + DDD + 9XXXXXXXX), but the WhatsApp Cloud API is
    observed to sometimes strip that `9` and deliver the legacy 12-digit
    form (e.g., `558398257544` instead of `5583998257544`).

    To match either, we return a list containing the original input plus,
    when applicable, the sibling variant. Comparison is done via IN (...)
    in the SQL query.

    This function does NOT strip a leading `+` — per D-04 stored phones
    have no `+`, so a `+`-prefixed input should not match. We only
    expand within plain digit strings that start with the Brazil
    country code `55`.
    """
    variants = [phone]
    if not phone.startswith("55") or not phone.isdigit():
        return variants

    # 12 digits: 55 + DDD(2) + subscriber(8) → add 13-digit variant with `9`
    if len(phone) == 12:
        cc_ddd = phone[:4]            # "5583"
        subscriber = phone[4:]        # "98257544"
        # Only synthesize a mobile if the 8-digit subscriber starts with 8 or 9
        # (the Brazilian mobile range). Avoids synthesizing bogus 9-prefixed
        # numbers for landlines that happen to be 12 digits.
        if subscriber[0] in ("8", "9"):
            variants.append(f"{cc_ddd}9{subscriber}")
        return variants

    # 13 digits: 55 + DDD(2) + 9 + subscriber(8) → add 12-digit variant
    if len(phone) == 13 and phone[4] == "9":
        variants.append(phone[:4] + phone[5:])
        return variants

    return variants


class WebhookService:
    """Webhook business logic encapsulating phone lookup, session management,
    and the verification state machine."""

    async def lookup_student_by_phone(
        self, phone: str, db: AsyncSession
    ) -> Optional[Student]:
        """Look up a student by phone number per D-04.

        Accepts both 12-digit (legacy) and 13-digit (with mobile `9`) Brazilian
        phone formats, because the WhatsApp Cloud API is observed to send the
        legacy 12-digit form while student records are stored with the modern
        13-digit form (or vice versa). See `_phone_variants`.
        """
        variants = _phone_variants(phone)
        result = await db.execute(
            select(Student).where(
                and_(Student.phone.in_(variants), Student.status == "active")
            )
        )
        return result.scalar_one_or_none()

    async def get_or_create_session(
        self, student_id: uuid.UUID, phone: str, db: AsyncSession
    ) -> tuple[ChatSession, bool]:
        """Reuse active session or create new one per D-10.

        D-10: Reuse active session per phone number.
        D-13: Closed session → new session, verification_state starts unverified.
        Updates updated_at on reuse for pg_cron auto-close tracking.

        Returns:
            Tuple of (session, is_new) where is_new=True if session was just created.
            Used by router to trigger welcome message generation (D-01).
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
            return session, False

        # Create new session — starts unverified (D-13)
        session = ChatSession(
            student_id=student_id,
            whatsapp_phone=phone,
            status="active",
            verification_state="unverified",
        )
        db.add(session)
        await db.flush()
        return session, True

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

    async def initiate_mid_conversation_verification(
        self, session: ChatSession, db: AsyncSession
    ) -> None:
        """Transition session to awaiting_email state for mid-conversation OTP.

        Called when the agent requests verification for a mutating action.
        The student's next message will be processed by the verification flow.
        Per D-15: Agent naturally asks for email when mutating action is needed.
        Per D-16: Once OTP is completed, verification persists for entire session.
        """
        session.verification_state = "awaiting_email"
        await db.flush()

    async def handle_verification_flow(
        self,
        session: ChatSession,
        message_text: str,
        phone: str,
        db: AsyncSession,
        wa_client: WhatsAppClient,
    ) -> None:
        """Implement the verification state machine for OTP in progress.

        With lazy OTP (D-13/D-14), this method is only called when OTP is
        already in progress (awaiting_email or awaiting_code). The "unverified"
        state no longer routes here — unverified students go directly to the
        AI agent for read-only operations.

        States handled:
        - awaiting_email: Validate email, send OTP
        - awaiting_code: Validate 6-digit code
        - verified: Message goes to agent (handled in router, not here)
        """
        state = session.verification_state

        if state == "awaiting_email":
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
            "Enviei um codigo para seu email. Informe o codigo de 6 digitos "
            "(ou envie 'cancelar' para sair).",
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
                "Por favor, informe o codigo de 6 digitos enviado para seu email "
                "(ou envie 'cancelar' para sair).",
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
                # MAX_ATTEMPTS_REACHED is a TERMINAL state per CONVENTIONS.md
                # ("Rate limiting: 429 for OTP attempts exhausted").
                # Invalidate the code and CLOSE the session — do NOT auto-reissue
                # a fresh OTP, which previously trapped the user in an infinite
                # `awaiting_code` loop (see debug session
                # `.planning/debug/whatsapp-otp-loop-no-cancel.md`).
                code_row.used = True
                session.status = "closed"
                session.ended_at = datetime.now(timezone.utc)
                await db.flush()
                await wa_client.send_text_message(
                    phone,
                    "Numero maximo de tentativas atingido. Sessao encerrada. "
                    "Envie qualquer mensagem para recomecar.",
                )
            else:
                await db.flush()
                await wa_client.send_text_message(
                    phone,
                    f"Codigo invalido. Tente novamente. ({remaining} tentativa(s) restante(s)) "
                    "Ou envie 'cancelar' para sair.",
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
