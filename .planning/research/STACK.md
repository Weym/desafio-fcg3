# Technology Stack — v3.0 Additions

**Project:** Desafio FCG3 — Plataforma Acadêmica
**Researched:** 2026-05-08
**Scope:** NEW dependencies only for FCM, prompt injection defense, session management, role expansion, and Flutter calendar

## Recommended Stack Additions

### 1. FCM Push Notifications — Backend (Python)

| Technology | Version | Purpose | Why |
|---|---|---|---|
| `firebase-admin` | `>=7.4.0` | Send FCM messages from FastAPI | **Already in requirements.txt** at `>=6.6.0`. Bump to `>=7.4.0` (latest, Apr 2026) for current FCM v1 HTTP API support. Handles `messaging.send()` and `messaging.send_each()` for batch notifications |

**Integration Point:** `backend/src/infrastructure/` — create `fcm_client.py` that initializes Firebase app from `settings.fcm_credentials_path` (already configured in `config.py` line 195). The `fcm_tokens` table and `FcmToken` model already exist.

**No new backend dependency needed** — `firebase-admin` is already declared. Just bump version pin.

### 2. FCM Push Notifications — Flutter (Mobile)

| Technology | Version | Purpose | Why |
|---|---|---|---|
| `firebase_core` | `^4.7.0` | Firebase initialization | Required foundation for all Firebase plugins. 4.0k likes, published by firebase.google.com. Cross-platform (Android, iOS, macOS, web, Windows) |
| `firebase_messaging` | `^16.2.0` | Receive push notifications, get device token | Official FlutterFire plugin. 3.9k likes, handles foreground/background/terminated states. Auto-handles token refresh |
| `flutter_local_notifications` | `^21.0.0` | Display notifications in system tray when app is foreground | firebase_messaging alone doesn't show heads-up notifications while app is open. This bridges the gap. 7.2k likes, cross-platform |

**Why NOT just `firebase_messaging` alone:** On Android, FCM messages arriving while the app is in foreground don't automatically show in the notification tray. `flutter_local_notifications` solves this by letting you trigger a local notification display from the FCM `onMessage` handler.

**Integration Point:** Initialize Firebase in `main.dart` before `runApp()`. Register FCM token on login, send to `POST /auth/fcm-token` endpoint. Listen to `onMessage`, `onMessageOpenedApp`, `onBackgroundMessage`.

### 3. Prompt Injection Defense — AI Service (Python)

| Technology | Version | Purpose | Why |
|---|---|---|---|
| Custom prompt-based defense | N/A | System prompt hardening | Zero-dependency, works within existing LangChain agent. Most practical for this use case because: (1) no external API calls = no latency penalty, (2) no ML model downloads = no Docker image bloat, (3) the system prompt already goes through the LLM which inherently classifies intent |
| `llm-guard` (optional, future) | `>=0.3.16` | ML-based prompt injection scanner | **NOT recommended for MVP** — requires ONNX runtime, downloads ML models (~500MB), adds cold start latency. Consider post-MVP if prompt-based defense proves insufficient |

**Rationale for NOT using `llm-guard` or `rebuff`:**

- **`rebuff`** (v0.1.1, Jan 2024) — Requires Pinecone vector DB as external dependency. Adds API call latency to every message. Overkill for a controlled academic chatbot.
- **`llm-guard`** (v0.3.16, May 2025) — Production-quality but heavy. Downloads transformer models. Requires `onnxruntime`. Docker image would grow ~500MB. Appropriate for public-facing LLM APIs, not a scoped WhatsApp bot with known user base.
- **`lakera-chainguard`** — External API service (Lakera Guard). Adds vendor dependency and per-request cost.

**Recommended approach:** Multi-layer defense via prompt engineering + input sanitization:

1. **System prompt hardening** — Clear persona boundaries, explicit refusal instructions, delimiter separation of user input
2. **Input length limiting** — Already have `MAX_AGENT_EXECUTION_TIME=45s` and `MAX_AGENT_ITERATIONS=10`; add character limit on user messages (e.g., 2000 chars)
3. **Canary token technique** — Inject a canary string in system prompt, check if output contains it (indicates prompt leak)
4. **Role separation** — User messages wrapped in delimiters: `<user_message>{input}</user_message>`

**No new pip dependency required.**

### 4. LangChain Session Lifecycle Management

| Technology | Version | Purpose | Why |
|---|---|---|---|
| LangChain `BaseCallbackHandler` | (included in `langchain>=0.3`) | Detect conversation start/end, log lifecycle events | Already available. Custom callback handler can emit session lifecycle events (first message = "start", timeout/goodbye = "end") |
| Existing `chat_sessions` + `chat_messages` tables | N/A | Session state tracking | Already modeled. Add `closed_at` timestamp column via Alembic migration |

**Approach:** Session lifecycle is a backend concern, not an AI library concern:

