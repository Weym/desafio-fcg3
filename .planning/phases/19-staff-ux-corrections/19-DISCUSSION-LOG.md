# Phase 19: Staff UX Corrections - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-08
**Phase:** 19-Staff UX Corrections
**Areas discussed:** Navigation & Cadastro placement, Search & filter pattern, Dashboard navigation with pre-applied filters, Agendamentos card redesign

---

## Navigation & Cadastro Placement

| Option | Description | Selected |
| ------ | ----------- | -------- |
| 5 tabs + Cadastro via Dashboard | Não mexe no bottom nav. Chats encaixado dentro de Intervenção (nova aba). Cadastro acessível via card no Dashboard. | |
| Renomear para Chats | Renomeia 'Intervenção' para 'Chats'. Dentro dela: sub-tabs (Todos, Pendentes, Em atendimento). Cadastro via Dashboard. Nav: Painel, Agenda, Chats, Docs, Recursos. | ✓ |
| Expandir com overflow | Adiciona mais destinos com menu 'Mais' no phone para acomodar tudo. | |

**User's choice:** Renomear para Chats (Recomendado)
**Notes:** User chose the recommended option for cleaner navigation.

### Follow-up: Cadastro access from Dashboard

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Card KPI que navega | Card no grid de KPIs mostrando count de alunos. Tap navega para /staff/cadastro. | |
| Seção Ações Rápidas | Seção separada abaixo dos KPIs com botões de ação. | ✓ |

**User's choice:** Seção Ações Rápidas
**Notes:** User preferred separating metrics (KPIs) from management actions visually.

---

## Search & Filter Pattern

| Option | Description | Selected |
| ------ | ----------- | -------- |
| SearchBar fixa no topo | SearchBar fixa no topo de cada tela de lista (abaixo do AppBar, acima dos filter tabs). Sempre visível. | ✓ |
| Search expansível no AppBar | Botão de lupa no AppBar que expande para SearchBar quando clicado. | |
| Misto por frequência de uso | SearchBar fixa para Cadastro, search no AppBar para Agenda/Intervenção. | |

**User's choice:** SearchBar fixa no topo (Recomendado)
**Notes:** Consistent pattern across all screens needing search.

### Follow-up: Cadastro advanced filter (SFUX-25)

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Search unificado + pills de estado | SearchBar busca em todos os campos simultaneamente. Filtro de estado como filter tabs/pills abaixo. | ✓ |
| Search básico + sheet filtro avançado | SearchBar simples (só nome) + botão de filtro avançado que abre sheet com campos RA, número, estado. | |
| Você decide | Agent's discretion on best approach. | |

**User's choice:** Search unificado + pills de estado (Recomendado)
**Notes:** Unified search across multiple fields — simpler UX.

---

## Dashboard Navigation with Pre-applied Filters

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Query params na rota | Passar filtro como parâmetro na rota GoRouter. Tela lê o query param e seta filtro inicial. Web-friendly. | ✓ |
| StateProvider compartilhado | Usar StateProvider (Riverpod) compartilhado entre Dashboard e tela destino. Padrão Phase 18. | |
| Você decide | Agent's discretion on technical approach. | |

**User's choice:** Query params na rota (Recomendado)
**Notes:** Clean URL-based approach, no provider coupling between screens.

---

## Agendamentos Card Redesign

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Avatar + Nome + Recurso + status | Avatar com inicial + Nome do aluno (título) + Recurso reservado (subtítulo) + data/hora + status badge. | ✓ |
| Card compacto sem avatar | Nome (bold) + Recurso em linha única + data/hora ao lado direito + status. Mais denso. | |
| Você decide | Agent's discretion on card layout. | |

**User's choice:** Avatar + Nome + Recurso + status (Recomendado)
**Notes:** Consistent with existing GlassCard patterns across staff screens.

### Follow-up: Detail screen approach

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Corrigir tela existente | Manter StaffAppointmentDetailScreen (push route). Corrigir campos mostrados + fix confirmar. | ✓ |
| Bottom sheet no lugar | Substituir tela de detalhe por bottom sheet (padrão Phase 18). | |

**User's choice:** Corrigir tela existente (Recomendado)
**Notes:** Existing detail screen kept — just needs field corrections and confirm action fix.

---

## Agent's Discretion

- Loading skeletons/shimmer design
- Empty state text and icons per screen
- Exact spacing and typography for new sections
- Transition animations between tabs
- Phone number formatting mask
- "Ações Rápidas" section visual design specifics

## Deferred Ideas

None — discussion stayed within phase scope.
