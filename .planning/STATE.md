---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
last_updated: "2026-05-08T18:48:48.510Z"
last_activity: 2026-05-08 -- Phase 15.1 execution started
progress:
  total_phases: 10
  completed_phases: 5
  total_plans: 31
  completed_plans: 27
  percent: 87
---

# Project State

## Current Position

Phase: 15.1 (fix-logo-ugly-not-as-agreed-and-tilted) — EXECUTING
Plan: 1 of 1
Status: Executing Phase 15.1
Last activity: 2026-05-08 -- Phase 15.1 execution started

Progress: [██████████] 100%

## Phase Status

| Phase | Name | Status |
|-------|------|--------|
| 7 | Flutter Scaffold & Auth | complete |
| 8 | Client Interface | complete |
| 9 | Staff Interface | complete |
| 10 | Cross-Platform Polish | complete |
| 11 | Alpha Connect Visual Refactoring | complete |
| 12 | Frontend-Backend Integration | complete |
| 13 | Resource Allocation | complete |
| 14 | Human Intervention | complete |
| 15 | Cyber-Academic Visual Redesign | complete |

## Current Focus

**All phases delivered (7-15). 9 phases, 31 plans executed.**
Previous milestone (M1 Backend + AI + MCP) delivered 6 phases, 47 plans.

Branches:

- `feat/resource-allocation` — Phase 13 (10 commits)
- `feat/human-intervention` — Phase 13 + 14 (18 commits total)

Next action: Merge branches to main or start next milestone.

## Accumulated Context

### Decisions

Recent decisions affecting current work:

- [Phase 15]: JPEG logo replaced with CustomPainter vector widget (α mark + "ALPHA CONNECT" text)
- [Phase 15]: Cyber-Academic design system: Electric Teal #00E5FF primary, Obsidian #111317 dark surface
- [Phase 15]: Typography switched to Montserrat + JetBrains Mono
- [Phase 15]: GlassCard enhanced with 20px blur, 5% fill, neon outer glow, 3 elevation levels
- [Phase 15]: Navigation shells use neonTeal glow accent for selected state
- [Phase 14-polish]: Dark mode audit applied — 28 hardcoded color issues fixed across 15 screen files
- [Phase 14-polish]: Responsive audit — 15 layout constraints fixed (bottom sheets max-width 500px, chat bubbles max 500px, desktop panels max 400px)
- [Phase 14-polish]: All amber/green/red status colors now adapt to brightness (lighter shades in dark mode)
- [Phase 14-polish]: Skeleton shimmer placeholders use colorScheme.surface instead of Colors.white
- [Phase 14]: Escalation keywords checked BEFORE AI call to save AI service resources
- [Phase 14]: Staff sees all 'human_needed' + only their own 'human_active' sessions (FIFO by escalated_at)
- [Phase 14]: AI response escalation saves bot message before escalating — staff has full context
- [Phase 11]: App renamed from "Desafio FCG3" to "Alpha Connect"
- [Phase 11]: google_fonts added — Plus Jakarta Sans (headings) + Inter (body)
- [Phase 11]: Color palette aligned to alpha-connect: primary #3B608F, secondary #6A548A, tertiary #676001
- [Phase 11]: Explicit ColorScheme (not fromSeed) for precise color control in light + dark modes
- [Phase 11]: GlassCard widget (BackdropFilter + soft shadow) replaces standard Material Card across all screens
- [Phase 11]: PillButton widget (4 variants) replaces standard ElevatedButton style
- [Phase 11]: Glassmorphism bottom nav on phone; NavigationRail preserved for tablet/desktop
- [Phase 11]: Segmented filter controls replace FilterChip rows on Documents/Schedule screens
- [Phase 11]: Shared AppBarActions widget ensures theme toggle + logout on every screen
- [Phase 11]: Demo mode (setDemoUser) added for frontend preview without backend
- [Phase 11]: Dark mode text legibility fixed with explicit onSurface color on all text inputs
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
- [Phase 12]: Integration tests use real seeded emails (ana.silva@usp.br, roberto@icmc.usp.br) with DEV_MASTER_OTP=000000 bypass

### Key Decisions Resolved

- Merge `feat/resource-allocation` and `feat/human-intervention` branches into main
- Decide next milestone scope (if any)

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
- Phase 11 added: Alpha Connect Visual Refactoring (2026-05-06)
- Phase 12 added: Frontend-Backend Integration (2026-05-06)
- Phase 13 added: Resource Allocation (2026-05-06)
- Phase 14 added: Human Intervention (2026-05-06)
- Phase 15 added: Cyber-Academic Visual Redesign (2026-05-08)
- Phase 15 executed: 4 plans, 3 waves — logo fix, design system, tests all pass (2026-05-08)
- Phase 15.1 inserted after Phase 15: Fix logo — ugly, not as agreed, and tilted (URGENT)

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260505-jcm | Validar e corrigir base URL de autenticação do frontend e adicionar CORS no backend para Flutter web | 2026-05-05 | 4e1ca3d | [260505-jcm-validar-e-corrigir-base-url-de-autentica](./quick/260505-jcm-validar-e-corrigir-base-url-de-autentica/) |
| 260505-jur | Corrigir crash no login OTP alinhando frontend ao TokenPair do backend | 2026-05-05 | 5fee628 | [260505-jur-corrigir-crash-no-login-otp-alinhando-o-](./quick/260505-jur-corrigir-crash-no-login-otp-alinhando-o-/) |
| 260508-0z | Rebrand SIAC→Alpha Connect, implement logo, verify light/dark mode | 2026-05-08 | 4b16b62 | [260508-0z-rebrand-alpha-connect-themes-logo](./quick/260508-0z-rebrand-alpha-connect-themes-logo/) |

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