1. **Session creation** — Already happens when first WhatsApp message arrives (webhook creates `chat_session`)
2. **Session activity detection** — Query `chat_messages` for last message timestamp. If gap > 30 min, consider session stale
3. **Explicit goodbye** — System prompt instructs agent to output `[SESSION_END]` marker. Backend webhook handler detects and closes session
4. **Welcome message** — On new session creation, send predefined greeting via WhatsApp before invoking agent

**No new pip dependency required.**

### 5. Role Expansion (student/staff/provider)

| Technology | Version | Purpose | Why |
|---|---|---|---|
| Existing `require_role()` dependency | N/A | Role guard | Already implemented in `backend/src/shared/auth.py`. Supports single-role check per endpoint |
| `require_any_role()` (new utility) | N/A | Multi-role guard | Simple addition: `require_any_role('staff', 'provider')` for shared endpoints |

**Approach:** The current auth system stores `role` as a string in the JWT claims. Adding `provider` requires:

1. **Alembic migration** — Add `provider` to allowed roles in `students` table (or create separate `providers` table if semantics differ significantly from students)
2. **JWT role claim** — Already dynamic from DB. No JWT code changes needed
3. **New `require_any_role` dependency** — Trivial extension of existing `require_role` in `shared/auth.py`
4. **Route-level guards** — Apply `Depends(require_role('provider'))` or `Depends(require_any_role('staff', 'provider'))` to new endpoints

**No new pip dependency required.**

### 6. Flutter Weekly Calendar View

| Technology | Version | Purpose | Why |
|---|---|---|---|
| `table_calendar` | `^3.2.0` | Weekly schedule display | 3.3k likes, 140 pub points. Supports week/month/2-week formats natively. Has `eventLoader` for marking class slots. Locale support (`pt_BR`). Highly customizable via `CalendarBuilders`. Active maintenance (16 months since last release but stable API) |
| `intl` | `^0.19.0` | Date formatting + locale for calendar | Required by `table_calendar` for locale support. Likely already transitively available but should be explicit |

**Why `table_calendar` over alternatives:**

- **`weekly_calendar`** (v0.1.2) — Only 21 likes, 24 weekly downloads. Too simple, no event marking, no time slots. Not production-ready.
- **`syncfusion_flutter_calendar`** — Feature-rich but requires Syncfusion license for commercial use. Community edition has watermark.
- **Custom widget** — Unnecessary when `table_calendar` supports `CalendarFormat.week` mode with full customization.

**Integration Point:** Use `TableCalendar(calendarFormat: CalendarFormat.week)` with `eventLoader` that maps class schedule data from API. The glassmorphism design system can be applied via `CalendarBuilders` for custom day cell rendering.

## What NOT to Add

| Library | Why NOT |
|---|---|
| `rebuff` | Requires Pinecone. Academic chatbot with authenticated users doesn't need external vector-based injection detection |
| `llm-guard` | 500MB+ model downloads. Overkill for controlled user base. Adds cold start latency |
| `nemoguardrails` (NeMo Guardrails) | NVIDIA's framework. Heavy, opinionated, replaces your agent architecture. Not compatible with existing LangChain ReAct setup |
| `redis` | Out of scope per PROJECT.md. Session management via PostgreSQL is sufficient at current scale |
| `celery` / `dramatiq` | Out of scope. `asyncio.create_task` is sufficient for webhook processing within 5s constraint |
| `syncfusion_flutter_calendar` | License concerns for academic project |
| `firebase_analytics` | Not needed for push notifications. Would add unnecessary tracking |
| `firebase_crashlytics` | Not needed for push notifications. Sentry is out of scope per PROJECT.md |

## Alternatives Considered

| Category | Recommended | Alternative | Why Not Alternative |
|---|---|---|---|
| FCM Flutter | `firebase_messaging` | `onesignal_flutter` | OneSignal adds vendor layer between you and FCM. Backend already uses `firebase-admin` directly |
| Local notifications | `flutter_local_notifications` | `awesome_notifications` | Less mainstream (1.8k vs 7.2k likes), more complex API, compatibility issues reported with firebase_messaging |
| Calendar | `table_calendar` | Custom `PageView` + `GridView` | table_calendar handles edge cases (week boundaries, locale, swipe) that take weeks to implement correctly |
| Prompt defense | System prompt hardening | `llm-guard` PromptInjection scanner | Latency + Docker bloat. Prompt hardening is the industry standard for scoped bots (not public GPT wrappers) |
| Session management | DB-driven lifecycle | LangChain `RunnableWithMessageHistory` | Already have custom chat_sessions table. RunnableWithMessageHistory adds abstraction without value for existing architecture |

## Installation Commands

### Backend (bump version pin)

```bash
# In backend/requirements.txt — change:
# firebase-admin>=6.6.0
# To:
firebase-admin>=7.4.0
```

No other backend pip additions needed.

### AI Service

No new dependencies. Prompt injection defense is prompt-engineering based.

### Flutter (mobile/pubspec.yaml)

```yaml
dependencies:
  # ... existing deps ...
  firebase_core: ^4.7.0
  firebase_messaging: ^16.2.0
  flutter_local_notifications: ^21.0.0
  table_calendar: ^3.2.0
  intl: ^0.19.0
```

