from __future__ import annotations

import json
from typing import Any

import httpx
from fastmcp.exceptions import ToolError
from fastmcp.server.dependencies import get_context


GENERIC_SERVER_ERROR = "Erro interno do servidor. Tente novamente mais tarde."
RETRY_STATE_KEY = "api_retry"


def _format_error_message(message: str) -> str:
    normalized = message.strip()
    if normalized.lower().startswith("erro:"):
        return normalized
    return f"Erro: {normalized}"


def _translate_error_message(response: httpx.Response) -> str:
    try:
        payload = response.json()
    except json.JSONDecodeError:
        payload = None

    if isinstance(payload, dict):
        error = payload.get("error")
        if isinstance(error, dict):
            message = error.get("message")
            if isinstance(message, str) and message.strip():
                return _format_error_message(message)

            code = error.get("code")
            if isinstance(code, str) and code.strip():
                translated = code.replace("_", " ").lower()
                return _format_error_message(translated)

    return _format_error_message("Nao foi possivel concluir a solicitacao")


async def _mark_retry_state() -> None:
    try:
        ctx = get_context()
    except RuntimeError:
        return

    await ctx.set_state(RETRY_STATE_KEY, True, serializable=False)


async def call_api_raw(
    client: httpx.AsyncClient,
    method: str,
    path: str,
    *,
    student_id: str | None = None,
    **kwargs: Any,
) -> tuple[httpx.Response, bool]:
    if student_id is not None:
        existing_headers = kwargs.get("headers") or {}
        kwargs["headers"] = {**existing_headers, "X-Student-Id": student_id}

    try:
        response = await client.request(method, path, **kwargs)
        response.raise_for_status()
        return response, False
    except httpx.HTTPStatusError as exc:
        if exc.response.status_code < 500:
            raise ToolError(_translate_error_message(exc.response)) from exc
    except (httpx.TimeoutException, httpx.RequestError):
        pass

    try:
        response = await client.request(method, path, **kwargs)
        response.raise_for_status()
        await _mark_retry_state()
        return response, True
    except httpx.HTTPStatusError as exc:
        if exc.response.status_code < 500:
            raise ToolError(_translate_error_message(exc.response)) from exc
        raise ToolError(GENERIC_SERVER_ERROR) from exc
    except httpx.TimeoutException as exc:
        raise ToolError(GENERIC_SERVER_ERROR) from exc
    except httpx.RequestError as exc:
        raise ToolError(GENERIC_SERVER_ERROR) from exc


async def call_api(
    client: httpx.AsyncClient,
    method: str,
    path: str,
    *,
    student_id: str | None = None,
    **kwargs: Any,
) -> tuple[dict[str, Any], bool]:
    response, retried = await call_api_raw(client, method, path, student_id=student_id, **kwargs)
    data = response.json()
    if not isinstance(data, dict):
        raise ToolError(GENERIC_SERVER_ERROR)
    return data, retried
