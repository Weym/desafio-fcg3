#!/usr/bin/env bash
# scripts/uat/test_phase_05_gap_closure.sh
#
# HUMAN-UAT runner para os dois pontos abertos da Phase 05:
#   1. RAG com threshold 0.45 retorna resposta fundamentada (Test 3 do UAT)
#   2. MCP action_logs INSERT popula id via gen_random_uuid()
#
# Pré-requisitos:
#   - `docker compose up -d --build` concluído; containers healthy
#   - Seed carregado (Ana Silva como aluna de teste)
#   - OPENAI_API_KEY ou equivalente configurada em .env
#   - Ingest da knowledge base já executado (17 chunks esperados)
#
# Uso:
#   bash scripts/uat/test_phase_05_gap_closure.sh
#   bash scripts/uat/test_phase_05_gap_closure.sh --only rag
#   bash scripts/uat/test_phase_05_gap_closure.sh --only mcp
#
# O script NÃO modifica banco nem código — apenas lê e faz POSTs de leitura.
# A única escrita é a criação (idempotente) de uma chat_session de teste.

set -euo pipefail

# ---------- config ----------
STUDENT_EMAIL="${STUDENT_EMAIL:-ana.silva@usp.br}"
STUDENT_PHONE="${STUDENT_PHONE:-5511987654321}"
COMPOSE_PROJECT="${COMPOSE_PROJECT:-$(basename "$(pwd)")}"
RAG_QUESTION="${RAG_QUESTION:-Quais sao os criterios para trancar matricula?}"
MCP_QUESTION="${MCP_QUESTION:-Quais sao minhas matriculas ativas?}"

ONLY=""
if [[ "${1:-}" == "--only" && -n "${2:-}" ]]; then
  ONLY="$2"
fi

# ---------- helpers ----------
color() { printf '\033[%sm%s\033[0m' "$1" "$2"; }
info()  { echo "$(color '1;36' "[INFO]") $*"; }
ok()    { echo "$(color '1;32' "[ OK ]") $*"; }
fail()  { echo "$(color '1;31' "[FAIL]") $*"; }
hr()    { printf '%.0s-' {1..70}; echo; }

require_healthy() {
  local svc="$1"
  if ! docker compose ps --format '{{.Name}} {{.State}}' | grep -q "^${svc} running"; then
    fail "Container ${svc} nao esta rodando. Rode: docker compose up -d"
    exit 1
  fi
}

# ---------- env loader ----------
load_env() {
  if [ ! -f .env ]; then
    fail ".env nao encontrado na raiz do projeto"
    exit 1
  fi
  # shellcheck disable=SC2046
  export $(grep -E '^(MCP_SERVICE_TOKEN|POSTGRES_USER|POSTGRES_DB|POSTGRES_PASSWORD|RAG_SIMILARITY_THRESHOLD|LLM_PROVIDER)=' .env | xargs)
  if [ -z "${MCP_SERVICE_TOKEN:-}" ]; then
    fail "MCP_SERVICE_TOKEN ausente em .env"
    exit 1
  fi
}

# ---------- setup chat_session ----------
ensure_chat_session() {
  info "Criando/recuperando chat_session de teste para ${STUDENT_EMAIL}..."
  local sql
  sql=$(cat <<SQL
WITH target AS (
  SELECT id AS student_id FROM students WHERE email = '${STUDENT_EMAIL}' LIMIT 1
), existing AS (
  SELECT cs.id
  FROM chat_sessions cs
  JOIN target t ON cs.student_id = t.student_id
  WHERE cs.whatsapp_phone = '${STUDENT_PHONE}' AND cs.status = 'active'
  ORDER BY cs.started_at DESC
  LIMIT 1
), created AS (
  INSERT INTO chat_sessions (id, student_id, whatsapp_phone, status)
  SELECT gen_random_uuid(), (SELECT student_id FROM target), '${STUDENT_PHONE}', 'active'
  WHERE NOT EXISTS (SELECT 1 FROM existing)
    AND EXISTS (SELECT 1 FROM target)
  RETURNING id
)
SELECT id FROM existing
UNION ALL
SELECT id FROM created;
SQL
)
  TEST_SESSION_ID=$(
    docker compose exec -T postgres \
      psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -At -c "$sql"
  )
  if [ -z "$TEST_SESSION_ID" ]; then
    fail "Nao foi possivel obter/criar chat_session. Aluno ${STUDENT_EMAIL} existe? (rode o seed)"
    exit 1
  fi
  ok "chat_session: ${TEST_SESSION_ID}"
  export TEST_SESSION_ID
}

