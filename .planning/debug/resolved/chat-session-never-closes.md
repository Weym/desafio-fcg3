---
status: resolved
trigger: "chat-session-never-closes: Registros na tabela chat_sessions nunca transitam de status='active' para status='closed'"
created: 2026-05-06T00:00:00Z
updated: 2026-05-06T07:00:00Z
---

## Current Focus

hypothesis: CONFIRMED AND FIXED — pg_cron job had doubled single quotes (`''closed''`) in its stored command due to mixing `$$…$$` dollar-quoting with `''` SQL-escape in migration 011. Produced syntax error every hour. Fix: corrective migration 012 reschedules with correct single quotes, source migration 011 edited to match, regression test added.
test: (a) queried `cron.job` after migration 012 → command now uses single quotes; (b) executed the exact stored command after back-dating one session by 25h → transitioned active→closed correctly; (c) unit regression test asserts both 011 upgrade() and 012 upgrade() contain single-quoted not doubled-quoted tokens, and that 012 unschedules before rescheduling.
expecting: Fix to be verified in real production conditions — i.e., user should wait up to 1 hour (next cron tick) or trigger a session to be auto-closed to confirm end-to-end.
next_action: Awaiting human verification that the cron actually fires with the fixed command (next scheduled tick on the hour) and that no existing functional tests regressed.

## Symptoms

expected: Quando uma conversa chega ao fim (inatividade, ação explícita do usuário, ou conclusão de fluxo), a chat_session deve mudar para status='closed' com timestamp closed_at preenchido, conforme convenção 'active -> closed' documentada em CONVENTIONS.md.
actual: A chat_session fica com status='active' indefinidamente. Nenhum trigger está fechando a sessão porque "a conversa nunca termina" — não há lógica que dispare o encerramento.
errors: Sem erros — é uma funcionalidade ausente ou lógica incompleta.
reproduction: Iniciar qualquer conversa com o bot via WhatsApp ou via app, deixar passar qualquer tempo, verificar no banco: `SELECT id, status, created_at, closed_at FROM chat_sessions` → todas as linhas permanecem 'active'.
started: Identificado após integração completa do chatbot (milestone v1.0).

## Eliminated

- hypothesis: Feature nunca foi implementada (sem schema, sem código)
  evidence: Migration 011 existe, coluna `updated_at` existe no schema, método `close_session` existe no webhook service, keywords "sair"/"encerrar" são tratadas no router
  timestamp: 2026-05-06T00:03:00Z

- hypothesis: pg_cron extension não está instalada (migration "skipped gracefully")
  evidence: `SELECT FROM pg_extension` mostra pg_cron 1.6 instalado. Dockerfile instala postgresql-16-cron. docker-compose configura shared_preload_libraries=pg_cron. Job foi de fato criado em `cron.job`.
  timestamp: 2026-05-06T00:04:00Z

- hypothesis: Premissa inicial da issue "nenhum trigger existe" e "a conversa nunca termina" — estratégia de timeout por inatividade nunca foi implementada
  evidence: Estratégia ESTÁ implementada (pg_cron + coluna updated_at tocada em get_or_create_session e save_message). O problema é um bug de escape de aspas no comando SQL do cron.
  timestamp: 2026-05-06T00:05:00Z

- hypothesis: `updated_at` nunca é atualizado, fazendo sessões antigas serem fechadas incorretamente (raciocínio invertido da minha primeira leitura)
  evidence: Isto seria o problema OPOSTO ao reportado (sessões fechariam cedo demais). Mas dados reais mostram o contrário: chat_sessions com `updated_at` há mais de 24h ainda estão `active` porque o UPDATE falha por erro de sintaxe.
  timestamp: 2026-05-06T00:05:00Z

## Evidence

- timestamp: 2026-05-06T00:01:00Z
  checked: Estrutura do backend: `backend/src/features/chat/`, `backend/src/features/webhook/`
  found: `ChatSession` model tem colunas `status`, `started_at`, `ended_at` (não `closed_at` como sugerido nos hints), `updated_at`. CheckConstraint valida `status IN ('active','closed')`.
  implication: Schema suporta estados active/closed. Nome da coluna de encerramento é `ended_at`, não `closed_at`.

