---
phase: 05-ai-service
verified: 2026-05-02T19:30:00Z
status: human_needed
score: 5/5 must-haves verified
overrides_applied: 1
overrides:
  - must_have: "RAG retriever finds relevant policy chunks from the knowledge base with cosine similarity threshold calibrated at ≥ 0.75"
    reason: "Threshold was intentionally lowered from 0.75 to 0.45 (and made configurable via RAG_SIMILARITY_THRESHOLD env var) during Plan 05-10 gap closure. OpenRouter-proxied text-embedding-3-small produces a different similarity distribution than OpenAI direct — UAT evidence showed even exact-title matches only score 0.6685 (range 0.49–0.67 for relevant content). The threshold remains calibrated — it is now calibrated for the actual embedding provider in use. Rationale documented in 05-10-PLAN.md."
    accepted_by: "user (stated in verification prompt)"
    accepted_at: "2026-05-02T19:30:00Z"
re_verification:
  previous_status: human_needed
  previous_score: 5/5
  gaps_closed:
    - "UAT Test 3 blocker: RAG SIMILARITY_THRESHOLD=0.75 too high for OpenRouter embedding distribution — fixed by Plan 05-10 (default 0.45, configurable via env var)"
    - "UAT Additional Finding: mcp_action_logs INSERT missing gen_random_uuid() for id column — fixed by Plan 05-10"
    - "Cross-phase regression: test_agent_flow.py SimpleNamespace settings missing RAG_SIMILARITY_THRESHOLD — fixed by commit 158b9d5"
    - "Cross-phase regression: test_conversation_memory.py SimpleNamespace settings missing RAG_SIMILARITY_THRESHOLD — fixed by commit 158b9d5"
    - "Cross-phase regression: fake_create_rag_tool stub signature missing similarity_threshold kwarg — fixed by commit 158b9d5"
    - "HUMAN-UAT Blocker 1: MCP server not injecting X-Student-Id header on proxied requests — all tool calls failing with IDENTIFICACAO_AUSENTE — fixed by Plan 05-11 (centralized header injection in api_client.py, all 16 tools wired)"
    - "HUMAN-UAT Blocker 2: System prompt told agent RAG threshold is 0.75 when code uses 0.45 — fixed by Plan 05-11 (threshold in system_prompt.txt corrected to 0.45)"
  gaps_remaining: []
  regressions: []
human_verification:
  - test: "End-to-end academic answer with tuned threshold (re-run UAT Test 3)"
    expected: "POST /chat with valid X-Service-Token and Portuguese academic question returns a response grounded in knowledge base content (not the generic fallback). With RAG_SIMILARITY_THRESHOLD=0.45 default and OpenRouter embeddings scoring ~0.49-0.67 for relevant content, the RAG tool should now return chunks. Agent should cite specific policy details (e.g., enrollment rules, deadlines) rather than saying it has no information."
    why_human: "Requires live OpenRouter/OpenAI LLM, live OpenRouter embeddings, live PostgreSQL with ingested knowledge_base_chunks, and running MCP server. This specifically validates Plan 05-10 Task 1 (configurable threshold) against real embedding scores — unit tests cover the code contract but not the embedding provider behavior."
  - test: "End-to-end agent tool call without MCP action-log crash (validates Plan 05-10 Task 2)"
    expected: "POST /chat with a question that forces the agent to invoke an MCP tool (e.g., \"Quais sao minhas matriculas ativas?\") completes without the cascading agent failure previously caused by NOT NULL violation on mcp_action_logs.id. Verify by querying: SELECT id, tool_name, status FROM mcp_action_logs ORDER BY created_at DESC LIMIT 5 — should show newly populated rows with non-null UUIDs."
    why_human: "Requires live MCP server, live LLM, live PostgreSQL. Unit test now asserts gen_random_uuid() appears in the SQL string, but only a live Postgres INSERT confirms the id column is populated without error."
  - test: "Provider switch (Gemini) produces valid response"
    expected: "Set LLM_PROVIDER=gemini with valid GEMINI_API_KEY, restart langchain-service, send the same Portuguese academic question. Gemini produces a valid Portuguese response without any code changes. (This SC #4 test was never exercised in 05-UAT.md — default provider during UAT was OpenAI/OpenRouter.)"
    why_human: "Requires live Gemini API key and container restart. Code-level verification confirms llm_factory.py handles the provider string mapping and instantiation, but only a live call confirms the credentials, model name, and response parsing all work end-to-end."
