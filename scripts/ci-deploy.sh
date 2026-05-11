#!/bin/bash
# =============================================================================
# ci-deploy.sh — Non-interactive deploy script for CI/CD
#
# Called by GitHub Actions self-hosted runner.
# Does NOT replace scripts/deploy.sh — that script remains for manual server
# management (seed, reingest, logs, etc.).
#
# Usage:
#   bash scripts/ci-deploy.sh [--skip-flutter]
#
# Expects:
#   - .env file present at PROJECT_DIR/.env
#   - Virtualenvs already created (by initial scripts/deploy.sh run)
#   - Optionally: flutter-web-build/ directory with built Flutter Web files
# =============================================================================

set -euo pipefail

# --- Cores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[ERRO]${NC} $1"; exit 1; }
info() { echo -e "${CYAN}[i]${NC} $1"; }

# --- Parse args ---
SKIP_FLUTTER=false
for arg in "$@"; do
  case $arg in
    --skip-flutter) SKIP_FLUTTER=true ;;
  esac
done

# --- Paths ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
ENV_FILE="$PROJECT_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  err ".env file not found at $ENV_FILE"
fi

# Load environment
set -a
source "$ENV_FILE"
set +a

DEPLOY_USER="${USER}"
WEB_DIR="/home/$DEPLOY_USER/desafio-fcg3/frontend"

# =============================================================================
# Step 1: Update dependencies (only if requirements changed)
# =============================================================================
update_deps() {
  info "Checking if dependencies need updating..."

  local changed=false
  if git diff HEAD~1 --name-only 2>/dev/null | grep -q "requirements.txt"; then
    changed=true
  fi

  if [[ "$changed" == true ]]; then
    warn "requirements.txt changed -- updating dependencies..."
    for svc in backend ai_service mcp_server; do
      local venv_path="$PROJECT_DIR/$svc/.venv"
      local req_file="$PROJECT_DIR/$svc/requirements.txt"
      if [[ -d "$venv_path" ]] && [[ -f "$req_file" ]]; then
        "$venv_path/bin/pip" install -r "$req_file" -q
        log "Updated deps: $svc"
      else
        warn "Skipping $svc -- venv or requirements.txt not found"
      fi
    done
  else
    log "Dependencies: no changes detected"
  fi
}

# =============================================================================
# Step 2: Run database migrations
# =============================================================================
run_migrations() {
  info "Running Alembic migrations..."
  cd "$PROJECT_DIR/backend"

  set -a
  source "$ENV_FILE"
  set +a

  "$PROJECT_DIR/backend/.venv/bin/alembic" upgrade head
  log "Migrations applied."
  cd "$PROJECT_DIR"
}

# =============================================================================
# Step 3: Restart services (ordered)
# =============================================================================
restart_services() {
  info "Restarting services..."
  sudo /usr/bin/systemctl restart fcg3-api
  sleep 2
  sudo /usr/bin/systemctl restart fcg3-mcp
  sleep 2
  sudo /usr/bin/systemctl restart fcg3-ai
  sleep 3
  log "Services restarted."
}

# =============================================================================
# Step 4: Deploy Flutter Web (if artifact present)
# =============================================================================
deploy_flutter() {
  if [[ "$SKIP_FLUTTER" == true ]]; then
    log "Flutter: skipped (--skip-flutter flag)"
    return
  fi

  local FLUTTER_ARTIFACT="$PROJECT_DIR/flutter-web-build"

  if [[ -d "$FLUTTER_ARTIFACT" ]]; then
    info "Deploying Flutter Web from artifact..."
    rm -rf "$WEB_DIR"
    mkdir -p "$WEB_DIR"
    cp -r "$FLUTTER_ARTIFACT"/* "$WEB_DIR"/
    log "Flutter Web deployed to $WEB_DIR"
  else
    log "Flutter: no build artifact found at $FLUTTER_ARTIFACT -- skipping"
  fi
}

# =============================================================================
# Step 5: Re-ingest knowledge base (only if knowledge files changed)
# =============================================================================
reingest_knowledge() {
  info "Checking if knowledge base needs re-ingestion..."

  local changed=false
  if git diff HEAD~1 --name-only 2>/dev/null | grep -q "^ai_service/knowledge/"; then
    changed=true
  fi

  if [[ "$changed" == true ]]; then
    warn "Knowledge base files changed -- re-ingesting embeddings..."
    cd "$PROJECT_DIR"

    set -a
    source "$ENV_FILE"
    set +a

    "$PROJECT_DIR/ai_service/.venv/bin/python" -m ai_service.ingest
    log "Knowledge base re-ingested."
    cd "$PROJECT_DIR"
  else
    log "Knowledge base: no changes detected"
  fi
}

# =============================================================================
# Step 6: Health checks
# =============================================================================
check_health() {
  info "Running health checks..."
  local all_healthy=true

  for port_svc in "8000:fcg3-api" "8001:fcg3-ai" "8002:fcg3-mcp"; do
    local port="${port_svc%%:*}"
    local svc="${port_svc##*:}"

    local retries=5
    local healthy=false
    while [[ $retries -gt 0 ]]; do
      if curl -sf "http://127.0.0.1:$port/health" >/dev/null 2>&1; then
        echo -e "  ${GREEN}OK${NC} $svc (:$port)"
        healthy=true
        break
      fi
      retries=$((retries - 1))
      sleep 2
    done

    if [[ "$healthy" == false ]]; then
      echo -e "  ${RED}FAIL${NC} $svc (:$port) -- not responding after retries"
      all_healthy=false
    fi
  done

  if [[ "$all_healthy" == false ]]; then
    err "One or more services failed health check"
  fi

  log "All services healthy."
}

# =============================================================================
# Main
# =============================================================================
main() {
  echo ""
  echo "========================================"
  echo "  FCG3 -- CI/CD Deploy"
  echo "========================================"
  echo ""

  update_deps
  run_migrations
  restart_services
  deploy_flutter
  reingest_knowledge
  check_health

  echo ""
  log "Deploy complete."
}

main "$@"