- timestamp: 2026-05-06T00:01:30Z
  checked: `backend/src/features/webhook/service.py`
  found: Método `close_session` (L179-185) atualiza `status='closed'` e `ended_at=now()`. Constante `SESSION_CLOSE_KEYWORDS = {"sair","encerrar"}` (L38). `get_or_create_session` (L127) e `save_message` (L170-173) tocam `updated_at` a cada interação, indicando estratégia de "inactivity tracking".
  implication: Existe caminho síncrono de encerramento (via keyword "sair"/"encerrar") e infraestrutura para caminho assíncrono por inatividade.

- timestamp: 2026-05-06T00:02:00Z
  checked: `backend/src/features/webhook/router.py` L147-157
  found: Router detecta "sair"/"encerrar" antes da verificação e chama `close_session`. Esse caminho funciona.
  implication: O problema NÃO é o caminho síncrono. Usuários só enviarão "sair"/"encerrar" em casos raros; a expectativa do relato é sobre sessões que ficam active indefinidamente mesmo quando o usuário simplesmente para de responder → isso depende do caminho assíncrono por inatividade.

- timestamp: 2026-05-06T00:02:30Z
  checked: `backend/alembic/versions/011_add_pg_cron_session_autoclose.py`
  found: Migration adiciona coluna `updated_at` e tenta agendar job pg_cron `close-inactive-chat-sessions` com schedule `0 * * * *` (hourly). Usa `SAVEPOINT` para tolerar ausência do pg_cron. O comando agendado é construído via `sa.text(...)` com dollar-quoting `$$...$$` e aspas internas escapadas como `''...''`.
  implication: Se pg_cron estiver instalado, job é agendado. Mas a combinação de dollar-quoting COM escape duplo pode estar errada.

- timestamp: 2026-05-06T00:03:00Z
  checked: `docker-compose.yml` e `backend/docker/postgres/Dockerfile`
  found: Dockerfile instala `postgresql-16-cron` (apt). docker-compose configura `-c shared_preload_libraries=pg_cron -c cron.database_name=${POSTGRES_DB}`. Container postgres está rodando e saudável.
  implication: pg_cron está instalado e configurado corretamente. A hipótese "pg_cron graceful skip" é falsa.

- timestamp: 2026-05-06T00:03:30Z
  checked: `SELECT extname FROM pg_extension` no banco
  found: pg_cron 1.6 + vector 0.8.2 instaladas.
  implication: Confirma que o CREATE EXTENSION foi bem-sucedido em produção.

- timestamp: 2026-05-06T00:04:00Z
  checked: `SELECT version_num FROM alembic_version`
  found: 011a — a migration de pg_cron foi aplicada.
  implication: Job deveria estar agendado.

- timestamp: 2026-05-06T00:04:30Z
  checked: `SELECT jobid, schedule, command, active, jobname FROM cron.job`
  found: Job `close-inactive-chat-sessions` existe, `active=t`, schedule `0 * * * *`. Command (armazenado): `UPDATE chat_sessions SET status = ''closed'', ended_at = NOW() WHERE updated_at < NOW() - INTERVAL ''24 hours'' AND status = ''active''`
  implication: **SMOKING GUN** — o comando armazenado tem aspas duplas-duplicadas (`''closed''`, `''24 hours''`, `''active''`) em vez de aspas simples. Isto é syntax error em PostgreSQL: `''` é string vazia; então a expressão vira `status = '' || closed || ''` o que dispara ERROR: syntax error at or near "closed".

- timestamp: 2026-05-06T00:04:45Z
  checked: `SELECT FROM cron.job_run_details ORDER BY start_time DESC LIMIT 10`
  found: TODAS as execuções (runids 3–12, cobrindo vários dias) com `status='failed'` e `return_message = 'ERROR: syntax error at or near "closed"'`. Primeira falha documentada: 2026-05-02 22:00 UTC. Última: 2026-05-06 05:00 UTC.
  implication: Job nunca executou com sucesso — nenhum UPDATE foi aplicado desde que a migration rodou. Isto é consistente com "todas as chat_sessions permanecem active".

