# Phase 3: Business Feature Slices - Context

**Gathered:** 2026-04-20
**Status:** Ready for planning

<domain>
## Phase Boundary

All FastAPI business endpoints operational, role-gated, and IDOR-safe — providing the complete API surface that the MCP server will proxy in Phase 4. Covers 7 feature slices: Students, Courses & Curriculum, Enrollment, Grades, Documents, Appointments, Staff Dashboard. 36 requirements (STU-01 through STAFF-01).

</domain>

<decisions>
## Implementation Decisions

### Infraestrutura Compartilhada
- **D-01:** Build complete shared infrastructure BEFORE feature slices — Plan 3.0. Includes: PaginationParams dependency, paginated response schema, standard exception handlers (404, 409, 422), base service with list/get/create/update methods, dual-auth dependency. All 7 feature slices reuse these patterns from day one.
- **D-02:** Dual-auth implemented as a single `get_current_user_or_service()` dependency with fallback — tries JWT Bearer first, if not present tries X-Service-Token. Returns user context in both cases. MCP-accessible endpoints use this dependency; JWT-only endpoints use `get_current_user()`.
- **D-03:** API language: error codes e messages tudo em portugues. Codes usam SCREAMING_SNAKE_CASE em portugues (ex: `PERIODO_MATRICULA_FECHADO`, `PREREQUISITO_NAO_CUMPRIDO`). Messages descritivas em portugues.

### Protecao contra IDOR
- **D-04:** Agent's discretion on IDOR check implementation approach — service-level check vs generic dependency. The agent chooses the most secure and maintainable pattern for FastAPI.
- **D-05:** Same ownership check for both JWT and X-Service-Token requests. Defense in depth — even when MCP injects student_id, the service layer still verifies ownership. No shortcut for service token.
- **D-06:** Role-based bypass for staff. If `role == staff`, ownership check is skipped — staff can access any student's resources. If `role == student`, standard ownership check applies (resource.student_id == current_user_id).

### Calculo do CRA
- **D-07:** CRA calculation at service-level in Python, not SQL. Fetch grades + courses (for credits) from DB, calculate in service layer. More testable (unit tests for GRADES-03/TEST-03), more readable, easier to debug.
- **D-08:** Include only grades with `final_grade IS NOT NULL` in CRA. Grades without a final grade (in-progress, locked courses) are excluded. Division by zero protection: if no completed grades, return CRA = 0.0.

### Modelo de Scheduling Slots
- **D-09:** Scheduling slots belong to resources (`scheduling_slots.resource_id` FK -> `resources`), as defined in `docs/database.md`. Keep the schema as-is. API layer adapts response to show resource information. The `resources` table can represent staff members, rooms, or other bookable entities.
- **D-10:** SELECT FOR UPDATE for appointment booking. Pessimistic lock on the slot during the booking transaction. Two students cannot reserve the same slot simultaneously. Appropriate for MVP academic volume.

### Lifecycle da Matricula
- **D-11:** Lock operates at TWO levels: (a) `POST /enrollments/{id}/lock` sets the entire enrollment to `locked` status and all associated enrollment_courses to locked; (b) individual enrollment_courses can also be locked independently (trancamento por disciplina). Both are irreversible in MVP.
- **D-12:** Course drop (DELETE /enrollments/{id}/courses/{cid}) only allowed while enrollment is in `draft` status. After confirmation, the student must use lock (trancamento) instead of drop.
- **D-13:** Enrollment outside active period returns `409 Conflict` with error code `PERIODO_MATRICULA_FECHADO`. Prerequisite failure returns `409 Conflict` with error code `PREREQUISITO_NAO_CUMPRIDO`.

### Feature Slice Ordering
- **D-14:** Implementation order: Plan 3.0 (shared infra) -> Plan 3.1 (Students) -> Plan 3.2 (Courses/Curriculum) -> Plan 3.3 (Enrollment) -> Plan 3.4 (Grades) -> Plan 3.5 (Documents) -> Plan 3.6 (Appointments) -> Plan 3.7 (Staff Dashboard). Shared infra first ensures all slices start with correct patterns. Natural dependency chain: enrollment needs courses, grades need enrollment.

