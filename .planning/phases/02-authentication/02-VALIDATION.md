---
phase: 2
slug: authentication
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-23
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | pytest 8.x + pytest-asyncio + httpx AsyncClient |
| **Config file** | `backend/pyproject.toml` (`[tool.pytest.ini_options]`) — created by Wave 0 if absent |
| **Quick run command** | `cd backend && pytest tests/unit -x -q` |
| **Full suite command** | `cd backend && pytest -x -q` |
| **Estimated runtime** | unit ~5s · full suite ~25s (mocks Resend + slowapi in-memory) |

---

## Sampling Rate

- **After every task commit:** Run `cd backend && pytest tests/unit -x -q` (if unit tests exist) OR the task-scoped integration test
- **After every plan wave:** Run `cd backend && pytest -x -q`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 2-01-01 | 01 | 1 | AUTH-01,AUTH-03 | T-02-02 / T-02-03 | Alembic 003 adds `code_hash`, `code_salt`, `token_type`, `parent_jti` columns | migration | `cd backend && alembic upgrade head && alembic downgrade -1 && alembic upgrade head` | ✅ | ⬜ pending |
| 2-01-02 | 01 | 1 | — | — | Settings + env.example include all 10 auth vars | unit | `cd backend && pytest tests/unit/test_settings.py -x` | ❌ W0 | ⬜ pending |
| 2-01-03 | 01 | 1 | AUTH-01 | T-02-01 | OTP generated, hashed, stored, sent via Resend (mocked); plaintext never persisted | unit | `cd backend && pytest tests/unit/test_otp_service.py -x` | ❌ W0 | ⬜ pending |
| 2-02-01 | 02 | 2 | AUTH-01 | T-02-04 / T-02-05 | `POST /auth/request-code` — 200 for any email (D-08), rate limits 5/email and 20/IP | integration | `cd backend && pytest tests/integration/test_auth_request_code.py tests/integration/test_auth_rate_limits.py tests/integration/test_auth_enumeration.py -x` | ❌ W0 | ⬜ pending |
| 2-02-02 | 02 | 2 | AUTH-02,AUTH-03 | T-02-01 / T-02-06 | `POST /auth/verify-code` — JWT with role/jti/exp issued; wrong code 3× triggers invalidate+auto-resend; expired doesn't count | integration | `cd backend && pytest tests/integration/test_auth_otp_flow.py -x` | ❌ W0 | ⬜ pending |
| 2-03-01 | 03 | 2 | AUTH-02 | T-02-06 / T-02-07 | `get_current_user` validates sig, checks `jti` against sessions, returns 401 on revoked | unit+integration | `cd backend && pytest tests/unit/test_jwt_service.py tests/integration/test_auth_me.py -x` | ❌ W0 | ⬜ pending |
| 2-03-02 | 03 | 2 | — | T-02-08 | `require_role("staff")` 403s students; `require_service_token` uses `hmac.compare_digest` | integration | `cd backend && pytest tests/integration/test_role_guard.py tests/integration/test_service_token.py -x` | ❌ W0 | ⬜ pending |
| 2-04-01 | 04 | 3 | AUTH-04,AUTH-05 | T-02-06 | `/auth/logout` revokes current jti only; `/auth/me` returns profile from JWT | integration | `cd backend && pytest tests/integration/test_auth_logout.py tests/integration/test_auth_me.py -x` | ❌ W0 | ⬜ pending |
| 2-04-02 | 04 | 3 | AUTH-02 | T-02-09 | `/auth/refresh` rotates refresh token; replay of old refresh returns 401 | integration | `cd backend && pytest tests/integration/test_auth_refresh_rotation.py -x` | ❌ W0 | ⬜ pending |
| 2-04-03 | 04 | 3 | AUTH-01..05 | all | Full phase suite green (TEST-01 coverage scaffold for Phase 6) | integration | `cd backend && pytest tests/integration -x -q` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Must be created as the first task of Plan 01 before any auth logic is written:

- [ ] `backend/pyproject.toml` — pytest config with asyncio mode, testpaths=["tests"]
- [ ] `backend/tests/conftest.py` — shared fixtures: test DB (transaction rollback per test), `app` fixture with TestClient/AsyncClient, `mock_resend` (monkeypatch `resend.Emails.send_async`), `reset_limiter` (clears slowapi in-memory storage between tests), seed users (one student, one staff)
- [ ] `backend/tests/unit/__init__.py` + stub files for `test_settings.py`, `test_otp_service.py`, `test_jwt_service.py` (skeletons with TODO markers)
- [ ] `backend/tests/integration/__init__.py` + stub files for each `test_auth_*.py` referenced above
- [ ] `backend/requirements-dev.txt` (or `[tool.poetry.group.dev.dependencies]`) — `pytest>=8`, `pytest-asyncio>=0.23`, `httpx>=0.27`, `pytest-cov`, `freezegun`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Actual Resend email delivery (not mock) | AUTH-01 | Third-party delivery cannot be asserted in CI | Deploy locally, set real `RESEND_API_KEY`, `POST /auth/request-code` with a real inbox, confirm email arrives within 30s with 6-digit code visible |
| Email template rendering | AUTH-01 | Visual review of HTML body | Same as above — open email in Gmail/Outlook, confirm code is legible and no broken markup |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (pytest config, conftest, stub files)
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-23 (by planner; awaits execution confirmation)
