# `architecture.md`

## O que mudou, resumão

**PGVector substituiu o "Vector DB a definir"**

- Removido o container `vector-db :6333` da topologia Docker
- Imagem trocada para `pgvector/pgvector:pg16` no container do PostgreSQL
- Adicionada nota de que basta `CREATE EXTENSION IF NOT EXISTS vector;` no init — zero infra extra

**Fluxo do webhook agora é pseudo-assíncrono**

- Diagrama de sequência novo mostrando o `200 OK` imediato ao WhatsApp
- `asyncio.create_task` despacha o processamento em background
- Evita o timeout de ~5s da Meta

**Fluxo de mídia documentado (critério de robustez)**

- Diagrama de sequência para mensagens não-texto
- Tabela com 6 tipos de mídia e resposta padrão de cada um
- Seção de roadmap pós-MVP (Whisper + GPT-4o Vision)

**FCM explicitamente como mecanismo de tempo real**

- Fluxo FCM expandido com tabela de 5 eventos que disparam push
- Meta de `< 2s` documentada explicitamente
- Cada evento mapeia para a tela que deve ser atualizada no app

**Diagrama C4 Level 2 adicionado**

- Containers com responsabilidades, tecnologia e protocolos de comunicação
- MCP com Service Token explícito nas chamadas internas

## O que mudou e por quê - detalhado

## Diagrama de Contexto (C4 - Level 1)

**O que mudou:** A descrição do FCM foi atualizada de "Notificações push" para "Notificações push e sincronização em tempo real".
**Por quê:** O FCM não é apenas notificação passiva — ele é o mecanismo que garante o critério de avaliação de integração em tempo real (< 2s). Deixar isso explícito no diagrama de mais alto nível sinaliza a decisão arquitetural desde o início.

---

## Diagrama de Containers (C4 - Level 2) — _novo_

**O que mudou:** Diagrama adicionado do zero.
**Por quê:** O Level 1 mostra o sistema como caixa preta. O Level 2 abre essa caixa e mostra os containers (FastAPI, LangChain Service, MCP Server, PostgreSQL+PGVector), suas responsabilidades individuais e os protocolos de comunicação entre eles — incluindo o Service Token do MCP e o canal FCM com a meta de < 2s explícita.

---

## Diagrama de Componentes

**O que mudou:** `Vector DB` separado foi substituído por `PostgreSQL + PGVector` como nó único. A seta do AI para o banco foi renomeada de "Consulta RAG" para "Similarity search RAG". A seta do MCP para a API ganhou a nota "Service Token".
**Por quê:** Com PGVector, o banco relacional e o banco vetorial são a mesma instância. Ter dois nós separados induziria a equipe a pensar que são serviços distintos durante a implementação.

---

## Fluxo de Mensagem WhatsApp — _reescrito_

**O que mudou:** O fluxo inteiro foi reestruturado para o modelo pseudo-assíncrono. Foi adicionado o participante `Background Task (asyncio)` e a separação entre o retorno imediato do `200 OK` e o processamento em background. O `Vector DB` virou `PostgreSQL + PGVector`.
**Por quê:** O diagrama anterior mostrava um fluxo síncrono onde o `200 OK` só era enviado ao WhatsApp após toda a cadeia IA → MCP → resposta ser completada. Isso causaria timeout real na Meta (~5s), derrubando o chatbot durante a demo.

---

## Fluxo de Mensagem WhatsApp — Mídia — _novo_

**O que mudou:** Diagrama e tabela adicionados do zero.
**Por quê:** Era o critério de robustez completamente ausente na documentação. Sem esse fluxo documentado, a equipe não saberia o que implementar quando chegasse uma mensagem de áudio ou imagem, e o avaliador questionaria diretamente esse ponto.

---

## Fluxo de Notificação Push (FCM) — _expandido_

**O que mudou:** O diagrama foi expandido com a nota de latência `< 2s` e com a etapa do app buscando os dados atualizados após receber o push. Foi adicionada a tabela de eventos que disparam FCM, mapeando cada evento para a tela correspondente no app.
**Por quê:** O diagrama original tinha apenas 3 linhas genéricas ("API envia → FCM entrega → App recebe"). Isso não demonstrava o critério de integração em tempo real nem deixava claro para o time Flutter quais eventos precisam de push e qual tela deve reagir a cada um.