---

# Phase 5: AI Service Verification Report

**Phase Goal:** The LangChain ReAct agent answers student academic questions in Portuguese, using MCP tools for live data and PGVector RAG for regulation and policy, with any LLM provider configurable by environment variable.
**Verified:** 2026-05-02T19:30:00Z
**Status:** human_needed
**Re-verification:** Yes — after Plan 05-10 gap closure (RAG threshold configurable + MCP UUID fix + cross-phase regression fix) and Plan 05-11 gap closure (X-Student-Id header injection + system prompt threshold fix)

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Agent receives a student message, selects MCP tools, calls them, and generates a Portuguese response end-to-end | ✓ VERIFIED (code) | `agent.py:invoke_agent` loads MCP tools (`load_mcp_tools`), creates RAG tool, builds ReAct agent via `create_agent`, injects Portuguese system prompt. `main.py /chat` saves user turn → invokes agent → saves assistant turn. UAT Tests 1, 4, 5, 6 previously passed live. Live re-run of Test 3 needed to confirm grounded answer with new threshold. |
| 2 | Conversation context rebuilt from last 20 messages on every invocation | ✓ VERIFIED | `database.py:load_chat_history` SELECTs `chat_messages ORDER BY created_at DESC LIMIT %s` with k=20; `agent.py:96-100` calls it before every agent invocation. UAT Test 4 previously passed live — agent correctly referenced prior conversation. |
| 3 | RAG retriever finds relevant policy chunks with cosine similarity above calibrated threshold | ✓ VERIFIED (override) | Threshold now sourced from `settings.RAG_SIMILARITY_THRESHOLD` (default 0.45, env-configurable). `rag.py:38` uses `WHERE 1 - (embedding <=> %s::vector) >= %s`; `rag.py:47` passes threshold as SQL parameter. Original ROADMAP specified ≥ 0.75 — documented override applied per user instruction because OpenRouter embedding proxy caps at ~0.67 for relevant content. |
| 4 | LLM provider configurable via LLM_PROVIDER env var (openai, gemini, openrouter) | ✓ VERIFIED (code) | `config.py:16` reads `LLM_PROVIDER`. `llm_factory.py` handles openai/gemini/openrouter via `get_model_string` (model-string path used by `create_agent`) and `create_llm`. Unit tests `test_llm_factory.py` cover all three providers and the unsupported-provider error path — all pass. Live provider-switch (Gemini) remains a human-verification item. |
| 5 | Running `python -m ai_service.ingest` processes all 5 knowledge documents into PGVector | ✓ VERIFIED | `ingest.py:38` imports `ai_service.config.settings` and uses `app_settings.DATABASE_URL`. All 5 knowledge files present in `ai_service/knowledge/` (matricula.md, faq.md, calendario.md, curriculo.md, regulamento.pdf). UAT Test 2 previously passed live — 5 docs ingested into 17 chunks. |

