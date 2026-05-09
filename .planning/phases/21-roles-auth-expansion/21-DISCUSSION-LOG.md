# Phase 21: Roles & Auth Expansion - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-08
**Phase:** 21-roles-auth-expansion
**Areas discussed:** Role architecture, Provider screen & navigation, CRUD interface & forms, Permission hierarchy

---

## Role Architecture

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Same staff table, new value in staff.role column | Provider lives in staff table with role='provider'. Login maps to JWT role. | ✓ |
| Separate providers table | New table with own schema. More isolation but more complexity. | |

**User's choice:** Same staff table
**Notes:** Simplest migration path, provider is just another staff.role value.

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Distinct 'provider' JWT role | JWT has role='provider'. Three values: student/staff/provider. | ✓ |
| JWT stays 'staff', use permissions | All staff-table users get role='staff'. Backend checks sub-role for operations. | |

**User's choice:** Distinct JWT role
**Notes:** Aligns with ROLE-01 requirement explicitly stating "student/staff/provider".

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Provider passes require_staff() | Expand check to accept both roles. Add separate require_provider(). | ✓ |
| Separate guards only | Keep require_staff() strict. Each endpoint declares allowed roles explicitly. | |

**User's choice:** Provider passes require_staff()
**Notes:** Consistent with ROLE-02 (provider inherits all staff capabilities).

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Provider uses user_type='staff' in sessions | Keep sessions simpler. JWT role distinguishes, not session record. | ✓ |
| Add 'provider' to user_type CHECK | Three-value constraint. More explicit at DB level. | |

**User's choice:** Provider uses user_type='staff'
**Notes:** Avoids unnecessary migration on sessions table.

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Yes, provider bypasses check_ownership() | Same as staff — consistent with total inheritance. | ✓ |
| Provider has different ownership rules | More restricted. | |

**User's choice:** Provider bypasses
**Notes:** ROLE-02 total inheritance.

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Only 'provider' gets distinct JWT role | coordinator/secretary/staff all get JWT role='staff'. Only provider maps differently. | ✓ |
| Sub-roles affect permissions too | Each staff.role maps to different capabilities. | |

**User's choice:** Only provider gets distinct JWT role
**Notes:** Keeps authorization simple — sub-roles are informational, not auth-affecting.

---

## Provider Screen & Navigation

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Reuse StaffShell + add management tab | Provider sees same 5-tab StaffShell + 6th "Gestao" tab. No new shell. | ✓ |
| Separate ProviderShell | New shell with different layout. More work. | |
| StaffShell with conditional tabs | Same widget, show/hide based on role. | |

**User's choice:** Reuse StaffShell + add management tab
**Notes:** Both staff AND provider get the 6th tab. Difference is internal content.

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Full-screen page with TabBar | Management screen is its own page with top TabBar (Staff + Alunos). | ✓ |
| Two separate bottom nav tabs | Replace existing tabs. Messier. | |

**User's choice:** Full-screen page with TabBar
**Notes:** Staff sees only student list (no TabBar). Provider sees TabBar with both tabs.

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| isStaffOrProvider getter | Add isProvider, isStaffOrProvider. Router uses latter. Shell checks former for conditional UI. | ✓ |
| Treat provider as staff for routing | Modify isStaff to include provider. Loses distinction. | |

**User's choice:** isStaffOrProvider getter
**Notes:** Maintains clean separation in UserModel.

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Last position (6th tab) | Gestao at the end. Keeps existing order. | ✓ |
| First position | Changes all existing navigation muscle memory. | |

**User's choice:** Last position

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Accept 6 tabs | Icons smaller but all accessible. | ✓ |
| Drawer for overflow | Hides functionality. | |
| Consolidate tabs | Merges existing features. | |

**User's choice:** Accept 6 tabs

---

## CRUD Interface & Forms

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Full-screen dedicated page | FAB → new page with form, AppBar + Save button. | ✓ |
| Bottom sheet | Sheet rises with fields. Less space for 7+ fields. | |

