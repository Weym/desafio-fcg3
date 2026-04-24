---
phase: 01
slug: infrastructure-schema
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-24
---

# Phase 01 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| `.env` / `.env.example` → application | Environment values cross from filesystem into service config | Secrets, DSNs, service tokens |
| Docker / host → containers | Compose exposes local ports and health endpoints | HTTP health traffic, database port access |
| Alembic / seed tooling → PostgreSQL | Migration and seed scripts execute with write privileges | DDL, destructive seed data, schema metadata |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-01-01 | I | `.env` file | mitigate | `.env` added to `.gitignore`; `.env.example` uses placeholders only | closed |
| T-01-02 | I | PostgreSQL port exposure | accept | Dev-only localhost exposure accepted for convenience | closed |
| T-01-03 | S | `MCP_SERVICE_TOKEN` | mitigate | Env-only token documented with placeholder/example values and per-environment generation guidance | closed |
| T-01-04 | T | Docker image base | mitigate | Pin service images to `python:3.12-slim` | closed |
| T-01-05 | D | Healthcheck storm | mitigate | 10-15s intervals, 5s timeout, 3 retries, 30s start period on Python services | closed |
| T-01-06 | I | `.dockerignore` | mitigate | Exclude `.env`, `.planning/`, `scripts/seed.py` | closed |
| T-02-01 | T | Alembic migration files | accept | Git review accepted as control in dev-only environment | closed |
| T-02-02 | I | `ALEMBIC_DATABASE_URL` / `DATABASE_URL` | mitigate | No hardcoded credentials in `alembic.ini`; `env.py` reads env vars | closed |
| T-02-03 | D | Migration lock timeout | mitigate | Alembic transaction-per-migration flow retained; long migrations require maintenance window | closed |
| T-02-04 | E | pgvector extension creation | accept | Superuser requirement accepted and documented here | closed |
| T-02-05 | T | Autogenerate drift | mitigate | `alembic check` required in pre-commit; additional run evidence supplied | closed |
| T-03-01 | I | `.env.example` | mitigate | Placeholder-only example values; no real-looking `sk-` / `re_` secrets committed | closed |
| T-03-02 | I | `.env` file | mitigate | `.gitignore` keeps `.env` untracked and pre-commit guidance warns against committing secrets | closed |
| T-03-03 | E | `MCP_SERVICE_TOKEN` | mitigate | Enforce `min_length=16` in settings validation | closed |
| T-03-04 | D | Missing env vars | accept | Lazy settings validation on first use | closed |
| T-03-05 | I | `JWT_SECRET` too short | mitigate | Enforce `min_length=16`; `.env.example` recommends 32+ chars | closed |
| T-04-01 | T | Seed data | accept | Development-only seed usage accepted | closed |
| T-04-02 | R | Data destruction | mitigate | Warning text and affected tables listed in seed script | closed |
| T-04-03 | I | Student email/phone in seed | accept | Fake sample identities accepted | closed |
| T-04-04 | D | `TRUNCATE` cascades | accept | Intentional destructive behavior accepted for dev seed flow | closed |
| T-01-05-01 | D | `backend/src/main.py` startup path | mitigate | Import `get_settings` from `src.infrastructure.config` without calling it | closed |
| T-01-05-02 | T | `backend/src/main.py` health stub | accept | Non-sensitive liveness-only `/health` endpoint accepted | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Threat Verification

| Threat ID | Category | Disposition | Evidence |
|-----------|----------|-------------|----------|
| T-01-01 | I | mitigate | `.gitignore:6`; `.env.example:1-2,30,42,58,70` |
| T-01-02 | I | accept | Accepted Risks Log `AR-01` |
| T-01-03 | S | mitigate | `.env.example:29-30,69-70`; `.gitignore:6` |
| T-01-04 | T | mitigate | `backend/Dockerfile:1`; `ai_service/Dockerfile:1`; `mcp_server/Dockerfile:1` |
| T-01-05 | D | mitigate | `docker-compose.yml:57-60,97-100,137-140` |
| T-01-06 | I | mitigate | `.dockerignore:3,7,10` |
| T-02-01 | T | accept | Accepted Risks Log `AR-02` |
| T-02-02 | I | mitigate | `backend/alembic.ini:4`; `backend/alembic/env.py:18-26` |
| T-02-03 | D | mitigate | `backend/alembic/env.py:43-44,62-63` |
| T-02-04 | E | accept | Accepted Risks Log `AR-03` |
| T-02-05 | T | mitigate | `.pre-commit-config.yaml:9-14`; user-supplied evidence: `python -m alembic check` → `No new upgrade operations detected.` |
| T-03-01 | I | mitigate | `.env.example:23,30,42,58,70` (placeholder-only example values; no `sk-` / live-looking tokens present) |
| T-03-02 | I | mitigate | `.gitignore:6-8`; `.pre-commit-config.yaml:16-19` |
| T-03-03 | E | mitigate | `backend/src/infrastructure/config.py:47-49` |
| T-03-04 | D | accept | Accepted Risks Log `AR-04` |
| T-03-05 | I | mitigate | `backend/src/infrastructure/config.py:32-34`; `.env.example:22-23` |
| T-04-01 | T | accept | Accepted Risks Log `AR-05` |
| T-04-02 | R | mitigate | `backend/scripts/seed.py:2-10,514-515` |
| T-04-03 | I | accept | Accepted Risks Log `AR-06` |
| T-04-04 | D | accept | Accepted Risks Log `AR-07` |
| T-01-05-01 | D | mitigate | `backend/src/main.py:3,9-10` |
| T-01-05-02 | T | accept | Accepted Risks Log `AR-08` |

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-01 | T-01-02 | PostgreSQL port `5432` is exposed for local development convenience; production isolation is handled separately. | gsd-security-auditor | 2026-04-24 |
| AR-02 | T-02-01 | Alembic migrations are version-controlled and expected to be reviewed in normal development workflow. | gsd-security-auditor | 2026-04-24 |
| AR-03 | T-02-04 | pgvector extension creation requires superuser privileges during environment bootstrap. | gsd-security-auditor | 2026-04-24 |
| AR-04 | T-03-04 | Lazy settings validation intentionally fails on first use instead of import time for Phase 1 safety. | gsd-security-auditor | 2026-04-24 |
| AR-05 | T-04-01 | Seed script is for development-only database population and must not run in production. | gsd-security-auditor | 2026-04-24 |
| AR-06 | T-04-03 | Seeded student contact values are fake sample data for testing flows only. | gsd-security-auditor | 2026-04-24 |
| AR-07 | T-04-04 | Destructive `TRUNCATE ... CASCADE` behavior is intentional for repeatable dev reseeding. | gsd-security-auditor | 2026-04-24 |
| AR-08 | T-01-05-02 | `/health` remains a read-only liveness endpoint with no secret-bearing behavior in Phase 1. | gsd-security-auditor | 2026-04-24 |

---

## Unregistered Flags

None. No `## Threat Flags` section was found in `01-01-SUMMARY.md` through `01-05-SUMMARY.md`.

---

## Additional Verification Evidence

- `python -m pre_commit validate-config` passed from repo root (user-supplied evidence).
- `python -m alembic check` passed from `backend/` with output `No new upgrade operations detected.` (user-supplied evidence).

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-24 | 22 | 18 | 4 | gsd-security-auditor |
| 2026-04-24 | 22 | 22 | 0 | OpenCode |
| 2026-04-24 | 22 | 22 | 0 | gpt-5.4 |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified
