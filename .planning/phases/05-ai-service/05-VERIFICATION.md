---
phase: 05-ai-service
verified: 2026-04-27T19:45:00Z
status: human_needed
score: 5/5 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/5
  gaps_closed:
    - "ingest.py reads DATABASE_URL directly from os.environ instead of using Settings object — will fail in Docker where DATABASE_URL is not set"
    - "test_compose_limits_ai_service_env_to_runtime_dependencies now fails because Plan 08 removed DATABASE_URL from langchain-service compose config but the test still asserts its presence"
  gaps_remaining: []
  regressions: []
human_verification:
  - test: "Cold start smoke test — docker compose down && docker compose up -d --build, then docker compose exec langchain-service curl -sf http://localhost:8001/health"
    expected: "Returns {\"status\":\"healthy\"} with no import or startup errors"
    why_human: "Requires running Docker containers with live PostgreSQL connection"
  - test: "Knowledge base ingest — docker compose exec langchain-service python -m ai_service.ingest with valid OPENAI_API_KEY"
    expected: "Processes 5 documents, generates embeddings, stores chunks, writes .last_ingest.json"
    why_human: "Requires live OpenAI API key and running PostgreSQL with pgvector"
  - test: "Academic policy answer — POST /chat with valid X-Service-Token and academic question"
    expected: "Returns Portuguese answer grounded in knowledge base content"
    why_human: "Requires live LLM provider, MCP server, and ingested knowledge base"
  - test: "Provider switch — set LLM_PROVIDER=gemini, restart, send same question"
    expected: "Different LLM produces valid response without code changes"
    why_human: "Requires live Gemini API key and container restart"
---

# Phase 5: AI Service Verification Report

