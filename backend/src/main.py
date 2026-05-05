import os
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

import resend
from fastapi import FastAPI, Request
from fastapi.exceptions import HTTPException, RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from slowapi.errors import RateLimitExceeded

from src.shared.rate_limit import limiter, rate_limit_exceeded_handler
from src.shared.exceptions import register_exception_handlers
from src.features.auth.deps import BodyCacheMiddleware
from src.features.auth.routes import router as auth_router
from src.features.students.routes import router as students_router
from src.features.courses.routes import courses_router, curriculum_router
from src.features.enrollment.routes import (
    enrollment_periods_router,
    enrollments_router,
    staff_enrollment_router,
)
from src.features.documents.routes import documents_router
from src.features.appointments.routes import scheduling_router, appointments_router
from src.features.grades.routes import grades_router
from src.features.staff.routes import staff_router
from src.features.webhook.router import router as webhook_router
from src.features.chat.router import router as chat_router


@asynccontextmanager
async def lifespan(_app: FastAPI) -> AsyncIterator[None]:
    """Application lifespan: configure third-party services at startup."""
    # Allow the API to start with placeholder env values during infrastructure setup.
    resend_api_key = os.getenv("RESEND_API_KEY", "")
    if resend_api_key.startswith("re_"):
        resend.api_key = resend_api_key
    yield


app = FastAPI(title="Desafio FCG3 - API", version="0.1.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Exception handlers — AppException (business logic) before slowapi/HTTP handlers
register_exception_handlers(app)

# Middleware — body cache for slowapi key_func (must be added before slowapi)
app.add_middleware(BodyCacheMiddleware)

# Rate limiting — slowapi
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, rate_limit_exceeded_handler)


@app.exception_handler(HTTPException)
async def normalize_http_exception(request: Request, exc: HTTPException) -> JSONResponse:
    """Normalize HTTPException detail to the canonical error shape.

    Routes use JSONResponse with {"error": {...}} directly, but FastAPI
    dependencies (get_current_user, require_role, require_service_token) must
    raise HTTPException — which wraps the body under "detail". This handler
    unwraps it so ALL error responses share the canonical shape:
    {"error": {"code": ..., "message": ...}}
    """
    body = exc.detail
    # If detail is already our canonical shape, use it directly
    if isinstance(body, dict) and "error" in body:
        return JSONResponse(status_code=exc.status_code, content=body)
    # Otherwise wrap it
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": {"code": "error", "message": str(body)}},
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    """WR-04: Normalize Pydantic/FastAPI validation errors to canonical shape.

    Without this handler, malformed request bodies produce FastAPI's default
    {"detail": [...]} shape instead of our canonical {"error": {...}}.
    """
    return JSONResponse(
        status_code=422,
        content={
            "error": {
                "code": "VALIDATION_ERROR",
                "message": "Request validation failed",
                "details": exc.errors(),
            }
        },
    )

# Routers
app.include_router(auth_router, prefix="/api/v1")
app.include_router(students_router, prefix="/api/v1")
app.include_router(courses_router, prefix="/api/v1")
app.include_router(curriculum_router, prefix="/api/v1")
app.include_router(enrollment_periods_router, prefix="/api/v1")
app.include_router(enrollments_router, prefix="/api/v1")
app.include_router(staff_enrollment_router, prefix="/api/v1")
app.include_router(documents_router, prefix="/api/v1")
app.include_router(scheduling_router, prefix="/api/v1")
app.include_router(appointments_router, prefix="/api/v1")
app.include_router(grades_router, prefix="/api/v1")
app.include_router(staff_router, prefix="/api/v1")
app.include_router(webhook_router, prefix="/api/v1")
app.include_router(chat_router, prefix="/api/v1")


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok"}


# Static file serving for uploads (MVP — production should use nginx/CDN)
os.makedirs("uploads/documents", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")
