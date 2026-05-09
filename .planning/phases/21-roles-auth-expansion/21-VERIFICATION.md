---
phase: 21-roles-auth-expansion
verified: 2026-05-09T03:53:28Z
status: human_needed
score: 5/7 must-haves verified
overrides_applied: 0
gaps:
  - truth: "Staff can CRUD students (cadastrar, editar, ativar/desativar, remover) with required fields"
    status: failed
    reason: "Alunos tab shows placeholder text only. Student CRUD was explicitly deferred to Phase 19 by context decision D-13, but ROADMAP SC-3 and requirements ROLE-04/ROLE-06 map this to Phase 21."
    artifacts:
      - path: "mobile/lib/features/staff/screens/staff_gestao_screen.dart"
        issue: "Alunos tab (line 59-61) renders placeholder 'Gestão de alunos será integrada em breve' — no student list, no CRUD"
    missing:
      - "Student CRUD Flutter UI in Gestao Alunos tab"
      - "Backend student CRUD endpoints accessible by staff (may already exist from prior phases)"
  - truth: "Provider screen has 2 tabs (staff + aluno) with separate CRUD interfaces"
    status: partial
    reason: "2 tabs exist (Staff + Alunos) and Staff tab has full CRUD. However, Alunos tab is a placeholder — only one of the two CRUDs is functional."
    artifacts:
      - path: "mobile/lib/features/staff/screens/staff_gestao_screen.dart"
        issue: "TabBarView has 2 children but second is placeholder Center(Text(...))"
    missing:
      - "Functional student CRUD interface in the Alunos tab"
human_verification:
  - test: "Log in as provider and verify 6-tab navigation renders correctly"
    expected: "All 6 tabs visible in bottom nav; tapping Gestão navigates to /staff/gestao"
    why_human: "Visual rendering of bottom nav with 6 icons — layout fit, icon visibility"
  - test: "Provider sees Staff tab with staff cards after API returns data"
    expected: "Cards display name, email, status badge (green Ativo / red Inativo), position"
    why_human: "Visual rendering of card layout, badge colors, spacing — depends on running app with data"
  - test: "Create, edit, and deactivate a staff member through the form"
    expected: "Form validates inputs, API calls succeed, list refreshes with updated data"
    why_human: "Full form interaction flow requires running app with backend connection"
---

# Phase 21: Roles & Auth Expansion Verification Report