### Agent's Discretion
- IDOR check implementation pattern (service-level vs generic dependency)
- Prerequisite validation approach for enrollment (recursive CTE vs iterative Python)
- Base CRUD service class design and method signatures
- Exact PaginationParams implementation (query params, defaults)
- Individual endpoint implementation details within each slice

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### API Contract
- `docs/api.md` — Full REST endpoint specifications for all 36 requirements. Request/response shapes, error codes, HTTP status mappings, pagination format, filtering params. Defines which endpoints accept X-Service-Token (marked "Aceita X-Service-Token (MCP)").

### Database Schema
- `docs/database.md` — Authoritative schema for all 17 tables. Column types, constraints, indexes, foreign keys, ERD. Critical for: `scheduling_slots.resource_id` FK -> `resources` (D-09), `grades` table structure for CRA (D-08), `enrollment_courses.status` lifecycle.

### MCP Tool Mapping
- `docs/mcp.md` — 16 MCP tools and which FastAPI endpoints they call. Defines which endpoints must support dual-auth (X-Service-Token). Critical for Plan 3.0 dual-auth dependency design.

### Architecture
- `docs/architecture.md` — C4 diagrams, Docker topology, service communication patterns. Establishes vertical slice architecture, async-first patterns.

### Phase Dependencies
- `.planning/phases/01-infrastructure-schema/01-CONTEXT.md` — D-09/D-10/D-11: Migration grouping, ORM models per-feature, central model import. D-01/D-03: Seed data includes sample students, staff, enrollment period.
- `.planning/phases/02-authentication/02-CONTEXT.md` — D-02/D-05: JWT with enriched payload (sub=user_id, role, jti). D-12: In-memory rate limiting. Dual-auth middleware (JWT + X-Service-Token) designed in Phase 2.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- No existing Python code — all backend directories contain only `.gitkeep` scaffolding. Phase 1 and Phase 2 must be completed first.
- `backend/src/features/auth/` and `backend/src/features/enrollment/` directories already scaffolded.
- New feature directories to create: `students/`, `courses/`, `grades/`, `documents/`, `appointments/`, `staff/`.

### Established Patterns
- Vertical slice architecture: each feature owns `controllers/`, `services/`, `routes.py` under `backend/src/features/{name}/`.
- SQLAlchemy ORM models as single source of truth (from Phase 1 D-10).
- Settings via Pydantic BaseSettings — never inline `os.getenv()`.
- Error response shape: `{"error": {"code": "...", "message": "...", "details": [...]}}`.
- All FastAPI route handlers must be `async def`.
- Standard pagination: `?page=1&per_page=20` with `{"data": [...], "pagination": {...}}` response.

### Integration Points
- `backend/src/main.py` — FastAPI app entry point, route registration.
- `backend/src/shared/` — Auth middleware (get_current_user, require_role) from Phase 2. Plan 3.0 adds pagination, error handlers, base CRUD, dual-auth dependency here.
- `backend/src/infrastructure/` — DB session factory (async SQLAlchemy + asyncpg), settings.
- 16 endpoints marked in docs/api.md as MCP-accessible need `get_current_user_or_service()` dependency.

</code_context>

<specifics>
## Specific Ideas

- Error codes in Portuguese (SCREAMING_SNAKE_CASE) to maintain consistency with an all-PT-BR system. Examples: `PERIODO_MATRICULA_FECHADO`, `PREREQUISITO_NAO_CUMPRIDO`, `MATRICULA_JA_CONFIRMADA`, `ALUNO_NAO_ENCONTRADO`.
- Lock at two levels mirrors real Brazilian university trancamento: trancamento total (semestre) and trancamento parcial (disciplina individual).
- Resources table for scheduling is intentionally generic — can represent staff, rooms, or other bookable entities. This provides flexibility for future expansion without schema changes.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 03-business-feature-slices*
*Context gathered: 2026-04-20*
