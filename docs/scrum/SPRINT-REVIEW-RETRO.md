# Sprint Review & Retrospectiva — Desafio FCG3

**Projeto:** Plataforma Academica com Chatbot WhatsApp  
**Ultima atualizacao:** 2026-05-11  

---

## Sprint 1 Review — Planejamento

**Data:** 23/04/2026  
**Sprint:** Sprint 1 (08/04 - 23/04)  
**Participantes:** Tech Lead  
**Duracao:** 16 dias  

---

### Natureza da Sprint

Sprint de **planejamento**. Nenhum Story Point entregue. Foco em pesquisa, documentacao e design.

### O que foi entregue

| Entregavel | Status |
|---|---|
| Pesquisa de dominio (4 areas) | Entregue |
| REQUIREMENTS.md (69 requisitos) | Entregue |
| ROADMAP.md (6 fases, 44 plans) | Entregue |
| Architecture documentation | Entregue |
| Database schema design (21 tabelas) | Entregue |
| Threat models (auth, MCP) | Entregue |
| Validation strategies (6 fases) | Entregue |

### Incremento Funcional Entregue

Pacote completo de planejamento pronto para execucao.

### O que NAO foi entregue

| Item | Razao | Acao |
|------|-------|------|
| Qualquer codigo | Sprint exclusivamente de planejamento | Mover para Sprint 2 |

### Feedback dos Stakeholders

- Planejamento abrangente porem demorado — 16 dias poderia ter sido comprimido

---

## Sprint 1 Retrospectiva

**Data:** 23/04/2026  
**Formato:** Start / Stop / Continue  

### O que deu certo (Continue)

| Item | Impacto |
|------|---------|
| Planejamento detalhado antes de codar | Base solida para execucao rapida |
| Requisitos claros e documentados | Sem ambiguidade na implementacao |
| Abordagem fase-por-fase | Dependencias mapeadas, execucao ordenada |

### O que nao deu certo (Stop)

| Item | Impacto | Correcao |
|------|---------|----------|
| Tempo excessivo em planejamento sem codigo | 16 dias sem nenhum entregavel funcional | Comecar a codar mais cedo |
| Sem envolvimento do time | Bus factor = 1, sem distribuicao de conhecimento | Envolver time desde o inicio |

### O que deveriamos comecar (Start)

| Item | Beneficio |
|------|-----------|
| Comecar a codar mais cedo | Entregar valor funcional antes |
| Envolver time mais cedo | Distribuicao de conhecimento e risco |

---

## Sprint 2 Review — Execucao

**Data:** 30/04/2026  
**Sprint:** Sprint 2 (23/04 - 30/04)  
**Participantes:** Tech Lead  
**Duracao:** 8 dias  
**SP Entregues:** 193 por 1 pessoa (Tech Lead com assistencia de IA)  

---

### O que foi entregue

| Epico | SP Planejado | SP Entregue | % |
|-------|-------------|-------------|---|
| Infraestrutura | 24 | 24 | 100% |
| Autenticacao | 26 | 26 | 100% |
| Business Features | 78 | 78 | 100% |
| MCP Server | 32 | 32 | 100% |
| AI Service | 37 | 34 | 92% |
| WhatsApp Webhook | 24 | 24 | 100% |
| **Total** | **221** | **218** | **99%** |

### Incremento Funcional Entregue

1. **Stack Docker completa** — 4 servicos sobem com `docker compose up`, Alembic migrations criam schema, seed popula dados de teste
2. **Autenticacao via OTP** — Fluxo completo: solicitar codigo -> verificar -> JWT -> logout -> revogacao, com rate limiting
3. **35 endpoints REST** — 7 feature slices cobrindo toda a gestao academica (alunos, cursos, matricula, notas, documentos, agendamentos, dashboard)
4. **MCP Server** — 16 ferramentas expostas, student_id injetado por sessao, logging completo, retry automatico
5. **AI Service** — Agente ReAct LangChain, RAG com PGVector, provider agnostico (OpenAI/Gemini), memoria de conversa
6. **WhatsApp Webhook** — HMAC validation, background processing, deduplicacao, media handling, chat visibility para staff

