---
phase: quick-260505-jcm-validar-e-corrigir-base-url-de-autentica
plan: 01
subsystem: auth-integration
tags:
  - flutter-web
  - fastapi
  - auth
  - cors
requirements:
  - QUICK-JCM-AUTH-BASE-URL
dependency_graph:
  requires:
    - mobile/lib/features/auth/services/auth_service.dart
    - backend/src/features/auth/routes.py
  provides:
    - Platform-aware Flutter API base URL
    - /api/v1 auth route registration
    - Local development CORS preflight support
  affects:
    - mobile/lib/core/config/env_config.dart
    - backend/src/main.py
tech_stack:
  added:
    - fastapi.middleware.cors.CORSMiddleware
    - package:flutter/foundation.dart kIsWeb
  patterns:
    - Explicit API_BASE_URL override before platform default
    - Credentialed CORS constrained to localhost and 127.0.0.1 origins
key_files:
  created:
    - .planning/quick/260505-jcm-validar-e-corrigir-base-url-de-autentica/260505-jcm-SUMMARY.md
  modified:
    - mobile/lib/core/config/env_config.dart
    - backend/src/main.py
decisions:
  - Use kIsWeb in AppConfig so Flutter web defaults to localhost while mobile/emulator keeps 10.0.2.2.
  - Mount auth_router under /api/v1 to match the existing Dio baseUrl plus relative /auth/* service paths.
  - Use allow_origin_regex for local development origins instead of wildcard CORS with credentials.
metrics:
  started_at: 2026-05-05T16:58:27Z
  completed_at: 2026-05-05T17:01:02Z
  duration: 2m35s
  tasks_completed: 3
  files_modified: 2
---

# Quick Task 260505-jcm: Validar e corrigir base URL de autenticação Summary

Flutter web auth now resolves to FastAPI `/api/v1/auth/*` on localhost, while mobile/emulator defaults and explicit `API_BASE_URL` overrides continue to work.

## Completed Tasks

| Task | Name | Commit | Files |
| --- | --- | --- | --- |
| 1 | Corrigir base URL padrão do Flutter por plataforma | 153e990 | `mobile/lib/core/config/env_config.dart` |
| 2 | Alinhar prefixo de auth e habilitar CORS local no FastAPI | 4e1ca3d | `backend/src/main.py` |
| 3 | Verificar o fluxo de integração auth web | No code commit | Verification only |

## What Changed

- `AppConfig.apiBaseUrl` now uses an explicit `API_BASE_URL` dart-define when present, otherwise selects `http://localhost:8000/api/v1` for Flutter web and `http://10.0.2.2:8000/api/v1` for non-web builds.
- FastAPI now registers auth routes under `/api/v1/auth/*`, removing the active legacy `/auth/*` route registration.
- FastAPI now has credentialed CORS middleware limited to local development origins matching `localhost` or `127.0.0.1` with optional ports.
- `AuthService` remains unchanged and continues using relative `/auth/*` paths, which compose correctly with the `/api/v1` base URL.

## Verification Commands Run

```powershell
flutter analyze "lib/core/config/env_config.dart" "lib/features/auth/services/auth_service.dart"
```

Result: `No issues found!`

```powershell
$env:PYTHONPATH='backend'; python -c "from src.main import app; paths=sorted(r.path for r in app.routes); assert '/api/v1/auth/request-code' in paths; assert '/auth/request-code' not in paths; assert any(m.cls.__name__ == 'CORSMiddleware' for m in app.user_middleware); print('auth prefix and CORS ok')"
```

Result: `auth prefix and CORS ok`

```powershell
$env:PYTHONPATH='backend'; python -c "from src.main import app; assert any(r.path == '/api/v1/auth/verify-code' for r in app.routes); print('route verify ok')"
```

Result: `route verify ok`

```powershell
$env:PYTHONPATH='backend'; python -c "from fastapi.testclient import TestClient; from src.main import app; response = TestClient(app).options('/api/v1/auth/request-code', headers={'Origin': 'http://localhost:8080', 'Access-Control-Request-Method': 'POST'}); assert response.status_code == 200, response.status_code; assert response.headers.get('access-control-allow-origin') == 'http://localhost:8080'; assert 'POST' in response.headers.get('access-control-allow-methods', ''); print('cors preflight ok')"
```

Result: `cors preflight ok`

## Deviations from Plan

None - plan executed exactly as written.

## Auth Gates

None.

## Known Stubs

None. The existing `placeholder env values` comment in `backend/src/main.py` predates this task and is not a UI/data stub introduced by these changes.

## Threat Flags

None. The CORS and auth route trust surfaces were already identified in the plan threat model and mitigated.

## Self-Check: PASSED

- Summary created at `.planning/quick/260505-jcm-validar-e-corrigir-base-url-de-autentica/260505-jcm-SUMMARY.md`.
- Code commits found: `153e990`, `4e1ca3d`.
- Unrelated pre-existing dirty files were not staged or committed.