---

## Topologia Docker — _simplificada_

**O que mudou:** O container `vector-db :6333` foi removido. A imagem do PostgreSQL foi trocada de `postgres:16` para `pgvector/pgvector:pg16`. As setas do `AI` e `MCP` para o banco foram atualizadas para apontar para o nó unificado.
**Por quê:** Com PGVector, não existe mais um segundo container de dados. Manter o `vector-db` na topologia criaria um container fantasma que ninguém saberia o que colocar lá na hora de subir o ambiente.

---

## Tech Stack — _atualizada_

**O que mudou:** `Vector DB (a definir)` → `PGVector (extensão PostgreSQL)`. Adicionadas as linhas de `asyncio.create_task` e a nota sobre a imagem Docker do PGVector.
**Por quê:** A tabela de tech stack é a referência rápida que qualquer integrante do time consulta para saber "o que usamos aqui". Ter "a definir" nessa tabela é uma decisão em aberto que bloqueia implementação.

# `chatbot.md` - O que mudou e por quê

## Diagrama da Arquitetura do Agente

**O que mudou:** Adicionado nó de detecção de mídia antes do agente, nó `PGVector` no lugar de `Vector DB`, e a ramificação de threshold (>= 0.75 → injeta contexto / < 0.75 → fallback).
**Por quê:** O diagrama de mais alto nível precisa refletir as três decisões mais importantes do sistema: mídia é barrada antes do agente, RAG usa PGVector, e existe um critério objetivo de quando o contexto é ou não usado.

## Componentes do Agente — tabela

**O que mudou:** `k=10` → `k=20` na memória; RAG atualizado para `PGVector + threshold 0.75`.
**Por quê:** A tabela é a referência rápida do time. Qualquer dev que abrir o arquivo precisa saber exatamente o que está configurado, sem ter que procurar em outra seção.

## Tratamento de Mensagens de Mídia — _nova seção_

**O que mudou:** Seção adicionada antes do fluxo de verificação, espelhando as decisões do `architecture.md`.
**Por quê:** O `chatbot.md` é o documento que o dev de IA vai implementar. Sem essa seção aqui, a decisão ficaria apenas no `architecture.md` e correria risco de não ser implementada.

## Fluxo de Verificação de Identidade

**O que mudou:** O diagrama foi expandido com um `loop` de até 3 tentativas, contador de tentativas restantes na mensagem ao aluno, e o bloco de bloqueio com reenvio automático após esgotar as tentativas.
**Por quê:** O fluxo anterior tinha apenas um `alt` genérico de "código inválido" sem nenhuma proteção. Com 6 dígitos, um código expira em 5 minutos — tempo mais do que suficiente para tentar todas as combinações sem rate limiting.

## Tabela de Intents

**O que mudou:** Adicionada a intent `confirm_enrollment` mapeada para a tool `confirm_enrollment`.
**Por quê:** O fluxo de matrícula cria um `draft` mas a confirmação definitiva estava sem intent mapeada — o agente não saberia que tool chamar quando o aluno dissesse "sim, confirmar".

## System Prompt

**O que mudou:** Adicionada a regra 8 sobre o threshold do RAG.
**Por quê:** O agente precisa saber explicitamente o que fazer quando o RAG não retorna contexto relevante. Sem essa regra, o LLM poderia tentar "ajudar" com conhecimento geral e alucinação.

## Conversation Memory

**O que mudou:** `k=10` → `k=20`, com justificativa documentada.
**Por quê:** Fluxos de matrícula têm 8-12 turnos facilmente. Com `k=10`, o agente poderia "esquecer" as disciplinas que o aluno escolheu no começo da conversa ao chegar na confirmação definitiva.

## Pipeline RAG — diagrama e threshold

**O que mudou:** `Vector DB` → `PGVector`. Adicionada ramificação de threshold com tabela de comportamento por score e a resposta padrão de fallback.
**Por quê:** Sem threshold documentado, cada dev implementaria um critério diferente (ou nenhum). Em um sistema acadêmico, uma resposta inventada sobre prazo de matrícula tem consequência real para o aluno.

## Pipeline de Ingestão de Documentos — _nova seção_

