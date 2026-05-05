---
phase: quick-260505-jcm-validar-e-corrigir-base-url-de-autentica
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - backend/src/main.py
  - mobile/lib/core/config/env_config.dart
autonomous: true
requirements:
  - QUICK-JCM-AUTH-BASE-URL
must_haves:
  truths:
    - "Flutter web em desenvolvimento chama a API FastAPI em localhost sem usar o host Android-emulator 10.0.2.2."
    - "Chamadas de autenticação do frontend resolvem para endpoints existentes do backend."
    - "Preflight CORS do navegador permite POST/GET de auth a partir do Flutter web local."
  artifacts:
    - path: "mobile/lib/core/config/env_config.dart"
      provides: "Base URL padrão por plataforma para web e mobile/emulador"
      contains: "kIsWeb"
    - path: "backend/src/main.py"
      provides: "Registro de CORS middleware e prefixo /api/v1 para auth"
      contains: "CORSMiddleware"
  key_links:
    - from: "mobile/lib/features/auth/services/auth_service.dart"
      to: "backend/src/features/auth/routes.py"
      via: "Dio baseUrl + '/auth/*' resolves to FastAPI auth routes"
      pattern: "http://localhost:8000/api/v1 + /auth/request-code -> /api/v1/auth/request-code"
    - from: "Flutter web browser"
      to: "backend/src/main.py"
      via: "CORS preflight OPTIONS"
      pattern: "Origin http://localhost:* allowed for dev"
---

<objective>
Validar e corrigir a integração de autenticação entre Flutter web e FastAPI.

Purpose: o login por OTP no Flutter web precisa atingir a URL correta do backend e passar pelo CORS do navegador, sem quebrar o uso mobile/emulador já configurado.
Output: plano de correção para base URL por plataforma, alinhamento do prefixo de auth e CORS local de desenvolvimento.
</objective>

<execution_context>
@.opencode/get-shit-done/workflows/execute-plan.md
@.opencode/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@./AGENTS.md
@backend/src/main.py
@backend/src/routes.py
@backend/src/features/auth/routes.py
@mobile/lib/core/config/env_config.dart
@mobile/lib/features/auth/services/auth_service.dart

<interfaces>
Existing backend routing contracts:
```python
# backend/src/features/auth/routes.py
router = APIRouter(prefix="/auth", tags=["auth"])
@router.post("/request-code", status_code=200)
@router.post("/verify-code", status_code=200)
@router.post("/logout", status_code=200)
@router.get("/me", status_code=200)
@router.post("/refresh", status_code=200)

# backend/src/main.py currently registers auth without /api/v1, while other routers use /api/v1.
app.include_router(auth_router)
```

Existing frontend contract:
```dart
// mobile/lib/core/config/env_config.dart
static const String devApiBaseUrl = 'http://10.0.2.2:8000/api/v1';

// mobile/lib/features/auth/services/auth_service.dart
_client.dio.post('/auth/request-code')
_client.dio.post('/auth/verify-code')
_client.dio.get('/auth/me')
_client.dio.post('/auth/logout')
```

Required resulting URLs:
- Flutter web dev default: `http://localhost:8000/api/v1/auth/request-code`
- Android emulator dev default: `http://10.0.2.2:8000/api/v1/auth/request-code`
- Explicit `--dart-define=API_BASE_URL=...` continues to override defaults.
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Corrigir base URL padrão do Flutter por plataforma</name>
  <files>mobile/lib/core/config/env_config.dart</files>
  <action>Atualize `AppConfig` para manter `String.fromEnvironment('API_BASE_URL')` como override explícito e usar default por plataforma quando o define vier vazio: `http://localhost:8000/api/v1` para Flutter web e `http://10.0.2.2:8000/api/v1` para mobile/emulador. Use `package:flutter/foundation.dart` e `kIsWeb`; não altere `auth_service.dart`, porque seus paths relativos `/auth/*` estão corretos quando o backend expõe auth sob `/api/v1`.</action>
  <verify>
    <automated>cd mobile; flutter analyze lib/core/config/env_config.dart lib/features/auth/services/auth_service.dart</automated>
  </verify>
  <done>`AppConfig.apiBaseUrl` retorna localhost no web sem `--dart-define`, retorna 10.0.2.2 fora do web sem `--dart-define`, e respeita `API_BASE_URL` quando informado.</done>
</task>