### Flutter Platform Setup Required

**Android (`android/app/build.gradle.kts`):**
- Apply `com.google.gms.google-services` plugin
- Add `google-services.json` to `android/app/`
- Enable desugaring for `flutter_local_notifications`
- Set `compileSdk = 35` minimum
- Set `minSdk = 21` minimum (for firebase_messaging)

**iOS (`ios/`):**
- Add `GoogleService-Info.plist` to Runner
- Enable Push Notifications capability in Xcode
- Enable Background Modes > Remote notifications
- Add `UNUserNotificationCenter.current().delegate = self` in AppDelegate

**Firebase Console:**
- Create Firebase project (or reuse existing)
- Register Android app (package name)
- Register iOS app (bundle ID)
- Download config files (`google-services.json`, `GoogleService-Info.plist`)
- Generate service account JSON for backend (already planned via `fcm_credentials_path`)

## Version Compatibility Matrix

| Component | Dart SDK | Flutter | Notes |
|---|---|---|---|
| `firebase_core ^4.7.0` | `^3.2` | `>=3.x` | Compatible with Dart ^3.11.4 |
| `firebase_messaging ^16.2.0` | `^3.2` | `>=3.x` | Compatible |
| `flutter_local_notifications ^21.0.0` | `^3.2` | `>=3.38.1` | **Requires Flutter 3.38.1+** — project uses 3.41.6, compatible |
| `table_calendar ^3.2.0` | `^2.17` | `>=2.x` | Very compatible, no constraints |
| `intl ^0.19.0` | `>=2.12` | any | Compatible |

| Component | Python | Notes |
|---|---|---|
| `firebase-admin >=7.4.0` | `>=3.9` | Compatible with Python 3.12 |
| `llm-guard >=0.3.16` (NOT recommended) | `>=3.10, <3.13` | Would be compatible but NOT adding |

## Architecture Integration Summary

```
┌─────────────────────────────────────────────────────────┐
│ Flutter App (mobile/)                                    │
│  + firebase_core (init)                                 │
│  + firebase_messaging (receive push, get token)         │
│  + flutter_local_notifications (foreground display)     │
│  + table_calendar (weekly schedule view)                │
│  + intl (locale for calendar)                          │
└────────────────────┬────────────────────────────────────┘
                     │ FCM token registration
                     │ POST /auth/fcm-token
                     ▼
┌─────────────────────────────────────────────────────────┐
│ FastAPI Backend (backend/)                               │
│  firebase-admin >=7.4.0 (send notifications)            │
│  + fcm_client.py (new infrastructure module)            │
│  + notifications feature slice (new)                    │
│  + require_any_role() (new auth utility)                │
│  + provider role support (migration)                    │
└────────────────────┬────────────────────────────────────┘
                     │ (no changes)
                     ▼
┌─────────────────────────────────────────────────────────┐
│ AI Service (ai_service/)                                │
│  NO new dependencies                                    │
│  + System prompt hardening (prompt injection defense)   │
│  + Session lifecycle hooks (callback handlers)          │
│  + Input sanitization (char limits, delimiter wrapping) │
└─────────────────────────────────────────────────────────┘
```

## Confidence Assessment

| Area | Confidence | Reason |
|---|---|---|
| FCM Backend | HIGH | `firebase-admin` already in project, official Google SDK, verified on PyPI (v7.4.0, Apr 2026) |
| FCM Flutter | HIGH | Official FlutterFire packages, published by firebase.google.com, millions of downloads |
| Prompt injection defense | MEDIUM | Prompt-engineering approach is standard practice but effectiveness varies by LLM model. No library provides 100% guarantee |
| Session management | HIGH | No new deps needed. Pure application logic on existing DB schema |
| Role expansion | HIGH | Trivial extension of existing `require_role()` pattern |
| Calendar widget | HIGH | `table_calendar` is the de facto standard Flutter calendar. Verified on pub.dev (3.3k likes, 494k downloads) |

## Sources

- PyPI: `firebase-admin` v7.4.0 — https://pypi.org/project/firebase-admin/ (verified Apr 2026)
- pub.dev: `firebase_core` v4.7.0 — https://pub.dev/packages/firebase_core
- pub.dev: `firebase_messaging` v16.2.0 — https://pub.dev/packages/firebase_messaging
- pub.dev: `flutter_local_notifications` v21.0.0 — https://pub.dev/packages/flutter_local_notifications
- pub.dev: `table_calendar` v3.2.0 — https://pub.dev/packages/table_calendar
- PyPI: `llm-guard` v0.3.16 — https://pypi.org/project/llm-guard/ (evaluated, not recommended)
- PyPI: `rebuff` v0.1.1 — https://pypi.org/project/rebuff/ (evaluated, not recommended)
- Existing codebase: `backend/requirements.txt`, `mobile/pubspec.yaml`, `ai_service/agent.py`, `backend/src/shared/auth.py`
