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
