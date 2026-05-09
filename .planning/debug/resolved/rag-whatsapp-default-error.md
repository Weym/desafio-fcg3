---
status: resolved
trigger: "rag-whatsapp-default-error: Bot retorna mensagem default de erro em vez de usar RAG quando perguntas conceituais chegam via WhatsApp webhook"
created: 2026-05-06T00:00:00Z
updated: 2026-05-06T05:53:35Z
resolved: 2026-05-06T05:53:35Z
---

## Current Focus

hypothesis: O bot retorna FALLBACK_MESSAGE porque o agente LangChain **morre** quando qualquer tool chamada lança ToolException. Duas causas convergentes:
  (A) `knowledge_base_chunks` está VAZIA (0 linhas) — RAG sempre retorna string vazia, forçando o LLM a tentar MCP tools que não fazem sentido para a pergunta.
  (B) Várias MCP tools (`get_available_courses`, `get_course_prerequisites`, `get_available_slots`) lançam `ToolException` quando a API backend retorna 5xx / 400 — e a default `handle_tool_errors` do LangGraph `ToolNode` re-raises, matando o agent loop.
test: Confirmado nos logs — `knowledge_base_chunks count = 0`; tracebacks em `fcg3-ai` mostram `ToolException` propagando de `langchain_mcp_adapters` através de `langgraph.prebuilt.tool_node._default_handle_tool_errors` até `agent.py:104` `asyncio.wait_for(agent.ainvoke(...))`.
expecting: (1) ingerir knowledge base → perguntas RAG funcionam; (2) configurar `handle_tool_errors=True` (ou callable) no `create_agent` → qualquer falha de MCP tool vira mensagem "tool failed" para o LLM continuar, em vez de matar o agent.
next_action: Confirmar via execução direta do ingest e verificar se existe MCP tool validation bug separado; depois aplicar ambos os fixes.

## Fallback Chain (onde a string "Desculpe..." aparece)

Três lugares emitem uma versão da fallback message:
1. `backend/src/features/webhook/background.py:26-29` — "Desculpe, estou com dificuldades tecnicas. Tente novamente em alguns minutos." (quando backend não consegue chamar `ai_service/chat`)
2. `ai_service/main.py:141-144` — idêntica à anterior (wrap genérico no `/chat` endpoint)
3. `ai_service/agent.py:20-23` — "Desculpe, estou com dificuldades tecnicas para processar sua solicitacao. Tente novamente em alguns minutos ou procure a secretaria." (retornada de `invoke_agent` em timeout, GraphRecursionError, ou Exception)

Qual é emitida depende de **onde** a cadeia falha. No caminho atual, o agente **sempre** cai no #3 (FALLBACK_MESSAGE do agent.py) porque ToolException do MCP propaga até o `except Exception` em `invoke_agent`.

## Symptoms

expected: Aluno pergunta algo coberto pela base de conhecimento (regras de matrícula, FAQ, documentos, currículo) via WhatsApp → LangChain agent faz retrieval semântico em `knowledge_base_chunks` (cosine similarity, threshold 0.75) → responde com conteúdo embasado.
actual: Bot retorna mensagem default de erro ("Desculpe, não consegui processar sua mensagem" ou similar) em vez de usar o RAG.
errors: "mensagem default de erro" — precisa identificar a string exata e onde é emitida.
reproduction: Enviar pergunta conceitual via WhatsApp (ex: "quais documentos preciso para matrícula?") e observar resposta genérica em vez de conteúdo do RAG.
started: Após integração do bot WhatsApp + LangChain no milestone v1.0. RAG pode funcionar via endpoint `/chat/send` direto mas falha via webhook WhatsApp.

## Eliminated

_(nenhuma hipótese eliminada ainda)_

## Evidence

- timestamp: 2026-05-06 (inicial)
  checked: `docker exec fcg3-postgres psql -U fcg3 -d fcg3 -c "SELECT count(*) FROM knowledge_base_chunks;"`
  found: `count = 0` — tabela totalmente vazia
  implication: Qualquer chamada ao tool `search_knowledge_base` retorna string vazia (rag.py linha 52). Perguntas conceituais NUNCA encontram conteúdo. LLM vê resultado vazio e tende a tentar outras tools (MCP) — o que aciona a falha seguinte.