**Phase Goal:** The LangChain ReAct agent answers student academic questions in Portuguese, using MCP tools for live data and PGVector RAG for regulation and policy, with any LLM provider configurable by environment variable.
**Verified:** 2026-04-27T19:45:00Z
**Status:** human_needed
**Re-verification:** Yes — after Plan 09 gap closure (ingest.py DATABASE_URL sourcing + stale regression test)

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Agent receives a student message, selects MCP tools, and generates a Portuguese response end-to-end | ✓ VERIFIED | `agent.py` creates ReAct agent with `create_agent(model=get_model_string(settings), tools=[...mcp_tools, rag_tool], system_prompt=...)`. `main.py /chat` saves user message → calls `invoke_agent` → saves assistant response. System prompt enforces Portuguese. Fallback message in Portuguese. |
| 2 | Conversation context rebuilt from last 20 messages on every invocation | ✓ VERIFIED | `database.py:load_chat_history` queries `chat_messages ORDER BY created_at DESC LIMIT %s` with `k=20`; reverses to chronological order. `agent.py:89-93` calls it before agent invocation. No in-memory state — fully stateless. |
| 3 | RAG retriever finds relevant policy chunks with cosine similarity ≥ 0.75 | ✓ VERIFIED | `rag.py:40-42` uses `WHERE 1 - (embedding <=> %s::vector) >= 0.75 ORDER BY similarity DESC LIMIT 3`. Returns empty string when no chunks pass threshold. `@tool` decorated for LangChain use. |
| 4 | LLM provider is configurable via LLM_PROVIDER env var (openai, gemini) | ✓ VERIFIED | `config.py:16` reads `LLM_PROVIDER`. `llm_factory.py:17-22` maps to `openai:{model}` or `google_genai:{model}`. Also supports `openrouter`. `create_llm()` instantiates correct provider class. |
| 5 | Running python -m ai_service.ingest processes all 5 knowledge documents and stores chunks in PGVector | ✓ VERIFIED | **Gap CLOSED by Plan 09.** `ingest.py:38` now imports `from ai_service.config import settings as app_settings` and reads `app_settings.DATABASE_URL` instead of `os.environ.get("DATABASE_URL")`. Behavioral spot-check confirmed: with only POSTGRES_* vars set (no DATABASE_URL), `IngestSettings.from_env()` produces a valid `postgresql://` URL. All 5 knowledge files present in `ai_service/knowledge/`. |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `ai_service/main.py` | FastAPI app with /health and /chat | ✓ VERIFIED (166 lines) | Lifespan manages DB pool + system prompt; X-Service-Token auth via `hmac.compare_digest`; ChatRequest/ChatResponse models; user+assistant persistence; Portuguese fallback |
| `ai_service/config.py` | Settings via env vars | ✓ VERIFIED (57 lines) | 12 env vars; `__post_init__` builds DATABASE_URL from POSTGRES_* components when empty; frozen dataclass |
| `ai_service/database.py` | psycopg3 pool + chat history | ✓ VERIFIED (78 lines) | create_pool, load_chat_history (DESC→reverse), save_chat_message (gen_random_uuid()), check_db_health, normalize_psycopg_dsn |
| `ai_service/agent.py` | ReAct agent factory + invoke | ✓ VERIFIED (118 lines) | create_chat_agent with model string; _extract_response_text walks reversed messages for last AIMessage; asyncio.wait_for timeout; fallback message |
| `ai_service/rag.py` | RAG tool with pgvector search | ✓ VERIFIED (68 lines) | create_rag_tool factory; @tool decorated; cosine similarity ≥ 0.75; LIMIT 3; text-embedding-3-small; returns formatted chunks or empty string |
| `ai_service/ingest.py` | Knowledge base ingestion | ✓ VERIFIED (267 lines) | **Gap CLOSED.** `IngestSettings.from_env()` now delegates to `ai_service.config.settings.DATABASE_URL`. Full pipeline: chunking, embedding, delete-then-insert per source. |
| `ai_service/llm_factory.py` | Provider-agnostic LLM factory | ✓ VERIFIED (57 lines) | get_model_string for openai/gemini/openrouter; create_llm instantiates correct provider class |
| `ai_service/mcp_tools.py` | MCP tool loading | ✓ VERIFIED (30 lines) | MultiServerMCPClient with X-Chat-Session-ID header; async get_tools() |
| `ai_service/prompts/system_prompt.txt` | Canonical system prompt | ✓ VERIFIED (13 lines) | Portuguese academic assistant prompt; 8 rules from docs/chatbot.md |
| `ai_service/requirements.txt` | Python dependencies | ✓ VERIFIED | langchain, langchain-mcp-adapters, langchain-openai, langchain-google-genai, psycopg, fastapi, uvicorn, etc. |
| `ai_service/knowledge/` | 5 knowledge base documents | ✓ VERIFIED | matricula.md, faq.md, calendario.md, curriculo.md, regulamento.pdf all present |
| `ai_service/Dockerfile` | Container startup | ✓ VERIFIED | `CMD ["python", "-m", "ai_service.main"]`; copies package correctly |
| `docker-compose.yml` | langchain-service config | ✓ VERIFIED | `command: python -m ai_service.main`; `./ai_service:/app/ai_service` mount; POSTGRES_* component vars; no DATABASE_URL; no host port |
| `ai_service/tests/test_runtime_entrypoint.py` | Runtime regressions | ✓ VERIFIED (77 lines) | **Gap CLOSED.** Asserts POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_HOST, POSTGRES_PORT. Negative assertion: `DATABASE_URL:` not in langchain-service env. All 4 compose/file tests pass (1 import test pre-existing failure due to missing langchain_mcp_adapters in local dev). |
| `ai_service/tests/test_chat_gap_closure.py` | Chat persistence tests | ✓ VERIFIED (114 lines) | Tests extract_response_text, chat_persists_user_before_agent, chat_persists_fallback (cannot run locally — requires langchain_mcp_adapters; designed for Docker) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `main.py` | `config.py` | `from ai_service.config import settings` | ✓ WIRED | Line 15 |
| `main.py` | `database.py` | `create_pool, save_chat_message, check_db_health` | ✓ WIRED | Line 16; used in lifespan (pool), /chat (save), /health (check) |
| `main.py` | `agent.py` | `invoke_agent` | ✓ WIRED | Line 14; called in /chat endpoint line 120 |
| `agent.py` | `mcp_tools.py` | `from ai_service.mcp_tools import load_mcp_tools` | ✓ WIRED | Line 14; called in invoke_agent line 85 |
| `agent.py` | `rag.py` | `from ai_service.rag import create_rag_tool` | ✓ WIRED | Line 15; called in invoke_agent line 86 |
| `agent.py` | `llm_factory.py` | `from ai_service.llm_factory import get_model_string` | ✓ WIRED | Line 13; used in create_chat_agent line 29 |
| `agent.py` | `database.py` | `from ai_service.database import load_chat_history` | ✓ WIRED | Line 12; called in invoke_agent line 89 |
| `mcp_tools.py` | MCP server | `MultiServerMCPClient` with `X-Chat-Session-ID` | ✓ WIRED | Lines 19-29 |
| `rag.py` | `knowledge_base_chunks` | pgvector cosine similarity | ✓ WIRED | Lines 35-53 with parameterized query |
| `rag.py` | OpenAI Embeddings | `embed_query` via text-embedding-3-small | ✓ WIRED | Lines 19-22 and 32 |
| `ingest.py` | `config.py` | `from ai_service.config import settings as app_settings` | ✓ WIRED | **Gap CLOSED.** Line 38; uses `app_settings.DATABASE_URL` |
| `ingest.py` | `database.py` | `normalize_psycopg_dsn` | ✓ WIRED | Line 15 |
| `ingest.py` | `knowledge_base_chunks` | DELETE + INSERT per source | ✓ WIRED | Lines 140-163 |
| `Dockerfile` | `main.py` | `python -m ai_service.main` | ✓ WIRED | Line 15 |
| `docker-compose.yml` | `main.py` | `command: python -m ai_service.main` | ✓ WIRED | Line 115 |
| `docker-compose.yml` | bind mount | `./ai_service:/app/ai_service` | ✓ WIRED | Line 102 |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `main.py /chat` | `response_text` | `invoke_agent()` → `create_agent().ainvoke()` | LLM-generated response | ✓ FLOWING — agent invocation returns real LLM output |
| `main.py /chat` | `request.message` | HTTP POST body | User input | ✓ FLOWING — saved to chat_messages before agent |
| `database.py load_chat_history` | `rows` | SQL query to `chat_messages` | DB query result | ✓ FLOWING — parameterized SELECT with LIMIT |
| `rag.py search_knowledge_base` | `rows` | SQL query to `knowledge_base_chunks` | DB query with pgvector | ✓ FLOWING — cosine similarity query |
| `agent.py _extract_response_text` | `result["messages"]` | LangChain agent output | Agent message list | ✓ FLOWING — reversed scan for last AIMessage |
| `ingest.py IngestSettings.from_env` | `database_url` | `app_settings.DATABASE_URL` via config.py | Settings singleton with POSTGRES_* fallback | ✓ FLOWING — behavioral spot-check confirmed URL derived from component vars |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| All source files parse without syntax errors | `python -c "import ast; ..."` for 8 files | All 8 files parse OK | ✓ PASS |
| IngestSettings derives DATABASE_URL from POSTGRES_* | Simulated Docker env (no DATABASE_URL, POSTGRES_* set) | `postgresql://fcg3:test_pass@postgres:5432/fcg3` | ✓ PASS |
| Runtime entrypoint tests pass | `pytest test_runtime_entrypoint.py -v -k "not test_import"` | 4 passed, 0 failed | ✓ PASS |
| Regression test asserts POSTGRES_* component vars | Inspected assertions in test file lines 61-65 | 5 POSTGRES_* assertions + negative DATABASE_URL assertion | ✓ PASS |
| DATABASE_URL absent from langchain-service compose section | docker-compose.yml lines 85-116 | Only POSTGRES_* vars present; no DATABASE_URL | ✓ PASS |
| Plan 09 commits exist in git | `git log --oneline 20315cc eb35c8f` | Both verified: `20315cc` (ingest fix), `eb35c8f` (test fix) | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| AI-01 | 05-01, 05-04, 05-05, 05-06 | ReAct agent processes messages, calls MCP tools, generates Portuguese response | ✓ SATISFIED | agent.py creates ReAct agent; loads MCP + RAG tools; main.py /chat wires end-to-end; system prompt enforces Portuguese |
| AI-02 | 05-01, 05-04, 05-05, 05-06 | Conversation memory rebuilt from DB (last 20) on every invocation | ✓ SATISFIED | database.py load_chat_history queries last 20 messages; agent.py injects into agent input; main.py saves user+assistant turns |
| AI-03 | 05-03 | RAG search with cosine similarity ≥ 0.75 threshold | ✓ SATISFIED | rag.py implements pgvector query with WHERE similarity >= 0.75, LIMIT 3, returns formatted chunks or empty |
| AI-04 | 05-01, 05-04 | LLM provider configurable via env var | ✓ SATISFIED | config.py reads LLM_PROVIDER; llm_factory.py maps to provider:model strings for openai/gemini/openrouter |
| AI-05 | 05-02, 05-09 | Ingest script processes 5 knowledge docs into PGVector | ✓ SATISFIED | **Unblocked by Plan 09.** ingest.py full pipeline present; IngestSettings now derives DATABASE_URL from shared config.settings; all 5 knowledge docs present |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `ai_service/agent.py` | 28-29 | `get_model_string(settings)` instead of `create_llm(settings)` for OpenRouter | ⚠️ Warning | OpenRouter provider path may not work correctly since `create_agent` uses model string, not a pre-built model instance — WR-01 from 05-REVIEW.md. Not a blocker for openai/gemini. |
| `ai_service/main.py` | 113-133 | Synchronous DB calls in async handler | ℹ️ Info | WR-03 from 05-REVIEW.md — `save_chat_message` is sync psycopg3 in an async endpoint. Acceptable for MVP load. |
| `ai_service/tests/test_runtime_entrypoint.py` | 12 | `test_import_preserves_health_and_chat_routes` fails locally (missing `langchain_mcp_adapters`) | ℹ️ Info | Pre-existing issue — package only available inside Docker. Not a Plan 09 regression. Other 4 tests pass. |

