# Chatbot WhatsApp - Fluxos e Arquitetura

## Visao Geral

O chatbot atende alunos do curso de Ciencia da Computacao via WhatsApp, usando LangChain para
orquestracao e RAG para consulta de regras academicas. As acoes sao executadas via MCP tools
que chamam a API REST.

---

## Arquitetura do Agente LangChain

```mermaid
graph TB
    MSG[Mensagem do Aluno] --> WH[Webhook WhatsApp]
    WH --> MEDIA{Tipo da mensagem?}
    MEDIA -->|Midia| MEDIA_RESP[Resposta padrao de midia]
    MEDIA -->|Texto| API[FastAPI]
    API --> AUTH{Aluno autenticado?}
    AUTH -->|Nao| VERIFY[Fluxo de Verificacao]
    AUTH -->|Sim| AGENT[LangChain Agent]

    AGENT --> MEMORY[Conversation Memory k=20]
    AGENT --> RAG[RAG - PGVector]
    AGENT --> TOOLS[MCP Tools]

    RAG --> THRESHOLD{Score >= 0.75?}
    THRESHOLD -->|Sim| CONTEXT[Injeta contexto no prompt]
    THRESHOLD -->|Nao| FALLBACK[Resposta padrao: nao encontrei]

    TOOLS --> API_INT[Chamadas internas API]
    TOOLS --> LOG[Log MCP]

    AGENT --> RESP[Resposta gerada]
    RESP --> WA[WhatsApp Cloud API]
    WA --> ALUNO[Aluno recebe resposta]
```

### Componentes do Agente

| Componente | Tecnologia                            | Funcao                                                        |
| ---------- | ------------------------------------- | ------------------------------------------------------------- |
| Agent      | LangChain ReAct Agent                 | Decide qual tool usar com base na mensagem                    |
| LLM        | (a definir)                           | Modelo de linguagem para gerar respostas                      |
| Memory     | ConversationBufferWindowMemory (k=20) | Mantem contexto das ultimas 20 mensagens                      |
| Tools      | MCP Tools                             | Acoes concretas (consultar notas, matricular, etc)            |
| RAG        | PGVector + LangChain Retriever        | Busca informacoes em documentos academicos com threshold 0.75 |

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
    API-->>WA: 200 OK (imediato — processamento assincrono via asyncio.create_task)
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

## Tratamento de Mensagens de Midia (MVP)

Mensagens que nao sao do tipo `text` recebem resposta padrao imediata, sem passar pelo agente.
O tipo da midia e registrado em `chat_messages` para auditoria.

| Tipo de Midia | Resposta do Bot                                                                              |
| ------------- | -------------------------------------------------------------------------------------------- |
| `audio`       | "Nao consigo processar audios ainda. Por favor, descreva sua duvida em texto."               |
| `image`       | "Nao consigo analisar imagens ainda. Por favor, descreva o que precisa em texto."            |
| `document`    | "Recebi um documento, mas nao consigo processa-lo ainda. Descreva sua solicitacao em texto." |
| `sticker`     | "Por favor, descreva sua duvida em texto para que eu possa te ajudar."                       |
| `location`    | "Nao preciso da sua localizacao. Como posso te ajudar? Digite sua duvida."                   |
| `video`       | "Nao consigo processar videos. Por favor, descreva sua solicitacao em texto."                |

> **Roadmap pos-MVP:**
>
> - `audio` → transcricao via **Whisper API** (OpenAI)
> - `image` → descricao e analise via **GPT-4o Vision**

---

## Fluxo de Verificacao de Identidade

O aluno tem **ate 3 tentativas** para informar o codigo correto. Apos 3 erros consecutivos,
o codigo e invalidado e um novo e enviado automaticamente. O contador de tentativas e
armazenado na tabela `verification_codes`.

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
        API->>DB: Gera codigo (6 digitos, expira em 5min, attempts=0)
        BOT->>A: "Enviei um codigo para seu email. Informe o codigo de 6 digitos."

        loop Ate 3 tentativas
            A->>BOT: Informa codigo
            BOT->>API: POST /auth/verify-code {email, code, platform: "whatsapp"}

            alt Codigo valido
                API-->>BOT: Token JWT + dados do aluno
                BOT->>DB: Vincula sessao ao aluno
                BOT->>A: "Identidade verificada! Ola, Joao. Como posso ajudar?"
            else Codigo invalido (tentativas < 3)
                API->>DB: Incrementa attempts
                BOT->>A: "Codigo invalido. Tente novamente. ({N} tentativa(s) restante(s))"
            else Codigo invalido (tentativas = 3)
                API->>DB: Invalida codigo atual
                API->>DB: Gera novo codigo automaticamente
                API-->>BOT: Erro: max_attempts_reached + novo codigo enviado
                BOT->>A: "Codigo invalido. Limite atingido. Enviei um novo codigo para seu email."
            end
        end
    end
