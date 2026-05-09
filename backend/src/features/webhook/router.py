"""Webhook router: GET and POST /webhook/whatsapp endpoints.

GET: Webhook verification challenge per WH-01.
POST: Receive WhatsApp messages per WH-02, WH-03, WH-04.

Lazy OTP (D-13/D-14): Unverified students reach the AI agent for read-only
operations. Only awaiting_email/awaiting_code states route to verification flow.
Mutating actions are gated by the agent + MCP middleware (D-15/D-21).

CRITICAL-1: Raw body is read FIRST before any JSON parsing for HMAC validation.
CRITICAL-3: Background tasks use add_done_callback for error visibility.
CRITICAL-4: Background tasks open their OWN DB session (not request-scoped).
"""

from __future__ import annotations

import asyncio
import hmac
import logging

from fastapi import APIRouter, HTTPException, Query, Request
from fastapi.responses import PlainTextResponse, Response

from src.features.webhook.background import (
    _handle_task_result,
    process_message,
)
from src.features.webhook.dependencies import get_whatsapp_client, get_webhook_service
from src.features.webhook.schemas import WhatsAppWebhookPayload
from src.features.webhook.service import SESSION_CLOSE_KEYWORDS
from src.infrastructure.config import get_settings
from src.infrastructure.database import async_session
from src.infrastructure.whatsapp_client import validate_signature

logger = logging.getLogger(__name__)

router = APIRouter(tags=["webhook"])


@router.get("/webhook/whatsapp")
async def webhook_challenge(
    hub_mode: str = Query(None, alias="hub.mode"),
    hub_verify_token: str = Query(None, alias="hub.verify_token"),
    hub_challenge: str = Query(None, alias="hub.challenge"),
) -> PlainTextResponse:
    """Webhook verification challenge per WH-01.

    Meta sends hub.mode=subscribe, hub.verify_token, hub.challenge.
    Respond with hub.challenge if verify_token matches.
    """
    settings = get_settings()
    if (
        hub_mode == "subscribe"
        and hmac.compare_digest(hub_verify_token or "", settings.whatsapp_webhook_verify_token)
    ):
        return PlainTextResponse(content=hub_challenge)
    raise HTTPException(status_code=403, detail="Verification failed")


@router.post("/webhook/whatsapp")
async def whatsapp_webhook(request: Request) -> Response:
    """Receive WhatsApp messages per WH-02, WH-03, WH-04.

    CRITICAL-1: Read raw body FIRST before any parsing for HMAC validation.
    Returns 200 OK immediately — processing is async (< 5s WhatsApp budget).
    """
    settings = get_settings()

    # CRITICAL-1: Read raw body FIRST before any parsing
    raw_body = await request.body()

    # Validate HMAC-SHA256 signature
    signature = request.headers.get("X-Hub-Signature-256", "")
    if not validate_signature(raw_body, signature, settings.whatsapp_app_secret):
        raise HTTPException(status_code=403, detail="Invalid signature")

    # Parse payload manually (not via Pydantic body param to avoid double-read)
    payload = WhatsAppWebhookPayload.model_validate_json(raw_body)

    wa_client = get_whatsapp_client()
    webhook_service = get_webhook_service()

    # Process each entry/change/message
    for entry in payload.entry:
        for change in entry.changes:
            # Filter out status updates (delivery receipts) — MODERATE-1
            if not change.value.messages:
                continue

            for message in change.value.messages:
                phone = message.from_
                wamid = message.id

                # Open own DB session (CRITICAL-4 — not request-scoped)
                async with async_session() as db:
                    # Phone lookup per D-04
                    student = await webhook_service.lookup_student_by_phone(
                        phone, db
                    )
                    logger.info(
                        "webhook msg: from=%s wamid=%s type=%s student_found=%s",
                        phone,
                        wamid,
                        message.type,
                        student is not None,
                    )
                    if student is None:
                        # D-03: Unknown phone, send rejection, no session
                        await wa_client.send_text_message(
                            phone,
                            "Nao encontrei cadastro para este numero. "
                            "Procure a secretaria para cadastro.",
                        )
                        continue

                    session = await webhook_service.get_or_create_session(
                        student.id, phone, db
                    )

                    # Handle media messages immediately (no agent) per docs/chatbot.md
                    if message.type != "text":
                        media_response = webhook_service.get_media_response(
                            message.type
                        )
                        # Only persist media_type for types the DB constraint allows
                        _known_media = {"audio", "image", "document", "video", "sticker"}
                        await webhook_service.save_message(
                            session.id,
                            "user",
                            f"[{message.type}]",
                            message.type if message.type in _known_media else None,
                            wamid,
                            db,
                        )
                        await webhook_service.save_message(
                            session.id,
                            "assistant",
                            media_response,
                            None,
                            None,
                            db,
                        )
                        await db.commit()
                        await wa_client.send_text_message(phone, media_response)
                        continue

                    # Text message — extract body
                    if message.text is None:
                        continue
                    text_content = message.text.body

                    # D-11: close-keywords close the session (checked BEFORE
                    # verification so users can always escape the OTP flow).
                    # Vocabulary is the single source of truth in
                    # `WebhookService` — see `SESSION_CLOSE_KEYWORDS`.
                    if text_content.strip().lower() in SESSION_CLOSE_KEYWORDS:
                        await webhook_service.save_message(
                            session.id, "user", text_content, None, wamid, db
                        )
                        await webhook_service.close_session(session, db)
                        await db.commit()
                        await wa_client.send_text_message(
                            phone, "Sessao encerrada. Ate logo!"
                        )
                        continue

                    # Save user message with dedup
                    msg = await webhook_service.save_message(
                        session.id, "user", text_content, None, wamid, db
                    )
                    if msg is None:
                        continue  # duplicate wamid, skip

                    # Lazy OTP routing per D-13/D-14:
                    # - "awaiting_email" / "awaiting_code": OTP in progress → verification flow
                    # - "unverified" / "verified": route to agent (reads trust phone identity;
                    #   mutating actions gated by agent + MCP middleware per D-15/D-21)
                    if session.verification_state in ("awaiting_email", "awaiting_code"):
                        await webhook_service.handle_verification_flow(
                            session, text_content, phone, db, wa_client
                        )
                        await db.commit()
                        continue

                    # Unverified or verified: dispatch to AI agent
                    await db.commit()

                    # HI-01: Skip AI dispatch if session is under human intervention
                    if session.status in ("human_needed", "human_active"):
                        logger.info(
                            "Session %s in human intervention (status=%s), skipping AI",
                            session.id,
                            session.status,
                        )
                        continue

                    task = asyncio.create_task(
                        process_message(
                            session.id, text_content, phone, wa_client
                        )
                    )
                    task.add_done_callback(_handle_task_result)  # CRITICAL-3

    return Response(status_code=200)
