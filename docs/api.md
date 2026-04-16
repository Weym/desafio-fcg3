# API - Endpoints

## Convencoes

| Item         | Valor                                        |
| ------------ | -------------------------------------------- |
| Base URL     | `http://localhost:8000/api/v1`               |
| Formato      | JSON                                         |
| Autenticacao | Bearer Token (JWT) no header `Authorization` |
| Paginacao    | `?page=1&per_page=20`                        |
| Ordenacao    | `?sort_by=created_at&order=desc`             |

### Autenticacao

O sistema possui dois mecanismos de autenticacao:

| Tipo              | Header                                 | Usado por                            |
| ----------------- | -------------------------------------- | ------------------------------------ |
| **JWT Bearer**    | `Authorization: Bearer {token}`        | App Flutter, chamadas do aluno/staff |
| **Service Token** | `X-Service-Token: {MCP_SERVICE_TOKEN}` | MCP Server (chamadas internas)       |

Endpoints acessiveis pelo MCP sao marcados com **(aceita X-Service-Token)**.
O token vive como variavel de ambiente e nunca entra no codigo-fonte.

### Formato de Erro Padrao

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Descricao legivel do erro",
    "details": [{ "field": "email", "message": "Email invalido" }]
  }
}
```

### Codigos HTTP

| Codigo | Uso                                           |
| ------ | --------------------------------------------- |
| 200    | Sucesso                                       |
| 201    | Criado                                        |
| 400    | Erro de validacao                             |
| 401    | Nao autenticado                               |
| 403    | Sem permissao                                 |
| 404    | Nao encontrado                                |
| 409    | Conflito (ex: matricula duplicada)            |
| 422    | Entidade nao processavel                      |
| 429    | Limite de tentativas atingido (rate limiting) |
| 500    | Erro interno                                  |

---

## Auth

### `POST /auth/request-code`

Solicita codigo de verificacao por email ou SMS.

**Request:**

```json
{
  "email": "aluno@universidade.edu",
  "channel": "email"
}
```

**Response (200):**

```json
{
  "message": "Codigo enviado para aluno@universidade.edu",
  "expires_in": 300
}
```

---

### `POST /auth/verify-code`

Valida o codigo e retorna token JWT.
O aluno tem **3 tentativas**. Ao esgotar, o codigo atual e invalidado e um novo e enviado automaticamente.

**Request:**

```json
{
  "email": "aluno@universidade.edu",
  "code": "123456",
  "platform": "app"
}
```

**Response (200):**

```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "uuid",
    "name": "Joao Silva",
    "type": "student",
    "email": "aluno@universidade.edu"
  },
  "expires_at": "2025-04-14T10:00:00Z"
}
```

**Response (401) — codigo invalido:**

```json
{
  "error": {
    "code": "INVALID_CODE",
    "message": "Codigo invalido.",
    "details": [{ "field": "attempts_remaining", "message": "2" }]
  }
}
```

**Response (429) — tentativas esgotadas:**

```json
{
  "error": {
    "code": "MAX_ATTEMPTS_REACHED",
    "message": "Limite de tentativas atingido. Um novo codigo foi enviado para seu email."
  }
}
```

---

### `POST /auth/logout`

Invalida a sessao atual. **Requer autenticacao.**

**Response (200):**

```json
{ "message": "Sessao encerrada" }
```

---

### `GET /auth/me`

Retorna dados do usuario autenticado. **Requer autenticacao.**

**Response (200):**

```json
{
  "id": "uuid",
  "name": "Joao Silva",
  "type": "student",
  "email": "aluno@universidade.edu",
  "phone": "+5521999999999"
}
```

---

## Students

### `GET /students`

Lista alunos. **Requer autenticacao (staff).**

**Query params:** `?search=joao&semester=3&status=active&page=1&per_page=20`

**Response (200):**

```json
{
  "data": [
    {
      "id": "uuid",
      "name": "Joao Silva",
      "email": "joao@universidade.edu",
      "registration_number": "2024001",
      "semester": 3,
      "status": "active"
    }
  ],
  "pagination": { "page": 1, "per_page": 20, "total": 150 }
}
```

---

### `GET /students/{id}`

Detalhe do aluno. **Requer autenticacao.**

---

### `POST /students`

Cria aluno. **Requer autenticacao (staff).**

**Request:**

```json
{
  "name": "Joao Silva",
  "email": "joao@universidade.edu",
  "phone": "+5521999999999",
  "registration_number": "2024001",
  "curriculum_id": "uuid"
}
```

---

### `PUT /students/{id}`

Atualiza aluno. **Requer autenticacao (staff).**

---

### `DELETE /students/{id}`

Remove aluno (soft delete). **Requer autenticacao (staff).**

---

### `GET /students/{id}/academic-summary`

Resumo academico do aluno. **Requer autenticacao. Aceita X-Service-Token (MCP).**

**Response (200):**

```json
{
  "student_id": "uuid",
  "name": "Joao Silva",
  "semester": 3,
  "completed_courses": 12,
  "total_courses": 40,
  "gpa": 7.8,
  "status": "active",
  "pending_documents": 1,
  "next_appointment": null
}
```

---

### `GET /students/{id}/grades`

Notas do aluno. **Requer autenticacao. Aceita X-Service-Token (MCP).**

**Query params:** `?semester_year=2025.1`

**Response (200):**

```json
{
  "data": [
    {
      "id": "uuid",
      "course": { "code": "CC101", "name": "Algoritmos e Programacao" },
      "semester_year": "2025.1",
      "grade_1": 8.5,
      "grade_2": 7.0,
      "grade_final": 7.75,
      "status": "approved"
    }
  ]
}
```

---

### `GET /students/{id}/transcript`

Historico escolar completo. **Requer autenticacao. Aceita X-Service-Token (MCP).**

---

### `GET /students/{id}/available-courses`

Disciplinas disponiveis para matricula (respeita pre-requisitos). **Requer autenticacao. Aceita X-Service-Token (MCP).**

**Response (200):**

```json
{
  "data": [
    {
      "id": "uuid",
      "code": "CC201",
      "name": "Estrutura de Dados",
      "credits": 4,
      "prerequisites_met": true,
      "semester": 2
    }
  ]
}
```

---

### `PUT /students/{id}/fcm-token`

Atualiza token FCM do aluno. **Requer autenticacao (student).**

**Request:**

```json
{ "fcm_token": "eF1k2..." }
```

---

## Courses & Curriculum

### `GET /courses`

Lista disciplinas. **Requer autenticacao.**

**Query params:** `?search=algoritmo&semester=1`

---

### `GET /courses/{id}`

Detalhe da disciplina com pre-requisitos.

**Response (200):**

```json
{
  "id": "uuid",
  "code": "CC101",
  "name": "Algoritmos e Programacao",
  "credits": 4,
  "workload_hours": 60,
  "description": "Ementa da disciplina...",
  "prerequisites": [
    { "id": "uuid", "code": "CC100", "name": "Logica Matematica" }
  ]
}
```

---

### `GET /courses/{id}/prerequisites`

Arvore completa de pre-requisitos da disciplina. **Aceita X-Service-Token (MCP).**

---

### `GET /curriculum/active`

Retorna o curriculo vigente com todas as disciplinas por periodo. **Aceita X-Service-Token (MCP).**

**Response (200):**

```json
{
  "id": "uuid",
  "name": "CC 2024.1",
  "year": 2024,
  "semesters": [
    {
      "semester": 1,
      "courses": [
        {
          "id": "uuid",
          "code": "CC101",
          "name": "Algoritmos e Programacao",
          "credits": 4,
          "is_required": true
        }
      ]
    }
  ]
}
```

---

### `GET /curriculum/{id}`

Detalhe de um curriculo especifico.

---

## Enrollment (Matricula)

### `GET /enrollment-periods/current`

Retorna o periodo de matricula ativo (se houver). **Aceita X-Service-Token (MCP).**

**Response (200):**

```json
{
  "id": "uuid",
  "name": "2025.1 - Matricula",
  "type": "enrollment",
  "start_date": "2025-01-15",
  "end_date": "2025-02-15",
  "semester_year": "2025.1",
  "is_active": true
}
```

---

### `POST /enrollments`

Cria matricula (rascunho). **Requer autenticacao (student). Aceita X-Service-Token (MCP).**

**Request:**

```json
{
  "enrollment_period_id": "uuid",
  "course_ids": ["uuid1", "uuid2", "uuid3"]
}
```

**Response (201):**

```json
{
  "id": "uuid",
  "status": "draft",
  "courses": ["..."],
  "created_at": "2025-01-20T10:00:00Z"
}
```

---

### `POST /enrollments/{id}/confirm`

Confirma a matricula definitivamente (draft -> confirmed). **Requer autenticacao (student). Aceita X-Service-Token (MCP).**

**Response (200):**

```json
{
  "id": "uuid",
  "status": "confirmed",
  "confirmed_at": "2025-01-20T10:15:00Z"
}
```

**Erros possiveis:**

| Codigo | Code                           | Situacao                                        |
| ------ | ------------------------------ | ----------------------------------------------- |
| 404    | `ENROLLMENT_NOT_FOUND`         | enrollment_id invalido ou nao pertence ao aluno |
| 409    | `ENROLLMENT_PERIOD_CLOSED`     | Periodo de matricula encerrado                  |
| 409    | `ENROLLMENT_ALREADY_CONFIRMED` | Matricula ja confirmada anteriormente           |

---

### `PUT /enrollments/{id}`

Modifica disciplinas da matricula (enquanto draft). **Requer autenticacao (student).**

---

### `DELETE /enrollments/{id}/courses/{course_id}`

Remove disciplina da matricula. **Requer autenticacao (student). Aceita X-Service-Token (MCP).**

---

### `POST /enrollments/{id}/lock`

Tranca a matricula inteira. **Requer autenticacao (student). Aceita X-Service-Token (MCP).**

---

### `GET /enrollments`

Lista matriculas. **Requer autenticacao.**

**Query params:** `?student_id=uuid&semester_year=2025.1&status=confirmed`

---

## Grades (Notas)

### `PUT /grades/{id}`

Lanca/atualiza nota. **Requer autenticacao (staff).**

**Request:**

```json
{ "grade_1": 8.5, "grade_2": 7.0 }
```

---

## Documents (Documentos)

### `POST /documents`

Solicita emissao de documento. **Requer autenticacao (student). Aceita X-Service-Token (MCP).**

**Request:**

```json
{ "type": "transcript", "notes": "Preciso para estagio" }
```

**Response (201):**

```json
{
  "id": "uuid",
  "type": "transcript",
  "status": "requested",
  "requested_at": "2025-01-20T10:00:00Z"
}
```

---

### `GET /documents`

Lista documentos. **Requer autenticacao.**

**Query params:** `?student_id=uuid&type=transcript&status=ready`

---

### `GET /documents/{id}`

Detalhe do documento (inclui URL para download quando pronto). **Aceita X-Service-Token (MCP).**

---

### `PUT /documents/{id}/status`

Atualiza status do documento. **Requer autenticacao (staff).**

**Request:**

```json
{
  "status": "ready",
  "file_url": "https://storage.example.com/docs/transcript-uuid.pdf"
}
```

---

## Scheduling (Agendamentos)

### `GET /scheduling/slots`

Slots disponiveis. **Requer autenticacao. Aceita X-Service-Token (MCP).**

**Query params:** `?date_from=2025-01-20&date_to=2025-01-27&staff_id=uuid`

> Padrao quando omitidos: `date_from` = hoje, `date_to` = hoje + 7 dias.

**Response (200):**

```json
{
  "data": [
    {
      "id": "uuid",
      "staff": { "id": "uuid", "name": "Maria Coordenadora" },
      "date": "2025-01-20",
      "start_time": "10:00",
      "end_time": "10:30",
      "is_available": true
    }
  ]
}
```

---

### `POST /scheduling/slots`

Cria slots de agendamento. **Requer autenticacao (staff).**

**Request:**

```json
{
  "date": "2025-01-20",
  "start_time": "08:00",
  "end_time": "12:00",
  "slot_duration_minutes": 30
}
```

---

### `POST /appointments`

Agenda atendimento. **Requer autenticacao (student). Aceita X-Service-Token (MCP).**

**Request:**

```json
{
  "slot_id": "uuid",
  "reason": "Duvida sobre trancamento de disciplina"
}
```

---

### `GET /appointments`

Lista agendamentos. **Requer autenticacao.**

**Query params:** `?student_id=uuid&status=scheduled`

---

### `PUT /appointments/{id}/cancel`

Cancela agendamento. **Requer autenticacao. Aceita X-Service-Token (MCP).**

---

## Staff / CRM

### `GET /staff/dashboard`

Dashboard com KPIs. **Requer autenticacao (staff).**

**Response (200):**

```json
{
  "total_students": 500,
  "active_enrollments": 450,
  "pending_documents": 23,
  "upcoming_appointments": 8,
  "active_chat_sessions": 3,
  "enrollment_period": {
    "name": "2025.1",
    "is_active": true,
    "days_remaining": 12
  }
}
```

---

### `GET /staff/enrollment-periods`

Lista todos os periodos de matricula. **Requer autenticacao (staff).**

---

### `POST /staff/enrollment-periods`

Cria periodo de matricula. **Requer autenticacao (staff).**

---

### `PUT /staff/enrollment-periods/{id}`

Atualiza periodo. **Requer autenticacao (staff).**

---

## Chatbot / WhatsApp

### `POST /webhook/whatsapp`

Webhook que recebe mensagens do WhatsApp Business Cloud API. **Sem autenticacao (validado por X-Hub-Signature-256).**

**Request (do WhatsApp):**

```json
{
  "object": "whatsapp_business_account",
  "entry": [
    {
      "changes": [
        {
          "value": {
            "messages": [
              {
                "from": "5521999999999",
                "type": "text",
                "text": { "body": "Quais sao minhas notas?" }
              }
            ]
          }
        }
      ]
    }
  ]
}
```

---

### `GET /webhook/whatsapp`

Verificacao do webhook (challenge do WhatsApp). **Sem autenticacao.**

---

### `GET /chat-sessions`

Lista sessoes de chat. **Requer autenticacao (staff).**

**Query params:** `?student_id=uuid&status=active`

---

### `GET /chat-sessions/{id}/messages`

Mensagens de uma sessao. **Requer autenticacao.**

---

### `GET /chat-sessions/{id}/action-logs`

Logs MCP de uma sessao. **Requer autenticacao (staff).**

---

## Notificacoes

### `POST /notifications/send`

Envia notificacao push via FCM. **Requer autenticacao (staff) ou chamada interna.**

**Request:**

```json
{
  "student_id": "uuid",
  "title": "Documento Pronto",
  "body": "Seu historico escolar esta disponivel para download.",
  "data": {
    "type": "document_ready",
    "document_id": "uuid"
  }
}
```

---

## Mapeamento MCP Tool -> API Endpoint

| MCP Tool                   | Metodo | Endpoint                           | Descricao               |
| -------------------------- | ------ | ---------------------------------- | ----------------------- |
| `get_student_info`         | GET    | `/students/{id}/academic-summary`  | Resumo academico        |
| `get_grades`               | GET    | `/students/{id}/grades`            | Notas do aluno          |
| `get_transcript`           | GET    | `/students/{id}/transcript`        | Historico escolar       |
| `get_available_courses`    | GET    | `/students/{id}/available-courses` | Disciplinas disponiveis |
| `create_enrollment`        | POST   | `/enrollments`                     | Cria matricula (draft)  |
| `confirm_enrollment`       | POST   | `/enrollments/{id}/confirm`        | Confirma matricula      |
| `drop_course`              | DELETE | `/enrollments/{id}/courses/{cid}`  | Remove disciplina       |
| `lock_enrollment`          | POST   | `/enrollments/{id}/lock`           | Tranca matricula        |
| `request_document`         | POST   | `/documents`                       | Solicita documento      |
| `get_document_status`      | GET    | `/documents/{id}`                  | Status do documento     |
| `get_available_slots`      | GET    | `/scheduling/slots`                | Horarios disponiveis    |
| `book_appointment`         | POST   | `/appointments`                    | Agendar atendimento     |
| `cancel_appointment`       | PUT    | `/appointments/{id}/cancel`        | Cancelar agendamento    |
| `get_curriculum`           | GET    | `/curriculum/active`               | Grade curricular        |
| `get_course_prerequisites` | GET    | `/courses/{id}/prerequisites`      | Pre-requisitos          |
| `get_enrollment_period`    | GET    | `/enrollment-periods/current`      | Periodo de matricula    |
