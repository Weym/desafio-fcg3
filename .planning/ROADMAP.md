# Roadmap — Desafio FCG3

**Milestone:** M2 — Flutter Frontend
**Granularity:** Standard
**Coverage:** 17/17 requirements mapped
**Last Updated:** 2026-05-04
**Previous Milestone:** M1 — Backend + AI Service + MCP Server (Phases 1-6, complete)

---

## Phases

- [ ] **Phase 7: Flutter Scaffold & Auth** — App boots with role-based navigation, OTP authentication, secure JWT storage
- [ ] **Phase 8: Client Interface** — All 6 client screens consuming the REST API (dashboard, chat history, documents, notifications, support)
- [ ] **Phase 9: Staff Interface** — All 4 staff/provider management screens (dashboard, schedule, AI data, document management)
- [ ] **Phase 10: Cross-Platform Polish** — Responsiveness on all form factors, performance optimization, data sync efficiency

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

**Plans:** 3 plans

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

**Plans:** 5 plans

Plans:
- [x] 08-01-PLAN.md — Data layer: models, services, and Riverpod providers for all client domains
- [x] 08-02-PLAN.md — Dashboard (Home) with 3 summary cards + Support & Contact screen
- [ ] 08-03-PLAN.md — Documents screen with filter chips, status cards, and request bottom sheet
- [ ] 08-04-PLAN.md — Chat History screen (session list + detail with messages/actions tabs)
- [ ] 08-05-PLAN.md — Notifications (derived) screen + final router wiring

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

### Plans
*(Not yet planned)*

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

### Plans
*(Not yet planned)*

---

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 7. Flutter Scaffold & Auth | 0/3 | Planned | - |
| 8. Client Interface | 0/0 | Not Started | - |
| 9. Staff Interface | 0/0 | Not Started | - |
| 10. Cross-Platform Polish | 0/0 | Not Started | - |
