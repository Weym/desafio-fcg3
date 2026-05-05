# Phase 9: Staff Interface - Context

**Gathered:** 2026-05-04
**Status:** Ready for planning

<domain>
## Phase Boundary

All 4 staff/provider management screens are functional within the existing StaffShell (4-tab bottom nav: Dashboard, Agenda, IA, Documentos). The provider can view business KPIs, manage appointments (approve/cancel + create slots), view AI-extracted insights from WhatsApp conversations, and manage document requests with proactive document sending. Includes a small backend addition: file upload endpoint for document attachment.

</domain>

<decisions>
## Implementation Decisions

### Staff Dashboard (KPIs)

- **D-01:** Grid 2x3 de cards numéricos — cada KPI com ícone, número grande e label descritivo. Dados: total_students, active_enrollments, pending_documents, upcoming_appointments, active_chat_sessions.
- **D-02:** Banner/card especial no topo para enrollment_period ativo — nome do período, badge "Ativo", dias restantes em destaque.
- **D-03:** Tap no card navega para a tab correspondente (ex: tap no card de documentos pendentes vai para tab Documentos, agendamentos vai para Agenda).
- **D-04:** Pull-to-refresh para recarregar todos os KPIs.
- **D-05:** Sem saudação personalizada — AppBar com "Dashboard" e direto aos dados (sem "Olá, {nome}").

### Controle de Agenda

- **D-06:** Lista cronológica de agendamentos em cards (data, nome do aluno, horário, motivo, status). Filter chips no topo: "Todos", "Agendados", "Cancelados".
- **D-07:** Tap no card abre tela de detalhe dedicada com informações completas + botões de ação (Confirmar, Cancelar). Confirmação via dialog antes de executar.
- **D-08:** FAB (FloatingActionButton) que abre bottom sheet para criar slots de disponibilidade. Formulário: data, hora início, hora fim, duração do slot em minutos.
- **D-09:** Pattern de filter chips reutilizado do client documents (toggle behavior — tap em chip ativo reseta para "Todos").

### Dados/Insights da IA

- **D-10:** Duas tabs no topo da tela: "Sessões" (lista de chat sessions) e "Estatísticas" (métricas agregadas).
- **D-11:** Tab Sessões: cards com nome do aluno, data, status (ativo/fechado), preview da última mensagem, badge com contagem de ações executadas pelo bot naquela sessão.
- **D-12:** Tab Estatísticas: contadores simples com números grandes — total de sessões, ações com sucesso, ações com erro, top 3 tools mais usadas. Sem gráficos/charts (evita dependência extra).
- **D-13:** Tap numa sessão abre detalhe reutilizando o mesmo layout do client: mensagens em bolhas (WhatsApp-style) + sub-tab de action logs expandíveis.

### Gestão de Documentos

- **D-14:** Lista de todos documentos com filter chips (Todos, Pendentes, Processando, Prontos). Cada card mostra: nome do aluno, tipo do documento, data de solicitação, chip colorido de status.
- **D-15:** Tap no card abre bottom sheet para atualizar status (dropdown de status + campo file_url condicional). O campo de upload (file picker) só aparece quando status selecionado = "ready".
- **D-16:** File picker real com upload para endpoint `POST /documents/upload` no backend — retorna URL do arquivo. Exceção assumida ao "no backend changes" para viabilizar o fluxo real.
- **D-17:** Criação proativa de documentos via FAB — bottom sheet com formulário: busca de aluno por nome (autocomplete via GET /students) + tipo do documento + file picker para anexar. Cria documento já com status "ready".
- **D-18:** Envio em massa por grupo: além de enviar para aluno individual, staff pode selecionar turma/período e enviar o mesmo documento para todos os alunos do grupo.
- **D-19:** Pull-to-refresh na lista de documentos.

### Backend Additions (exceção ao "no backend changes")

- **D-20:** Endpoint `POST /documents/upload` — recebe arquivo, salva em storage, retorna URL. Necessário para file picker real.
- **D-21:** Suporte a envio em massa no backend (batch create de documentos por grupo/turma) ou loop no frontend sobre criações individuais — decisão de implementação para o planner.

### Agent's Discretion

- Loading skeletons/shimmer para cada tela durante fetch
- Empty state designs por tela
- Exact card dimensions, spacing, border radius
- Dialog de confirmação design para ações destrutivas (cancelar agendamento)
- Autocomplete widget library choice para busca de alunos
- Storage solution para upload de arquivos (local filesystem, S3, etc)
- Pagination vs infinite scroll para listas longas

</decisions>

<canonical_refs>

## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Staff API Contract