```

---

## Tabela de Intents

| Intent (Portugues)                                            | Acao do Agente                         | MCP Tool                   |
| ------------------------------------------------------------- | -------------------------------------- | -------------------------- |
| "Quais minhas notas?" / "Como estao minhas notas?"            | Consulta notas do periodo atual        | `get_grades`               |
| "Quero meu historico escolar"                                 | Solicita documento de historico        | `request_document`         |
| "Quero me matricular" / "Quais disciplinas posso cursar?"     | Lista disciplinas disponiveis          | `get_available_courses`    |
| "Matricula em Estrutura de Dados e Calculo II"                | Cria matricula com disciplinas         | `create_enrollment`        |
| "Confirmar matricula" / "Sim, confirmar definitivamente"      | Confirma matricula (draft → confirmed) | `confirm_enrollment`       |
| "Quero trancar a matricula"                                   | Tranca matricula                       | `lock_enrollment`          |
| "Remover Calculo II da matricula"                             | Remove disciplina                      | `drop_course`              |
| "Quero agendar atendimento" / "Horarios disponiveis"          | Lista slots                            | `get_available_slots`      |
| "Agendar para segunda as 10h"                                 | Agenda atendimento                     | `book_appointment`         |
| "Cancelar meu agendamento"                                    | Cancela atendimento                    | `cancel_appointment`       |
| "Como funciona o trancamento?" / "Qual o prazo de matricula?" | Consulta regras via RAG                | RAG retrieval              |
| "Quais os pre-requisitos de IA?"                              | Consulta pre-requisitos                | `get_course_prerequisites` |
| "Qual a grade curricular?"                                    | Mostra curriculo                       | `get_curriculum`           |
| "Status do meu documento"                                     | Verifica status                        | `get_document_status`      |
| "Meus dados" / "Meu resumo academico"                         | Resumo do aluno                        | `get_student_info`         |

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
8. Se a base de conhecimento nao retornar contexto relevante (score < 0.75), informe
   que nao encontrou a informacao e oriente o aluno a procurar a secretaria.
```

### Tool Binding

O agente LangChain recebe as MCP tools como funcoes invocaveis. Cada tool tem:

- Nome e descricao
- Schema de parametros (JSON Schema)
- Funcao que chama o endpoint da API correspondente

### Conversation Memory

- **Tipo**: ConversationBufferWindowMemory (k=20)
- **Persistencia**: Mensagens salvas em `chat_messages` no PostgreSQL
- **Restauracao**: Ao retomar sessao, carrega ultimas 20 mensagens do banco
- **Justificativa do k=20**: Fluxos de matricula podem ter 8-12 turnos (listar → escolher →
  confirmar rascunho → confirmar definitivamente). k=20 garante que o agente mantenha
  contexto completo sem risco de "esquecer" escolhas anteriores do aluno.

---

## Pipeline RAG

```mermaid
graph LR
    DOCS[Documentos Academicos] --> EMBED[Embedding Model]
    EMBED --> PG[(PGVector - PostgreSQL)]

    QUERY[Pergunta do Aluno] --> EMBED2[Embedding]
    EMBED2 --> SEARCH[Similarity Search]
    PG --> SEARCH
    SEARCH --> THRESHOLD{Score >= 0.75?}
    THRESHOLD -->|Sim| CONTEXT[Contexto Relevante injetado no prompt]
    THRESHOLD -->|Nao| FALLBACK[Resposta padrao: nao encontrei na base]
    CONTEXT --> LLM[LLM + Prompt]
    LLM --> RESP[Resposta Fundamentada]
```

### Threshold de Similaridade

| Score   | Comportamento                                                |
| ------- | ------------------------------------------------------------ |
| >= 0.75 | Contexto injetado no prompt do agente normalmente            |
| < 0.75  | Contexto descartado — agente usa resposta padrao de fallback |

**Resposta padrao de fallback RAG:**

> "Nao encontrei informacoes sobre isso na minha base de conhecimento. Para essa duvida,
> recomendo entrar em contato com a secretaria diretamente pelo e-mail ou presencialmente."

### Knowledge Base (conteudo para RAG)