**User's choice:** Full-screen page
**Notes:** More space for all fields and validation messages.

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Simple AlertDialog confirmation | Text + Cancel/Confirm buttons. Same pattern as Phase 9. | ✓ |
| Swipe-to-delete with undo | Fluid but risky for important actions. | |

**User's choice:** AlertDialog

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Cards with summary info + quick actions | Nome, email, status badge. Tap → detail. | ✓ |
| Simple ListTile | More compact. | |

**User's choice:** Cards

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| SearchBar + filter chips (Todos/Ativos/Inativos) | Text search + status filter combined. | ✓ |
| Text search only | Simpler but less functional. | |

**User's choice:** SearchBar + filter chips

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Soft delete (status = 'inactive') | Same pattern as students. Preserves data. Can reactivate. | ✓ |
| Hard delete | Irreversible. | |

**User's choice:** Soft delete
**Notes:** Consistent with student pattern.

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Free text field | String field, user types "08:00-17:00 Seg-Sex". | ✓ |
| Structured fields | Separate hour/day fields. More complex. | |

**User's choice:** Free text
**Notes:** Avoids parsing complexity.

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Separate `position` field (text) | Role column = auth level. Position = displayable cargo. | ✓ |
| Use existing role column as cargo | Role does double duty. | |

**User's choice:** Separate position field
**Notes:** Clean separation of auth concerns from display metadata.

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| All table columns in form | Full form with all fields. | ✓ |
| Only ROLE-06 fields | Subset of fields. | |

**User's choice:** All table columns

---

**User clarification:** Student CRUD UI is being done in Phase 19 (parallel, another machine). Phase 21 only delivers Staff tab + backend role changes. Alunos tab is placeholder.

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Only backend + Staff tab this phase | Phase 21: provider role + staff CRUD. Alunos tab integration deferred. | ✓ |
| Create placeholder tab | Structure with placeholder. | |
| Create both tabs fully | May conflict with Phase 19. | |

**User's choice:** Only backend + Staff tab

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Full REST CRUD | GET list, GET detail, POST, PUT, DELETE. All require_provider(). | ✓ |
| Include extra endpoints (PATCH status) | Separate activate/deactivate endpoint. | |

**User's choice:** Standard CRUD

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| POST /staff enables login immediately | Email in staff table = can do OTP. No extra step. | ✓ |
| Invite flow (email + confirmation) | More secure but more complex. | |

**User's choice:** Immediate login enabled

---

## Permission Hierarchy

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Multiple providers, cannot manage each other | Several providers exist but don't manage each other. | |
| Provider unique (super admin) | Only 1 exists. Created via seed. No create endpoint. | ✓ |
| Providers manage all (including other providers) | Flat hierarchy among providers. | |

**User's choice:** Provider unique (super admin)
**Notes:** Simplest model. No provider management needed.

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Cannot self-deactivate | Endpoint blocks PUT/DELETE on own ID. | ✓ |
| Can self-deactivate | No restriction. Use seed to recover. | |

**User's choice:** Cannot self-deactivate
**Notes:** Prevents accidental lock-out.

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Total inheritance | Provider accesses ALL staff screens + Gestao. | ✓ |
| Partial inheritance | Provider only gets management, not operations. | |

**User's choice:** Total inheritance
**Notes:** Aligns with ROLE-02.

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Provider hidden from GET /staff list | Filter WHERE role != 'provider'. | ✓ |
| Provider visible but without actions | Shows in list, buttons disabled. | |

**User's choice:** Hidden from list
**Notes:** Clean UX — provider doesn't appear as manageable entity.

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Seed data with fixed provider | Alembic seed creates provider record. Email via env var or hardcoded for dev. | ✓ |
| Separate CLI command | More infrastructure. | |

**User's choice:** Seed data

---

## Agent's Discretion

- Loading skeleton/shimmer for staff list
- Empty state design
- Card dimensions, spacing, icons
- FAB icon for "create staff"
- Pagination strategy
- Validation rules detail
- How inactive staff login attempt is handled

## Deferred Ideas

- Student CRUD UI in Gestao tab — Phase 19 delivers this
- Provider management endpoint — not needed (seed-only)
- Granular permissions per staff sub-role — not MVP
