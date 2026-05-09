---
phase: 04
slug: mcp-server
status: verified
threats_open: 0
asvs_level: 1
created: 2026-04-25
---

# Phase 04 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| AI Service → MCP Server | Tool calls and `X-Chat-Session-ID` arrive from an untrusted caller and must be validated before execution/logging. | Tool arguments, session header |
| MCP Server → FastAPI | Internal service-to-service calls must carry `X-Service-Token`. | Backend requests, mutation payloads |
| MCP Server → PostgreSQL | Session resolution and audit logging cross directly into the database. | `chat_sessions` lookups, `mcp_action_logs` writes |
| Docker/Compose → MCP runtime | Runtime entrypoint must boot the real FastMCP package safely. | Container command, package startup |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-04-01 | Spoofing | X-Chat-Session-ID header | mitigate | Validate UUID format before DB query; only accept active sessions from `chat_sessions`. | closed |
| T-04-02 | Tampering | Tool input_params | mitigate | FastMCP schema-typed tool params and parameterized DB access. | closed |
| T-04-03 | Information Disclosure | student_id in logs | mitigate | Remove `student_id` from logged `input_params` and keep it out of tool schemas. | closed |
| T-04-04 | Information Disclosure | MCP_SERVICE_TOKEN | mitigate | Env-only token use in MCP and constant-time comparison in FastAPI. | closed |
| T-04-05 | Denial of Service | Unbounded tool calls | accept | MVP low-volume risk accepted; rate limiting deferred. | closed |
| T-04-06 | Elevation of Privilege | IDOR via session_id | mitigate | Resolve `student_id` server-side from active session only; never accept from tool input. | closed |
| T-04-07 | Tampering | course_id param | mitigate | `course_id` remains typed tool input and is proxied to FastAPI validation. | closed |
| T-04-08 | Information Disclosure | Raw API response to agent | accept | Student-owned read data returned to agent is accepted. | closed |
| T-04-09 | Spoofing | student_id absent in get_curriculum | accept | `get_curriculum` is public and does not require student context. | closed |
| T-04-10 | Tampering | enrollment_id in confirm/drop/lock | mitigate | MCP only proxies resource IDs; ownership enforcement stays on FastAPI. | closed |
| T-04-11 | Repudiation | Mutation tool calls | mitigate | Every valid tool call is logged to `mcp_action_logs` with audit fields. | closed |
| T-04-12 | Elevation of Privilege | Agent calling create_enrollment for wrong student | mitigate | `create_enrollment` injects `student_id` from session resolver, not agent input. | closed |
| T-04-13 | Tampering | document type param | mitigate | `type` remains typed tool input and is proxied to FastAPI validation. | closed |
| T-04-14 | Information Disclosure | student_id in schema | mitigate | Schema regression test asserts `student_id` is absent from all 16 tool schemas. | closed |
| T-04-15 | Spoofing | Missing X-Service-Token | mitigate | Lifespan injects `X-Service-Token`; tests verify outbound presence and backend rejection paths. | closed |
| T-04-05-01 | D | `mcp_server/Dockerfile`, `docker-compose.yml` | mitigate | Runtime uses `python -m mcp_server.main` and copies the package. | closed |
| T-04-05-02 | D | `mcp_server/main.py` | mitigate | Import-safe startup removes import-time `asyncio.run(...)`. | closed |
| T-04-05-03 | T | MCP runtime manifests | mitigate | Regression tests lock package entrypoint and 16-tool registration surface. | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-04-01 | T-04-05 | MVP volume is low and rate limiting can be added later via FastMCP middleware if needed. | Phase 04 threat register | 2026-04-25 |
| AR-04-02 | T-04-08 | Read-only API responses are limited to student-owned data and are needed for agent responses. | Phase 04 threat register | 2026-04-25 |
| AR-04-03 | T-04-09 | `get_curriculum` is intentionally public and requires no student context. | Phase 04 threat register | 2026-04-25 |

---

## Unregistered Flags

No `## Threat Flags` sections were present in the Phase 04 summary files.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-25 | 18 | 18 | 0 | gsd-security-auditor |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-25
