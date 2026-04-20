# Phase 3: Business Feature Slices - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-20
**Phase:** 03-business-feature-slices
**Areas discussed:** Infraestrutura compartilhada, Protecao contra IDOR, Calculo do CRA, Modelo de scheduling slots, Lifecycle da matricula, Feature slice ordering

---

## Infraestrutura Compartilhada

### Q1: Quanta infraestrutura compartilhada construir?

| Option | Description | Selected |
|--------|-------------|----------|
| Completa (Recomendado) | Criar em shared/: PaginationParams, paginated response, exception handlers, base service CRUD. Todas as 7 slices reaproveitem. | ✓ |
| Minima | So PaginationParams + exception handlers. Cada slice implementa proprio service. | |
| Agente decide | Agente determina conforme implementa. | |

**User's choice:** Completa (Recomendado)
**Notes:** None

### Q2: Dual-auth dependency pattern

| Option | Description | Selected |
|--------|-------------|----------|
| Dependency unica com fallback (Recomendado) | get_current_user_or_service() tenta JWT primeiro, fallback para X-Service-Token. | ✓ |
| Decorator por endpoint | Cada endpoint MCP recebe decorator separado. | |
| Agente decide | Agente escolhe abordagem mais idiomatica. | |

**User's choice:** Dependency unica com fallback (Recomendado)
**Notes:** None

### Q3: Idioma dos error codes e messages

| Option | Description | Selected |
|--------|-------------|----------|
| Codes ingles, messages portugues (Recomendado) | SCREAMING_SNAKE_CASE ingles + messages PT-BR. | |
| Tudo em portugues | Codes e messages em portugues. | ✓ |
| Agente decide | Seguir docs/api.md. | |

**User's choice:** Tudo em portugues
**Notes:** User wants full Portuguese consistency including error codes.

---

## Protecao contra IDOR

### Q1: Como verificar ownership?

| Option | Description | Selected |
|--------|-------------|----------|
| Service-level check (Recomendado) | Cada service verifica resource.student_id == current_user_id. | |
| Dependency/middleware generica | get_owned_resource(model, id) automatico. | |
| Agente decide | Agente escolhe abordagem mais segura. | ✓ |

**User's choice:** Agente decide
**Notes:** Agent has discretion on implementation approach.

### Q2: IDOR check para requests via MCP (X-Service-Token)

| Option | Description | Selected |
|--------|-------------|----------|
| Mesmo check para ambos (Recomendado) | Defesa em profundidade — same ownership check regardless of auth method. | ✓ |
| Skip check para service token | Confiar no student_id injetado pelo MCP. | |
| Agente decide | Baseado em melhores praticas. | |

**User's choice:** Mesmo check para ambos (Recomendado)
**Notes:** Defense in depth — even MCP requests are validated.

### Q3: Staff access pattern

| Option | Description | Selected |
|--------|-------------|----------|
| Role-based bypass (Recomendado) | Staff bypasses ownership, student has normal check. | ✓ |
| Staff com filtro explicito | Staff must pass student_id explicitly. | |
| Agente decide | Per-endpoint decision. | |

**User's choice:** Role-based bypass (Recomendado)
**Notes:** None

---

## Calculo do CRA

### Q1: Onde calcular CRA?

| Option | Description | Selected |
|--------|-------------|----------|
| Service-level em Python (Recomendado) | Buscar grades + courses, calcular no service. Mais testavel. | ✓ |
| SQL-level via query ou view | CTE ou view materializada no PostgreSQL. | |
| Agente decide | Baseado em complexidade. | |

**User's choice:** Service-level em Python (Recomendado)
**Notes:** None

### Q2: Quais grades incluir no CRA?

| Option | Description | Selected |
|--------|-------------|----------|
| Incluir so com nota final (Recomendado) | Se final_grade IS NOT NULL, inclui. Sem nota final = exclui. | ✓ |
| Usar status do enrollment_course | Verificar enrollment_courses.status para determinar inclusao. | |
| Agente decide | Analisa schema e decide. | |

**User's choice:** Incluir so com nota final (Recomendado)
**Notes:** None

---

## Modelo de Scheduling Slots

### Q1: A quem pertencem os slots?

| Option | Description | Selected |
|--------|-------------|----------|
| Slots pertencem a staff (Recomendado) | Trocar resource_id por staff_id. | |
| Slots pertencem a resources | Manter schema database.md. Resources podem ser staff/salas. | ✓ |
| Slots tem ambos | staff_id + resource_id. | |
| Agente decide | Reconcilia pragmaticamente. | |

**User's choice:** Slots pertencem a resources
**Notes:** Keep the database schema as designed. API adapts the response.

### Q2: Race condition handling para booking

| Option | Description | Selected |
|--------|-------------|----------|
| SELECT FOR UPDATE (Recomendado) | Lock pessimista durante transacao. | ✓ |
| Optimistic locking | Version column, retorna 409 em conflito. | |
| Agente decide | Baseado no volume. | |

**User's choice:** SELECT FOR UPDATE (Recomendado)
**Notes:** None

---

## Lifecycle da Matricula

### Q1: Comportamento do lock (trancamento)

| Option | Description | Selected |
|--------|-------------|----------|
| Lock muda enrollment para locked (Recomendado) | Enrollment inteiro fica locked + todos enrollment_courses. | |
| Lock so nos enrollment_courses | Enrollment continua confirmed, courses individuais locked. | |
| Agente decide | Analisa docs/api.md. | |

**User's choice:** (Free text) Deve ser possivel trancar o semestre inteiro e tambem trancar por disciplina.
**Notes:** Two-level lock: whole enrollment AND individual enrollment_courses.

### Q2: Drop de curso — quando permitido?

| Option | Description | Selected |
|--------|-------------|----------|
| Apenas em draft (Recomendado) | So remove disciplinas em draft. Depois de confirmed, usa lock. | ✓ |
| Em draft e confirmed | Remove mesmo depois de confirmado. | |
| Agente decide | Analisa a spec. | |

**User's choice:** Apenas em draft (Recomendado)
**Notes:** None

### Q3: Erro para enrollment fora do periodo

| Option | Description | Selected |
|--------|-------------|----------|
| 409 Conflict com ENROLLMENT_PERIOD_CLOSED | Conflict porque estado do sistema impede a acao. | ✓ |
| 400 Bad Request com ENROLLMENT_PERIOD_CLOSED | Erro de validacao de regra de negocio. | |
| Agente decide | Segue docs/api.md. | |

**User's choice:** 409 Conflict com ENROLLMENT_PERIOD_CLOSED
**Notes:** Error code in Portuguese: PERIODO_MATRICULA_FECHADO.

---

## Feature Slice Ordering

### Q1: Ordem de implementacao dos 7 plans

| Option | Description | Selected |
|--------|-------------|----------|
| Ordem do roadmap (Recomendado) | 3.1 Students -> 3.2 Courses -> ... -> 3.7 Dashboard. | |
| Shared infra primeiro | Plan 3.0 (paginacao, erros, base CRUD) antes dos 7 plans. | ✓ |
| Agente decide | Baseado em dependencias tecnicas. | |

**User's choice:** Shared infra primeiro
**Notes:** Create Plan 3.0 for shared infrastructure before the 7 feature plans.

---

## Agent's Discretion

- IDOR check implementation pattern (service-level check vs generic dependency)
- Prerequisite validation approach for enrollment
- Base CRUD service class design
- PaginationParams implementation details
- Individual endpoint implementation details

## Deferred Ideas

None — discussion stayed within phase scope.
