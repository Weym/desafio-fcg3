# Burndown Chart — Desafio FCG3

**Projeto:** Plataforma Academica com Chatbot WhatsApp  
**Ultima atualizacao:** 2026-05-11  

---

## Sprint 1: Planejamento (08/04 a 23/04)

**Tipo:** Sprint de planejamento  
**Duracao:** 16 dias  
**Story Points entregues:** 0 (output e documentacao, nao codigo)  
**Commits totais:** 39  
**Resultado:** Todos os artefatos de planejamento criados e validados

### Entregas de Planejamento

| Data | Entrega | Commits |
|------|---------|---------|
| 08/04 | Repositorio criado | 1 |
| 13/04 | Planejamento inicial | 1 |
| 14/04 | Revisao e expansao do planejamento | 1 |
| 15/04 | Pesquisa de ecossistema + requisitos + roadmap | 7 |
| 20/04 | Contexto das 6 fases capturado | 8 |
| 22/04 | Contexto fases 5-6 | 2 |
| 23/04 | Todos os 44 plans criados + validacao | 19 |

### Grafico de Progresso Sprint 1 (Artefatos de Planejamento)

```
Commits (acumulado)
 39  |                                                    *
     |                                                   /
 35  |                                                  /
     |                                                 /
 30  |                                                /
     |                                               /
 25  |                                              /
     |                                             /
 20  |                                  *---------*
     |                                 /
 15  |                                /
     |                          *----*
 10  |                    *----*
     |                   /
  5  |                  /
     |            *    /
  2  |     *--*--*
  1  |  *
  0  |___________________________________________________
     08   13   14   15   16   17   18   19   20   21   22   23
                              Abril 2026

     * Commits acumulados por dia
```

### Analise Sprint 1

| Metrica | Valor |
|---------|-------|
| **Duracao** | 16 dias (08/04 - 23/04) |
| **Story Points** | 0 (sprint de planejamento) |
| **Commits** | 39 |
| **Artefatos gerados** | 44 plans de execucao + requisitos + roadmap |
| **Dias ativos** | 7 de 16 |
| **Padrao observado** | Crescimento progressivo — pesquisa inicial, depois captura massiva de contexto |

---

## Sprint 2: Execucao (23/04 a 30/04)

**Total planejado:** 193 Story Points  
**Duracao:** 8 dias  
**Entregue:** 193 SP  
**Resultado:** Sprint Goal atingida — backend completo com todas as 6 fases implementadas

### Dados Diarios (Story Points Restantes)

| Data | SP Restantes | SP Entregues no Dia | Ideal | Commits | Observacao |
|------|-------------|--------------------|---------|---------|----|
| 23/04 (Inicio) | 193 | 0 | 193 | (planning commits) | Inicio da sprint |
| 24/04 | 89 | 104 | 169 | 106 | Phase 1 + Phase 2 + inicio Phase 3 |
| 25/04 | 19 | 70 | 145 | 110 | Phase 3 completa + Phase 4 completa |
| 26/04 | 19 | 0 | 121 | 6 | Estabilizacao |
| 27/04 | 6 | 13 | 97 | 20 | Phase 5 fixes (embedding, UUID, OpenRouter) |
| 28/04 | 6 | 0 | 72 | 0 | — |
| 29/04 | 6 | 0 | 48 | 1 | Config ajuste .env.example |
| 30/04 | 0 | 6 | 0 | 34 | Phase 6 completa + UAT final |

### Grafico Burndown Sprint 2

```
SP Restantes
200 |*
    | \  Ideal
180 |  - .
    |    - .
160 |      - .
    |        - .
140 |          - .
    |            - .
120 |              - .
    |                - .
100 |           *      - .
    |            \       - .
 80 |             \        - .
    |              \         - .
 60 |               \          - .
    |                \           - .
 40 |                 \            - .
    |                  *---*         - .
 20 |                       \          - .
    |                        *--*--*     - .
  0 |________________________________________*
    23   24   25   26   27   28   29   30
                   Abril 2026

    --- Ideal (linear)     * Real
```

### Analise Sprint 2

