# Roadmap — Desafio FCG3

## Milestones

- **v1.0 Backend + AI + MCP** — Phases 1-6 (shipped 2026-05-04)
- **v2.0 Flutter Frontend** — Phases 7-17 (shipped 2026-05-07)
- 🚧 **v3.0 Correções, Melhorias & Features** — Phases 18-24 (in progress)

---

## Completed Milestones

<details>
<summary>v1.0 Backend + AI Service + MCP Server (Phases 1-6) — SHIPPED 2026-05-04</summary>

- [x] Phase 1: Foundation & Infrastructure (6/6 plans) — completed 2026-04-09
- [x] Phase 2: Authentication & Security (4/4 plans) — completed 2026-04-10
- [x] Phase 3: Academic Feature Slices (7/7 plans) — completed 2026-04-12
- [x] Phase 4: MCP Server (4/4 plans) — completed 2026-04-14
- [x] Phase 5: AI Service & RAG (4/4 plans) — completed 2026-04-20
- [x] Phase 6: WhatsApp Integration (3/3 plans) — completed 2026-05-04

**Archive:** [v1.0 details in git history]

</details>

<details>
<summary>v2.0 Flutter Frontend (Phases 7-17) — SHIPPED 2026-05-07</summary>

- [x] Phase 7: Flutter Scaffold & Auth (3/3 plans) — completed 2026-05-05
- [x] Phase 8: Client Interface (5/5 plans) — completed 2026-05-05
- [x] Phase 9: Staff Interface (5/5 plans) — completed 2026-05-05
- [x] Phase 10: Cross-Platform Polish (6/6 plans) — completed 2026-05-07
- [x] Phase 11: Alpha Connect Visual Refactoring (1/1 plans) — completed 2026-05-06
- [x] Phase 12: Frontend-Backend Integration (3/3 plans) — completed 2026-05-06
- [x] Phase 13: Resource Allocation (3/3 plans) — completed 2026-05-06
- [x] Phase 14: Human Intervention (2/2 plans) — completed 2026-05-06
- [x] Phase 15: Requirements Traceability Sync (1/1 plans) — completed 2026-05-07
- [x] Phase 16: Auth & Router Tech Debt (1/1 plans) — completed 2026-05-07
- [x] Phase 17: Loading State Polish (1/1 plans) — completed 2026-05-07

**Archive:** [v2.0-ROADMAP.md](./milestones/v2.0-ROADMAP.md)

</details>

---

## 🚧 v3.0 Correções, Melhorias & Features (Active)

**Milestone Goal:** Corrigir navegação e UX quebrados em ambas as visões, completar workflow LangChain, expandir roles para provider, implementar FCM push notifications, e adicionar features novas (cardápio, perfil, grade curricular).

**Parallelization Strategy:**
```
GROUP 1 — Corrections (parallel):
  Phase 18 ──┐
  Phase 19 ──┘── can execute simultaneously

GROUP 2 — Improvements (parallel):
  Phase 20 ──┐
  Phase 21 ──├── can execute simultaneously
  Phase 22 ──┘

GROUP 3 — New Features:
  Phase 23 ──── independent screens (internal parallelism)

GROUP 4 — Polish (depends on all above):
  Phase 24 ──── final integration validation
```

## Phases

- [ ] **Phase 18: Student UX Corrections** - Fix navigation, chat UX, documents, notifications on student screens
- [ ] **Phase 19: Staff UX Corrections** - Fix dashboard, agendamentos, chats, intervenção, documentos, recursos, cadastro
- [ ] **Phase 20: LangChain Workflow** - Complete agent lifecycle, RAG, MCP, defenses, logging
- [ ] **Phase 21: Roles & Auth Expansion** - Add provider role with hierarchical CRUDs
- [ ] **Phase 22: FCM Push Notifications** - End-to-end push infrastructure (backend + Flutter)
- [ ] **Phase 23: New Features** - Cardápio semanal, perfil do aluno, grade curricular
- [ ] **Phase 24: UI Polish & Integration** - Splash screen, dashboard metrics, end-to-end coherence

