# Project Research Summary — v3.0

**Project:** Desafio FCG3 — Plataforma Academica com Chatbot WhatsApp
**Domain:** Multi-service academic platform (FastAPI + LangChain + MCP + Flutter + PostgreSQL/PGVector)
**Researched:** 2026-05-08
**Milestone:** v3.0 — FCM Push, LangChain Completion, Prompt Injection Defense, Provider Role, Flutter Features
**Confidence:** HIGH

---

## Executive Summary

Milestone v3.0 adds real-time push notifications (FCM), completes the LangChain agent workflow (session lifecycle management), hardens the AI service against prompt injection, expands the role system to include `provider`, and delivers three new Flutter screens (cardápio, perfil, grade curricular calendar). Unlike v1.0 which built the entire foundation from scratch, v3.0 operates on an established codebase — the critical path is integration correctness, not greenfield construction. The primary risk is cross-cutting: FCM notifications must fire from multiple event sources (document ready, enrollment confirmed, appointment confirmed, chat reply, action status), meaning the notification infrastructure must be designed as a shared service callable from any feature slice.

The recommended approach is lightweight and dependency-minimal. The backend requires only a version bump on `firebase-admin` (already declared). The AI service requires zero new pip dependencies — prompt injection defense uses system prompt engineering, input sanitization, and canary token techniques rather than heavy ML-based scanners. Flutter adds three packages (`firebase_core`, `firebase_messaging`, `flutter_local_notifications`) for push and one (`table_calendar` + `intl`) for the calendar view. The role expansion (`provider`) is a trivial extension of existing auth patterns. This means the implementation risk is low on the dependency side but moderate on the integration side — particularly around Firebase platform setup (Android `google-services.json`, iOS capabilities) and ensuring the LangChain session lifecycle correctly triggers notification events.

The top risks for v3.0 are: (1) Firebase platform configuration — missing `google-services.json` or iOS push capability causes silent notification failures with no user-visible error; (2) prompt injection escalation in a controlled-user chatbot — while the user base is authenticated, a compromised student account could still attempt data exfiltration via prompt manipulation; (3) FCM token lifecycle management — tokens rotate silently and stale tokens cause `messaging.send()` to fail; (4) the session lifecycle "end" detection — there's no reliable signal for when a WhatsApp conversation ends (no "disconnect" event), requiring a timeout-based approach.

---

## Key Findings

### Stack Additions (from STACK.md)

v3.0 is remarkably lean in new dependencies. The entire backend addition is a version bump. The AI service adds nothing. Flutter adds 5 packages.

**Backend:**
- `firebase-admin >=7.4.0` (bump from `>=6.6.0`): FCM v1 HTTP API support, `messaging.send()` and `messaging.send_each()` for batch — already declared, just needs version pin update

