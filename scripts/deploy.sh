#!/bin/bash
# =============================================================================
# deploy.sh — Script unificado de deploy (setup + update)
#
# Uso:
#   sudo bash deploy.sh
#
# Na primeira execucao: instala tudo (PostgreSQL, Python, venvs, systemd, Nginx)
# Nas seguintes: verifica infraestrutura e apresenta menu de acoes
# =============================================================================

set -euo pipefail

# --- Cores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[ERRO]${NC} $1"; exit 1; }
info() { echo -e "${CYAN}[i]${NC} $1"; }

# =============================================================================
# Validacoes iniciais
# =============================================================================

if [[ $EUID -ne 0 ]]; then
  err "Execute como root: sudo bash deploy.sh"
fi

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$PROJECT_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  err "Arquivo .env nao encontrado.
  Copie .env.example para .env e preencha com valores reais:
    cp .env.example .env && nano .env"
fi

# Carregar variaveis
set -a
source "$ENV_FILE"
set +a

# Validar criticas
for var in POSTGRES_DB POSTGRES_USER POSTGRES_PASSWORD JWT_SECRET MCP_SERVICE_TOKEN; do
  [[ -z "${!var:-}" ]] && err "$var nao definida no .env"
done

DEPLOY_USER="${SUDO_USER:-$USER}"
[[ "$DEPLOY_USER" == "root" ]] && err "Execute com sudo a partir de um usuario normal, nao como root direto"

# =============================================================================
# Funcoes de infraestrutura (idempotentes — seguras para rodar varias vezes)
# =============================================================================