<task type="auto">
  <name>Task 2: Alinhar prefixo de auth e habilitar CORS local no FastAPI</name>
  <files>backend/src/main.py</files>
  <action>Em `backend/src/main.py`, importe `CORSMiddleware` de `fastapi.middleware.cors`, adicione o middleware após a criação de `app` e antes dos routers, permitindo origens locais de desenvolvimento do Flutter web: `http://localhost`, `http://localhost:*`, `http://127.0.0.1`, `http://127.0.0.1:*` se a versão Starlette aceitar regex via `allow_origin_regex`, ou liste as portas locais usadas pelo projeto (`3000`, `5000`, `8080`, `5173`) junto com localhost sem porta. Use `allow_credentials=True`, `allow_methods=["*"]`, `allow_headers=["*"]`. Também altere `app.include_router(auth_router)` para `app.include_router(auth_router, prefix="/api/v1")`, alinhando o backend ao `apiBaseUrl` existente do frontend. Não mova nem reescreva os handlers de auth.</action>
  <verify>
    <automated>$env:PYTHONPATH='backend'; python -c "from src.main import app; paths=sorted(r.path for r in app.routes); assert '/api/v1/auth/request-code' in paths; assert '/auth/request-code' not in paths; assert any(m.cls.__name__ == 'CORSMiddleware' for m in app.user_middleware); print('auth prefix and CORS ok')"</automated>
  </verify>
  <done>FastAPI registra auth em `/api/v1/auth/*`, não deixa rota legacy `/auth/*` ativa, e possui CORS middleware para origens locais de desenvolvimento web.</done>
</task>

<task type="auto">
  <name>Task 3: Verificar o fluxo de integração auth web</name>
  <files>backend/src/main.py, mobile/lib/core/config/env_config.dart, mobile/lib/features/auth/services/auth_service.dart</files>
  <action>Execute verificações finais sem criar novos arquivos: confirme por introspecção FastAPI que as rotas de auth existem sob `/api/v1`; confirme que `auth_service.dart` segue usando paths relativos `/auth/*`; e, se o backend estiver rodando localmente, teste o preflight CORS com `OPTIONS /api/v1/auth/request-code` usando origem `http://localhost:8080`. Não adicionar fallbacks hardcoded no serviço de auth e não inserir tokens ou segredos em código.</action>
  <verify>
    <automated>$env:PYTHONPATH='backend'; python -c "from src.main import app; assert any(r.path == '/api/v1/auth/verify-code' for r in app.routes); print('route verify ok')"</automated>
    <automated>cd mobile; flutter analyze lib/core/config/env_config.dart lib/features/auth/services/auth_service.dart</automated>
  </verify>
  <done>O executor consegue demonstrar, via comandos automatizados, que Flutter web montará URLs `/api/v1/auth/*`, o backend registra essas rotas, e CORS está configurado para desenvolvimento local.</done>
</task>

</tasks>

<threat_model>

## Trust Boundaries

| Boundary | Description |
| --- | --- |
| Flutter web browser → FastAPI | Browser sends untrusted auth requests and CORS preflight to backend. |
| Frontend config → backend routes | Client-side base URL/path composition must not route auth traffic to wrong origin or endpoint. |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
| --- | --- | --- | --- | --- |
| T-JCM-01 | Spoofing | CORS in `backend/src/main.py` | mitigate | Allow only localhost/127.0.0.1 development origins; do not use wildcard origins with credentials. |
| T-JCM-02 | Information Disclosure | `mobile/lib/core/config/env_config.dart` | mitigate | Keep only public API base URLs in Dart config; do not add tokens, OTP values, or secrets. |
| T-JCM-03 | Tampering | Auth URL composition | mitigate | Use a single `/api/v1` base URL plus relative `/auth/*` paths; avoid duplicate hardcoded full endpoint strings. |

</threat_model>

<verification>
Run both automated verification commands from the tasks. If the backend server is already running, additionally verify preflight manually from a shell:

```powershell
Invoke-WebRequest -Method OPTIONS "http://localhost:8000/api/v1/auth/request-code" -Headers @{ Origin = "http://localhost:8080"; "Access-Control-Request-Method" = "POST" }
```

Expected: response includes `Access-Control-Allow-Origin` for the localhost origin and allows `POST`.
</verification>

<success_criteria>
- Flutter web default no longer uses `10.0.2.2`.
- Auth endpoints called by `AuthService` exist at `/api/v1/auth/*` in FastAPI.
- Browser CORS preflight for local Flutter web development succeeds.
- No source code contains service tokens or new secrets.
</success_criteria>

<output>
After completion, create `.planning/quick/260505-jcm-validar-e-corrigir-base-url-de-autentica/260505-jcm-SUMMARY.md`.
</output>
