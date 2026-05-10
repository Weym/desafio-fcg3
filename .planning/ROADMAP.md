# Roadmap — Desafio FCG3

**Milestone:** M2 — Flutter Frontend
**Granularity:** Standard
**Coverage:** 17/17 requirements mapped
**Last Updated:** 2026-05-08
**Previous Milestone:** M1 — Backend + AI Service + MCP Server (Phases 1-6, complete)

---

## Phases

- [x] **Phase 7: Flutter Scaffold & Auth** — App boots with role-based navigation, OTP authentication, secure JWT storage
 (completed 2026-05-05)
- [x] **Phase 8: Client Interface** — All 6 client screens consuming the REST API (dashboard, chat history, documents, notifications, support)
 (completed 2026-05-05)
- [x] **Phase 9: Staff Interface** — All 4 staff/provider management screens (dashboard, schedule, AI data, document management)
 (completed 2026-05-05)
- [x] **Phase 10: Cross-Platform Polish** — Responsiveness on all form factors, performance optimization, data sync efficiency
 (completed 2026-05-05)
- [x] **Phase 11: Alpha Connect Visual Refactoring** — Align Flutter app visual identity with alpha-connect prototype (glassmorphism, new palette, fonts, layout restructure)
 (completed 2026-05-06)
- [x] **Phase 12: Frontend-Backend Integration** — Validate API contracts, Docker Compose full stack, OTP bypass for dev, E2E automated tests with real data flowing
 (completed 2026-05-06)
- [x] **Phase 13: Resource Allocation** — CRUD de recursos (gestor), agendamento com upload de autorização (aluno), novos tipos de recurso, flag requires_authorization
 (completed 2026-05-06)
- [x] **Phase 14: Human Intervention** — Tela de intervenção humana (gestor assume chats não resolvidos pelo bot, responde via WhatsApp)
 (completed 2026-05-06)
- [x] **Phase 15: Cyber-Academic Visual Redesign** — Apply Cyber-Academic design system (obsidian palette, neon accents, Montserrat typography, glassmorphism) to make the app more attractive and modern
 (completed 2026-05-08)

---

### Phase 14: Human Intervention

**Goal:** Complete human intervention system — bot escalates conversations when unable to resolve, staff sees pending sessions, assumes conversations, replies directly to students via WhatsApp, and marks sessions resolved.
**Depends on:** Phase 13
**Requirements:** HI-01, HI-02, HI-03, HI-04, HI-05, HI-06, HI-07, HI-08, HI-09, HI-10, HI-11, HI-12, HI-13, HI-14, HI-15, HI-16

### Success Criteria
1. Chat sessions support 4 status values (active, closed, human_needed, human_active) with assigned_staff_id tracking.
2. Bot detects escalation keywords ("atendente", "humano", etc.) and AI responses containing "procurar a secretaria" — triggers escalation automatically.
3. Student receives acknowledgment message on escalation; AI stops processing their messages until resolved.
4. Staff can list pending interventions, assume a conversation, send replies (delivered via WhatsApp), and resolve sessions.
5. Flutter staff app has "Intervenção" tab with session cards (student name, RA, status badge, elapsed time) and chat interface.

**Plans:** 2 plans

Plans:
- [x] 14-01-PLAN.md — Backend: migration, escalation detection, AI skip, assign/reply/resolve endpoints
- [x] 14-02-PLAN.md — Frontend staff: intervention screen, chat detail, navigation wiring

---

### Phase 15: Cyber-Academic Visual Redesign

