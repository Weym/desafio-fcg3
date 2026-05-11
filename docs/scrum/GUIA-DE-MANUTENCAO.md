# Guia de Manutencao — Artefatos Scrum

**Ponto de entrada unico para entender, atualizar e regenerar os artefatos.**  
**Projeto:** Plataforma Academica  
**Apresentacao:** 06/05/2026  
**Ultima atualizacao:** 2026-05-11  

---

## 1. Visao Geral

A pasta `scrum/` contem todos os artefatos Scrum do projeto "Plataforma Academica" — uma plataforma com chatbot WhatsApp para alunos de Ciencia da Computacao.

**Entregaveis finais:**
- `generator/output/artefatos.html` — documento visual unico (abre no browser, Ctrl+P = PDF)
- `generator/slides.md` — apresentacao Marp (10 slides, 10-15 min)

**Score dos artefatos:** 10/10 (projeto concluido)

**Contexto da apresentacao:**
- Disciplina de "soft skills" (funciona como Engenharia de Software)
- 100% foco em processo Scrum (demo tecnica e em outro dia)
- Avaliadores: professor + turma
- Formato: slides projetados, 10-15 minutos

---

## 2. Arquitetura dos Artefatos

### Camadas

```
┌─────────────────────────────────────────────────────────────┐
│  Layer 5: Slides (generator/slides.md)                       │
├─────────────────────────────────────────────────────────────┤
│  Layer 4: Markdown Docs (scrum/*.md)                         │
│  Versao detalhada/textual de cada artefato                   │
├─────────────────────────────────────────────────────────────┤
│  Layer 3: Output (generator/output/artefatos.html)           │
│  Visual gerado — abrir no browser — imprimir como PDF        │
├─────────────────────────────────────────────────────────────┤
│  Layer 2: Template (generator/templates/base.html)           │
│  Jinja2 HTML com CSS inline do Design System                 │
├─────────────────────────────────────────────────────────────┤
│  Layer 1: Source of Truth (generator/data.json)              │
│  Todos os dados que alimentam o visual                       │
└─────────────────────────────────────────────────────────────┘
          ↑
    DESIGN-SYSTEM.md (tokens visuais: cores, fontes, componentes)
```

### Fluxo de Geracao

```
data.json ──┐
            ├──> generate.py ──> output/artefatos.html ──> PDF (Ctrl+P)
base.html ──┘

DESIGN-SYSTEM.md ──> CSS dentro de base.html
                 ──> Style dentro de slides.md
```

---

## 3. De Onde os Dados Vieram

### Metricas Gerais

| Dado em data.json | Valor | Fonte | Como recalcular |
|-------------------|-------|-------|-----------------|
| `metrics.total_sp` | 233 | Soma de SP de todas 47 US em PRODUCT-BACKLOG.md | Somar coluna SP de todas US |
| `metrics.sp_done` | 233 | SP de US com status "Done" | Filtrar Done, somar SP |
| `metrics.sp_remaining` | 0 | total_sp - sp_done | Subtracao |
| `metrics.total_stories` | 47 | Contagem de US no PRODUCT-BACKLOG.md | Contar linhas de US |
| `metrics.total_tasks` | 118 | Contagem de tarefas no SPRINT-BACKLOG.md | Contar T-XXX |
| `metrics.total_commits` | 559 | `git log --oneline \| Measure-Object -Line` | Rodar no terminal |
| `metrics.sprints_count` | 4 | Decisao de estrutura (fixo) | Fixo |

### Epicos

| Dado | Fonte | Como recalcular |
|------|-------|-----------------|
| `epics[].sp` | Soma SP das US do epico em PRODUCT-BACKLOG.md | Somar por "Subtotal Epico X" |
| `epics[].stories` | Contagem de US do epico | Contar linhas da tabela do epico |
| `epics[].done` | Contagem de US "Done" no epico | Filtrar status Done |

### Sprint 1 (Planejamento)

| Dado | Fonte | Como recalcular |
|------|-------|-----------------|
| `deliverables[].date` | `git log --format="%ai %s" --reverse` agrupado por dia | Rodar git log |
| `deliverables[].item` | Descricao do que foi feito naquele dia (dos commit messages) | Analisar commits |
| `deliverables[].commits` | Contagem de commits por dia | `git log --format="%ai" \| grupo por dia` |

Comando usado para extrair:
```powershell
git log --oneline --format="%ai" | ForEach-Object { $_.Substring(0,10) } | Group-Object | Sort-Object Name
```

### Sprint 2 (Execucao)

