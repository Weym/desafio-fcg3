# Phase 21: Roles & Auth Expansion - Context

**Gathered:** 2026-05-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Add provider role with hierarchical management. Provider (unique super admin) manages staff; staff manages students. Deliver: backend provider role in JWT, staff CRUD endpoints, Flutter navigation expansion (6th tab "Gestao" with staff management screen). Student CRUD UI is out of scope (handled by Phase 19 in parallel).

</domain>

<decisions>
## Implementation Decisions

### Role Architecture

- **D-01:** Provider lives in the existing `staff` table with `staff.role = 'provider'`. No new table.
- **D-02:** JWT gets distinct `role = 'provider'` — three possible values: `student | staff | provider`.
- **D-03:** Login flow: find user in staff table → if `staff.role == 'provider'` → JWT role = `'provider'`, else → JWT role = `'staff'`. Coordinator/secretary get JWT `role = 'staff'`.
- **D-04:** `require_staff()` expands to accept `role in ('staff', 'provider')`. Provider inherits ALL staff endpoints.
- **D-05:** New `require_provider()` dependency for provider-only endpoints (staff CRUD).
- **D-06:** `check_ownership()` bypasses for both `role == 'staff'` and `role == 'provider'`.
- **D-07:** `sessions.user_type` stays `'staff'` for providers — no migration needed on sessions table.
- **D-08:** Migration adds `'provider'` to `staff.role` CHECK constraint: `('staff', 'coordinator', 'secretary', 'provider')`.

### Provider Screen & Navigation

- **D-09:** Provider reuses existing StaffShell — no separate ProviderShell.
- **D-10:** StaffShell expands to 6 tabs for BOTH staff and provider. 6th tab = "Gestao" at last position.
- **D-11:** Staff sees Gestao tab with student list directly (no TabBar) — BUT student CRUD UI is Phase 19's scope. Phase 21 creates the tab structure.
- **D-12:** Provider sees Gestao tab with top TabBar: "Staff" + "Alunos" tabs.
- **D-13:** Phase 21 only delivers the "Staff" tab fully functional. "Alunos" tab = placeholder pending Phase 19 integration.
- **D-14:** Accept 6 tabs in bottom nav (icons smaller but all accessible).
- **D-15:** `UserModel`: add `isProvider => role == 'provider'` and `isStaffOrProvider => isStaff || isProvider`. Router uses `isStaffOrProvider` for redirect. StaffShell checks `isProvider` for conditional TabBar.

### Staff CRUD Backend

- **D-16:** Endpoints: `GET /staff` (paginated list), `GET /staff/{id}`, `POST /staff`, `PUT /staff/{id}`, `DELETE /staff/{id}` (soft delete). All protected by `require_provider()`.
- **D-17:** `GET /staff` filters `WHERE role != 'provider'` — provider hidden from management list.
- **D-18:** `POST /staff` only creates `role: 'staff' | 'coordinator' | 'secretary'` — never provider.
- **D-19:** Creating staff via `POST /staff` immediately enables OTP login (email exists in staff table = can authenticate).
- **D-20:** Staff "remove" = soft delete (`status = 'inactive'`). Inactive staff cannot log in. Can be reactivated.
- **D-21:** Endpoint blocks operations (PUT/DELETE) on the provider's own ID — prevents self-deactivation.

### Staff Table Migration

- **D-22:** Add `status` column (VARCHAR, CHECK: 'active', 'inactive', default 'active').
- **D-23:** Add `work_schedule` column (TEXT, free-form string for "horario de trabalho").
- **D-24:** Add `position` column (VARCHAR, cargo/funcao displayable — separate from auth `role` column).
- **D-25:** Add `'provider'` to existing `staff.role` CHECK constraint.

### Staff CRUD Flutter UI

- **D-26:** List = cards with nome, email, status badge (colored), position. Tap opens detail/edit.
- **D-27:** SearchBar at top + filter chips (Todos, Ativos, Inativos).
- **D-28:** FAB opens full-screen dedicated page for creating new staff member.
- **D-29:** Form fields: all staff table columns (nome, email, phone, position, work_schedule, role dropdown for staff/coordinator/secretary).
- **D-30:** Destructive actions (deactivate, remove) use simple AlertDialog confirmation.

### Permission Hierarchy

- **D-31:** Provider is unique super admin — only 1 exists, created via seed data (Alembic seed script).
- **D-32:** No endpoint to create providers. Provider record managed only at database/seed level.
- **D-33:** Provider has total inheritance — accesses all staff screens (Dashboard, Agenda, Intervencao, Docs, Recursos) + Gestao.

### Agent's Discretion

- Loading skeleton/shimmer for staff list during fetch
- Empty state design for staff list when no staff members exist
- Exact card dimensions, spacing, icons
- FAB icon choice for "create staff"
- Pagination strategy for staff list (infinite scroll vs page numbers)
- Validation rules detail (email format, phone format, required fields)
- How inactive staff login attempt is handled (generic error vs specific message)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Auth System (Foundation)

