# CI/CD Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Automate deployment to the bare-metal server on every push to `main`, including Flutter Web builds, using a self-hosted GitHub Actions runner + cloud runner hybrid.

**Architecture:** A single GitHub Actions workflow with two jobs: (1) a cloud runner (`ubuntu-latest`) builds Flutter Web when `mobile/` files change, and (2) a self-hosted runner on the server pulls code, updates deps, runs migrations, restarts services, and deploys the Flutter build artifact. The self-hosted runner only makes outbound connections (works behind VPN).

**Tech Stack:** GitHub Actions, self-hosted runner (Linux x64), Flutter 3.41.6, bash, systemd

**Decision Record:** See `docs/adr-cicd-approach.md` for the full comparison of approaches and why self-hosted runner was chosen over webhook-based deploy.

---

## File Structure

| File | Action | Purpose |
|------|--------|---------|
| `.github/workflows/deploy.yml` | Create | The single workflow file -- builds Flutter Web on cloud, deploys backend on self-hosted runner |
| `scripts/ci-deploy.sh` | Create | Non-interactive deploy script called by the workflow (extracted from scripts/deploy.sh logic) |
| `docs/deploy.md` | Modify | Add CI/CD section documenting the automated pipeline and self-hosted runner setup |

---

## Prerequisites (manual, on the server -- documented in Task 1)

These steps must be done once, manually, on the server via SSH. They cannot be automated by the workflow because the runner doesn't exist yet.

---

### Task 1: Document and Execute Self-hosted Runner Installation on Server

This task is **manual** -- performed via SSH on the server. The plan documents the exact commands.

**Files:**
- Modify: `docs/deploy.md` (add CI/CD section at the end)

- [ ] **Step 1: SSH into the server**

```bash
# Connect via VPN first, then:
ssh grupo3@desafio03
```

- [ ] **Step 2: Create a directory for the runner**

```bash
mkdir -p /home/grupo3/actions-runner && cd /home/grupo3/actions-runner
```

- [ ] **Step 3: Download the runner binary**

Go to `https://github.com/Weym/desafio-fcg3/settings/actions/runners/new` and follow the exact commands shown by GitHub. They look like this (but use the actual token GitHub gives you):

```bash
# Download (GitHub shows the exact URL and SHA)
curl -o actions-runner-linux-x64-2.321.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.321.0/actions-runner-linux-x64-2.321.0.tar.gz

# Validate hash (GitHub shows the expected hash)
echo "<HASH_FROM_GITHUB>  actions-runner-linux-x64-2.321.0.tar.gz" | shasum -a 256 -c

# Extract
tar xzf ./actions-runner-linux-x64-2.321.0.tar.gz
```

**Important:** The version number and hash change over time. Always use what GitHub shows on the runner setup page.

- [ ] **Step 4: Configure the runner**

```bash
# Run as grupo3, NOT as root
./config.sh --url https://github.com/Weym/desafio-fcg3 --token <TOKEN_FROM_GITHUB>
```

When prompted:
- **Runner group:** press Enter (default)
- **Runner name:** `servidor-fcg3`
- **Labels:** `self-hosted,linux,x64,fcg3` (add `fcg3` as a custom label)
- **Work folder:** press Enter (default `_work`)

- [ ] **Step 5: Install and start as a systemd service**

```bash
# Install the service (requires sudo)
sudo ./svc.sh install grupo3

# Start the service
sudo ./svc.sh start

# Verify it's running
sudo ./svc.sh status
```

This creates a systemd service that auto-starts on boot and runs as `grupo3`.

- [ ] **Step 6: Grant grupo3 passwordless sudo for deploy commands**

The workflow needs to restart systemd services, which requires sudo. Create a sudoers drop-in:

```bash
sudo visudo -f /etc/sudoers.d/fcg3-deploy
```

Add this content:

```
# Allow grupo3 to restart FCG3 services and run deploy tasks without password
grupo3 ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart fcg3-api
grupo3 ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart fcg3-mcp
grupo3 ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart fcg3-ai
grupo3 ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart fcg3-api fcg3-mcp fcg3-ai
grupo3 ALL=(ALL) NOPASSWD: /usr/bin/systemctl status fcg3-api
grupo3 ALL=(ALL) NOPASSWD: /usr/bin/systemctl status fcg3-mcp
grupo3 ALL=(ALL) NOPASSWD: /usr/bin/systemctl status fcg3-ai
```

Verify syntax:

```bash
sudo visudo -c -f /etc/sudoers.d/fcg3-deploy
# Expected: /etc/sudoers.d/fcg3-deploy: parsed OK
```

- [ ] **Step 7: Verify the runner appears on GitHub**

Go to `https://github.com/Weym/desafio-fcg3/settings/actions/runners`.
The runner `servidor-fcg3` should show as **Idle** with a green dot.

---

### Task 2: Create the Non-interactive Deploy Script

This script extracts the deploy logic from `scripts/deploy.sh` into a non-interactive version that the CI workflow can call. It does NOT replace `scripts/deploy.sh` -- the manual menu script remains for ad-hoc server management.