**Score:** 5/5 truths verified (1 via documented override)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `ai_service/config.py` | Settings with RAG_SIMILARITY_THRESHOLD | ✓ VERIFIED | Lines 37-39 add field; default 0.45; reads `RAG_SIMILARITY_THRESHOLD` env var. Existing 12 env vars preserved; DATABASE_URL POSTGRES_* fallback intact. |
| `ai_service/rag.py` | create_rag_tool with configurable threshold | ✓ VERIFIED | Line 13-17: signature accepts `similarity_threshold: float = 0.45`. Line 47: threshold passed as SQL parameter. Hardcoded `SIMILARITY_THRESHOLD = 0.75` module constant removed. |
| `ai_service/agent.py` | invoke_agent passes threshold from settings | ✓ VERIFIED | Lines 89-93: `create_rag_tool(db_pool, embeddings, similarity_threshold=settings.RAG_SIMILARITY_THRESHOLD)`. |
| `ai_service/main.py` | FastAPI /health and /chat with X-Service-Token | ✓ VERIFIED | Service-token check at lines 22-36; lifespan manages DB pool; user + assistant persistence. |
| `ai_service/database.py` | psycopg3 pool + chat history + save | ✓ VERIFIED | `load_chat_history` (DESC→reverse → chronological), `save_chat_message` (gen_random_uuid()), `check_db_health`. |
| `ai_service/llm_factory.py` | Provider-agnostic factory | ✓ VERIFIED | get_model_string + create_llm support openai/gemini/openrouter; clear error for unsupported. |
| `ai_service/ingest.py` | 5-doc pipeline using shared Settings | ✓ VERIFIED | Reads DATABASE_URL + embedding config from `ai_service.config.settings`. Delete-then-insert per source. |
| `ai_service/mcp_tools.py` | MCP client with X-Chat-Session-ID header | ✓ VERIFIED | MultiServerMCPClient with per-session header; async `load_mcp_tools`. |
| `ai_service/prompts/system_prompt.txt` | Portuguese academic assistant prompt | ✓ VERIFIED | 13 lines, 8 rules from docs/chatbot.md. |
| `ai_service/knowledge/` | 5 documents present | ✓ VERIFIED | matricula.md, faq.md, calendario.md, curriculo.md, regulamento.pdf — all present. |
| `mcp_server/middleware.py` | INSERT INTO mcp_action_logs with id + gen_random_uuid() | ✓ VERIFIED | Line 103 adds `id,` to column list; line 113 adds `gen_random_uuid(),` as first VALUES entry; positional parameters $1-$8 unchanged. |
| `docker-compose.yml` | langchain-service runs package entrypoint, POSTGRES_* env | ✓ VERIFIED | `command: python -m ai_service.main`, bind-mount `./ai_service:/app/ai_service`, POSTGRES_* component vars (no DATABASE_URL), no host port exposed. |
| `ai_service/tests/test_rag_retrieval.py` | Threshold configurability tests | ✓ VERIFIED | `test_retrieval_uses_custom_threshold` present (line 75 passing); no import of removed SIMILARITY_THRESHOLD constant; all 3 tests pass. |
| `mcp_server/tests/test_middleware_logging.py` | gen_random_uuid() assertion | ✓ VERIFIED | `assert "gen_random_uuid()" in query` present; 10/10 tests pass. |
| `ai_service/tests/test_agent_flow.py` | SimpleNamespace settings include RAG_SIMILARITY_THRESHOLD | ✓ VERIFIED | Commit 158b9d5 added RAG_SIMILARITY_THRESHOLD=0.45 to SimpleNamespace (line 69) and extended `fake_create_rag_tool` to accept `similarity_threshold=0.45` kwarg (line 27); test passes. |
| `ai_service/tests/test_conversation_memory.py` | SimpleNamespace settings include RAG_SIMILARITY_THRESHOLD | ✓ VERIFIED | Commit 158b9d5 added RAG_SIMILARITY_THRESHOLD=0.45 (line 102); test passes. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `main.py` | `config.py` | `from ai_service.config import settings` | ✓ WIRED | Used in lifespan, auth, /chat |
| `main.py` | `database.py` | `create_pool`, `save_chat_message`, `check_db_health` | ✓ WIRED | Pool in lifespan; save on user + assistant turns; health check |
| `main.py` | `agent.py` | `invoke_agent` | ✓ WIRED | Called in /chat handler with session_id |
| `agent.py` | `mcp_tools.py` | `load_mcp_tools(MCP_SERVER_URL, session_id)` | ✓ WIRED | Per-session client for X-Chat-Session-ID header |
| `agent.py` | `rag.py` | `create_rag_tool(db_pool, embeddings, similarity_threshold=settings.RAG_SIMILARITY_THRESHOLD)` | ✓ WIRED | **Plan 05-10 new wiring** — threshold flows from Settings into tool factory |
| `agent.py` | `llm_factory.py` | `get_model_string(settings)` in create_chat_agent | ✓ WIRED | Produces `openai:{model}` / `google_genai:{model}` string for `create_agent` |
| `agent.py` | `database.py` | `load_chat_history(db_pool, session_id, k=settings.CHAT_HISTORY_K)` | ✓ WIRED | Called before every agent invocation |
| `rag.py` | `knowledge_base_chunks` | pgvector `embedding <=> %s::vector` with threshold parameter | ✓ WIRED | Parameterized similarity threshold; LIMIT 3 |
| `rag.py` | OpenAI Embeddings | `embeddings.embed_query(query)` | ✓ WIRED | via text-embedding-3-small |
| `ingest.py` | `config.py` | `from ai_service.config import settings as app_settings` | ✓ WIRED | Lines 38, 188 |
| `mcp_server/middleware.py` | `mcp_action_logs.id` | INSERT with `gen_random_uuid()` in VALUES | ✓ WIRED | **Plan 05-10 new wiring** — server-side UUID generation, positional params unchanged |
| `Dockerfile` | `main.py` | `CMD ["python", "-m", "ai_service.main"]` | ✓ WIRED | Package entrypoint |
| `docker-compose.yml` | `main.py` | `command: python -m ai_service.main` | ✓ WIRED | Plus bind mount and POSTGRES_* env |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `main.py /chat` | `response_text` | `invoke_agent` → `create_agent().ainvoke()` → LangChain | Real LLM call | ✓ FLOWING (unit tests cover contract; live LLM call confirmed by prior UAT Test 4) |
| `database.py load_chat_history` | `rows` | SQL SELECT on chat_messages | DB query | ✓ FLOWING (parameterized LIMIT k) |
| `rag.py search_knowledge_base` | `rows` | SQL SELECT with pgvector + threshold parameter | DB query | ✓ FLOWING (threshold now env-configurable) |
| `agent.py invoke_agent` | `similarity_threshold` | `settings.RAG_SIMILARITY_THRESHOLD` from env | Real config value | ✓ FLOWING (Plan 05-10 new path — unit test `test_retrieval_uses_custom_threshold` confirms value propagates to SQL params) |
| `mcp_server middleware` | `id` | `gen_random_uuid()` server-side in INSERT | Postgres-generated UUID | ✓ FLOWING at code level — live INSERT remains human-verification item |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| ai_service test suite | `pytest ai_service/tests/ -v` | 20 passed, 0 failed | ✓ PASS |
| MCP middleware logging tests | `pytest mcp_server/tests/test_middleware_logging.py -v` | 10 passed, 0 failed | ✓ PASS |
| RAG threshold configurability | `grep -n "RAG_SIMILARITY_THRESHOLD" ai_service/config.py ai_service/rag.py ai_service/agent.py` | Returns wiring in all 3 files | ✓ PASS |
| Hardcoded threshold removed | `grep -n "SIMILARITY_THRESHOLD = 0.75" ai_service/rag.py` | Empty result | ✓ PASS |
| MCP INSERT has gen_random_uuid() | `grep -n "gen_random_uuid" mcp_server/middleware.py` | Line 113 | ✓ PASS |
| Plan 05-10 commits present | `git log --oneline` | 97fb2d1 (feat RAG), 34d881e (fix UUID), 158b9d5 (fix regression) | ✓ PASS |
| Cross-phase regression fix wires similarity_threshold into fake stub | `git show 158b9d5` | Diff adds kwarg + SimpleNamespace field to 2 test files | ✓ PASS |
| All 5 knowledge docs present | `ls ai_service/knowledge/` | matricula.md, faq.md, calendario.md, curriculo.md, regulamento.pdf | ✓ PASS |
| Live chat happy path (Test 3) | N/A — requires live LLM + DB + MCP | — | ? SKIP (human_verification) |
| Live provider switch (Gemini) | N/A — requires live Gemini key + restart | — | ? SKIP (human_verification) |
| Live MCP tool call without crash | N/A — requires live stack | — | ? SKIP (human_verification) |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| AI-01 | 05-01, 05-04, 05-05, 05-06 | ReAct agent processes messages, calls MCP tools, generates Portuguese response | ✓ SATISFIED | agent.py creates ReAct agent via `create_agent`; loads MCP + RAG tools; main.py /chat wires end-to-end; system prompt enforces Portuguese; fallback message is Portuguese. UAT Tests 1, 4, 5, 6 previously passed live. |
| AI-02 | 05-01, 05-04, 05-05 | Conversation memory rebuilt from DB (last 20) on every invocation | ✓ SATISFIED | database.py load_chat_history DESC→reverse→chronological with k=20; agent.py injects on every call; no in-memory state. UAT Test 4 previously passed live. |
| AI-03 | 05-03, 05-10 | RAG search with calibrated cosine similarity threshold | ✓ SATISFIED (override) | rag.py uses parameterized threshold; default 0.45 via settings (documented OpenRouter calibration per Plan 05-10 rationale). Override accepted per verification prompt. |
| AI-04 | 05-01, 05-04 | LLM provider configurable via env var | ✓ SATISFIED (code) | config.py reads LLM_PROVIDER; llm_factory.py handles openai/gemini/openrouter; unit tests cover all three. Live Gemini switch remains human-verification. |
| AI-05 | 05-02, 05-09 | Ingest script processes 5 knowledge docs into PGVector | ✓ SATISFIED | ingest.py uses shared Settings for DATABASE_URL; delete-then-insert per source; all 5 knowledge docs present. UAT Test 2 previously passed live (5 docs → 17 chunks). |
| MCP-03 | 05-10 (cross-phase fix) | MCP action log INSERT succeeds (no NOT NULL violation on id) | ✓ SATISFIED | middleware.py INSERT now lists `id` and uses `gen_random_uuid()` in VALUES; unit test asserts `"gen_random_uuid()" in query`; live INSERT confirmation remains human-verification. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `ai_service/agent.py` | ~28-29 | `get_model_string(settings)` instead of `create_llm(settings)` for OpenRouter | ⚠️ Warning | Legacy finding from 05-REVIEW.md (WR-01). OpenRouter path relies on model-string inference; may not honor custom base_url/api_key via `create_agent`. Not a blocker for Phase 5 passing — affects OpenRouter provider path only. |
| `ai_service/main.py` | 113-133 | Synchronous psycopg3 calls in async handler | ℹ️ Info | Legacy finding from 05-REVIEW.md (WR-03). Acceptable for MVP load; not a functional defect. |
| `ai_service/tests/` | N/A | No integration test for live provider switch (AI-04) | ℹ️ Info | Unit tests cover code contract for all three providers; live switch verification deferred to human_verification. |