| Metrica | Valor |
|---------|-------|
| **Velocidade total** | 193 SP / 8 dias = 24.1 SP/dia |
| **Dias efetivos de codigo** | 4 dias (24, 25, 27, 30) |
| **Velocidade efetiva** | 48.25 SP/dia em dias de codigo |
| **Maior dia** | 24/04 — 104 SP (Phase 1 + 2 + inicio Phase 3) |
| **Padrao observado** | Execucao concentrada apos planejamento detalhado |
| **Burst pattern** | 90% do trabalho concluido nos dias 24-25 (174 de 193 SP) |
| **Risco materializado** | RAG threshold (gap tecnico descoberto no UAT dia 30) |

---

## Sprint 3: Demonstracao (01/05 a 06/05)

**Total planejado:** 40 Story Points  
**Status:** Concluido (38 SP entregues, 2 SP carregados para Sprint 4)  
**Membros:** 6  
**Commits totais:** ~220  
**Meta:** Sistema demonstravel com frontend + WhatsApp + artefatos Scrum

### Dados Diarios (Story Points Restantes) — Real

| Data | SP Restantes (Ideal) | SP Restantes (Real) | Commits | Observacao |
|------|---------------------|---------------------|---------|-----|
| 01/05 (Inicio) | 40 | 40 | 0 | Inicio da sprint — planejamento |
| 01/05 (Fim dia) | 33 | 40 | 0 | Sem progresso no dia 1 |
| 02/05 (Fim dia) | 27 | 35 | 23 | MCP X-Student-Id injection fix + RAG fixes (5 SP) |
| 03/05 (Fim dia) | 20 | 35 | 0 | Sem commits |
| 04/05 (Fim dia) | 13 | 22 | 56 | Flutter fases 7+8 — Scaffold + Client Interface (13 SP) |
| 05/05 (Fim dia) | 7 | 10 | 62 | Flutter fases 9+10 — Staff Interface + Cross-Platform Polish (12 SP) |
| 06/05 (Fim dia) | 0 | 2 | 58 | Fases 11-14 — Alpha Connect, Docker, Resources, E2E (8 SP, 2 SP para Sprint 4) |

### Grafico Burndown Sprint 3 (Real)

```
SP Restantes
 40  |*--*
     |    \
     |     \
 35  |      *--*
     |          \
     |           \
 22  |            *
     |             \
     |              \
 10  |               *
     |                \
     |                 \
  2  |                  *
  0  |_________________________
     01  02  03  04  05  06
              Maio 2026

     * Real     . Ideal (linear)
```

### Distribuicao de SP por Dia (Sprint 3) — Real

| Dia | SP Entregues | Commits | Tarefas Realizadas |
|-----|-------------|---------|-------------------|
| 01/05 (Qui) | 0 SP | 0 | Planejamento |
| 02/05 (Sex) | 5 SP | 23 | MCP X-Student-Id fix + RAG pipeline fixes |
| 03/05 (Sab) | 0 SP | 0 | — |
| 04/05 (Dom) | 13 SP | 56 | Phase 7+8: Flutter Scaffold + Client Interface |
| 05/05 (Seg) | 12 SP | 62 | Phase 9+10: Staff Interface + Cross-Platform Polish |
| 06/05 (Ter) | 8 SP | 58 | Phases 11-14: Alpha Connect, Docker, Resources, E2E Tests |

### Nota sobre Sprint 3

A sprint entregou 38 de 40 SP planejados (95%). Os 2 SP restantes (Phases 12-14 parcial) foram carregados para Sprint 4 e concluidos no dia 07/05. O volume de 220 commits em 6 dias demonstra execucao intensa e burst pattern tipico do Tech Lead.

---

## Burndown Acumulado (Projeto Completo)

### Progresso Total: 233 SP (meta)

| Fase | Data | SP Acumulado |
|------|------|-------------|
| Sprint 1 end | 23/04 | 0 (planning only) |
| Sprint 2 start | 23/04 | 0 |
| Sprint 2 day 2 | 24/04 | 104 |
| Sprint 2 day 3 | 25/04 | 174 |
| Sprint 2 day 5 | 27/04 | 187 |
| Sprint 2 end | 30/04 | 193 |
| Sprint 3 end | 06/05 | 231 (38 SP entregues, 2 SP para Sprint 4) |
| Sprint 4 end | 07/05 | 243 (12 SP entregues — 2 carry-over + 10 novos) |

