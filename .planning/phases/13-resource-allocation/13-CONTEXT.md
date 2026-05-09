# Phase 13: Resource Allocation - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Implementar sistema completo de alocação de recursos no frontend e backend: gestor cadastra recursos (CRUD com flag de autorização), define horários de disponibilidade, visualiza e gerencia agendamentos. Aluno visualiza recursos disponíveis, agenda horários (com upload de autorização quando exigido), e gerencia seus agendamentos.

O backend já possui models (Resource, SchedulingSlot, Appointment), migrations, services com locking, e 5 endpoints. Esta fase EXPANDE o sistema existente com: novos tipos de recurso, flag `requires_authorization`, endpoint de upload de autorização, CRUD de recursos para staff, e telas dedicadas no frontend.

</domain>

<decisions>
## Implementation Decisions

### Recursos - Backend

- **D-01:** Expandir `resource_type` CHECK constraint para incluir: `room`, `lab`, `equipment`, `auditorium`, `study_room`, `sports_court`.
- **D-02:** Adicionar campo `requires_authorization` (boolean, default false) ao model `Resource`.
- **D-03:** Adicionar campo `description` (Text, nullable) ao model `Resource`.
- **D-04:** Criar endpoints CRUD de recursos para staff: `GET /resources`, `POST /resources`, `PUT /resources/{id}`, `DELETE /resources/{id}`.
- **D-05:** O endpoint `DELETE` faz soft-delete (marca `is_available = false`) — não remove fisicamente.

### Recursos - Aluno (Agendamento)

- **D-06:** Aluno vê lista de recursos disponíveis com filtro por tipo.
- **D-07:** Ao agendar, se recurso exige autorização (`requires_authorization = true`), aluno DEVE fazer upload de PDF/imagem.
- **D-08:** Upload de autorização: aceitar PDF, JPG, PNG. Limite de tamanho: 5MB.
- **D-09:** Adicionar campo `authorization_file_url` (String, nullable) ao model `Appointment`.
- **D-10:** Endpoint de upload: `POST /appointments/{id}/authorization` (multipart/form-data).
- **D-11:** Aluno pode visualizar seus agendamentos e cancelar agendamentos futuros (já existente via `PUT /appointments/{id}/cancel`).

### Recursos - Gestor

- **D-12:** Gestor vê todos os agendamentos de todos os recursos com filtros (por recurso, por data, por status).
- **D-13:** Gestor pode cancelar/bloquear qualquer agendamento.
- **D-14:** Gestor define horários de disponibilidade ao criar slots (já existente via `POST /scheduling/slots`).
- **D-15:** Tela de gestão de recursos é separada da tela de agenda (nova tela "Recursos").

### Frontend

- **D-16:** Nova tela "Recursos" no staff shell (5ª tab ou sub-rota da agenda).
- **D-17:** Nova tela "Recursos" no client shell (substituir ou complementar a tela de agendamentos existente).
- **D-18:** Upload de autorização usa `file_picker` (já na pubspec) + multipart upload via Dio.
- **D-19:** Indicação visual clara quando recurso exige autorização (badge/icon na listagem).

### Agent's Discretion

- Organização interna dos novos endpoints (novo router ou extensão do scheduling_router)
- Estrutura de diretórios para models/schemas de resources no backend
- Design visual dos cards de recursos no mobile (seguir padrão glass card)

</decisions>

<canonical_refs>

## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Backend (Source of truth)
- `backend/src/features/scheduling/models.py` — Models existentes: Resource, SchedulingSlot, Appointment
- `backend/src/features/appointments/schemas.py` — Pydantic schemas para slots e appointments
- `backend/src/features/appointments/services.py` — Services com locking e IDOR protection
- `backend/src/features/appointments/controllers.py` — Routes registradas

### Database
- `docs/database.md` — Schema documentado (tabelas resources, scheduling_slots, appointments)
- `backend/alembic/versions/005_create_documents_scheduling_tables.py` — Migration atual

### API
- `docs/api.md` §Scheduling — Endpoints GET /scheduling/slots, POST /scheduling/slots, POST /appointments, GET /appointments, PUT /appointments/{id}/cancel

### Mobile
- `mobile/lib/features/client/models/appointment_model.dart` — Model Dart existente
- `mobile/lib/features/staff/screens/staff_schedule_screen.dart` — Tela staff atual
- `mobile/lib/features/staff/screens/widgets/create_slot_sheet.dart` — Bottom sheet de criar slot

</canonical_refs>

<code_context>

## Existing Code Insights

### Reusable Assets

- `Resource` model já existe com campos: name, resource_type, capacity, location, is_available
- `SchedulingSlot` + `Appointment` models com relacionamentos configurados
- `SlotService.create_slots()` já gera slots com overlap check e pessimistic locking
- `AppointmentService` já tem book/cancel com SELECT FOR UPDATE
- `file_picker` já está no pubspec.yaml do Flutter
- `StaffDocumentService` já faz multipart upload (padrão reutilizável)
- GlassCard, segmented filters, FAB pattern já estabelecidos no frontend

### Established Patterns

- Staff services usam `DioClient` injetado via Riverpod
- Upload usa `FormData.fromMap` + `MultipartFile` (ver staff_document_service.dart)
- Backend: `SELECT FOR UPDATE` para concorrência em slots
- Frontend: Segmented filter + lista com pull-to-refresh + FAB

### Integration Points

- Backend: novo router para resources CRUD + extensão do appointments router
- Frontend staff: nova tela "Recursos" no shell (ou sub-tab)
- Frontend client: tela de agendamentos expandida com seleção de recurso + upload
- Alembic: nova migration para adicionar campos (requires_authorization, description, authorization_file_url)

</code_context>

<specifics>
## Specific Ideas

- O gestor marca se recurso precisa de autorização na hora de cadastrar
- No card do recurso para o aluno, mostrar badge "Requer Autorização" quando aplicável
- O aluno só consegue confirmar agendamento em recurso com autorização APÓS enviar o documento
- Tipos de recurso: laboratório, auditório, sala de estudos, quadra esportiva, sala, equipamento
- Limite de upload: 5MB (PDF, JPG, PNG)

</specifics>

<deferred>
## Deferred Ideas

- Aprovação manual de autorizações pelo gestor (por agora, enviar = aprovado)
- Notificação push quando agendamento é confirmado/cancelado
- Calendário visual de disponibilidade (grid semanal)
- Relatórios de uso de recursos
- Fase 14: Intervenção Humana (branch separada)

</deferred>

---

_Phase: 13-resource-allocation_
_Context gathered: 2026-05-06_