**Files:**
- Create: `scripts/ci-deploy.sh`

- [ ] **Step 1: Create `scripts/ci-deploy.sh`**

```bash
#!/bin/bash
# =============================================================================
# ci-deploy.sh — Non-interactive deploy script for CI/CD
#
# Called by GitHub Actions self-hosted runner.
# Does NOT replace scripts/deploy.sh — that script remains for manual server management.
#
# Usage:
#   bash scripts/ci-deploy.sh [--skip-flutter]
#
# Expects:
#   - PROJECT_DIR env var set (defaults to script's parent's parent dir)
#   - .env file present at PROJECT_DIR/.env
#   - Virtualenvs already created (by initial scripts/deploy.sh run)
#   - Optionally: /tmp/flutter-web/ directory with built Flutter Web files
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

  # Source env again in subshell context
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
# Step 5: Health checks
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
  check_health

  echo ""
  log "Deploy complete."
}

main "$@"
```

- [ ] **Step 2: Make the script executable**

Run: `chmod +x scripts/ci-deploy.sh`

- [ ] **Step 3: Commit**

```bash
git add scripts/ci-deploy.sh
git commit -m "feat: add non-interactive CI deploy script"
```

---

### Task 3: Create the GitHub Actions Workflow

This is the core of the CI/CD pipeline. One workflow file, two jobs.

**Files:**
- Create: `.github/workflows/deploy.yml`

- [ ] **Step 1: Create `.github/workflows/deploy.yml`**

```yaml
name: Deploy to Server

on:
  push:
    branches: [main]

# Prevent concurrent deploys -- cancel in-progress if a new push arrives
concurrency:
  group: deploy-production
  cancel-in-progress: true

jobs:
  # ================================================================
  # Job 1: Build Flutter Web (cloud runner)
  # Only runs when mobile/ files change.
  # Uploads the build output as a workflow artifact.
  # ================================================================
  build-flutter:
    runs-on: ubuntu-latest
    # Detect if mobile/ files changed in this push
    outputs:
      flutter-changed: ${{ steps.changes.outputs.mobile }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 2  # Need previous commit for diff

      - name: Detect mobile/ changes
        id: changes
        run: |
          if git diff --name-only HEAD~1 HEAD | grep -q '^mobile/'; then
            echo "mobile=true" >> "$GITHUB_OUTPUT"
          else
            echo "mobile=false" >> "$GITHUB_OUTPUT"
          fi

      - name: Setup Flutter
        if: steps.changes.outputs.mobile == 'true'
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.41.6'
          channel: 'stable'
          cache: true

      - name: Install dependencies
        if: steps.changes.outputs.mobile == 'true'
        working-directory: mobile
        run: flutter pub get

      - name: Build Flutter Web
        if: steps.changes.outputs.mobile == 'true'
        working-directory: mobile
        run: |
          flutter build web --release \
            --base-href=/server03/ \
            --dart-define=API_BASE_URL=/server03/api/v1

      - name: Upload Flutter Web artifact
        if: steps.changes.outputs.mobile == 'true'
        uses: actions/upload-artifact@v4
        with:
          name: flutter-web-build
          path: mobile/build/web/
          retention-days: 5

  # ================================================================
  # Job 2: Deploy to server (self-hosted runner)
  # Runs after Flutter build (if it ran).
  # Pulls code, updates deps, migrates DB, restarts services.
  # ================================================================
  deploy:
    needs: build-flutter
    runs-on: [self-hosted, linux, x64, fcg3]
    # Always run deploy, even if flutter build was skipped
    if: always() && !cancelled()
    defaults:
      run:
        working-directory: /home/grupo3/desafio-fcg3

    steps:
      - name: Pull latest code
        run: |
          git fetch origin main
          git reset --hard origin/main

      - name: Download Flutter Web artifact
        if: needs.build-flutter.outputs.flutter-changed == 'true' && needs.build-flutter.result == 'success'
        uses: actions/download-artifact@v4
        with:
          name: flutter-web-build
          path: /home/grupo3/desafio-fcg3/flutter-web-build

      - name: Run deploy script
        env:
          FLUTTER_CHANGED: ${{ needs.build-flutter.outputs.flutter-changed }}
          FLUTTER_SUCCESS: ${{ needs.build-flutter.result }}
        run: |
          if [[ "$FLUTTER_CHANGED" == "true" && "$FLUTTER_SUCCESS" == "success" ]]; then
            bash scripts/ci-deploy.sh
          else
            bash scripts/ci-deploy.sh --skip-flutter
          fi

      - name: Clean up Flutter artifact
        if: always()
        run: rm -rf /home/grupo3/desafio-fcg3/flutter-web-build
```

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/deploy.yml
git commit -m "feat: add GitHub Actions CI/CD workflow with self-hosted runner"
```

---

### Task 4: Update docs/deploy.md with CI/CD Documentation

**Files:**
- Modify: `docs/deploy.md` (add section at the end)

- [ ] **Step 1: Add CI/CD section to docs/deploy.md**

Append the following after the "Estimativa de RAM" section at the end of `docs/deploy.md`:

```markdown
---