## Phase Details

### Phase 18: Student UX Corrections

**Goal**: Student can navigate all screens correctly with proper actions, drawers, and notification management
**Depends on**: Nothing (correction of existing code)
**Requirements**: STUX-01, STUX-02, STUX-03, STUX-04, STUX-05, STUX-06, STUX-07, STUX-08, STUX-09, STUX-10, STUX-11, STUX-12, STUX-13, STUX-14, STUX-15
**Success Criteria** (what must be TRUE):
  1. Student taps quick actions and arrives at the correct destination (agendamentos detail, documents with drawer open)
  2. Student can rename chat sessions, filter by active/inactive, and see them ordered by date
  3. Student can view full document details in a drawer, see type/date on each item, and add documents via drawer
  4. Student notifications show read/unread state, can be filtered, individually marked as read, and bulk-marked
  5. Student accesses support via header icon and views agendamento details via drawer
**Plans:** 3/5 plans executed

Plans:
- [x] 18-01-PLAN.md — Fix home quick actions + add support/notifications to header
- [x] 18-02-PLAN.md — Chat rename, active/inactive filter, date ordering
- [x] 18-03-PLAN.md — Documents type/date display + detail drawer
- [ ] 18-04-PLAN.md — Notifications read/unread state + filters + mark-as-read
- [ ] 18-05-PLAN.md — Appointment detail drawer + wiring

**UI hint**: yes

### Phase 19: Staff UX Corrections

**Goal**: Staff can manage all operational screens with correct data display, filters, search, and CRUD operations
**Depends on**: Nothing (correction of existing code)
**Requirements**: SFUX-01, SFUX-02, SFUX-03, SFUX-04, SFUX-05, SFUX-06, SFUX-07, SFUX-08, SFUX-09, SFUX-10, SFUX-11, SFUX-12, SFUX-13, SFUX-14, SFUX-15, SFUX-16, SFUX-17, SFUX-18, SFUX-19, SFUX-20, SFUX-21, SFUX-22, SFUX-23, SFUX-24, SFUX-25
**Success Criteria** (what must be TRUE):
  1. Staff dashboard shows truncated metrics and navigates to filtered views (docs pendentes, chats hoje)
  2. Staff agendamentos display correct card info (nome + recurso), support search by RA/nome, and confirm works
  3. Staff chats show tab navigation, student identification (nome + número), and informative header in conversation
  4. Staff intervenção follows visual patterns (drawer, search), shows concluídos tab
  5. Staff documentos have state tabs, type filter, full data view, drawer pattern, and error on missing file
  6. Staff recursos toggle ativar/desativar works and delete option exists
  7. Staff cadastro de alunos is a full CRUD with cards, 3-dot menu, floating add button, expandable details, and search/filters
**Plans**: TBD
**UI hint**: yes

### Phase 20: LangChain Workflow

**Goal**: WhatsApp chatbot handles complete conversation lifecycle with RAG, MCP tools, security defenses, and structured logging
**Depends on**: Nothing (backend/AI service, independent of Flutter)
**Requirements**: LANG-01, LANG-02, LANG-03, LANG-04, LANG-05, LANG-06, LANG-07, LANG-08, LANG-09, LANG-10, LANG-11, LANG-12, LANG-13, LANG-14
**Success Criteria** (what must be TRUE):
  1. Student receives welcome message when starting WhatsApp conversation and goodbye message when session ends (timeout or farewell)
  2. Agent answers academic questions from knowledge base (RAG) and executes actions via MCP tools with correct student context
  3. Off-scope questions receive polite redirection; media messages receive creative rejection; failures trigger human intervention
  4. Prompt injection attempts are detected and neutralized without disrupting legitimate conversation
  5. Staff can see RAG debug info (chunks, scores) in chat logs; system logs capture full LangChain decision traceability
**Plans**: TBD

### Phase 21: Roles & Auth Expansion

