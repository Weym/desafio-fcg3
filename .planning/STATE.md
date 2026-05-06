---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: Flutter Frontend
status: complete
last_updated: "2026-05-05T21:00:00.000Z"
last_activity: 2026-05-05
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 18
  completed_plans: 18
  percent: 100
---

# Project State

## Current Position

Phase: 10 (all M2 phases complete)
Plan: All 18 plans executed
Status: Milestone complete — verification and hardening phase
Last activity: 2026-05-05 - Validated full stack (DB fix, auth tests, AI/RAG E2E, Flutter tests)

Progress: [██████████] 100%

## Phase Status

| Phase | Name | Status |
|-------|------|--------|
| 7 | Flutter Scaffold & Auth | complete |
| 8 | Client Interface | complete |
| 9 | Staff Interface | complete |
| 10 | Cross-Platform Polish | complete |

## Current Focus

**Milestone v2.0 (Flutter Frontend) complete.**
All 4 phases executed (18/18 plans). Verification and hardening session completed 2026-05-05.

Remaining work is manual/environment verification:
- Phase 6: WhatsApp webhook E2E (requires ngrok + WhatsApp Business API)
- Phases 7/9/10: Visual testing on emulator/device
- Phase 1 stack tests: require Docker CLI on host (not inside container)

## Accumulated Context

### Decisions

Recent decisions affecting current work:

- [Milestone v2.0]: Phase numbering continues from M1 (Phase 7+) — no reset
- [Milestone v2.0]: Frontend requirements derived from `requerimentos_frontend.md` with 2 user profiles (Client, Provider/Staff)
- [Milestone v2.0]: Flutter mobile/web using existing REST API surface from M1 — no backend changes needed
- [Phase 07]: State management: Riverpod (with riverpod_annotation + code generation)
- [Phase 07]: Navigation: GoRouter with refreshListenable pattern (avoids GlobalKey crashes)
- [Phase 07]: Auth interceptor uses QueuedInterceptor for proper async serialization
- [Phase 08]: Client data layer uses @JsonSerializable codegen + DioClient injection + @riverpod annotations for 3 domains (chat, documents, appointments)
- [Phase 08]: url_launcher added for support screen external app actions (email, phone, WhatsApp)
- [Phase 08]: Filter chips use toggle behavior — tapping active filter resets to null (Todos)
- [Phase 08]: Used initialValue instead of deprecated value on DropdownButtonFormField (Flutter 3.41.6)
- [Phase 08]: Chat detail uses ConsumerStatefulWidget with SingleTickerProviderStateMixin for TabController lifecycle
- [Phase 08]: Replaced Documents and Chat placeholders in app_router.dart with real screens
- [Phase 08]: All 5 client tabs wired to real screens; _PlaceholderScreen retained only for staff routes (Phase 9)
- [Phase 08]: Derived notifications aggregate from documents (7d window) and appointments (48h window) — no backend endpoint needed
- [Phase 09]: Reuse client models cross-feature for staff services — no duplication of AppointmentModel, DocumentModel, etc.
- [Phase 09]: Staff-specific models only for staff-unique API responses (dashboard KPIs, scheduling slots, student summary)
- [Phase 09]: Dashboard screen kept separate from staff_home_screen.dart; Plan 05 handles router swap
- [Phase 09]: Confirmation dialogs use barrierDismissible: false for deliberate staff actions (threat T-09-04)
- [Phase 09]: Staff chat detail reuses same layout pattern as ClientChatDetailScreen with staff-specific providers
- [Phase 09]: Statistics tab shows numeric counters only (no charts) per D-12 to avoid extra dependencies
- [Phase 09]: Backend upload uses local filesystem (uploads/documents/) with UUID prefix for MVP
- [Phase 09]: Bulk send (D-18) deferred as TODO — individual send fully functional
- [Phase 09]: Autocomplete uses direct service call in optionsBuilder for simplicity in bottom sheet context
- [Phase 09]: All staff routes wired to real screens — _PlaceholderScreen removed from app_router.dart
- [Phase 09]: StaffHomeScreen deprecated (kept for compatibility), StaffDashboardScreen is now the default /staff route
- [Phase 10]: Shimmer uses colorScheme.surfaceContainerHighest/surface for M3 dark-mode compatibility

### Key Decisions Resolved

- State management: **Riverpod** (with riverpod_annotation + code generation) — decided in Phase 7
- Navigation architecture: **GoRouter** with refreshListenable pattern — decided in Phase 7

### Architecture Constraints (non-negotiable)

- `student_id` is NEVER exposed to the LangChain agent — always injected by MCP Server
- `MCP_SERVICE_TOKEN` only in environment variables, never in source code
- JWT stored in `flutter_secure_storage` — never in plain SharedPreferences
- Role-based route guards — student cannot access staff screens and vice versa
- All API calls use `Authorization: Bearer {token}` header
- Two separate PostgreSQL drivers: `asyncpg` for FastAPI + MCP; `psycopg3` for LangChain service

### Roadmap Evolution

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260427-h6x | adicionar opcao de escolher provedor e modelo do embedding via env | 2026-04-27 | 0aceac2 | [260427-h6x-adicionar-opcao-de-escolher-provedor-e-m](./quick/260427-h6x-adicionar-opcao-de-escolher-provedor-e-m/) |
| 260504-i90 | Expandir a base de conhecimento do RAG | 2026-05-04 | e470f57 | [260504-i90-expandir-a-base-de-conhecimento-do-rag](./quick/260504-i90-expandir-a-base-de-conhecimento-do-rag/) |

- Milestone v2.0 started: Flutter Frontend (Phases 7-10)
- Phase 7 added: Flutter Scaffold & Auth
- Phase 8 added: Client Interface
- Phase 9 added: Staff Interface
- Phase 10 added: Cross-Platform Polish

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260505-jcm | Validar e corrigir base URL de autenticação do frontend e adicionar CORS no backend para Flutter web | 2026-05-05 | 4e1ca3d | [260505-jcm-validar-e-corrigir-base-url-de-autentica](./quick/260505-jcm-validar-e-corrigir-base-url-de-autentica/) |
| 260505-jur | Corrigir crash no login OTP alinhando frontend ao TokenPair do backend | 2026-05-05 | 5fee628 | [260505-jur-corrigir-crash-no-login-otp-alinhando-o-](./quick/260505-jur-corrigir-crash-no-login-otp-alinhando-o-/) |

### Hardening Session (2026-05-05)

| Branch | Fix | Validated |
|--------|-----|-----------|
| `fix/db-credential-mismatch` | pg_hba custom + compose hba_file flag + mcp_server POSTGRES_* fallback | alembic upgrade head + seed: both pass |
| `fix/auth-tests-url-prefix` | Add /api/v1 prefix to 7 auth integration test files (38 URLs) | 37/37 integration tests pass |

Additional validations performed (no code fix needed):
- AI/RAG ingest: 6 docs, 47 chunks via OpenRouter embeddings — success
- AI/RAG chat E2E: LLM responds with correct knowledge base context — success
- Flutter tests: 8/8 pass via Windows Flutter SDK
- Phase 7 runtime bugs (CR-01/02/03): already fixed in codebase — confirmed

## Session Continuity

To resume work: read this file, then read `.planning/ROADMAP.md` to see current phase and plan status.
All M2 code work is complete. Remaining items are manual verification (WhatsApp webhook, device testing).
