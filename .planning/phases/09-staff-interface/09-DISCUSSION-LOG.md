# Phase 9: Staff Interface - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-04
**Phase:** 09-staff-interface
**Areas discussed:** Dashboard KPIs, Controle de Agenda, Dados/Insights da IA, Gestao de Documentos

---

## Dashboard KPIs

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Cards numericos em grid | Grid 2x3 de cards numericos (como admin panels) — cada KPI com icone, numero e label. | ✓ |
| Cards + mini graficos | Cards no topo + mini graficos de tendencia. Mais visualmente rico, requer dados historicos. | |
| Lista vertical de metricas | Lista vertical com valores prominentes e badges de status. | |

**User's choice:** Cards numericos em grid (Recommended)
**Notes:** Simple and direct admin panel style.

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Tap navega para tab correspondente | Tap no card de documentos pendentes navega para tab Documentos, etc. | ✓ |
| Sem navegacao (so visualizacao) | Apenas exibe numeros, sem navegacao. | |
| Preview em bottom sheet | Tap abre pop-up/bottom sheet com detalhes antes de navegar. | |

**User's choice:** Tap navega para tab correspondente (Recommended)

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Banner destacado no topo | Banner/card especial com nome do periodo, badge 'Ativo' e dias restantes. | ✓ |
| Card normal na grid | Incluir como card comum na grid. | |
| You decide | Agente decide. | |

**User's choice:** Banner destacado no topo (Recommended)

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Pull-to-refresh | RefreshIndicator padrao. Recarrega todos os KPIs. | ✓ |
| Sem refresh manual | Dados carregados uma vez. | |

**User's choice:** Pull-to-refresh (Recommended)

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Greeting + nome | Saudacao 'Ola, {name}!' no topo. | |
| Sem greeting, direto aos dados | Sem saudacao. AppBar com 'Dashboard' e direto nos dados. | ✓ |
| You decide | Agente decide. | |

**User's choice:** Sem greeting, direto aos dados

---

## Controle de Agenda

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Lista de agendamentos | Lista cronologica de agendamentos (cards). Filtros por data/status. | ✓ |
| Visualizacao calendario | Calendario visual semanal com slots coloridos. | |
| Tabs separados (slots vs agendamentos) | Duas abas: slots disponiveis e agendamentos confirmados. | |

**User's choice:** Lista de agendamentos (Recommended)

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Acoes inline no card | Botoes de acao visiveis diretamente no card. | |
| Tela de detalhe com acoes | Tap abre tela de detalhe com acoes. Mais espaco, menos cliques acidentais. | ✓ |
| Swipe gestures | Swipe left = cancelar, swipe right = confirmar. | |

**User's choice:** Tela de detalhe com acoes

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| FAB + bottom sheet | FAB abre bottom sheet com formulario de criacao de slots. | ✓ |
| Tela dedicada de criacao | Botao na AppBar navega para tela dedicada. | |
| You decide | Agente decide. | |

**User's choice:** FAB + bottom sheet (Recommended)

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Filter chips | 'Todos', 'Agendados', 'Cancelados'. Mesma pattern do client. | ✓ |
| Dropdown na AppBar | Dropdown de filtro na AppBar. | |
| Sem filtro | Lista tudo cronologicamente. | |

**User's choice:** Filter chips (Recommended)

---

## Dados/Insights da IA

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Lista de sessoes + detalhe | Lista de sessoes com preview e tap para detalhes. | |
| Dashboard analitico | Estatisticas: total sessoes, acoes, taxa de sucesso, tools mais usadas. | |
| Tabs: Sessoes + Estatisticas | Ambas em tabs separadas. | ✓ |

**User's choice:** Tabs: Sessoes + Estatisticas

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Cards com preview e badge | Cards com nome do aluno, data, status, preview, badge de acoes. | ✓ |
| Tabela compacta | Tabela com colunas: aluno, data, status, qtd acoes. | |
| You decide | Agente decide. | |

