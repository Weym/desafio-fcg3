# Phase 20: LangChain Workflow - Context

**Gathered:** 2026-05-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Complete the WhatsApp chatbot's conversation lifecycle: enhanced system prompt with persona, welcome/goodbye messages, off-scope handling, prompt injection defense (full defense-in-depth), structured logging (RAG + LangSmith), lazy OTP (verification only for mutating actions), and auto-run RAG ingest on bootstrap. The agent ("Alpha") handles the full conversation arc from greeting through academic assistance to farewell, with 3-layer session closure.

</domain>

<decisions>
## Implementation Decisions

### Welcome/Goodbye Flow (LANG-01, LANG-02)

- **D-01:** AI-generated welcome message. When a student starts a new session (first message after phone lookup, whether verified or not), the agent generates a personalized greeting using the student's name and persona tone. Not a hardcoded template.
- **D-02:** 3-layer session end detection:
  - **Layer 1 — AI farewell detection:** Agent recognizes farewell intent in any phrasing (not just keywords) and responds with goodbye + closes session. Natural language understanding, not regex.
  - **Layer 2 — 24h inactivity timeout:** pg_cron job (already exists from Phase 6 D-12) closes sessions with 24h of inactivity.
  - **Layer 3 — Short-term idle timeout (5-10 min):** If student goes quiet for 5 min after a response that didn't ask a question, the agent sends "precisa de mais alguma coisa?" — another 5 min silence triggers goodbye + session close.
- **D-03:** Agent asks "precisa de mais alguma coisa?" only after 2+ turns of idle silence — NOT automatically after every completed action. Avoids annoying the student mid-flow.
- **D-04:** Always send goodbye message on any session close (farewell, idle timeout, 24h timeout). Message like "Ate mais, {name}! Se precisar, e so mandar mensagem."

### Prompt Injection Defense (LANG-09)

- **D-05:** Full defense-in-depth with 4 layers:
  1. **System prompt hardening** — explicit instructions: ignore role-change attempts, never reveal system prompt, stay in persona.
  2. **Input sanitization** — pre-processing to strip known injection patterns from user messages before reaching the agent (regex-based).
  3. **Canary tokens** — hidden markers in system prompt that trigger alert if echoed back in agent output.
  4. **Output filtering** — block responses that leak system info before sending to WhatsApp.
- **D-06:** On detection: Agent warns student once ("Detectei uma mensagem fora do padrao"), logs the attempt for staff review, and adds a short cooldown before processing next message. Student sees the warning.
- **D-07:** Output filtering blocks: system prompt verbatim text, mentions of "system prompt"/"minhas instrucoes", internal details (tool names as code identifiers, API URLs, service architecture references, database table names).
- **D-08:** Whether repeated injection attempts auto-escalate to human intervention is at agent's discretion (planner decides threshold and flow).

### Observability & Staff Debug (LANG-10, LANG-11, LANG-12, LANG-13)

- **D-09:** RAG logging captures: which chunks were retrieved, their similarity scores, the search query the agent formulated, and whether the threshold was met. Stored per RAG invocation.
- **D-10:** LangChain decision tracing via **LangSmith** integration. Always-on in production (`LANGCHAIN_TRACING_V2=true` in Docker env). Every conversation fully traced. Staff uses LangSmith dashboard for debugging.
- **D-11:** RAG metadata stored in a **separate `rag_logs` table** with FK to `chat_message_id`. Stores: query, chunks retrieved (identifiers + scores), threshold result per invocation.
- **D-12:** MCP tool call visibility: existing `mcp_action_logs` table (Phase 4) + LangSmith. No additional Flutter UI changes for MCP details — staff uses LangSmith or DB queries for deep tool inspection.

### Lazy OTP Strategy (LANG-14)

- **D-13:** Skip OTP for informational queries (RAG knowledge base questions) AND read-only MCP tools (get_grades, get_student_info, get_document_status, etc.). Require OTP only when a **mutating** MCP tool call is needed (create_enrollment, confirm_enrollment, request_document, book_appointment, cancel_appointment, etc.).
- **D-14:** Read-only MCP tools trust phone-based identity. Phone-to-student mapping from Phase 6 lookup provides student_id. No lightweight verification step needed for reads.
- **D-15:** When a mutating action is needed and student isn't verified, the **agent requests verification naturally** mid-conversation: "Para executar essa acao, preciso confirmar sua identidade. Qual seu email institucional?" — then the existing verification state machine handles the OTP flow.
- **D-16:** Once OTP is completed mid-conversation, `verification_state='verified'` persists for the **entire session**. No re-verification for subsequent mutating actions in the same session.

