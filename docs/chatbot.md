# Chatbot WhatsApp - Fluxos e Arquitetura

## Visao Geral

O chatbot atende alunos do curso de Ciencia da Computacao via WhatsApp, usando LangChain para orquestracao e RAG para consulta de regras academicas. As acoes sao executadas via MCP tools que chamam a API REST.

---

## Arquitetura do Agente LangChain

```mermaid
graph TB
    MSG[Mensagem do Aluno] --> WH[Webhook WhatsApp]
    WH --> API[FastAPI]
    API --> AUTH{Aluno autenticado?}
    AUTH -->|Nao| VERIFY[Fluxo de Verificacao]
    AUTH -->|Sim| AGENT[LangChain Agent]

    AGENT --> MEMORY[Conversation Memory]
    AGENT --> RAG[RAG - Vector DB]
    AGENT --> TOOLS[MCP Tools]

    TOOLS --> API_INT[Chamadas internas API]
    TOOLS --> LOG[Log MCP]

    AGENT --> RESP[Resposta gerada]
    RESP --> WA[WhatsApp Cloud API]
    WA --> ALUNO[Aluno recebe resposta]
```

### Componentes do Agente

| Componente | Tecnologia | Funcao |
|------------|-----------|--------|
| Agent | LangChain ReAct Agent | Decide qual tool usar com base na mensagem |
| LLM | (a definir) | Modelo de linguagem para gerar respostas |
| Memory | ConversationBufferWindowMemory | Mantem contexto das ultimas N mensagens |
| Tools | MCP Tools | Acoes concretas (consultar notas, matricular, etc) |
| RAG | Vector DB + LangChain Retriever | Busca informacoes em documentos academicos |

---

## Integracao WhatsApp Business API

### Webhook

O WhatsApp Business Cloud API envia mensagens via webhook:

```mermaid
sequenceDiagram
    participant WA as WhatsApp Cloud API
    participant API as FastAPI
    participant DB as PostgreSQL

    WA->>API: POST /webhook/whatsapp (mensagem)
    API->>API: Valida signature (X-Hub-Signature-256)
    API->>DB: Busca/cria chat_session pelo telefone
    API->>DB: Salva chat_message (role: user)
    API-->>WA: 200 OK (resposta assincrona)
```

### Envio de Resposta

```
POST https://graph.facebook.com/v18.0/{phone_number_id}/messages
Authorization: Bearer {WHATSAPP_TOKEN}

{
  "messaging_product": "whatsapp",
  "to": "5521999999999",
  "type": "text",
  "text": {"body": "Suas notas do periodo 2025.1: ..."}
}
```

---

## Fluxo de Verificacao de Identidade

```mermaid
sequenceDiagram
    participant A as Aluno (WhatsApp)
    participant BOT as Chatbot
    participant API as FastAPI
    participant DB as PostgreSQL

    A->>BOT: Qualquer mensagem
    BOT->>DB: Verifica sessao ativa para o telefone

    alt Sessao ativa e valida
        BOT->>BOT: Prossegue com o atendimento
    else Sem sessao ou expirada
        BOT->>A: "Preciso verificar sua identidade. Qual seu email institucional?"
        A->>BOT: "joao@universidade.edu"
        BOT->>API: POST /auth/request-code {email, channel: "email"}
        API->>DB: Gera codigo, envia por email
        BOT->>A: "Enviei um codigo para seu email. Informe o codigo de 6 digitos."
        A->>BOT: "123456"
        BOT->>API: POST /auth/verify-code {email, code, platform: "whatsapp"}

        alt Codigo valido
            API-->>BOT: Token JWT + dados do aluno
            BOT->>DB: Vincula sessao ao aluno
            BOT->>A: "Identidade verificada! Ola, Joao. Como posso ajudar?"
        else Codigo invalido
            BOT->>A: "Codigo invalido. Tente novamente ou solicite um novo codigo."
        end
    end
```

---

## Tabela de Intents

