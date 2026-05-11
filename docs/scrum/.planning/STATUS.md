# Planejamento de Melhorias — Artefatos Scrum

**Avaliacao atual:** 7.5/10  
**Meta:** 9.5/10  
**Ultima atualizacao:** 2026-05-01  

---

## 1. Estado Atual (O que foi feito)

### Artefatos Criados

| # | Artefato | Arquivo | Conteudo |
|---|----------|---------|----------|
| 1 | Product Backlog | `PRODUCT-BACKLOG.md` | 47 User Stories, 10 epicos, 233 SP, priorizacao MoSCoW, criterios de aceitacao |
| 2 | Sprint Backlog | `SPRINT-BACKLOG.md` | Sprint 1 (59 tarefas/193 SP) + Sprint 2 (53 tarefas/40 SP), horas, responsaveis |
| 3 | Definition of Done | `DEFINITION-OF-DONE.md` | 3 niveis (Tarefa/Story/Incremento), criterios por tipo (Backend/Frontend/AI/Docs) |
| 4 | Burndown Chart | `BURNDOWN-CHART.md` | Dados diarios Sprint 1 (reais), projecao Sprint 2, graficos ASCII, velocidade |
| 5 | Kanban Board | `KANBAN-BOARD.md` | 5 colunas, WIP limits, regras de transicao, estado da Sprint 2 |
| 6 | Sprint Planning | `SPRINT-PLANNING.md` | Planning Sprint 1 (retro) e Sprint 2, riscos, capacidade, acordos |
| 7 | Sprint Review & Retro | `SPRINT-REVIEW-RETRO.md` | Review Sprint 1, template Sprint 2, Start/Stop/Continue, licoes |
| 8 | Daily Standup | `DAILY-STANDUP.md` | Template 5 dias x 6 membros + log impedimentos |

### Pontos Fortes

- Dados reais (commits, datas) fundamentam o burndown
- Coerencia numerica entre documentos (SP, tarefas, datas batem)
- DoD com 3 niveis e criterios por tipo de trabalho
- Rastreabilidade: US -> Tarefa -> Epico -> Requirement
- Sprint 1 com tarefas detalhadas retroativamente

---

## 2. Gaps Identificados (O que precisa melhorar)

| # | Gap | Severidade | Impacto na Apresentacao |
|---|-----|:---:|---|
| G-01 | User Stories sem formato completo ("So that..."/beneficio) | Alta | Professor pode cobrar estrutura formal |
| G-02 | Sprint 1 executada por 1 pessoa, sem dailies — nao e Scrum puro | Media | Risco em arguicao — precisa narrativa coerente |
| G-03 | Burndown Sprint 2 sem dados reais (sprint começa hoje) | Baixa | Normal no inicio — resolve ao longo da semana |
| G-04 | Falta Definition of Ready (DoR) | Media | Artefato complementar esperado |
| G-05 | Falta personas e user journey | Media | Contextualiza stakeholders |
| G-06 | Falta criterios Given/When/Then (BDD) | Baixa-Media | Mais rigor formal |
| G-07 | Artefatos so em texto/ASCII — sem identidade visual | Alta | Apresentacao e 100% projetada em tela — precisa ser VISUAL |
| G-08 | Nao existe design system para consistencia visual | Alta | Tudo precisa parecer "um projeto so" |
| G-09 | Nao existe pipeline de geracao — artefatos sao manuais | Media | Dados mudam ao longo da semana, precisa regenerar facilmente |

---

## 3. Decisoes Tomadas

| # | Decisao | Escolha | Justificativa |
|---|---------|---------|---------------|
| D-01 | Ferramenta visual | **HTML/CSS estatico** com media query para impressao -> PDF | Automatizavel, versionavel, exportavel |
| D-02 | Formato dos slides | **Reveal.js / Marp** | Markdown-based, versionavel, usa o mesmo design system |
| D-03 | BDD (Given/When/Then) | **Top 20 User Stories** | Cobertura representativa sem explodir verbosidade |
| D-04 | Narrativa Sprint 1 | **Sprint 1 com sub-sprints** (planejamento 15-23 + execucao 23-30) | Justifica burndown irregular sem mentir |
| D-05 | Nome nos artefatos | **Generico** ("Plataforma Academica") | Nao tem marca definida |
| D-06 | Tom visual | **Vibrante/Startup** | Cores vivas, gradientes, bold. Tipo Vercel/Stripe |
| D-07 | Burndown Sprint 2 | **Real ate hoje + projecao ideal** | Dados reais conforme preenchidos + linha ideal |
| D-08 | Saida visual | **1 PDF unico** com todos os artefatos | Entrega coesa para o professor |
| D-09 | Granularidade burndown | **Diaria** (dias 1-5 individuais) | Maximo de visibilidade do progresso |
| D-10 | Pipeline de geracao | **JSON -> HTML (Jinja2 + weasyprint)** | Um JSON com dados, templates HTML, gera PDF automaticamente |
| D-11 | Foco da apresentacao 6/5 | **100% artefatos Scrum** (demo tecnica e em outro dia) | Disciplina de soft skills/eng software |
| D-12 | Abordagem na apresentacao | **Top 3 visuais (Kanban, Burndown, Backlog) + mencao aos demais** | 10-15 min e curto — focar no impactante |
| D-13 | Avaliadores | **Professor + turma** | Tom: claro, visual, acessivel — nao academico demais |
| D-14 | Apresentacao | **Slides projetados** | Reveal.js/Marp + exportar para PDF como backup |

