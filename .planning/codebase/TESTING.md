# Testing Patterns

**Analysis Date:** 2026-04-15

## Project State

No test files or test configuration exist yet. The backend source is in early
scaffolding (`backend/src/main.py` is empty). This document describes the
**prescriptive** testing approach to establish when writing tests, based on
the project's tech stack (Python 3.12, FastAPI, PostgreSQL, async codebase)
and the complexity areas identified in the design documentation.

## Test Framework

**Runner:**
- Use **pytest** — standard for Python/FastAPI projects
- Config file: `backend/pyproject.toml` or `backend/pytest.ini` (to be created)

**Async support:**
- Use **pytest-asyncio** for testing async FastAPI routes and async service
  functions

**HTTP test client:**
- Use FastAPI's built-in `TestClient` (sync) or `httpx.AsyncClient` for async
  integration tests

**Database:**
- Use a separate PostgreSQL test database (do not reuse the dev database)
- Transactions should be rolled back after each test to maintain isolation

**Run Commands:**
```bash
pytest                          # Run all tests
pytest -v                       # Verbose output
pytest --cov=src --cov-report=html  # Coverage report
pytest -k "test_auth"           # Run tests matching pattern
pytest -x                       # Stop at first failure
```

## Test File Organization

**Location:**
- Test files are co-located with the feature they test inside a `tests/`
  subdirectory per feature, OR in a top-level `backend/tests/` directory
- Recommended structure mirrors `src/`:

```
backend/
├── src/
│   ├── features/
│   │   ├── auth/
│   │   └── enrollment/
│   ├── infrastructure/
│   └── shared/
└── tests/
    ├── features/
    │   ├── auth/
    │   │   ├── test_request_code.py
    │   │   └── test_verify_code.py
    │   └── enrollment/
    │       ├── test_create_enrollment.py
    │       └── test_confirm_enrollment.py
    ├── conftest.py
    └── infrastructure/
```

**Naming:**
- Test files: `test_<module_or_feature>.py`
- Test functions: `test_<scenario>_<expected_outcome>`
- Examples: `test_verify_code_returns_jwt_on_valid_code`,
  `test_verify_code_returns_429_after_three_attempts`,
  `test_confirm_enrollment_returns_409_when_period_closed`

## Test Structure

**Suite Organization:**
```python
# Example: tests/features/auth/test_verify_code.py

import pytest
from httpx import AsyncClient
from fastapi import status

class TestVerifyCode:
    async def test_returns_jwt_on_valid_code(self, client: AsyncClient, db_session):
        # Arrange: create verification code in DB
        # Act: POST /auth/verify-code with valid code
        # Assert: response is 200 with token field

    async def test_returns_401_on_invalid_code(self, client: AsyncClient, db_session):
        # Arrange
        # Act
        # Assert: response is 401 with INVALID_CODE error code

    async def test_returns_429_after_max_attempts(self, client: AsyncClient, db_session):
        # Arrange: code with attempts=3
        # Act: POST /auth/verify-code
        # Assert: response is 429 with MAX_ATTEMPTS_REACHED and new code sent
```

**Patterns:**
- Use Arrange / Act / Assert structure explicitly (as comments if needed)
- Each test covers exactly one scenario
- Use descriptive test names that read as specifications

## Mocking

**Framework:** `unittest.mock` (stdlib) or `pytest-mock` (`mocker` fixture)

**What to mock:**
- External HTTP calls: WhatsApp Cloud API, Firebase FCM — never make real
  network calls in tests
- Email/SMS delivery (verification code sending)
- `asyncio.create_task` when testing that background tasks are dispatched
  without executing them
- `time.monotonic()` when testing latency logging

**What NOT to mock:**
- The PostgreSQL database — use a real test DB with transaction rollback
- FastAPI request/response cycle — use `TestClient` or `httpx.AsyncClient`
- Business logic under test

**Mocking external HTTP (pattern for WhatsApp and FCM calls):**
```python
from unittest.mock import AsyncMock, patch

async def test_webhook_responds_200_immediately(client: AsyncClient):
    with patch("src.features.chatbot.send_whatsapp_message", new_callable=AsyncMock) as mock_send:
        with patch("asyncio.create_task") as mock_task:
            response = await client.post("/api/v1/webhook/whatsapp", json=webhook_payload)
    assert response.status_code == 200
    mock_task.assert_called_once()
    mock_send.assert_not_called()  # should be called in background, not synchronously
```

**Mocking service token middleware:**
```python
# Override dependency for tests that don't need service token auth
app.dependency_overrides[verify_service_token] = lambda: None
```

## Fixtures and Factories

