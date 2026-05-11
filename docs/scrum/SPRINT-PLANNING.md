# Sprint Planning — Desafio FCG3

**Projeto:** Plataforma Academica com Chatbot WhatsApp  
**Ultima atualizacao:** 2026-05-11  

---

## Sprint 1 Planning — Planejamento

**Data da Planning:** 08/04/2026  
**Participantes:** Tech Lead (1 membro)  
**Duracao da Sprint:** 16 dias (08/04 - 23/04)  
**Capacidade:** 1 pessoa x 16 dias x 4h/dia = 64h disponiveis  

### Sprint Goal

> Definir escopo completo, requisitos validados, arquitetura documentada, e 44 planos de execucao detalhados — prontos para implementacao sem ambiguidade.

### Itens Selecionados do Product Backlog

Nenhum SP comprometido (sprint de planejamento). Os entregaveis sao documentacao:

- Pesquisa de dominio e ecossistema
- REQUIREMENTS.md (69 requisitos)
- ROADMAP.md (6 fases)
- 44 execution plans across 6 phases
- Validation strategies + threat models
- Architecture and database documentation

### Criterios de Sucesso da Sprint 1

1. Todos os requisitos escritos com criterios de aceitacao claros
2. Todas as 6 fases possuem planos de execucao detalhados
3. Cada plano tem task breakdown, dependencias e passos de verificacao
4. Threat models cobrem autenticacao e padroes de acesso a dados

### Riscos Identificados na Planning

| Risco | Probabilidade | Impacto | Mitigacao |
|-------|------|---------|-----------|
| Scope creep durante planejamento | Media | Alto | Timebox rigido por documento |
| Over-engineering dos planos | Media | Medio | Foco em MVP — cortar complexidade especulativa |

---

## Sprint 2 Planning — Execucao

**Data da Planning:** 23/04/2026  
**Participantes:** Tech Lead (1 membro)  
**Duracao da Sprint:** 8 dias (23/04 - 30/04)  
**Capacidade:** 1 pessoa x 8 dias x 8h/dia = 64h disponiveis (intensivo)  

### Sprint Goal

> Implementar todo o backend (API REST, MCP Server, AI Service, WhatsApp Webhook) com o fluxo end-to-end funcional em ambiente Docker local.

### Itens Selecionados do Product Backlog

| Epico | User Stories | SP Total |
|-------|-------------|----------|
| 1. Infraestrutura | US-001 a US-004 | 24 |
| 2. Autenticacao | US-005 a US-009 | 26 |
| 3. Gestao Academica | US-010 a US-022 | 78 |
| 4. MCP Server | US-023 a US-027 | 32 |
| 5. AI Service | US-028 a US-031 | 34 |
| 6. WhatsApp Webhook | US-033 a US-037 | 24 |
| **Total comprometido** | **30 User Stories** | **193 SP** |

*Nota: SP alto viavel devido ao planejamento completo na Sprint 1 + desenvolvimento assistido por IA.*

### Criterios de Sucesso da Sprint 2

1. `docker compose up` sobe 4 containers saudaveis
2. Todos os 35 endpoints REST respondem corretamente
3. MCP Server chama tools e loga acoes
4. AI Service responde perguntas em portugues usando tools + RAG
5. Webhook WhatsApp recebe e responde mensagens

### Riscos Identificados na Planning Sprint 2

| Risco | Probabilidade | Impacto | Mitigacao |
|-------|------|---------|-----------|
| Complexidade de integracao entre 4 servicos | Alta | Alto | Resolver infraestrutura primeiro (Phase 1) |
| PGVector + LangChain podem ter incompatibilidades | Media | Medio | Pesquisa previa documentada |
| SELECT FOR UPDATE + async pode gerar deadlocks | Media | Medio | Testes focados em concorrencia |
| OpenAI API pode ter mudancas/instabilidade | Baixa | Alto | Implementar provider agnostico |

---

## Sprint 3 Planning — Demonstracao