**Goal:** Apply the Cyber-Academic design system — deep obsidian palette (#111317), Electric Teal (#00E5FF) primary, Cyber Violet (#7209B7) secondary, Montserrat + JetBrains Mono typography, glassmorphism cards with backdrop blur, neon glow elevation, and pill-shaped buttons — to make the app visually striking and modern. No changes to functionality, application logic, or responsive breakpoint behavior.
**Depends on:** Phase 14
**Requirements:** UI-NFR-02 (visual consistency), UI-NFR-04 (dark mode support)

### Success Criteria
1. Color palette replaced with Cyber-Academic tokens: primary Electric Teal, secondary Cyber Violet, tertiary Magenta, obsidian surfaces — in both light/dark modes.
2. Typography switched to Montserrat (headlines Black/ExtraBold, body Regular) + JetBrains Mono (technical/AI data), with tracking and weight hierarchy per design spec.
3. All cards use glassmorphism treatment (backdrop blur 20px, 5% white fill, 1px 12% white border, neon outer glow on Layer 2 elements).
4. Buttons use pill-shaped style (full-round radius); primary solid Electric Teal with black text, secondary ghost with teal border.
5. Spacing system migrated to 8px base unit with defined xs/sm/md/lg/xl tokens.
6. Existing functionality, API integrations, and responsive breakpoints remain fully intact (no behavioral regressions).

**Plans:** 4 plans

Plans:
- [ ] 15-01-PLAN.md — Theme foundation: Cyber-Academic color palette, Montserrat + JetBrains Mono typography, enhanced GlassCard with neon glow
- [ ] 15-02-PLAN.md — Screen-level updates: replace old font refs, update branding, neon nav accents
- [ ] 15-03-PLAN.md — Verification: update widget tests, full flutter analyze + test pass
- [ ] 15-04-PLAN.md — Logo fix: replace JPEG with theme-adaptive CustomPainter vector widget

---

### Phase 15.2: Add Alpha Connect SVG logos to the app (INSERTED)

**Goal:** Replace text-based logo (Greek α via Google Fonts) with real Adobe Illustrator SVG logos — full logo (α + ALPHA CONNECT text) and short logo (α mark only) — rendered via flutter_svg with theme-adaptive color tinting.
**Requirements**: UI-NFR-02
**Depends on:** Phase 15
**Plans:** 1 plan

Plans:
- [ ] 15.2-01-PLAN.md — Add flutter_svg + SVG assets, rewrite AlphaConnectLogo widget, verify tests

### Phase 15.1: Fix logo — ugly, not as agreed, and tilted (INSERTED)

**Goal:** Rewrite the CustomPainter α mark to accurately match the reference JPEG (circular O-body + X-tail) and remove the unwanted Transform.rotate tilt from the login screen.
**Requirements**: UI-NFR-02
**Depends on:** Phase 15
**Plans:** 1/1 plans complete

Plans:
- [x] 15.1-01-PLAN.md — Rewrite α mark geometry (stroke-based arc + X-tail) and remove rotation from login

### Phase 13: Resource Allocation

**Goal:** Complete resource allocation system — staff manages resources with authorization flags, students browse/book resources with file upload for restricted ones, expanded resource types and seed data.
**Depends on:** Phase 12
**Requirements:** RES-01, RES-02, RES-03, RES-04, RES-05, RES-06, RES-07, RES-08, RES-09, RES-10, RES-11, RES-12, RES-13, RES-14

### Success Criteria
1. Backend supports 6 resource types with description and requires_authorization fields.
2. Staff can CRUD resources via API and dedicated "Recursos" screen (5th tab).
3. Students can browse available resources filtered by type, with clear authorization badge.
4. Booking flow enforces file upload (PDF/JPG/PNG, 5MB) for authorization-required resources.
5. Students can view and cancel their appointments from "Meus Agendamentos" section.
6. Seed data includes diverse resources across all 6 types.

**Plans:** 3 plans

Plans:
- [x] 13-01-PLAN.md — Backend: migration, resources CRUD endpoints, upload endpoint, seed expansion
- [x] 13-02-PLAN.md — Frontend staff: resources screen with CRUD + navigation wiring
- [x] 13-03-PLAN.md — Frontend client: resource booking flow with upload + my appointments

---

## Phase Details

### Phase 7: Flutter Scaffold & Auth

**Goal:** The Flutter app boots, detects authentication state, authenticates students and staff via the existing FastAPI OTP flow, stores JWT securely, and routes users to role-appropriate home screens.
**Depends on:** M1 Phase 2 (Authentication endpoints), M1 Phase 1 (Docker stack running)
**Requirements:** UI-INFRA-01, UI-INFRA-02, UI-INFRA-03, UI-NFR-03

### Success Criteria
1. App launches and detects no saved token → navigates to login screen; saved valid token → navigates directly to role-appropriate home.
2. User enters email → receives OTP → enters 6-digit code → receives JWT → app navigates to Client home (student) or Staff dashboard (staff).
3. JWT is persisted in flutter_secure_storage and survives app restart; expired or revoked token is detected and routes back to login.
4. Role-based navigation: student sees only Client routes (Dashboard, Chat, Documents, Notifications, Support); staff sees only Provider routes (Dashboard, Schedule, AI Data, Documents).
5. Invalid OTP entry shows clear error; 3 failed attempts shows "new code sent" message matching backend behavior.

**Plans:** 3/3 plans complete

Plans:
- [x] 07-01-PLAN.md — Project infrastructure (dependencies, folder structure, Dio, theme, models, AuthService)
- [x] 07-02-PLAN.md — Auth feature (Riverpod providers, auth state, login screen with OTP flow)
- [x] 07-03-PLAN.md — Navigation & splash (GoRouter, route guards, ShellRoute, BottomNav shells, placeholder homes)

---

### Phase 8: Client Interface

**Goal:** All 6 client-facing screens are functional, consuming data from the FastAPI REST API — the student can view their academic situation, chat history, documents, and notifications from the app.
**Depends on:** Phase 7
**Requirements:** UI-C01, UI-C02, UI-C03, UI-C04, UI-C05, UI-C06, UI-NFR-01

### Success Criteria
1. Client Dashboard displays a summary of recent WhatsApp actions and upcoming appointments fetched from `/students/{id}/summary`.
2. Chat History screen lists chat sessions and allows viewing messages per session, with status indicators for open requests.
3. Document Board shows issued/received documents with download capability; Document Request screen triggers new document issuance via `POST /documents`.
4. Notification Center displays alerts, appointment reminders, and status updates — with unread indicators.
5. Support & Contact screen provides a direct channel for the client to reach administrative support.

**Plans:** 5/5 plans complete

Plans:
- [x] 08-01-PLAN.md — Data layer: models, services, and Riverpod providers for all client domains
- [x] 08-02-PLAN.md — Dashboard (Home) with 3 summary cards + Support & Contact screen
- [x] 08-03-PLAN.md — Documents screen with filter chips, status cards, and request bottom sheet
- [x] 08-04-PLAN.md — Chat History screen (session list + detail with messages/actions tabs)
- [x] 08-05-PLAN.md — Notifications (derived) screen + final router wiring

---

### Phase 9: Staff Interface

**Goal:** All 4 staff/provider management screens are functional with admin-level data access — the provider can manage appointments, view AI insights, and handle documents from the app.
**Depends on:** Phase 7
**Requirements:** UI-F01, UI-F02, UI-F03, UI-F04

### Success Criteria
1. Staff Dashboard displays business KPIs: total students, active enrollments, pending documents, upcoming appointments, active chat sessions — fetched from `/staff/dashboard`.
2. Schedule Control screen lists appointments with approve/reschedule/cancel actions calling the appointments API.
3. AI Data Interaction screen shows structured information, summaries, and insights extracted from WhatsApp conversations (via chat sessions and MCP action logs endpoints).
4. Document Management screen allows sending documents to client boards and managing pending document requests with status updates.

**Plans:** 5/5 plans complete

Plans:
- [x] 09-01-PLAN.md — Staff data layer (models, services, Riverpod providers + file_picker dep)
- [x] 09-02-PLAN.md — Dashboard screen (KPI grid) + Schedule screen (appointments + create slot)
- [x] 09-03-PLAN.md — AI Data screen (sessions list + statistics tabs + chat detail)
- [x] 09-04-PLAN.md — Document Management screen (filter + status update + send doc) + backend upload endpoint
- [x] 09-05-PLAN.md — Router wiring (replace placeholders, add sub-routes for detail screens)

---

### Phase 10: Cross-Platform Polish

**Goal:** The Flutter app renders correctly on smartphones, tablets, and web; data synchronization is efficient; the user experience is polished across all form factors.
**Depends on:** Phase 8, Phase 9
**Requirements:** UI-NFR-02, UI-NFR-04

### Success Criteria
1. All screens render correctly and are usable on phone (360dp width), tablet (768dp width), and web (1280dp+ width).
2. Consistent loading states, error handling, and empty states across all screens.
3. Data fetches complete in < 2s for cached data and < 5s for fresh API calls, with visual feedback during loading.
4. UI passes basic accessibility checks: sufficient contrast ratio, minimum 48dp touch targets, text scales with system font size.

**Plans:** 5/5 plans complete

Plans:
- [x] 10-01-PLAN.md — Theme foundation (dark mode, spacing tokens, breakpoints, responsive typography)
- [x] 10-02-PLAN.md — Shared UX widgets (skeleton, empty, error, offline banner, responsive container)
- [x] 10-03-PLAN.md — Adaptive navigation shells + master-detail split view
- [x] 10-04-PLAN.md — Data cache TTL + prefetch strategy
- [x] 10-05-PLAN.md — Screen integration (all screens → shared widgets, responsive grid, theme toggle, a11y)

---

### Phase 11: Alpha Connect Visual Refactoring

**Goal:** Align the Flutter app's visual identity with the alpha-connect React prototype — new color palette, typography (Plus Jakarta Sans + Inter), glassmorphism components, pill-shaped CTAs, and restructured screen layouts — while preserving all existing features, API integrations, and responsive behaviors.
**Depends on:** Phase 10
**Requirements:** UI-NFR-02 (visual consistency), UI-NFR-04 (dark mode support)

### Success Criteria
1. App renamed to "Alpha Connect" with matching branding (icon badge + uppercase title).
2. Color palette matches alpha-connect prototype: primary #3B608F, secondary #6A548A, tertiary #676001 with full dark mode variants.
3. Typography uses Plus Jakarta Sans (headings) + Inter (body) via google_fonts.
4. Navigation uses glassmorphism bottom bar (phone) with pill-shaped active items; NavigationRail preserved for tablet/desktop.
5. All screens restructured to match alpha-connect card layouts (glass cards, segmented filters, KPI grids, quick-action grids).
6. Theme toggle + logout accessible from every screen via shared AppBarActions widget.
7. Dark mode fully legible — input text, OTP digits, search bars all use explicit onSurface colors.
8. 38 tests passing (8 existing auth + 30 new: theme tokens, GlassCard, PillButton).

**Plans:** Executed as single refactoring pass (no sub-plans)

Branch: `feat/alpha-connect-visual-refactoring`
Commits:
- [x] `69c392f` — feat(mobile): align visual identity with alpha-connect prototype
- [x] `eb4b91f` — fix(mobile): add theme toggle + logout to all screens, fix dark mode text legibility

### Phase 12: Frontend-Backend Integration

**Goal:** The Flutter app connects to the real FastAPI backend — Docker Compose orchestrates the full stack locally, API contracts are validated and corrected, OTP bypass enables dev login, and E2E tests prove data flows end-to-end.
**Depends on:** Phase 11
**Requirements:** UI-INFRA-02, UI-NFR-03

### Success Criteria
1. `docker compose up` starts all 5 services (fastapi-app, langchain-service, mcp-server, postgres, flutter-web) with healthchecks passing.
2. Flutter web app at `:3000` authenticates against backend at `:8000` using DEV_MASTER_OTP=000000 bypass.
3. All Dart models parse real API responses without exceptions — contract mismatches fixed.
4. Seed data populates on first boot; subsequent boots skip seeding (conditional seed).
5. Flutter integration tests pass against the running stack: auth flow, documents, chat, staff dashboard.

**Plans:** 3/3 plans complete

Plans:
- [x] 12-01-PLAN.md — Docker Compose full stack (flutter-web service, conditional seed, .env docs)
- [x] 12-02-PLAN.md — API contract validation and Dart model corrections
- [x] 12-03-PLAN.md — E2E integration tests (auth, documents, chat, staff)

---

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 7. Flutter Scaffold & Auth | 3/3 | Complete | 2026-05-05 |
| 8. Client Interface | 5/5 | Complete | 2026-05-05 |
| 9. Staff Interface | 5/5 | Complete | 2026-05-05 |
| 10. Cross-Platform Polish | 5/5 | Complete | 2026-05-05 |
| 11. Alpha Connect Visual Refactoring | 1/1 | Complete | 2026-05-06 |
| 12. Frontend-Backend Integration | 3/3 | Complete | 2026-05-06 |
| 13. Resource Allocation | 3/3 | Complete | 2026-05-06 |
| 14. Human Intervention | 2/2 | Complete | 2026-05-06 |
| 15. Cyber-Academic Visual Redesign | 0/3 | Planned | — |
