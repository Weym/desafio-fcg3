---
phase: 12-frontend-backend-integration
plan: 01
subsystem: infrastructure
tags: [docker, flutter-web, seed, devops]
dependency_graph:
  requires: []
  provides: [full-stack-docker-compose, flutter-web-container, conditional-seed]
  affects: [docker-compose.yml, mobile/Dockerfile, backend/scripts/seed.py, .env.example]
tech_stack:
  added: [nginx:alpine, ghcr.io/cirruslabs/flutter:3.41.6]
  patterns: [multi-stage-docker-build, conditional-seed, spa-nginx-routing]
key_files:
  created: [mobile/Dockerfile, mobile/nginx.conf]
  modified: [docker-compose.yml, backend/scripts/seed.py, .env.example]
decisions:
  - "Flutter web served via nginx:alpine with SPA try_files routing"
  - "Seed runs inline in fastapi-app command (not separate service) for first-boot simplicity"
  - "Conditional seed checks students table count — zero means first boot"
  - "--force flag preserves destructive re-seed capability for development"
metrics:
  duration: ~3min
  completed: "2026-05-06"
  tasks_completed: 2
  tasks_total: 2
---

# Phase 12 Plan 01: Docker Compose Full Stack with Flutter Web Summary

**One-liner:** Full Docker Compose stack with 5 services (flutter-web via nginx, conditional seed on first boot, DEV_MASTER_OTP documented)

## Tasks Completed

| # | Task | Commit | Key Files |
|---|------|--------|-----------|
| 1 | Add Flutter web service to Docker Compose | 374526c | mobile/Dockerfile, mobile/nginx.conf, docker-compose.yml |
| 2 | Implement conditional seed + document .env | ecee965 | backend/scripts/seed.py, .env.example, docker-compose.yml |

## Implementation Details

### Task 1: Flutter Web Docker Service

Created a multi-stage Dockerfile for the Flutter web app:
- **Stage 1 (builder):** Uses `ghcr.io/cirruslabs/flutter:3.41.6`, runs `flutter pub get` + `flutter build web` with `--dart-define=API_BASE_URL=http://localhost:8000/api/v1`
- **Stage 2 (serve):** Uses `nginx:alpine`, copies built assets, applies custom nginx.conf with SPA routing

Added `flutter-web` service to docker-compose.yml:
- Port mapping: 3000:80 (developer accesses at localhost:3000)
- Depends on fastapi-app healthy (ensures API is ready before frontend serves)
- Connected to app-network only (browser makes direct requests to localhost:8000 via CORS)
- Healthcheck with 60s start_period (accounts for Flutter build time in CI)

### Task 2: Conditional Seed + Environment Documentation

Modified `backend/scripts/seed.py`:
- Added `check_data_exists()` — queries `SELECT COUNT(*) FROM students`
- If count > 0 and no `--force` flag, prints skip message and returns cleanly
- Added `argparse` with `--force` flag for explicit destructive re-seed
- First boot: seed runs automatically (students table empty)
- Subsequent boots: seed exits immediately (data already present)

Updated `docker-compose.yml` fastapi-app command:
- `bash -c "python -m scripts.seed && exec uvicorn src.main:app --host 0.0.0.0 --port 8000 --reload"`
- `exec` ensures uvicorn is PID 1 for proper signal handling

Updated `.env.example`:
- Added `DEV ONLY` section with `DEV_MASTER_OTP=000000`
- Clear production warning: "MUST be unset in production"

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED

All 5 files verified present. Both commit hashes (374526c, ecee965) confirmed in git log.
