# Codebase Structure

**Analysis Date:** 2026-04-15

## Directory Layout

```
desafio-fcg3/                   # Monorepo root
├── backend/                    # Python FastAPI backend service
│   └── src/
│       ├── features/           # Vertical slices — one dir per feature
│       │   ├── auth/           # Auth slice (scaffolded, empty)
│       │   └── enrollment/     # Enrollment slice (scaffolded, empty)
│       ├── infrastructure/     # DB connections, external service clients (empty)
│       ├── shared/             # Shared utilities, middleware, base types (empty)
│       └── main.py             # FastAPI application entry point (empty)
│
├── mobile/                     # Flutter mobile application
│   ├── lib/
│   │   ├── main.dart           # Flutter app entry point
│   │   ├── screens/            # Screen-level widgets (empty)
│   │   ├── components/         # Reusable UI components (empty)
│   │   ├── core/               # Core config, theme, routing (empty)
│   │   └── shared/             # Shared utilities and models (empty)
│   ├── android/                # Android platform config
│   ├── ios/                    # iOS platform config
│   ├── linux/                  # Linux desktop platform config
│   ├── macos/                  # macOS platform config
│   ├── windows/                # Windows desktop platform config
│   ├── web/                    # Web platform config
│   ├── test/                   # Flutter tests
│   └── pubspec.yaml            # Flutter dependencies
│
├── docs/                       # Planning and architecture documentation
│   ├── architecture.md         # C4 diagrams, flows, tech stack decisions
│   ├── api.md                  # Full REST API endpoint specifications
│   ├── database.md             # Database schema (ERD, tables, indexes)
│   ├── app.md                  # Flutter app features and screens
│   ├── chatbot.md              # LangChain agent architecture and WhatsApp flows
│   ├── mcp.md                  # MCP server protocol, tools, logging behavior
│   ├── changelog_docs.md       # Documentation change log
│   └── backup/                 # Archived older doc versions
│
├── .planning/                  # GSD planning workspace
│   └── codebase/               # Codebase analysis documents (this directory)
│
├── docker-compose.yml          # Multi-service Docker orchestration (empty)
├── .fvmrc                      # Flutter Version Manager version pin
└── README.md                   # Project overview and run instructions
```

---

## Directory Purposes

**`backend/src/features/`:**
- Purpose: Vertical slices — each feature is a self-contained unit
- Contains: Per-feature subdirectories, each with `controllers/`, `services/`, `routes.py`
- Currently: Both feature directories contain only `.gitkeep` — scaffolding only

**`backend/src/infrastructure/`:**
- Purpose: Database connection setup, external service clients (WhatsApp API, FCM, etc.)
- Contains: Planned — DB session factory, HTTP clients for external APIs
- Currently: Empty (`.gitkeep` only)

**`backend/src/shared/`:**
- Purpose: Cross-feature reusable code — middleware, base schemas, error handlers
- Contains: Planned — JWT validation middleware, Service Token middleware, pagination helpers, error response factories
- Currently: Empty (`.gitkeep` only)

**`mobile/lib/screens/`:**
- Purpose: Full-screen Flutter widgets mapped to app navigation routes
- Planned screens: Login, Home, Chat History, Chat Detail, Action Tracker, Documents
- Currently: Empty (`.gitkeep` only)

**`mobile/lib/components/`:**
- Purpose: Reusable UI widgets used across multiple screens
- Currently: Empty (`.gitkeep` only)

**`mobile/lib/core/`:**
- Purpose: App-wide configuration — theme, routing, HTTP client setup, environment config
- Currently: Empty (`.gitkeep` only)

**`mobile/lib/shared/`:**
- Purpose: Shared data models, DTOs, API response types, utility functions
- Currently: Empty (`.gitkeep` only)

**`docs/`:**
- Purpose: Comprehensive planning documentation — treat as source of truth for design decisions
- Generated: No — hand-authored
- Committed: Yes

---

## Key File Locations

**Entry Points:**
- `backend/src/main.py`: FastAPI application factory and server startup
- `mobile/lib/main.dart`: Flutter app root widget and entry point

**Configuration:**
- `docker-compose.yml`: Docker Compose service definitions (currently empty)
- `.fvmrc`: Flutter version pin managed by FVM

