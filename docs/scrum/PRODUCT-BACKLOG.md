# Product Backlog — Desafio FCG3

**Produto:** Plataforma Academica com Chatbot WhatsApp  
**Product Owner:** [Nome do PO]  
**Ultima atualizacao:** 2026-05-11  
**Total de Story Points:** 375 SP  
**SP Entregues:** 341/375 (91%)  
**SP Restantes:** 34 SP (Fases 23-24)  
**Status:** 91% concluido (v3.0 em andamento)  

---

## Legenda

| Campo | Descricao |
|-------|-----------|
| **ID** | Identificador unico da User Story |
| **Prioridade** | Must Have / Should Have / Could Have / Won't Have (MoSCoW) |
| **SP** | Story Points (Fibonacci: 1, 2, 3, 5, 8, 13, 21) |
| **Status** | Done / In Progress / To Do / Blocked |
| **Sprint** | Sprint em que foi/sera implementada |

---

## Epico 1: Infraestrutura e Ambiente

| ID | User Story | Criterios de Aceitacao | SP | Prioridade | Status | Sprint |
|----|-----------|----------------------|-----|------------|--------|--------|
| US-001 | Como desenvolvedor, quero subir o ambiente completo com um unico comando, **para que** todos consigam trabalhar localmente sem configuracao manual | 1. `docker compose up` sobe 4 containers (postgres, fastapi, langchain, mcp)<br>2. Healthchecks passam em < 60s<br>3. Nenhuma configuracao manual alem de `.env` | 8 | Must Have | Done | Sprint 1 |
| US-002 | Como desenvolvedor, quero que o schema do banco seja gerenciado por migrations, **para que** mudancas sejam rastreavies, reproduziveis e reversiveis em qualquer ambiente | 1. `alembic upgrade head` cria todas as 21 tabelas<br>2. Extensao pgvector habilitada na migration #001<br>3. Index HNSW criado em knowledge_base_chunks.embedding | 8 | Must Have | Done | Sprint 1 |
| US-003 | Como desenvolvedor, quero um arquivo `.env.example` documentado, **para que** novos membros configurem o ambiente rapidamente sem precisar ler codigo-fonte | 1. Todas as variaveis (DATABASE_URL, MCP_SERVICE_TOKEN, WHATSAPP_TOKEN, OPENAI_API_KEY, etc.) listadas<br>2. Comentarios explicando cada variavel<br>3. Valores placeholder seguros | 3 | Must Have | Done | Sprint 1 |
| US-004 | Como desenvolvedor, quero seed data do curriculo, **para que** eu tenha dados realistas para testar fluxos academicos durante o desenvolvimento | 1. Script popula 8 semestres com ~40 disciplinas<br>2. Pre-requisitos entre disciplinas configurados<br>3. Alunos e staff de teste criados<br>4. Seed e destrutivo (limpa antes de inserir) | 5 | Must Have | Done | Sprint 1 |

**Subtotal Epico 1:** 24 SP — **100% Done**

---

## Epico 2: Autenticacao e Seguranca

| ID | User Story | Criterios de Aceitacao | SP | Prioridade | Status | Sprint |
|----|-----------|----------------------|-----|------------|--------|--------|
| US-005 | Como aluno, quero receber um codigo OTP no meu email, **para que** eu possa me autenticar de forma segura sem precisar lembrar senhas | 1. `POST /auth/request-code` envia email com codigo de 6 digitos via Resend<br>2. Codigo expira em 5 minutos<br>3. Rate limit: max 3 tentativas por email a cada 5 min | 8 | Must Have | Done | Sprint 1 |
| US-006 | Como aluno, quero verificar meu codigo OTP e receber um token JWT, **para que** eu tenha acesso autenticado a todos os recursos da plataforma | 1. `POST /auth/verify-code` valida codigo e retorna JWT<br>2. JWT contem campos: sub (user_id), role (student/staff), jti (unico)<br>3. Apos 3 tentativas erradas, codigo e invalidado e novo e enviado automaticamente | 8 | Must Have | Done | Sprint 1 |
| US-007 | Como aluno, quero encerrar minha sessao, **para que** ninguem consiga usar meu token caso eu perca o dispositivo | 1. `POST /auth/logout` marca sessao como revogada (jti na tabela sessions)<br>2. Requisicoes subsequentes com mesmo JWT sao rejeitadas (401) | 3 | Must Have | Done | Sprint 1 |
| US-008 | Como aluno, quero consultar meus dados de perfil, **para que** eu confirme que estou logado na conta correta antes de realizar acoes | 1. `GET /auth/me` retorna dados do usuario logado<br>2. Retorna 401 se token invalido/expirado/revogado | 2 | Should Have | Done | Sprint 1 |
| US-009 | Como sistema, devo validar o X-Service-Token nas chamadas internas do MCP, **para que** apenas o MCP Server autorizado consiga acessar endpoints internos da API | 1. Header `X-Service-Token` validado via `hmac.compare_digest`<br>2. Ausencia do header retorna 401<br>3. Token invalido retorna 401 | 5 | Must Have | Done | Sprint 1 |