**Phase Goal:** Provider role exists with hierarchical management — provider manages staff, staff manages students — with dedicated Flutter screens
**Verified:** 2026-05-09T03:53:28Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | JWT token includes provider role; provider can log in and see provider-specific navigation | ✓ VERIFIED | Login maps `staff.role=='provider'` to JWT `role='provider'` (routes.py:139); Router uses `isStaffOrProvider` guard (app_router.dart:82); StaffShell has 6 tabs |
| 2 | Provider can CRUD staff members with required fields (nome, email, celular, cargo, horário) | ✓ VERIFIED | 5 endpoints at /staff/members/* protected by require_provider(); StaffCreate schema has all fields; Flutter form has 6 fields with validation |
| 3 | Staff can CRUD students with required fields | ✗ FAILED | Alunos tab is placeholder only (D-13 explicitly deferred to Phase 19). No student CRUD UI exists in Phase 21 deliverables. |
| 4 | Provider screen has 2 tabs (staff + aluno) with separate CRUD interfaces | ⚠️ PARTIAL | 2 tabs exist structurally (TabBar with "Staff" + "Alunos"); Staff tab is full CRUD; Alunos tab is placeholder text. |
| 5 | Provider inherits all staff permissions | ✓ VERIFIED | `require_staff()` accepts `("staff", "provider")` (dependencies.py:163); `check_ownership()` bypasses for provider (line 146) |
| 6 | require_provider() blocks non-provider roles | ✓ VERIFIED | Strict `user.role != "provider"` check (dependencies.py:177); Used on all 5 CRUD endpoints |
| 7 | Provider cannot operate on their own record | ✓ VERIFIED | Self-check `staff_id == current_user_id` in update_staff (services.py:264) and soft_delete_staff (services.py:303) |

**Score:** 5/7 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `backend/alembic/versions/014_expand_staff_table_provider_role.py` | Migration adding provider role + new columns | ✓ VERIFIED | 96 lines, revision 014a, adds status/work_schedule/position, expands role CHECK to include 'provider', has downgrade() |
| `backend/src/shared/dependencies.py` | require_provider() + expanded require_staff() + check_ownership() | ✓ VERIFIED | All three functions present and correct (lines 139-180) |
| `backend/src/features/auth/routes.py` | Login flow mapping staff.role='provider' to JWT role='provider' | ✓ VERIFIED | Lines 138-139: `jwt_role = "provider" if staff.role == "provider" else "staff"` |
| `backend/src/features/auth/models.py` | Updated Staff model with new columns and CHECK constraint | ✓ VERIFIED | Staff has status, work_schedule, position columns; ck_staff_role includes 'provider'; ck_staff_status constrains active/inactive |
| `backend/src/features/staff/controllers.py` | 5 CRUD endpoints protected by require_provider() | ✓ VERIFIED | 147 lines, all 5 endpoints present with require_provider(user) guard |
| `backend/src/features/staff/schemas.py` | StaffCreate, StaffUpdate, StaffDetail, StaffListItem schemas | ✓ VERIFIED | All 4 schemas present with proper validation (role regex, email validation) |
| `backend/src/features/staff/services.py` | StaffManagementService with CRUD + security guards | ✓ VERIFIED | 313 lines, list (filters provider out), create (email unique check), update (self-edit block), soft_delete (self-deactivation block) |
| `mobile/lib/core/models/user_model.dart` | isProvider, isStaffOrProvider getters | ✓ VERIFIED | Lines 28-29: both getters present |
| `mobile/lib/core/router/route_names.dart` | staffGestao route constants | ✓ VERIFIED | RouteNames.staffGestao (line 26) and RoutePaths.staffGestao (line 56) |
| `mobile/lib/core/router/app_router.dart` | Router redirect using isStaffOrProvider, staffGestao route | ✓ VERIFIED | Line 82 uses isStaffOrProvider; line 223-225 defines staffGestao GoRoute |
| `mobile/lib/features/staff/screens/staff_shell.dart` | 6-tab StaffShell with Gestao at position 5 | ✓ VERIFIED | 6 _NavItem entries, 6 NavigationRailDestination entries, index 5 maps to staffGestao |
| `mobile/lib/features/staff/screens/staff_gestao_screen.dart` | Gestao screen with conditional TabBar for provider | ✓ VERIFIED | 532 lines, full CRUD UI with search, filter chips, cards, PopupMenuButton, AlertDialog |
| `mobile/lib/features/staff/models/staff_member_model.dart` | StaffMemberModel data class | ✓ VERIFIED | 39 lines with all fields, json_annotation, isActive getter |
| `mobile/lib/features/staff/services/staff_management_service.dart` | HTTP client for /staff/members endpoints | ✓ VERIFIED | 59 lines, 5 methods matching all backend endpoints |
| `mobile/lib/features/staff/providers/staff_management_provider.dart` | Riverpod providers for staff list state | ✓ VERIFIED | 68 lines, StaffMemberList notifier with setSearch, setStatusFilter, refresh, CRUD methods |
| `mobile/lib/features/staff/screens/staff_member_form_screen.dart` | Full-screen form for creating/editing staff | ✓ VERIFIED | 273 lines, 6 fields (name, email, phone, position, work_schedule, role dropdown), validation, error handling |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| auth/routes.py | auth/services/jwt_service.py | `issue_token_pair` with role='provider' | ✓ WIRED | Line 147: `jwt_service.issue_token_pair(user.id, role, ...)` where role can be 'provider' |
| shared/dependencies.py | All staff-protected endpoints | require_staff() accepting provider | ✓ WIRED | `("staff", "provider")` set membership at line 163 |
| staff/controllers.py | shared/dependencies.py | require_provider(user) on every endpoint | ✓ WIRED | 5 calls confirmed via grep (lines 76, 93, 109, 127, 144) |
| staff/services.py | auth/models.py | Staff model for DB queries | ✓ WIRED | `from src.features.auth.models import Staff` at line 16 |
| app_router.dart | user_model.dart | isStaffOrProvider for redirect | ✓ WIRED | Line 82: `user.isStaffOrProvider` |
| staff_shell.dart | route_names.dart | RoutePaths.staffGestao navigation | ✓ WIRED | Line 48: startsWith check, Line 65: context.go(RoutePaths.staffGestao) |
| staff_gestao_screen.dart | staff_management_provider.dart | ref.watch for staff list state | ✓ WIRED | Line 123: `ref.watch(staffMemberListProvider)` |
| staff_management_service.dart | Backend /staff/members | DioClient HTTP calls | ✓ WIRED | All 5 HTTP methods call `/staff/members` endpoint path |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|-------------------|--------|
| staff_gestao_screen.dart | staffMemberListProvider → members | StaffManagementService → DioClient → GET /staff/members | Yes — backend queries Staff table with SQLAlchemy | ✓ FLOWING |
| staff/controllers.py (list) | items, total from list_staff() | StaffManagementService → select(Staff).where(...) | Yes — SQLAlchemy select with pagination | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Backend modules import | `cd backend && python -c "from src.features.staff.controllers import staff_router"` | Requires async runtime (Docker-only) | ? SKIP |
| Generated Dart files exist | `ls mobile/lib/features/staff/models/staff_member_model.g.dart` | File exists | ✓ PASS |
| Generated provider files exist | `ls mobile/lib/features/staff/providers/staff_management_provider.g.dart` | File exists | ✓ PASS |

Step 7b: Behavioral spot-checks partially SKIPPED — backend requires Docker runtime with asyncpg/postgres; Flutter requires device/emulator. Static analysis checks confirm file structure is valid.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| ROLE-01 | Plan 01, 03 | Role provider adicionada ao sistema JWT | ✓ SATISFIED | Staff.role CHECK includes 'provider'; JWT role='provider' mapped in login flow |
| ROLE-02 | Plan 01, 03 | Provider herda funcionalidades do staff | ✓ SATISFIED | require_staff() accepts ('staff', 'provider'); check_ownership() bypasses for provider |
| ROLE-03 | Plan 02, 04 | Provider pode cadastrar, editar, ativar/desativar e remover staff | ✓ SATISFIED | 5 CRUD endpoints with full Flutter UI |
| ROLE-04 | **NONE** | Staff pode cadastrar, editar, ativar/desativar e remover students | ✗ ORPHANED | Not claimed by any plan in Phase 21. Student CRUD deferred to Phase 19 by D-13. |
| ROLE-05 | Plan 03, 04 | Tela de cadastro Provider com 2 tabs (staff + aluno) e CRUDs separados | ⚠️ PARTIAL | 2 tabs exist; Staff CRUD complete; Alunos CRUD is placeholder |
| ROLE-06 | **NONE** | Staff cadastra aluno com: nome, email, celular, endereço, RA, período, campus | ✗ ORPHANED | Not claimed by any plan. Student creation form not implemented. |
| ROLE-07 | Plan 02, 04 | Provider cadastra staff com: nome, email, celular, cargo/função, horário de trabalho | ✓ SATISFIED | StaffCreate schema + form have all required fields |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| staff_gestao_screen.dart | 59-61 | Placeholder text "Gestão de alunos será integrada em breve" | ℹ️ Info | Intentional per D-13; Phase 19 scope. Does not block staff CRUD goal. |
| staff_gestao_screen.dart | 80-81 | Staff view placeholder "Gestão de alunos será integrada em breve" | ℹ️ Info | Same — intentional deferral to Phase 19 |

### Human Verification Required

### 1. Provider Login & Navigation Flow

**Test:** Log in with a provider account (staff.role='provider') and observe navigation
**Expected:** App navigates to /staff (not /client), 6-tab bottom nav visible, tapping "Gestão" tab shows TabBar with "Staff" and "Alunos" tabs
**Why human:** Visual rendering of navigation elements, tab switching animation, icon layout with 6 items

### 2. Staff List Card Rendering

**Test:** With staff members in the database, open the Staff tab within Gestão
**Expected:** Cards show avatar initial, name (bold), email, position (if set), colored status badge (green "Ativo" / red "Inativo"), PopupMenuButton
**Why human:** Visual appearance of cards, color accuracy, text overflow handling, dark/light mode

### 3. Staff CRUD Full Lifecycle

**Test:** Create a staff member via FAB → fill form → submit; Edit via card tap; Deactivate via PopupMenu → AlertDialog
**Expected:** All operations succeed with appropriate SnackBar feedback; list refreshes after each operation
**Why human:** End-to-end form interaction, API integration, state refresh timing, AlertDialog UX

### Gaps Summary

Two requirements (ROLE-04, ROLE-06) mapped to Phase 21 in the ROADMAP were not implemented. The context decisions (D-11, D-13) explicitly state student CRUD UI is Phase 19 scope. This creates a **roadmap-to-context misalignment**: the ROADMAP lists 7 ROLE requirements for Phase 21 but the discuss-phase decisions deferred 2 of them.

**Root cause:** The ROADMAP's success criteria #3 ("Staff can CRUD students with required fields") and requirement mapping (ROLE-04, ROLE-06 → Phase 21) conflict with the context decisions (D-13: "Phase 21 only delivers the 'Staff' tab fully functional. 'Alunos' tab = placeholder pending Phase 19 integration").

**Impact:** The staff-management goal (provider manages staff) is **fully achieved**. The student-management goal (staff manages students) is **explicitly deferred** and structurally prepared (tab exists, will be populated by Phase 19).

**Recommendation:** Either:
1. Move ROLE-04 and ROLE-06 to Phase 19 in REQUIREMENTS.md (aligns with D-13 decision), OR
2. Accept via override that these are intentionally deferred per context decisions

The core value of Phase 21 — provider role with hierarchical staff management — is delivered.

---

_Verified: 2026-05-09T03:53:28Z_
_Verifier: the agent (gsd-verifier)_