**Data da Planning:** 01/05/2026  
**Participantes:** 6 membros (Tech Lead + 5)  
**Duracao da Sprint:** 5 dias (01/05 - 05/05)  
**Capacidade:** 6 pessoas x 5 dias x 3.5h/dia = 105h disponiveis  
*(3.5h/dia considerando que o time e junior e trabalha parcialmente no projeto)*

### Sprint Goal

> Tornar o sistema demonstravel para a apresentacao do dia 06/05 — com frontend minimo funcional, chatbot WhatsApp respondendo ao vivo, guardrails de seguranca testados, e todos os artefatos Scrum completos.

### Itens Selecionados do Product Backlog

| Epico | User Stories | SP Total | Responsavel |
|-------|-------------|----------|-------------|
| 5. AI Service (gap) | US-030, US-032 | 11 | Tech Lead |
| 7. Frontend | US-038, US-039, US-040 | 16 | Membro 1 + 2 |
| 8. Guardrails | US-041, US-042 | 8 | Membro 4 |
| 9. Deploy | US-043, US-044 | 10 | Tech Lead |
| — Scrum/Apresentacao | (nao mapeado em SP) | — | Membro 5 |
| — Knowledge Base | (suporte a US-030/031) | — | Membro 3 |
| **Total comprometido** | **8 User Stories** | **40 SP** |

### Capacidade por Membro

| Membro | Horas Disponiveis | Tarefas | SP Alvo |
|--------|-------------------|---------|---------|
| Tech Lead | 5 x 5h = 25h | 13 | 19 |
| Membro 1 | 5 x 3.5h = 17.5h | 8 | 8 |
| Membro 2 | 5 x 3.5h = 17.5h | 8 | 11 |
| Membro 3 | 5 x 3.5h = 17.5h | 8 | 5 (+suporte) |
| Membro 4 | 5 x 3.5h = 17.5h | 8 | 8 |
| Membro 5 | 5 x 3.5h = 17.5h | 8 | — (scrum) |

### Criterios de Sucesso da Sprint 3

1. [x] RAG retorna chunks relevantes com threshold 0.45 (fix validado)
2. [x] Frontend Flutter: login OTP + dashboard com dados reais funcionam
3. [x] Deploy no servidor: `docker compose up` funciona remotamente
4. [x] WhatsApp webhook aponta pro servidor e responde ao vivo
5. [x] System prompt rejeita prompt injection (testado)
6. [x] Artefatos Scrum completos e visiveis (Backlog, DoD, Kanban, Burndown)
7. [x] Demo ensaiada com roteiro definido

### Riscos Identificados na Planning Sprint 3

| Risco | Probabilidade | Impacto | Mitigacao |
|-------|------|---------|-----------|
| Docker nao funciona no servidor | Media | Critico | Plano B: ngrok local |
| Time junior nao entrega frontend a tempo | Media | Alto | Telas minimas (2-3 apenas) |
| WhatsApp webhook nao verifica sem HTTPS | Alta | Alto | Usar ngrok com HTTPS |
| RAG threshold 0.45 ainda filtra demais | Baixa | Medio | Pode baixar para 0.35 |
| Perguntas na demo saem do escopo | Media | Media | Roteiro com "perguntas seguras" |

### Acordos do Time

1. **Daily standup:** Quick update diario no grupo (texto, nao chamada) — o que fez, o que vai fazer, bloqueios
2. **WIP limit:** 1 tarefa por pessoa de cada vez
3. **Comunicacao de bloqueio:** Avisar IMEDIATAMENTE se travou (nao esperar daily)
4. **Code review:** Revisao rapida (pode ser verbal/screen share)
5. **Deadline real:** Tudo deve estar pronto ate 05/05 as 22h para permitir ajustes
6. **Plano B da demo:** Gravar video ate 04/05 caso algo falhe ao vivo

---

## Sprint 4 — v3.0 Correcoes, Melhorias & Features

**Data:** 2026-05-07 a 2026-05-14 (8 dias)  
**Status:** Em andamento  
**Goal:** Completar milestone v3.0 — corrigir UX broken, aprimorar AI workflow, expandir roles, implementar FCM push, adicionar features novas (cardapio, perfil, grade curricular)  
**Membros:** 6 (paralelo por grupos)  
**Capacidade:** 6 membros x 8 dias x 6h = 288h  
**Story Points planejados:** 152 SP

