# Desafio FCG3

Plataforma academica com backend em FastAPI, servico de IA, servidor MCP e app Flutter.

## Requisitos

- Docker e Docker Compose
- Python 3.12
- Flutter 3.41.6 (opcional para o app `mobile/`)

## Como rodar

1. Copie o arquivo de ambiente:

```bash
cp .env.example .env
```

2. Preencha os valores do `.env`.

Observacoes:

- `JWT_SECRET` deve ser unico por ambiente
- `MCP_SERVICE_TOKEN` deve ser unico por ambiente
- nunca versione o `.env`

3. Suba a stack:

```bash
docker compose up --build -d
```

O comando destacado acima termina antes dos healthchecks dos servicos HTTP concluirem. Trate essa saida destacada como um estado intermediario de startup, nao como veredito final de falha.

4. Confira a saude dos servicos:

```bash
docker compose ps
curl http://localhost:8000/health
curl http://localhost:8001/health
curl http://localhost:8002/health
```

Se `docker compose ps` ainda mostrar servicos em estado de transicao (`created`, `starting` ou equivalente), aguarde alguns segundos e rode o comando novamente por ate 60 segundos antes de declarar falha no cold start. Considere a stack realmente falha apenas se esse intervalo terminar sem os servicos estabilizarem ou se o `curl http://localhost:8000/health` nao responder com sucesso.

## Banco de dados

Aplicar migrations:

```bash
docker compose exec fastapi-app alembic upgrade head
```

Popular dados de desenvolvimento:

```bash
docker compose exec fastapi-app python -m scripts.seed
```

## Servicos locais

- API FastAPI: `http://localhost:8000`
- AI service: `http://localhost:8001`
- MCP server: `http://localhost:8002`
- PostgreSQL: `localhost:5432`

## Estrutura

| Diretorio     | Conteudo                                         |
| ------------- | ------------------------------------------------ |
| `backend/`    | API FastAPI, Alembic, seed e modelos             |
| `ai_service/` | Servico de IA (LangChain)                        |
| `mcp_server/` | Servidor MCP                                     |
| `mobile/`     | App Flutter                                      |
| `scripts/`    | Scripts de deploy e operacao                     |
| `docs/`       | Documentacao completa ([indice](docs/README.md)) |

## Deploy

O deploy em producao usa CI/CD com GitHub Actions (self-hosted runner). Ver [docs/deploy.md](docs/deploy.md) e [docs/cicd-pipeline-plan.md](docs/cicd-pipeline-plan.md).

## Documentacao

Toda documentacao detalhada esta em [`docs/`](docs/README.md) e em [`.planning/`](.planning/ROADMAP.md).

## Comandos uteis

Parar a stack:

```bash
docker compose down
```

Ver logs da API:

```bash
docker compose logs -f fastapi-app
```

O app Flutter tem instrucoes proprias em `mobile/README.md`.