**Subtotal Epico 2:** 26 SP — **100% Done**

---

## Epico 3: Gestao Academica (Backend REST)

| ID | User Story | Criterios de Aceitacao | SP | Prioridade | Status | Sprint |
|----|-----------|----------------------|-----|------------|--------|--------|
| US-010 | Como staff, quero gerenciar alunos (listar, criar, atualizar, desativar), **para que** o cadastro academico esteja sempre atualizado e consistente | 1. CRUD completo com paginacao e filtros (nome, semestre, status)<br>2. Soft delete (status: inactive)<br>3. Protecao IDOR: staff so gerencia alunos do proprio escopo | 8 | Must Have | Done | Sprint 1 |
| US-011 | Como aluno, quero ver meu resumo academico, **para que** eu acompanhe meu progresso e saiba exatamente onde estou na graduacao | 1. Retorna: semestre atual, disciplinas concluidas, CRA, status, documentos pendentes, proximo agendamento<br>2. CRA ponderado por creditos, exclui disciplinas em andamento/trancadas<br>3. Protecao contra divisao por zero | 5 | Must Have | Done | Sprint 1 |
| US-012 | Como aluno, quero ver quais disciplinas posso me matricular, **para que** eu planeje meu semestre sabendo exatamente o que esta disponivel para mim | 1. Lista apenas disciplinas com pre-requisitos cumpridos<br>2. Exclui disciplinas ja concluidas ou em andamento<br>3. Mostra creditos e carga horaria de cada disciplinas | 5 | Must Have | Done | Sprint 1 |
| US-013 | Como usuario, quero navegar disciplinas e ver a arvore de pre-requisitos, **para que** eu entenda as dependencias e planeje a sequencia ideal de disciplinas | 1. Listagem com filtro por nome e periodo<br>2. Detalhe com creditos, carga horaria, pre-requisitos diretos<br>3. Arvore recursiva via CTE (sem loop infinito em grafos ciclicos) | 8 | Must Have | Done | Sprint 1 |
| US-014 | Como aluno, quero criar, confirmar e gerenciar minha matricula, **para que** eu consiga me inscrever nas disciplinas do proximo semestre de forma autonoma | 1. Criar matricula em rascunho com 1+ disciplinas (durante periodo ativo)<br>2. Confirmar matricula (draft -> confirmed)<br>3. Remover disciplina individual<br>4. Trancar matricula inteira<br>5. Bloqueio: fora do periodo, pre-requisito nao cumprido, disciplina duplicada | 13 | Must Have | Done | Sprint 1 |
| US-015 | Como staff, quero gerenciar periodos de matricula, **para que** eu controle com precisao quando alunos podem se inscrever em disciplinas | 1. Criar periodo (nome, tipo, datas inicio/fim, semestre letivo)<br>2. Ativar/desativar periodo<br>3. Listar todos os periodos | 5 | Must Have | Done | Sprint 1 |
| US-016 | Como aluno, quero consultar minhas notas e historico, **para que** eu acompanhe meu desempenho e identifique disciplinas que precisam de atencao | 1. Notas por disciplina e periodo letivo<br>2. Historico escolar completo<br>3. CRA ponderado calculado automaticamente | 5 | Must Have | Done | Sprint 1 |
| US-017 | Como staff, quero lancar e atualizar notas, **para que** o desempenho dos alunos fique registrado oficialmente e disponivel para consulta | 1. Lancar N1 e N2 por aluno/disciplina<br>2. Nota final calculada automaticamente<br>3. Pode atualizar notas ja lancadas | 5 | Must Have | Done | Sprint 1 |
| US-018 | Como aluno, quero solicitar documentos e acompanhar o status, **para que** eu obtenha comprovantes academicos sem precisar ir presencialmente a secretaria | 1. Solicitar: transcript, enrollment_proof, declaration, certificate<br>2. Listar documentos com filtro por tipo e status<br>3. Ver detalhe com URL de download quando status=ready | 5 | Must Have | Done | Sprint 1 |
| US-019 | Como staff, quero atualizar o status de documentos e vincular arquivos, **para que** eu atenda solicitacoes dos alunos de forma organizada e rastreavel | 1. Mudar status: requested -> processing -> ready -> delivered<br>2. Vincular URL do arquivo gerado<br>3. Aluno ve URL quando status muda para ready | 3 | Must Have | Done | Sprint 1 |
| US-020 | Como aluno, quero agendar atendimento em horarios disponiveis, **para que** eu resolva questoes academicas presencialmente sem esperar em filas | 1. Consultar slots disponiveis com filtro por data/responsavel<br>2. Reservar slot com motivo (SELECT FOR UPDATE contra race condition)<br>3. Cancelar agendamento proprio | 8 | Must Have | Done | Sprint 1 |
| US-021 | Como staff, quero criar slots de atendimento, **para que** os alunos vejam minha disponibilidade e agendem horarios de forma autonoma | 1. Criar slots com data, horario inicio/fim, duracao<br>2. Slots aparecem como disponiveis para alunos | 3 | Must Have | Done | Sprint 1 |
| US-022 | Como staff, quero ver um dashboard com KPIs, **para que** eu tenha visao geral do sistema e identifique rapidamente o que precisa de atencao | 1. Total de alunos ativos<br>2. Matriculas no periodo atual<br>3. Documentos pendentes<br>4. Agendamentos futuros<br>5. Sessoes de chat ativas | 5 | Should Have | Done | Sprint 1 |