install_system_packages() {
  local packages_needed=()

  command -v psql    &>/dev/null || packages_needed+=(postgresql-16 postgresql-contrib-16)
  command -v nginx   &>/dev/null || packages_needed+=(nginx)
  command -v certbot &>/dev/null || packages_needed+=(certbot python3-certbot-nginx)
  command -v git     &>/dev/null || packages_needed+=(git)
  [[ -f /usr/bin/python3 ]]     || packages_needed+=(python3 python3-pip python3-venv python3.12-venv)

  dpkg -l | grep -q python3.12-venv 2>/dev/null || packages_needed+=(python3.12-venv)
  dpkg -l | grep -q libpq-dev       2>/dev/null || packages_needed+=(libpq-dev)
  dpkg -l | grep -q build-essential  2>/dev/null || packages_needed+=(build-essential curl wget)

  if [[ ${#packages_needed[@]} -gt 0 ]]; then
    log "Instalando pacotes: ${packages_needed[*]}"
    apt-get update -qq
    apt-get install -y -qq "${packages_needed[@]}"
  else
    log "Pacotes do sistema: todos presentes"
  fi
}

install_pgvector() {
  if ! dpkg -l | grep -q postgresql-16-pgvector 2>/dev/null; then
    log "Instalando pgvector..."
    apt-get install -y -qq postgresql-16-pgvector
  else
    log "pgvector: instalado"
  fi
}

install_pg_cron() {
  if ! dpkg -l | grep -q postgresql-16-cron 2>/dev/null; then
    log "Instalando pg_cron..."
    apt-get install -y -qq postgresql-16-cron
  else
    log "pg_cron: instalado"
  fi
}

configure_postgres() {
  local PG_CONF="/etc/postgresql/16/main/postgresql.conf"
  local PG_HBA="/etc/postgresql/16/main/pg_hba.conf"
  local TUNING_CONF="/etc/postgresql/16/main/conf.d/fcg3-tuning.conf"
  local changed=false

  # shared_preload_libraries
  if ! grep -q "shared_preload_libraries.*pg_cron" "$PG_CONF" 2>/dev/null; then
    sed -i "s/^#*shared_preload_libraries.*/shared_preload_libraries = 'pg_cron'/" "$PG_CONF" 2>/dev/null || \
      echo "shared_preload_libraries = 'pg_cron'" >> "$PG_CONF"
    changed=true
  fi

  # cron.database_name
  if ! grep -q "cron.database_name" "$PG_CONF"; then
    echo "cron.database_name = '$POSTGRES_DB'" >> "$PG_CONF"
    changed=true
  fi

  # Tuning
  if [[ ! -f "$TUNING_CONF" ]]; then
    mkdir -p "$(dirname "$TUNING_CONF")"
    cat > "$TUNING_CONF" << 'PGCONF'
shared_buffers = 128MB
effective_cache_size = 256MB
work_mem = 4MB
maintenance_work_mem = 64MB
max_connections = 30
wal_buffers = 4MB
checkpoint_completion_target = 0.9
huge_pages = off
PGCONF
    changed=true
  fi

  # pg_hba
  if ! grep -q "$POSTGRES_USER" "$PG_HBA" 2>/dev/null; then
    echo "host    all    ${POSTGRES_USER}    127.0.0.1/32    scram-sha-256" >> "$PG_HBA"
    changed=true
  fi

  if [[ "$changed" == true ]]; then
    systemctl restart postgresql
    log "PostgreSQL: configuracao atualizada e reiniciado"
  else
    systemctl is-active postgresql >/dev/null 2>&1 || systemctl start postgresql
    log "PostgreSQL: configuracao OK"
  fi

  systemctl enable postgresql >/dev/null 2>&1
}

create_database() {
  local db_exists
  db_exists=$(sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='${POSTGRES_DB}'" 2>/dev/null || echo "")

  if [[ "$db_exists" != "1" ]]; then
    log "Criando banco de dados e role..."
    sudo -u postgres psql -v ON_ERROR_STOP=1 <<SQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${POSTGRES_USER}') THEN
    CREATE ROLE ${POSTGRES_USER} WITH LOGIN PASSWORD '${POSTGRES_PASSWORD}';
  END IF;
END
\$\$;
CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER};
\c ${POSTGRES_DB}
CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_cron;
GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${POSTGRES_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${POSTGRES_USER};
SQL
    log "Banco de dados criado."
  else
    # Garantir extensoes existem
    sudo -u postgres psql -d "$POSTGRES_DB" -c "CREATE EXTENSION IF NOT EXISTS vector;" >/dev/null 2>&1
    sudo -u postgres psql -d "$POSTGRES_DB" -c "CREATE EXTENSION IF NOT EXISTS pg_cron;" >/dev/null 2>&1
    log "Banco de dados: ja existe"
  fi
}

ensure_swap() {
  # TODO: Descomente quando resolver o erro "skipping - it appears to have holes"
  # O erro acontece porque fallocate em alguns filesystems (ext4 com certas configs, btrfs)
  # cria arquivos esparsos. Solucao: usar dd em vez de fallocate.
  # Exemplo: dd if=/dev/zero of=/swapfile2 bs=1M count=1024
  #
  # local total_swap_kb
  # total_swap_kb=$(grep SwapTotal /proc/meminfo | awk '{print $2}')
  #
  # if [[ $total_swap_kb -lt 2000000 ]]; then
  #   if [[ ! -f /swapfile2 ]]; then
  #     log "Adicionando 1 GB de swap..."
  #     dd if=/dev/zero of=/swapfile2 bs=1M count=1024 status=progress
  #     chmod 600 /swapfile2
  #     mkswap /swapfile2 >/dev/null
  #     swapon /swapfile2
  #     grep -q '/swapfile2' /etc/fstab || echo '/swapfile2 none swap sw 0 0' >> /etc/fstab
  #   fi
  # fi
  #
  # grep -q 'vm.swappiness' /etc/sysctl.conf || echo 'vm.swappiness=60' >> /etc/sysctl.conf
  # sysctl -w vm.swappiness=60 >/dev/null 2>&1

  log "Swap: $(free -h | grep Swap | awk '{print $2}') total (gerenciamento desabilitado)"
}

ensure_firewall() {
  if command -v ufw &>/dev/null; then
    ufw allow 22/tcp  >/dev/null 2>&1 || true
    ufw allow 80/tcp  >/dev/null 2>&1 || true
    ufw allow 443/tcp >/dev/null 2>&1 || true
    ufw --force enable >/dev/null 2>&1 || true
    log "Firewall: portas 22, 80, 443 liberadas"
  fi
}

ensure_venvs() {
  local changed=false

  for svc in backend ai_service mcp_server; do
    local venv_path="$PROJECT_DIR/$svc/.venv"
    local req_file="$PROJECT_DIR/$svc/requirements.txt"

    if [[ ! -d "$venv_path" ]]; then
      log "Criando virtualenv: $svc..."
      python3 -m venv "$venv_path"
      "$venv_path/bin/pip" install --upgrade pip -q
      "$venv_path/bin/pip" install -r "$req_file" -q
      chown -R "$DEPLOY_USER:$DEPLOY_USER" "$venv_path"
      changed=true
    else
      log "Virtualenv $svc: existe"
    fi
  done

  [[ "$changed" == true ]] && log "Virtualenvs criados." || true
}

ensure_systemd_services() {
  local needs_reload=false

  # --- fcg3-api ---
  if [[ ! -f /etc/systemd/system/fcg3-api.service ]]; then
    cat > /etc/systemd/system/fcg3-api.service << EOF
[Unit]
Description=FCG3 FastAPI Backend
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=exec
User=$DEPLOY_USER
Group=$DEPLOY_USER
WorkingDirectory=$PROJECT_DIR/backend
EnvironmentFile=$ENV_FILE
ExecStart=$PROJECT_DIR/backend/.venv/bin/uvicorn src.main:app --host 127.0.0.1 --port 8000 --workers 1
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
MemoryMax=300M
MemoryHigh=250M

[Install]
WantedBy=multi-user.target
EOF
    needs_reload=true
  fi

  # --- fcg3-mcp ---
  if [[ ! -f /etc/systemd/system/fcg3-mcp.service ]]; then
    cat > /etc/systemd/system/fcg3-mcp.service << EOF
[Unit]
Description=FCG3 MCP Server
After=network.target postgresql.service fcg3-api.service

[Service]
Type=exec
User=$DEPLOY_USER
Group=$DEPLOY_USER
WorkingDirectory=$PROJECT_DIR
EnvironmentFile=$ENV_FILE
ExecStart=$PROJECT_DIR/mcp_server/.venv/bin/python -m mcp_server.main
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
MemoryMax=200M
MemoryHigh=150M

[Install]
WantedBy=multi-user.target
EOF
    needs_reload=true
  fi

  # --- fcg3-ai ---
  if [[ ! -f /etc/systemd/system/fcg3-ai.service ]]; then
    cat > /etc/systemd/system/fcg3-ai.service << EOF
[Unit]
Description=FCG3 LangChain AI Service
After=network.target postgresql.service fcg3-mcp.service

[Service]
Type=exec
User=$DEPLOY_USER
Group=$DEPLOY_USER
WorkingDirectory=$PROJECT_DIR
EnvironmentFile=$ENV_FILE
ExecStart=$PROJECT_DIR/ai_service/.venv/bin/python -m ai_service.main
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
MemoryMax=450M
MemoryHigh=350M

[Install]
WantedBy=multi-user.target
EOF
    needs_reload=true
  fi

  if [[ "$needs_reload" == true ]]; then
    systemctl daemon-reload
    systemctl enable fcg3-api fcg3-mcp fcg3-ai >/dev/null 2>&1
    log "Servicos systemd: criados e habilitados"
  else
    log "Servicos systemd: ja configurados"
  fi
}

ensure_nginx() {
  # Este servidor compartilhado usa /etc/nginx/sites-enabled/medclinic
  # O projeto FCG3 vive sob o path /server03
  local NGINX_CONF="/etc/nginx/sites-enabled/medclinic"
  local SNIPPET_FILE="$PROJECT_DIR/nginx-server03.conf"
  local WEB_DIR="/home/$DEPLOY_USER/desafio-fcg3/frontend"

  # Gerar snippet de referencia
  cat > "$SNIPPET_FILE" << 'NGINX_SNIPPET'
    # =========================================================
    # FCG3 — Flutter Web (/server03)
    # Acesso direto (VPN): http://desafio03.alphaedtech/server03/
    # =========================================================
    location /server03 {
        alias /home/grupo3/desafio-fcg3/frontend;
        try_files $uri $uri/ @server03_fallback;
    }

    location @server03_fallback {
        rewrite ^ /server03/index.html break;
        root /home/grupo3/desafio-fcg3/frontend;
    }

    # =========================================================
    # FCG3 — API Backend (/server03/api)
    # =========================================================
    location /server03/api/ {
        proxy_pass http://127.0.0.1:8000/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 30s;
    }

    # =========================================================
    # FCG3 — Webhook WhatsApp (/server03/webhook)
    # =========================================================
    location /server03/webhook/ {
        proxy_pass http://127.0.0.1:8000/webhook/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 10s;
    }

    # =========================================================
    # FCG3 — Health Check (/server03/health)
    # =========================================================
    location /server03/health {
        proxy_pass http://127.0.0.1:8000/health;
    }

    # =========================================================
    # FCG3 — Rotas sem prefixo (proxy externo faz strip de /server03)
    # Acesso externo: https://lab.alphaedtech.org.br/server03/
    # O proxy externo remove /server03 e repassa /api/, /webhook/, /health
    # =========================================================
    location /api/ {
        proxy_pass http://127.0.0.1:8000/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 30s;
    }

    location /webhook/ {
        proxy_pass http://127.0.0.1:8000/webhook/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 10s;
    }

    location = /health {
        proxy_pass http://127.0.0.1:8000/health;
    }
NGINX_SNIPPET

  # Criar diretorio do frontend
  mkdir -p "$WEB_DIR"
  if [[ ! -f "$WEB_DIR/index.html" ]] || grep -q "Deploy Flutter Web pendente" "$WEB_DIR/index.html" 2>/dev/null; then
    echo "<h1>FCG3 — Deploy Flutter Web pendente</h1>" > "$WEB_DIR/index.html"
  fi
  chown -R "$DEPLOY_USER:$DEPLOY_USER" "$WEB_DIR"

  # Verificar se o nginx config ja tem nosso bloco
  if [[ -f "$NGINX_CONF" ]] && grep -q "FCG3" "$NGINX_CONF"; then
    log "Nginx: configuracao FCG3 ja presente"
    return
  fi

  # Substituir o arquivo inteiro (medclinic -> FCG3)
  info "Nginx: aplicando configuracao FCG3..."

  # Backup do original (se existir e nao tiver backup ainda)
  if [[ -f "$NGINX_CONF" ]] && [[ ! -f "/home/$DEPLOY_USER/desafio-fcg3/medclinic-backup.old" ]]; then
    cp "$NGINX_CONF" "/home/$DEPLOY_USER/desafio-fcg3/medclinic-backup.old"
    chown "$DEPLOY_USER:$DEPLOY_USER" "/home/$DEPLOY_USER/desafio-fcg3/medclinic-backup.old"
    log "Backup do nginx original salvo em: /home/$DEPLOY_USER/desafio-fcg3/medclinic-backup.old"
  fi

  # Escrever configuracao completa
  cat > "$NGINX_CONF" << 'NGINXCONF'
server {
    listen 80;
    server_name _;

    root /home/grupo3/desafio-fcg3/frontend;
    index index.html;

    # =========================================================
    # FCG3 — Flutter Web (/server03) — acesso via VPN
    # =========================================================
    location /server03 {
        alias /home/grupo3/desafio-fcg3/frontend;
        try_files $uri $uri/ @server03_fallback;
    }

    location @server03_fallback {
        rewrite ^ /server03/index.html break;
        root /home/grupo3/desafio-fcg3/frontend;
    }

    # =========================================================
    # FCG3 — API (/server03/api) — acesso via VPN
    # =========================================================
    location /server03/api/ {
        proxy_pass http://127.0.0.1:8000/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 30s;
    }

    # =========================================================
    # FCG3 — Webhook (/server03/webhook) — acesso via VPN
    # =========================================================
    location /server03/webhook/ {
        proxy_pass http://127.0.0.1:8000/webhook/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 10s;
    }

    # =========================================================
    # FCG3 — Health (/server03/health) — acesso via VPN
    # =========================================================
    location /server03/health {
        proxy_pass http://127.0.0.1:8000/health;
    }

    # =========================================================
    # FCG3 — Rotas sem prefixo (proxy externo faz strip de /server03)
    # Acesso externo: https://lab.alphaedtech.org.br/server03/
    # =========================================================
    location /api/ {
        proxy_pass http://127.0.0.1:8000/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 30s;
    }

    location /webhook/ {
        proxy_pass http://127.0.0.1:8000/webhook/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 10s;
    }

    location = /health {
        proxy_pass http://127.0.0.1:8000/health;
    }

    # =========================================================
    # Fallback — Flutter Web SPA
    # =========================================================
    location / {
        try_files $uri $uri/ /index.html;
    }
}
NGINXCONF

  # Testar configuracao
  if nginx -t >/dev/null 2>&1; then
    systemctl reload nginx
    log "Nginx: configuracao FCG3 aplicada e recarregada"
  else
    # Rollback
    local err_msg
    err_msg=$(nginx -t 2>&1)
    if [[ -f "/home/$DEPLOY_USER/desafio-fcg3/medclinic-backup.old" ]]; then
      cp "/home/$DEPLOY_USER/desafio-fcg3/medclinic-backup.old" "$NGINX_CONF"
      systemctl reload nginx 2>/dev/null || true
    fi
    warn "Nginx: FALHA na validacao — restaurado backup"
    warn "Erro: $err_msg"
  fi
}

ensure_backup_cron() {
  local BACKUP_SCRIPT="$PROJECT_DIR/backup.sh"

  if [[ ! -f "$BACKUP_SCRIPT" ]]; then
    mkdir -p /home/grupo3/backups
    cat > "$BACKUP_SCRIPT" << 'BACKUP'
#!/bin/bash
set -e
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR=/home/grupo3/backups
sudo -u postgres pg_dump fcg3 | gzip > "$BACKUP_DIR/db_$TIMESTAMP.sql.gz"
find "$BACKUP_DIR" -name "db_*.sql.gz" -mtime +7 -delete
echo "[$(date)] Backup: db_$TIMESTAMP.sql.gz"
BACKUP
    chmod +x "$BACKUP_SCRIPT"
    (crontab -l 2>/dev/null | grep -v "backup.sh"; echo "0 3 * * * $BACKUP_SCRIPT >> /var/log/fcg3-backup.log 2>&1") | crontab -
    log "Backup cron: configurado (3h diario)"
  else
    log "Backup cron: ja configurado"
  fi
}

# =============================================================================
# Funcoes de acao (menu)
# =============================================================================

action_update_repo() {
  info "Atualizando repositorio..."

  cd "$PROJECT_DIR"
  sudo -u "$DEPLOY_USER" git pull

  # Verificar se requirements mudaram
  if git diff HEAD~1 --name-only 2>/dev/null | grep -q "requirements.txt"; then
    warn "requirements.txt mudou — atualizando dependencias..."
    for svc in backend ai_service mcp_server; do
      "$PROJECT_DIR/$svc/.venv/bin/pip" install -r "$PROJECT_DIR/$svc/requirements.txt" -q
    done
    log "Dependencias atualizadas."
  fi

  # Rodar migrations pendentes
  info "Verificando migrations pendentes..."
  sudo -u "$DEPLOY_USER" bash -c "
    set -a; source $ENV_FILE; set +a
    cd $PROJECT_DIR/backend
    $PROJECT_DIR/backend/.venv/bin/alembic upgrade head
  "
  log "Migrations aplicadas."

  # Checar variaveis novas
  check_env_diff

  # Reiniciar servicos
  info "Reiniciando servicos..."
  systemctl restart fcg3-api
  sleep 2
  systemctl restart fcg3-mcp
  sleep 2
  systemctl restart fcg3-ai
  sleep 3

  # Verificar saude
  check_health

  log "Update completo."
}

action_reseed() {
  warn "Isso vai APAGAR todos os dados atuais e recriar com dados de seed."
  echo -en "${YELLOW}Confirmar? (digite 'sim' para continuar): ${NC}"
  read -r confirm
  [[ "$confirm" != "sim" ]] && { info "Cancelado."; return; }

  info "Re-executando seed (truncate + insert)..."
  sudo -u "$DEPLOY_USER" bash -c "
    set -a; source $ENV_FILE; set +a
    cd $PROJECT_DIR/backend
    $PROJECT_DIR/backend/.venv/bin/python scripts/seed.py
  "
  log "Seed completo — dados recriados."
}

action_reingest() {
  warn "Isso vai APAGAR os embeddings atuais e gerar novos (consome creditos da API)."
  echo -en "${YELLOW}Confirmar? (digite 'sim' para continuar): ${NC}"
  read -r confirm
  [[ "$confirm" != "sim" ]] && { info "Cancelado."; return; }

  info "Re-ingerindo knowledge base..."
  sudo -u "$DEPLOY_USER" bash -c "
    set -a; source $ENV_FILE; set +a
    cd $PROJECT_DIR
    $PROJECT_DIR/ai_service/.venv/bin/python -m ai_service.ingest
  "
  log "Knowledge base re-ingerida."
}

action_run_migrations() {
  info "Rodando migrations..."
  sudo -u "$DEPLOY_USER" bash -c "
    set -a; source $ENV_FILE; set +a
    cd $PROJECT_DIR/backend
    $PROJECT_DIR/backend/.venv/bin/alembic upgrade head
  "
  log "Migrations aplicadas."
}

action_restart_services() {
  info "Reiniciando servicos..."
  systemctl restart fcg3-api
  sleep 2
  systemctl restart fcg3-mcp
  sleep 2
  systemctl restart fcg3-ai
  sleep 3
  check_health
}

action_check_status() {
  echo ""
  echo -e "${BOLD}--- Status dos Servicos ---${NC}"
  for svc in fcg3-api fcg3-mcp fcg3-ai; do
    local status
    status=$(systemctl is-active "$svc" 2>/dev/null || echo "inativo")
    local mem
    mem=$(systemctl show "$svc" --property=MemoryCurrent 2>/dev/null | cut -d= -f2)
    if [[ "$status" == "active" ]]; then
      echo -e "  ${GREEN}●${NC} $svc: ativo (RAM: $mem)"
    else
      echo -e "  ${RED}●${NC} $svc: $status"
    fi
  done

  echo ""
  echo -e "${BOLD}--- Saude (health checks) ---${NC}"
  check_health

  echo ""
  echo -e "${BOLD}--- Recursos ---${NC}"
  echo "  RAM: $(free -h | grep Mem | awk '{print $3 " usada / " $2 " total"}')"
  echo "  Swap: $(free -h | grep Swap | awk '{print $3 " usada / " $2 " total"}')"
  echo "  Disco: $(df -h / | tail -1 | awk '{print $3 " usado / " $2 " total (" $5 ")"}')"
  echo ""
}

action_view_logs() {
  echo ""
  echo "Qual servico?"
  echo "  1) fcg3-api (FastAPI)"
  echo "  2) fcg3-ai (LangChain)"
  echo "  3) fcg3-mcp (MCP Server)"
  echo "  4) Todos"
  echo -en "${CYAN}Escolha [1-4]: ${NC}"
  read -r log_choice

  case $log_choice in
    1) journalctl -u fcg3-api -n 50 --no-pager ;;
    2) journalctl -u fcg3-ai -n 50 --no-pager ;;
    3) journalctl -u fcg3-mcp -n 50 --no-pager ;;
    4) journalctl -u 'fcg3-*' -n 80 --no-pager ;;
    *) warn "Opcao invalida" ;;
  esac
}