### Grafico Acumulado

```
SP Entregues (acumulado)
 245 |                                                        * (meta)
     |                                                       /
 230 |                                                      /
     |                                               *-----*
 200 |                                              /
     |                                 *-----------*
 180 |                              *
     |                             /
 160 |                            /
     |                           /
 140 |                          /
     |                         /
 120 |                        /
     |                       /
 100 |                    *
     |                   /
  80 |                  /
     |                 /
  60 |                /
     |               /
  40 |              /
     |             /
  20 |            /
     |           /
   0 |*--------*...............* - - - - - - - - - - *-----* - - - *
     08   13   15   20   23   24   25   26   27   28   29   30   01   06   07
     |------- Sprint 1 -------|------- Sprint 2 ---------|-- Sprint 3 --|S4|
              Abril                                           Maio
```

---

## Metricas de Velocidade

| Metrica | Sprint 1 | Sprint 2 | Sprint 3 (real) | Sprint 4 (real) |
|---------|----------|----------|-----------------|-----------------|
| **Duracao** | 16 dias | 8 dias | 6 dias | 1 dia |
| **Story Points** | 0 | 193 | 38 (real, 2 SP para Sprint 4) | 12 (2 carry-over + 10 novos) |
| **Membros ativos** | 1 (Tech Lead) | 1 (Tech Lead) | 6 | 1 (Tech Lead) |
| **Velocidade (SP/dia)** | N/A (planning) | 24.1 | 6.3 | 12.0 |
| **Commits totais** | 39 | 277 | ~220 | 43 |

---

## Observacoes para a Apresentacao

1. **Sprint 1 nao possui burndown tradicional** — e uma sprint de planejamento onde o output sao artefatos de documentacao (44 plans, requisitos, roadmap). O progresso e medido por entregas de planejamento, nao story points.

2. **O burndown da Sprint 2 mostra um padrao "burst"** — 90% do trabalho entregue nos dias 24-25 (174 de 193 SP). Isso e resultado direto do planejamento pesado da Sprint 1. Uma unica pessoa executou apos ter planos detalhados para cada fase.

3. **Sprint 3 tambem seguiu o burst pattern** — 0 commits no dia 1, 0 commits no dia 3, mas execucao intensa nos dias 2, 4, 5 e 6 (56-62 commits/dia nos picos). A equipe de 6 membros trabalhou em paralelo nos dominios de frontend, backend, e infraestrutura.

4. **Sprint 3 entregou 38 de 40 SP (95%)** — os 2 SP restantes foram carregados para Sprint 4 e concluidos no dia 07/05.

5. **Sprint 4 foi uma micro-sprint de 1 dia** — focada em tech debt (auth/router), traceability (47/47 verificada), e polimento (skeleton shimmer). 244 testes Flutter passando ao final.

6. **A separacao em 4 sprints reflete a realidade do projeto:**
   - Sprint 1: Planejamento solo (1 pessoa, 0 SP, 39 commits de docs)
   - Sprint 2: Execucao solo (1 pessoa, 193 SP, 277 commits de codigo)
   - Sprint 3: Demonstracao colaborativa (6 pessoas, 38 SP, ~220 commits)
   - Sprint 4: Polimento final (Tech Lead, 12 SP, 43 commits)

7. **Total do projeto:** 559 commits | 233/233 SP entregues (100%) | Milestone v2.0 SHIPPED

8. **Recomendacao para o grafico visual:** usar ferramenta como Google Sheets ou Notion com chart para gerar um grafico mais bonito para os slides.

---

## Sprint 4 — v3.0 Correcoes, Melhorias & Features (07/05 - 14/05/2026)

**Status:** Em andamento (Sprint ativa — termina 14/05/2026)  
**Goal:** Completar milestone v3.0 — UX corrections (phases 18-19), AI workflow (phase 20), auth expansion (phase 21), FCM push (phase 22), novas features (phases 23-24)  
**Scope:** 92 tasks | 152 SP | 8 dias | 6 membros  
**Commits estimados apos merge:** ~737

