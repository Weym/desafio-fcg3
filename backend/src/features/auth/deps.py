"""FastAPI dependencies and middleware for auth routes.

body_parser: caches request body on request.state to avoid double-read issue (P-01).
email_key_func: slowapi key_func (SYNC) that extracts email from the cached body.
BodyCacheMiddleware: pre-reads request body for /auth/ routes so key_func has access.
"""

import json

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.responses import Response


class BodyCacheMiddleware(BaseHTTPMiddleware):
    """Pre-reads and caches request body for /auth/ routes.

    slowapi key_func runs BEFORE FastAPI dependency resolution, so the
    body_parser Depends() hasn't executed yet. This middleware ensures the
    body is cached on request.state.parsed_body before slowapi evaluates limits.
    """

    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> Response:
        if request.url.path.startswith("/auth/") and request.method == "POST":
            raw = await request.body()
            try:
                request.state.parsed_body = json.loads(raw) if raw else {}
            except json.JSONDecodeError:
                request.state.parsed_body = {}
        return await call_next(request)


async def body_parser(request: Request) -> dict:
    """
    Mitigation for P-01: reads and caches request body on request.state.parsed_body.
    If BodyCacheMiddleware already ran, returns the cached value immediately.
    """
    if hasattr(request.state, "parsed_body"):
        return request.state.parsed_body
    raw = await request.body()
    try:
        data = json.loads(raw) if raw else {}
    except json.JSONDecodeError:
        data = {}
    request.state.parsed_body = data
    return data


def email_key_func(request: Request) -> str:
    """slowapi key_func (SYNC): rate limit by email extracted from cached body.

    Must be synchronous — slowapi calls key_func in a sync context.
    BodyCacheMiddleware has already cached the body on request.state.parsed_body.
    """
    body = getattr(request.state, "parsed_body", None)
    if body is None:
        body = {}
    email = (body.get("email") or "").lower().strip()
    return f"email:{email}" if email else "email:unknown"