| Intent (Portugues) | Acao do Agente | MCP Tool |
|---------------------|---------------|----------|
| "Quais minhas notas?" / "Como estao minhas notas?" | Consulta notas do periodo atual | `get_grades` |
| "Quero meu historico escolar" | Solicita documento de historico | `request_document` |
| "Quero me matricular" / "Quais disciplinas posso cursar?" | Lista disciplinas disponiveis | `get_available_courses` |
| "Matricula em Estrutura de Dados e Calculo II" | Cria matricula com disciplinas | `create_enrollment` |
| "Quero trancar a matricula" | Tranca matricula | `lock_enrollment` |
| "Remover Calculo II da matricula" | Remove disciplina | `drop_course` |
| "Quero agendar atendimento" / "Horarios disponiveis" | Lista slots | `get_available_slots` |
| "Agendar para segunda as 10h" | Agenda atendimento | `book_appointment` |
| "Cancelar meu agendamento" | Cancela atendimento | `cancel_appointment` |
| "Como funciona o trancamento?" / "Qual o prazo de matricula?" | Consulta regras via RAG | RAG retrieval |
| "Quais os pre-requisitos de IA?" | Consulta pre-requisitos | `get_course_prerequisites` |
| "Qual a grade curricular?" | Mostra curriculo | `get_curriculum` |
| "Status do meu documento" | Verifica status | `get_document_status` |
| "Meus dados" / "Meu resumo academico" | Resumo do aluno | `get_student_info` |

---

## Design do Agente

### System Prompt

```
Voce e o assistente virtual da secretaria academica do curso de Ciencia da Computacao.

Regras:
1. Sempre responda em portugues brasileiro.
2. Antes de executar qualquer acao que altere dados (matricula, trancamento, agendamento),
   confirme com o aluno.
3. Use as tools disponiveis para consultar e executar acoes.
4. Para duvidas sobre regras academicas, consulte a base de conhecimento (RAG).
5. Seja claro e objetivo nas respostas.
6. Se nao souber responder, oriente o aluno a procurar a secretaria presencialmente.
7. Nunca invente informacoes - use apenas dados das tools e do RAG.
```

### Tool Binding

O agente LangChain recebe as MCP tools como funcoes invocaveis. Cada tool tem:
- Nome e descricao
- Schema de parametros (JSON Schema)
- Funcao que chama o endpoint da API correspondente

### Conversation Memory

- **Tipo**: ConversationBufferWindowMemory (k=10)
- **Persistencia**: Mensagens salvas em `chat_messages` no PostgreSQL
- **Restauracao**: Ao retomar sessao, carrega ultimas 10 mensagens do banco

---

## Pipeline RAG

```mermaid
graph LR
    DOCS[Documentos Academicos] --> EMBED[Embedding Model]
    EMBED --> VDB[(Vector DB)]

    QUERY[Pergunta do Aluno] --> EMBED2[Embedding]
    EMBED2 --> SEARCH[Similarity Search]
    VDB --> SEARCH
    SEARCH --> CONTEXT[Contexto Relevante]
    CONTEXT --> LLM[LLM + Prompt]
    LLM --> RESP[Resposta Fundamentada]
```

### Knowledge Base (conteudo para RAG)

| Categoria | Exemplos de Documentos |
|-----------|----------------------|
| Regras de matricula | Prazos, numero maximo de disciplinas, regras de trancamento |
| Curriculo | Disciplinas por periodo, ementas, pre-requisitos |
| Regulamento academico | Aprovacao, reprovacao, jubilamento, frequencia minima |
| Documentos | Tipos disponiveis, prazo de emissao, requisitos |
| Agendamento | Horarios de funcionamento, tipos de atendimento |
| FAQ | Perguntas frequentes da secretaria |

---

## Diagramas de Conversacao

### Fluxo: Consulta de Notas