### O que NAO foi entregue

| Item | Razao | Acao |
|------|-------|------|
| RAG threshold funcional (US-030 parcial) | Threshold 0.75 muito alto para OpenRouter embeddings (max score ~0.67) | Mover para Sprint 3 — fix trivial |
| MCP action logs UUID (US-032) | INSERT sem gen_random_uuid() — descoberto no UAT | Mover para Sprint 3 — fix trivial |

### Demo da Sprint 2

**Cenario demonstrado:** Enviar mensagem no WhatsApp → webhook recebe → AI processa → resposta enviada

**Resultado:** Funcional com limitacao — agente responde mas sem dados do RAG (threshold bloqueando). MCP tools funcionam quando action logging nao e acionado.

### Feedback dos Stakeholders

- Backend robusto e bem estruturado
- Necessidade de frontend para demonstracao visual
- Necessidade de deploy em servidor acessivel
- Artefatos Scrum precisam ser formalizados

---

## Sprint 2 Retrospectiva

**Data:** 30/04/2026  
**Formato:** Start / Stop / Continue  

### O que deu certo (Continue)

| Item | Impacto |
|------|---------|
| Vertical slice architecture | Cada feature isolada, sem acoplamento |
| Docker desde o dia 1 | Ambiente reproduzivel, sem "funciona na minha maquina" |
| UAT humano apos cada fase | Bugs reais encontrados (SELECT FOR UPDATE, ciclo pre-requisitos, etc.) |
| AI-assisted development | 1 pessoa entregou 193 SP em 8 dias |

### O que nao deu certo (Stop)

| Item | Impacto | Correcao |
|------|---------|----------|
| UAT so no final da Sprint | Blocker do RAG descoberto tarde demais | UAT parcial ao longo da sprint |
| Trabalho centralizado em 1 pessoa | Risco de bus factor, gargalo | Sprint 3: distribuir entre 6 membros |
| RAG threshold hardcoded | Inflexivel para diferentes providers | Tornar configuravel via env var |

### O que deveriamos comecar (Start)

| Item | Beneficio |
|------|-----------|
| Daily standups | Visibilidade do progresso, desbloqueio rapido |
| Pair programming | Distribuicao de conhecimento para time junior |
| Testar mais cedo com dados reais | Detectar problemas como RAG threshold antes |
| Distribuir trabalho | Reduzir bus factor |

### Acoes da Retro (para Sprint 3)

| # | Acao | Responsavel | Prazo |
|---|------|-------------|-------|
| R-01 | Distribuir trabalho entre 6 membros | Tech Lead | Sprint 3 |
| R-02 | Daily standup via texto (manha) | Todos | Diario |
| R-03 | UAT parcial a cada 2 dias (nao so no fim) | Tech Lead | 02/05 e 04/05 |
| R-04 | Gravar video backup da demo ate 04/05 | Membro 5 | 04/05 |
| R-05 | RAG threshold configuravel (nao hardcoded) | Tech Lead | 01/05 |

---

## Sprint 3 Review — Demonstracao

**Data:** 06/05/2026  
**Sprint:** Sprint 3 (01/05/2026 — 06/05/2026)  
**Participantes:** Todos (6 membros)  
**Duracao:** 6 dias  

---

### O que foi entregue

| Epico | SP Planejado | SP Entregue | % |
|-------|-------------|-------------|---|
| Flutter Scaffold + Auth | 6 | 6 | 100% |
| Client Interface | 8 | 8 | 100% |
| Staff Interface | 8 | 8 | 100% |
| Cross-Platform Polish | 4 | 4 | 100% |
| Alpha Connect Refactoring | 4 | 4 | 100% |
| Frontend-Backend Integration | 5 | 5 | 100% |
| Resource Allocation | 3 | 3 | 100% |
| Human Intervention | 2 | 2 | 100% |
| **Total** | **40** | **40** | **100%** |

