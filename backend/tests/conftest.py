# --- env preload (MUST precede any backend.* import) ---
# backend/src/infrastructure/config.py declares Settings with required fields
# that Pydantic Settings instantiates at import time. Without preloading,
# `pytest --collect-only` fails with ValidationError.
import os

os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://test:test@localhost:5432/test_desafio_fcg3")
os.environ.setdefault("JWT_SECRET", "x" * 64)
os.environ.setdefault("RESEND_API_KEY", "re_test_key")
os.environ.setdefault("RESEND_FROM", "Test <no-reply@test.invalid>")
os.environ.setdefault("MCP_SERVICE_TOKEN", "y" * 64)
os.environ.setdefault("WHATSAPP_TOKEN", "placeholder-whatsapp-token")
os.environ.setdefault("WHATSAPP_PHONE_NUMBER_ID", "123456")
os.environ.setdefault("WHATSAPP_WEBHOOK_VERIFY_TOKEN", "verify-token")
# ---------------------------------------------------------

import sys
import uuid
from datetime import datetime, timezone
from pathlib import Path
from unittest.mock import AsyncMock

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient

# Ensure backend root is on sys.path for imports
BACKEND_ROOT = Path(__file__).resolve().parent.parent
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from src.infrastructure.database import Base, async_session, engine  # noqa: E402
from src.features.auth.models import Student, Staff  # noqa: E402


@pytest_asyncio.fixture
async def db_session():
    """Async SQLAlchemy session with per-test transaction rollback."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with async_session() as session:
        async with session.begin():
            yield session
            await session.rollback()


@pytest.fixture
def app():
    """Yields the FastAPI application instance."""
    from src.main import app as _app
    return _app


@pytest_asyncio.fixture
async def client(app):
    """httpx AsyncClient wired to the FastAPI ASGI app."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c


@pytest.fixture
def mock_resend(monkeypatch, request):
    """Monkeypatches resend.Emails.send_async to an AsyncMock.

    Captured call args are available at request.config.mock_resend_calls.
    """
    calls: list[dict] = []
    request.config.mock_resend_calls = calls

    async_mock = AsyncMock(return_value={"id": "mock-email-id"})

    def capture_side_effect(params):
        calls.append(params)
        return async_mock.return_value

    async_mock.side_effect = capture_side_effect

    import resend
    monkeypatch.setattr(resend.Emails, "send_async", async_mock)
    return async_mock


@pytest.fixture
def reset_limiter():
    """Clears slowapi in-memory storage between tests."""
    yield
    try:
        from src.shared.rate_limit import limiter
        limiter.reset()
    except (ImportError, AttributeError):
        pass  # rate_limit module not yet created in Wave 1


@pytest_asyncio.fixture
async def seed_users(db_session):
    """Inserts one student and one staff row for test use."""
    student = Student(
        id=uuid.uuid4(),
        name="Test Student",
        email="student@test.edu",
        phone="+5511999990001",
        registration_number="STU001",
        semester=3,
        status="active",
        enrollment_year=2024,
    )
    staff = Staff(
        id=uuid.uuid4(),
        name="Test Staff",
        email="staff@test.edu",
        phone="+5511999990002",
        role="staff",
    )
    db_session.add(student)
    db_session.add(staff)
    await db_session.flush()
    return {"student": student, "staff": staff}