```mermaid
sequenceDiagram
    participant A as Aluno
    participant BOT as Chatbot
    participant MCP as MCP Tools

    A->>BOT: "Quais minhas notas?"
    BOT->>MCP: get_grades(student_id, semester_year="atual")
    MCP-->>BOT: Lista de notas
    BOT->>A: "Suas notas em 2025.1:\n- Algoritmos: N1=8.5 N2=7.0 Final=7.75 ✓\n- Calculo I: N1=6.0 (aguardando N2)"
```

### Fluxo: Matricula em Disciplinas

```mermaid
sequenceDiagram
    participant A as Aluno
    participant BOT as Chatbot
    participant MCP as MCP Tools

    A->>BOT: "Quero me matricular"
    BOT->>MCP: get_enrollment_period()
    MCP-->>BOT: Periodo ativo ate 15/02

    BOT->>MCP: get_available_courses(student_id)
    MCP-->>BOT: Lista de disciplinas

    BOT->>A: "Periodo de matricula aberto ate 15/02.\nDisciplinas disponiveis:\n1. Estrutura de Dados\n2. Calculo II\n3. POO\n..."

    A->>BOT: "Quero Estrutura de Dados e POO"
    BOT->>A: "Confirma matricula em:\n- Estrutura de Dados (4 cred)\n- POO (4 cred)\nTotal: 8 creditos. Confirmar?"

    A->>BOT: "Sim"
    BOT->>MCP: create_enrollment(student_id, course_ids=[...])
    MCP-->>BOT: Matricula criada (draft)
    BOT->>A: "Matricula realizada com sucesso! Status: rascunho.\nDeseja confirmar definitivamente?"
```

### Fluxo: Solicitacao de Documento

```mermaid
sequenceDiagram
    participant A as Aluno
    participant BOT as Chatbot
    participant MCP as MCP Tools

    A->>BOT: "Preciso do historico escolar"
    BOT->>A: "Vou solicitar seu historico escolar. Confirmar?"
    A->>BOT: "Sim"
    BOT->>MCP: request_document(student_id, type="transcript")
    MCP-->>BOT: Documento solicitado, id=uuid
    BOT->>A: "Historico solicitado! Voce recebera uma notificacao quando estiver pronto. Acompanhe pelo app."
```

### Fluxo: Agendamento

```mermaid
sequenceDiagram
    participant A as Aluno
    participant BOT as Chatbot
    participant MCP as MCP Tools

    A->>BOT: "Quero agendar atendimento"
    BOT->>MCP: get_available_slots(date_range)
    MCP-->>BOT: Slots disponiveis

    BOT->>A: "Horarios disponiveis:\n- Seg 20/01 10:00-10:30 (Maria)\n- Seg 20/01 14:00-14:30 (Carlos)\n- Ter 21/01 09:00-09:30 (Maria)"

    A->>BOT: "Segunda as 10h"
    BOT->>A: "Agendar com Maria em 20/01 as 10:00. Qual o motivo?"
    A->>BOT: "Duvida sobre trancamento"
    BOT->>MCP: book_appointment(slot_id, reason="Duvida sobre trancamento")
    MCP-->>BOT: Agendamento confirmado
    BOT->>A: "Agendamento confirmado!\n20/01 (seg) as 10:00 com Maria.\nMotivo: Duvida sobre trancamento"
```

---

## Tratamento de Erros

| Situacao | Resposta do Bot |
|----------|----------------|
| API indisponivel | "Desculpe, estou com dificuldades tecnicas. Tente novamente em alguns minutos." |
| Periodo de matricula fechado | "O periodo de matricula nao esta aberto. Proximo periodo: {data}." |
| Pre-requisito nao cumprido | "Voce nao pode cursar {disciplina} pois falta o pre-requisito: {prereq}." |
| Aluno nao encontrado | "Nao encontrei seu cadastro. Procure a secretaria presencialmente." |
| Slots esgotados | "Nao ha horarios disponiveis para o periodo solicitado. Tente outra data." |
| Intent nao reconhecido | "Nao entendi sua solicitacao. Posso ajudar com: notas, matricula, documentos, agendamentos e informacoes do curso. Deseja entrar em contato com a secretaria?" |