### Human Verification Required

### 1. Cold Start Smoke Test

**Test:** Kill containers (`docker compose down`), rebuild (`docker compose up -d --build`), then `docker compose exec langchain-service curl -sf http://localhost:8001/health`
**Expected:** Returns `{"status":"healthy"}` with no import/startup errors
**Why human:** Requires live Docker + PostgreSQL connection — validates full container wiring

### 2. Knowledge Base Ingest (Gap Closure Validation)

**Test:** Run `docker compose exec langchain-service python -m ai_service.ingest` with valid `OPENAI_API_KEY` in `.env`
**Expected:** Processes 5 documents, prints chunk counts per category, writes `.last_ingest.json`
**Why human:** Requires live OpenAI API key for embedding generation and running PostgreSQL with pgvector — this specifically validates Plan 09's fix

### 3. Academic Policy Answer

**Test:** Send authorized `POST /chat` with `X-Service-Token` and question "Quais sao as regras de matricula?"
**Expected:** Portuguese answer grounded in knowledge base content — not generic fallback
**Why human:** Requires live LLM provider, running MCP server, and ingested knowledge base

### 4. Provider Switch

**Test:** Set `LLM_PROVIDER=gemini`, restart langchain-service, send same academic question
**Expected:** Gemini produces valid Portuguese response without code changes
**Why human:** Requires live Gemini API key and container restart

### Gaps Summary

**All gaps from previous verification are now CLOSED:**

Plan 09 successfully fixed both remaining gaps:
- ✅ **ingest.py DATABASE_URL sourcing** — `IngestSettings.from_env()` now imports `ai_service.config.settings.DATABASE_URL` (line 38-40) instead of reading `os.environ.get("DATABASE_URL")`. Behavioral spot-check confirmed: with only POSTGRES_* vars set, produces valid `postgresql://fcg3:test_pass@postgres:5432/fcg3`.
- ✅ **Stale regression test** — `test_compose_limits_ai_service_env_to_runtime_dependencies` now asserts 5 POSTGRES_* component vars (lines 61-65) and has a negative assertion that `DATABASE_URL:` is not present (line 77). All 4 compose/file tests pass green.

**No new gaps found.** All 5 ROADMAP success criteria are satisfied at the code level. 4 human verification items remain (require live Docker + API keys) to confirm runtime behavior.

---

_Verified: 2026-04-27T19:45:00Z_
_Verifier: the agent (gsd-verifier)_
