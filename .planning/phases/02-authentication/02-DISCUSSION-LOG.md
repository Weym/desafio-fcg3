# Phase 2: Authentication - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-20
**Phase:** 02-authentication
**Areas discussed:** Tempo de vida do JWT, Fluxo de registro de usuario, Politica de multi-sessao, Rate limiting no OTP, JWT payload contents, Refresh token storage e endpoint

---

## Tempo de vida do JWT

| Option | Description | Selected |
|--------|-------------|----------|
| 24 horas | Equilibrio seguranca/UX para app academico. Re-autentica uma vez por dia. Sem refresh token. | |
| 7 dias | Login semanal. Menos friccao, mas janela maior se token comprometido. | |
| 1 hora + refresh token | Access token curto com refresh token separado (30 dias). Mais complexo mas mais seguro. | ✓ |

**User's choice:** 1 hora + refresh token
**Notes:** None

### Follow-up: Refresh token duration

| Option | Description | Selected |
|--------|-------------|----------|
| 7 dias | Re-login semanal via OTP | |
| 30 dias | Re-login mensal. Menos friccao. | ✓ |
| 90 dias | Login trimestral. Conveniente mas risco maior. | |

**User's choice:** 30 dias

### Follow-up: Refresh token rotation

| Option | Description | Selected |
|--------|-------------|----------|
| Sim, rotacionar a cada uso | Cada refresh gera novo refresh token. Antigo invalidado. Padrao de seguranca recomendado. | ✓ |
| Nao, refresh token fixo | Mesmo refresh token ate expirar. Simples mas menos seguro. | |

**User's choice:** Sim, rotacionar a cada uso

### Follow-up: JWT refresh behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Re-autentica via OTP | Sem refresh token. Token expirou = novo OTP. | |
| Refresh token silencioso | App renova automaticamente com refresh token. | ✓ |

**User's choice:** Refresh token silencioso

### Follow-up: JWT signing algorithm

| Option | Description | Selected |
|--------|-------------|----------|
| HS256 com secret key | Algoritmo simetrico. Uma unica chave (JWT_SECRET env var). Padrao para MVP. | ✓ |
| RS256 com par de chaves | Algoritmo assimetrico. Necessario se multiplos servicos validassem JWT independentemente. | |
| Voce decide | Agente escolhe. | |

**User's choice:** HS256 com secret key

---

## Fluxo de registro de usuario

| Option | Description | Selected |
|--------|-------------|----------|
| Apenas cadastrados | So emails existentes em students ou staff recebem OTP. Staff cria aluno primeiro. | ✓ |
| Qualquer email (auto-registro) | Qualquer pessoa pode solicitar OTP. Se email nao existe, cria registro basico. | |

**User's choice:** Apenas cadastrados

### Follow-up: Response for unregistered email

| Option | Description | Selected |
|--------|-------------|----------|
| Erro generico | Responde "Codigo enviado" mesmo que email nao exista. Previne enumeracao. | ✓ |
| Erro explicito | Responde 404 "Email nao encontrado". Permite enumeracao. | |

**User's choice:** Erro generico

### Follow-up: User lookup mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Busca em students + staff por email | Endpoint busca email em ambas tabelas. Se encontrar, envia OTP. | ✓ |
| Tabela unificada de usuarios | Nova tabela 'users' para autenticacao. Adiciona abstracao nao prevista no schema. | |

**User's choice:** Busca em students + staff por email

---

## Politica de multi-sessao

| Option | Description | Selected |
|--------|-------------|----------|
| Multiplas sessoes permitidas | Uma sessao por plataforma (app + whatsapp coexistem). Login no app nao revoga WhatsApp. | ✓ |
| Sessao unica por plataforma | Novo login no app revoga sessao anterior do app. WhatsApp continua. | |
| Sessao unica global | Qualquer novo login revoga TODAS as sessoes. Maximo 1 sessao total. | |

**User's choice:** Multiplas sessoes permitidas

