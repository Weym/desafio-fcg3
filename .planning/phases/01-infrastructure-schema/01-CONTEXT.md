# Phase 1: Infrastructure & Schema - Context

**Gathered:** 2026-04-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver the four-service Docker Compose stack (postgres+pgvector, fastapi-app, langchain-service, mcp-server) running with healthchecks, all 17 database tables created via Alembic migrations, environment configuration documented, and curriculum seed data loaded — ready for Phase 2 (Authentication) to build on.

</domain>

<decisions>
## Implementation Decisions

### Seed Data Scope
- **D-01:** Seed script creates curriculum AND sample users. Beyond the core curriculum (8 períodos, ~40 disciplinas), seed 3-5 sample students at different semesters, 2 staff members, and one active enrollment period.
- **D-02:** Curriculum modeled after USP ICMC (São Carlos) Ciência da Computação program — use real discipline names, credit hours, and prerequisite chains from that program.
- **D-03:** Sample students include academic history — grades for completed courses, some in-progress enrollments. This enables immediate testing of CRA calculation, prerequisite validation, and enrollment flows from Phase 2/3 onward.
- **D-04:** Seed script is destructive (drop + recreate) — truncates seed-targeted tables and reinserts. Guarantees clean, repeatable state. No idempotency logic needed.

### Local Development Workflow
- **D-05:** Docker Compose uses volume mounts for source code with hot-reload. All three Python services run with `uvicorn --reload` (or equivalent) so code changes reflect immediately without rebuild.
- **D-06:** Each service has its own `requirements.txt` in its directory (`backend/requirements.txt`, `ai_service/requirements.txt`, `mcp_server/requirements.txt`). Keeps images lean — MCP server doesn't install LangChain deps, etc.
- **D-07:** One Dockerfile per service directory. Each service builds independently from its own Dockerfile.
- **D-08:** For Phase 1, LangChain and MCP service containers run a minimal healthcheck stub (tiny FastAPI app returning 200 on `/health`). Actual implementation comes in Phases 4-5. This keeps `docker compose up` working with all 4 containers healthy.

### Migration Granularity
- **D-09:** Alembic migrations are domain-grouped:
  - Migration #001: `CREATE EXTENSION IF NOT EXISTS vector` (pgvector — MUST be first)
  - Migration #002: Auth tables (students, staff, verification_codes, sessions, fcm_tokens)
  - Migration #003: Curriculum tables (courses, prerequisites, curriculum, curriculum_courses)
  - Migration #004: Enrollment tables (enrollment_periods, enrollments, enrollment_courses, grades)
  - Migration #005: Documents + Scheduling (documents, scheduling_slots, appointments)
  - Migration #006: Chat + Knowledge Base (chat_sessions, chat_messages, mcp_action_logs, knowledge_base_chunks)
- **D-10:** Migrations use SQLAlchemy ORM models with `alembic revision --autogenerate`. Models are the single source of truth for schema.
- **D-11:** SQLAlchemy models organized per-feature: `features/auth/models.py`, `features/enrollment/models.py`, etc. A central import module aggregates all models for Alembic autogenerate discovery.

### Agent's Discretion
- Migration execution strategy (auto on container start vs manual `alembic upgrade head`) — agent decides based on what's simplest for development.
- PostgreSQL port exposure on localhost — agent decides based on debugging convenience vs isolation.
- Exact entrypoint script structure for containers.
- Alembic `env.py` async configuration details (asyncpg driver setup).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Database Schema
- `docs/database.md` — Full schema definition for all 17 tables, columns, types, constraints, indexes, ERD, and seed data examples. This is the authoritative source for table structure.

### Architecture & Docker Topology
- `docs/architecture.md` — C4 diagrams (context + container), Docker container layout (4 services, 2 networks, port mappings), service communication patterns.

### API Surface (for understanding table relationships)
- `docs/api.md` — REST endpoint specifications. Relevant for understanding how tables map to API resources.

### MCP Protocol (for understanding mcp_action_logs schema)
- `docs/mcp.md` — MCP server protocol, tool schemas, logging behavior. Defines the structure that `mcp_action_logs` table must support.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- No existing Python code to reuse — all backend directories contain only `.gitkeep` scaffolding.
- `docker-compose.yml` exists at root but is empty — ready to be written.
- `backend/src/main.py` exists but is empty — ready for FastAPI app setup.

### Established Patterns
- Vertical slice architecture: each feature owns `controllers/`, `services/`, `routes.py` under `backend/src/features/[name]/`.
- Infrastructure code (DB connections, settings) goes in `backend/src/infrastructure/`.
- Shared cross-feature code (middleware, base schemas) goes in `backend/src/shared/`.

### Integration Points
- `backend/src/features/auth/` and `backend/src/features/enrollment/` directories already scaffolded.
- `ai_service/` and `mcp_server/` directories need to be created at project root level.
- Alembic configuration will live in `backend/` (alongside `alembic.ini` and `alembic/` directory).

</code_context>

<specifics>
## Specific Ideas

- USP ICMC (São Carlos) CC program as curriculum reference — look up the actual grade curricular for discipline names, credit weights, and prerequisite chains.
- Sample students should span different semesters (e.g., 2o, 4o, 6o, 8o período) with realistic academic histories — some approved, some failed, some in-progress courses.
- Destructive seed script means developers can always `python scripts/seed.py` to reset to a known good state during development.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 01-infrastructure-schema*
*Context gathered: 2026-04-20*
