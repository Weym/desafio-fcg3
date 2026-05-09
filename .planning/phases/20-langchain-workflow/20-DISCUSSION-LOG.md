# Phase 20: LangChain Workflow - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-09
**Phase:** 20-langchain-workflow
**Areas discussed:** Welcome/Goodbye flow, Prompt injection defense, Observability & staff debug, Lazy OTP strategy, System prompt & persona

---

## Welcome/Goodbye Flow

| Option | Description | Selected |
| --- | --- | --- |
| AI-generated welcome | Agent generates personalized greeting using student name + persona tone | ✓ |
| Hardcoded template | Fixed message like verification success already does | |
| Hybrid: template + AI hint | Fixed skeleton with contextual hint from MCP check | |

**User's choice:** AI-generated welcome
**Notes:** Agent handles the greeting naturally within its persona.

---

| Option | Description | Selected |
| --- | --- | --- |
| Keyword + timeout | Keywords OR 24h timeout | |
| Timeout only | No explicit goodbye detection, only 24h + close keywords | |
| AI detects farewell intent | Agent recognizes farewell in any phrasing | |

**User's choice:** Custom 3-layer approach: (1) AI detects farewell intent, (2) 24h inactivity timeout, (3) 5-10 min idle timeout after agent follow-up question with no response.
**Notes:** Layer 3 triggers only after 2+ turns of silence — agent asks "precisa de mais alguma coisa?" and waits 5 min for response.

---

| Option | Description | Selected |
| --- | --- | --- |
| Always ask after completing an action | Agent always asks follow-up after actions | |
| Ask only after 2+ turns idle | Agent asks follow-up only after 2+ turns of silence | ✓ |
| You decide | Agent's discretion | |

**User's choice:** Ask only after 2+ turns idle

---

| Option | Description | Selected |
| --- | --- | --- |
| Always send goodbye | Sends farewell on any session close | ✓ |
| Only on explicit farewell | Only responds to "tchau" | |
| Farewell + idle only | Goodbye on farewell and idle, silent on 24h | |

**User's choice:** Always send goodbye

---

## Prompt Injection Defense

| Option | Description | Selected |
| --- | --- | --- |
| System prompt hardening only | Lightweight, no extra code | |
| Hardening + input sanitization | Prompt rules + regex pre-processing | |
| Full defense-in-depth | Hardening + sanitization + canary tokens + output filtering | ✓ |

**User's choice:** Full defense-in-depth

---

| Option | Description | Selected |
| --- | --- | --- |
| Polite redirect + log | Generic response, silent logging | |
| Warning + log + cooldown | Visible warning, logs, adds cooldown | ✓ |
| Silent block + escalate | Generic response + auto-escalation after N attempts | |

**User's choice:** Warning + log + cooldown

---

| Option | Description | Selected |
| --- | --- | --- |
| Yes, escalate after threshold | Auto-escalate after N flagged messages | |
| No, just log and warn | Only log and warn, no escalation | |
| You decide | Planner decides | ✓ |

**User's choice:** You decide (agent's discretion)

---

| Option | Description | Selected |
| --- | --- | --- |
| Block system prompt echo only | Only block verbatim prompt text | |
| Block system + internal details | Block prompt echo + tool names, API URLs, architecture, DB tables | ✓ |
| You decide | Downstream agent determines | |

**User's choice:** Block system + internal details

---

## Observability & Staff Debug

| Option | Description | Selected |
| --- | --- | --- |
| Chunks + scores | Log chunks retrieved, scores, search query, threshold result | ✓ |
| Minimal: score + hit/miss | Only top score and pass/fail | |
| Full: chunks + scores + content | Everything plus actual chunk text content | |

**User's choice:** Chunks + scores (recommended)

---

| Option | Description | Selected |
| --- | --- | --- |
| LangChain callbacks | BaseCallbackHandler, structured JSON per message | |
| LangSmith integration | Full tracing via LangSmith platform | ✓ |
| Custom logging only | Python structured logging, not in DB | |

**User's choice:** LangSmith integration

---

| Option | Description | Selected |
| --- | --- | --- |
| New column on chat_messages | JSONB metadata column inline | |
| Separate rag_logs table | New table with FK to chat_message_id | ✓ |
| Extend mcp_action_logs | Reuse existing table for RAG metadata too | |

**User's choice:** Separate rag_logs table

---

| Option | Description | Selected |
| --- | --- | --- |
| Always-on | LANGCHAIN_TRACING_V2=true in production | ✓ |
| Env-flag controlled | Off by default, enable for debugging | |
| Dev/staging only | No external dependency in production | |

