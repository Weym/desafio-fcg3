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
from sqlalchemy import event
from sqlalchemy.ext.asyncio import (
    AsyncSession as _AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

# Ensure backend root is on sys.path for imports
BACKEND_ROOT = Path(__file__).resolve().parent.parent
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from src.infrastructure.database import Base, get_db_session  # noqa: E402
from src.features.auth.models import (  # noqa: E402
    Student, Staff, VerificationCode, Session as SessionModel, FcmToken,
)

# Import ALL models so ORM mapper resolves relationships (Student -> Enrollment, etc.)
import src.features.courses.models  # noqa: F401,E402
import src.features.enrollment.models  # noqa: F401,E402
import src.features.students.models  # noqa: F401,E402
import src.features.documents.models  # noqa: F401,E402
import src.features.scheduling.models  # noqa: F401,E402
import src.features.chat.models  # noqa: F401,E402
import src.features.knowledge_base.models  # noqa: F401,E402

# Tables that SQLite can handle (excludes those using JSONB/Vector: mcp_action_logs, knowledge_base_chunks)
# chat_sessions and chat_messages use only standard column types (VARCHAR, Text, DateTime, UUID)
# and are safe for SQLite testing. mcp_action_logs has JSONB columns; knowledge_base_chunks has Vector.
_SQLITE_SAFE_TABLES = [
    t for t in Base.metadata.sorted_tables
    if t.name not in ("mcp_action_logs", "knowledge_base_chunks")
]

# ---- Test engine: use SQLite (aiosqlite) for isolation without PostgreSQL ----
_TEST_DATABASE_URL = "sqlite+aiosqlite://"

_test_engine = create_async_engine(
    _TEST_DATABASE_URL,
    echo=False,
    connect_args={"check_same_thread": False},
)

# Compile-time hook: strip FOR UPDATE clauses (unsupported in SQLite)
from sqlalchemy.ext.compiler import compiles  # noqa: E402

try:
    from sqlalchemy.sql.selectable import ForUpdateArg

    @compiles(ForUpdateArg, "sqlite")
    def _compile_for_update_sqlite(element, compiler, **kw):
        return ""
except ImportError:
    pass


_test_async_session = async_sessionmaker(
    _test_engine,
    class_=_AsyncSession,
    expire_on_commit=False,
)


@pytest_asyncio.fixture
async def db_session():
    """Async SQLAlchemy session with per-test table create/drop using SQLite.

    Uses a connection-level transaction with nested savepoints so that route
    handlers calling session.commit() only commit the savepoint — the outer
    connection transaction is rolled back at the end for full test isolation.
    """
    async with _test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all, tables=_SQLITE_SAFE_TABLES)

    async with _test_engine.connect() as conn:
        txn = await conn.begin()
        session = _AsyncSession(bind=conn, expire_on_commit=False)

        # Use SAVEPOINT so that session.commit() inside route handlers
        # commits the savepoint, not the outer connection transaction.
        nested = await conn.begin_nested()

        # After each commit (savepoint release), immediately open a new savepoint
        @event.listens_for(session.sync_session, "after_transaction_end")
        def _restart_savepoint(sync_session, transaction):
            if conn.closed:
                return
            if not conn.in_nested_transaction():
                conn.sync_connection.begin_nested()

        yield session

        await session.close()
        await txn.rollback()

    # Clean up tables after each test
    async with _test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all, tables=_SQLITE_SAFE_TABLES)


@pytest.fixture
def app():
    """Yields the FastAPI application instance."""
    from src.main import app as _app
    return _app


@pytest_asyncio.fixture
async def client(app, db_session):
    """httpx AsyncClient wired to the FastAPI ASGI app with DB override.

    Overrides get_db_session so route handlers share the test's transactional session.
    """
    async def _override_get_db():
        yield db_session

    app.dependency_overrides[get_db_session] = _override_get_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c
    app.dependency_overrides.pop(get_db_session, None)


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
    try:
        from src.shared.rate_limit import reset
        reset()
    except (ImportError, AttributeError):
        pass
    yield
    try:
        from src.shared.rate_limit import reset
        reset()
    except (ImportError, AttributeError):
        pass


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