**O que mudou:** Seção inteiramente nova com estrutura de pastas, comando de execução e comportamento do script. Roadmap pós-MVP com endpoint admin.
**Por quê:** Era o gap mais crítico da documentação — a base de conhecimento não se popula sozinha. Sem documentar como os PDFs e markdowns da secretaria entram no PGVector, ninguém saberia o que fazer na Semana 2 do cronograma.

## Fluxo: Matrícula em Disciplinas

**O que mudou:** Fluxo expandido com a etapa de `confirm_enrollment` (draft → confirmed) e bloco de texto documentando o comportamento quando o período de matrícula encerra com draft ativo.
**Por quê:** O draft é um estado intermediário — sem documentar o que acontece com ele no fim do período, o banco acumularia registros órfãos e o aluno poderia ficar confuso ao tentar retomar uma matrícula cancelada.

## Tabela de Tratamento de Erros

**O que mudou:** Adicionadas 4 novas linhas: draft cancelado por fim de período, RAG sem contexto relevante, código esgotado e mensagem de mídia recebida.
**Por quê:** A tabela de erros é o mapa de todos os caminhos infelizes. Se um cenário não está aqui, ele não vai ser implementado.

---

# `mcp.md` - O que mudou e por quê

## Diagrama de Visão Geral

**O que mudou:** Label `X-Service-Token` adicionado na seta `MCP → API`.
**Por quê:** O diagrama de mais alto nível precisa deixar visível que essa comunicação é autenticada, não apenas "executa ação".

## Seção: Autenticação MCP → API — _nova_

**O que mudou:** Seção criada com o padrão do header, regras de segurança (`.env`, `.gitignore`) e o snippet do middleware FastAPI de validação.
**Por quê:** Sem credencial documentada, todas as chamadas internas retornariam `401` em produção.

## Seção: Injeção de `student_id` pelo Contexto da Sessão — _nova_

**O que mudou:** Seção criada com diagrama de sequência mostrando que o agente nunca passa `student_id` - o MCP extrai da sessão ativa.
**Por quê:** Se o `student_id` fosse parâmetro da tool, qualquer aluno poderia consultar dados de outro passando um ID diferente no texto - vulnerabilidade IDOR.

## Seção: Comportamento de Retry — _nova_

**O que mudou:** Seção criada documentando retry único imediato para erros 5xx/timeout, sem retry para erros 4xx.
**Por quê:** Sem isso, cada dev implementaria um comportamento diferente; a distinção 4xx vs 5xx é especialmente importante para não mascarar erros de lógica.

## Seção: Extração de `reasoning` via Callback Handler — _nova_

**O que mudou:** Seção criada com o snippet do `MCPLoggingHandler` usando `on_agent_action` e `reasoning` marcado como nullable.
**Por quê:** O campo `reasoning` é o diferencial de auditoria do sistema — sem implementação documentada, ficaria `null` para sempre.

## Schemas das tools — `student_id` removido

**O que mudou:** `student_id` removido dos schemas de `get_student_info`, `get_grades`, `get_transcript`, `get_available_courses`, `create_enrollment`, `request_document`, `book_appointment` e nota de implementação adicionada no topo da seção.
**Por quê:** O schema é o contrato com o LLM — se `student_id` aparecer, o agente vai tentar preenchê-lo a partir do texto do aluno.

## Tool `confirm_enrollment` — _nova_

**O que mudou:** Tool adicionada com endpoint `POST /enrollments/{id}/confirm`, erros possíveis (`409`, `404`) e descrição que referencia `create_enrollment`.
**Por quê:** Sem essa tool o fluxo de matrícula é tecnicamente incompleto — o draft nunca poderia ser confirmado pelo bot.

## Tabela Resumo de Tools — _nova_

**O que mudou:** Tabela consolidada com todas as 16 tools, mostrando endpoint, status do `student_id` e se requer confirmação do aluno.
**Por quê:** Com 16 tools o documento fica difícil de navegar; a tabela permite checar rapidamente quais tools alteram dados e quais injetam o `student_id`.

## Especificação de Logging — campos atualizados

**O que mudou:** `reasoning` marcado como nullable, campos `retry` (boolean) e status `retry_success` adicionados, `student_id` removido do exemplo de `input_params`.
**Por quê:** O log precisa refletir exatamente o que será persistido no banco — inclusive os cenários de retry e de modelos que não expõem chain-of-thought.

