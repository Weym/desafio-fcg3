# Phase 8: Client Interface - Context

**Gathered:** 2026-05-04
**Status:** Ready for planning

<domain>
## Phase Boundary

All 6 client-facing screens are functional, consuming data from the FastAPI REST API built in M1. The student can view their academic situation dashboard, chat history with bot actions, request and view documents, see derived notifications, and access support contact info — all within the existing 5-tab bottom navigation established in Phase 7.

</domain>

<decisions>
## Implementation Decisions

### Dashboard (Home)

- **D-01:** Dashboard shows 3 summary cards with quick links — tap on a card navigates to the corresponding detail screen.
- **D-02:** Cards displayed: (1) Ultima atividade do bot (last bot action from chat sessions), (2) Proximo agendamento (next upcoming appointment), (3) Status de documentos (count by status: pending/ready).
- **D-03:** Data fetched from multiple endpoints aggregated on frontend: `GET /chat-sessions`, `GET /appointments`, `GET /documents`. No single summary endpoint needed.
- **D-04:** Layout: Greeting "Ola, {name}!" at top + vertical scrollable column of cards below.
- **D-05:** Pull-to-refresh to reload all cards simultaneously.

### Chat History

- **D-06:** Chat tab opens a list of chat sessions. Inside a session detail, 2 sub-tabs: "Mensagens" (messages) and "Acoes" (action logs). Tracker lives within the chat context, not as a separate screen.
- **D-07:** Session list displays as cards with: date, status indicator (active/closed), preview of last message, message count. Tap opens session detail.
- **D-08:** Message display uses WhatsApp-style bubbles — user messages right-aligned (primary color), bot messages left-aligned (gray/surface variant). Timestamps discrete.
- **D-09:** Action logs (sub-tab "Acoes") displayed as expandable list: tool name, status (success/error), timestamp. Tap expands to show input/output detail.

### Documents (Board + Request)

- **D-10:** Single screen for Documents tab. List/board shows all documents. A FAB or AppBar button triggers the request flow.
- **D-11:** Each document displayed as a card with: document type, request date, and a colored chip indicating status (yellow=processing, green=ready, gray=delivered).
- **D-12:** New document request opens as a bottom sheet with form: document type (dropdown) + optional observation + "Solicitar" button.
- **D-13:** Filter chips at the top of the list: "Todos", "Pendentes", "Prontos". User can filter by document status.
- **D-14:** Download button visible directly on the card when document status is "ready" or "delivered". Non-ready documents don't show download action.

### Notifications (Derived)

- **D-15:** No backend notifications endpoint exists; FCM is out of scope. Notifications are derived from existing data sources on the frontend.
- **D-16:** Three notification sources: (1) Documents with recently changed status (derived from `GET /documents`), (2) Upcoming appointments within 48h (derived from `GET /appointments`), (3) Relevant bot action errors like failed document retrieval (derived from action-logs with error status).
- **D-17:** Visual format: chronological list with icons by type — document icon (green) for doc status changes, clock icon (blue) for appointment reminders, alert icon (red) for error alerts. No read/unread indicator.

### Support & Contact

- **D-18:** Support screen shows static contact information: support email, phone number, office hours. Action buttons to open email client and open WhatsApp support chat.
- **D-19:** Contact data is hardcoded in the app (static constants). No API call needed.

### Agent's Discretion

- Exact card widget dimensions and spacing on dashboard
- Pull-to-refresh implementation details (RefreshIndicator vs custom)
- Chat bubble padding, border radius, and exact color shades
- Expandable tile implementation for action logs (ExpansionTile vs custom)
- Document type options list for the request dropdown (query from API if available, else hardcode known types)
- Exact notification derivation logic (time windows, thresholds for "recent")
- Support screen visual layout (icons, spacing, card vs simple list)
- Loading skeletons/shimmer for each screen during data fetch
- Empty state designs per screen
- Error snackbar vs inline error display pattern