**Subtotal Epico 3:** 78 SP — **100% Done**

---

## Epico 4: MCP Server (Proxy de Ferramentas)

| ID | User Story | Criterios de Aceitacao | SP | Prioridade | Status | Sprint |
|----|-----------|----------------------|-----|------------|--------|--------|
| US-023 | Como agente IA, preciso de ferramentas MCP para consultar e executar acoes academicas, **para que** eu consiga responder perguntas e realizar operacoes em nome do aluno em tempo real | 1. 16 tools implementadas via Streamable HTTP<br>2. Tools: get_student_info, get_available_courses, get_grades, get_transcript, get_curriculum, get_course_prerequisites, get_enrollment_period, create_enrollment, confirm_enrollment, drop_course, lock_enrollment, request_document, get_document_status, get_available_slots, book_appointment, cancel_appointment | 13 | Must Have | Done | Sprint 1 |
| US-024 | Como sistema, devo injetar student_id no contexto, **para que** o agente nunca tenha acesso direto ao ID do aluno e ataques IDOR sejam impossíveis | 1. student_id NAO aparece em nenhum schema de tool<br>2. MCP resolve student_id da sessao ativa antes de cada chamada<br>3. Impossivel para o agente forjar student_id (prevencao IDOR) | 8 | Must Have | Done | Sprint 1 |
| US-025 | Como staff, quero que toda chamada de tool seja logada, **para que** eu possa auditar acoes do chatbot e diagnosticar problemas rapidamente | 1. Cada invocacao gera registro em mcp_action_logs<br>2. Campos: tool_name, input_params (sem student_id), output_result, reasoning, latency_ms, retry, status<br>3. Log nao bloqueia a execucao da tool | 5 | Must Have | Done | Sprint 1 |
| US-026 | Como sistema, devo validar X-Service-Token em toda chamada MCP->API, **para que** apenas o MCP Server autorizado consiga invocar endpoints internos | 1. Comparacao via hmac.compare_digest (constant-time)<br>2. Token ausente = 401<br>3. Token invalido = 401 | 3 | Must Have | Done | Sprint 1 |
| US-027 | Como sistema, devo fazer retry em erros 5xx/timeout e nao retry em 4xx, **para que** falhas transientes sejam recuperadas sem criar loops infinitos em erros de logica | 1. 5xx ou timeout: uma unica retentativa imediata<br>2. 4xx: nao retenta (erro de logica)<br>3. Retry logado em mcp_action_logs com flag retry=true | 3 | Must Have | Done | Sprint 1 |