**Flutter (new packages):**
- `firebase_core ^4.7.0`: Firebase initialization foundation — required before any Firebase plugin works
- `firebase_messaging ^16.2.0`: Receive push notifications, obtain device FCM token, handle foreground/background/terminated states
- `flutter_local_notifications ^21.0.0`: Display heads-up notifications when app is in foreground (FCM alone doesn't show them)
- `table_calendar ^3.2.0`: Weekly schedule view with `CalendarFormat.week` mode, `eventLoader` for class slots, pt_BR locale support
- `intl ^0.19.0`: Date formatting and locale for calendar (may already be transitive, make explicit)

**AI Service — zero new dependencies:**
- Prompt injection defense: system prompt hardening + input length limiting + canary token technique + delimiter wrapping
- Session lifecycle: `BaseCallbackHandler` (already in LangChain >=0.3) + DB-driven session state

**What was explicitly rejected:**
- `llm-guard` — 500MB+ model downloads, cold start latency, overkill for authenticated user base
- `rebuff` — requires Pinecone, external API latency on every message
- `nemoguardrails` — replaces agent architecture, incompatible with existing ReAct setup
- `redis` — PostgreSQL sufficient at current scale
- `syncfusion_flutter_calendar` — license concerns

### Feature Classification (from FEATURES.md + v3.0 scope)

**Must have (table stakes for v3.0):**
- FCM push notifications for 5 event types: `document_ready`, `enrollment_confirmed`, `appointment_confirmed`, `chat_reply`, `action_status`
- FCM token registration endpoint (`POST /auth/fcm-token`) + multi-device support per student
- LangChain session lifecycle: welcome message on new session, session close on timeout/goodbye, `[SESSION_END]` marker detection
- Prompt injection defense: multi-layer (system prompt hardening, 2000-char input limit, canary token, `<user_message>` delimiters)
- Provider role: new role in auth system, `require_any_role()` utility, route-level guards on shared endpoints
- Flutter weekly calendar (grade curricular): `table_calendar` in week mode with class schedule data from API
- Flutter perfil screen: student profile display with academic info
- Flutter cardápio screen: meal/menu display (data source TBD — likely new API endpoint or static data)

**Should have (differentiators):**
- FCM notification tap navigation: deep-link to relevant screen when notification is tapped
- Stale FCM token cleanup: detect `messaging.send()` failures and remove invalid tokens
- Session activity heatmap in staff dashboard (from session lifecycle data)
- Prompt injection audit logging: flag suspicious inputs that trigger defense mechanisms

**Defer to v4+:**
- Audio transcription (Whisper) for WhatsApp voice messages
- Knowledge base admin UI for staff
- Scheduled notification digests (daily summary push)
- Provider-specific WhatsApp chatbot flow (v3.0 adds role only, not provider chat)

### Architecture Integration Points (from ARCHITECTURE.md)

v3.0 code connects to the existing architecture at these specific seams:

**1. FCM — New infrastructure module + notifications feature slice:**
```
backend/src/infrastructure/fcm_client.py     ← NEW: Firebase app init, send helpers
backend/src/features/notifications/          ← NEW: feature slice
  router.py       (FCM token CRUD endpoints)
  service.py      (send_notification logic, batch send)
  models.py       (FcmToken model — already exists, move here)
  schemas.py      (NotificationPayload, TokenRegistration)
```
Called FROM: documents service (on status→ready), enrollment service (on confirm), appointments service (on book/cancel), webhook handler (on chat_reply), MCP action completion (on action_status).

**2. Prompt injection — AI service system prompt + input preprocessor:**
```
ai_service/prompts/system_prompt.py   ← MODIFY: add injection defense instructions
ai_service/security/input_guard.py    ← NEW: length check, delimiter wrap, canary check
ai_service/security/output_guard.py   ← NEW: canary leak detection in responses
```

**3. Session lifecycle — webhook handler + AI service callbacks:**
```
backend/src/features/webhook/service.py  ← MODIFY: detect new session → send welcome
ai_service/callbacks/lifecycle.py        ← NEW: BaseCallbackHandler for session events
```
Session "end" detection: query `chat_messages` for last timestamp; if gap > 30 min → close session via background task.

**4. Provider role — auth + migrations:**
```
backend/src/shared/auth.py               ← MODIFY: add require_any_role()
alembic/versions/XXX_add_provider_role.py ← NEW: migration
```

**5. Flutter new screens:**
```
mobile/lib/features/cardapio/            ← NEW: meal menu screen
mobile/lib/features/perfil/              ← NEW: profile screen
mobile/lib/features/calendario/          ← NEW: weekly calendar screen
mobile/lib/core/notifications/           ← NEW: FCM initialization + handlers
```

### Top Pitfalls to Watch (from PITFALLS.md + v3.0 specific)

1. **FCM token rotation without re-registration** — Firebase silently rotates device tokens. If the app doesn't listen to `onTokenRefresh` and re-register, push notifications start failing silently. **Prevention:** Subscribe to `FirebaseMessaging.instance.onTokenRefresh` and call `POST /auth/fcm-token` on every token change. On backend, replace (not append) old token for same device.

2. **Firebase platform setup incomplete** — Missing `google-services.json` (Android) or Push Notification capability (iOS) causes FCM to fail at runtime with no build-time error. **Prevention:** Checklist-driven setup; test push delivery to physical device before marking feature complete.

3. **Notification spam from rapid state changes** — If enrollment is confirmed, then a document is requested, then an appointment is booked in quick succession, the student gets 3 notifications within seconds. **Prevention:** Debounce notifications per student (e.g., batch notifications within a 5-second window) or accept this as intentional in v3.0.

4. **Prompt injection via multi-turn conversation** — Single-message defenses can be bypassed by gradually shifting context over multiple turns. **Prevention:** The system prompt is injected on EVERY agent invocation (not just the first), and the canary token check runs on every output. `ConversationBufferWindowMemory(k=20)` means attack context eventually ages out.

5. **`asyncio.create_task` for notifications swallows failures** — Same pitfall as CRITICAL-3 in PITFALLS.md: if the FCM send task fails (invalid token, Firebase outage), no retry and no log. **Prevention:** Apply the same `add_done_callback(_handle_task_result)` pattern to all notification sends. Log failures. Mark failed tokens for cleanup.

6. **SQLAlchemy session in notification background tasks** — Same as CRITICAL-4: notifications triggered from within a request handler cannot reuse the request's DB session if sent via `create_task`. **Prevention:** Notification service always opens its own session.

---

## Implications for Roadmap

v3.0 features decompose into 5 workstreams, some parallelizable. The key insight is that FCM infrastructure must be built first because multiple features depend on it, but the Flutter screens are independent of each other and independent of backend notification logic.

### Phase 3.1: FCM Infrastructure + Notification Service (Backend)

**Rationale:** FCM is the cross-cutting dependency. The notification service must exist before any feature can trigger push. This phase establishes the `fcm_client.py` infrastructure, the `notifications` feature slice, the FCM token registration endpoint, and the ability to send notifications. No feature-level triggers yet — just the plumbing.

**Delivers:**
- `POST /auth/fcm-token` — register device token (multi-device per student)
- `DELETE /auth/fcm-token` — deregister on logout
- `fcm_client.py` with `send_to_student(student_id, payload)` and `send_batch(student_ids, payload)`
- Firebase Admin SDK initialized from `settings.fcm_credentials_path`
- Alembic migration for any schema additions (e.g., device_name on fcm_tokens)

**Addresses:** FCM push notifications (must-have), multi-device support
**Avoids:** Silent notification failures (done callback pattern), session leak in background sends

### Phase 3.2: Provider Role + Auth Expansion (Backend)

**Rationale:** Can run in parallel with 3.1. Pure auth-layer change with no external service dependency. Unblocks any provider-specific endpoints needed by other phases.

**Delivers:**
- `require_any_role('staff', 'provider')` utility in `shared/auth.py`
- Alembic migration adding `provider` to role options
- Provider-specific endpoints (TBD based on requirements — at minimum, read access to certain data)
- Updated JWT claims documentation

**Addresses:** Provider role expansion (must-have)
**Avoids:** MODERATE-5 (role not asserted on endpoints) — ensure new endpoints have explicit role guards

### Phase 3.3: Prompt Injection Defense + Session Lifecycle (AI Service)

**Rationale:** Can run in parallel with 3.1 and 3.2. Zero new dependencies. Entirely contained within the AI service codebase. The session lifecycle work also enables the `chat_reply` notification trigger.

**Delivers:**
- Hardened system prompt with explicit persona boundaries, refusal instructions, delimiter separation
- Input guard: 2000-char limit, `<user_message>` delimiter wrapping
- Canary token injection in system prompt + output check for canary leak
- Session lifecycle: welcome message on new session creation
- Session lifecycle: `[SESSION_END]` marker detection → close session
- Session lifecycle: 30-minute inactivity timeout → close session (background task)
- `closed_at` column on `chat_sessions` (Alembic migration)

**Addresses:** Prompt injection defense (must-have), session lifecycle completion (must-have)
**Avoids:** MODERATE-2 (agent loop — reinforced by defense prompt reducing confusion), multi-turn injection (system prompt on every invocation)

### Phase 3.4: FCM Event Triggers (Backend — Feature Integration)

**Rationale:** Depends on Phase 3.1 (notification service must exist). This phase wires existing feature slices to trigger notifications at the right moments.

**Delivers:**
- Document service: trigger `document_ready` notification on status → `ready`
- Enrollment service: trigger `enrollment_confirmed` notification on confirm
- Appointment service: trigger `appointment_confirmed` on book, notify on cancel
- Webhook handler: trigger `chat_reply` notification when AI response sent (if app is backgrounded)
- MCP action hook: trigger `action_status` notification for long-running actions

**Addresses:** All 5 FCM event types (must-have)
**Avoids:** Notification spam (document debounce strategy), silent failures (done callback on every send)

### Phase 3.5: Flutter — FCM + New Screens (Mobile)

**Rationale:** Can begin in parallel with Phase 3.1 (Firebase setup is shared work). Flutter screens (cardápio, perfil, calendario) are independent of backend notification triggers. FCM client-side setup requires Firebase project configuration which is a shared dependency with the backend.

**Delivers:**
- Firebase initialization in `main.dart`
- FCM token retrieval + registration on login + `onTokenRefresh` listener
- Foreground notification display via `flutter_local_notifications`
- Notification tap → deep-link to relevant screen
- Perfil screen (student profile with academic info)
- Cardápio screen (meal/menu display)
- Grade curricular calendar (weekly view with `table_calendar`, class schedule data from API)

**Addresses:** Flutter new features (must-have), FCM client-side (must-have)
**Avoids:** Firebase platform setup pitfall (checklist-driven), token rotation (onTokenRefresh handler)

### Phase Ordering and Parallelization

```
              ┌─── Phase 3.1: FCM Infrastructure ───────────┐
              │                                              ▼
START ───────▶├─── Phase 3.2: Provider Role (parallel) ──── Phase 3.4: FCM Triggers ──→ DONE
              │                                              ▲
              └─── Phase 3.3: Prompt + Session (parallel) ──┘

              ┌─── Phase 3.5: Flutter (parallel with all backend) ──────────────────→ DONE
START ───────▶┘
```

- **Phases 3.1, 3.2, 3.3, 3.5** can all begin simultaneously
- **Phase 3.4** depends on Phase 3.1 completion (notification service must exist)
- **Phase 3.5** Flutter FCM setup shares the Firebase project config with Phase 3.1; coordinate `google-services.json` generation early
- **Total critical path:** Phase 3.1 → Phase 3.4 (backend notification triggers are last to complete)

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3.3 (Prompt Injection):** The canary token technique needs a concrete implementation pattern — how to inject the canary, where to check the output, and what to do on detection (log + suppress? re-run without the suspicious input?). Research specific prompt defense patterns for LangChain ReAct agents.
- **Phase 3.5 (Flutter Calendar):** The grade curricular data model (what endpoint provides class schedule? what's the shape?) is not yet specified. Need to determine if a new API endpoint is required or if existing curriculum data is sufficient.

Phases with standard/well-documented patterns (skip research):
- **Phase 3.1 (FCM Backend):** `firebase-admin` SDK is well-documented. Pattern: init app → get token from client → `messaging.send(Message(...))`. Official Firebase docs are comprehensive.
- **Phase 3.2 (Provider Role):** Trivial extension of existing `require_role()`. Standard FastAPI dependency injection.
- **Phase 3.4 (FCM Triggers):** Pattern is: after successful business operation, call `notification_service.send(student_id, event_type, payload)`. No novelty.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All dependencies verified on PyPI/pub.dev with exact version pins. Zero ambiguity — only 1 pip bump + 5 Flutter packages. No new architecture dependencies. |
| Features | HIGH | FCM event types defined in project docs. Session lifecycle approach is DB-driven (no new lib). Prompt defense is prompt-engineering (well-understood). Provider role is trivial auth extension. |
| Architecture | HIGH | Integration points are clear — FCM client goes in `infrastructure/`, notification slice in `features/`, prompt defense in AI service. No new services, no new containers, no new databases. |
| Pitfalls | MEDIUM-HIGH | FCM-specific pitfalls (token rotation, platform setup) are well-documented in Firebase docs. Prompt injection effectiveness is inherently MEDIUM — no technique is 100%. |

**Overall confidence:** HIGH

### Gaps to Address

- **Cardápio data source:** Where does the meal/menu data come from? Is there a new API endpoint needed? Is it static data bundled in the app? Or an external API? This is unspecified and must be resolved before Phase 3.5 Flutter implementation.

- **Provider role scope:** What can a provider actually DO? The role is added but the specific endpoints accessible to providers are not defined. Need product decision: can providers see student data? Which endpoints get `require_any_role('staff', 'provider')`?

- **Notification payload structure:** What data goes in each notification type? Example: `document_ready` — does it include document_id for deep-linking? Does it include the document title? Define the FCM payload schema for each of the 5 event types.

- **Session close notification trigger:** When a session is closed (30-min timeout), should the student receive a "your session has ended" WhatsApp message? Or is it silent? This affects the session lifecycle implementation.

- **Calendar data endpoint:** Does `GET /curriculum/active` return enough data (day-of-week, time slot, room) for the weekly calendar view? Or is a new endpoint needed like `GET /students/{id}/weekly-schedule`?

---

## Sources

### Primary (HIGH confidence)
- PyPI: `firebase-admin` v7.4.0 — verified Apr 2026, FCM v1 HTTP API support
- pub.dev: `firebase_core` v4.7.0, `firebase_messaging` v16.2.0, `flutter_local_notifications` v21.0.0 — official FlutterFire packages
- pub.dev: `table_calendar` v3.2.0 — 3.3k likes, 494k downloads, stable API
- Existing codebase: `backend/requirements.txt`, `mobile/pubspec.yaml`, `backend/src/shared/auth.py`, `ai_service/agent.py`
- Project spec docs: PROJECT.md, docs/api.md, docs/chatbot.md, docs/mcp.md, docs/database.md

### Secondary (MEDIUM confidence)
- Firebase Admin Python SDK docs — `messaging.send()`, `messaging.send_each()`, token management
- FlutterFire docs — `onMessage`, `onBackgroundMessage`, `onTokenRefresh` lifecycle
- LangChain docs — `BaseCallbackHandler`, system prompt patterns, ReAct agent defense
- Prompt injection literature — OWASP LLM Top 10, prompt hardening best practices for scoped bots

### Tertiary (LOW confidence — needs validation)
- Canary token technique effectiveness — documented in security research but not battle-tested for this specific LangChain ReAct + MCP architecture
- `flutter_local_notifications` + `firebase_messaging` interaction on iOS — known to require careful `UNUserNotificationCenter` delegate setup; test on physical device

---

## Open Questions for the Team

1. **Cardápio:** Is this a static menu (JSON bundled in app)? A new endpoint? An external cafeteria API? This blocks the Flutter screen design.

2. **Provider permissions:** Which existing endpoints should providers access? Staff-level read? Limited write? Need explicit permission matrix.

3. **Notification opt-out:** Can students disable specific notification types? Or is it all-or-nothing in v3.0?

4. **Session end message:** Should the chatbot send "Sua sessao foi encerrada por inatividade. Envie uma mensagem a qualquer momento para retomar." on timeout? Or silently close?

5. **Calendar granularity:** Does the weekly calendar need time-of-day slots (8:00-10:00 Algorithms, 10:00-12:00 Data Structures) or just day-level markers?

---

*Research completed: 2026-05-08*
*Milestone: v3.0*
*Ready for roadmap: yes*
