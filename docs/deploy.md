# Deploy Bare-Metal em Ubuntu 24.04 — Sem Docker

## Visão Geral

Tudo é gerenciado pelo script `scripts/deploy.sh`. Na primeira execução ele instala a infraestrutura completa. Nas seguintes, apresenta um menu interativo para ações de manutenção.

```
Internet (HTTPS)
   │
   └── https://lab.alphaedtech.org.br/server03/
         │
         └──► Nginx (servidor compartilhado)
                ├── /server03/            ──► Flutter Web (arquivos estáticos)
                ├── /server03/api/        ──► proxy 127.0.0.1:8000/api/
                └── /server03/webhook/    ──► proxy 127.0.0.1:8000/webhook/

VPN (HTTP)
   │
   └── http://desafio03.alphaedtech/server03/  (mesmo bloco nginx)

Internamente (localhost only):
   FastAPI :8000 ──► LangChain :8001 ──► MCP Server :8002
        │
        └──► PostgreSQL :5432
```

O Nginx faz strip do prefixo `/server03` — os serviços Python não sabem que existe.

---

## URLs Finais

| Recurso | URL |
|---------|-----|
| App (Flutter Web) | `https://lab.alphaedtech.org.br/server03/` |
| API | `https://lab.alphaedtech.org.br/server03/api/v1/` |
| Webhook WhatsApp | `https://lab.alphaedtech.org.br/server03/webhook/whatsapp` |
| Health check | `https://lab.alphaedtech.org.br/server03/health` |
| Acesso VPN | `http://desafio03.alphaedtech/server03/` |

---

## Pré-requisitos

- Ubuntu 24.04 LTS (servidor compartilhado — grupo3)
- Acesso sudo
- Conexão com a internet (para instalar pacotes e acessar APIs)
- Arquivo `.env` preenchido com secrets reais
- Deploy key SSH configurada no GitHub (ver [ssh-setup.md](ssh-setup.md) seção 5)

---

## Deploy Inicial (primeira vez)

```bash
# 1. Conectar no servidor (ver docs/ssh-setup.md)
ssh grupo3@desafio03

# 2. Clonar o projeto (branch de deploy)
git clone -b feat/backend-execution git@github.com:Hnry-Gab/desafio-fcg3.git /home/grupo3/desafio-fcg3

# 3. Configurar variáveis de ambiente
cd /home/grupo3/desafio-fcg3
cp .env.example .env
nano .env    # Preencher com valores reais (ver tabela abaixo)

# 4. Executar deploy
sudo bash scripts/deploy.sh
```

Na primeira execução o script:
1. Instala pacotes do sistema (PostgreSQL 16, pgvector, pg_cron, Python 3.12)
2. Configura swap (2 GB total)
3. Cria banco de dados e role
4. Cria virtualenvs para os 3 serviços Python
5. Roda migrations (Alembic)
6. Executa seed (dados iniciais)
7. Ingere knowledge base (RAG embeddings)
8. Cria serviços systemd e inicia tudo
9. Gera snippet Nginx (aplicação manual no arquivo compartilhado)
10. Configura backup diário via cron

---

## Atualizações (execuções seguintes)

```bash
ssh grupo3@desafio03
cd /home/grupo3/desafio-fcg3
sudo bash scripts/deploy.sh
```

O menu apresentado:

```
========================================
   FCG3 — Painel de Deploy
========================================

  1) Atualizar repositório (git pull + deps + migrations + restart)
  2) Re-executar seed (apaga dados e recria)
  3) Re-ingerir knowledge base (apaga embeddings e gera novos)
  4) Rodar migrations apenas
  5) Reiniciar serviços
  6) Ver status e saúde
  7) Ver logs
  8) Deploy Flutter Web
  0) Sair
```

---

## Variáveis de Ambiente (.env)

| Variável | Como obter |
|----------|-----------|
| `POSTGRES_PASSWORD` | `openssl rand -hex 16` |
| `JWT_SECRET` | `openssl rand -hex 32` |
| `MCP_SERVICE_TOKEN` | `openssl rand -hex 32` |
| `WHATSAPP_TOKEN` | Meta for Developers → WhatsApp → API Setup |
| `WHATSAPP_PHONE_NUMBER_ID` | Meta for Developers → WhatsApp → Phone Numbers |
| `WHATSAPP_APP_SECRET` | Meta for Developers → Basic Settings |
| `WHATSAPP_WEBHOOK_VERIFY_TOKEN` | `openssl rand -hex 16` (livre escolha) |
| `OPENROUTER_API_KEY` | https://openrouter.ai/keys |
| `RESEND_API_KEY` | https://resend.com/api-keys |

### URLs no .env (bare-metal — todas 127.0.0.1)

```env
# PostgreSQL
POSTGRES_DB=fcg3
POSTGRES_USER=fcg3
POSTGRES_PASSWORD=SUA_SENHA
POSTGRES_HOST=127.0.0.1
POSTGRES_PORT=5432

# Database URLs
DATABASE_URL=postgresql+asyncpg://fcg3:SUA_SENHA@127.0.0.1:5432/fcg3
ALEMBIC_DATABASE_URL=postgresql://fcg3:SUA_SENHA@127.0.0.1:5432/fcg3
DATABASE_URL_AI=postgresql+psycopg://fcg3:SUA_SENHA@127.0.0.1:5432/fcg3
DATABASE_URL_MCP=postgresql+asyncpg://fcg3:SUA_SENHA@127.0.0.1:5432/fcg3

# Serviços internos (localhost — Nginx faz strip do /server03)
AI_SERVICE_URL=http://127.0.0.1:8001
FASTAPI_URL=http://127.0.0.1:8000
FASTAPI_BASE_URL=http://127.0.0.1:8000/api/v1
MCP_SERVER_URL=http://127.0.0.1:8002/mcp
```