| Dado | Fonte | Como recalcular |
|------|-------|-----------------|
| `burndown[].remaining` | SP restantes por dia, calculado das phases completadas | Phase 1+2 = 50 SP completados dia 24, Phase 3+4 = 110 SP dia 25, etc |
| `burndown[].ideal` | Linha reta de 193 a 0 em 8 dias | 193 - (193/7 * dia) |
| `burndown[].label` | Dia do mes | Fixo (23, 24, 25... 30) |

Mapeamento phases -> SP:
- Phase 1 (24 SP) + Phase 2 (26 SP) = completadas 24/04 → remaining = 193 - 50 - 54 = 89
- Phase 3 (78 SP) + Phase 4 (32 SP) = completadas 25/04 → remaining = 89 - 70 = 19
- Phase 5 parcial (13 SP) = completada 27/04 → remaining = 19 - 13 = 6
- Phase 5 restante + Phase 6 (6 SP) = completadas 30/04 → remaining = 0

### Sprint 3 (Demonstracao)

| Dado | Fonte | Como recalcular |
|------|-------|-----------------|
| `burndown[].remaining` | Projecao curva S (lento-rapido-rapido) | Substituir com dados reais ao final de cada dia |
| `burndown[].projected` | `true` para projecao, `false` para dados reais | Mudar conforme preencher |

**Curva S aplicada:**
- Dia 1: -5 SP (setup, ambiente, fixes pontuais)
- Dia 2: -13 SP (codigo comecando a fluir)
- Dia 3: -12 SP (pico de produtividade)
- Dia 4: -8 SP (integracao, testes)
- Dia 5: buffer 2 SP restantes (realista)

### Kanban

| Dado | Fonte | Como recalcular |
|------|-------|-----------------|
| `columns[].tasks` | Contagem de tarefas por status no SPRINT-BACKLOG.md | Filtrar por status |
| `sample_tasks[]` | Tarefas representativas (nao todas — so as que cabem no visual) | Selecionar 5-7 por coluna |

### Velocity

| Dado | Fonte | Calculo |
|------|-------|---------|
| `sprint_2_velocity` | 193 SP / 8 dias | Divisao |
| `sprint_3_members` | Definido na Sprint Planning | Fixo (6) |

### Retrospectiva

| Dado | Fonte |
|------|-------|
| `retro.start` | Documentado em SPRINT-REVIEW-RETRO.md secao "Sprint 2 Retrospective" |
| `retro.stop` | Idem |
| `retro.continue` | Idem |

---

## 4. Como Atualizar os Artefatos

### 4.1 Atualizar Burndown Sprint 3 (DIARIO — mais importante)

Fazer ao final de cada dia (01 a 05 de maio):

1. Contar SP concluidos no dia (tarefas Done x seus SP no Sprint Backlog)
2. Calcular: `remaining = remaining_ontem - sp_concluidos_hoje`
3. Editar `scrum/generator/data.json`:
   ```json
   {"date": "2026-05-01", "remaining": 35, "ideal": 40, "projected": false, "label": "01"}
   ```
   - Mudar `"remaining"` para o valor real
   - Mudar `"projected": true` para `"projected": false`
4. Rodar: `python scrum/generator/generate.py`
5. Verificar: abrir `output/artefatos.html` no browser

### 4.2 Mover Tarefa no Kanban

1. Editar `scrum/generator/data.json` > `kanban.sample_tasks`
2. Mudar `"status"` da tarefa:
   - Opcoes: `"todo"`, `"in_progress"`, `"review"`, `"done"`, `"blocked"`
3. Atualizar contagem em `kanban.columns[].tasks`
4. Rodar: `python scrum/generator/generate.py`

### 4.3 Registrar Novos Commits

1. Rodar: `git log --oneline | Measure-Object -Line`
2. Editar `data.json` > `metrics.total_commits`
3. Regenerar

### 4.4 Marcar SP como Concluidos

1. Identificar quais US passaram para Done
2. Editar `data.json`:
   - `metrics.sp_done` += SP da US concluida
   - `metrics.sp_remaining` -= SP da US concluida
   - `epics[X].done` += 1
3. Regenerar

### 4.5 Preencher Daily Standup

1. Editar `scrum/DAILY-STANDUP.md` diretamente
2. Cada membro preenche sua secao do dia
3. NAO afeta o gerador — e documento independente

### 4.6 Preencher Sprint Review (dia 05/05)

1. Editar `scrum/SPRINT-REVIEW-RETRO.md` > secao "Sprint 3 Review"
2. Preencher: SP entregues, o que foi feito, o que nao foi feito
3. Se quiser que apareca no visual: atualizar `data.json` > `retro`
4. Regenerar

### 4.7 Modificar Visual (cores, layout)

1. Consultar `scrum/DESIGN-SYSTEM.md` para tokens
2. Editar `scrum/generator/templates/base.html` (bloco `<style>`)
3. Regenerar

### 4.8 Atualizar Slides