</decisions>

<canonical_refs>

## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### API Contract (Client Endpoints)

- `docs/api.md` — Full REST API specification. Key endpoints for this phase: `GET /chat-sessions`, `GET /chat-sessions/{id}/messages`, `GET /chat-sessions/{id}/action-logs`, `GET /documents`, `GET /documents/{id}`, `POST /documents`, `GET /appointments`, `GET /students/{id}/academic-summary`
- `docs/api.md` §Error format — Standard error response shape `{"error": {"code": "...", "message": "...", "details": [...]}}`

### App Feature Specs

- `docs/app.md` — Flutter app features spec defining Client screens (Home, Chat, Tracker, Documents, Notifications), auth flow diagram, and API integration patterns

### Phase 7 Decisions (Foundation)

- `.planning/phases/07-flutter-scaffold-auth/07-CONTEXT.md` — All Flutter scaffold decisions: Riverpod (D-01/D-02), GoRouter (D-03), bottom nav structure (D-04/D-05), feature-first folders (D-12), Dio + interceptors (D-13), json_serializable (D-14), service classes pattern (D-17)

### Database Schema

- `docs/database.md` — Authoritative schema for documents, appointments, chat_sessions, chat_messages, mcp_action_logs tables

### Architecture

- `docs/architecture.md` — System topology, how Flutter connects to FastAPI at :8000

</canonical_refs>

<code_context>

## Existing Code Insights

### Reusable Assets

- **ClientShell** (`mobile/lib/features/client/screens/client_shell.dart`): BottomNavigationBar with 5 tabs already wired. Tab routing via GoRouter paths.
- **ClientHomeScreen** (`mobile/lib/features/client/screens/client_home_screen.dart`): Placeholder with auth state access pattern — shows how to use `ref.watch(authProvider)` for user data.
- **DioClient** (`mobile/lib/core/network/dio_client.dart`): Configured HTTP client with auth interceptor and refresh support. All service classes should use this.
- **UserModel** (`mobile/lib/core/models/user_model.dart`): User model with `id`, `name`, `email`, `role`. Available via auth state for greeting.
- **AppTheme** (`mobile/lib/core/theme/app_theme.dart`): Material 3 theme with rounded borders (12px), filled inputs, floating snackbars. Use theme tokens for consistency.
- **Route Paths** (`mobile/lib/core/router/route_names.dart`): All 5 client paths defined: `/client`, `/client/chat`, `/client/documents`, `/client/notifications`, `/client/support`.

### Established Patterns

- **State management**: Riverpod with `@riverpod` annotation + code generation. ConsumerWidget for reactive UI.
- **Service layer**: Service classes per feature (see AuthService pattern) using Dio, exposed via Riverpod provider. Screens never call Dio directly.
- **Models**: `@JsonSerializable()` with `part '*.g.dart'` for code generation.
- **Navigation**: GoRouter with ShellRoute for tab persistence. Route guards via redirect + auth state listener.

### Integration Points

- **Router** (`mobile/lib/core/router/app_router.dart`): Currently 4 placeholder screens using `_PlaceholderScreen`. Each must be replaced with real screen widgets. Sub-routes (e.g., `/client/chat/{sessionId}`) need to be added for detail screens.
- **ClientShell**: No changes needed — tab structure is correct as-is.
- **Providers**: New providers needed per feature domain (chat, documents, appointments, notifications).

</code_context>

<specifics>
## Specific Ideas

- Chat sub-tabs within session detail keep the "Tracker de Acoes" concept from docs/app.md without adding a separate top-level screen — cleaner navigation.
- Notifications derived from existing data avoid the need for new backend endpoints while still providing useful status awareness to the student.
- Support screen is deliberately minimal — contact info with action buttons, no complex forms or FAQ system.
- Document download button directly on card reduces navigation depth — user doesn't need to open detail just to download.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

_Phase: 08-client-interface_
_Context gathered: 2026-05-04_