---

## 4. Plano de Melhorias (Revisado)

### Fase 0: Design System (Pre-requisito para TUDO visual)

| ID | Entregavel | Descricao | Status |
|----|-----------|-----------|--------|
| M-00 | `DESIGN-SYSTEM.md` | Paleta vibrante, tipografia, espacamento, componentes (cards, badges, graficos, tabelas), tokens CSS, layout padrao | A fazer |

---

### Fase 1: Pipeline de Geracao (Infraestrutura)

| ID | Entregavel | Descricao | Status |
|----|-----------|-----------|--------|
| M-11 | `scrum/generator/data.json` | Schema JSON com todos os dados dos artefatos (backlog, sprints, burndown, kanban) | A fazer |
| M-12 | `scrum/generator/templates/` | Templates Jinja2 para cada artefato visual (HTML + CSS inline do design system) | A fazer |
| M-13 | `scrum/generator/generate.py` | Script principal: le data.json + templates -> gera HTMLs -> gera PDF unico via weasyprint | A fazer |
| M-14 | `scrum/generator/README.md` | Documentacao de uso: como atualizar dados e regenerar | A fazer |

---

### Fase 2: Melhorias de Conteudo

| ID | Gap | Entregavel | Esforco | Status |
|----|-----|-----------|---------|--------|
| M-01 | G-01 | Reescrever 47 User Stories com "para que..." (beneficio) | ~30 min | A fazer |
| M-02 | G-04 | Criar `DEFINITION-OF-READY.md` | ~15 min | A fazer |
| M-03 | G-05 | Criar `PERSONAS.md` com 2 personas + user journeys | ~20 min | A fazer |
| M-04 | G-06 | Adicionar Given/When/Then nas top 20 US | ~40 min | A fazer |

---

### Fase 3: Melhorias Narrativas

| ID | Gap | Entregavel | Esforco | Status |
|----|-----|-----------|---------|--------|
| M-05 | G-02 | Reframe Sprint 1 com sub-sprints (planejamento + execucao) nos artefatos | ~15 min | A fazer |
| M-06 | G-03 | Burndown Sprint 2: dados reais (dia 1) + projecao ideal (dias 2-5) por dia | ~15 min | A fazer |

---

### Fase 4: Materiais Visuais (depende de M-00 + M-11/12/13)

| ID | Gap | Entregavel | Esforco | Status |
|----|-----|-----------|---------|--------|
| M-07 | G-07 | Template HTML: Burndown Chart (grafico SVG/CSS inline) | ~30 min | A fazer |
| M-08 | G-07 | Template HTML: Kanban Board visual | ~30 min | A fazer |
| M-09 | G-07 | Template HTML: Product Backlog visual (cards por epico) | ~30 min | A fazer |
| M-10 | — | Template HTML: pagina capa + indice + todos artefatos compilados | ~20 min | A fazer |
| M-15 | — | Template Marp: slides da apresentacao (10-15 min) | ~30 min | A fazer |

---

## 5. Ordem de Execucao (Revisada)

```
M-00 (Design System)
  │
  ├──> Fase 1 (Pipeline): M-11 -> M-12 -> M-13 -> M-14
  │
  ├──> Fase 2 (Conteudo): M-01, M-02, M-03, M-04 (paralelo)
  │         └── Resultados alimentam data.json (M-11)
  │
  ├──> Fase 3 (Narrativa): M-05, M-06
  │         └── Resultados alimentam data.json (M-11)
  │
  └──> Fase 4 (Visuais): M-07, M-08, M-09, M-10, M-15
            └── Depende de M-00 (design) + M-11 (dados) + M-12 (templates)
```

### Dependencias Detalhadas

| Melhoria | Depende de | Bloqueada por |
|----------|-----------|---------------|
| M-00 | Nenhuma | — |
| M-01 a M-06 | Nenhuma (conteudo puro) | — |
| M-11 | M-01 a M-06 (dados finais) | Fase 2 e 3 |
| M-12 | M-00 (design tokens) | Design System |
| M-13 | M-11 (dados) + M-12 (templates) | Pipeline completo |
| M-07 a M-10, M-15 | M-00 + M-12 | Design + Templates |

### Caminho Critico

```
M-00 -> M-12 -> M-07/M-08/M-09/M-10 -> M-13 (gerar PDF final)
              \
               M-15 (slides Marp)
```