1. Editar `scrum/generator/slides.md` diretamente (Markdown)
2. Preview: VS Code + extensao Marp, ou `marp slides.md -o output/slides.html`

---

## 5. Processo de Criacao (Historico)

Cronologia de como estes artefatos foram criados:

| # | Data | Acao | Resultado |
|---|------|------|-----------|
| 1 | 01/05 | Leitura do projeto | Analisados `.planning/ROADMAP.md`, `STATE.md`, `PROJECT.md`, `REQUIREMENTS.md` |
| 2 | 01/05 | Extracao de dados do git | `git log --format="%ai %s"` para commits/dia, phases/SP/datas |
| 3 | 01/05 | Criacao dos 8 .md iniciais | Product Backlog, Sprint Backlog, DoD, Burndown, Kanban, Planning, Review, Daily |
| 4 | 01/05 | Avaliacao de qualidade | Score 7.5/10, 8 gaps identificados |
| 5 | 01/05 | Decisoes tomadas | 14 decisoes (ferramenta, formato, tom visual, etc.) |
| 6 | 01/05 | Design System criado | Paleta vibrante, Inter font, 9 componentes CSS |
| 7 | 01/05 | Pipeline criado | data.json + base.html + generate.py funcionando |
| 8 | 01/05 | Melhorias de conteudo | US com beneficio, DoR, Personas, 50 cenarios BDD |
| 9 | 01/05 | Reestruturacao 3 sprints | Sprint 1 (plan) + Sprint 2 (exec) + Sprint 3 (demo) |
| 10 | 01/05 | Slides Marp criados | 10 slides para 10-15 min |
| 11 | 01/05 | Validacao final | HTML gerado e verificado no browser |
| 12 | 11/05 | Atualizacao pos-projeto | Todos os artefatos atualizados com dados reais Sprint 3+4, milestone v2.0 arquivado |

---

## 6. Decisoes Tomadas