**Goal**: Provider role exists with hierarchical management — provider manages staff, staff manages students — with dedicated Flutter screens
**Depends on**: Nothing (auth layer extension, independent)
**Requirements**: ROLE-01, ROLE-02, ROLE-03, ROLE-04, ROLE-05, ROLE-06, ROLE-07
**Success Criteria** (what must be TRUE):
  1. JWT token includes provider role; provider can log in and see provider-specific navigation
  2. Provider can CRUD staff members (cadastrar, editar, ativar/desativar, remover) with required fields
  3. Staff can CRUD students (cadastrar, editar, ativar/desativar, remover) with required fields
  4. Provider screen has 2 tabs (staff + aluno) with separate CRUD interfaces
**Plans**: TBD
**UI hint**: yes

### Phase 22: FCM Push Notifications

**Goal**: Students receive push notifications on their phone for key academic events, with tap-to-navigate functionality
**Depends on**: Nothing (can begin infrastructure in parallel; event triggers wire into existing services)
**Requirements**: FCM-01, FCM-02, FCM-03, FCM-04, FCM-05, FCM-06, FCM-07, FCM-08
**Success Criteria** (what must be TRUE):
  1. Flutter app registers FCM token on login and refreshes it automatically; backend stores tokens per device
  2. Push notification appears in phone notification bar when document is ready, enrollment confirmed, appointment confirmed, or new chat message received
  3. Notifications display correctly in both foreground and background states
  4. Tapping a notification navigates the user to the relevant screen in the app
**Plans**: TBD
**UI hint**: yes

### Phase 23: New Features

**Goal**: Students can view weekly meal menu, their academic profile, and class schedule calendar
**Depends on**: Nothing (independent screens with new backend endpoints)
**Requirements**: CARD-01, CARD-02, CARD-03, PERF-01, PERF-02, PERF-03, GRAD-01, GRAD-02, GRAD-03
**Success Criteria** (what must be TRUE):
  1. Staff/provider can create and edit the weekly meal menu (text per day); students see it with day-by-day navigation
  2. Student can view and edit app profile data (photo, name, notification preferences) and see academic data (RA, curso, período, campus, notas)
  3. Student sees weekly calendar with enrolled classes showing time, professor, and subject description
  4. All three new features are accessible from the main navigation
**Plans**: TBD
**UI hint**: yes

### Phase 24: UI Polish & Integration

**Goal**: Application presents a polished, cohesive experience with custom splash screen and consistent navigation after all corrections
**Depends on**: Phases 18, 19, 20, 21, 22, 23 (final validation layer)
**Requirements**: UIPOL-01, UIPOL-02, UIPOL-03
**Success Criteria** (what must be TRUE):
  1. App launches with custom Alpha Connect splash screen (not default Flutter splash)
  2. Staff/provider dashboard displays additional relevant metrics
  3. End-to-end navigation is coherent — every screen reachable, every action completes, no dead ends
**Plans**: TBD
**UI hint**: yes

---

## Progress

**Execution Order:**
- Group 1 (Corrections): Phase 18 ∥ Phase 19 (parallel)
- Group 2 (Improvements): Phase 20 ∥ Phase 21 ∥ Phase 22 (parallel)
- Group 3 (New Features): Phase 23 (internal parallelism across 3 sub-features)
- Group 4 (Polish): Phase 24 (after all above)

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 18. Student UX Corrections | v3.0 | 3/5 | In Progress|  |
| 19. Staff UX Corrections | v3.0 | 0/TBD | Not started | - |
| 20. LangChain Workflow | v3.0 | 0/TBD | Not started | - |
| 21. Roles & Auth Expansion | v3.0 | 0/TBD | Not started | - |
| 22. FCM Push Notifications | v3.0 | 0/TBD | Not started | - |
| 23. New Features | v3.0 | 0/TBD | Not started | - |
| 24. UI Polish & Integration | v3.0 | 0/TBD | Not started | - |

---

**Total project:** 24 phases across 3 milestones.