**Subtotal Epico 4:** 32 SP — **100% Done**

---

## Epico 5: Servico de IA (LangChain + RAG)

| ID | User Story | Criterios de Aceitacao | SP | Prioridade | Status | Sprint |
|----|-----------|----------------------|-----|------------|--------|--------|
| US-028 | Como aluno, quero enviar uma pergunta e receber uma resposta inteligente em portugues sobre minha situacao academica, **para que** eu resolva duvidas e execute acoes sem depender de atendimento humano | 1. Agente ReAct processa mensagem de texto<br>2. Decide quais MCP tools chamar baseado no contexto<br>3. Resposta em portugues, tom institucional<br>4. Funciona com OpenAI e Gemini (configuravel via LLM_PROVIDER) | 13 | Must Have | Done | Sprint 1 |
| US-029 | Como aluno, quero que o chatbot lembre do contexto da conversa, **para que** eu nao precise repetir informacoes ja fornecidas em mensagens anteriores | 1. Ultimas 20 mensagens reconstruidas do banco a cada invocacao<br>2. Reiniciar container nao perde historico<br>3. Sessoes distintas nao compartilham memoria | 8 | Must Have | Done | Sprint 1 |
| US-030 | Como aluno, quero que o chatbot consulte documentos oficiais (regulamento, FAQ, calendario), **para que** as respostas sejam baseadas em informacoes oficiais e atualizadas da instituicao | 1. RAG busca chunks no PGVector com threshold de similaridade configuravel<br>2. Threshold padrao: 0.45 (ajustavel via RAG_SIMILARITY_THRESHOLD)<br>3. Queries irrelevantes retornam vazio (nao retorna lixo) | 8 | Must Have | Done | Sprint 3 |
| US-031 | Como administrador, quero ingerir documentos na base de conhecimento, **para que** o chatbot tenha acesso a informacoes atualizadas e responda com precisao | 1. `python -m ai_service.ingest` processa 5 documentos<br>2. Documentos: matricula.md, regulamento.pdf, faq.md, calendario.md, curriculo.md<br>3. Gera embeddings e armazena chunks em knowledge_base_chunks<br>4. Categorias: regras_matricula, faq, curriculo, documentos, agendamento, regulamento | 5 | Must Have | Done | Sprint 1 |
| US-032 | Como sistema, devo gerar UUIDs nos action logs do MCP, **para que** o fluxo de logging nunca cause crash por violacao de NOT NULL na coluna id | 1. INSERT em mcp_action_logs inclui gen_random_uuid() para coluna id<br>2. Nenhum NOT NULL violation no fluxo de logging<br>3. Fluxo end-to-end do agente nao quebra por falha de log | 3 | Must Have | Done | Sprint 3 |

**Subtotal Epico 5:** 37 SP — **100% Done**

---

## Epico 6: WhatsApp Webhook e Integracao