**User's choice:** Cards com preview e badge (Recommended)

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Contadores + top tools | Numeros grandes: total sessoes, sucesso, erro, top 3 tools. | ✓ |
| Graficos visuais (charts) | Bar chart, pie chart. Requer charts package. | |
| You decide | Agente decide. | |

**User's choice:** Contadores + top tools (Recommended)

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Mesmo layout do client | Mensagens em bolhas + aba de action logs expandiveis. | ✓ |
| Apenas action logs | Foco nos logs, sem mensagens. Staff se preocupa com o que o bot FEZ. | |
| You decide | Agente decide. | |

**User's choice:** Mesmo layout do client (Recommended)

---

## Gestao de Documentos

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Lista com filter chips | Filter chips (Pendentes/Processando/Prontos/Todos). Cards com aluno, tipo, data, status. | ✓ |
| Secoes por status expandiveis | Secoes colapsaveis por status. | |
| You decide | Agente decide. | |

**User's choice:** Lista com filter chips (Recommended)

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Bottom sheet com form | Bottom sheet com dropdown status + file_url + botao Atualizar. | ✓ |
| Tela de detalhe dedicada | Tela com informacoes completas + acoes. | |
| Dialog de mudanca rapida | Dialog simples de confirmacao. | |

**User's choice:** Bottom sheet com form (Recommended)

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| TextField para URL | Texto livre onde staff cola link. | |
| File picker com upload | File picker nativo + upload real. | |
| Campo condicional (so para 'ready') | Campo so aparece quando status = 'ready'. | |

**User's choice:** Campo condicional (so para 'ready') COM file picker real (combinacao de opcao 3 + file picker)

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Adicionar endpoint de upload nesta fase | POST /documents/upload — excecao ao "no backend changes". | ✓ |
| File picker com mock (sem backend change) | Picker com simulacao/mock. | |
| Voltar para TextField manual | Sem picker, sem upload. | |

**User's choice:** Adicionar endpoint de upload nesta fase
**Notes:** User accepted the backend exception for a working upload flow.

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Pull-to-refresh | Consistente com o resto do app. | ✓ |
| Sem refresh | Dados carregam uma vez. | |

**User's choice:** Pull-to-refresh (Recommended)

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Criar novos documentos (FAB) | Staff cria proativamente e publica no mural do aluno. | ✓ |
| Apenas gerenciar existentes | So gerencia pedidos feitos por alunos. | |
| You decide | Agente decide. | |

**User's choice:** Criar novos documentos (FAB)

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Bottom sheet com form completo | Selecionar aluno, tipo, file picker, botao Enviar. | ✓ |
| Tela dedicada de criacao | Mais espaco para formulario. | |
| You decide | Agente decide. | |

**User's choice:** Bottom sheet com form completo (Recommended)

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Busca por nome (autocomplete) | Campo de busca com autocomplete via GET /students. | ✓ (parcial) |
| Dropdown lista completa | Dropdown com todos alunos. | |
| Texto livre (ID/email) | Campo de texto para ID/email. | |

**User's choice:** Busca por nome com opcao de envios categorizados (por turma, por periodo)
**Notes:** User wants both individual search AND bulk categorized sending.

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Individual (filtros de busca) | Busca com filtros para encontrar UM aluno. | |
| Envio em massa por grupo | Selecionar turma/periodo e enviar para todos do grupo. | ✓ |

**User's choice:** Envio em massa por grupo
**Notes:** Staff can select a class/period and send same document to all students in that group.

---

## Agent's Discretion

- Loading skeletons/shimmer per screen
- Empty state designs
- Card dimensions, spacing, border radius
- Confirmation dialog design for destructive actions
- Autocomplete widget choice
- Storage solution for file upload
- Pagination vs infinite scroll for long lists

## Deferred Ideas

None — discussion stayed within phase scope.