### Incremento Funcional Entregue

- [x] Flutter app completo com telas do cliente (Login/OTP, Dashboard, Documentos, Chat, Notificacoes)
- [x] Telas do staff (Dashboard, Agenda, Sessao IA, Documentos, Recursos, Intervencoes)
- [x] Cross-platform: dark mode, responsividade, animacoes
- [x] Docker Compose full stack funcionando (`docker compose up` sobe tudo)
- [x] Testes E2E de integracao
- [x] Feature Resource Allocation completa (frontend + backend)
- [x] Feature Human Intervention completa (frontend + backend)
- [x] WhatsApp chatbot integrado e funcionando
- [x] 57 tarefas de escopo concluidas (53 originais + 4 adicionadas no escopo)

### Demo da Sprint 3

**Apresentacao realizada em 06/05/2026 — time completo presente.**

Demonstrado ao vivo:
1. Flutter app rodando — fluxo completo do aluno (login OTP → dashboard → documentos → chat)
2. Integracao WhatsApp chatbot com o backend em tempo real
3. Interface staff com gestao de recursos e intervencao humana
4. Docker Compose subindo a stack completa

### Feedback dos Stakeholders

- Apresentacao realizada com sucesso perante professor e turma
- Flutter frontend com design Glassmorphism recebeu feedback positivo
- Integracao completa frontend-backend-WhatsApp impressionou
- Projeto considerado concluido para os fins do desafio FCG3

---

## Sprint 3 Retrospectiva

**Data:** 06/05/2026  
**Formato:** Start / Stop / Continue  

### O que deu certo (Continue)

| Item | Impacto |
|------|---------|
| AI-assisted development para acelerar entregas | Time de 6 membros entregou 40 SP em 6 dias com qualidade alta |
| Docker desde o inicio | Ambiente reproduzivel, integracao sem atrito |
| Planejamento detalhado de fases antes de codar | Phases 7-14 executadas em ordem sem retrabalho significativo |
| Glassmorphism design system como identidade visual | UI coesa, moderna e bem recebida na apresentacao |

### O que nao deu certo (Stop)

| Item | Impacto | Correcao |
|------|---------|----------|
| Sessoes de desenvolvimento sem pausa | Fadiga no final da sprint (196 commits em 3 dias) | Planejar pausas estruturadas |
| Frontend adiado para ultimo momento no ciclo do projeto | Pressure intensa na Sprint 3 | Iniciar frontend mais cedo em projetos futuros |
| Acumular divida tecnica de UI | Overflow em texto grande descoberto somente ao final | Checklist de UI antes de fechar cada tela |

### O que deveriamos comecar (Start)

| Item | Beneficio |
|------|-----------|
| CI/CD pipeline para Flutter | Feedback automatico em cada PR, reduz regressoes |
| Testes automatizados antes de cada feature | Detectar bugs antes da integracao final |
| Code review coletivo | Distribuicao de conhecimento, qualidade de codigo |

### Metricas da Sprint 3

| Metrica | Valor |
|---------|-------|
| Velocidade realizada | 40 SP / 6 dias = 6.7 SP/dia |
| Tarefas concluidas | 57 / 57 (100%) |
| Tarefas nao concluidas | 0 |
| Bugs encontrados | 1 (overflow em texto grande — corrigido no Sprint 4) |
| Bugs criticos | 0 |
| Commits | ~196 |
| Satisfacao do time (1-10) | 9/10 |

---

## Historico de Velocidade

| Sprint | Tipo | SP Planejado | SP Entregue | Velocity |
|--------|------|--------------|-------------|---------|
| Sprint 1 | Planejamento | 0 | 0 | N/A |
| Sprint 2 | Execucao | 193 | 193 (100%) | 24.1 SP/dia |
| Sprint 3 | Demonstracao | 40 | 40 (100%) | ~6.7 SP/dia |