### Goal do Sprint 4

> "Entregar o milestone v3.0 completo: todas as 40 correcoes de UX, o chatbot Alpha com seguranca de nivel producao, auth multi-role, FCM push e 3 features novas para estudantes."

### Organizacao em Grupos (Execucao Paralela)

```
Grupo 1 (Correcoes):   Phase 18 ∥ Phase 19  →  concluido 09/05
Grupo 2 (Melhorias):   Phase 20 ∥ Phase 21 ∥ Phase 22  →  concluido 09/05
Grupo 3 (Features):    Phase 23  →  planejado 10-13/05
Grupo 4 (Polish):      Phase 24  →  planejado 13-14/05
```

### Itens Selecionados para Sprint 4

| # | Phase | Descricao | SP | Grupo | Status |
|---|-------|-----------|-----|-------|--------|
| 1 | 15-17 | Polimento final v2.0 (traceability, tech debt, skeleton) | 10 | Pre-sprint | Done |
| 2 | 18 | Student UX Corrections (7 itens, phases 18-01 a 18-07) | 15 | G1 | Done (branch) |
| 3 | 19 | Staff UX Corrections (9 itens, phases 19-01 a 19-09) | 26 | G1 | Done (branch) |
| 4 | 20 | LangChain Workflow (11 planos, Alpha persona, RAG, OTP, security) | 41 | G2 | Done (branch) |
| 5 | 21 | Roles & Auth Expansion (provider role, staff CRUD, 6th tab) | 13 | G2 | Done (branch) |
| 6 | 22 | FCM Push Notifications (backend service, Flutter handlers, deep-link) | 13 | G2 | Done (branch) |
| 7 | 23 | New Features (cardapio, perfil, grade curricular) | 21 | G3 | To Do |
| 8 | 24 | UI Polish & Integration v3.0 final | 13 | G4 | To Do |
| **Total** | | | **152 SP** | | |

### Riscos e Mitigacoes

| Risco | Probabilidade | Impacto | Mitigacao |
|-------|--------------|---------|-----------|
| Phases 23-24 nao completados no prazo | Media | Alto | Reducao de scope em US-063 (grade curricular) se necessario |
| Conflitos no merge das 4 branches | Baixa | Alto | Code review individual, CI/CD test suite |
| FCM sem device fisico para UAT | Alta | Medio | Testar com emulador Android com Google Play Services |
| LangChain Alpha persona regressao | Baixa | Alto | Suite de testes 20-UAT.md como guard de regressao |

### Sprint 4 Success Criteria

- [ ] 4 branches merged sem conflitos em main
- [ ] Phases 23-24 entregues (ou scope reduzido aceito pelo PO)
- [ ] 244+ testes Flutter passando apos merge
- [ ] Smoke test E2E: estudante envia mensagem e recebe resposta da Alpha via WhatsApp
- [ ] FCM: pelo menos 1 notificacao push entregue no device de teste
- [ ] Provider role: staff senior consegue criar/editar membros via app

### Accordos do Time

- Merge das branches somente com code review do Tech Lead
- UAT das 4 features (student UX, staff UX, LangChain, FCM) antes do merge
- Phases 23-24 em go/no-go decision em 11/05

---

## Definicao de "Pronto para Planning"

Um item do Product Backlog esta pronto para ser selecionado na Sprint quando:

- [ ] User Story escrita com criterios de aceitacao claros
- [ ] Dependencias tecnicas identificadas
- [ ] Estimativa em SP atribuida
- [ ] Acesso/ferramentas necessarias disponíveis
- [ ] Nenhum impedimento externo conhecido

---

## Sprint Planning Checklist

- [x] Product Backlog revisado e priorizado
- [x] Sprint Goal definida
- [x] Capacidade do time calculada
- [x] Itens selecionados e comprometidos
- [x] Tarefas quebradas (Sprint Backlog)
- [x] Dependencias mapeadas
- [x] Riscos identificados
- [x] Acordos do time registrados
- [x] DoD revisada e aceita pelo time
