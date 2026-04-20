# Phase 4: MCP Server - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-20
**Phase:** 04-mcp-server
**Areas discussed:** Framework & Transport, Session Context & student_id Injection, Tool Response Format, Reasoning Capture Flow, Tool Code Organization, Database Access, HTTP Client Configuration, Healthcheck

---

## Framework & Transport MCP

| Option | Description | Selected |
|--------|-------------|----------|
| FastMCP (Recomendado) | SDK oficial high-level para MCP em Python. API declarativa com decoradores. Suporta streamable-http nativamente. | ✓ |
| mcp SDK (low-level) | SDK base mostrado em docs/mcp.md. Mais controle manual, mais verbose. Transport: stdio/SSE. | |

**User's choice:** FastMCP (Recomendado)
**Notes:** None

| Option | Description | Selected |
|--------|-------------|----------|
| Streamable HTTP (Recomendado) | Transport padrao do MCP 2025. Stateless por request, funciona em container Docker. | ✓ |
| SSE (Server-Sent Events) | Transport legado do MCP. Persistente, unidirecional. | |
| stdio | Comunicacao local via stdin/stdout. Nao se encaixa na topologia Docker. | |

**User's choice:** Streamable HTTP (Recomendado)
**Notes:** None

| Option | Description | Selected |
|--------|-------------|----------|
| FastMCP standalone (Recomendado) | FastMCP roda seu proprio server HTTP na porta 8002. MCP server puro. | ✓ |
| FastMCP dentro de FastAPI | MCP server como mount/sub-app de um FastAPI. Mistura concerns. | |

**User's choice:** FastMCP standalone (Recomendado)
**Notes:** None

---

## Session Context & student_id Injection

| Option | Description | Selected |
|--------|-------------|----------|
| chat_session_id por request (Recomendado) | AI Service passa chat_session_id. MCP consulta banco para resolver student_id. Stateless. | |
| Header custom por request | AI Service envia header custom em cada request HTTP ao MCP. | ✓ |
| Voce decide | Agent decide o mecanismo. | |

**User's choice:** Header custom por request
**Notes:** Follow-up determined the header carries chat_session_id (not student_id directly).

| Option | Description | Selected |
|--------|-------------|----------|
| chat_session_id no header (Recomendado) | Header: X-Chat-Session-ID. MCP consulta chat_sessions para obter student_id. student_id nunca trafega entre servicos. | ✓ |
| student_id direto no header | Header: X-Student-ID. AI Service resolve e envia direto. student_id trafega entre servicos internos. | |

**User's choice:** chat_session_id no header (Recomendado)
**Notes:** Combined decision: X-Chat-Session-ID header per request, MCP resolves student_id from DB.

| Option | Description | Selected |
|--------|-------------|----------|
| Rejeitar tool call com erro (Recomendado) | Retorna erro claro ao agente. Fail-safe. | ✓ |
| Retornar resultado vazio | Tool retorna dados vazios. Pode gerar respostas confusas. | |

**User's choice:** Rejeitar tool call com erro (Recomendado)
**Notes:** None

---

## Tool Response Format

| Option | Description | Selected |
|--------|-------------|----------|
| JSON cru da API (Recomendado) | Repassa JSON da resposta FastAPI direto ao agente. Simples. | ✓ |
| JSON simplificado | MCP filtra/transforma JSON antes de repassar. | |
| Texto formatado em PT-BR | MCP converte JSON em texto legivel. | |

**User's choice:** JSON cru da API (Recomendado)
**Notes:** None

| Option | Description | Selected |
|--------|-------------|----------|
| Mensagem de erro em texto (Recomendado) | MCP converte o erro em mensagem legivel para o agente. | ✓ |
| JSON de erro cru da API | Repassa JSON de erro da API direto. | |
| Voce decide | Agent decide formato de erros. | |

**User's choice:** Mensagem de erro em texto (Recomendado)
**Notes:** None

---

## Reasoning Capture Flow

| Option | Description | Selected |
|--------|-------------|----------|
| MCP Server escreve (Recomendado) | MCP intercepta cada tool call via decorator, mede latencia, registra log. Reasoning via header do AI Service. | |
| AI Service escreve | AI Service captura reasoning e escreve log. MCP nao controla logging. | |
| Ambos colaboram | MCP escreve log basico, AI Service atualiza reasoning depois. | |

**User's choice:** Free text — "Seria viavel que o primeiro funcione com que cada chamada seja interceptada por um decorator que salva os metadados da chamada dentro do mcp_action_logs?"
**Notes:** User confirmed decorator/middleware approach for MCP logging. Aligns with `execute_tool_with_middleware` pattern from docs/mcp.md.

| Option | Description | Selected |
|--------|-------------|----------|
| Header X-Agent-Reasoning (Recomendado) | AI Service envia reasoning via header HTTP. MCP le e salva no log. | |
| Reasoning como nullable, preenchido depois | MCP salva sem reasoning, AI Service atualiza depois. | |
| Voce decide | Agent decide melhor forma. | ✓ |

**User's choice:** Voce decide
**Notes:** Reasoning capture mechanism left to agent's discretion during research/planning.

---

## Tool Code Organization

| Option | Description | Selected |
|--------|-------------|----------|
| Agrupados por dominio (Recomendado) | Modulos separados por dominio. Facil de navegar e manter. | ✓ |
| Arquivo unico | Todos 16 tools em tools.py. Simples mas arquivo grande. | |
| Voce decide | Agent decide baseado no tamanho final. | |

**User's choice:** Agrupados por dominio (Recomendado)
**Notes:** None

---

## Database Access

| Option | Description | Selected |
|--------|-------------|----------|
| asyncpg direto (Recomendado) | Queries SQL manuais com asyncpg. MCP so precisa 2 queries. Leve e rapido. | ✓ |
| SQLAlchemy async | Reutiliza setup do backend. Mais consistente mas mais dependencias. | |
| Voce decide | Agent decide baseado na complexidade. | |

**User's choice:** asyncpg direto (Recomendado)
**Notes:** None

---

## HTTP Client Configuration

| Option | Description | Selected |
|--------|-------------|----------|
| 10 segundos (Recomendado) | Timeout total de 10s. Com retry, maximo 20s. | ✓ |
| 5 segundos | Mais agressivo. Pode ser curto para queries pesadas. | |
| Voce decide | Agent calibra. | |

**User's choice:** 10 segundos (Recomendado)
**Notes:** None

| Option | Description | Selected |
|--------|-------------|----------|
| Environment variables (Recomendado) | FASTAPI_BASE_URL como env var. httpx.AsyncClient inicializado uma vez no startup. | ✓ |
| Hardcoded com override | Base URL hardcoded com fallback. Menos flexivel. | |

**User's choice:** Environment variables (Recomendado)
**Notes:** None

---

## Healthcheck

| Option | Description | Selected |
|--------|-------------|----------|
| DB + API reachability (Recomendado) | Valida PostgreSQL + FastAPI /health. Detecta problemas reais. | ✓ |
| Apenas 200 OK | Retorna 200 se processo esta rodando. Nao detecta DB/API down. | |
| Voce decide | Agent decide nivel de profundidade. | |

**User's choice:** DB + API reachability (Recomendado)
**Notes:** None

---

## Agent's Discretion

- Reasoning field capture mechanism (header-based vs post-hoc update vs nullable)
- Exact FastMCP middleware/decorator pattern for tool call interception
- asyncpg connection pool sizing
- Exact error message translations for each API error code
- Healthcheck endpoint implementation (separate HTTP server vs FastMCP built-in)

## Deferred Ideas

None — discussion stayed within phase scope.