### System Prompt & Persona (LANG-07)

- **D-17:** Friendly professional tone. Cordial, uses student's name, slightly warm but always objective. Like a helpful secretary who knows you. No slang, no emojis in responses.
- **D-18:** Bot named **"Alpha"** — consistent with Alpha Connect app branding. Introduces itself: "Oi, sou o Alpha, assistente da secretaria academica."
- **D-19:** System prompt includes **both** a human-readable capability summary ("Voce pode: consultar notas, matricular, solicitar documentos...") AND LangChain provides technical tool schemas via tool binding. Agent understands both intent boundaries and mechanics.
- **D-20:** Off-scope handling via **general instruction**: "Se a pergunta nao for relacionada a vida academica do aluno, redirecione educadamente para o escopo academico." Agent uses judgment rather than matching against an explicit enumeration.
- **D-21:** **Hybrid OTP awareness**: system prompt instructs the agent about verification requirements for mutating actions ("Antes de executar acoes que alteram dados, verifique se o aluno esta verificado. Se nao, solicite email institucional.") PLUS code-level gate in MCP middleware as safety net.
- **D-22:** Single monolithic `system_prompt.txt` file with clear section headers (## Persona, ## Regras, ## Capacidades, ## Seguranca). Current pattern maintained. Easy to read/edit as a whole.

### Off-Scope Handling (LANG-05)

- **D-23:** Agent uses general judgment for off-scope detection (per D-20). When off-scope is detected, responds with polite academic redirect. No hardcoded off-scope keyword list.

### Media Handling (LANG-08)

- **D-24:** Already implemented in `webhook/service.py` with hardcoded responses. Phase 20 enhances this to be slightly more creative/varied per LANG-08 requirement. Agent's discretion on exact wording improvements — must remain hardcoded (no LLM call for media).

### RAG Ingest on Bootstrap (Folded Todo)

- **D-25:** RAG ingest script (`ai_service/ingest.py`) runs automatically on `docker-compose up` bootstrap. Ensures knowledge base is always populated without manual `docker exec`. Implementation mechanism (entrypoint script, healthcheck dependency, or init container) at planner's discretion.

### Agent's Discretion

- Whether repeated prompt injection attempts trigger auto-escalation to human intervention (and at what threshold)
- Exact idle timeout duration within the 5-10 minute range
- Exact canary token placement strategy and detection logic
- Input sanitization regex patterns for injection detection
- Exact cooldown mechanism after injection detection (delay vs rate limit)
- Media response wording improvements (still hardcoded, just more creative/varied)
- RAG ingest bootstrap mechanism (entrypoint vs healthcheck dependency vs init container)
- Agent fallback behavior when LangSmith is unreachable (should not block responses)

</decisions>

<canonical_refs>

## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Chatbot Architecture & Agent Design
- `docs/chatbot.md` -- Complete chatbot architecture: system prompt (current minimal version), intent table, conversation flow diagrams, RAG pipeline design, media handling responses, verification flow, error handling table. Primary spec for agent behavior.

### MCP Protocol & Tool Schemas
- `docs/mcp.md` -- 16 MCP tool definitions (input schemas with student_id omitted), endpoint mappings, logging specification, retry behavior. Defines which tools are "mutating" vs "read-only" for lazy OTP classification.

### API Contract
- `docs/api.md` -- REST endpoint contracts. Which endpoints are read-only vs mutating. Error codes in Portuguese.

### Database Schema
- `docs/database.md` -- Schema for `chat_sessions` (verification_state column), `chat_messages`, `knowledge_base_chunks`, `mcp_action_logs`. New `rag_logs` table needs migration.

### Phase Dependencies (MUST READ)
- `.planning/phases/04-mcp-server/04-CONTEXT.md` -- D-04/D-05/D-06: X-Chat-Session-ID header, student_id resolution. D-08/D-09: Response formats. D-10: MCP logging already exists.
- `.planning/phases/05-ai-service/05-CONTEXT.md` -- D-01: langchain-mcp-adapters. D-06: system prompt from file. D-07: execution limits. D-08/D-09: stateless per request. D-11: RAG as explicit tool.
- `.planning/phases/06-whatsapp-webhook-integration/06-CONTEXT.md` -- D-01/D-02: verification state machine (needs modification for lazy OTP). D-06: retry + fallback. D-09: per-session locks. D-11: session close keywords.
- `.planning/phases/14-human-intervention/14-CONTEXT.md` -- D-05/D-06/D-07: escalation flow (keywords + AI response phrases). Already implemented in `background.py`.

### Existing Implementation (current state)
- `ai_service/agent.py` -- Current agent factory, tool error middleware, invoke_agent function
- `ai_service/main.py` -- FastAPI endpoint, service token auth
- `ai_service/config.py` -- Settings with LLM_PROVIDER, MCP_SERVER_URL, RAG thresholds
- `ai_service/prompts/system_prompt.txt` -- Current 8-rule minimal prompt (to be replaced)
- `backend/src/features/webhook/background.py` -- Background processing with escalation detection
- `backend/src/features/webhook/service.py` -- Verification state machine (needs modification for lazy OTP)

</canonical_refs>

<code_context>

## Existing Code Insights

### Reusable Assets

- `ai_service/agent.py`: ReAct agent with tool error middleware (`_tolerate_tool_errors`), timeout handling, fallback message pattern. Foundation to build upon.
- `ai_service/mcp_tools.py`: MCP tool loading via `langchain-mcp-adapters` with per-session `X-Chat-Session-ID` header injection.
- `ai_service/rag.py`: RAG tool creation with configurable similarity threshold.
- `backend/src/features/webhook/service.py`: Full verification state machine (unverified -> awaiting_email -> awaiting_code -> verified). Needs modification for lazy OTP but logic is reusable.
- `backend/src/features/webhook/background.py`: Escalation detection (keywords + AI response phrases), per-session locking, retry pattern.
- `backend/src/infrastructure/whatsapp_client.py`: WhatsApp send with retry.

### Established Patterns

- Stateless AI service: rebuilds agent per request, loads history from DB fresh each time.
- System prompt loaded from file at startup (`app.state.system_prompt`).
- `asyncio.create_task` + `add_done_callback` for background processing (5s webhook timeout compliance).
- Per-session `asyncio.Lock` prevents concurrent processing.
- psycopg3 sync driver for AI service DB access; asyncpg for backend.
- Settings via dataclass with `os.environ.get()` pattern (not Pydantic BaseSettings in AI service).

### Integration Points

- `ai_service/prompts/system_prompt.txt` — needs complete rewrite (8 rules → full persona + instructions + capabilities + security).
- `backend/src/features/webhook/service.py` — verification state machine needs "lazy" mode where unverified sessions can still reach the agent for read-only operations.
- `backend/src/features/webhook/background.py` — session idle timeout logic needs implementation (5-10 min check).
- New Alembic migration needed for `rag_logs` table.
- Docker environment needs `LANGCHAIN_TRACING_V2=true`, `LANGSMITH_API_KEY` vars.
- `ai_service/ingest.py` — needs bootstrap integration in Docker entrypoint or similar.

</code_context>

<specifics>
## Specific Ideas

- The bot is "Alpha" — same name as the app (Alpha Connect). This creates brand consistency when the student interacts via WhatsApp vs the mobile app.
- Lazy OTP is a significant UX improvement: student asks "quais minhas notas?" and gets an answer immediately without OTP friction. Only when they say "quero me matricular" does verification kick in naturally mid-conversation.
- The 3-layer goodbye prevents abandoned sessions (idle timeout catches students who just leave WhatsApp) while being natural for students who say "obrigado, tchau" (AI detects farewell intent).
- LangSmith always-on means staff can retroactively debug any conversation by finding it in the LangSmith dashboard — no need to reproduce issues.
- Defense-in-depth for injection is critical because the bot can execute real actions (matricula, documentos) — a successful injection could theoretically trigger unintended actions if it bypasses the MCP safety layer.

</specifics>

<deferred>
## Deferred Ideas

- Whisper API for audio transcription (post-MVP per PROJECT.md)
- GPT-4o Vision for image analysis (post-MVP per PROJECT.md)
- RAG admin UI for staff (knowledge base management via web instead of docker exec)
- Conversation analytics dashboard (per-topic volume, satisfaction metrics)
- Multi-language support (agent currently PT-BR only)

### Reviewed Todos (not folded)

None — the only matched todo (RAG ingest on bootstrap) was folded into scope.

</deferred>

---

_Phase: 20-langchain-workflow_
_Context gathered: 2026-05-09_