- timestamp: 2026-05-06T00:05:00Z
  checked: `SELECT id, status, started_at, ended_at, updated_at FROM chat_sessions`
  found: 4 sessões, TODAS `status='active'`, `ended_at=NULL`. Mais antiga de 2026-05-06 02:55 (ainda <24h, então não seria alvo do job mesmo que funcionasse). Nenhuma com ended_at preenchido no período coberto pelos logs.
  implication: Estado atual é consistente com bug; não há sessão antiga o suficiente no snapshot para provar que o fix funcionará só observando dados, então vou testar manualmente.

- timestamp: 2026-05-06T00:05:15Z
  checked: Teste direto: `UPDATE chat_sessions SET status = ''closed''...` vs `SET status = 'closed'...`
  found: Versão com `''closed''` falha com `ERROR: syntax error at or near "closed"`. Versão com `'closed'` sucede (UPDATE 0 para id inexistente, mas sintaticamente válida).
  implication: Prova definitiva do bug. Fix: remover o escape duplo de aspas; dollar-quoting `$$...$$` já torna as aspas internas literais — elas devem ser aspas simples puras.

## Resolution

root_cause: Migration `011_add_pg_cron_session_autoclose.py` construiu o SQL agendado em pg_cron com quoting inválido: usou `$$...$$` (dollar-quoting — tudo entre `$$` é literal, incluindo aspas) E TAMBÉM escapou as aspas internas como `''` (escape clássico de string-literal). O resultado é que o comando armazenado em `cron.job.command` contém literalmente `status = ''closed''`, que o PostgreSQL interpreta como strings vazias concatenadas com um identificador `closed` — `ERROR: syntax error at or near "closed"` a cada hora desde 2026-05-02 22:00 UTC (visível em `cron.job_run_details`, 10+ falhas consecutivas). Como o job falhou em todas as execuções, `status` permaneceu `active` indefinidamente e `ended_at` nunca foi preenchido.
fix: (1) Criada migration `012_fix_pg_cron_session_autoclose_quoting.py` (revision 012a, down_revision 011a) que desagenda o job quebrado via SAVEPOINT e reagenda com aspas simples corretas; mesma tolerância a ausência de pg_cron usando o padrão SAVEPOINT da 011. (2) Migration 011 também corrigida no repositório para que ambientes frescos (CI, dev setup) não reintroduzam o bug; a constante `_SCHEDULE_SQL` em 012 fica idêntica ao que 011 agora produz, garantindo convergência. (3) Adicionados testes unitários (`tests/unit/test_pg_cron_session_autoclose_quoting.py`) que fazem parse AST das migrations, extraem os argumentos passados a `sa.text(...)` (inclusive resolvendo constantes de módulo), e asseguram (a) nenhum token `''closed''|''active''|''24 hours''` em upgrade(), (b) presença dos tokens single-quoted corretos, (c) 012 desagenda antes de reagendar.
verification:
  - Migration 012a aplicada em banco dev (fcg3-postgres): `alembic upgrade head` sucedeu, `alembic_version` avançou 011a → 012a.
  - `SELECT command FROM cron.job WHERE jobname='close-inactive-chat-sessions'` agora retorna `UPDATE chat_sessions SET status = 'closed', ended_at = NOW() WHERE updated_at < NOW() - INTERVAL '24 hours' AND status = 'active'` (single-quoted, correto).
  - Executei a string exata armazenada em `cron.job.command` contra o banco após back-date de uma chat_session por 25h: `UPDATE 1`, sessão transicionou de `active`/`ended_at=NULL` para `closed`/`ended_at=NOW()`. Demais sessões dentro da janela 24h permanecem `active` — comportamento correto.
  - 3 testes de regressão em `tests/unit/test_pg_cron_session_autoclose_quoting.py`: PASS.
  - 14 testes existentes de session lifecycle (`tests/features/webhook/test_session_lifecycle.py`): PASS — caminho síncrono via keywords ("sair"/"encerrar"/"cancelar"/etc.) segue funcionando.
  - Pendente: verificação end-to-end do cron firing no próximo tick da hora com comando corrigido (não bloqueante — o que é garantido é que a string armazenada agora é válida).
