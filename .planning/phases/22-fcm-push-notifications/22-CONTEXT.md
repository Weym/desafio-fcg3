# Phase 22: FCM Push Notifications - Context

**Gathered:** 2026-05-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Students receive push notifications on their phone for key academic events (document ready, enrollment confirmed, appointment confirmed), with tap-to-navigate functionality. This phase covers the full stack: Firebase project setup, backend notification service, Flutter FCM integration, and deep-link navigation.

</domain>

<decisions>
## Implementation Decisions

### Token Registration & Lifecycle

- **D-01:** Register FCM token immediately after login (not deferred)
- **D-02:** Remove token from backend on logout via DELETE endpoint
- **D-03:** Follow existing spec `PUT /students/{id}/fcm-token` from `docs/api.md` for registration
- **D-04:** Support multiple devices per student — all registered tokens receive push
- **D-05:** Remove invalid tokens on send failure (Firebase "token not registered" error triggers deletion)
- **D-06:** Active `onTokenRefresh` listener in Flutter — new token sent to backend automatically

### Notification Dispatch & Content

- **D-07:** Centralized notification service in `backend/src/features/notifications/` — feature slices call this service after actions
- **D-08:** Payload format: `notification` + `data` (system shows banner in background; Flutter controls in foreground)
- **D-09:** Notification content is personalized with contextual data (e.g., "Documento pronto: Historico Escolar", not generic)
- **D-10:** **3 event types only** — `chat_reply` and `action_status` removed from original 5:
  - `document_ready` — when document processing completes
  - `enrollment_confirmed` — when staff confirms enrollment
  - `appointment_confirmed` — when staff confirms appointment
- **D-11:** Send via `asyncio.create_task()` (background, non-blocking) — same pattern as WhatsApp webhook
- **D-12:** Fire-and-forget strategy — log error on failure, no retry

### Foreground vs Background Behavior

- **D-13:** Foreground: Snackbar/Toast in-app (MaterialBanner style) with tap action to navigate
- **D-14:** Suppress snackbar if user is already on the relevant screen (e.g., on Documents when document_ready arrives)
- **D-15:** Auto-refresh data on the current screen when notification arrives in foreground (even if snackbar suppressed)
- **D-16:** Background: system handles display automatically (notification field in payload). Default system sound and vibration.

### Deep-link & Navigation on Tap

- **D-17:** Tap navigates to the target screen with specific item highlighted (e.g., Documents screen with drawer open on that document)
- **D-18:** If JWT expired on tap: redirect to login, then navigate to original destination after auth (preserve deep-link)
- **D-19:** Cold start (app terminated): use `getInitialMessage()` to detect notification that opened app, navigate to destination after auth check
- **D-20:** Event-to-route mapping in a dedicated file (`notification_routes.dart`) — centralized, testable

### Firebase Configuration

- **D-21:** Firebase project needs to be created from scratch (does not exist yet)
- **D-22:** Service account JSON referenced via `FCM_CREDENTIALS_PATH` env var, mounted as Docker volume (already wired in docker-compose.yml)
- **D-23:** Use FlutterFire CLI to generate `firebase_options.dart` (modern approach, multi-platform)
- **D-24:** Configure Android + iOS only (no web push in this phase)
- **D-25:** Commit FlutterFire generated files (google-services.json, firebase_options.dart) to repo — they contain only public project IDs

### Permissions & User Opt-out

- **D-26:** Request notification permission immediately after first login
- **D-27:** Global on/off only in this phase — granular per-type preferences deferred to Phase 23 (PERF-01)
- **D-28:** If user denies permission: respect the decision, show subtle banner if user visits profile screen. No link to system Settings (no settings screen exists)
- **D-29:** If permission denied, do NOT register token with backend (no token available on iOS; Android token exists but useless)

### Testing Strategy

- **D-30:** Backend: mock `firebase-admin` in unit tests. Integration tests verify trigger → notification service call chain.
- **D-31:** Flutter: mock `firebase_messaging` with platform condition. Existing 244 tests continue passing. New tests cover notification handler logic.

### Agent's Discretion

- Exact snackbar duration and styling (follows existing app design patterns)
- Notification channel configuration for Android (default is fine)
- Exact error handling flow when token registration fails
- How to structure the notification service internally (class-based vs function-based)