## Snippets de código

**O que mudou:** `get_grades` usa `session_context.get_student_id()` em vez de receber `student_id` como parâmetro; header `X-Service-Token` adicionado explicitamente na chamada HTTP.
**Por quê:** O snippet é o ponto de partida que o dev vai copiar — se mostrar o padrão errado, toda implementação replica o erro.

# `api.md` - O que mudou e por quê

## Convenções

**O que mudou:** A seção de convenções ganhou uma subseção de autenticação com dois mecanismos: `Authorization: Bearer {token}` para app/staff e `X-Service-Token` para chamadas internas do MCP.
**Por quê:** O `mcp.md` definiu Service Token fixo, então a API precisava documentar explicitamente que certos endpoints aceitam esse header além do JWT.

## Códigos HTTP

**O que mudou:** Foi adicionado o código `429` na tabela de status codes como “Limite de tentativas atingido (rate limiting)”.
**Por quê:** O fluxo de verificação de identidade no `chatbot.md` passou a ter bloqueio após 3 tentativas, então a API precisava refletir isso de forma correta e sem ambiguidade.

## `POST /auth/verify-code`

**O que mudou:** O endpoint passou a documentar 3 comportamentos: sucesso com JWT, erro `401` para código inválido e erro `429` para tentativas esgotadas com novo código reenviado automaticamente.
**Por quê:** Antes o endpoint só mostrava o caso feliz; agora ele cobre o comportamento real definido para o MVP e elimina a lacuna entre documentação e implementação esperada.

## Endpoints usados pelo MCP

**O que mudou:** Os endpoints consumidos pelas tools MCP passaram a ser marcados com “Aceita X-Service-Token (MCP)”, como `GET /students/{id}/academic-summary`, `GET /students/{id}/grades`, `GET /students/{id}/transcript`, `GET /students/{id}/available-courses`, `POST /enrollments`, `POST /enrollments/{id}/confirm`, `POST /documents`, `GET /documents/{id}`, `GET /scheduling/slots`, `POST /appointments`, `PUT /appointments/{id}/cancel`, `GET /curriculum/active`, `GET /courses/{id}/prerequisites` e `GET /enrollment-periods/current`.
**Por quê:** Só colocar a regra nas convenções não basta; quem lê um endpoint isolado precisa perceber imediatamente que ele participa da integração MCP → API.

## `POST /enrollments/{id}/confirm`

**O que mudou:** O endpoint ganhou response mínima de sucesso com `{ id, status, confirmed_at }` e tabela de erros possíveis (`404`, `409` para período encerrado e `409` para matrícula já confirmada).
**Por quê:** O fluxo de matrícula no `chatbot.md` e a tool `confirm_enrollment` no `mcp.md` exigem um contrato claro de resposta; sem isso o bot e o app não sabem como atualizar o estado após a confirmação.

## `GET /scheduling/slots`

**O que mudou:** Os query params foram padronizados para `date_from` e `date_to`, com nota de comportamento padrão quando omitidos.
**Por quê:** Havia inconsistência entre `api.md` e `mcp.md`; alinhar os dois evita implementação divergente e cobre melhor o caso de uso real de listar horários em uma janela de dias.

## Mapeamento MCP Tool → API Endpoint

**O que mudou:** A tabela final passou a incluir `confirm_enrollment`, que antes não aparecia no mapeamento.
**Por quê:** Essa tool já havia sido adicionada ao `mcp.md`; sem aparecer aqui, a documentação da API ficaria inconsistente com o restante do projeto.

## Ponto de atenção

## Cobertura parcial de endpoints

**O que mudou:** A versão atualizada priorizou os endpoints mais críticos para o fluxo principal do projeto e para a integração MCP/WhatsApp.
**Por quê:** Isso resolve os gaps funcionais mais importantes, mas ainda vale revisar depois se você quer manter no `api.md` exemplos completos também para endpoints menos centrais, como alguns detalhes de `GET /students/{id}`, `GET /courses/{id}` ou respostas mais completas de `GET /documents/{id}`.

---

# `database.md` - O que mudou e por quê

## ERD — diagrama atualizado

