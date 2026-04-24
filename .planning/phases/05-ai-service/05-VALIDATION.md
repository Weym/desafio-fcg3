---
phase: 5
slug: ai-service
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-04-23
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | AST parse checks (Waves 1-2) + pytest 8.x with mocked LLM/embeddings (Wave 3) |
| **Config file** | `ai_service/pyproject.toml` or inline — created by Wave 0 if absent |
| **Quick run command** | `python -c "import ast; ast.parse(open('ai_service/main.py').read()); print('OK')"` |
| **Full suite command** | `python -m pytest ai_service/tests/ -v --tb=short` |
| **Estimated runtime** | AST checks ~2s · unit ~10s · integration (mocked LLM) ~20s |

---

## Sampling Rate

- **After every task commit:** Run the task-scoped `<automated>` verify command from the plan
- **After every plan wave:** Run `python -m pytest ai_service/tests/ -v --tb=short` (when tests exist)
- **Before `/gsd-verify-work`:** Full suite must be green + Docker healthcheck `curl -sf http://localhost:8001/health`
- **Max feedback latency:** 20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 5-01-01 | 01 | 1 | AI-01,AI-04 | — | Config with LLM_PROVIDER/LLM_MODEL env vars; system prompt in Portuguese; requirements.txt with pinned versions; no hardcoded API keys | AST parse + file check | `python -c "import ast; ast.parse(open('ai_service/config.py').read()); print('config OK')" && python -c "f=open('ai_service/prompts/system_prompt.txt'); c=f.read(); assert len(c) > 100, 'prompt too short'; print('prompt OK')" && python -c "f=open('ai_service/requirements.txt'); lines=[l.strip() for l in f if l.strip()]; assert len(lines) >= 10, f'only {len(lines)} deps'; print('requirements OK')"` | ✅ | ⬜ pending |
| 5-01-02 | 01 | 1 | AI-01,AI-04 | — | Database layer with psycopg3 pool; LLM factory using create_agent model string format (openai:model, google_genai:model); FastAPI app with /health and placeholder /chat | AST parse | `python -c "import ast; ast.parse(open('ai_service/database.py').read()); ast.parse(open('ai_service/llm_factory.py').read()); ast.parse(open('ai_service/main.py').read()); print('All files parse OK')"` | ✅ | ⬜ pending |
| 5-02-01 | 02 | 1 | AI-05 | — | 5 knowledge base documents present (matricula.md, faq.md, calendario.md, curriculo.md, regulamento.pdf) | file check | `python -c "import os; files = os.listdir('ai_service/knowledge'); expected = {'matricula.md', 'faq.md', 'calendario.md', 'curriculo.md', 'regulamento.pdf'}; missing = expected - set(files); assert not missing, f'Missing: {missing}'; print(f'All {len(expected)} files present')"` | ✅ | ⬜ pending |
| 5-02-02 | 02 | 1 | AI-05 | — | Ingest script: delete-then-insert per source; text-embedding-3-small model; CATEGORY_MAP for 6 categories; RecursiveCharacterTextSplitter token-based (500 tokens, overlap 50) | AST parse + pattern check | `python -c "import ast; ast.parse(open('ai_service/ingest.py').read()); print('ingest.py parses OK')" && python -c "import re; code=open('ai_service/ingest.py').read(); assert 'DELETE FROM knowledge_base_chunks' in code, 'missing delete'; assert 'text-embedding-3-small' in code, 'missing embedding model'; assert 'CATEGORY_MAP' in code, 'missing category map'; assert 'RecursiveCharacterTextSplitter' in code, 'missing splitter'; print('All patterns present')"` | ✅ | ⬜ pending |
| 5-03-01 | 03 | 2 | AI-03 | — | RAG tool with @tool decorator; pgvector cosine similarity; threshold 0.75; LIMIT 3 chunks; embed_query for query embedding | AST parse + pattern check | `python -c "import ast; ast.parse(open('ai_service/rag.py').read()); print('rag.py parses OK')" && python -c "code=open('ai_service/rag.py').read(); assert 'search_knowledge_base' in code; assert '0.75' in code; assert 'embed_query' in code; assert 'LIMIT 3' in code; assert '@tool' in code; print('All RAG patterns present')"` | ✅ | ⬜ pending |
| 5-04-01 | 04 | 2 | AI-01,AI-02,AI-04 | — | MCP tool loading via MultiServerMCPClient with X-Chat-Session-ID header per request; get_tools for schema discovery | AST parse + pattern check | `python -c "import ast; ast.parse(open('ai_service/mcp_tools.py').read()); print('mcp_tools.py parses OK')" && python -c "code=open('ai_service/mcp_tools.py').read(); assert 'MultiServerMCPClient' in code; assert 'X-Chat-Session-ID' in code; assert 'get_tools' in code; print('MCP patterns present')"` | ✅ | ⬜ pending |
| 5-04-02 | 04 | 2 | AI-01,AI-02,AI-04 | — | ReAct agent factory with create_agent; MCP tools + RAG tool bound; conversation history loaded from chat_messages (last 20); provider-agnostic model string; fallback message on error | AST parse + pattern check | `python -c "import ast; ast.parse(open('ai_service/agent.py').read()); print('agent.py parses OK')" && python -c "code=open('ai_service/agent.py').read(); assert 'create_agent' in code; assert 'load_mcp_tools' in code; assert 'create_rag_tool' in code; assert 'load_chat_history' in code; assert 'FALLBACK_MESSAGE' in code; assert 'ainvoke' in code; print('All agent patterns present')"` | ✅ | ⬜ pending |
| 5-05-01 | 05 | 3 | AI-01,AI-02 | — | /chat endpoint: receives message + session_id; invokes agent; saves user message and assistant response to chat_messages; no 501 placeholder | AST parse + pattern check | `python -c "import ast; ast.parse(open('ai_service/main.py').read()); print('main.py parses OK')" && python -c "code=open('ai_service/main.py').read(); assert 'invoke_agent' in code; assert 'save_chat_message' in code; assert 'ChatRequest' in code; assert 'ChatResponse' in code; assert '501' not in code or 'Not implemented' not in code; print('Endpoint patterns present, placeholder removed')"` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Integration Tests (Phase-specific Validation)

