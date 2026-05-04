# Phase 7: Flutter Scaffold & Auth - Context

**Gathered:** 2026-05-04
**Status:** Ready for planning

<domain>
## Phase Boundary

The Flutter app boots, detects authentication state, authenticates students and staff via the existing FastAPI OTP flow (Phase 2), stores JWT securely, and routes users to role-appropriate home screens with bottom navigation. This phase delivers the app skeleton, auth flow, navigation shell, and project infrastructure — no feature screens beyond placeholder homes.

</domain>

<decisions>
## Implementation Decisions

### State Management
- **D-01:** Riverpod as the state management solution.
- **D-02:** Use `riverpod_generator` with `@riverpod` annotations and `build_runner` for code generation. All providers are generated, not manually defined.

### Navigation & Routing
- **D-03:** GoRouter as the navigation package. Declarative routing with support for redirects, guards, deep links, and ShellRoute.
- **D-04:** Bottom navigation bar (BottomNavigationBar) as the primary navigation pattern, using GoRouter's ShellRoute to persist the bar across tab screens.
- **D-05:** Role-based tab sets — Client (student) sees 5 tabs: Home/Dashboard, Chat, Documentos, Notificacoes, Suporte. Staff sees 4 tabs: Dashboard, Agenda, IA, Documentos.
- **D-06:** Route guards implemented via GoRouter redirect integrated with Riverpod auth state provider. Unauthenticated → login. Student → blocked from staff routes. Staff → blocked from student routes.
- **D-07:** Splash screen: native splash (android/ios) + Flutter intermediary screen that checks JWT validity in `flutter_secure_storage`, then redirects to login or role-appropriate home. Avoids flash of wrong screen.

### Authentication UX
- **D-08:** Single-screen two-step login flow. Step 1: email input field. On submit, step 2: OTP code field appears on the same screen with smooth transition. No page navigation for the auth flow.
- **D-09:** OTP input as a single numeric TextField (6 digits), not separate pin boxes.
- **D-10:** Authentication errors displayed via Snackbar at the bottom of the screen. Specific messages: "Codigo invalido", "Tentativas esgotadas — novo codigo enviado". Auto-dismiss after 4 seconds.
- **D-11:** Resend OTP button with 60-second countdown timer before re-enabling. Aligns with backend rate limit (5 requests per 15-minute window from Phase 2 D-13).

### Project Structure & Architecture
- **D-12:** Feature-first folder organization. Each feature has its own directory under `lib/features/` with subdirectories: `models/`, `services/`, `providers/`, `screens/`. Example: `lib/features/auth/models/`, `lib/features/auth/services/`, etc.
- **D-13:** Dio as the HTTP client. Interceptors for: automatic Authorization Bearer header injection, refresh token handling (silent renewal per Phase 2 D-02), error response parsing, logging in debug mode.
- **D-14:** `json_serializable` with `build_runner` for model serialization (fromJson/toJson generated). Build runner already required by Riverpod code gen.
- **D-15:** Custom Material 3 theme defined in `lib/core/theme/`. Custom ColorScheme, typography, and component overrides. Dark mode optional (agent's discretion).
- **D-16:** Environment configuration per environment (dev, staging, prod). API base URL, timeouts, feature flags. Injected via `--dart-define` or envied package.
- **D-17:** Data access layer: Service classes per feature using Dio + Riverpod providers. Example: `AuthService` with `requestCode()`, `verifyCode()`, exposed via Riverpod provider. Screens consume providers, never call Dio directly.

### Carried Forward from Phase 2
- **D-18:** JWT from backend contains: sub (user_id UUID), role (student | staff), jti, name, email, exp, iat. Frontend can decode token for role routing and display name without extra API call.
- **D-19:** Access token expires in 1h, refresh token in 30d. Refresh token rotation on every use. Dio interceptor handles silent refresh automatically.
- **D-20:** Only pre-registered emails (students/staff tables) can authenticate. Backend returns generic response for unregistered emails (anti-enumeration).

### Agent's Discretion
- Dark mode support (include or defer)
- Exact Material 3 color palette and seed color choice
- `--dart-define` vs `envied` package for environment config injection
- Pin input widget library choice (if any) for the single numeric field
- Loading skeleton/shimmer design during splash verification
- Exact Dio interceptor implementation details (retry logic, error mapping)
- Whether to use `flutter_native_splash` package for native splash screen

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Authentication API Contract
- `docs/api.md` — Auth endpoint specifications: POST /auth/request-code, POST /auth/verify-code, POST /auth/refresh, POST /auth/logout, GET /auth/me. Request/response shapes, error codes (INVALID_CODE, MAX_ATTEMPTS_REACHED).
- `.planning/phases/02-authentication/02-CONTEXT.md` — All auth decisions: JWT payload (D-05), token lifetimes (D-01), refresh rotation (D-03), rate limiting (D-12/D-13/D-14), multi-session policy (D-10).

### App Design & Screen Specs
- `docs/app.md` — Flutter app features spec: Client screens (Login, Home, Chat, Tracker, Documents, Notifications), Staff screens (Dashboard, Schedule, Chat Oversight, Documents). Auth flow sequence diagram. API integration patterns.

### Database Schema
- `docs/database.md` — Authoritative schema for students, staff, sessions, verification_codes tables. Needed to understand user model and session structure.

### Architecture
- `docs/architecture.md` — System topology, service communication patterns, Docker setup. Defines how Flutter connects to FastAPI at :8000.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **None** — Flutter app is an untouched `flutter create` scaffold. Package name is `frontend` (in pubspec.yaml). Only `cupertino_icons` declared as dependency.

### Established Patterns
- Directory scaffolding exists: `lib/components/`, `lib/core/`, `lib/screens/`, `lib/shared/` (all empty with `.gitkeep`). These will be reorganized to feature-first structure per D-12.
- `mobile/lib/main.dart` is the default counter app — will be completely replaced.
- Flutter version pinned to 3.41.6 via `.fvmrc`.

### Integration Points
- Backend API at `localhost:8000` (Docker) — all auth endpoints from Phase 2 are implemented and tested.
- `flutter_secure_storage` package needs to be added to pubspec.yaml for JWT persistence.
- `build_runner` needed for both `riverpod_generator` and `json_serializable`.

</code_context>

<specifics>
## Specific Ideas

- Bottom nav tabs are role-specific: student and staff see completely different navigation structures, not a shared nav with hidden items.
- Auth flow is deliberately compact — single screen with animated transition between email and OTP steps, not a multi-page wizard.
- OTP input is a simple single text field, avoiding complex pin-code widget libraries.
- The splash screen should feel professional — native splash transitions to a Flutter verification screen, then redirects. No visible "flash" of login when user is already authenticated.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 07-flutter-scaffold-auth*
*Context gathered: 2026-05-04*
