# Kanban Board — Desafio FCG3

**Projeto:** Plataforma Academica com Chatbot WhatsApp  
**Sprint:** Sprint 4 — Projeto Concluido (07/05/2026)  
**Ultima atualizacao:** 2026-05-11 (projeto concluido)  

---

## Legenda

| Coluna | Significado | WIP Limit |
|--------|-------------|-----------|
| **Backlog** | Tarefa identificada, ainda nao iniciada | Sem limite |
| **To Do** | Comprometida na sprint, pronta para iniciar | 10 |
| **In Progress** | Alguem esta trabalhando ativamente | 6 (1 por membro) |
| **In Review** | Aguardando validacao/teste por outro membro | 4 |
| **Done** | Atende todos os criterios da DoD | Sem limite |
| **Blocked** | Impedimento externo, nao pode avancar | — |

---

## Board Estado Atual (07/05/2026 — PROJETO CONCLUIDO)

### DONE (Sprint 1 + Sprint 2 — completas)

| ID | Tarefa | Responsavel | Concluida |
|----|--------|-------------|-----------|
| T-001 a T-059 | **59 tarefas da Sprint 1** (ver Sprint Backlog para detalhes) | Tech Lead | 30/04 |

> **Resumo Sprint 1 Done:**
> - Infraestrutura Docker (4 containers, migrations, seed) 
> - Autenticacao completa (OTP, JWT, roles, middleware) 
> - 35 endpoints REST (7 feature slices) 
> - MCP Server (16 tools, logging, retry, student_id injection) 
> - AI Service (ReAct agent, RAG pipeline, ingest, memoria) 
> - WhatsApp Webhook (HMAC, dedup, background tasks, chat visibility) 

---

### DONE — Sprint 3 + Sprint 4 (T-060 a T-118)

> Todas as tarefas foram movidas para DONE em 06/05/2026 (Sprint 3) e 07/05/2026 (Sprint 4).

| ID | Tarefa | Responsavel | Concluida |
|----|--------|-------------|-----------|
| T-060 a T-072 | **Tech Lead** — RAG threshold config, MCP fix, deploy end-to-end | Tech Lead | 06/05 |
| T-073 a T-080 | **Membro 1** — Flutter Login (email input, OTP, JWT storage, navegacao) | Membro 1 | 06/05 |
| T-081 a T-088 | **Membro 2** — Flutter Dashboard (academic summary, notas, logout) | Membro 2 | 06/05 |
| T-089 a T-096 | **Membro 3** — Knowledge Base + RAG Testing | Membro 3 | 06/05 |
| T-097 a T-104 | **Membro 4** — Prompt Engineering + Guardrails | Membro 4 | 06/05 |
| T-105 a T-112 | **Membro 5** — Scrum artifacts + Apresentacao | Membro 5 | 06/05 |
| T-113 a T-118 | **Sprint 4** — Polimento final, tech debt, entrega | Time | 07/05 |

> **Resumo Sprint 3+4 Done:**
> - Phase 7-9: Flutter Scaffold + Client Interface + Staff Interface (26 tasks)
> - Phase 10: Cross-Platform Polish (11 tasks)
> - Phase 11: Alpha Connect Visual Refactoring (2 tasks)
> - Phase 12: Frontend-Backend Integration (7 tasks)
> - Phase 13: Resource Allocation full-stack (6 tasks)
> - Phase 14: Human Intervention full-stack (6 tasks)
> - Phase 15-17: Polimento + Tech Debt (6 tasks)
> 
> **Total Sprint 3+4: 64 tasks | 50 SP**

---

### BLOCKED

| ID | Tarefa | Responsavel | Bloqueio | Acao |
|----|--------|-------------|----------|------|
| — | (nenhuma tarefa bloqueada — projeto concluido) | — | — | — |

---

### IN PROGRESS

| ID | Tarefa | Responsavel | Iniciada | Notas |
|----|--------|-------------|----------|-------|
| — | (nenhuma tarefa em andamento — projeto concluido) | — | — | — |

---

### IN REVIEW

| ID | Tarefa | Responsavel | Em Review | Notas |
|----|--------|-------------|-----------|-------|
| — | (nenhuma tarefa em review — projeto concluido) | — | — | — |

---

### TO DO

> Todas as tarefas foram movidas para DONE em 06/05/2026 (Sprint 3) e 07/05/2026 (Sprint 4).

| ID | Tarefa | Prioridade | Estimativa | Dia Alvo |
|----|--------|-----------|------------|----------|
| — | (nenhuma tarefa pendente — projeto concluido) | — | — | — |

---

## Fluxo de Trabalho

```
+----------+     +--------+     +-------------+     +-----------+     +------+
|          |     |        |     |             |     |           |     |      |
| BACKLOG  | --> | TO DO  | --> | IN PROGRESS | --> | IN REVIEW | --> | DONE |
|          |     |        |     |             |     |           |     |      |
+----------+     +--------+     +-------------+     +-----------+     +------+
                                       |
                                       v
                                 +---------+
                                 | BLOCKED |
                                 +---------+
```

### Regras de Transicao

| De → Para | Condicao |
|-----------|----------|
| Backlog → To Do | Comprometida na Sprint Planning |
| To Do → In Progress | Membro assume a tarefa |
| In Progress → In Review | Codigo pronto, precisa validacao |
| In Review → Done | Validacao OK, atende DoD |
| In Review → In Progress | Feedback: precisa de ajuste |
| Qualquer → Blocked | Impedimento externo identificado |
| Blocked → In Progress | Impedimento resolvido |

---

## Metricas do Board

| Metrica | Valor Atual | Meta |
|---------|-------------|------|
| Tarefas em To Do | 0 | 0 ao final da sprint |
| Tarefas In Progress | 0 | Max 6 simultaneas |
| Tarefas Done (Total) | 165 (Sprint 1+2: 108 + Sprint 3+4: 57) | 165 — CONCLUIDO |
| Lead Time medio | — | < 1 dia |
| Cycle Time medio | — | < 4 horas |
| Tarefas Blocked | 0 | 0 |

---

## Instrucoes para Uso

1. **Cada membro** move suas tarefas quando mudar de estado
2. **Atualizar diariamente** (ao final do dia ou no inicio do dia seguinte)
3. **Se bloqueado**, mover para Blocked E avisar no grupo imediatamente
4. **WIP limit**: nao pegar nova tarefa se ja tem 1 In Progress (foco!)
5. **Code review**: so mover para Done apos outro membro validar (pode ser verbal)

### Ferramentas Sugeridas para Board Visual

| Ferramenta | Preco | Recomendacao |
|-----------|-------|------|
| **Trello** | Gratis | Mais simples, bom para times pequenos |
| **GitHub Projects** | Gratis | Integrado com o repo |
| **Notion** | Gratis (edu) | Mais flexivel, bom para docs tambem |
| **Jira** | Gratis (10 users) | Mais completo mas mais complexo |

**Recomendacao:** Usar **Trello** ou **GitHub Projects** por simplicidade. O Membro 5 deve replicar este board em uma dessas ferramentas no Dia 1.

---

## Estado Final do Projeto

| Metrica | Valor |
|---------|-------|
| Milestone | v2.0 Flutter Frontend — SHIPPED 2026-05-07 |
| Todos os sprints | 4/4 concluidos |
| Total tasks Done | 165 (102 Sprint 1+2 + 63 Sprint 3+4) |
| Total SP | 233/233 (100%) |
| Total commits | 559 |
| Testes passando | 244 (Flutter) |
| Requisitos | 47/47 rastreados e entregues |