- `docs/api.md` §Staff/CRM — `GET /staff/dashboard` response shape (KPIs), `GET /staff/enrollment-periods`, `POST /staff/enrollment-periods`, `PUT /staff/enrollment-periods/{id}`
- `docs/api.md` §Scheduling — `GET /scheduling/slots`, `POST /scheduling/slots`, `GET /appointments`, `PUT /appointments/{id}/cancel`
- `docs/api.md` §Documents — `GET /documents`, `PUT /documents/{id}/status` (request shape with status + file_url)
- `docs/api.md` §Chatbot — `GET /chat-sessions` (staff auth, query by student_id/status), `GET /chat-sessions/{id}/messages`, `GET /chat-sessions/{id}/action-logs`

### App Feature Specs

- `docs/app.md` §Perfil: Fornecedor — Staff screen specs (Dashboard CRM, Agenda, Chat Oversight, Documentos)

### Phase 7 Decisions (Foundation)

- `.planning/phases/07-flutter-scaffold-auth/07-CONTEXT.md` — Riverpod (D-01/D-02), GoRouter (D-03), StaffShell with 4 tabs (D-05), feature-first folders (D-12), Dio + interceptors (D-13), json_serializable (D-14), service classes pattern (D-17)

### Phase 8 Patterns (Reference)

- `.planning/phases/08-client-interface/08-CONTEXT.md` — Data layer pattern (models → services → providers → screens), filter chips toggle behavior, bottom sheets for forms, chat detail layout with tabs (D-06 through D-09)

### Database Schema

- `docs/database.md` — Schema for appointments, scheduling_slots, documents, chat_sessions, chat_messages, mcp_action_logs, students tables

### Architecture

- `docs/architecture.md` — System topology, Docker setup, service communication

</canonical_refs>

<code_context>

## Existing Code Insights

### Reusable Assets

- **StaffShell** (`mobile/lib/features/staff/screens/staff_shell.dart`): 4-tab BottomNavigationBar already wired with GoRouter navigation. Ready to use.
- **StaffHomeScreen** (`mobile/lib/features/staff/screens/staff_home_screen.dart`): Placeholder with auth state access pattern. Will be replaced with real dashboard.
- **DioClient** (`mobile/lib/core/network/dio_client.dart`): Configured HTTP client with auth interceptor. All staff services will use this.
- **AppTheme** (`mobile/lib/core/theme/app_theme.dart`): Material 3 theme with rounded borders, filled inputs, snackbars.
- **Client data layer pattern** (`mobile/lib/features/client/`): Full reference implementation with models, services, providers, and screens — replicate this structure for staff.
- **AppointmentModel** (`mobile/lib/features/client/models/appointment_model.dart`): May be partially reusable for staff appointments view.
- **ChatSessionModel / ChatMessageModel / ActionLogModel** (`mobile/lib/features/client/models/`): Reusable as-is for staff AI data screen (same API endpoints).
- **ClientChatDetailScreen** (`mobile/lib/features/client/screens/client_chat_detail_screen.dart`): Reference for session detail layout (bubbles + action logs tabs).
- **DocumentModel** (`mobile/lib/features/client/models/document_model.dart`): Reusable for staff document list.

### Established Patterns

- **State management**: Riverpod with `@riverpod` annotations + code gen. ConsumerWidget for reactive UI.
- **Service layer**: Service classes per feature using DioClient, exposed via Riverpod providers.
- **Models**: @JsonSerializable() with `part '*.g.dart'`.
- **Filter chips**: Toggle behavior (tap active chip resets to null/Todos).
- **Bottom sheets**: Used for forms (document request in client).
- **Chat detail**: ConsumerStatefulWidget with SingleTickerProviderStateMixin for TabController.

### Integration Points

- **Router** (`mobile/lib/core/router/app_router.dart`): 3 staff routes currently use `_PlaceholderScreen` — must be replaced with real screen widgets. Sub-routes (e.g., `/staff/schedule/:appointmentId`) needed for detail screens.
- **Route names** (`mobile/lib/core/router/route_names.dart`): All staff paths defined (staffDashboard, staffSchedule, staffAI, staffDocuments).
- **Client models**: ChatSessionModel, ChatMessageModel, ActionLogModel, DocumentModel, AppointmentModel can be moved to a shared location or imported cross-feature.

</code_context>

<specifics>
## Specific Ideas

- Staff dashboard is data-dense and action-oriented — no greeting, no fluff, straight to KPIs with navigation shortcuts.
- Agenda detail screen (not inline actions) prevents accidental taps on confirm/cancel — deliberate action required.
- AI screen reuses client chat detail layout for consistency — staff sees the same conversation view the student sees, plus the action logs overlay.
- Document management supports both reactive (managing student requests) and proactive (staff pushing documents to students) workflows.
- Bulk document sending by class/period is a key differentiator for staff workflow efficiency.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

_Phase: 09-staff-interface_
_Context gathered: 2026-05-04_
