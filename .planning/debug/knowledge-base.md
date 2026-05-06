# GSD Debug Knowledge Base

Resolved debug sessions. Used by `gsd-debugger` to surface known-pattern hypotheses at the start of new investigations.

---

## whatsapp-otp-loop-no-cancel — OTP verification flow had no exit path and max-attempts was non-terminal

- **Date:** 2026-05-06
- **Error patterns:** whatsapp, otp, webhook, verification_state, awaiting_code, awaiting_email, loop, cancelar, sair, encerrar, MAX_ATTEMPTS_REACHED, SESSION_CLOSE_KEYWORDS, state machine, verify_code_hash, otp_max_attempts
- **Root cause:** Two defects in the hardcoded verification state machine in `backend/src/features/webhook/` (the LangChain agent is gated behind `verification_state == "verified"` at `router.py:167` and never sees pre-verification traffic): (1) only `{"sair", "encerrar"}` were recognized as cancel keywords and the OTP prompts never mentioned them; (2) the `attempts >= otp_max_attempts` branch silently reissued a fresh OTP and kept the session in `awaiting_code`, making `MAX_ATTEMPTS_REACHED` non-terminal in violation of the 429 convention.
- **Fix:** Expanded `SESSION_CLOSE_KEYWORDS` to include "cancelar", "cancel", "parar", "stop"; advertised cancellation in OTP prompts; made max-attempts a terminal state (close session + do NOT auto-reissue OTP); replaced inline literal in `router.py` with the shared constant.
- **Files changed:** backend/src/features/webhook/service.py, backend/src/features/webhook/router.py, backend/tests/features/webhook/test_verification_state.py, backend/tests/features/webhook/test_session_lifecycle.py

---

## chat-session-never-closes — pg_cron auto-close job installed with doubled quotes inside `$$...$$`, failing silently every hour

- **Date:** 2026-05-06
- **Error patterns:** chat_sessions, chat-session, status='active', closed, ended_at, updated_at, pg_cron, cron.schedule, cron.job, cron.job_run_details, close-inactive-chat-sessions, alembic, migration, 011a, 012a, dollar-quoting, $$...$$, '' escape, syntax error at or near "closed", auto-close, inactivity, session never ends, D-12
- **Root cause:** Alembic migration `011_add_pg_cron_session_autoclose.py` built the scheduled UPDATE with `sa.text("SELECT cron.schedule(..., $$UPDATE chat_sessions SET status = ''closed'', ended_at = NOW() WHERE updated_at < NOW() - INTERVAL ''24 hours'' AND status = ''active''$$)")` — mixing `$$...$$` dollar-quoting (which makes the body literal, single quotes included) with `''` SQL-escape (which doubles single quotes). The stored `cron.job.command` ended up containing literal `status = ''closed''`, which Postgres parses as two empty strings around a bare identifier → `ERROR: syntax error at or near "closed"` at every hourly tick. Job fired but UPDATE never ran, so `chat_sessions` never transitioned `active → closed`. The migration's `SAVEPOINT` graceful-skip pattern masked nothing here — pg_cron WAS installed; the command string itself was invalid and that only surfaced at runtime.
- **Fix:** (1) Corrected quoting in source migration 011 so fresh environments don't reintroduce the bug. (2) Added corrective migration 012 (revision `012a`) that unschedules the broken job via SAVEPOINT and reschedules with correct single quotes using a shared `_SCHEDULE_SQL` constant; mirrors 011's SAVEPOINT-on-missing-pg_cron pattern. (3) Added AST-based regression tests that parse migrations 011/012, extract arguments to `sa.text(...)` (resolving module-level string constants), and assert no `''closed''`/`''active''`/`''24 hours''` appears inside `upgrade()` while the single-quoted forms do — so a future "style fix" cannot silently re-break it.
- **Lesson:** When the SQL you're generating will itself be stored as a literal (pg_cron `cron.job.command`, event trigger bodies, stored procedure text, etc.), pick exactly ONE quoting mechanism — never combine `$$...$$` with `''`-escaping. Always inspect the stored form (`SELECT command FROM cron.job`) after scheduling, not just the migration source, because the syntax error manifests only at scheduled runtime and can silently corrupt scheduled behavior for days before anyone notices.
- **Files changed:** backend/alembic/versions/011_add_pg_cron_session_autoclose.py, backend/alembic/versions/012_fix_pg_cron_session_autoclose_quoting.py, backend/tests/unit/test_pg_cron_session_autoclose_quoting.py

---
