---
status: diagnosed
phase: 02-authentication
source: [02-VERIFICATION.md]
started: 2026-04-24T17:26:40Z
updated: 2026-04-24T19:35:00Z
---

## Current Test

[all tests executed]

## Tests

### 1. Full test suite execution

expected: Run `pytest -x -q` in backend/ — all 47 tests pass green as claimed in 02-04-SUMMARY.md
result: PASSED — 47/47 passed in 5.00s

### 2. Alembic migration round-trip

expected: With PostgreSQL running and Phase 1 migrations applied, migration 007a upgrades and downgrades cleanly (`alembic upgrade head && alembic downgrade -1 && alembic upgrade head`)
result: PASSED — upgrade/downgrade/upgrade all clean, no errors

### 3. Rate limiting live verification

expected: Sending >5 requests to `/auth/request-code` with the same email in 15 minutes returns 429 at the correct threshold. Same for >20 requests from same IP.
result: PASSED — 429 received on 6th request (5/email/15min limit working correctly)

### 4. D-08 enumeration timing verification

expected: Timing parity (within ~15%) between requests for existing vs non-existing emails when Resend is live (not mocked)
result: FAILED — 98% timing gap. Existing email: ~735ms (real Resend call); non-existing email: ~14ms (no synthetic delay). Code persists dummy row for DB timing parity but does not compensate for Resend network latency. Needs `asyncio.sleep()` in the non-existing path to match average Resend round-trip.

## Summary

total: 4
passed: 3
issues: 1
pending: 0
skipped: 0
blocked: 0

## Gaps

### 1. D-08 Enumeration timing gap

status: failed
severity: medium
description: The `otp_service.generate_and_send_code()` function equalizes DB operations (generate + hash + persist) for both existing and non-existing emails, but omits a synthetic delay in the non-existing email path to compensate for Resend API latency (~700ms). An attacker can distinguish existing from non-existing emails by measuring response times.
file: backend/src/features/auth/services/otp_service.py
lines: 80-91
fix: Add `asyncio.sleep(random.uniform(0.5, 1.0))` in the `else` branch (line 91) to simulate Resend latency for non-existing emails.
