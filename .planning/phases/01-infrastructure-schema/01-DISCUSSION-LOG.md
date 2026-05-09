# Phase 1: Infrastructure & Schema - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-20
**Phase:** 01-infrastructure-schema
**Areas discussed:** Seed data scope, Local dev workflow, Migration granularity

---

## Seed Data Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Curriculum + sample users | Seed curriculum PLUS 3-5 sample students, 2 staff, one active enrollment period | ✓ |
| Curriculum only | Seed just curriculum, courses, and prerequisites per INFRA-04 | |
| You decide | Agent's discretion | |

**User's choice:** Curriculum + sample users
**Notes:** User wants Phase 2 to be able to test against real data immediately.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Realistic fictional | Generic CC curriculum | |
| Based on a real program | Model after a specific university | ✓ |
| You decide | Agent picks | |

**User's choice:** Based on a real program

---

| Option | Description | Selected |
|--------|-------------|----------|
| USP (ICMC) | CC do ICMC/USP São Carlos | ✓ |
| UFMG | CC da UFMG | |
| UNICAMP | CC da UNICAMP | |

**User's choice:** USP (ICMC)

---

| Option | Description | Selected |
|--------|-------------|----------|
| With academic history | Students with grades, passed courses, some in progress | ✓ |
| Blank students only | Students exist but no grades/enrollment history | |
| You decide | Agent decides | |

**User's choice:** With academic history

---

| Option | Description | Selected |
|--------|-------------|----------|
| Idempotent | INSERT ON CONFLICT DO NOTHING, safe to re-run | |
| Destructive (drop + recreate) | Truncates and reinserts, guarantees clean state | ✓ |
| You decide | Agent picks | |

**User's choice:** Destructive (drop + recreate)

---

## Local Dev Workflow

| Option | Description | Selected |
|--------|-------------|----------|
| Volume mounts + hot-reload | Docker Compose mounts source code, uvicorn --reload | ✓ |
| Production-like containers | COPY source into images, requires rebuild | |
| Hybrid | COPY for prod, volumes in dev | |
| You decide | Agent picks | |

**User's choice:** Volume mounts + hot-reload

---

| Option | Description | Selected |
|--------|-------------|----------|
| Separate per service | Each service has own requirements.txt | ✓ |
| Single shared file | One requirements.txt at root | |
| You decide | Agent picks | |

**User's choice:** Separate per service

---

| Option | Description | Selected |
|--------|-------------|----------|
| One Dockerfile per service | Each directory has its own Dockerfile | ✓ |
| Single multi-stage Dockerfile | One Dockerfile with stage targets | |
| You decide | Agent picks | |

**User's choice:** One Dockerfile per service

---

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal healthcheck stub | Tiny FastAPI returning 200 on /health | ✓ |
| Empty containers (sleep) | Containers start with sleep/tail | |

**User's choice:** Minimal healthcheck stub

---

## Migration Granularity

| Option | Description | Selected |
|--------|-------------|----------|
| Domain-grouped | #001 pgvector, then grouped by domain (#002-#006) | ✓ |
| One big initial migration | #001 pgvector, #002 all 17 tables | |
| One table per migration | Each table its own migration file | |
| You decide | Agent picks | |

**User's choice:** Domain-grouped

---

| Option | Description | Selected |
|--------|-------------|----------|
| SQLAlchemy models + autogenerate | Define models in Python, use alembic --autogenerate | ✓ |
| Raw SQL migrations | Write SQL directly in migration files | |
| You decide | Agent picks | |

**User's choice:** SQLAlchemy models + autogenerate

---

| Option | Description | Selected |
|--------|-------------|----------|
| Per-feature models | Each feature directory gets models.py, central import aggregates | ✓ |
| Single models file | All models in one file | |
| You decide | Agent picks | |

**User's choice:** Per-feature models

---

## Agent's Discretion

- Migration execution strategy (auto on startup vs manual)
- PostgreSQL port exposure on localhost
- Entrypoint script structure
- Alembic env.py async configuration

## Deferred Ideas

None — discussion stayed within phase scope.