action_deploy_flutter() {
  local WEB_DIR="/home/$DEPLOY_USER/desafio-fcg3/frontend"
  local TARBALL="/tmp/flutter-web.tar.gz"

  if [[ -f "$TARBALL" ]]; then
    info "Encontrado $TARBALL — extraindo..."
    rm -rf "$WEB_DIR"
    mkdir -p "$WEB_DIR"
    tar -xzf "$TARBALL" -C "$WEB_DIR" --strip-components=1 2>/dev/null || \
      tar -xzf "$TARBALL" -C "$WEB_DIR"
    chown -R "$DEPLOY_USER:$DEPLOY_USER" "$WEB_DIR"
    rm -f "$TARBALL"
    log "Flutter Web deployado em $WEB_DIR"
  elif [[ -d "$PROJECT_DIR/mobile/build/web" ]]; then
    info "Encontrado build local em mobile/build/web — copiando..."
    rm -rf "$WEB_DIR"
    cp -r "$PROJECT_DIR/mobile/build/web" "$WEB_DIR"
    chown -R "$DEPLOY_USER:$DEPLOY_USER" "$WEB_DIR"
    log "Flutter Web deployado em $WEB_DIR"
  else
    warn "Nenhum build encontrado."
    echo ""
    echo "  Build (na sua maquina local):"
    echo ""
    echo "    cd mobile"
    echo "    flutter build web --release \\"
    echo "      --base-href=/server03/ \\"
    echo "      --dart-define=API_BASE_URL=/server03/api/v1"
    echo ""
    echo "  Enviar para o servidor:"
    echo "    cd build"
    echo "    tar -czf /tmp/flutter-web.tar.gz web/"
    echo "    scp /tmp/flutter-web.tar.gz grupo3@SERVIDOR:/tmp/"
    echo ""
    echo "  Depois rode este script novamente (opcao 8)."
    echo ""
    echo "  URLs finais:"
    echo "    App:     https://lab.alphaedtech.org.br/server03/"
    echo "    API:     https://lab.alphaedtech.org.br/server03/api/v1/"
    echo "    Webhook: https://lab.alphaedtech.org.br/server03/webhook/whatsapp"
  fi
}