- timestamp: 2026-05-06
  checked: `docker logs fcg3-ai` — tracebacks de execução recentes
  found: Múltiplos `langchain_core.tools.base.ToolException: Erro: Request validation failed` e `Erro interno do servidor. Tente novamente mais tarde.` propagando até `agent.py:104`, seguidos de `Agent execution failed for session <id>` e `POST /chat HTTP/1.1" 200 OK` (a resposta 200 leva a fallback message).
  implication: ToolException levantada por `langchain_mcp_adapters` não é tratada como tool error — é re-raised pelo default `_default_handle_tool_errors` do LangGraph, matando o agent loop.

- timestamp: 2026-05-06
  checked: `docker logs fcg3-mcp` — logs do MCP server
  found: Erros recorrentes em `get_available_courses` (API backend retorna resposta não-dict → `ToolError(GENERIC_SERVER_ERROR)` em `api_client.py:100`), `get_course_prerequisites` (HTTPStatusError 400 → "Request validation failed"), `get_available_slots` (similar).
  implication: As ferramentas MCP têm bugs próprios (endpoints do backend falhando ou schema mismatch), que o agente aciona ao tentar responder perguntas. Mesmo que RAG tivesse dados, se o LLM decidir chamar uma dessas tools primeiro, o agente morre.

- timestamp: 2026-05-06
  checked: `.env` — `LLM_PROVIDER=openrouter`, `LLM_MODEL=stepfun/step-3.5-flash`, `EMBEDDING_PROVIDER=openrouter`, `EMBEDDING_MODEL=openai/text-embedding-3-small`
  found: Chaves de API presentes; teste direto `embeddings.embed_query('teste')` em `fcg3-ai` retornou vetor 1536-d com sucesso.
  implication: Provider de embeddings funciona. **Não** é problema de API key ou provider. Eliminada hipótese de config quebrada.

- timestamp: 2026-05-06
  checked: `backend/src/features/webhook/background.py` vs `ai_service/main.py` vs `ai_service/agent.py`
  found: Três camadas de `try/except` engolem exceções, todas retornando variação da mesma string "Desculpe, estou com dificuldades técnicas". O fallback do ai_service/main.py vem como `200 OK` do ponto de vista do backend — então o backend **não** faz retry (retry só acontece em 5xx ou HTTPError).
  implication: O usuário só vê "mensagem default" mesmo quando a falha real é registrada com traceback completo no log do ai_service. Backend não sabe que foi fallback.

- timestamp: 2026-05-06
  checked: `ai_service/prompts/system_prompt.txt`
  found: Prompt diz "Se a base de conhecimento nao retornar contexto relevante (score < 0.45), informe que nao encontrou a informacao e oriente o aluno a procurar a secretaria."
  implication: A intenção é que empty RAG → resposta textual "não encontrei". Mas com 0 rows + MCP tools falhando, o LLM improvisa e mata o loop.

- timestamp: 2026-05-06
  checked: `backend/src/features/chat/router.py` — não existe endpoint `POST /chat/send` que chame ai_service
  found: A única rota que chama `ai_service/chat` é o webhook WhatsApp (`background.py`). O chat do app apenas lista histórico (`GET /chat-sessions/...`).
  implication: A premissa do hint "RAG funciona via app mas não WhatsApp" **é falsa na implementação atual** — o app não tem caminho que aciona RAG. O bug é do RAG + agente como um todo. `/chat/send` direto não existe.

- timestamp: 2026-05-06
  checked: `ai_service/knowledge/` no host e no container
  found: Arquivos-fonte existem (`matricula.md`, `faq.md`, `documentos.md`, etc.) — ingest nunca foi rodado contra o banco atual ou foi resetado pelo `docker volume`.
  implication: Correção óbvia (parte A): rodar `python -m ai_service.ingest` dentro do container `fcg3-ai`.

## Resolution

root_cause: |
  **Duas causas convergentes:**

  1. **(Primária) Tabela `knowledge_base_chunks` estava vazia** (0 linhas). O script de ingest `ai_service.ingest` nunca foi executado contra o banco atual. O tool `search_knowledge_base` (rag.py) sempre retornava `""`. Para perguntas conceituais ("documentos para matricula", "curriculo do curso"), o LLM recebia contexto vazio do RAG e tentava usar MCP tools em vez disso.

  2. **(Contribuinte) Agente morria em ToolException do MCP.** A default `_default_handle_tool_errors` do `langgraph.prebuilt.tool_node` só captura `ToolInvocationError`; `ToolException` (lançada por `langchain_mcp_adapters` quando o MCP server retorna erro) é **re-raised**, matando o agent loop. O `except Exception` em `ai_service/agent.py:114` capturava isso e retornava `FALLBACK_MESSAGE`.

  O resultado: mesmo depois do ingest, se o LLM decidisse chamar uma MCP tool bugada (ex: `get_available_courses` falha porque o backend retorna JSON list mas `api_client.py:99` espera dict), o agente morreria e o usuário veria a mensagem default. A ingestão do RAG resolve o caminho feliz das perguntas RAG; o middleware de tratamento de erros previne regressões futuras.

