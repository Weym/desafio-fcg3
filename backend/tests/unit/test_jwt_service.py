import pytest
import time
from uuid import uuid4

from jose import jwt, JWTError

from src.features.auth.services import jwt_service
from src.infrastructure.config import get_settings


def test_access_payload_contains_required_claims():
    settings = get_settings()
    uid = uuid4()
    tok = jwt_service.issue_access(uid, "student", "Ana", "ana@test.edu")
    claims = jwt.decode(tok.token, settings.jwt_secret, algorithms=["HS256"])
    assert claims["sub"] == str(uid)
    assert claims["role"] == "student"
    assert claims["name"] == "Ana"
    assert claims["email"] == "ana@test.edu"
    assert claims["jti"] == str(tok.jti)
    assert claims["exp"] > claims["iat"]
    assert claims["exp"] - claims["iat"] == settings.jwt_access_expiry_seconds


def test_refresh_payload_has_typ_refresh():
    settings = get_settings()
    tok = jwt_service.issue_refresh(uuid4(), "staff")
    claims = jwt.decode(tok.token, settings.jwt_secret, algorithms=["HS256"])
    assert claims["typ"] == "refresh"
    assert claims["exp"] - claims["iat"] == settings.jwt_refresh_expiry_seconds


def test_decode_rejects_tampered_signature():
    tok = jwt_service.issue_access(uuid4(), "student", "X", "x@y.z")
    tampered = tok.token[:-5] + "xxxxx"
    with pytest.raises(JWTError):
        jwt_service.decode(tampered)


def test_issue_token_pair_returns_distinct_jtis():
    pair = jwt_service.issue_token_pair(uuid4(), "student", "Ana", "ana@test.edu")
    assert pair.access.jti != pair.refresh.jti


def test_decode_returns_valid_claims():
    uid = uuid4()
    tok = jwt_service.issue_access(uid, "student", "Test", "test@test.edu")
    claims = jwt_service.decode(tok.token)
    assert claims["sub"] == str(uid)
    assert claims["role"] == "student"