files_changed:
  - backend/alembic/versions/011_add_pg_cron_session_autoclose.py
  - backend/alembic/versions/012_fix_pg_cron_session_autoclose_quoting.py
  - backend/tests/unit/test_pg_cron_session_autoclose_quoting.py

## DEBUG COMPLETE

**Status:** resolved — 2026-05-06
**Verification outcome:** End-to-end confirmed in live database.

### Final State
- pg_cron `close-inactive-chat-sessions` job operational with correct single-quoted SQL.
- Alembic head: `012a`.
- Chat sessions older than 24h (inactivity measured by `updated_at`) now transition `active → closed` with `ended_at` set on the next hourly tick.
- Synchronous close path via keywords (`sair`/`encerrar`/`cancelar`/`cancel`/`parar`/`stop`) untouched and passing.

### Root Cause (summary)
Migration 011 passed the UPDATE body to `cron.schedule` wrapped in `$$...$$` dollar-quoting **and** also escaped the inner single quotes as `''`. Dollar-quoting already treats everything between the delimiters as a literal, so the `''` became literally doubled quotes in `cron.job.command` — producing `status = ''closed''` which Postgres parses as two empty strings surrounding a bare identifier. Result: `ERROR: syntax error at or near "closed"` on every hourly execution since 2026-05-02 22:00 UTC, and no chat_session ever auto-closed.

### Fix (summary)
1. `backend/alembic/versions/011_add_pg_cron_session_autoclose.py` — corrected the dollar-quoted SQL to use literal single quotes; added inline comment documenting the pitfall so fresh environments don't reintroduce the bug.
2. `backend/alembic/versions/012_fix_pg_cron_session_autoclose_quoting.py` (new, revision `012a`, down_revision `011a`) — heals already-migrated databases: unschedules the broken job via SAVEPOINT, then reschedules the fixed command using the shared `_SCHEDULE_SQL` constant. Same graceful-skip pattern as 011 when pg_cron is absent.
3. `backend/tests/unit/test_pg_cron_session_autoclose_quoting.py` (new) — AST-based regression tests that parse migrations 011 and 012, extract `sa.text(...)` arguments (resolving module-level string constants), and assert: (a) no `''closed''`/`''active''`/`''24 hours''` in either `upgrade()`, (b) the correct single-quoted tokens are present, (c) 012 unschedules before rescheduling.

### Verification Evidence
- `cron.job` post-fix: `UPDATE chat_sessions SET status = 'closed', ended_at = NOW() WHERE updated_at < NOW() - INTERVAL '24 hours' AND status = 'active'` (single-quoted, correct).
- Manually back-dated one chat_session by 25h and executed the exact stored cron command → `UPDATE 1`, session transitioned `active → closed` with `ended_at` filled; other <24h sessions stayed `active` (correct).
- **Live cron tick confirmed by user:** runid=13 at `2026-05-06 06:00:00 UTC` — `status=succeeded`, `return_message=UPDATE 0`, no syntax error. Historical runids 3–12 remain `failed` in the append-only `cron.job_run_details` table (expected artifact of the pre-fix job, not a regression).
- Regression tests: 3/3 PASS.
- Existing session lifecycle tests: 14/14 PASS.

### Lesson (for knowledge base)
When building SQL strings that are themselves stored as literals (pg_cron `cron.job.command`, event trigger bodies, stored-procedure bodies passed as text, etc.): pick exactly **one** quoting mechanism. Mixing `$$...$$` dollar-quoting with `''` SQL-escape produces a string that looks valid in the migration source but is stored with literally doubled quotes — the syntax error manifests only at the scheduled runtime, silently corrupting scheduled behavior for days before anyone notices. Always inspect the stored form (`SELECT command FROM cron.job`) after scheduling, not just the source.