</decisions>

<canonical_refs>

## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Architecture & API Specs

- `docs/architecture.md` §FCM Notification Flow (lines 215-239) — Sequence diagram and 5 event types (now reduced to 3)
- `docs/api.md` §PUT /students/{id}/fcm-token (line 333) — Endpoint spec for token registration
- `docs/app.md` §FCM Integration (lines 56-135) — Flutter FCM integration sequence diagram and token registration flow
- `docs/database.md` §fcm_tokens (lines 63-73) — Table schema documentation

### Existing Implementation

- `backend/src/features/auth/models.py` (lines 119-133) — `FcmToken` SQLAlchemy model (already implemented)
- `backend/alembic/versions/002_create_auth_tables.py` (lines 89-101) — Migration creating `fcm_tokens` table
- `backend/src/infrastructure/config.py` (lines 195-198) — `fcm_credentials_path` setting
- `backend/requirements.txt` (line 12) — `firebase-admin>=6.6.0` dependency
- `docker-compose.yml` (lines 64, 148) — `FCM_CREDENTIALS_PATH` env var in fastapi-app and mcp-server containers

### Flutter Notification Context

- `mobile/lib/features/client/screens/client_notifications_screen.dart` — Existing derived notification UI (NOT FCM-based)
- `mobile/lib/features/client/providers/notification_provider.dart` — Current derived notification provider (aggregates from documents + appointments)
- `mobile/lib/core/router/app_router.dart` (lines 136-139) — Existing `/client/notifications` route

### Research

- `.planning/research/SUMMARY.md` (lines 135-206) — Phased implementation plan for FCM
- `.planning/research/STACK.md` (lines 120-180) — Dependency versions, platform setup, compatibility matrix

</canonical_refs>

<code_context>

## Existing Code Insights

### Reusable Assets

- **FcmToken model** (`backend/src/features/auth/models.py:119`): Already defined with student relationship, unique constraint, and index. Ready to use.
- **Database migration**: `fcm_tokens` table already created in migration 002. No new migration needed for the table itself.
- **Config setting**: `fcm_credentials_path` already in Settings class. Firebase Admin SDK init just needs to read it.
- **docker-compose.yml**: `FCM_CREDENTIALS_PATH` env var already wired for `fastapi-app` and `mcp-server` containers.
- **notification_provider.dart**: Existing derived notification logic — new FCM system can coexist or augment this.
- **GoRouter**: Route infrastructure already supports parameterized navigation. Deep-links can use `context.go()` or `context.push()`.

### Established Patterns

- **Background tasks**: `asyncio.create_task()` used for WhatsApp webhook processing — same pattern for FCM sends
- **Feature slices**: Each feature owns routes, services, controllers in `backend/src/features/{name}/`
- **Riverpod providers**: State management via `@riverpod` annotations with code generation
- **QueuedInterceptor**: Handles 401s with token refresh — deep-link after expired session can leverage this

### Integration Points

- **Backend triggers**: Document service (status → ready), Enrollment service (confirm action), Appointment service (confirm action) — each calls notification service
- **Flutter main.dart**: Firebase initialization needed at app startup (before runApp)
- **Flutter auth flow**: Token registration after successful OTP verification
- **GoRouter redirect**: Already handles auth check — extend to preserve deep-link destination

</code_context>

<specifics>
## Specific Ideas

- chat_reply event explicitly excluded — interaction with bot is real-time, push would be redundant
- action_status event excluded — internal MCP concern, not user-facing
- Notification content should be in Portuguese (matching the app's language)
- "Documento pronto: {nome do documento}" style — informative, not generic
- Phase 23 PERF-01 already scoped for notification preferences — no granular opt-out here

</specifics>

<deferred>
## Deferred Ideas

- **Granular notification preferences per event type** — belongs in Phase 23 (PERF-01: preferencias de notificacao)
- **Web push notifications** — separate infrastructure (service workers, VAPID keys), could be its own phase
- **Notification history/inbox in-app** — existing derived notifications screen may evolve in Phase 18 corrections
- **WhatsApp template messages for proactive notifications** — listed as FUTURE-07

</deferred>

---

_Phase: 22-fcm-push-notifications_
_Context gathered: 2026-05-08_
