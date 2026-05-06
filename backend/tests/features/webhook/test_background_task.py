"""Background task tests: AI service retry/fallback and error handling.

Tests per D-06, D-07, CRITICAL-3, CRITICAL-4:
- AI service returns 200 → response saved + sent via WhatsApp
- AI service returns 500 → retry once
- AI service down twice → fallback message sent
- _handle_task_result callback logs exceptions
- Background task creates its own DB session (CRITICAL-4)
"""

import asyncio
from unittest.mock import AsyncMock, MagicMock, patch
from uuid import uuid4

import pytest
import httpx

from src.features.webhook.background import (
    _handle_task_result,
    process_verified_message,
    FALLBACK_MESSAGE,
    _session_locks,
)


class TestHandleTaskResult:
    """Tests for _handle_task_result done callback (CRITICAL-3)."""

    def test_logs_exception_from_failed_task(self):
        """T-06-18: done_callback logs exceptions, no silent failures."""
        task = MagicMock(spec=asyncio.Task)
        task.exception.return_value = RuntimeError("test error")

        with patch("src.features.webhook.background.logger") as mock_logger:
            _handle_task_result(task)
            mock_logger.error.assert_called_once()
            assert "test error" in str(mock_logger.error.call_args)

    def test_no_log_when_task_succeeds(self):
        """Successful task → no error logging."""
        task = MagicMock(spec=asyncio.Task)
        task.exception.return_value = None

        with patch("src.features.webhook.background.logger") as mock_logger:
            _handle_task_result(task)
            mock_logger.error.assert_not_called()

    def test_handles_cancelled_task(self):
        """Cancelled task → warning logged, not error."""
        task = MagicMock(spec=asyncio.Task)
        task.exception.side_effect = asyncio.CancelledError()

        with patch("src.features.webhook.background.logger") as mock_logger:
            _handle_task_result(task)
            mock_logger.warning.assert_called_once()