---

## 6. Pipeline de Geracao — Especificacao

### Fluxo

```
data.json (dados)  ──┐
                     ├──> generate.py ──> output/
templates/ (HTML)  ──┘                    ├── artefatos.html (pagina unica)
                                          ├── artefatos.pdf (via weasyprint)
                                          └── slides.md (Marp source)
```

### Schema `data.json` (estrutura planejada)

```json
{
  "project": {
    "name": "Plataforma Academica",
    "team_size": 6,
    "sprints": [...]
  },
  "backlog": {
    "epics": [...],
    "stories": [...]
  },
  "sprints": {
    "sprint_1": {
      "start": "2026-04-15",
      "end": "2026-04-30",
      "goal": "...",
      "burndown_daily": [...]
    },
    "sprint_2": {
      "start": "2026-05-01",
      "end": "2026-05-05",
      "goal": "...",
      "burndown_daily": [...],
      "projection": true
    }
  },
  "kanban": {
    "columns": [...],
    "tasks": [...]
  },
  "dod": {...},
  "dor": {...},
  "personas": [...],
  "ceremonies": {
    "planning": {...},
    "review": {...},
    "retro": {...},
    "dailies": [...]
  }
}
```

### Uso

```bash
# Atualizar dados
# Editar scrum/generator/data.json

# Regenerar artefatos visuais
python scrum/generator/generate.py

# Saida em scrum/generator/output/
```

### Requisitos Python

- `jinja2` — template engine
- `weasyprint` — HTML -> PDF
- Sem dependencias pesadas (matplotlib eliminado — graficos sao CSS/SVG puro)

---

## 7. Criterios de Aceite (Revisados)

| Melhoria | Aceite |
|----------|--------|
| M-00 | Paleta hex (5 cores), tipografia (2 fontes), espacamento (escala), 5+ componentes definidos com exemplo visual |
| M-01 | 47 US com "Como X, quero Y, **para que Z**" |
| M-02 | DoR com 5+ criterios + checklist |
| M-03 | 2 personas (aluno CC + staff secretaria) com nome, foto placeholder, dores, objetivos, 1 journey cada |
| M-04 | 20 US com cenarios Given/When/Then (cobrindo todos os epicos) |
| M-05 | Sprint 1 descrita como sub-sprints (planejamento + execucao) em todos os artefatos afetados |
| M-06 | Burndown Sprint 2 com dados reais (dia 1) + projecao (dias 2-5), granularidade diaria |
| M-07 | HTML que renderiza burndown como grafico visual (CSS bars ou SVG path), cores do design system |
| M-08 | HTML que renderiza Kanban com colunas, cards coloridos por status, WIP badges |
| M-09 | HTML que renderiza backlog como cards agrupados por epico com badges de status/prioridade |
| M-10 | HTML pagina unica com capa + indice + todos os artefatos, exportavel para PDF A4 |
| M-11 | JSON valido que contem TODOS os dados necessarios para gerar os templates |
| M-12 | Templates Jinja2 que compilam sem erro com data.json |
| M-13 | `python generate.py` gera HTML + PDF sem erro em < 10s |
| M-14 | README com instrucoes: instalar deps, editar dados, rodar script |
| M-15 | Arquivo .md compativel com Marp que gera slides para 10-15 min |

---

## 8. Score Projetado (Revisado)

| Cenario | Melhorias aplicadas | Score |
|---------|--------------------|----|
| Atual | Nenhuma | 7.5 |
| + Fase 2 (conteudo) | M-01, M-02, M-03, M-04 | 8.5 |
| + Fase 3 (narrativa) | M-05, M-06 | 9.0 |
| + Fase 4 (visuais) + Pipeline | M-07 a M-15 | 9.5 |
| + Dados reais Sprint 2 preenchidos | G-03 fecha | 9.5+ |

---

## 9. Proximas Acoes

1. **AGORA:** Criar M-00 (Design System) — desbloqueia toda Fase 4
2. **Em seguida:** Fase 2 (conteudo) — pode rodar em paralelo com Fase 1 (pipeline)
3. **Depois:** Montar pipeline (M-11 a M-14) usando o design system
4. **Por fim:** Gerar visuais e slides (M-07 a M-15)

---

## 10. Riscos

| Risco | Mitigacao |
|-------|-----------|
| weasyprint tem problemas de instalacao no Windows | Fallback: usar `pdfkit` + `wkhtmltopdf`, ou exportar direto do browser (Ctrl+P) |
| Dados mudam mas esquecemos de regenerar | README claro + data.json como single source of truth |
| Design system fica ambicioso demais | Limitar a 5 cores + 2 fontes + 5 componentes. Minimalismo > perfeicao |
| 10-15 min nao cabe tudo | Top 3 artefatos (Kanban, Burndown, Backlog) como visuais projetados, demais como "material complementar entregue" |
