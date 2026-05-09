---
phase: 20-langchain-workflow
plan: 07
subsystem: webhook
tags: [bugfix, otp, farewell, session-management, unicode]
dependency_graph:
  requires: [20-04, 20-06]
  provides: [stale-otp-reset, accent-normalized-farewell]
  affects: [webhook-service, webhook-background]
tech_stack:
  added: []
  patterns: [timedelta-based-ttl-check, unicodedata-nfkd-normalization]
key_files:
  created: []
  modified:
    - backend/src/features/webhook/service.py
    - backend/src/features/webhook/background.py
decisions:
  - "Use server-side updated_at timestamp for OTP TTL check (not client-controlled) — T-20-07-01 mitigation"
  - "Strip accents at comparison time rather than duplicating FAREWELL_INDICATORS with accented variants"
metrics:
  duration: 65s
  completed: "2026-05-09T20:09:45Z"
  tasks: 2
  files: 2
---

# Phase 20 Plan 07: UAT Gap Closure (Stale OTP + Farewell Accents) Summary

**One-liner:** Fix stale OTP verification_state trapping students and accent-mismatched farewell detection using timedelta TTL check and unicodedata NFKD normalization.

## What Was Built

### Task 1: Stale OTP verification_state reset
- Added `timedelta` import to existing `datetime` imports in `service.py`
- In `get_or_create_session`, when reusing an existing session with `verification_state` in `('awaiting_email', 'awaiting_code')`, check if `updated_at` is older than 5 minutes (OTP TTL)
- If stale, reset `verification_state` to `'unverified'` so student can proceed with read-only queries
- Preserves the `(session, is_new)` return contract

### Task 2: Accent-normalized farewell detection
- Added `import unicodedata` at module level in `background.py`
- Created `_strip_accents()` helper using NFKD normalization + combining character removal
- Updated `_is_farewell_response()` to normalize response text before matching against unaccented `FAREWELL_INDICATORS`
- LLM output like "Até mais! Foi um prazer..." now correctly matches indicators

## Commits

| Task | Commit | Message |
| --- | --- | --- |
| 1 | a528a38 | fix(20-07): reset stale OTP verification_state in get_or_create_session |
| 2 | 3f3f776 | fix(20-07): add accent normalization to farewell detection |

## Deviations from Plan

None — plan executed exactly as written.

## Verification Results

- **Task 1:** AST parse valid, `timedelta` import present, stale OTP reset logic confirmed
- **Task 2:** All 5 farewell detection tests passed (accented, unaccented, non-farewell, single indicator, two accented indicators)

## Self-Check: PASSED

- [x] `backend/src/features/webhook/service.py` — FOUND, contains stale OTP reset
- [x] `backend/src/features/webhook/background.py` — FOUND, contains `_strip_accents` + `unicodedata`
- [x] Commit a528a38 — FOUND
- [x] Commit 3f3f776 — FOUND