**O que mudou:** Adicionadas as entidades `fcm_tokens` e `knowledge_base_chunks`; relação `enrollment_courses ||--o{ grades` adicionada.
**Por quê:** O ERD precisa refletir o schema real — sem essas entidades no diagrama, a visão de alto nível fica desatualizada em relação às tabelas documentadas abaixo.

## Tabela `students` — `fcm_token` removido

**O que mudou:** Coluna `fcm_token` removida; nota explicando a migração para `fcm_tokens`.
**Por quê:** Campo único impede que o aluno use mais de um dispositivo — tablet + celular perderia notificação em um dos dois.

## Tabela `fcm_tokens` — _nova_

**O que mudou:** Tabela criada com `student_id`, `token`, `device_name` e constraint `UNIQUE(student_id, token)`.
**Por quê:** Estrutura relacional correta para N dispositivos por aluno; o MVP funciona com um dispositivo, mas não precisará de migração quando surgir o segundo.

## Tabela `staff` — `fcm_token` removido

**O que mudou:** Coluna `fcm_token` removida.
**Por quê:** Staff não recebe notificações push no MVP; manter o campo cria falsa expectativa de funcionalidade não implementada.

## Tabela `grades` — FK `enrollment_course_id` adicionada

**O que mudou:** Coluna `enrollment_course_id UUID FK -> enrollment_courses.id NOT NULL` adicionada.
**Por quê:** Sem essa FK o banco permitia nota em disciplina sem matrícula formal — integridade referencial que a camada de aplicação não deve ser a única a garantir.

## Tabela `verification_codes` — coluna `attempts` adicionada

**O que mudou:** Coluna `attempts INTEGER NOT NULL DEFAULT 0` adicionada.
**Por quê:** O bloqueio após 3 tentativas decidido no `chatbot.md` e documentado na `api.md` (429) não tem como funcionar sem esse contador no banco.

## Tabela `sessions` — `token` substituído por `jti`

**O que mudou:** `token VARCHAR(500)` substituído por `jti UUID UNIQUE NOT NULL`; nota explicativa adicionada.
**Por quê:** JWT é stateless por design — guardar o token completo cria uma tabela enorme e consulta cara por VARCHAR(500) a cada request. O `jti` é um UUID leve que serve apenas para revogação.

## Tabela `chat_messages` — coluna `media_type` adicionada

**O que mudou:** Coluna `media_type VARCHAR(20) NULLABLE` adicionada com os valores possíveis documentados.
**Por quê:** O `chatbot.md` definiu que o tipo de mídia deve ser registrado para auditoria; sem a coluna, seria impossível monitorar volume de mensagens de mídia recebidas.

## Tabela `mcp_action_logs` — campos `retry` e `retry_success` adicionados

**O que mudou:** Coluna `retry BOOLEAN NOT NULL DEFAULT false` adicionada; status `retry_success` incluído nos valores possíveis.
**Por quê:** O `mcp.md` definiu retry único imediato — sem esses campos o log não consegue distinguir chamadas que falharam na primeira tentativa, perdendo o valor de observabilidade.

## Tabela `knowledge_base_chunks` — _nova_

**O que mudou:** Tabela criada com `content`, `embedding vector(1536)`, `source`, `category`, `chunk_index` e nota sobre a dimensão do vetor.
**Por quê:** Era o gap crítico de persistência do RAG — o script de ingestão do `chatbot.md` precisa gravar os embeddings em algum lugar; sem essa tabela o PGVector não tem onde trabalhar.

## Índices — 4 novos adicionados

**O que mudou:** `idx_grades_enrollment_course`, `idx_sessions_user`, `idx_fcm_tokens_student` e `idx_knowledge_base_embedding` (HNSW) adicionados.
**Por quê:** O índice em `sessions.user_id` estava ausente e toda autenticação faz lookup por esse campo; o HNSW é obrigatório para que a busca vetorial no PGVector seja eficiente.

## Seção de Limpeza de Registros — _nova_

**O que mudou:** Seção com as duas queries de limpeza (`verification_codes` e `sessions`) e nota de roadmap com `pg_cron`.
**Por quê:** Sem limpeza documentada, as tabelas crescem indefinidamente; para o MVP basta o script manual, mas o time precisa saber que essa manutenção existe.