### Dados Reais (07-09/05/2026)

| Dia | Data | SP Restantes | Tasks Restantes | Commits | Tipo | Observacao |
|-----|------|--------------|-----------------|---------|------|------------|
| Inicio | 07/05 manha | 152 | 92 | — | — | Sprint 4 start com v3.0 scope |
| Dia 1 | 07/05 | 142 | 86 | 43 | Real | Phases 15-17: polish -10 SP |
| Dia 2 | 08/05 | 101 | 54 | ~45 | Real | Phases 18-19 UX: -41 SP, -32 tasks |
| Dia 3 | 09/05 | 34 | 16 | ~85 | Real | Phases 20-22 AI/Auth/FCM: -67 SP |
| Dia 4 | 10/05 | 34 | 16 | 0 | Real | Sem commits (fim de semana) |
| Dia 5 | 11/05 | 34 | 16 | ~0 | Real/Projecao | Hoje — fases 23-24 nao iniciadas |
| Dia 6 | 12/05 | 22 | 10 | — | Projecao | Phase 23 (features) parcialmente |
| Dia 7 | 13/05 | 10 | 4 | — | Projecao | Phase 23 concluida |
| Dia 8 | 14/05 | 0 | 0 | — | Projecao | Phase 24 polish + sprint end |

### Burndown Sprint 4 — Grafico ASCII

```
Tasks/SP
 92 |* (inicio)                                                  [ideal]
 80 |  \                                                         ----
 70 |   *  86 tasks (07/05, after phase 15-17)                  ----
 60 |    \                                                       ----
 50 |     \                                                      ----
 40 |      *  54 tasks (08/05, after phases 18-19)              ----
 30 |       \                                                    ----
 20 |        *  16 tasks (09/05, after phases 20-22)  *proj     ----
 15 |         \                                          \       ----
 10 |          *  16 (10/05, 11/05 sem progresso)        \proj  ----
  5 |                                                     \     ----
  0 |___________________________________________*proj*proj*  <- 14/05
     07/05  08/05  09/05  10/05  11/05  12/05  13/05  14/05
```

**Padrao observado:** Sprint 4 repete o padrao de burst de Sprint 2 e 3 — pico de entregas nos primeiros 3 dias, seguido de desaceleracao antes de retomada final.

### Velocidade por Sub-fase

| Fase | Periodo | SP | Dias | SP/dia |
|------|---------|-----|------|--------|
| A: Polimento | 07/05 | 10 | 1 | 10.0 |
| B: UX Corrections | 08/05 | 41 | 1 | 41.0 |
| C: AI/Auth/FCM | 09/05 | 67 | 1 | 67.0 |
| D+E: Features+Polish | 12-14/05 | 34 | 3 (proj.) | 11.3 (proj.) |

### Projecao de Entrega

**Baseline de entrega:** 14/05/2026 (dentro do prazo da Sprint 4)  
**SP restantes:** 34 (phases 23-24)  
**Dias restantes:** 3 (Mai 12-14)  
**Velocity necessaria:** 11.3 SP/dia — factivel considerando velocidade historica de 10-67 SP/dia nessa sprint

**Confianca na entrega (Sprint 4):** Alta — 78% do scope entregue em 3 dias

### Burndown Acumulado — Projeto Completo (atualizado)

| Sprint | Periodo | SP Inicial | SP Entregues | Acumulado |
|--------|---------|-----------|--------------|-----------|
| Sprint 1 | 15/04 - 23/04 | 0 (planning) | 0 | 0/375 |
| Sprint 2 | 23/04 - 30/04 | 193 | 193 | 193/375 (51%) |
| Sprint 3 | 01/05 - 06/05 | 40 | 38 | 231/375 (62%) |
| Sprint 4 (parcial) | 07/05 - 09/05 | 152 | 118 | 349/375 (93%) |
| Sprint 4 (projecao) | 10-14/05 | 34 | 34 (proj.) | 375/375 (100%) |

**Velocity media (3 sprints entregues):** (193+38+118) / (8+6+3) = 349 SP / 17 dias = 20.5 SP/dia  
**Total SP atual:** 375 | **SP entregues:** 341 (91%) | **SP projetados:** 34 (9%)
