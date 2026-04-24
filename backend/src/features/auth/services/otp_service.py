"""OTP generation, SHA-256 hashing, persistence, and Resend dispatch.

Security invariants:
- Plaintext code is NEVER logged or persisted — only the hash + salt.
- Uses secrets.randbelow (CSPRNG), not random.randint.
- D-08: always runs full path (generate + hash + persist) for timing parity,
  regardless of whether the email is registered.
"""

import hashlib
import hmac
import logging
import secrets
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

import resend
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from src.features.auth.models import Staff, Student, VerificationCode
from src.infrastructure.config import get_settings

log = logging.getLogger(__name__)


@dataclass
class GeneratedCode:
    """Returned to caller only for testing — plaintext code is never persisted or logged."""

    plaintext: str
    expires_at: datetime


def _hash_code(plaintext: str, salt: str) -> str:
    """SHA-256 hash of plaintext + per-row salt."""
    return hashlib.sha256((plaintext + salt).encode("utf-8")).hexdigest()


def _generate_code() -> str:
    """6 digits, cryptographically secure (secrets.randbelow, not random)."""
    return f"{secrets.randbelow(10**6):06d}"


async def user_exists(session: AsyncSession, email: str) -> bool:
    """D-07: email must already be in students or staff. D-09 role determined by hit table."""
    q_student = await session.execute(select(Student.id).where(Student.email == email))
    if q_student.scalar_one_or_none() is not None:
        return True
    q_staff = await session.execute(select(Staff.id).where(Staff.email == email))
    return q_staff.scalar_one_or_none() is not None


async def generate_and_send_code(session: AsyncSession, email: str) -> GeneratedCode:
    """Generate OTP, hash it, persist only the hash, send via Resend if user exists.

    D-08 security: ALWAYS runs the full path (generate + hash + persist) for timing
    parity. Only sends the email if the user exists (checked via user_exists).
    Plaintext is never logged.
    """
    settings = get_settings()

    plaintext = _generate_code()
    salt = secrets.token_hex(16)  # 32-char hex string
    code_hash = _hash_code(plaintext, salt)
    expires_at = datetime.now(timezone.utc) + timedelta(seconds=settings.otp_expiry_seconds)

    row = VerificationCode(
        email=email,
        code_hash=code_hash,
        code_salt=salt,
        channel="email",
        expires_at=expires_at,
        attempts=0,
        used=False,
    )
    session.add(row)
    await session.flush()

    if await user_exists(session, email):
        params: resend.Emails.SendParams = {
            "from": settings.resend_from,
            "to": [email],
            "subject": "Seu codigo de verificacao",
            "html": (
                f"<p>Seu codigo e <strong>{plaintext}</strong>. "
                f"Valido por {settings.otp_expiry_seconds // 60} minutos.</p>"
            ),
        }
        await resend.Emails.send_async(params)
    # else: P-04 — silent drop, still persisted a dummy row to equalize timing

    return GeneratedCode(plaintext=plaintext, expires_at=expires_at)


def verify_code_hash(submitted: str, stored_hash: str, stored_salt: str) -> bool:
    """Compare submitted code against stored hash using the same salt (constant-time)."""
    computed = _hash_code(submitted, stored_salt)
    return hmac.compare_digest(computed, stored_hash)