---

## Sprint 4 — v3.0 Review e Retrospectiva (Template — preencher em 14/05)

**Sprint ativa: 07/05 a 14/05/2026**

### Progresso Atual (11/05/2026)

| Fase v3.0 | Status | SP | Tipo |
|-----------|--------|----|------|
| Phase 15-17 (Polimento) | Done | 10 SP | Concluido |
| Phase 18 (Student UX) | Done | 15 SP | Branch — pendente merge |
| Phase 19 (Staff UX) | Done | 26 SP | Branch — pendente merge |
| Phase 20 (LangChain) | Done | 41 SP | Branch — pendente merge |
| Phase 21 (Roles & Auth) | Done | 13 SP | Branch — pendente merge |
| Phase 22 (FCM Push) | Done | 13 SP | Branch — pendente merge |
| Phase 23 (New Features) | To Do | 21 SP | Planejado 10-13/05 |
| Phase 24 (UI Polish v3) | To Do | 13 SP | Planejado 13-14/05 |
| **Total** | 78% done | **152 SP** | |

### SP Entregues por Dia (real ate 09/05)

| Dia | Data | SP Acumulado | Commits |
|-----|------|--------------|---------|
| Dia 1 | 07/05 | 10 | 43 |
| Dia 2 | 08/05 | 51 | ~45 |
| Dia 3 | 09/05 | 118 | ~85 |
| Dia 4-5 | 10-11/05 | 118 | ~0 |

### Secoes a Preencher em 14/05

- [ ] Incremento entregue (o que foi demonstrado)
- [ ] SP planejados x entregues
- [ ] Demo realizada (quem apresentou, o que funcionou)
- [ ] Feedback dos stakeholders
- [ ] Retrospectiva Start/Stop/Continue do Sprint 4
- [ ] Velocidade historica Sprint 4

### Historico de Velocidade (atualizado)

| Sprint | Tipo | SP Planejado | SP Entregue | Velocity |
|--------|------|--------------|-------------|---------|
| Sprint 1 | Planejamento | 0 | 0 | — |
| Sprint 2 | Execucao | 193 | 193 (100%) | 24.1 SP/dia |
| Sprint 3 | Exec. Frontend | 40 | 38 (95%) | 6.3 SP/dia |
| Sprint 4 | v3.0 Milestone | 152 | 118 (78% — Em andamento) | ~39.3 SP/dia (dias 1-3) |

---

## Licoes Aprendidas (Projeto)

### Tecnicas

1. **Docker Compose primeiro** — investir no ambiente antes de codar features poupou muito debugging posterior
2. **Vertical slice > layers architecture** — cada feature slice pode ser desenvolvida independentemente sem conflitos
3. **MCP como proxy seguro** — student_id injetado pelo servidor, nunca exposto ao LLM, e uma decisao arquitetural acertada
4. **Provider agnostico** — suportar OpenAI + Gemini + OpenRouter via env var facilitou adaptacao a custos e disponibilidade
5. **Alembic migrations atomicas** — cada mudanca de schema rastreavel e reversivel

### Processo

1. **Planning detalhado = execucao rapida** — os 16 dias de planejamento (Sprint 1) permitiram executar 193 SP em 8 dias (Sprint 2)
2. **UAT humano e indispensavel** — testes automatizados nao pegaram o bug do RAG threshold nem o UUID missing
3. **Bus factor = 1 e perigoso** — Sprints 1 e 2 com 1 pessoa = alto risco; Sprint 3 distribui melhor
4. **Artefatos Scrum retroativos sao validos** — melhor documentar depois do que nao documentar

### Pessoais

1. **IA como multiplicador** — permite que 1 junior produza como 3 seniors em tarefas bem definidas
2. **Comunicacao de bloqueio imediata** — nunca esperar para amanha se travou
3. **Demo driven development** — definir primeiro o que vai mostrar na demo direciona prioridades