**Core Documentation (read before implementing):**
- `docs/architecture.md`: System C4 diagrams, async flows, Docker topology
- `docs/api.md`: All REST endpoints with request/response shapes
- `docs/database.md`: Full schema with table definitions and indexes
- `docs/chatbot.md`: LangChain agent design, RAG thresholds, WhatsApp integration
- `docs/mcp.md`: MCP protocol, tool schemas, IDOR prevention pattern

---

## Naming Conventions

**Backend files (planned, based on README and docs):**
- Feature routes: `routes.py` per feature slice
- Controllers: `[resource]_controller.py` or directory `controllers/`
- Services: `[resource]_service.py` or directory `services/`
- Infrastructure: `[service]_client.py` (e.g., `whatsapp_client.py`, `fcm_client.py`)

**Mobile files (planned, based on docs):**
- Screens: `[feature]_screen.dart` (e.g., `login_screen.dart`, `home_screen.dart`)
- Components: `[name]_widget.dart` or `[name]_card.dart`
- Models: `[entity].dart` (e.g., `student.dart`, `enrollment.dart`)

**Database (established in `docs/database.md`):**
- Tables: `snake_case` plural (e.g., `students`, `enrollment_courses`, `mcp_action_logs`)
- Foreign keys: `[referenced_table_singular]_id` (e.g., `student_id`, `enrollment_period_id`)
- Status columns: `VARCHAR(20)` with lowercase values (e.g., `'draft'`, `'confirmed'`, `'active'`)

---

## Where to Add New Code

**New backend feature slice:**
- Create directory: `backend/src/features/[feature_name]/`
- Add: `controllers/`, `services/`, `routes.py`
- Register routes in: `backend/src/routes.py`

**New API endpoint:**
- Implement in the relevant feature slice under `backend/src/features/[feature]/`
- Follow error shape from `docs/api.md`: `{"error": {"code": "...", "message": "...", "details": [...]}}`
- If accessible by MCP, add `X-Service-Token` middleware support

**New MCP tool:**
- Add tool schema to `mcp_server/` (planned directory)
- Omit `student_id` from schema — inject from session context inside MCP handler
- Map tool to existing API endpoint per `docs/api.md` MCP mapping table

**New Flutter screen:**
- Create: `mobile/lib/screens/[feature]_screen.dart`
- Register route in: `mobile/lib/core/` router config (once created)
- Shared widgets go in: `mobile/lib/components/`
- Data models go in: `mobile/lib/shared/`

**New database table:**
- Define schema in: `docs/database.md` first
- Add migration SQL to init script (once `backend/src/infrastructure/` is populated)
- Add relevant index following patterns in `docs/database.md`

**Shared backend utilities:**
- Place in: `backend/src/shared/`
- Examples: auth middleware, pagination helpers, standardized error factory

**External service clients:**
- Place in: `backend/src/infrastructure/`
- Examples: WhatsApp API client, FCM client, PostgreSQL session factory

---

## Special Directories

**`.planning/codebase/`:**
- Purpose: GSD codebase analysis documents for AI-assisted development
- Generated: Yes (by GSD map-codebase command)
- Committed: Yes

**`docs/backup/`:**
- Purpose: Archived older versions of planning documents
- Generated: No
- Committed: Yes

**`mobile/build/`:**
- Purpose: Flutter build artifacts
- Generated: Yes
- Committed: No (in `.gitignore`)

**`mobile/.dart_tool/`:**
- Purpose: Dart tooling cache
- Generated: Yes
- Committed: Partially (`package_config.json` may be committed)

**`.fvm/versions/`:**
- Purpose: Flutter SDK versions managed by FVM
- Generated: Yes
- Committed: No

---

## Implementation Status

All source directories are currently scaffolded with `.gitkeep` files only. The project is in planning phase. The `docs/` directory is the primary implementation reference — all feature design decisions, API contracts, and database schemas are fully documented there before any code is written.

| Component | Status |
|-----------|--------|
| `backend/src/features/auth/` | Scaffolded — empty |
| `backend/src/features/enrollment/` | Scaffolded — empty |
| `backend/src/infrastructure/` | Scaffolded — empty |
| `backend/src/shared/` | Scaffolded — empty |
| `backend/src/main.py` | Scaffolded — empty |
| `mobile/lib/` (all subdirs) | Scaffolded — empty |
| `mobile/lib/main.dart` | Flutter default counter app — not yet customized |
| `ai_service/` | Not yet created |
| `mcp_server/` | Not yet created |
| `docker-compose.yml` | Created but empty |

---

*Structure analysis: 2026-04-15*