# =============================================================================
# Utilidades
# =============================================================================

check_health() {
  for port_svc in "8000:fcg3-api" "8001:fcg3-ai" "8002:fcg3-mcp"; do
    local port="${port_svc%%:*}"
    local svc="${port_svc##*:}"
    if curl -sf "http://127.0.0.1:$port/health" >/dev/null 2>&1; then
      echo -e "  ${GREEN}✓${NC} $svc (:$port) — saudavel"
    else
      echo -e "  ${RED}✗${NC} $svc (:$port) — nao responde"
    fi
  done
}

check_env_diff() {
  local example="$PROJECT_DIR/.env.example"
  [[ ! -f "$example" ]] && return

  local missing=()
  while IFS='=' read -r key _; do
    # Ignorar comentarios e linhas vazias
    [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
    key=$(echo "$key" | xargs)  # trim
    [[ -z "$key" ]] && continue
    if ! grep -q "^$key=" "$ENV_FILE" 2>/dev/null; then
      missing+=("$key")
    fi
  done < "$example"

  if [[ ${#missing[@]} -gt 0 ]]; then
    warn "Variaveis presentes no .env.example mas ausentes no .env:"
    for var in "${missing[@]}"; do
      echo -e "    ${YELLOW}→ $var${NC}"
    done
    echo ""
    warn "Adicione-as ao .env se necessario."
  fi
}

# =============================================================================
# Menu principal
# =============================================================================

show_menu() {
  echo ""
  echo -e "${BOLD}========================================${NC}"
  echo -e "${BOLD}   FCG3 — Painel de Deploy${NC}"
  echo -e "${BOLD}========================================${NC}"
  echo ""
  echo "  1) Atualizar repositorio (git pull + deps + migrations + restart)"
  echo "  2) Re-executar seed (apaga dados e recria)"
  echo "  3) Re-ingerir knowledge base (apaga embeddings e gera novos)"
  echo "  4) Rodar migrations apenas"
  echo "  5) Reiniciar servicos"
  echo "  6) Ver status e saude"
  echo "  7) Ver logs"
  echo "  8) Deploy Flutter Web"
  echo "  0) Sair"
  echo ""
  echo -en "${CYAN}Escolha [0-8]: ${NC}"
}

# =============================================================================
# Execucao principal
# =============================================================================

main() {
  echo ""
  echo -e "${BOLD}FCG3 Deploy — Verificando infraestrutura...${NC}"
  echo ""

  # Passo 1: Garantir que toda infraestrutura permanente esta OK
  install_system_packages
  ensure_swap
  install_pgvector
  install_pg_cron
  configure_postgres
  create_database
  ensure_venvs
  ensure_systemd_services
  ensure_nginx
  ensure_backup_cron
  ensure_firewall

  echo ""
  log "Infraestrutura verificada — tudo OK."

  # Passo 2: Verificar se eh primeira execucao (servicos nunca rodaram)
  if ! systemctl is-active fcg3-api >/dev/null 2>&1; then
    warn "Primeira execucao detectada — iniciando setup completo..."
    echo ""

    # Migrations
    info "Rodando migrations..."
    sudo -u "$DEPLOY_USER" bash -c "
      set -a; source $ENV_FILE; set +a
      cd $PROJECT_DIR/backend
      $PROJECT_DIR/backend/.venv/bin/alembic upgrade head
    "
    log "Migrations aplicadas."

    # Seed
    info "Populando banco (seed)..."
    sudo -u "$DEPLOY_USER" bash -c "
      set -a; source $ENV_FILE; set +a
      cd $PROJECT_DIR/backend
      $PROJECT_DIR/backend/.venv/bin/python scripts/seed.py
    "
    log "Seed executado."

    # Ingest
    info "Ingerindo knowledge base (embeddings)..."
    warn "Isso consome creditos da API de embeddings."
    sudo -u "$DEPLOY_USER" bash -c "
      set -a; source $ENV_FILE; set +a
      cd $PROJECT_DIR
      $PROJECT_DIR/ai_service/.venv/bin/python -m ai_service.ingest
    "
    log "Knowledge base ingerida."

    # Iniciar servicos
    info "Iniciando servicos..."
    systemctl start fcg3-api
    sleep 2
    systemctl start fcg3-mcp
    sleep 2
    systemctl start fcg3-ai
    sleep 3

    echo ""
    check_health
    echo ""
    log "Setup completo! Use 'sudo bash deploy.sh' para gerenciar."
    exit 0
  fi

  # Passo 3: Ja esta configurado — mostrar menu
  while true; do
    show_menu
    read -r choice
    echo ""
    case $choice in
      1) action_update_repo ;;
      2) action_reseed ;;
      3) action_reingest ;;
      4) action_run_migrations ;;
      5) action_restart_services ;;
      6) action_check_status ;;
      7) action_view_logs ;;
      8) action_deploy_flutter ;;
      0) echo "Saindo."; exit 0 ;;
      *) warn "Opcao invalida." ;;
    esac
  done
}

main "$@"