| ID | User Story | Criterios de Aceitacao | SP | Prioridade | Status | Sprint |
|----|-----------|----------------------|-----|------------|--------|--------|
| US-033 | Como sistema, devo receber mensagens do WhatsApp com validacao de assinatura, **para que** mensagens forjadas por terceiros sejam rejeitadas antes de qualquer processamento | 1. Validacao HMAC-SHA256 do header X-Hub-Signature-256<br>2. Assinatura invalida = 403<br>3. Corpo da requisicao lido ANTES de qualquer parse JSON | 5 | Must Have | Done | Sprint 1 |
| US-034 | Como sistema, devo responder 200 OK em < 5s e processar em background, **para que** o WhatsApp nao reenvie a mensagem por timeout e o processamento IA ocorra sem bloquear a resposta | 1. Webhook retorna 200 imediatamente<br>2. Processamento IA via asyncio.create_task + add_done_callback<br>3. Falhas no background task sao logadas (nao silenciadas) | 8 | Must Have | Done | Sprint 1 |
| US-035 | Como sistema, devo tratar mensagens de midia com resposta padrao, **para que** o aluno receba feedback imediato e o agente IA nao tente processar conteudo que nao suporta | 1. Audio, imagem, video, documento, sticker, localizacao = resposta padrao<br>2. Tipo de midia registrado em chat_messages<br>3. Nao passa pelo agente IA | 3 | Must Have | Done | Sprint 1 |
| US-036 | Como sistema, devo deduplicar mensagens, **para que** reenvios do WhatsApp nao causem acoes duplicadas como matriculas ou agendamentos repetidos | 1. Coluna whatsapp_message_id com indice parcial unico (WHERE NOT NULL)<br>2. Mensagem com ID existente = ignorada silenciosamente<br>3. Nenhum efeito colateral na duplicata | 3 | Must Have | Done | Sprint 1 |
| US-037 | Como staff, quero visualizar sessoes de chat e logs MCP, **para que** eu monitore a qualidade do atendimento automatizado e identifique falhas rapidamente | 1. Listar sessoes com filtro por aluno e status<br>2. Ver mensagens de uma sessao em ordem cronologica<br>3. Ver logs MCP: tool_name, params, resultado, reasoning, latencia | 5 | Should Have | Done | Sprint 1 |

**Subtotal Epico 6:** 24 SP — **100% Done**

---

## Epico 7: Frontend Mobile (Flutter)

| ID | User Story | Criterios de Aceitacao | SP | Prioridade | Status | Sprint |
|----|-----------|----------------------|-----|------------|--------|--------|
| US-038 | Como aluno, quero fazer login pelo app com OTP, **para que** eu acesse minha area academica pelo celular de forma segura e pratica | 1. Tela de input de email<br>2. Tela de input de OTP (6 digitos)<br>3. JWT armazenado em flutter_secure_storage<br>4. Redirecionamento para dashboard apos login | 5 | Must Have | Done | Sprint 3 |
| US-039 | Como aluno, quero ver meu dashboard academico no app, **para que** eu tenha visao geral da minha situacao academica a qualquer momento pelo celular | 1. Tela com resumo: semestre, CRA, disciplinas<br>2. Lista de disciplinas disponiveis para matricula<br>3. Lista de notas do periodo<br>4. Botao de logout funcional | 8 | Must Have | Done | Sprint 3 |
| US-040 | Como aluno, quero navegar entre telas do app de forma fluida, **para que** a experiencia de uso seja agradavel e eu encontre informacoes sem frustracoes | 1. Navegacao entre Login -> Dashboard -> Detalhes<br>2. Loading states durante requisicoes<br>3. Tratamento de erros (sem tela branca) | 3 | Should Have | Done | Sprint 3 |

**Subtotal Epico 7:** 16 SP — **100% Concluido**

---

## Epico 8: Guardrails e Seguranca do Chatbot

| ID | User Story | Criterios de Aceitacao | SP | Prioridade | Status | Sprint |
|----|-----------|----------------------|-----|------------|--------|--------|
| US-041 | Como sistema, devo rejeitar tentativas de prompt injection, **para que** usuarios maliciosos nao consigam manipular o agente para executar acoes fora do escopo | 1. System prompt contem instrucoes anti-injection<br>2. "Ignore previous instructions" nao funciona<br>3. Agente recusa acoes fora do escopo academico | 5 | Must Have | Done | Sprint 3 |
| US-042 | Como aluno, nao devo conseguir acessar dados de outro aluno via chatbot, **para que** a privacidade de todos os alunos seja garantida mesmo em tentativas deliberadas | 1. Pedir "notas do aluno X" retorna apenas dados proprios<br>2. student_id injetado pelo MCP (nunca do prompt)<br>3. Teste manual documenta cenarios tentados | 3 | Must Have | Done | Sprint 3 |

**Subtotal Epico 8:** 8 SP — **100% Concluido**

---

## Epico 9: Deploy e Operacoes