### Human Verification Required

### 1. End-to-End Academic Answer with Tuned Threshold (Re-run UAT Test 3)

**Test:** From inside the Docker network, send a POST to `/chat` with a valid `X-Service-Token` and a Portuguese academic question such as `"Quais sao as regras de matricula?"`
**Expected:** Response contains a Portuguese answer grounded in knowledge base content — cites specific enrollment rules rather than the generic "nao encontrei informacao" fallback. With `RAG_SIMILARITY_THRESHOLD=0.45` (new default) and OpenRouter embeddings scoring ~0.49-0.67 for relevant content, the RAG tool should now return matching chunks.
**Why human:** Requires live OpenRouter/OpenAI LLM, live OpenRouter embeddings, running PostgreSQL with ingested knowledge_base_chunks, and running MCP server. This specifically validates Plan 05-10 Task 1 against real embedding scores — unit tests cover the code contract but not the embedding provider's actual score distribution.

### 2. End-to-End Agent Tool Call Without MCP Action-Log Crash (Plan 05-10 Task 2 Validation)

**Test:** Send a POST `/chat` with a question that forces the agent to invoke an MCP tool, such as `"Quais sao minhas matriculas ativas?"` (expected to trigger `get_enrollments` or similar). After the call, run `SELECT id, tool_name, status FROM mcp_action_logs ORDER BY created_at DESC LIMIT 5;` inside the postgres container.
**Expected:** The /chat call completes without the cascading agent failure previously caused by the NOT NULL violation. The query returns recent rows with non-null UUIDs in the `id` column — confirming `gen_random_uuid()` is populating it correctly.
**Why human:** Requires live MCP server, live LLM, live PostgreSQL. Unit test asserts the SQL string contains `gen_random_uuid()` but only a live Postgres INSERT confirms the id column is populated without error.