**Nota**: nenhuma variável no `.env` contém `/server03`. O prefixo é tratado exclusivamente pelo Nginx.

---

## Nginx (servidor compartilhado)

O servidor já tem um arquivo nginx em `/etc/nginx/sites-enabled/medclinic` com outros projetos. O `scripts/deploy.sh` gera um snippet em `nginx-server03.conf` com o bloco correto para substituir o antigo `/server03` (medclinic).

### Aplicar manualmente

```bash
# Ver o snippet gerado
cat /home/grupo3/desafio-fcg3/nginx-server03.conf

# Editar o arquivo do servidor
sudo nano /etc/nginx/sites-enabled/medclinic

# Substituir o bloco antigo /server03 pelo novo
# Testar e recarregar
sudo nginx -t && sudo systemctl reload nginx
```

---

## Deploy do Flutter Web

O Flutter Web são arquivos estáticos servidos pelo Nginx em `/home/grupo3/desafio-fcg3/frontend`.

### Build (na sua máquina local)

```bash
cd mobile
flutter build web --release \
  --base-href=/server03/ \
  --dart-define=API_BASE_URL=/server03/api/v1
```

- `--base-href=/server03/` — faz assets carregarem corretamente sob o prefixo
- `API_BASE_URL=/server03/api/v1` — URL relativa, funciona tanto na VPN quanto externamente

### Enviar para o servidor

```bash
cd mobile/build
tar -czf /tmp/flutter-web.tar.gz web/
scp /tmp/flutter-web.tar.gz grupo3@desafio03:/tmp/
```

### Deployar (no servidor)

```bash
cd /home/grupo3/desafio-fcg3
sudo bash scripts/deploy.sh
# Escolher opção 8
```

---

## Webhook WhatsApp

1. Meta for Developers → App → WhatsApp → Configuration
2. Callback URL: `https://lab.alphaedtech.org.br/server03/webhook/whatsapp`
3. Verify token: mesmo valor de `WHATSAPP_WEBHOOK_VERIFY_TOKEN` no `.env`
4. Subscribe em: `messages`

---

## SSL (HTTPS)

Já gerenciado pelo servidor principal (`lab.alphaedtech.org.br`). Não precisa configurar Certbot — o certificado já cobre o domínio.

---

## Comandos Úteis

```bash
# Status
sudo systemctl status fcg3-api fcg3-mcp fcg3-ai

# Logs em tempo real
sudo journalctl -u fcg3-api -f
sudo journalctl -u fcg3-ai -f
sudo journalctl -u fcg3-mcp -f

# Health checks (local)
curl http://127.0.0.1:8000/health
curl http://127.0.0.1:8001/health
curl http://127.0.0.1:8002/health

# Health check (via nginx)
curl https://lab.alphaedtech.org.br/server03/health

# RAM
free -h

# Reiniciar tudo
sudo systemctl restart fcg3-api fcg3-mcp fcg3-ai
```

---

## Arquivos de Referência

| Arquivo | Descrição |
|---------|-----------|
| `scripts/deploy.sh` | Script unificado de setup + gerenciamento |
| `nginx-server03.conf` | Snippet nginx (gerado pelo scripts/deploy.sh) para colar no arquivo do servidor |
| `docs/ssh-setup.md` | Guia de configuração SSH e transferência de arquivos |
| `.env.example` | Template com todas as variáveis necessárias |
| `backup.sh` | Gerado pelo scripts/deploy.sh — backup diário do banco |

---

## Estimativa de RAM (1 GB servidor)

| Processo | RAM estimada |
|----------|-------------|
| PostgreSQL 16 | ~100-150 MB |
| FastAPI (1 worker) | ~80-100 MB |
| MCP Server | ~50-70 MB |
| LangChain (idle) | ~150-200 MB |
| Nginx + sistema | ~85 MB |
| **Total idle** | **~465-605 MB** |

Picos do LangChain (~200 MB extras) são absorvidos pelo swap.

---

## CI/CD — Deploy Automatizado

O deploy acontece automaticamente quando um push é feito na branch `main`. A pipeline usa um **self-hosted GitHub Actions runner** instalado no servidor.

### Como funciona

```
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
           - Health checks
```

### Decisão de Arquitetura

A escolha do self-hosted runner sobre webhook-based deploy está documentada em [adr-cicd-approach.md](adr-cicd-approach.md) com uma comparação detalhada de 20 critérios.

### Pré-requisitos do Runner

- Runner instalado em `/home/grupo3/actions-runner` (systemd service)
- `grupo3` tem sudoers para restart dos serviços FCG3
- Deploy key SSH configurada no GitHub (já existente)

### Verificar Status

```bash
# Status do runner
sudo /home/grupo3/actions-runner/svc.sh status

# Logs do runner
journalctl -u actions.runner.Weym-desafio-fcg3.servidor-fcg3 -f

# Dashboard no GitHub
# https://github.com/Weym/desafio-fcg3/actions
```

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

```bash
ssh grupo3@desafio03
cd /home/grupo3/desafio-fcg3
sudo bash scripts/deploy.sh
```