| ID | User Story | Criterios de Aceitacao | SP | Prioridade | Status | Sprint |
|----|-----------|----------------------|-----|------------|--------|--------|
| US-043 | Como equipe, quero o sistema rodando num servidor acessivel, **para que** consigamos demonstrar o produto ao vivo para a banca avaliadora | 1. Docker instalado no servidor<br>2. `docker compose up` funciona no servidor<br>3. Webhook WhatsApp aponta para o servidor (DNS ou tunnel) | 5 | Must Have | Done | Sprint 4 |
| US-044 | Como equipe, quero um teste end-to-end real no WhatsApp, **para que** validemos o fluxo completo antes da apresentacao e corrijamos falhas a tempo | 1. Mensagem enviada no WhatsApp chega ao servidor<br>2. Resposta gerada pela IA retorna ao WhatsApp<br>3. Tempo de resposta < 30s (incluindo processamento IA) | 5 | Must Have | Done | Sprint 4 |

**Subtotal Epico 9:** 10 SP — **100% Concluido**

---

## Epico 10: Testes

| ID | User Story | Criterios de Aceitacao | SP | Prioridade | Status | Sprint |
|----|-----------|----------------------|-----|------------|--------|--------|
| US-045 | Como desenvolvedor, quero testes de integracao do fluxo de auth completo, **para que** regressoes no login e logout sejam detectadas automaticamente antes de chegar a producao | 1. OTP -> JWT -> logout -> token revogado<br>2. Esgotamento de tentativas -> novo codigo<br>3. Codigo expirado nao conta como tentativa | 3 | Could Have | Done | Sprint 3 |
| US-046 | Como desenvolvedor, quero testes de integracao do fluxo de matricula, **para que** regras de negocio criticas (pre-requisitos, periodos, IDOR) sejam validadas a cada mudanca | 1. Draft -> confirm flow<br>2. Pre-requisito nao cumprido -> rejeicao<br>3. Periodo fechado -> rejeicao<br>4. IDOR prevention test | 3 | Could Have | Done | Sprint 3 |
| US-047 | Como desenvolvedor, quero testes unitarios do calculo de CRA, **para que** erros de ponderacao ou divisao por zero sejam capturados antes de afetar dados reais dos alunos | 1. Ponderacao por creditos correta<br>2. Exclusao de disciplinas em andamento<br>3. Divisao por zero tratada | 2 | Could Have | Done | Sprint 4 |

**Subtotal Epico 10:** 8 SP — **100% Concluido**

---

## Epico 11 — UX Corrections (Phases 18-19)

**Objetivo:** Corrigir navegacao e UX quebrados em ambas as visoes estudante e staff

| ID | User Story | Criterios de Aceitacao (resumo) | Prioridade | SP | Status | Sprint |
|----|------------|--------------------------------|------------|-----|--------|--------|
| US-048 | Como estudante, quero renomear sessoes de chat, filtrar por ativas/inativas e ver documentos com detalhes, para organizar minha comunicacao academica com o Alpha | Chat rename via long-press; filter tabs Ativo/Inativo; document detail bottom sheet com tipo e data | Must Have | 5 | Done | Sprint 4 |
| US-049 | Como estudante, quero que notificacoes tenham estado lido/nao-lido, com filtros, e que agendamentos abriam um painel de detalhe, para gerenciar alertas academicos de forma eficiente | Notificacoes com read/unread styling; bulk mark-all; appointment detail sheet no tap | Must Have | 5 | Done | Sprint 4 |
| US-050 | Como estudante, quero que acoes rapidas do home naveguem corretamente e backend exponha endpoint de renomeacao de chat | Quick actions navegam ao destino correto; PUT /chat-sessions/{id} rename + migracao Alembic 014 | Must Have | 5 | Done | Sprint 4 |

**Subtotal Epico 11a (Estudante):** 3 stories, 15 SP, 100% Concluido