### 3. Provider Switch (Gemini) Produces Valid Response

**Test:** In `.env` set `LLM_PROVIDER=gemini` with a valid `GEMINI_API_KEY`, run `docker compose restart langchain-service`, then send the same Portuguese academic question from Test 1.
**Expected:** Gemini produces a valid Portuguese response without any code changes — demonstrating SC #4's provider agnosticism end-to-end. Previously not exercised in live UAT (default provider was OpenAI/OpenRouter).
**Why human:** Requires live Gemini API key and container restart. Code-level verification confirms `llm_factory.py` handles the provider string mapping and instantiation; only a live call confirms credentials, model name, and response parsing all work.

### Gaps Summary

**All code-level gaps from previous verifications are now CLOSED.**

Plan 05-10 successfully closed both remaining runtime blockers from 05-UAT.md:

- ✅ **RAG threshold too aggressive for OpenRouter** (UAT Test 3 blocker) — `RAG_SIMILARITY_THRESHOLD` added to `ai_service.config.Settings` with default 0.45 (env-configurable); `create_rag_tool` accepts `similarity_threshold` kwarg; `invoke_agent` passes `settings.RAG_SIMILARITY_THRESHOLD`; hardcoded `SIMILARITY_THRESHOLD = 0.75` module constant removed; new unit test `test_retrieval_uses_custom_threshold` confirms propagation. Threshold change is a documented calibration override (accepted per verification prompt), not a reduction in SC strictness.
- ✅ **MCP action logs NOT NULL violation** (UAT Additional Finding) — `mcp_server/middleware.py` INSERT now lists `id` first and uses `gen_random_uuid()` in VALUES clause; positional parameters $1-$8 unchanged; unit test asserts `"gen_random_uuid()" in query`. Eliminates the cascading agent failure that crashed tool-invoking chat flows.
- ✅ **Cross-phase regression from Plan 05-10** — commit 158b9d5 updated `test_agent_flow.py` and `test_conversation_memory.py` SimpleNamespace settings mocks to include `RAG_SIMILARITY_THRESHOLD=0.45` and extended the `fake_create_rag_tool` stub to accept the new `similarity_threshold` kwarg. All 20 ai_service tests pass (up from 18 pre-fix, plus 2 that would have broken without the regression fix).

Plan 05-11 closed the two HUMAN-UAT blockers:

- ✅ **MCP X-Student-Id header not injected** (HUMAN-UAT Blocker 1) — `api_client.py` `call_api_raw` and `call_api` now accept `student_id: str | None = None` kwarg; when provided, merges `X-Student-Id` header. All 16 MCP tools pass `student_id=student_id`. 9 tools that previously lacked it now resolve via `Depends(resolve_student_id)`. 4 regression tests added. 57 MCP server tests pass.
- ✅ **System prompt threshold mismatch** (HUMAN-UAT Blocker 2) — `system_prompt.txt` corrected from 0.75 to 0.45 to match `RAG_SIMILARITY_THRESHOLD` code default.

**No new code-level gaps found.** All 5 ROADMAP success criteria are satisfied at the code level, with SC #3 accepted via documented override. Three human-verification items remain (require live Docker + API keys) to confirm runtime behavior — in particular to re-run the specific UAT case (Test 3) that previously failed and to exercise SC #4 live with Gemini.

---

_Verified: 2026-05-02T19:30:00Z_
_Verifier: the agent (gsd-verifier)_
