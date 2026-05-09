# Phase 19: Staff UX Corrections - Context

**Gathered:** 2026-05-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix all staff operational screens to display correct data, support proper filters, search, and CRUD operations. Covers: Dashboard navigation with pre-applied filters, Agendamentos card redesign + search + confirm fix, Chats tab navigation with student identification, Intervenção visual patterns (drawer/search/concluídos tab), Documentos state tabs + type filter + detail view, Recursos toggle/delete, and new Cadastro de Alunos CRUD screen. This is correction/improvement of existing staff screens — no new backend endpoints unless absolutely required for data display.

</domain>

<decisions>
## Implementation Decisions

### Navigation Structure

- **D-01:** Tab "Intervenção" no bottom nav renomeada para "Chats" — conceito mais amplo que engloba conversas normais + intervenção humana
- **D-02:** Dentro da tela "Chats": sub-tabs (Todos, Pendentes, Em atendimento, Concluídos) para organizar diferentes estados
- **D-03:** Bottom nav mantém 5 tabs: Painel, Agenda, **Chats**, Docs, Recursos
- **D-04:** Cadastro de Alunos acessível via seção "Ações Rápidas" no Dashboard (abaixo dos KPIs), não como tab no bottom nav
- **D-05:** Rota do Cadastro: `/staff/cadastro` como push route a partir do Dashboard

### Dashboard (SFUX-01, SFUX-02, SFUX-03)

- **D-06:** Taxa de resolução automatizada — truncar casas decimais (ex: 95.3%, não 95.33333%)
- **D-07:** Cards KPI são clicáveis e navegam usando **query params na rota** para pré-aplicar filtros
- **D-08:** "Docs pendentes" → navega `/staff/documents?filter=pendentes`
- **D-09:** "Chats hoje" → navega `/staff/chats?filter=hoje`
- **D-10:** Seção "Ações Rápidas" abaixo do grid de KPIs com botão "Gerenciar Alunos" que navega para `/staff/cadastro`

### Search & Filter Pattern

- **D-11:** SearchBar fixa no topo de cada tela que precisa de busca — sempre visível, posicionada abaixo do AppBar e acima dos filter tabs/pills
- **D-12:** SearchBar com ícone de lupa e hint text específico por tela (ex: "Buscar por nome ou RA...")
- **D-13:** Busca client-side (filtra lista já carregada) — sem chamada extra à API
- **D-14:** Pattern consistente: SearchBar → Filter Pills → Lista de resultados

### Agendamentos (SFUX-04, SFUX-05, SFUX-06, SFUX-07)

- **D-15:** Card reformulado: CircularAvatar com inicial do aluno + Nome do aluno (título) + Recurso reservado (subtítulo) + data/hora + status badge
- **D-16:** Field "motivo" removido do card (mantido apenas na tela de detalhe)
- **D-17:** Tela de detalhe existente (`StaffAppointmentDetailScreen`) corrigida — campos: Nome, RA, data emissão, recurso, status, motivo
- **D-18:** Ação "Confirmar" fix — garantir que o endpoint correto é chamado e estado atualiza
- **D-19:** SearchBar no topo busca por RA ou nome de aluno (search unificado)

### Chats (SFUX-08, SFUX-09, SFUX-10)

- **D-20:** Tab "Chats" no bottom nav substitui "Intervenção" — mesma posição no nav
- **D-21:** Sub-tabs internas: Todos | Pendentes (intervenção) | Em atendimento | Concluídos
- **D-22:** Card de chat mostra: nome do aluno + número formatado (ex: "(11) 99999-1234")
- **D-23:** Ao entrar no chat: header informativo com nome do aluno, RA, e dados da sessão (data início, status)

### Intervenção (SFUX-11, SFUX-12, SFUX-13)

- **D-24:** Intervenção agora é uma sub-tab dentro de "Chats" (Pendentes = aguardando intervenção, Em atendimento = staff assumiu)
- **D-25:** Tab "Concluídos" adicionada para histórico de intervenções resolvidas
- **D-26:** SearchBar no topo busca por Nome/RA/Telefone (search unificado)
- **D-27:** Visual segue padrão existente: GlassCard + bottom sheet para detalhes (padrão "drawer" do projeto = bottom sheet)

### Documentos (SFUX-14, SFUX-15, SFUX-16, SFUX-17, SFUX-18)

- **D-28:** Filter tabs corrigidas para: Todos | Processando | Prontos (renomear/reorganizar pills existentes)
- **D-29:** Filtro adicional por tipo de documento (segunda linha de filter pills ou dropdown)
- **D-30:** Tap no card abre visualização completa dos dados da solicitação via bottom sheet (padrão `showDocumentDetailSheet` do Phase 18)
- **D-31:** Bottom sheet de adicionar/editar segue mesmo padrão drawer (consistente com Phase 18)
- **D-32:** Mensagem de erro clara (SnackBar com `colors.error`) quando staff tenta finalizar sem arquivo anexado

### Recursos (SFUX-19, SFUX-20)

- **D-33:** Toggle ativar/desativar com feedback visual correto — Switch widget ou ícone que muda estado com confirmação
- **D-34:** Opção "Deletar" adicionada ao PopupMenu (3 pontos) dos cards de recurso, com dialog de confirmação

### Cadastro de Alunos (SFUX-21, SFUX-22, SFUX-23, SFUX-24, SFUX-25)

