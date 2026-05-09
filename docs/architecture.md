# Arquitetura do Sistema

## Visao Geral

Sistema academico para o curso de Ciencia da Computacao (8 periodos) composto por:

- **Chatbot WhatsApp** com IA (LangChain + RAG) para atendimento de secretaria
- **App Flutter** (Mobile/Web) para Cliente e Fornecedor
- **API Backend** (FastAPI) como camada central
- **PostgreSQL** + PGVector para persistencia relacional e RAG
- **Firebase Cloud Messaging (FCM)** para notificacoes push e sincronizacao em tempo real

---

## Diagrama de Contexto (C4 - Level 1)

```mermaid
C4Context
    title Sistema Academico - Diagrama de Contexto

    Person(cliente, "Cliente (Aluno)", "Interage via WhatsApp e App Flutter")
    Person(fornecedor, "Fornecedor (Staff)", "Gerencia via App Flutter (CRM)")

    System(sistema, "Sistema Academico", "Plataforma de atendimento academico com IA")

    System_Ext(whatsapp, "WhatsApp Business Cloud API", "Canal de comunicacao do chatbot")
    System_Ext(fcm, "Firebase Cloud Messaging", "Notificacoes push e sincronizacao em tempo real")

    Rel(cliente, whatsapp, "Envia mensagens")
    Rel(whatsapp, sistema, "Webhook / Cloud API")
    Rel(cliente, sistema, "Usa App Flutter")
    Rel(fornecedor, sistema, "Usa App Flutter (CRM)")
    Rel(sistema, fcm, "Envia notificacoes de eventos")
    Rel(fcm, cliente, "Push notifications (< 2s)")
```

---

## Diagrama de Containers (C4 - Level 2)

```mermaid
C4Container
    title Sistema Academico - Diagrama de Containers

    Person(cliente, "Aluno", "Usa WhatsApp e App Flutter")
    Person(fornecedor, "Staff", "Usa App Flutter (CRM)")

    System_Ext(whatsapp, "WhatsApp Business Cloud API", "Mensagens e webhook")
    System_Ext(fcm, "Firebase Cloud Messaging", "Push notifications")

    Container_Boundary(sistema, "Sistema Academico") {
        Container(app_cli, "App Flutter (Cliente)", "Flutter", "Historico de chat, tracker de acoes, documentos, notificacoes")
        Container(app_forn, "App Flutter (Fornecedor)", "Flutter", "Dashboard CRM, agenda, gestao de atendimentos")

        Container(api, "FastAPI", "Python 3.12", "API REST central. Orquestra IA, persiste dados, envia FCM")
        Container(ai_svc, "LangChain Service", "Python 3.12", "Agente ReAct com RAG e MCP tools")
        Container(mcp, "MCP Server", "Python 3.12", "Tool calling com logging automatico de acoes")

        ContainerDb(pg, "PostgreSQL + PGVector", "postgres:16 + pgvector", "Dados relacionais e embeddings RAG na mesma instancia")
    }

    Rel(cliente, app_cli, "Usa", "Mobile/Web")
    Rel(fornecedor, app_forn, "Usa", "Mobile/Web")

    Rel(cliente, whatsapp, "Envia mensagem")
    Rel(whatsapp, api, "POST /webhook/whatsapp", "HTTPS")

    Rel(app_cli, api, "REST", "HTTPS + JWT")
    Rel(app_forn, api, "REST", "HTTPS + JWT")

    Rel(api, ai_svc, "Dispatch async task", "HTTP interno")
    Rel(ai_svc, mcp, "Chama tools", "MCP Protocol")
    Rel(mcp, api, "Chamadas internas", "HTTP interno + Service Token")

    Rel(api, pg, "CRUD + Embeddings", "SQL / pgvector")
    Rel(ai_svc, pg, "Similarity search (RAG)", "pgvector")
    Rel(mcp, pg, "Log de acoes", "SQL")

    Rel(api, fcm, "Push de eventos", "HTTPS")
    Rel(fcm, app_cli, "Notificacao push", "< 2s")
    Rel(api, whatsapp, "Envia resposta ao aluno", "HTTPS")
```

---

## Diagrama de Componentes

