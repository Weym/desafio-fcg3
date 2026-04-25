from __future__ import annotations

import json
import time
from typing import Any
from uuid import UUID

from fastmcp.server.dependencies import get_http_headers
from fastmcp.server.middleware import Middleware, MiddlewareContext

from mcp_server.api_client import RETRY_STATE_KEY


def _to_json_payload(value: Any) -> str | None:
    if value is None:
        return None
    return json.dumps(value, default=str)


def _serialize_result(result: Any) -> Any:
    if hasattr(result, "model_dump"):
        return result.model_dump(mode="json")
    if hasattr(result, "dict"):
        return result.dict()
    if isinstance(result, (dict, list, str, int, float, bool)) or result is None:
        return result
    return str(result)


class ToolLoggingMiddleware(Middleware):
    def __init__(self) -> None:
        super().__init__()

    async def on_call_tool(self, context: MiddlewareContext, call_next):
        tool_name = context.message.name
        input_params = context.message.arguments or {}
        headers = get_http_headers(include={"x-chat-session-id"})
        raw_chat_session_id = headers.get("x-chat-session-id")
        start = time.monotonic()
        result: Any = None
        status = "success"

        try:
            result = await call_next(context)
        except Exception:
            status = "error"
            raise
        finally:
            latency_ms = int((time.monotonic() - start) * 1000)
            await self._log_call(
                context=context,
                tool_name=tool_name,
                input_params=input_params,
                raw_chat_session_id=raw_chat_session_id,
                result=result,
                latency_ms=latency_ms,
                status=status,
            )

        return result

    async def _log_call(
        self,
        *,
        context: MiddlewareContext,
        tool_name: str,
        input_params: dict[str, Any],
        raw_chat_session_id: str | None,
        result: Any,
        latency_ms: int,
        status: str,
    ) -> None:
        fastmcp_context = context.fastmcp_context
        if fastmcp_context is None or not raw_chat_session_id:
            return

        try:
            chat_session_id = UUID(raw_chat_session_id)
        except ValueError:
            return

        db_pool = fastmcp_context.lifespan_context.get("db_pool")
        if db_pool is None:
            return

        retry = bool(await fastmcp_context.get_state(RETRY_STATE_KEY))
        effective_status = status
        if status == "success" and retry:
            effective_status = "retry_success"

        try:
            await db_pool.execute(
                """
                INSERT INTO mcp_action_logs (
                    chat_session_id,
                    tool_name,
                    input_params,
                    output_result,
                    reasoning,
                    latency_ms,
                    retry,
                    status
                )
                VALUES ($1, $2, $3::jsonb, $4::jsonb, $5, $6, $7, $8)
                """,
                chat_session_id,
                tool_name,
                _to_json_payload(input_params) or "{}",
                _to_json_payload(_serialize_result(result)),
                None,
                latency_ms,
                retry,
                effective_status,
            )
        except Exception:
            return