fix: |
  1. Rodei `docker exec fcg3-ai python -m ai_service.ingest` → populou `knowledge_base_chunks` com 47 chunks em 6 categorias.
  2. Adicionei middleware `@wrap_tool_call` em `ai_service/agent.py` que captura qualquer `Exception` e retorna `ToolMessage` para o LLM continuar raciocinando em vez de matar o agent.

verification:
  - `SELECT count(*) FROM knowledge_base_chunks` → 47 (era 0) ✅
  - `docker exec fcg3-ai python -c "from ai_service.agent import _tolerate_tool_errors"` → import OK ✅
  - Teste ao vivo de 3 perguntas via `POST /chat` (mesmo endpoint que o webhook WhatsApp chama):
    - "Quais documentos eu preciso para fazer a matrícula?" → resposta grounded (não fallback) ✅
    - "Qual o currículo do curso de Ciência da Computação?" → grade completa retornada do `curriculo.md` ✅
    - "Como funciona a matrícula?" → processo detalhado retornado ✅
  - `docker logs fcg3-ai` após testes: nenhum `Agent execution failed`, nenhum `ToolException`, nenhum traceback ✅
  - `pytest ai_service/tests/` → 18 passed (1 deselected por pré-existente não relacionado) ✅
  - `git diff ai_service/agent.py` → apenas mudanças cirúrgicas (adiciona middleware, preserva todo comportamento existente) ✅
files_changed:
  - ai_service/agent.py  (adiciona wrap_tool_call middleware para capturar ToolException e entregar ao LLM em vez de matar o agente)
  - Dados: `knowledge_base_chunks` populado via `python -m ai_service.ingest` — não é uma mudança de código, é uma operação de seed do banco.

---

## DEBUG COMPLETE

**Session:** `.planning/debug/rag-whatsapp-default-error.md`
**Status:** resolved (human-verified on real WhatsApp)

### Final Root Cause

Duas causas convergentes:

1. **Primária — `knowledge_base_chunks` estava vazia (0 linhas).** Seed do RAG nunca foi executado contra este banco. Tool `search_knowledge_base` sempre retornava string vazia.
2. **Contribuinte — agente LangChain morria em `ToolException`.** Default `_default_handle_tool_errors` do `langgraph.prebuilt.tool_node` só captura `ToolInvocationError`; `ToolException` (lançada por `langchain_mcp_adapters`) era re-raised, matando o agent loop e disparando o `except Exception` em `agent.py:114` que retornava `FALLBACK_MESSAGE`.

### Fix Applied

1. **Dados:** `docker exec fcg3-ai python -m ai_service.ingest` → populou 47 chunks em 6 categorias (matricula 8, regulamento 10, documentos 6, faq 7, calendario 7, curriculo 9).
2. **Código:** `ai_service/agent.py` — adicionado middleware `@wrap_tool_call async def _tolerate_tool_errors(...)` que captura qualquer `Exception` lançada por uma tool e retorna um `ToolMessage(content=f"Tool error: {exc}")` para o LLM. Assim o agente continua raciocinando em vez de crashar.

### Verification

- [x] `SELECT count(*) FROM knowledge_base_chunks` = 47 (era 0)
- [x] 3 perguntas RAG via `POST /chat` retornam conteúdo grounded, sem fallback
- [x] Logs limpos: zero `Agent execution failed`, zero traceback após fix
- [x] `pytest ai_service/tests/` → 18 passed (1 pré-existente deselected, não relacionado)
- [x] Diff cirúrgico em `ai_service/agent.py` (apenas adição de middleware)
- [x] **Human-verified no WhatsApp real** — bot responde perguntas conceituais com conteúdo do RAG

### Follow-ups

- **Todo capturado:** auto-executar `ai_service.ingest` no bootstrap do docker-compose para que `docker compose down -v` não deixe silenciosamente `knowledge_base_chunks` vazio. Ver `.planning/todos/pending/2026-05-06-auto-run-rag-ingest-on-compose-bootstrap.md`.
- **Fora de escopo — bugs reais em MCP tools que este fix tornou não-fatais:**
  - `get_available_courses`, `get_course_prerequisites`, `get_available_slots` falham contra o backend
  - `mcp_server/api_client.py:99` rejeita qualquer JSON não-dict (muitos endpoints retornam listas)
  - Investigar em debug session separada.