## CI/CD — Deploy Automatizado

O deploy acontece automaticamente quando um push é feito na branch `main`. A pipeline usa um **self-hosted GitHub Actions runner** instalado no servidor.

### Como funciona

\```
Push na main
    │
    ├──► Job 1: build-flutter (GitHub cloud runner)
    │      - Só roda se arquivos em mobile/ mudaram
    │      - flutter build web --release
    │      - Upload do artifact
    │
    └──► Job 2: deploy (self-hosted runner no servidor)
           - git pull origin main
           - pip install (se requirements mudou)
           - alembic upgrade head
           - systemctl restart fcg3-api fcg3-mcp fcg3-ai
           - Download + extração do Flutter Web (se disponível)
           - Re-ingestão da knowledge base (se ai_service/knowledge/ mudou)
           - Health checks
\```

### Decisão de Arquitetura

A escolha do self-hosted runner sobre webhook-based deploy está documentada em `docs/adr-cicd-approach.md` com uma comparação detalhada de 20 critérios.

### Pré-requisitos do Runner

- Runner instalado em `/home/grupo3/actions-runner` (systemd service)
- `grupo3` tem sudoers para restart dos serviços FCG3
- Deploy key SSH configurada no GitHub (já existente)

### Verificar Status

\```bash
# Status do runner
sudo /home/grupo3/actions-runner/svc.sh status

# Logs do runner
journalctl -u actions.runner.Weym-desafio-fcg3.servidor-fcg3 -f

# Dashboard no GitHub
# https://github.com/Weym/desafio-fcg3/actions
\```

### Troubleshooting

| Problema | Solução |
|----------|---------|
| Runner offline no GitHub | `sudo /home/grupo3/actions-runner/svc.sh start` |
| Deploy falhou (GitHub UI) | Verificar logs no Actions tab → re-run |
| Health check falhou | `sudo journalctl -u fcg3-api -n 50` para ver o erro |
| Flutter build falhou | Verificar Actions tab → job "build-flutter" → logs |
| Migrations falharam | SSH no servidor → `cd /home/grupo3/desafio-fcg3/backend && .venv/bin/alembic history` |

### Deploy Manual (ainda funciona)

O `scripts/deploy.sh` com menu interativo continua disponível para ações que não estão no CI/CD (seed, reingest, logs):

\```bash
ssh grupo3@desafio03
cd /home/grupo3/desafio-fcg3
sudo bash scripts/deploy.sh
\```
```

- [ ] **Step 2: Commit**

```bash
git add docs/deploy.md
git commit -m "docs: add CI/CD section to docs/deploy.md"
```

---

### Task 5: Test the Full Pipeline

- [ ] **Step 1: Verify the runner is online**

On GitHub: go to `https://github.com/Weym/desafio-fcg3/settings/actions/runners`.
Runner `servidor-fcg3` should show **Idle** (green dot).

- [ ] **Step 2: Push all changes to main and observe**

```bash
git push origin main
```

- [ ] **Step 3: Monitor the workflow on GitHub**

Go to `https://github.com/Weym/desafio-fcg3/actions`.
You should see the "Deploy to Server" workflow running with two jobs.

- [ ] **Step 4: Verify the deploy job completes**

The `deploy` job should show:
- "Pull latest code" -- success
- "Run deploy script" -- success with health check output
- "Download Flutter Web artifact" -- skipped (unless mobile/ changed) or success

- [ ] **Step 5: Verify services are healthy on the server**

```bash
ssh grupo3@desafio03
curl http://127.0.0.1:8000/health
curl http://127.0.0.1:8001/health
curl http://127.0.0.1:8002/health
```

All three should return 200 OK.

- [ ] **Step 6: Test Flutter Web deploy**

Make a trivial change in `mobile/` (e.g., add a comment to `mobile/lib/main.dart`), commit and push. The workflow should now run both jobs: build-flutter on the cloud runner and deploy on the self-hosted runner. After completion, verify:

```bash
curl -s https://lab.alphaedtech.org.br/server03/ | head -20
```

Should return actual Flutter Web HTML, not the placeholder "Deploy Flutter Web pendente".

---

## Execution Order

| # | Task | Type | Depends on |
|---|------|------|------------|
| 1 | Install self-hosted runner | Manual (SSH) | Nothing |
| 2 | Create `scripts/ci-deploy.sh` | Code | Nothing |
| 3 | Create `.github/workflows/deploy.yml` | Code | Nothing |
| 4 | Update `docs/deploy.md` | Docs | Nothing |
| 5 | Test the full pipeline | Manual | Tasks 1-4 |

Tasks 2, 3, and 4 can be done in parallel (no dependencies between them). Task 1 is manual and must be done before Task 5. Task 5 must be last.
