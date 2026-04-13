# Arquitetura do Sistema

## Visao Geral

Sistema academico para o curso de Ciencia da Computacao (8 periodos) composto por:

- **Chatbot WhatsApp** com IA (LangChain + RAG) para atendimento de secretaria
- **App Flutter** (Mobile/Web) para Cliente e Fornecedor
- **API Backend** (FastAPI) como camada central
- **PostgreSQL** + Vector DB para persistencia e RAG
- **Firebase Cloud Messaging (FCM)** para notificacoes push

---

## Diagrama de Contexto (C4 - Level 1)

```mermaid
C4Context
    title Sistema Academico - Diagrama de Contexto

    Person(cliente, "Cliente (Aluno)", "Interage via WhatsApp e App Flutter")
    Person(fornecedor, "Fornecedor (Staff)", "Gerencia via App Flutter (CRM)")

    System(sistema, "Sistema Academico", "Plataforma de atendimento academico com IA")

    System_Ext(whatsapp, "WhatsApp Business Cloud API", "Canal de comunicacao do chatbot")
    System_Ext(fcm, "Firebase Cloud Messaging", "Notificacoes push")

    Rel(cliente, whatsapp, "Envia mensagens")
    Rel(whatsapp, sistema, "Webhook / Cloud API")
    Rel(cliente, sistema, "Usa App Flutter")
    Rel(fornecedor, sistema, "Usa App Flutter (CRM)")
    Rel(sistema, fcm, "Envia notificacoes")
    Rel(fcm, cliente, "Push notifications")
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
        PG[(PostgreSQL)]
        VDB[(Vector DB)]
    end

    subgraph "Servicos Externos"
        FCM[Firebase Cloud Messaging]
    end

    WA_API -->|Webhook| API
    API -->|Resposta| WA_API
    APP_CLI -->|REST| API
    APP_FORN -->|REST| API

    API -->|Orquestra| AI
    AI -->|Tools via MCP| MCP
    MCP -->|Chamadas internas| API
    MCP -->|Log de acoes| PG

    AI -->|Consulta RAG| VDB
    API -->|CRUD| PG

    API -->|Push| FCM
```

---

## Fluxo de Mensagem WhatsApp

```mermaid
sequenceDiagram
    participant C as Cliente (WhatsApp)
    participant WA as WhatsApp Cloud API
    participant API as FastAPI
    participant AI as LangChain Agent
    participant MCP as MCP Server
    participant DB as PostgreSQL
    participant VDB as Vector DB

    C->>WA: Envia mensagem
    WA->>API: POST /webhook/whatsapp
    API->>DB: Registra chat_message
    API->>AI: Processa mensagem

    AI->>VDB: Busca contexto (RAG)
    VDB-->>AI: Documentos relevantes

    AI->>MCP: Chama tool (ex: get_grades)
    MCP->>API: Chamada interna ao endpoint
    API->>DB: Query
    DB-->>API: Resultado
    API-->>MCP: Resposta
    MCP->>DB: Log da acao (mcp_action_logs)
    MCP-->>AI: Resultado da tool

    AI-->>API: Resposta gerada
    API->>DB: Registra resposta (chat_message)
    API->>WA: Envia resposta
    WA->>C: Mensagem de resposta
```

---

## Fluxo de Notificacao Push (FCM)

```mermaid
sequenceDiagram
    participant API as FastAPI
    participant FCM as Firebase Cloud Messaging
    participant APP as App Flutter (Cliente)

    API->>FCM: Envia notificacao (status update, documento pronto, etc)
    FCM->>APP: Push notification
    APP->>API: GET recurso atualizado
```

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
            PG_C[postgres :5432]
            VDB_C[vector-db :6333]
        end
    end

    API_C --> PG_C
    API_C --> AI_C
    AI_C --> MCP_C
    AI_C --> VDB_C
    MCP_C --> PG_C
```

| Container | Imagem | Porta | Descricao |
|-----------|--------|-------|-----------|
| fastapi-app | python:3.12 | 8000 | API REST principal |
| langchain-service | python:3.12 | 8001 | Agente IA com LangChain |
| mcp-server | python:3.12 | 8002 | MCP Server (tools + logging) |
| postgres | postgres:16 | 5432 | Banco de dados principal |
| vector-db | (a definir) | 6333 | Vector DB para RAG |

---

## Tech Stack

| Camada | Tecnologia | Uso |
|--------|-----------|-----|
| Frontend | Flutter | App Mobile/Web (Cliente + Fornecedor) |
| Backend | FastAPI (Python) | API REST |
| IA | LangChain | Orquestracao do agente |
| RAG | Vector DB (a definir) | Retrieval-Augmented Generation |
| Chatbot | WhatsApp Business Cloud API | Canal de atendimento |
| Banco | PostgreSQL | Dados relacionais |
| Notificacoes | Firebase Cloud Messaging | Push notifications |
| Infra | Docker / LXC | Containerizacao |
| Protocolo | MCP | Tool calling + Logging |
