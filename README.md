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

4. Confira a saude dos servicos:

```bash
docker compose ps
curl http://localhost:8000/health
curl http://localhost:8001/health
curl http://localhost:8002/health
```

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

- `backend/` - API FastAPI, Alembic, seed e modelos
- `ai_service/` - servico de IA
- `mcp_server/` - servidor MCP
- `mobile/` - app Flutter
- `.planning/` - artefatos do workflow GSD

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