- `backend/src/features/auth/routes.py` — Login flow that determines JWT role from staff.role column. Lines 124-141 need modification for provider role mapping.
- `backend/src/shared/auth.py` — `get_current_user`, `require_role()` (strict equality, needs expansion), `require_service_token`
- `backend/src/shared/dependencies.py` — `require_staff()` (line 155-166, needs expansion to accept provider), `check_ownership()` (line 146-147, needs expansion), `UserContext`
- `backend/src/features/auth/services/jwt_service.py` — Token issuance (role claim)

### Database Models

- `backend/src/features/auth/models.py` — Staff model definition (lines 48-63: id, name, email, phone, role with CHECK constraint, created_at, updated_at). Needs new columns: status, work_schedule, position.
- `docs/database.md` — Authoritative schema reference

### Existing Student CRUD (Pattern Reference)

- `backend/src/features/students/controllers.py` — Full CRUD reference implementation (GET list/detail, POST, PUT, DELETE soft-delete). Staff CRUD should follow same patterns.
- `backend/src/features/students/schemas.py` — Pydantic schema patterns for create/update/response

### Flutter Navigation & Staff Shell

- `mobile/lib/core/router/app_router.dart` — GoRouter redirect logic (lines 65-85). Needs `isStaffOrProvider` check.
- `mobile/lib/core/models/user_model.dart` — UserModel with isStudent/isStaff getters. Needs isProvider, isStaffOrProvider.
- `mobile/lib/features/staff/screens/staff_shell.dart` — StaffShell BottomNavigationBar (5 tabs → 6 tabs, conditional Gestao content).
- `mobile/lib/core/router/route_names.dart` — Route path constants (needs new Gestao route).

### Phase 2 Context (Auth Decisions)

- `.planning/phases/02-authentication/02-CONTEXT.md` — D-05 (JWT payload: sub, role, jti, name, email), D-09 (user lookup queries both tables), D-06 (sub = user_id UUID directly)

### Phase 9 Context (Staff Interface Patterns)

- `.planning/phases/09-staff-interface/09-CONTEXT.md` — Data layer pattern, filter chips, FAB pattern, StaffShell tab structure

### API Documentation

- `docs/api.md` — Endpoint specifications and response shapes. Staff CRUD endpoints not documented yet — will need to follow existing patterns.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **Student CRUD** (`backend/src/features/students/controllers.py`): Full CRUD with pagination, soft delete, search. Staff CRUD should mirror this pattern exactly.
- **Student schemas** (`backend/src/features/students/schemas.py`): Pydantic models for create/update/response — copy pattern for staff schemas.
- **StaffShell** (`mobile/lib/features/staff/screens/staff_shell.dart`): 5-tab BottomNavigationBar. Needs expansion to 6 tabs with conditional content.
- **DioClient** (`mobile/lib/core/network/dio_client.dart`): Configured HTTP client with auth interceptor.
- **Client data layer** (`mobile/lib/features/client/`): Model → Service → Provider → Screen pattern. Reference for staff management screen.
- **Filter chips pattern**: Already used in staff documents (toggle behavior). Reuse for Gestao list.

### Established Patterns

- **Vertical slice**: Each feature owns controllers, services, routes under `backend/src/features/{feature}/`
- **Riverpod + code gen**: `@riverpod` annotations + `.g.dart` files
- **GoRouter sub-routes**: Detail screens as sub-routes (e.g., `/staff/gestao/:staffId`)
- **Soft delete pattern**: Students use `status = 'inactive'`. Staff will follow same pattern.
- **Pagination**: Students endpoint has page/per_page/sort_by/order params. Staff CRUD should match.

### Integration Points

- **Auth routes** (`backend/src/features/auth/routes.py`): Login verification must add provider role check
- **Shared auth** (`backend/src/shared/auth.py`, `dependencies.py`): require_staff, check_ownership must expand
- **App router** (`mobile/lib/core/router/app_router.dart`): Redirect logic must handle provider
- **Staff shell** (`mobile/lib/features/staff/screens/staff_shell.dart`): Tab count must be dynamic
- **Alembic migrations**: New migration for staff table columns + role CHECK update

</code_context>

<specifics>
## Specific Ideas

- Provider is a singular super-admin created via seed — not self-service, not multi-tenant.
- Staff.role column has dual purpose: auth-relevant ('provider' → distinct JWT role) AND organizational (staff/coordinator/secretary → same JWT 'staff' role but different positions).
- The `position` field is the human-readable "cargo/funcao" — completely separate from the `role` column used for auth.
- Staff CRUD endpoints mirror student CRUD exactly for consistency. Same pagination params, same response shapes, same error patterns.
- The 6th tab is visible to both staff and provider — the difference is WHAT they see inside (staff = student list when Phase 19 integrates; provider = TabBar with Staff + Alunos).

</specifics>

<deferred>
## Deferred Ideas

- Student CRUD UI in Gestao tab — Phase 19 delivers this, integration comes later
- Provider management endpoint (create/edit provider) — no need, provider is seed-only
- Granular permissions per staff sub-role (coordinator vs secretary) — not needed for MVP

</deferred>

---

_Phase: 21-roles-auth-expansion_
_Context gathered: 2026-05-08_