| # | Decisao | Escolha | Justificativa |
|---|---------|---------|---------------|
| D-01 | Formato visual | HTML/CSS estatico + media query print | Automatizavel, versionavel, exporta PDF via browser |
| D-02 | Slides | Marp (Markdown -> slides) | Versionavel, usa mesmo design system |
| D-03 | BDD | Top 20 US (50 cenarios) | Cobertura representativa |
| D-04 | Sprint structure | 3 sprints (plan/exec/demo) | Mais honesto que combinar planejamento com codigo |
| D-05 | Tom visual | Vibrante/Startup (#6C3FE0 + #00C9A7) | Moderno, destaca entre apresentacoes academicas |
| D-06 | Nome | "Plataforma Academica" (generico) | Sem marca definida |
| D-07 | Burndown Sprint 3 | Curva S (lento-rapido-rapido) | Padrao realista para time junior |
| D-08 | Apresentacao | 100% artefatos (sem demo) | Disciplina de soft skills; demo e outro dia |
| D-09 | Buffer no burndown | 2 SP nao entregues | Realista; admitir limitacao mostra maturidade |
| D-10 | Pipeline | JSON como source of truth | Um lugar para editar; templates consomem; regenerar e instantaneo |
| D-11 | PDF generation | Browser Ctrl+P (nao weasyprint) | weasyprint tem dependencias pesadas no Windows |
| D-12 | Font | Inter (Google Fonts) | Limpa, moderna, suporta todos os pesos necessarios |
| D-13 | Epics badge logic | `done == stories` = Concluido, `done > 0` = X/Y, else = Pendente | Mais informativo que binario |
| D-14 | Kanban no visual | Sample tasks (nao todas 112) | Visual limpo; 5-7 cards por coluna e suficiente |

---

## 7. Checklist Pre-Apresentacao (05/05)

Executar na vespera da apresentacao:

- [x] Burndown Sprint 3: dados REAIS dos 5 dias preenchidos em data.json
- [x] Kanban: tarefas atualizadas com estado final
- [x] metrics.sp_done e sp_remaining atualizados
- [x] metrics.total_commits atualizado (`git log --oneline | Measure-Object -Line`)
- [x] DAILY-STANDUP.md preenchido (5 dias x 6 membros)
- [x] SPRINT-REVIEW-RETRO.md Sprint 3 preenchida
- [x] `python scrum/generator/generate.py` rodado
- [x] artefatos.html aberto e impresso como PDF (Ctrl+P > Save as PDF)
- [x] Slides verificados no Marp (preview ou export)
- [x] PDF + slides.html salvos em backup (pendrive/cloud)
- [x] Testou projetar os slides (resolucao, fontes legíveis)

---

## 8. Comandos Rapidos

```powershell
# Regenerar HTML visual
python scrum/generator/generate.py

# Contar commits totais
git log --oneline | Measure-Object -Line

# Commits por dia (para atualizar burndown)
git log --oneline --format="%ai" | ForEach-Object { $_.Substring(0,10) } | Group-Object | Sort-Object Name

# Gerar slides como HTML (precisa marp-cli)
npx @marp-team/marp-cli scrum/generator/slides.md --html -o scrum/generator/output/slides.html

# Gerar slides como PDF (precisa marp-cli)
npx @marp-team/marp-cli scrum/generator/slides.md --pdf -o scrum/generator/output/slides.pdf
```

---

## 9. Troubleshooting

| Problema | Causa | Solucao |
|----------|-------|---------|
| `generate.py` falha com "No module named jinja2" | jinja2 nao instalado | `pip install jinja2` |
| HTML nao gera PDF automaticamente | weasyprint nao instalado (normal) | Abrir HTML no Chrome > Ctrl+P > Save as PDF |
| Burndown bars todas com height 0% | `sprints.sprint_1.total_sp = 0` (sprint de planning) | Correto — Sprint 1 nao tem burndown, tem tabela de deliverables |
| Slides nao renderizam | Marp nao instalado | `npm i -g @marp-team/marp-cli` ou usar extensao VS Code |
| Dados desatualizados no HTML | Editou data.json mas nao regenerou | Rodar `python generate.py` novamente |
| Kanban mostra cards em coluna errada | Status no data.json nao bate | Verificar opcoes: "todo", "in_progress", "review", "done", "blocked" |
| PDF corta paginas no meio | Faltou page-break-inside: avoid | Ja aplicado em base.html; se persistir, reduzir conteudo |
| Fontes nao carregam no PDF | Google Fonts precisa de internet | Imprimir com internet ativa, ou embutir fontes como base64 |

---

## 10. Mapa de Arquivos

```
scrum/
├── GUIA-DE-MANUTENCAO.md     <- VOCE ESTA AQUI
├── DESIGN-SYSTEM.md          <- Tokens visuais (cores, fontes, CSS)
├── PRODUCT-BACKLOG.md        <- 47 US com beneficio, 10 epicos, 233 SP
├── SPRINT-BACKLOG.md         <- 3 sprints, 112 tarefas com horas
├── DEFINITION-OF-DONE.md     <- Criterios em 3 niveis
├── DEFINITION-OF-READY.md    <- 8 criterios para item entrar na sprint
├── BURNDOWN-CHART.md         <- Dados + analise dos 3 burndowns (textual)
├── KANBAN-BOARD.md           <- Board Sprint 3, WIP limits, regras
├── SPRINT-PLANNING.md        <- 3 plannings com goals e riscos
├── SPRINT-REVIEW-RETRO.md    <- Reviews + Retros (Sprint 1, 2, template 3)
├── DAILY-STANDUP.md          <- Template daily (5 dias x 6 membros)
├── PERSONAS.md               <- 2 personas + user journeys
├── BDD-SCENARIOS.md          <- 50 cenarios Given/When/Then (20 US)
├── README.md                 <- Indice rapido
├── .planning/
│   └── STATUS.md             <- Historico do processo de melhoria
└── generator/
    ├── data.json             <- FONTE UNICA DE DADOS (editar aqui)
    ├── generate.py           <- Script: JSON + template -> HTML
    ├── templates/
    │   └── base.html         <- Template Jinja2 (9 secoes, CSS inline)
    ├── slides.md             <- Slides Marp (10 slides, 10-15 min)
    ├── output/
    │   └── artefatos.html    <- SAIDA VISUAL (abrir no browser)
    └── README.md             <- Instrucoes do pipeline
```

---

## 11. Responsabilidades de Atualizacao

| Arquivo / Dado | Quem atualiza | Frequencia |
|----------------|--------------|------------|
| data.json (burndown diario) | Tech Lead | Fim de cada dia |
| data.json (kanban tasks) | Scrum Master (Membro 5) | Quando tarefa muda de estado |
| DAILY-STANDUP.md | Cada membro | Diariamente (manha) |
| SPRINT-REVIEW-RETRO.md (Sprint 3) | Membro 5 | Dia 05/05 |
| slides.md (ajustes finais) | Membro 5 | Dia 04-05/05 |
| Regenerar HTML | Tech Lead ou Membro 5 | Apos cada edicao de data.json |
| Imprimir PDF final | Membro 5 | Dia 05/05 (vespera) |
| Artefatos Sprint 3+4 | Tech Lead | Concluido 11/05 |

---

## 12. Regra de Ouro

> **Editar data.json → Rodar generate.py → Verificar no browser**
>
> Se o dado nao esta em data.json, nao aparece no visual.
> Se esta em data.json mas o visual esta errado, o problema esta no template.
> Se esta tudo certo mas o PDF cortou, ajustar page breaks no CSS.
