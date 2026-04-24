from slowapi import Limiter
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded
from fastapi import Request
from fastapi.responses import JSONResponse

# Singleton — imported wherever a route needs @limiter.limit(...)
limiter = Limiter(key_func=get_remote_address)


def rate_limit_exceeded_handler(request: Request, exc: RateLimitExceeded) -> JSONResponse:
    """D-13/D-14: per-email/IP rate limit -> 429 with our canonical error shape."""
    return JSONResponse(
        status_code=429,
        content={
            "error": {
                "code": "MAX_ATTEMPTS_REACHED",
                "message": "Too many requests. Please wait before trying again.",
                "details": [{"limit": str(exc.detail)}],
            }
        },
    )


def reset() -> None:
    """Test helper — clears in-memory storage between tests (used by reset_limiter fixture)."""
    # slowapi in-memory backend exposes ._storage or storage
    storage = getattr(limiter, "_storage", None)
    if storage is not None:
        for fn_name in ("reset", "clear"):
            fn = getattr(storage, fn_name, None)
            if callable(fn):
                fn()
                return
    # Fallback: recreate the limiter's storage (slowapi 0.1.9+)
    try:
        from limits.storage import MemoryStorage
        limiter._storage = MemoryStorage()
    except Exception:
        pass
