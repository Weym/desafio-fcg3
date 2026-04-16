# Technology Stack

**Analysis Date:** 2026-04-15

## Languages

**Primary:**
- Python 3.12 - Backend API (FastAPI), AI/LangChain service, MCP server
- Dart 3.11.4+ - Flutter mobile/web frontend

**Secondary:**
- SQL - PostgreSQL queries and schema management (pgvector HNSW indexes, pg_cron planned)

## Runtime

**Environment:**
- Python 3.12 (FastAPI, LangChain service, MCP server)
- Dart SDK ^3.11.4 (Flutter 3.41.6)

**Package Manager:**
- Python: pip (requirements.txt per service — file not yet present, structure planned per `docs/architecture.md`)
- Flutter/Dart: pub (lockfile: `mobile/pubspec.lock` — Flutter managed)
- Lockfile: present for Flutter; Python lockfile not yet present (early project state)

## Frameworks

**Core:**
- FastAPI (Python) - Central REST API at `:8000`, async webhook processing via `asyncio.create_task`
- LangChain - AI orchestration service at `:8001`, ReAct agent with `ConversationBufferWindowMemory(k=20)`
- MCP (Model Context Protocol) - Tool calling + logging server at `:8002`, stdio/SSE transport
- Flutter 3.41.6 - Cross-platform mobile/web app (iOS, Android, Linux, Web, macOS, Windows)

**Testing:**
- `flutter_test` SDK - Flutter unit/widget tests (`mobile/test/`)
- `flutter_lints` ^6.0.0 - Dart linting rules

**Build/Dev:**
- Docker Compose - Multi-container orchestration (`docker-compose.yml` present, empty — not yet written)
- FVM (Flutter Version Manager) - Flutter version pinning via `.fvmrc` (`flutter: 3.41.6`)

## Key Dependencies

**Critical:**
- `langchain` - LangChain agent framework for ReAct pattern, ConversationBufferWindowMemory, BaseCallbackHandler
- `pgvector` extension for PostgreSQL - Vector similarity search (HNSW index, cosine ops, `vector(1536)`)
- `httpx` - Async HTTP client used in MCP server for internal API calls with retry logic
- `cupertino_icons` ^1.0.8 - Flutter iOS-style icons
- `flutter_secure_storage` (planned) - JWT token storage on Flutter client

**Infrastructure:**
- `postgres:16 + pgvector/pgvector:pg16` - Single database image with PGVector extension pre-installed
- `python:3.12` Docker base image - Used for all three backend services (fastapi-app, langchain-service, mcp-server)

## Configuration

**Environment:**
- Configured via environment variables (no `.env` files present yet)
- Critical vars: `MCP_SERVICE_TOKEN` (internal service auth), `WHATSAPP_TOKEN`, `DATABASE_URL`, embedding model config
- `MCP_SERVICE_TOKEN` is never committed to source — env-only per `docs/mcp.md`
- `.gitignore` files present on root `.gitignore`

**Build:**
- `.fvmrc` — Flutter version pinning (`flutter: 3.41.6`)
- `mobile/pubspec.yaml` — Flutter package manifest
- Docker Compose at `docker-compose.yml` (currently empty, to be written)

## Platform Requirements

**Development:**
- Python 3.12+
- Flutter 3.41.6 / Dart SDK ^3.11.4
- Docker + Docker Compose
- FVM for Flutter version management
- PostgreSQL 16 with pgvector extension

**Production:**
- Docker containerization
- 4 containers: `fastapi-app:8000`, `langchain-service:8001`, `mcp-server:8002`, `postgres:5432`
- Networks: `app-network` (API + AI services) and `data-network` (postgres)
- Embedding model: `text-embedding-3-small` (OpenAI) — vector dimension 1536

---

*Stack analysis: 2026-04-15*