**User's choice:** Always-on (recommended)

---

| Option | Description | Selected |
| --- | --- | --- |
| Surface in staff chat UI | Per-message MCP tool info in Flutter | |
| LangSmith + existing table | Use LangSmith dashboard + mcp_action_logs | ✓ |
| Both | Summary in Flutter + full details in LangSmith | |

**User's choice:** LangSmith + existing table

---

## Lazy OTP Strategy

| Option | Description | Selected |
| --- | --- | --- |
| Skip OTP for read-only, require for actions | RAG + read-only tools without OTP, mutating tools require OTP | ✓ |
| Delayed prompt | Let student state intent before asking for OTP | |
| Trust returning verified phones | Skip OTP if phone previously verified within X days | |

**User's choice:** Skip OTP for read-only queries AND read-only MCP tools. Only mutating MCP tool calls require OTP.

---

| Option | Description | Selected |
| --- | --- | --- |
| ALL MCP tools require OTP | Any tool accessing student data needs verification | |
| Only mutating tools | Read-only tools work pre-OTP, phone identity sufficient | ✓ |
| All tools with different prompt | All require OTP but asked naturally mid-conversation | |

**User's choice:** Only mutating tools

---

| Option | Description | Selected |
| --- | --- | --- |
| Agent requests verification naturally | Agent says "preciso confirmar sua identidade" mid-conversation | ✓ |
| System-level interrupt | MCP rejects, webhook takes over OTP flow | |
| You decide | Planner determines UX | |

**User's choice:** Agent requests verification naturally

---

| Option | Description | Selected |
| --- | --- | --- |
| Trust phone-based identity | Phone maps to student, no extra check for reads | ✓ |
| Confirm name before reads | Agent asks "Voce e {name}?" before first read tool | |
| You decide | Planner determines | |

**User's choice:** Trust phone-based identity

---

| Option | Description | Selected |
| --- | --- | --- |
| Yes, persist for session | verified state lasts entire session | ✓ |
| Persist per session + expiry | Verified but expires after 1h | |
| Re-verify each mutating action | Fresh OTP per action | |

**User's choice:** Yes, persist for session (recommended)

---

## System Prompt & Persona

| Option | Description | Selected |
| --- | --- | --- |
| Friendly professional | Cordial, uses name, warm but objective. No slang, no emojis | ✓ |
| Casual/approachable | Informal, emojis, like a senior student | |
| Strictly professional | Formal, no personality beyond helpfulness | |

**User's choice:** Friendly professional

---

| Option | Description | Selected |
| --- | --- | --- |
| Both: prompt summary + tool binding | Human-readable summary in prompt + LangChain tool schemas | ✓ |
| Tool binding only | Rely on LangChain's auto tool descriptions | |
| Detailed prompt only | Full capability list in prompt, tools secondary | |

**User's choice:** Both (recommended)

---

| Option | Description | Selected |
| --- | --- | --- |
| Explicit boundary list | Enumerated list of allowed topics | |
| General instruction | General rule: "nao academico → redirecione" | ✓ |
| You decide | Planner determines | |

**User's choice:** General instruction

---

| Option | Description | Selected |
| --- | --- | --- |
| Prompt includes OTP awareness | System prompt instructs about verification | |
| Code-level OTP gate | MCP rejects, code handles, agent unaware | |
| Hybrid: prompt awareness + code gate | Agent knows about OTP + code enforces as safety net | ✓ |

**User's choice:** Hybrid: prompt awareness + code gate

---

| Option | Description | Selected |
| --- | --- | --- |
| Single file | One system_prompt.txt with section headers | ✓ |
| Multiple files composed | Separate files composed at startup | |
| Jinja2 template | Template with variables rendered per-request | |

**User's choice:** Single file (recommended)

---

| Option | Description | Selected |
| --- | --- | --- |
| Named: 'Alpha' | Consistent with Alpha Connect app branding | ✓ |
| Anonymous: 'assistente virtual' | No name | |
| You decide | Planner picks | |

**User's choice:** Named "Alpha"

---

## Agent's Discretion

- Whether repeated prompt injection attempts auto-escalate to human intervention (and at what threshold)
- Exact idle timeout duration (5 or 10 min)
- Exact canary token strategy
- Input sanitization regex patterns
- Cooldown mechanism for injection detection
- Media response creative improvements
- RAG ingest bootstrap mechanism

## Deferred Ideas

- Whisper API for audio transcription
- GPT-4o Vision for image analysis
- RAG admin UI for staff
- Conversation analytics dashboard
- Multi-language support
