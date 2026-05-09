"""Unit tests for the document upload endpoint (DOCS-05).

Tests:
- Rejects invalid file extensions (INVALID_FILE_TYPE)
- Rejects oversized files (FILE_TOO_LARGE)
- Accepts valid PDF/PNG/JPG files and returns URL
- Returned URL contains the original filename with UUID prefix
"""

from __future__ import annotations

import io
import os
import shutil
import uuid
from unittest.mock import patch, MagicMock

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient

# These tests validate the upload_document function behavior by calling
# the actual endpoint through the ASGI app.


@pytest.fixture(autouse=True)
def clean_uploads():
    """Ensure uploads directory is clean before/after each test."""
    upload_dir = "uploads/documents"
    if os.path.exists(upload_dir):
        shutil.rmtree(upload_dir)
    yield
    if os.path.exists(upload_dir):
        shutil.rmtree(upload_dir)


@pytest_asyncio.fixture
async def staff_client(app, db_session, seed_users):
    """httpx AsyncClient authenticated as staff user."""
    from src.infrastructure.database import get_db_session
    from src.shared.dependencies import get_current_user_or_service, UserContext

    staff = seed_users["staff"]

    async def _override_get_db():
        yield db_session

    def _override_auth():
        return UserContext(id=staff.id, role="staff", name="Test Staff")

    app.dependency_overrides[get_db_session] = _override_get_db
    app.dependency_overrides[get_current_user_or_service] = _override_auth

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c

    app.dependency_overrides.pop(get_db_session, None)
    app.dependency_overrides.pop(get_current_user_or_service, None)


class TestUploadEndpointValidation:
    """Tests for file type and size validation."""

    @pytest.mark.asyncio
    async def test_rejects_invalid_file_extension(self, staff_client):
        """Upload endpoint rejects .exe files with INVALID_FILE_TYPE error."""
        content = b"fake executable content"
        files = {"file": ("malware.exe", io.BytesIO(content), "application/octet-stream")}

        response = await staff_client.post("/api/v1/documents/upload", files=files)

        assert response.status_code == 400
        detail = response.json()["detail"]
        assert detail["error"]["code"] == "INVALID_FILE_TYPE"

    @pytest.mark.asyncio
    async def test_rejects_txt_file(self, staff_client):
        """Upload endpoint rejects .txt files."""
        content = b"some text content"
        files = {"file": ("notes.txt", io.BytesIO(content), "text/plain")}

        response = await staff_client.post("/api/v1/documents/upload", files=files)

        assert response.status_code == 400
        detail = response.json()["detail"]
        assert detail["error"]["code"] == "INVALID_FILE_TYPE"

    @pytest.mark.asyncio
    async def test_rejects_oversized_file(self, staff_client):
        """Upload endpoint rejects files larger than 10MB."""
        # Create a file just over 10MB
        content = b"x" * (10 * 1024 * 1024 + 1)
        files = {"file": ("large.pdf", io.BytesIO(content), "application/pdf")}

        response = await staff_client.post("/api/v1/documents/upload", files=files)

        assert response.status_code == 400
        detail = response.json()["detail"]
        assert detail["error"]["code"] == "FILE_TOO_LARGE"


class TestUploadEndpointSuccess:
    """Tests for successful file uploads."""

    @pytest.mark.asyncio
    async def test_accepts_pdf_file_and_returns_url(self, staff_client):
        """Upload endpoint accepts a PDF file and returns URL with filename."""
        content = b"%PDF-1.4 fake pdf content"
        files = {"file": ("document.pdf", io.BytesIO(content), "application/pdf")}

        response = await staff_client.post("/api/v1/documents/upload", files=files)

        assert response.status_code == 200
        data = response.json()
        assert "url" in data
        assert data["url"].startswith("/uploads/documents/")
        assert "document.pdf" in data["url"]
        assert data["filename"] == "document.pdf"

    @pytest.mark.asyncio
    async def test_accepts_png_file(self, staff_client):
        """Upload endpoint accepts a PNG file."""
        content = b"\x89PNG\r\n\x1a\n fake png"
        files = {"file": ("image.png", io.BytesIO(content), "image/png")}

        response = await staff_client.post("/api/v1/documents/upload", files=files)

        assert response.status_code == 200
        data = response.json()
        assert "image.png" in data["url"]

    @pytest.mark.asyncio
    async def test_accepts_jpg_file(self, staff_client):
        """Upload endpoint accepts a JPG file."""
        content = b"\xff\xd8\xff fake jpg"
        files = {"file": ("photo.jpg", io.BytesIO(content), "image/jpeg")}

        response = await staff_client.post("/api/v1/documents/upload", files=files)

        assert response.status_code == 200
        data = response.json()
        assert "photo.jpg" in data["url"]

    @pytest.mark.asyncio
    async def test_accepts_jpeg_extension(self, staff_client):
        """Upload endpoint accepts .jpeg extension."""
        content = b"\xff\xd8\xff fake jpeg"
        files = {"file": ("photo.jpeg", io.BytesIO(content), "image/jpeg")}

        response = await staff_client.post("/api/v1/documents/upload", files=files)

        assert response.status_code == 200
        data = response.json()
        assert "photo.jpeg" in data["url"]

    @pytest.mark.asyncio
    async def test_saved_file_exists_on_disk(self, staff_client):
        """Upload saves the file to the uploads directory."""
        content = b"test file content for disk check"
        files = {"file": ("test.pdf", io.BytesIO(content), "application/pdf")}

        response = await staff_client.post("/api/v1/documents/upload", files=files)

        assert response.status_code == 200
        url = response.json()["url"]
        # URL is like /uploads/documents/{uuid}_test.pdf
        filename = url.split("/")[-1]
        filepath = os.path.join("uploads/documents", filename)
        assert os.path.exists(filepath)

        with open(filepath, "rb") as f:
            assert f.read() == content

    @pytest.mark.asyncio
    async def test_url_contains_uuid_prefix(self, staff_client):
        """Upload URL has a UUID prefix for path traversal prevention."""
        content = b"uuid prefix test"
        files = {"file": ("report.pdf", io.BytesIO(content), "application/pdf")}

        response = await staff_client.post("/api/v1/documents/upload", files=files)

        assert response.status_code == 200
        url = response.json()["url"]
        filename = url.split("/")[-1]
        # Should be {uuid}_report.pdf — uuid is 36 chars + underscore
        parts = filename.split("_", 1)
        assert len(parts) == 2
        # Validate UUID format
        try:
            uuid.UUID(parts[0])
        except ValueError:
            pytest.fail(f"Expected UUID prefix but got: {parts[0]}")
        assert parts[1] == "report.pdf"


class TestUploadEndpointAuth:
    """Tests for authentication enforcement on upload."""

    @pytest.mark.asyncio
    async def test_rejects_student_role(self, app, db_session, seed_users):
        """Upload endpoint requires staff role — students are rejected."""
        from src.infrastructure.database import get_db_session
        from src.shared.dependencies import get_current_user_or_service, UserContext

        student = seed_users["student"]

        async def _override_get_db():
            yield db_session

        def _override_auth():
            return UserContext(id=student.id, role="student", name="Test Student")

        app.dependency_overrides[get_db_session] = _override_get_db
        app.dependency_overrides[get_current_user_or_service] = _override_auth

        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            content = b"test"
            files = {"file": ("test.pdf", io.BytesIO(content), "application/pdf")}
            response = await client.post("/api/v1/documents/upload", files=files)

        app.dependency_overrides.pop(get_db_session, None)
        app.dependency_overrides.pop(get_current_user_or_service, None)

        assert response.status_code == 403