| Categoria             | Exemplos de Documentos                                      |
| --------------------- | ----------------------------------------------------------- |
| Regras de matricula   | Prazos, numero maximo de disciplinas, regras de trancamento |
| Curriculo             | Disciplinas por periodo, ementas, pre-requisitos            |
| Regulamento academico | Aprovacao, reprovacao, jubilamento, frequencia minima       |
| Documentos            | Tipos disponiveis, prazo de emissao, requisitos             |
| Agendamento           | Horarios de funcionamento, tipos de atendimento             |
| FAQ                   | Perguntas frequentes da secretaria                          |

---

## Pipeline de Ingestao de Documentos (RAG)

### MVP: Script de Ingestao Manual

O script `ingest.py` le documentos de uma pasta local, gera os embeddings e persiste
os vetores no PGVector. Deve ser executado sempre que a base de conhecimento for atualizada.

```
scripts/
└── ingest.py          # Script principal de ingestao
    └── /knowledge     # Pasta com os documentos fonte
        ├── matricula.md
        ├── regulamento.pdf
        ├── faq.md
        ├── calendario.md
        └── curriculo.md
```

**Execucao:**

```bash
# Via Docker
docker exec langchain-service python scripts/ingest.py

# Localmente
python scripts/ingest.py --source ./knowledge --chunk-size 500 --overlap 50
```

**Comportamento do script:**

1. Le todos os arquivos `.md` e `.pdf` da pasta `/knowledge`
2. Divide os documentos em chunks (tamanho: 500 tokens, overlap: 50 tokens)
3. Gera embeddings para cada chunk
4. Persiste os vetores em `pgvector` com metadados (`source`, `category`, `chunk_index`)
5. Exibe relatorio: total de documentos, chunks gerados, tempo de execucao

> **Roadmap pos-MVP:** Endpoint `POST /admin/knowledge-base/upload` para upload via
> painel do Fornecedor, sem necessidade de acesso tecnico ao servidor.

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

O fluxo de matricula tem dois momentos de confirmacao: criacao do rascunho e confirmacao
definitiva. Um draft nao confirmado expira automaticamente quando o periodo de matricula
encerra — se o aluno tentar confirmar apos o fechamento, o bot informa a situacao.

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
    MCP-->>BOT: Matricula criada (status: draft)
    BOT->>A: "Matricula salva como rascunho!\n- Estrutura de Dados\n- POO\nDeseja confirmar definitivamente? Esta acao nao pode ser desfeita."

    A->>BOT: "Sim, confirmar"
    BOT->>MCP: confirm_enrollment(enrollment_id)
    MCP-->>BOT: Matricula confirmada
    BOT->>A: "Matricula confirmada com sucesso! Voce recebera uma notificacao no app."
```

**Comportamento do draft ao fim do periodo:**

> Se o periodo de matricula encerrar com um draft ativo, o status e alterado para `cancelled`.
> Caso o aluno tente interagir com o draft apos o encerramento, o bot responde:
> "O periodo de matricula foi encerrado. Seu rascunho foi cancelado automaticamente.
> Aguarde a abertura do proximo periodo."

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

| Situacao                                    | Resposta do Bot                                                                                                                                                |
| ------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| API indisponivel                            | "Desculpe, estou com dificuldades tecnicas. Tente novamente em alguns minutos."                                                                                |
| Periodo de matricula fechado                | "O periodo de matricula nao esta aberto. Proximo periodo: {data}."                                                                                             |
| Draft cancelado por fim de periodo          | "O periodo de matricula foi encerrado. Seu rascunho foi cancelado. Aguarde o proximo periodo."                                                                 |
| Pre-requisito nao cumprido                  | "Voce nao pode cursar {disciplina} pois falta o pre-requisito: {prereq}."                                                                                      |
| Aluno nao encontrado                        | "Nao encontrei seu cadastro. Procure a secretaria presencialmente."                                                                                            |
| Slots esgotados                             | "Nao ha horarios disponiveis para o periodo solicitado. Tente outra data."                                                                                     |
| RAG sem contexto relevante (score < 0.75)   | "Nao encontrei informacoes sobre isso na minha base. Recomendo contatar a secretaria presencialmente ou pelo e-mail."                                          |
| Codigo de verificacao: tentativas esgotadas | "Codigo invalido. Limite atingido. Enviei um novo codigo para seu email."                                                                                      |
| Mensagem de midia recebida                  | (ver tabela de Tratamento de Mensagens de Midia acima)                                                                                                         |
| Intent nao reconhecido                      | "Nao entendi sua solicitacao. Posso ajudar com: notas, matricula, documentos, agendamentos e informacoes do curso. Deseja entrar em contato com a secretaria?" |