- **D-35:** Tela CRUD completa — nova screen `StaffCadastroScreen` em `/staff/cadastro`
- **D-36:** Lista de alunos como GlassCards com menu 3 pontos (PopupMenu: Editar, Excluir, Ativar/Desativar) + indicador visual de estado (dot verde/vermelho)
- **D-37:** FAB (FloatingActionButton) com ícone "+" para adicionar aluno — abre bottom sheet com formulário
- **D-38:** Card expansível (ExpansionTile ou similar dentro do GlassCard) mostra informações pessoais ao expandir
- **D-39:** SearchBar unificada no topo — busca simultaneamente em nome, RA e número
- **D-40:** Filter pills de estado: Todos | Ativos | Inativos

### Agent's Discretion

- Loading skeletons/shimmer durante fetch em telas corrigidas
- Empty state text e ícones específicos por tela
- Exact spacing, padding, typography das novas seções
- Animações de transição entre tabs
- Formatação exata do número de telefone (máscara)
- Design específico da seção "Ações Rápidas" no dashboard (botões vs cards vs chips)

</decisions>

<canonical_refs>

## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Staff API Contract

- `docs/api.md` §Staff/CRM — `GET /staff/dashboard` response shape, KPI fields
- `docs/api.md` §Scheduling — `GET /appointments`, `PUT /appointments/{id}/confirm`, `PUT /appointments/{id}/cancel`
- `docs/api.md` §Documents — `GET /documents`, `PUT /documents/{id}/status`
- `docs/api.md` §Chatbot — `GET /chat-sessions`, `GET /chat-sessions/{id}/messages`
- `docs/api.md` §Students — `GET /students`, `POST /students`, `PUT /students/{id}`, `DELETE /students/{id}`

### App Feature Specs

- `docs/app.md` §Perfil: Fornecedor — Staff screen specs (Dashboard CRM, Agenda, Chat Oversight, Documentos)

### Prior Phase Decisions

- `.planning/phases/09-staff-interface/09-CONTEXT.md` — Original staff interface decisions, patterns established
- `.planning/phases/08-client-interface/08-CONTEXT.md` — Client data layer pattern, filter chips, bottom sheets

### Phase 18 Patterns (Parallel Correction Phase)

- Phase 18 STATE.md entries: `showDocumentDetailSheet` pattern, `_DetailRow` for key-value display, `GlassCard.onLongPress`, `documentAutoOpenDrawerProvider` pattern

### Database Schema

- `docs/database.md` — Schema for students, appointments, documents, chat_sessions, scheduling_slots

</canonical_refs>

<code_context>

## Existing Code Insights

### Reusable Assets

- **StaffShell** (`mobile/lib/features/staff/screens/staff_shell.dart`): 5-tab nav — needs tab rename from "Intervenção" to "Chats"
- **StaffDashboardScreen** (`mobile/lib/features/staff/screens/staff_dashboard_screen.dart`): KPI grid — needs "Ações Rápidas" section added below
- **StaffScheduleScreen** (`mobile/lib/features/staff/screens/staff_schedule_screen.dart`): Filter tabs + card list — needs card fields corrected + SearchBar added
- **StaffAppointmentDetailScreen** (`mobile/lib/features/staff/screens/staff_appointment_detail_screen.dart`): Detail view — needs fields corrected
- **StaffInterventionScreen** (`mobile/lib/features/staff/screens/staff_intervention_screen.dart`): 2 tabs — will be merged into "Chats" screen
- **StaffDocumentsScreen** (`mobile/lib/features/staff/screens/staff_documents_screen.dart`): Filter tabs — needs tab values corrected + type filter + detail sheet
- **StaffResourcesScreen** (`mobile/lib/features/staff/screens/staff_resources_screen.dart`): PopupMenu — needs "Deletar" option + toggle fix
- **GlassCard** (`mobile/lib/shared/widgets/glass_card.dart`): Shared card widget — reuse for Cadastro
- **showDocumentDetailSheet** (Phase 18 pattern): Bottom sheet with `_DetailRow` for key-value display — reuse for all detail views
- **Filter tabs** (`_FilterTab` pattern): Copied per screen — reuse/extract for SearchBar consistency

### Established Patterns

- **Data layer**: Service (DioClient) → Provider (@riverpod) → Screen (ConsumerWidget)
- **Filter state**: Notifier class with `setFilter(String?)` method
- **Bottom sheets**: `showModalBottomSheet` with `isScrollControlled: true, useSafeArea: true`
- **Status badges**: Colored Container with borderRadius, dynamic color by status string
- **FAB**: FloatingActionButton with Icon(Icons.add) for create actions
- **Pull-to-refresh**: RefreshIndicator with `ref.invalidate(provider)`
- **Confirmation dialogs**: `showDialog<bool>` with AlertDialog for destructive actions
- **Responsive**: AppBreakpoints.isPhone/isTablet/isDesktop

### Integration Points

- **Router** (`mobile/lib/core/router/app_router.dart`): Add `/staff/cadastro` route, add query param support to existing routes
- **StaffShell**: Rename tab label and icon for Intervenção → Chats
- **StaffInterventionScreen**: Merge into new unified "Chats" screen with sub-tabs
- **StaffAiScreen**: Sessions list from AI screen may merge into Chats "Todos" tab
- **Models**: May need `StudentModel` in staff feature for Cadastro (or reuse from client)

</code_context>

<specifics>
## Specific Ideas

- "Drawer" no vocabulário deste projeto = bottom sheet (padrão Phase 18 `showDocumentDetailSheet`)
- Seção "Ações Rápidas" no Dashboard em vez de mais um card KPI para Cadastro — separar métricas de ações
- Search unificado: um campo busca em múltiplos atributos simultaneamente (não precisa escolher "buscar por nome" vs "buscar por RA")
- Query params para filtros pré-aplicados: mantém rotas compartilháveis e independência entre telas

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

_Phase: 19-staff-ux-corrections_
_Context gathered: 2026-05-08_