### Follow-up: Logout scope

| Option | Description | Selected |
|--------|-------------|----------|
| Apenas sessao atual | POST /auth/logout revoga apenas o jti do token enviado. Outras sessoes continuam. | ✓ |
| Todas as sessoes | POST /auth/logout revoga TODAS as sessoes do usuario. | |
| Opcao para ambos | Dois endpoints: /auth/logout (atual) e /auth/logout-all (todas). | |

**User's choice:** Apenas sessao atual

---

## Rate limiting no OTP

| Option | Description | Selected |
|--------|-------------|----------|
| In-memory | Dicionario em memoria (slowapi). Simples, single-instance. Reseta se container reiniciar. | ✓ |
| Banco de dados | Contar registros recentes em verification_codes. Mais persistente, mais queries. | |
| Voce decide | Agente escolhe. | |

**User's choice:** In-memory

### Follow-up: OTP request limit per email

| Option | Description | Selected |
|--------|-------------|----------|
| 5 req / 15 min | Previne abuso sem bloquear uso legit (3 tentativas + 2 reenvios cabe no limite). | ✓ |
| 3 req / 10 min | Mais restritivo. Pode bloquear usuario legit. | |
| 10 req / 30 min | Mais permissivo. Janela maior para abuso. | |

**User's choice:** 5 req / 15 min

### Follow-up: Rate limit by IP

| Option | Description | Selected |
|--------|-------------|----------|
| Sim, ambos (email + IP) | Per-email (5/15min) + per-IP (20/15min). Previne enumeracao. | ✓ |
| Apenas por email | Mais simples. Resposta generica ja protege contra enumeracao. | |

**User's choice:** Sim, ambos

---

## JWT payload contents

| Option | Description | Selected |
|--------|-------------|----------|
| Minimo: sub + role + jti | JWT leve. get_current_user faz SELECT para dados extras. Dados sempre frescos. | |
| Enriquecido: sub + role + jti + name + email | Dados basicos no token. /auth/me pode extrair do JWT sem query. Mas dados ficam defasados se admin atualizar. | ✓ |
| Voce decide | Agente escolhe. | |

**User's choice:** Enriquecido: sub + role + jti + name + email

### Follow-up: JWT subject field

| Option | Description | Selected |
|--------|-------------|----------|
| user_id (UUID) direto | sub = UUID do student ou staff. Simples. | ✓ |
| user_type:user_id composto | sub = 'student:uuid'. Permite saber tipo sem claim extra. Formato nao-padrao. | |

**User's choice:** user_id (UUID) direto

---

## Refresh token storage e endpoint

| Option | Description | Selected |
|--------|-------------|----------|
| Mesma tabela sessions com tipo | Adicionar token_type ou refresh_jti na tabela sessions. Schema simples. | ✓ |
| Tabela separada refresh_tokens | Nova tabela dedicada. Separacao clara, mas tabela extra. | |
| Voce decide | Agente escolhe. | |

**User's choice:** Mesma tabela sessions com tipo

### Follow-up: Refresh endpoint route

| Option | Description | Selected |
|--------|-------------|----------|
| POST /auth/refresh | Endpoint dedicado. Recebe refresh token, retorna novo access + refresh. | ✓ |
| POST /auth/verify-code reutilizado | Mesmo endpoint aceita refresh token como alternativa. Menos REST-like. | |

**User's choice:** POST /auth/refresh

---

## Agent's Discretion

- OTP code generation approach (random vs cryptographic) and storage (hashed vs plaintext)
- Exact slowapi configuration and cache backend
- How POST /auth/refresh receives the refresh token (body, cookie, or header)
- SMS channel support (email-only in MVP, sms as future stub)
- X-Service-Token middleware implementation details

## Deferred Ideas

- SMS OTP channel — api.md lists sms channel but no provider specified
- POST /auth/logout-all — global logout not needed for MVP
- Redis-backed rate limiting — for multi-instance post-MVP