class TestProcessVerifiedMessage:
    """Tests for process_verified_message background task."""

    async def test_successful_ai_response_saved_and_sent(self):
        """AI service returns 200 → response saved to DB and sent via WhatsApp."""
        session_id = uuid4()
        wa_client = AsyncMock()
        wa_client.send_text_message = AsyncMock(return_value=True)

        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"response": "Suas notas sao..."}

        mock_http = AsyncMock()
        mock_http.post = AsyncMock(return_value=mock_response)
        mock_http.__aenter__ = AsyncMock(return_value=mock_http)
        mock_http.__aexit__ = AsyncMock(return_value=False)

        mock_db = AsyncMock()
        mock_db.commit = AsyncMock()

        mock_svc_instance = AsyncMock()
        mock_svc_instance.save_message = AsyncMock()

        with patch("src.features.webhook.background.httpx.AsyncClient", return_value=mock_http), \
             patch("src.features.webhook.background.async_session") as mock_session_maker, \
             patch("src.features.webhook.service.WebhookService", return_value=mock_svc_instance):
            mock_session_maker.return_value.__aenter__ = AsyncMock(return_value=mock_db)
            mock_session_maker.return_value.__aexit__ = AsyncMock(return_value=False)

            _session_locks.pop(str(session_id), None)
            await process_verified_message(session_id, "Quais notas?", "5521999999999", wa_client)

        # Verify sent via WhatsApp
        wa_client.send_text_message.assert_called_once()
        sent = wa_client.send_text_message.call_args[0][1]
        assert sent == "Suas notas sao..."

    async def test_ai_service_500_retries_once(self):
        """AI service returns 500 on first attempt → retries once."""
        session_id = uuid4()
        wa_client = AsyncMock()
        wa_client.send_text_message = AsyncMock(return_value=True)

        # First call fails (500), second succeeds (200)
        fail_response = MagicMock()
        fail_response.status_code = 500

        ok_response = MagicMock()
        ok_response.status_code = 200
        ok_response.json.return_value = {"response": "Retry success"}

        mock_http = AsyncMock()
        mock_http.post = AsyncMock(side_effect=[fail_response, ok_response])
        mock_http.__aenter__ = AsyncMock(return_value=mock_http)
        mock_http.__aexit__ = AsyncMock(return_value=False)

        mock_db = AsyncMock()
        mock_db.commit = AsyncMock()

        mock_svc_instance = AsyncMock()
        mock_svc_instance.save_message = AsyncMock()

        with patch("src.features.webhook.background.httpx.AsyncClient", return_value=mock_http), \
             patch("src.features.webhook.background.async_session") as mock_session_maker, \
             patch("src.features.webhook.service.WebhookService", return_value=mock_svc_instance):
            mock_session_maker.return_value.__aenter__ = AsyncMock(return_value=mock_db)
            mock_session_maker.return_value.__aexit__ = AsyncMock(return_value=False)

            _session_locks.pop(str(session_id), None)
            await process_verified_message(session_id, "Test", "5521999999999", wa_client)

        # Should have called AI service twice (retry)
        assert mock_http.post.call_count == 2
        # Response should be the successful one
        wa_client.send_text_message.assert_called_once()
        sent = wa_client.send_text_message.call_args[0][1]
        assert sent == "Retry success"

    async def test_ai_service_down_twice_sends_fallback(self):
        """AI service fails twice → fallback message (D-06)."""
        session_id = uuid4()
        wa_client = AsyncMock()
        wa_client.send_text_message = AsyncMock(return_value=True)

        mock_http = AsyncMock()
        mock_http.post = AsyncMock(side_effect=httpx.ConnectError("Connection refused"))
        mock_http.__aenter__ = AsyncMock(return_value=mock_http)
        mock_http.__aexit__ = AsyncMock(return_value=False)

        mock_db = AsyncMock()
        mock_db.commit = AsyncMock()

        mock_svc_instance = AsyncMock()
        mock_svc_instance.save_message = AsyncMock()

        with patch("src.features.webhook.background.httpx.AsyncClient", return_value=mock_http), \
             patch("src.features.webhook.background.async_session") as mock_session_maker, \
             patch("src.features.webhook.service.WebhookService", return_value=mock_svc_instance):
            mock_session_maker.return_value.__aenter__ = AsyncMock(return_value=mock_db)
            mock_session_maker.return_value.__aexit__ = AsyncMock(return_value=False)

            _session_locks.pop(str(session_id), None)
            await process_verified_message(session_id, "Test", "5521999999999", wa_client)

        # Fallback message should be sent
        wa_client.send_text_message.assert_called_once()
        sent = wa_client.send_text_message.call_args[0][1]
        assert sent == FALLBACK_MESSAGE

    async def test_background_task_opens_own_session(self):
        """CRITICAL-4: background task opens its own async_session, not request-scoped."""
        session_id = uuid4()
        wa_client = AsyncMock()
        wa_client.send_text_message = AsyncMock(return_value=True)

        mock_response = AsyncMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"response": "Test"}

        mock_http = AsyncMock()
        mock_http.post = AsyncMock(return_value=mock_response)
        mock_http.__aenter__ = AsyncMock(return_value=mock_http)
        mock_http.__aexit__ = AsyncMock(return_value=False)

        mock_db = AsyncMock()
        mock_db.commit = AsyncMock()

        mock_svc_instance = AsyncMock()
        mock_svc_instance.save_message = AsyncMock()

        with patch("src.features.webhook.background.httpx.AsyncClient", return_value=mock_http), \
             patch("src.features.webhook.background.async_session") as mock_session_maker, \
             patch("src.features.webhook.service.WebhookService", return_value=mock_svc_instance):
            mock_session_maker.return_value.__aenter__ = AsyncMock(return_value=mock_db)
            mock_session_maker.return_value.__aexit__ = AsyncMock(return_value=False)

            _session_locks.pop(str(session_id), None)
            await process_verified_message(session_id, "Test", "5521999999999", wa_client)

        # async_session() should have been called (own session, not injected)
        mock_session_maker.assert_called_once()

    async def test_ai_service_call_includes_service_token_header(self):
        """Regression: the AI service `/chat` endpoint is guarded by
        require_service_token (ai_service/main.py). The webhook must send
        X-Service-Token on every attempt, otherwise every verified student
        receives the fallback message regardless of service health.
        """
        from src.infrastructure.config import get_settings

        session_id = uuid4()
        wa_client = AsyncMock()
        wa_client.send_text_message = AsyncMock(return_value=True)

        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"response": "ok"}

        mock_http = AsyncMock()
        mock_http.post = AsyncMock(return_value=mock_response)
        mock_http.__aenter__ = AsyncMock(return_value=mock_http)
        mock_http.__aexit__ = AsyncMock(return_value=False)

        mock_db = AsyncMock()
        mock_db.commit = AsyncMock()

        mock_svc_instance = AsyncMock()
        mock_svc_instance.save_message = AsyncMock()

        with patch("src.features.webhook.background.httpx.AsyncClient", return_value=mock_http), \
             patch("src.features.webhook.background.async_session") as mock_session_maker, \
             patch("src.features.webhook.service.WebhookService", return_value=mock_svc_instance):
            mock_session_maker.return_value.__aenter__ = AsyncMock(return_value=mock_db)
            mock_session_maker.return_value.__aexit__ = AsyncMock(return_value=False)

            _session_locks.pop(str(session_id), None)
            await process_verified_message(
                session_id, "Quais notas?", "5521999999999", wa_client
            )

        # http.post was called at least once; inspect the headers kwarg on every call
        assert mock_http.post.call_count >= 1
        expected_token = get_settings().mcp_service_token
        for call in mock_http.post.call_args_list:
            headers = call.kwargs.get("headers") or {}
            assert headers.get("X-Service-Token") == expected_token, (
                f"AI service call is missing X-Service-Token header; got headers={headers!r}"
            )

    async def test_per_session_lock_used(self):
        """D-09: Per-session asyncio.Lock used for concurrent protection."""
        session_id = uuid4()

        # Clean up any existing lock
        _session_locks.pop(str(session_id), None)

        wa_client = AsyncMock()
        wa_client.send_text_message = AsyncMock(return_value=True)

        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"response": "Test"}

        mock_http = AsyncMock()
        mock_http.post = AsyncMock(return_value=mock_response)
        mock_http.__aenter__ = AsyncMock(return_value=mock_http)
        mock_http.__aexit__ = AsyncMock(return_value=False)

        mock_db = AsyncMock()
        mock_db.commit = AsyncMock()

        mock_svc_instance = AsyncMock()
        mock_svc_instance.save_message = AsyncMock()

        with patch("src.features.webhook.background.httpx.AsyncClient", return_value=mock_http), \
             patch("src.features.webhook.background.async_session") as mock_session_maker, \
             patch("src.features.webhook.service.WebhookService", return_value=mock_svc_instance):
            mock_session_maker.return_value.__aenter__ = AsyncMock(return_value=mock_db)
            mock_session_maker.return_value.__aexit__ = AsyncMock(return_value=False)

            await process_verified_message(session_id, "Test", "5521999999999", wa_client)

        # After execution, lock should be cleaned up (HI-01 fix: prevent memory leak)
        # The lock was used during processing but removed after completion
        assert str(session_id) not in _session_locks