```mermaid
graph TB
    subgraph "Frontend"
        APP_CLI[App Flutter - Cliente]
        APP_FORN[App Flutter - Fornecedor]
    end

    subgraph "WhatsApp"
        WA_API[WhatsApp Business Cloud API]
    end

    subgraph "Backend"
        API[FastAPI - API REST]
        AI[Servico IA - LangChain Agent]
        MCP[MCP Server - Tools + Logging]
    end

    subgraph "Dados"
        PG[(PostgreSQL + PGVector)]
    end

    subgraph "Servicos Externos"
        FCM[Firebase Cloud Messaging]
    end

    WA_API -->|Webhook| API
    API -->|Resposta assincrona| WA_API
    APP_CLI -->|REST| API
    APP_FORN -->|REST| API

    API -->|asyncio.create_task| AI
    AI -->|Tools via MCP| MCP
    MCP -->|Chamadas internas + Service Token| API
    MCP -->|Log de acoes| PG

    AI -->|Similarity search RAG| PG
    API -->|CRUD + pgvector| PG

    API -->|Push evento| FCM
    FCM -->|Notificacao < 2s| APP_CLI
```

---

## Fluxo de Mensagem WhatsApp (Pseudo-Assincrono)

O webhook responde 200 OK imediatamente ao WhatsApp e despacha o processamento da IA em background via asyncio.create_task. Isso evita timeout (limite de ~5s da Meta) e garante estabilidade durante chamadas mais lentas ao LLM.

```mermaid
sequenceDiagram
    participant C as Cliente (WhatsApp)
    participant WA as WhatsApp Cloud API
    participant API as FastAPI
    participant BG as Background Task (asyncio)
    participant AI as LangChain Agent
    participant MCP as MCP Server
    participant DB as PostgreSQL + PGVector

    C->>WA: Envia mensagem (texto)
    WA->>API: POST /webhook/whatsapp
    API->>API: Valida X-Hub-Signature-256
    API->>DB: Registra chat_message (role: user)
    API->>BG: asyncio.create_task(process_message)
    API-->>WA: 200 OK (imediato)

    Note over BG,AI: Processamento em background
    BG->>AI: Processa mensagem com contexto da sessao

    AI->>DB: Similarity search RAG (pgvector)
    DB-->>AI: Chunks de documentos relevantes

    AI->>MCP: Chama tool (ex: get_grades)
    MCP->>API: GET /students/{id}/grades (Service Token)
    API->>DB: Query
    DB-->>API: Resultado
    API-->>MCP: Resposta
    MCP->>DB: Log da acao (mcp_action_logs)
    MCP-->>AI: Resultado da tool

    AI-->>BG: Resposta gerada
    BG->>DB: Registra resposta (chat_message, role: assistant)
    BG->>WA: POST graph.facebook.com - Envia resposta
    WA->>C: Mensagem de resposta
```

---

## Fluxo de Mensagem WhatsApp (Midia - MVP)

Quando o aluno envia mensagem de midia, o bot responde com mensagem padrao orientando
o uso de texto. O tipo da midia e registrado no banco para auditoria.

```mermaid
sequenceDiagram
    participant C as Cliente (WhatsApp)
    participant WA as WhatsApp Cloud API
    participant API as FastAPI
    participant DB as PostgreSQL

    C->>WA: Envia midia (audio, imagem, sticker, localizacao, documento)
    WA->>API: POST /webhook/whatsapp (type != "text")
    API->>API: Valida X-Hub-Signature-256
    API->>DB: Registra chat_message (role: user, content: "[midia: {tipo}]")
    API->>WA: Envia resposta padrao
    WA->>C: Mensagem de resposta padrao
```

### Respostas Padrao por Tipo de Midia (MVP)

| Tipo de Midia | Resposta do Bot                                                                              |
| ------------- | -------------------------------------------------------------------------------------------- |
| audio         | "Nao consigo processar audios ainda. Por favor, descreva sua duvida em texto."               |
| image         | "Nao consigo analisar imagens ainda. Por favor, descreva o que precisa em texto."            |
| document      | "Recebi um documento, mas nao consigo processa-lo ainda. Descreva sua solicitacao em texto." |
| sticker       | "Por favor, descreva sua duvida em texto para que eu possa te ajudar."                       |
| location      | "Nao preciso da sua localizacao. Como posso te ajudar? Digite sua duvida."                   |
| video         | "Nao consigo processar videos. Por favor, descreva sua solicitacao em texto."                |

Roadmap pos-MVP (INCERTO):
audio → transcricao via Whisper API (OpenAI)
image → descricao e analise via GPT-4o Vision