| Test ID | Scope | Requirements | Test Type | Automated Command | File Exists | Status |
|---------|-------|-------------|-----------|-------------------|-------------|--------|
| V-05-01 | Agent processes message, selects MCP tools, generates Portuguese response (mocked LLM + mocked MCP) | AI-01 | integration | `python -m pytest ai_service/tests/test_agent_flow.py -x` | ❌ W0 | ⬜ pending |
| V-05-02 | Conversation history rebuilt from last 20 messages in chat_messages; restart does not lose context | AI-02 | integration | `python -m pytest ai_service/tests/test_conversation_memory.py -x` | ❌ W0 | ⬜ pending |
| V-05-03 | RAG retriever returns only chunks with cosine similarity >= 0.75; irrelevant queries return empty | AI-03 | unit | `python -m pytest ai_service/tests/test_rag_retrieval.py -x` | ❌ W0 | ⬜ pending |
| V-05-04 | LLM_PROVIDER=openai uses openai:model; LLM_PROVIDER=gemini uses google_genai:model; no code changes needed | AI-04 | unit | `python -m pytest ai_service/tests/test_llm_factory.py -x` | ❌ W0 | ⬜ pending |
| V-05-05 | Ingest script processes all 5 knowledge base documents, generates embeddings, stores chunks with correct categories | AI-05 | integration | `python -m pytest ai_service/tests/test_ingest.py -x` | ❌ W0 | ⬜ pending |

### Coverage Matrix (Success Criteria -> Validations)

| Success Criterion | Validations |
|-------------------|-------------|
| SC-1: Agent processes message with MCP tools, generates Portuguese response | V-05-01 |
| SC-2: Conversation context rebuilt from last 20 messages, survives restart | V-05-02 |
| SC-3: RAG retriever at >= 0.75 cosine similarity; irrelevant returns empty | V-05-03 |
| SC-4: LLM_PROVIDER switches provider without code changes | V-05-04 |
| SC-5: Ingest script processes 5 docs, embeds, stores chunks | V-05-05 |

---

## Wave 0 Requirements

Test stubs and infrastructure to be created alongside or after plan execution:

- [ ] `ai_service/tests/__init__.py` — package marker
- [ ] `ai_service/tests/conftest.py` — shared fixtures: mock psycopg3 connection, mock OpenAIEmbeddings, mock LLM (FakeListChatModel or similar), mock MCP tools, seed chat_messages rows
- [ ] `ai_service/tests/test_agent_flow.py` — stubs for V-05-01 (mocked LLM + mocked MCP tools)
- [ ] `ai_service/tests/test_conversation_memory.py` — stubs for V-05-02 (load_chat_history with DB fixture)
- [ ] `ai_service/tests/test_rag_retrieval.py` — stubs for V-05-03 (cosine similarity threshold)
- [ ] `ai_service/tests/test_llm_factory.py` — stubs for V-05-04 (model string generation per provider)
- [ ] `ai_service/tests/test_ingest.py` — stubs for V-05-05 (mocked embeddings + DB)
- [ ] `ai_service/requirements-dev.txt` — `pytest>=8`, `pytest-asyncio>=0.23`, `pytest-mock>=3.12`

*Note: Waves 1-2 rely on AST parse checks and pattern assertions since the AI service has external dependencies (LLM APIs, MCP server) that cannot be tested without mocks. Wave 0 test stubs provide the mocking infrastructure.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| End-to-end agent response with real LLM (OpenAI or Gemini) | AI-01 | Requires real API key and live LLM call | 1. Set `OPENAI_API_KEY` in env 2. `docker compose up -d` 3. Seed DB + run ingest 4. `curl -X POST http://localhost:8001/chat -d '{"session_id": "...", "message": "Quais sao minhas notas?"}'` 5. Verify Portuguese response with relevant MCP tool calls |
| Provider switch: Gemini produces valid response | AI-04 | Requires real Gemini API key | 1. Set `LLM_PROVIDER=gemini`, `GOOGLE_API_KEY=...` 2. Repeat step 4 above 3. Verify response quality is acceptable |
| Ingest script with real embeddings | AI-05 | Requires real OpenAI API key for text-embedding-3-small | 1. Set `OPENAI_API_KEY` 2. `docker compose up -d postgres` 3. `python ai_service/ingest.py` 4. `psql -c "SELECT count(*), category FROM knowledge_base_chunks GROUP BY category"` 5. Verify 5+ categories with chunks |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (7 test files + conftest + requirements-dev)
- [x] No watch-mode flags
- [x] Feedback latency < 20s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-23 (by planner; awaits execution confirmation)
