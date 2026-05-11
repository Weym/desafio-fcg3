---
marp: true
theme: default
paginate: true
size: 4:3
style: |
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700;800&display=swap');
  section {
    font-family: 'Inter', sans-serif;
    color: #374151;
  }
  section.lead {
    background: linear-gradient(135deg, #6C3FE0 0%, #00C9A7 100%);
    color: white;
  }
  section.lead h1 { color: white; }
  section.lead h2 { color: rgba(255,255,255,0.9); }
  section.lead strong { color: white; }
  h1 { color: #6C3FE0; font-weight: 800; }
  h2 { color: #111827; font-weight: 700; }
  strong { color: #6C3FE0; }
  table { font-size: 0.8em; }
  th { background: #F9FAFB; }
---

<!-- _class: lead -->

# Plataforma de Assistencia Academica

## Artefatos Scrum — Sprint Review

Caroline Cabral | Felipe Mello | Gabriel Rezende
Henry Gabriel | Ricardo Rossi | Weydson Marinho

Maio 2026

---

# O Projeto

Plataforma academica com chatbot WhatsApp para alunos de Ciencia da Computacao.

- **Auth OTP** — Login seguro via email com codigo de verificacao
- **API REST** — 35 endpoints cobrindo todo o dominio academico
- **AI Chatbot** — Agente inteligente com RAG para atendimento via WhatsApp

**Arquitetura — 4 Servicos**

| FastAPI `:8000` | LangChain `:8001` | MCP Server `:8002` | PostgreSQL `:5432` |
|:---:|:---:|:---:|:---:|
| API Central | Agente IA | Proxy + Logs | Dados + Vetores |

---

# Metodologia

## Como aplicamos Scrum

| Sprint | Foco | Duracao | Membros | Story Points |
|--------|------|---------|---------|-------------|
| Sprint 1 | Planejamento | 9 dias | 1 | -- (71 tasks definidas) |
| Sprint 2 | Execucao | 8 dias | 1 | 193 SP |
| Sprint 3 | Demonstracao | 6 dias | 6 | 40 SP |
| Sprint 4 | Planejado | 7 dias | 6 | A definir |

**Cerimonias realizadas:**
- Planning, Daily (via texto), Review, Retrospectiva

**Papeis definidos:**
- Product Owner, Scrum Master, Dev Team (6 membros)

---

# Product Backlog — 47 User Stories

| Epico | SP | Status |
|-------|---:|:------:|
| Infraestrutura e Ambiente | 24 | Concluido |
| Autenticacao e Seguranca | 26 | Concluido |
| Gestao Academica | 78 | Concluido |
| MCP Server | 32 | Concluido |
| AI Service (LangChain + RAG) | 37 | Concluido |
| WhatsApp Webhook | 24 | Concluido |
| Frontend Mobile | 16 | Em andamento |
| Guardrails e Seguranca | 8 | Pendente |
| Deploy e Operacoes | 10 | Pendente |
| Testes | 8 | Parcial |
| **Total** | **233 SP** | **85% done** |

---

# Sprint 1 — Planejamento

**Periodo:** 15/04 - 23/04 (9 dias)
**Goal:** Definir escopo, requisitos, arquitetura e planos de execucao

| Entrega | Quantidade |
|---------|-----------|
| Requisitos funcionais e nao-funcionais | 69 |
| Planos de execucao detalhados | 29 |
| Tasks definidas nos planos | 71 |
| Commits | 36 |

**Burnup:** De 4 tasks definidas (dia 15) ate 71 tasks (dia 23)

> "Planning detalhado = execucao rapida"

---

# Sprint 2 — Burndown (Execucao)

**193 SP | 71 tasks iniciais + 31 scope discovery = 102 tasks finais**

| Dia | Tasks Done | SP Done | Scope Added |
|-----|:---------:|:-------:|:-----------:|
| 24/04 | 37 | 104 SP | +5 (gaps infra) |
| 25/04 | 80 | 174 SP | +20 (gaps business + MCP + AI) |
| 27/04 | 84 | 187 SP | +4 (gaps AI) |
| 30/04 | 102 | 193 SP | +2 (gaps AI final) |

**Velocidade:** 24.1 SP/dia | **Scope Discovery:** +31 tasks (gap closures)

> "Identificar e corrigir gaps no momento mostra maturidade do processo"

---

# Sprint 3 — Kanban Board (Demonstracao)

**01/05 a 06/05 | 6 dias | 6 membros | 40 SP | 53+4 tasks**

| To Do (3) | In Progress (2) | In Review (1) | Done (9) |
|-----------|----------------|---------------|----------|
| Prompt hardening | Flutter login | Knowledge base | API completa |
| Deploy servidor | Flutter dashboard | | Auth OTP |
| | | | RAG + MCP fix |
| | | | X-Student-Id fix |
| | | | Chatbot + Webhook |

**Definition of Done:**
- Codigo funcional, sem secrets, testado, commitado com msg descritiva, funciona no Docker

---

# Definition of Done

## 3 Niveis de Validacao

**Tarefa:**
- Codigo implementado e funcional
- Sem erros de lint ou tipo

**User Story:**
- Todos os criterios de aceitacao atendidos
- Endpoint testavel via HTTP (Postman/curl)
- Documentacao de API atualizada

**Incremento:**
- Servico executa sem erros em ambiente local
- Integracao entre servicos validada

**Trade-offs aceitos para o prazo:**
- Cobertura de testes unitarios minima (foco em testes de integracao)
- Deploy automatizado adiado para Sprint 3

---

<!-- _class: lead -->

# Resumo

**233 SP** | **47 US** | **339 commits** | **4 Sprints** | **6 membros**

**Progresso:** 198/233 SP entregues (85%)

**Artefatos completos:**
Backlog, Sprint Backlog, DoD, DoR, Kanban, Burndown,
Burnup, Planning, Review, BDD, Personas

##

**Obrigado — Perguntas?**