# ---------- Test 1: RAG policy answer ----------
test_rag_policy() {
  hr
  info "TEST 1 — RAG academic policy (threshold ${RAG_SIMILARITY_THRESHOLD:-0.45})"
  info "Pergunta: ${RAG_QUESTION}"
  echo

  local response
  response=$(
    docker compose exec -T langchain-service \
      curl -sS -X POST "http://localhost:8001/chat" \
        -H "Content-Type: application/json" \
        -H "X-Service-Token: ${MCP_SERVICE_TOKEN}" \
        -d "$(jq -nc --arg sid "$TEST_SESSION_ID" --arg msg "$RAG_QUESTION" \
              '{session_id:$sid, message:$msg}')" \
        --max-time 60
  )
  echo "Resposta bruta:"
  echo "$response" | jq . 2>/dev/null || echo "$response"
  echo

  local text
  text=$(echo "$response" | jq -r '.response // empty')
  if [ -z "$text" ]; then
    fail "Resposta vazia ou invalida"
    return 1
  fi

  # heuristica: fallback conhecido comeca com "Desculpe, estou com dificuldades"
  if echo "$text" | grep -qiE "desculpe.*dificuldades tecnicas"; then
    fail "Recebeu fallback generico (erro interno). Ver logs: docker compose logs langchain-service --tail=40"
    return 1
  fi

  # heuristica: respostas 'nao encontrei' costumam ter essas marcas
  if echo "$text" | grep -qiE "nao (encontrei|tenho|possuo|foram encontradas)|sem informacao|informacao nao esta|nao (consegui|localizei)"; then
    fail "Agente respondeu que nao encontrou informacao — RAG pode estar vazio ou threshold ainda alto"
    info "Ver chunks candidatos manualmente rodando o query do bloco TEST 1B abaixo"
    return 1
  fi

  ok "Resposta em portugues, nao-fallback, nao-'nao encontrei'"
  ok "Tamanho: $(echo -n "$text" | wc -c) chars"
}

# ---------- Test 1B: sanity check direto no banco ----------
test_rag_direct_similarity() {
  hr
  info "TEST 1B — Sanity check: similaridade dos chunks para a pergunta"
  info "(confirma que ha chunks >= ${RAG_SIMILARITY_THRESHOLD:-0.45} no banco)"

  # Gera o embedding via python dentro do container
  docker compose exec -T langchain-service python -c "
import json, os, sys
from ai_service.config import settings
from ai_service.embedding_factory import create_embeddings
import psycopg
emb = create_embeddings(settings)
vec = emb.embed_query('${RAG_QUESTION}')
vec_str = '[' + ','.join(f'{x:.6f}' for x in vec) + ']'
with psycopg.connect(settings.DATABASE_URL) as conn, conn.cursor() as cur:
    cur.execute('''
        SELECT source, category, 1 - (embedding <=> %s::vector) AS sim
        FROM knowledge_base_chunks
        ORDER BY embedding <=> %s::vector
        LIMIT 5
    ''', (vec_str, vec_str))
    rows = cur.fetchall()
    for src, cat, sim in rows:
        print(f'{sim:.4f}  [{cat}]  {src}')
" 2>&1 | tee /tmp/rag_similarities.txt

  local max_sim
  max_sim=$(awk '{print $1}' /tmp/rag_similarities.txt | sort -rn | head -1)
  echo
  if awk -v s="$max_sim" -v t="${RAG_SIMILARITY_THRESHOLD:-0.45}" 'BEGIN{exit !(s+0 >= t+0)}'; then
    ok "Top similarity ${max_sim} >= threshold ${RAG_SIMILARITY_THRESHOLD:-0.45} — chunks deveriam chegar ao agente"
  else
    fail "Top similarity ${max_sim} < threshold ${RAG_SIMILARITY_THRESHOLD:-0.45} — diminua RAG_SIMILARITY_THRESHOLD em .env e restart langchain-service"
  fi
}

