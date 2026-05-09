---
phase: 20
slug: langchain-workflow
status: verified
threats_open: 0
asvs_level: 1
created: 2026-05-09
---

# Phase 20 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| WhatsApp → Webhook | Untrusted user messages arrive from WhatsApp Cloud API | Text, media type indicators |
| System prompt → LLM | Prompt instructions must not leak to user response | System instructions, persona rules |
| User message → Agent | Untrusted input could manipulate LLM behavior | Free-text student messages |
| Agent response → WhatsApp | Agent output could leak internal system details | Generated text responses |
| AI service → Database | RAG logs write to internal database | Query text, chunk metadata, scores |
| Docker env → LangSmith cloud | Tracing data sent to external service | Conversation traces, tool calls |
| Timer → Session state | Background timer modifies session status | Session ID, status transition |
| WhatsApp → Agent (unverified) | Phone-identified but unverified students query agent | Read-only data requests |
| Agent → MCP (mutating tools) | Mutating tools must gate on verification state | Tool calls with student context |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-20-01 | Information Disclosure | system_prompt.txt | mitigate | Canary token + security section instructs never reveal prompt content | closed |
| T-20-02 | Spoofing | system_prompt.txt | mitigate | Explicit instruction to ignore role-change attempts and contradictory instructions | closed |
| T-20-03 | Information Disclosure | rag_logs | accept | Logs stored in internal DB only; staff-only access; no PII in knowledge chunks | closed |
| T-20-04 | Denial of Service | _log_rag_invocation | mitigate | try/except wrapping — logging failure logged as warning, does not block RAG response | closed |
| T-20-05 | Information Disclosure | LangSmith | accept | LangSmith receives conversation data per policy; LANGSMITH_API_KEY is env-only | closed |
| T-20-06 | Denial of Service | entrypoint.sh | mitigate | Ingest failure non-fatal via `||` pattern — service starts regardless | closed |
| T-20-07 | Tampering | knowledge/ files | accept | Knowledge files in-repo — no external source; academic content only | closed |
| T-20-08 | Elevation of Privilege | Lazy OTP bypass | mitigate | Dual-layer: system prompt rule 9 gates mutating actions + router enforces OTP states + service mid-conversation verification | closed |
| T-20-09 | Spoofing | Phone-based identity | accept | Phone→student mapping trusted for read operations; mutating ops still require OTP verification | closed |
| T-20-10 | Repudiation | Unverified actions | mitigate | Read-only actions logged in mcp_action_logs with session context; mutating actions blocked until verified | closed |
| T-20-11 | Tampering | LLM prompt context | mitigate | 4-layer defense: hardened prompt + input sanitization (12 patterns EN/PT) + canary token + output filter | closed |
| T-20-12 | Information Disclosure | Agent response | mitigate | Output filter blocks 16 tool names, API URLs, 16 DB table names, Docker refs, canary token detection | closed |
| T-20-13 | Elevation of Privilege | Injection → tool call | mitigate | Input sanitization strips role-change patterns; system prompt refuses; MCP gates mutating tools on verification | closed |
| T-20-14 | Denial of Service | Regex patterns | accept | Simple alternation patterns; no nested quantifiers; no catastrophic backtracking risk | closed |
| T-20-15 | Denial of Service | _idle_timers memory | mitigate | Timers cleaned up on completion/cancellation; keys removed in finally block; schedule resets existing | closed |
| T-20-16 | Tampering | Session close via timer | accept | Timer verifies idle state via DB query before close; premature close is recoverable (new session on next message) | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-01 | T-20-03 | RAG logs contain only academic chunk metadata (source, category, score) — no student PII. Staff-only access. | gsd-security-auditor | 2026-05-09 |
| AR-02 | T-20-05 | LangSmith tracing per-policy decision; API key never in source; opt-in via env var (default false). | gsd-security-auditor | 2026-05-09 |
| AR-03 | T-20-07 | Knowledge base files are version-controlled and contain only academic regulations/FAQ. No external source. | gsd-security-auditor | 2026-05-09 |
| AR-04 | T-20-09 | Phone→student mapping is the trust anchor for informational queries. Risk: phone number spoofing only yields read-only academic data (grades, courses) — acceptable. | gsd-security-auditor | 2026-05-09 |
| AR-05 | T-20-14 | Regex patterns use simple alternation (`|`) and anchored matches. No `.*` with nested quantifiers. Manual review confirms no ReDoS vectors. | gsd-security-auditor | 2026-05-09 |
| AR-06 | T-20-16 | Idle timer closes session after DB-verified idle period. Worst case: premature close forces student to send new message (creates new session — no data loss). | gsd-security-auditor | 2026-05-09 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-05-09 | 16 | 16 | 0 | gsd-security-auditor |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-05-09