| ID | User Story | Criterios de Aceitacao (resumo) | Prioridade | SP | Status | Sprint |
|----|------------|--------------------------------|------------|-----|--------|--------|
| US-051 | Como staff, quero um painel de agendamentos redesenhado e barra de busca, e poder navegar para telas corretas via KPIs do dashboard, para gerenciar o calendario academico eficientemente | Dashboard KPI navigation com query params; StaffSearchBar widget; appointment detail fields corretos | Must Have | 7 | Done | Sprint 4 |
| US-052 | Como staff, quero tela de documentos com abas corretas e filtro por tipo, e tela de recursos com toggle ativo/inativo e opcao de deletar, para gerenciar documentos e recursos com precisao | Document filter tabs corretos; type filter pills; resource toggle Switch; delete PopupMenu com confirmation | Must Have | 5 | Done | Sprint 4 |
| US-053 | Como staff/provider, quero um modulo de cadastro de estudantes com CRUD completo, para gerenciar o cadastro academico sem depender de outro sistema | StaffCadastroScreen com ExpansionTile cards, FAB, form sheet, busca, filtros; StaffStudentModel | Must Have | 5 | Done | Sprint 4 |
| US-054 | Como staff, quero uma tela unificada de chats com 4 sub-abas e informacoes de contexto do estudante no cabecalho, para acompanhar todas as conversacoes | StaffChatsScreen 4 tabs; chat detail header com student context; backend retorna student_name+RA | Must Have | 9 | Done | Sprint 4 |

**Subtotal Epico 11b (Staff):** 4 stories, 26 SP, 100% Concluido

**Subtotal Epico 11 (total):** 7 stories, 41 SP, 100% Concluido

---

## Epico 12 — AI/LangChain v2 (Phase 20)

**Objetivo:** Completar workflow LangChain com persona Alpha, RAG observabilidade, seguranca de prompt e ciclo de vida de sessao

| ID | User Story | Criterios de Aceitacao (resumo) | Prioridade | SP | Status | Sprint |
|----|------------|--------------------------------|------------|-----|--------|--------|
| US-055 | Como estudante, quero interagir com o chatbot Alpha num estilo amigavel-profissional em portugues, com saudacao personalizada, despedida e timeout de inatividade, para ter uma experiencia de atendimento humanizada | Persona Alpha no system prompt; welcome message com nome; farewell detection (tiered); idle follow-up 5min; auto-close 10min; plain-text output (sem markdown WhatsApp) | Must Have | 21 | Done | Sprint 4 |
| US-056 | Como sistema, quero que o agente AI logue chamadas RAG no banco e permita OTP lazy (leitura sem verificacao), e que inputs maliciosos sejam bloqueados antes de chegar ao LLM, para garantir seguranca e observabilidade da IA | rag_logs table + LangSmith tracing; lazy OTP routing; 4-layer prompt injection defense; MCP verification gate; verification_state propagado ponta-a-ponta | Must Have | 20 | Done | Sprint 4 |

**Subtotal Epico 12:** 2 stories, 41 SP, 100% Concluido

---

## Epico 13 — Auth & Roles Expansion (Phase 21)

**Objetivo:** Adicionar papel provider com CRUD de staff gerenciado por staff senior

| ID | User Story | Criterios de Aceitacao (resumo) | Prioridade | SP | Status | Sprint |
|----|------------|--------------------------------|------------|-----|--------|--------|
| US-057 | Como provider, quero ter acesso a todos os recursos de staff e poder criar/editar/desativar membros da equipe via API, para gerenciar a equipe academica | Alembic 016: status+work_schedule+position+role='provider'; 5 CRUD endpoints /staff/members; require_provider() dependency; auto-protecao contra auto-delecao | Must Have | 7 | Done | Sprint 4 |
| US-058 | Como provider, quero uma 6a aba de Gestao no app Flutter com lista de membros, busca, filtros e formulario de criacao/edicao, para gerenciar a equipe pelo app | StaffGestaoScreen com card list, search, FilterChips; StaffMemberFormScreen (6 campos); GoRouter guard isStaffOrProvider | Must Have | 6 | Done | Sprint 4 |

**Subtotal Epico 13:** 2 stories, 13 SP, 100% Concluido

---

## Epico 14 — FCM Push Notifications (Phase 22)

**Objetivo:** Notificacoes push em tempo real para eventos academicos criticos