# ---------- Test 2: MCP tool call populates mcp_action_logs ----------
test_mcp_action_log_uuid() {
  hr
  info "TEST 2 — MCP tool call popula mcp_action_logs com gen_random_uuid()"
  info "Pergunta (dispara tool): ${MCP_QUESTION}"
  echo

  # snapshot ANTES
  local count_before
  count_before=$(docker compose exec -T postgres psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -At -c \
    "SELECT COUNT(*) FROM mcp_action_logs WHERE chat_session_id = '${TEST_SESSION_ID}';")
  info "mcp_action_logs antes: ${count_before} rows para esta session"

  local response
  response=$(
    docker compose exec -T langchain-service \
      curl -sS -X POST "http://localhost:8001/chat" \
        -H "Content-Type: application/json" \
        -H "X-Service-Token: ${MCP_SERVICE_TOKEN}" \
        -d "$(jq -nc --arg sid "$TEST_SESSION_ID" --arg msg "$MCP_QUESTION" \
              '{session_id:$sid, message:$msg}')" \
        --max-time 90
  )
  echo "Resposta bruta:"
  echo "$response" | jq . 2>/dev/null || echo "$response"
  echo

  local text
  text=$(echo "$response" | jq -r '.response // empty')
  if echo "$text" | grep -qiE "desculpe.*dificuldades tecnicas"; then
    fail "Agente caiu em fallback durante a tool call. Ver: docker compose logs mcp-server --tail=80"
    return 1
  fi

  # snapshot DEPOIS
  info "Verificando insert em mcp_action_logs..."
  docker compose exec -T postgres psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -c "
    SELECT
      id::text AS id,
      (id IS NOT NULL) AS id_present,
      tool_name,
      status,
      latency_ms,
      retry,
      created_at
    FROM mcp_action_logs
    WHERE chat_session_id = '${TEST_SESSION_ID}'
    ORDER BY created_at DESC
    LIMIT 5;
  "

  local count_after
  count_after=$(docker compose exec -T postgres psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -At -c \
    "SELECT COUNT(*) FROM mcp_action_logs WHERE chat_session_id = '${TEST_SESSION_ID}';")
  local null_ids
  null_ids=$(docker compose exec -T postgres psql -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" -At -c \
    "SELECT COUNT(*) FROM mcp_action_logs WHERE chat_session_id = '${TEST_SESSION_ID}' AND id IS NULL;")

  echo
  info "mcp_action_logs depois: ${count_after} rows (${null_ids} com id NULL)"

  if [ "${count_after}" -le "${count_before}" ]; then
    fail "Nenhum INSERT novo em mcp_action_logs — agente nao disparou tool?"
    info "Ver logs: docker compose logs mcp-server langchain-service --tail=120"
    return 1
  fi

  if [ "${null_ids}" -gt 0 ]; then
    fail "${null_ids} rows com id NULL — gen_random_uuid() nao foi aplicado"
    return 1
  fi

  ok "Novos INSERTs em mcp_action_logs com id UUID populado. Zero NULL ids."
}

# ---------- run ----------
main() {
  load_env
  require_healthy "fcg3-postgres"
  require_healthy "fcg3-ai"
  require_healthy "fcg3-mcp"
  ensure_chat_session

  case "$ONLY" in
    rag) test_rag_policy ; test_rag_direct_similarity ;;
    mcp) test_mcp_action_log_uuid ;;
    "")  test_rag_policy ; test_rag_direct_similarity ; test_mcp_action_log_uuid ;;
    *)   fail "--only aceita: rag | mcp"; exit 2 ;;
  esac

  hr
  ok "UAT runner finalizado. Atualize .planning/phases/05-ai-service/05-HUMAN-UAT.md com 'result: pass/issue' em cada teste."
}

main "$@"
