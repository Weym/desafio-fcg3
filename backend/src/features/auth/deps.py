"""FastAPI dependencies for auth routes.

body_parser: caches request body on request.state to avoid double-read issue (P-01).
email_key_func: slowapi key_func that extracts email from the cached body.
"""

import json
from fastapi import Request


async def body_parser(request: Request) -> dict:
    """
    Mitigation for P-01: slowapi key_func runs before FastAPI body parsing, so
    if email_key_func calls `await request.json()` and then the route handler
    does too, Starlette raises 'body already consumed'. This dependency runs
    FIRST (as the route's Depends), reads request.body() once, caches it on
    request.state.parsed_body, and returns the dict. email_key_func reads the
    same cached value.
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


async def email_key_func(request: Request) -> str:
    """slowapi key_func: rate limit by email extracted from cached body."""
    body = getattr(request.state, "parsed_body", None)
    if body is None:
        # Fallback — body_parser should have run first, but in case it didn't, read now.
        raw = await request.body()
        try:
            body = json.loads(raw) if raw else {}
        except json.JSONDecodeError:
            body = {}
        request.state.parsed_body = body
    email = (body.get("email") or "").lower().strip()
    return f"email:{email}" if email else "email:unknown"