---

## Fluxo de Notificacao Push e Sincronizacao em Tempo Real (FCM)

```mermaid
sequenceDiagram
    participant API as FastAPI
    participant FCM as Firebase Cloud Messaging
    participant APP as App Flutter (Cliente)

    Note over API: Evento ocorre (ex: documento pronto, matricula confirmada, resposta do bot)
    API->>FCM: POST /send {student_fcm_token, title, body, data: {type, resource_id}}
    FCM->>APP: Push notification (< 2s)
    APP->>APP: Exibe notificacao / atualiza badge
    APP->>API: GET recurso atualizado (ex: GET /documents/{id})
    API-->>APP: Dados atualizados
```

---

## Eventos que Disparam FCM

| Evento                     | Payload data                                    | Tela atualizada no App |
| -------------------------- | ----------------------------------------------- | ---------------------- |
| Documento pronto           | {type: "document_ready", document_id}           | Visualizar Documentos  |
| Matricula confirmada       | {type: "enrollment_confirmed", enrollment_id}   | Tracker de Acoes       |
| Agendamento confirmado     | {type: "appointment_confirmed", appointment_id} | Tracker de Acoes       |
| Resposta do bot processada | {type: "chat_reply", session_id}                | Historico de Chat      |
| Status de acao atualizado  | {type: "action_status", log_id}                 | Tracker de Acoes       |

---

## Fluxo de Autenticacao (Codigo de Verificacao)

```mermaid
sequenceDiagram
    participant U as Usuario
    participant APP as App / WhatsApp
    participant API as FastAPI
    participant DB as PostgreSQL

    U->>APP: Informa email/telefone
    APP->>API: POST /auth/request-code {email}
    API->>DB: Gera verification_code (expira em 5min)
    API-->>U: Envia codigo por email/SMS

    U->>APP: Informa codigo recebido
    APP->>API: POST /auth/verify-code {email, code}
    API->>DB: Valida codigo + cria sessao
    API-->>APP: Token JWT da sessao
```

---

## Topologia Docker

```mermaid
graph TB
    subgraph "Docker Compose"
        subgraph "Rede: app-network"
            API_C[fastapi-app :8000]
            AI_C[langchain-service :8001]
            MCP_C[mcp-server :8002]
        end

        subgraph "Rede: data-network"
            PG_C[postgres+pgvector :5432]
        end
    end

    API_C --> PG_C
    API_C --> AI_C
    AI_C --> MCP_C
    AI_C --> PG_C
    MCP_C --> PG_C
```

| Container         | Imagem                 | Porta | Descricao                                             |
| ----------------- | ---------------------- | ----- | ----------------------------------------------------- |
| fastapi-app       | python:3.12            | 8000  | API REST principal                                    |
| langchain-service | python:3.12            | 8001  | Agente IA com LangChain                               |
| mcp-server        | python:3.12            | 8002  | MCP Server (tools + logging)                          |
| postgres          | pgvector/pgvector:pg16 | 5432  | Banco de dados principal + extensao PGVector para RAG |

Nota PGVector: A imagem pgvector/pgvector:pg16 ja inclui a extensao instalada.
Basta executar CREATE EXTENSION IF NOT EXISTS vector; no init do banco.
Nao e necessario container separado para o Vector DB.

---

## Tech Stack

| Camada       | Tecnologia                     | Uso                                                     |
| ------------ | ------------------------------ | ------------------------------------------------------- |
| Frontend     | Flutter                        | App Mobile/Web (Cliente + Fornecedor)                   |
| Backend      | FastAPI (Python)               | API REST                                                |
| IA           | LangChain                      | Orquestracao do agente ReAct                            |
| RAG          | PGVector (extensao PostgreSQL) | Retrieval-Augmented Generation                          |
| Chatbot      | WhatsApp Business Cloud API    | Canal de atendimento                                    |
| Banco        | PostgreSQL 16                  | Dados relacionais + vetores RAG                         |
| Notificacoes | Firebase Cloud Messaging       | Push notifications e sincronizacao em tempo real (< 2s) |
| Infra        | Docker / LXC                   | Containerizacao                                         |
| Protocolo    | MCP                            | Tool calling + Logging                                  |
| Async        | asyncio.create_task (FastAPI)  | Processamento assincrono do webhook                     |