| ID | User Story | Criterios de Aceitacao (resumo) | Prioridade | SP | Status | Sprint |
|----|------------|--------------------------------|------------|-----|--------|--------|
| US-059 | Como sistema, quero disparar notificacoes push Firebase para documento_pronto, matricula_confirmada e agendamento_confirmado, de forma nao-bloqueante, com limpeza automatica de tokens invalidos | NotificationService com 3 triggers; asyncio.create_task (fire-and-forget); FcmToken CRUD endpoints; 8 testes unitarios | Must Have | 7 | Done | Sprint 4 |
| US-060 | Como estudante, quero receber notificacoes push no app Flutter para eventos academicos, com navegacao profunda ao recurso correto, tanto em foreground quanto em background/cold-start | Firebase init + background handler; FcmService provider (register/unregister no auth lifecycle); foreground snackbar "Ver"; deep-link navigation por evento | Must Have | 6 | Done | Sprint 4 |

**Subtotal Epico 14:** 2 stories, 13 SP, 100% Concluido

---

## Epico 15 — Novas Features (Phase 23)

**Objetivo:** Features novas de valor para estudantes: cardapio do RU, perfil do estudante, grade curricular

| ID | User Story | Criterios de Aceitacao (resumo) | Prioridade | SP | Status | Sprint |
|----|------------|--------------------------------|------------|-----|--------|--------|
| US-061 | Como estudante, quero ver o cardapio semanal do restaurante universitario no app, para planejar minhas refeicoes | Tela de cardapio com dados por dia da semana e tipo de refeicao; backend com endpoint /cardapio | Should Have | 7 | To Do | Sprint 4 |
| US-062 | Como estudante, quero ver e editar meu perfil (foto, contato, configuracoes), para manter meus dados cadastrais atualizados | Tela de perfil com avatar, campos editaveis (telefone, preferencias); PUT /students/{id}/profile | Should Have | 7 | To Do | Sprint 4 |
| US-063 | Como estudante, quero visualizar minha grade curricular com progresso de conclusao por disciplina, para planejar meu curso | Tela de grade curricular com disciplinas agrupadas por semestre; indicador de status (cursando/concluida/pendente) | Should Have | 7 | To Do | Sprint 4 |

**Subtotal Epico 15:** 3 stories, 21 SP, 0% Concluido (planejado Sprint 4)

---

## Epico 16 — UI Polish v3 (Phase 24)

**Objetivo:** Polimento visual e integracao final do milestone v3.0

| ID | User Story | Criterios de Aceitacao (resumo) | Prioridade | SP | Status | Sprint |
|----|------------|--------------------------------|------------|-----|--------|--------|
| US-064 | Como usuario, quero que o app tenha consistencia visual, animacoes fluidas e integracao completa entre todos os modulos do v3.0, sem regressions de UI | Audit visual completo; correcoes de overflow e contraste; animacoes page transitions; testes E2E pos-merge | Could Have | 13 | To Do | Sprint 4 |

**Subtotal Epico 16:** 1 story, 13 SP, 0% Concluido (planejado Sprint 4)

---

## Resumo por Prioridade

| Prioridade | Total SP | Done | Restante |
|------------|----------|------|----------|
| Must Have | 207 | 207 | 0 |
| Must Have (v3.0) | 64 | 64 | 0 |
| Should Have | 18 | 18 | 0 |
| Should Have (v3.0) | 21 | 0 | 21 |
| Could Have | 8 | 8 | 0 |
| Could Have (v3.0) | 13 | 0 | 13 |
| **Total** | **375** | **341 (91%)** | **34** |

---

## Velocidade Observada

- **Sprint 1 (15-30 Abr):** 193 SP entregues em 16 dias
- **Velocidade media:** ~12 SP/dia
- **Sprint 3 (1-6 Mai):** 40 SP entregues em 6 dias = 8 SP/dia
- **Sprint 4 (7-11 Mai):** Deploy, testes finais, validacao end-to-end + v3.0 Fases 18-22 concluidas
- **v3.0 Fases 18-22:** 108 SP entregues (Epicos 11-14)
- **v3.0 Fases 23-24:** 34 SP restantes (Epicos 15-16, planejado Sprint 4)
- **Status atual:** 341/375 SP entregues — **91% concluido**