**Core fixtures in `tests/conftest.py`:**
```python
import pytest
import pytest_asyncio
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

@pytest_asyncio.fixture
async def client(app) -> AsyncClient:
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client

@pytest_asyncio.fixture
async def db_session() -> AsyncSession:
    # Begin transaction, yield session, rollback after test
    async with async_session_factory() as session:
        async with session.begin():
            yield session
            await session.rollback()

@pytest.fixture
def student_factory(db_session):
    async def _create(**kwargs):
        defaults = {
            "name": "Test Student",
            "email": "test@universidade.edu",
            "registration_number": "2024001",
            "semester": 1,
            "status": "active",
        }
        return await StudentRepository.create(db_session, {**defaults, **kwargs})
    return _create
```

**Test data location:**
- Fixtures and factories in `tests/conftest.py` (shared) and
  `tests/features/<feature>/conftest.py` (feature-scoped)

## Critical Test Scenarios

Based on the design documentation, the following scenarios are highest
priority to test:

**Auth — `tests/features/auth/`:**
- `POST /auth/verify-code` returns JWT on valid code
- `POST /auth/verify-code` returns `401` with `INVALID_CODE` on wrong code
- `POST /auth/verify-code` returns `429` with `MAX_ATTEMPTS_REACHED` after 3 failures
- `POST /auth/verify-code` auto-sends new code when attempts exhausted
- Verification code expires after 5 minutes

**Enrollment — `tests/features/enrollment/`:**
- `POST /enrollments` creates enrollment with `status=draft`
- `POST /enrollments/{id}/confirm` transitions draft to confirmed
- `POST /enrollments/{id}/confirm` returns `409` when enrollment period is closed
- `POST /enrollments/{id}/confirm` returns `409` when already confirmed
- `POST /enrollments/{id}/lock` locks enrollment
- Prerequisites are enforced before creating enrollment

**Webhook — `tests/features/chatbot/`:**
- `POST /webhook/whatsapp` returns `200 OK` immediately (does not wait for AI)
- `asyncio.create_task` is called once per text message
- Media messages receive standard response without passing through agent
- X-Hub-Signature-256 validation rejects unsigned requests

**MCP middleware — `tests/features/mcp/`:**
- 5xx errors trigger exactly one retry
- 4xx errors do not trigger retry
- Every tool call generates a log entry in `mcp_action_logs`
- `student_id` never appears in logged `input_params`
- `X-Service-Token` absent returns `401`

## Test Types

**Unit Tests:**
- Scope: individual service functions, validators, domain logic
- No database, no HTTP — pure Python functions
- Examples: prerequisite checking logic, grade calculation, status transition
  validation

**Integration Tests:**
- Scope: HTTP endpoints tested against a real test database
- Use `httpx.AsyncClient` with FastAPI app
- Each test rolls back its transaction after completion
- Cover the full request → service → DB → response path

**E2E Tests:**
- Not used in MVP — the system involves external services (WhatsApp, FCM, LLM)
  that make true E2E testing impractical without heavy mocking

## Coverage

**Requirements:** No formal coverage threshold defined yet — aim for full
coverage of business-critical paths listed in "Critical Test Scenarios" above.

**View Coverage:**
```bash
pytest --cov=src --cov-report=html
# Open htmlcov/index.html
```

## Async Testing

**Pattern:**
```python
import pytest

@pytest.mark.asyncio
async def test_async_endpoint(client: AsyncClient):
    response = await client.post("/api/v1/auth/request-code", json={"email": "test@uni.edu", "channel": "email"})
    assert response.status_code == 200
```

## Error Testing

**Pattern:**
```python
async def test_confirm_enrollment_fails_when_period_closed(client: AsyncClient, db_session, student_factory):
    student = await student_factory()
    enrollment = await create_draft_enrollment(db_session, student.id)
    await close_enrollment_period(db_session)

    response = await client.post(
        f"/api/v1/enrollments/{enrollment.id}/confirm",
        headers={"Authorization": f"Bearer {generate_jwt(student.id)}"},
    )

    assert response.status_code == 409
    assert response.json()["error"]["code"] == "ENROLLMENT_PERIOD_CLOSED"
```

## Background Task Testing

The webhook endpoint dispatches AI processing via `asyncio.create_task`. Tests
should verify:
1. The response is `200 OK` without waiting for the task
2. The task was dispatched (mock `asyncio.create_task` and assert it was called)
3. The task logic itself is tested separately in a unit test

```python
async def test_webhook_dispatches_background_task(client: AsyncClient):
    with patch("asyncio.create_task") as mock_task:
        response = await client.post(
            "/api/v1/webhook/whatsapp",
            json=valid_text_webhook_payload,
            headers={"X-Hub-Signature-256": compute_valid_signature(valid_text_webhook_payload)},
        )
    assert response.status_code == 200
    mock_task.assert_called_once()
```

---

*Testing analysis: 2026-04-15*
