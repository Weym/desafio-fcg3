# Requirements: Desafio FCG3 — v3.0

**Defined:** 2026-05-08
**Core Value:** Aluno envia mensagem no WhatsApp e recebe resposta precisa sobre sua situação acadêmica — com ações concretas executadas em tempo real.

## v3.0 Requirements

Requirements for milestone v3.0. Each maps to roadmap phases.

### Student UX Corrections

- [ ] **STUX-01**: Botão "Agendamentos" nas ações rápidas redireciona para o agendamento mais próximo do aluno
- [ ] **STUX-02**: Botão "Solicitar documentos" redireciona para tela de documentos com drawer de adicionar já aberto
- [ ] **STUX-03**: Ação rápida "Conversar com mentor" removida da tela principal
- [ ] **STUX-04**: Tab de suporte adicionada ao header da aplicação
- [ ] **STUX-05**: Chat permite renomear sessão (nome default gerado pela IA)
- [ ] **STUX-06**: Chat possui filtro entre sessões ativas e inativas
- [ ] **STUX-07**: Chat possui ordenação por data
- [ ] **STUX-08**: Documentos exibem tipo e data com hora em cada item
- [ ] **STUX-09**: Clique no documento abre drawer com informações completas
- [ ] **STUX-10**: Adicionar documento usa drawer (mesmo design da tela de recursos)
- [ ] **STUX-11**: Avisos possuem estado de visualizado/não visualizado com filtro
- [ ] **STUX-12**: Botão "visualizar todos" marca todas notificações como lidas
- [ ] **STUX-13**: Notificação só marca como visualizada ao clicar diretamente nela
- [ ] **STUX-14**: Tela de avisos reposicionada para botão no header (removida do menu inferior)
- [ ] **STUX-15**: Agendamentos do student mostram detalhes via drawer ao clicar

### Staff UX Corrections

- [ ] **SFUX-01**: Dashboard — taxa de resolução automatizada com truncamento de casas decimais
- [ ] **SFUX-02**: Dashboard — "Docs pendentes" aplica filtro automaticamente ao navegar
- [ ] **SFUX-03**: Dashboard — "Chats hoje" aplica filtro de data automaticamente ao navegar
- [ ] **SFUX-04**: Agendamentos — detalhamento mostra Nome, RA, data emissão, recurso
- [ ] **SFUX-05**: Agendamentos — card exibe nome e recurso (não motivo)
- [ ] **SFUX-06**: Agendamentos — confirmar agendamento funciona corretamente
- [ ] **SFUX-07**: Agendamentos — search por RA ou nome de aluno
- [ ] **SFUX-08**: Chats — tab de navegação para tela de chats no menu
- [ ] **SFUX-09**: Chats — identificação mostra nome do aluno + número formatado
- [ ] **SFUX-10**: Chats — header ao entrar no chat com nome, RA e dados da sessão
- [ ] **SFUX-11**: Intervenção — acessível para teste após correção LangChain
- [ ] **SFUX-12**: Intervenção — widgets adequados ao padrão (drawer, search por Nome/RA/Telefone)
- [ ] **SFUX-13**: Intervenção — tab de concluídos adicionada
- [ ] **SFUX-14**: Documentos — tabs para "processando" e "prontos"
- [ ] **SFUX-15**: Documentos — filtro por tipo de documento
- [ ] **SFUX-16**: Documentos — visualização completa dos dados da solicitação ao clicar
- [ ] **SFUX-17**: Documentos — widget de adicionar/editar segue padrão drawer
- [ ] **SFUX-18**: Documentos — mensagem de erro clara ao finalizar sem arquivo anexado
- [ ] **SFUX-19**: Recursos — toggle ativar/desativar com feedback visual correto
- [ ] **SFUX-20**: Recursos — opção de deletar recurso
- [ ] **SFUX-21**: Cadastro — tela CRUD completa para alunos (cadastrar, visualizar, editar, remover, ativar/desativar)
- [ ] **SFUX-22**: Cadastro — lista de alunos como cards com menu 3 pontos (editar, excluir, ativar/desativar) e indicador de estado
- [ ] **SFUX-23**: Cadastro — botão flutuante "+" para adicionar aluno
- [ ] **SFUX-24**: Cadastro — expansão do card mostra informações pessoais
- [ ] **SFUX-25**: Cadastro — search por nome + filtro estado + filtro avançado (RA, número, nome)

### LangChain Workflow

- [x] **LANG-01**: Agente detecta início de sessão e envia welcome message via template
- [ ] **LANG-02**: Agente detecta fim de sessão (timeout ou despedida) e envia goodbye + atualiza status
- [ ] **LANG-03**: RAG responde perguntas acadêmicas com base em knowledge base
- [ ] **LANG-04**: MCP tool calling executa ações no backend via session context
- [ ] **LANG-05**: Respostas fora de escopo são tratadas educadamente redirecionando ao acadêmico
- [ ] **LANG-06**: Falha de atendimento ativa intervenção humana automaticamente
- [ ] **LANG-07**: System prompt define persona, instruções operacionais e ações disponíveis
- [x] **LANG-08**: Mídia recebida (imagem/áudio) recebe rejeição educada e criativa
- [ ] **LANG-09**: Prompt injection defense via hardening + sanitização + canary tokens
- [ ] **LANG-10**: Logging estruturado para RAG (chunks recuperados, similarity score)
- [ ] **LANG-11**: Logging estruturado para MCP (tool call, params, resultado, latência)
- [ ] **LANG-12**: Debug tooling para fluxo geral do LangChain (traceability de decisões)
- [ ] **LANG-13**: Log do RAG visível nos chats do staff (quantidade chunks, score)
- [ ] **LANG-14**: Lazy loading do OTP na conversa do WhatsApp (sem bloqueio desnecessário)

### Roles & Auth

- [ ] **ROLE-01**: Role provider adicionada ao sistema JWT (student/staff/provider)
- [ ] **ROLE-02**: Provider herda funcionalidades do staff
- [ ] **ROLE-03**: Provider pode cadastrar, editar, ativar/desativar e remover staff
- [ ] **ROLE-04**: Staff pode cadastrar, editar, ativar/desativar e remover students
- [ ] **ROLE-05**: Tela de cadastro Provider com 2 tabs (staff + aluno) e CRUDs separados
- [ ] **ROLE-06**: Staff cadastra aluno com: nome, email, celular, endereço, RA, período, campus
- [ ] **ROLE-07**: Provider cadastra staff com: nome, email, celular, cargo/função, horário de trabalho

### FCM Push Notifications

- [ ] **FCM-01**: Flutter registra FCM token no login e envia ao backend
- [ ] **FCM-02**: Backend armazena/atualiza FCM tokens por dispositivo
- [ ] **FCM-03**: Notificação push enviada quando documento fica pronto
- [ ] **FCM-04**: Notificação push enviada quando matrícula é confirmada
- [ ] **FCM-05**: Notificação push enviada quando agendamento é confirmado
- [ ] **FCM-06**: Notificação push enviada para nova mensagem de chat
- [ ] **FCM-07**: Notificação push exibida na barra de notificações do celular (foreground + background)
- [ ] **FCM-08**: Tap na notificação navega para a tela relevante no app

### Features Novas — Cardápio

- [ ] **CARD-01**: Staff/provider pode cadastrar cardápio semanal (texto por dia)
- [ ] **CARD-02**: Student visualiza cardápio da semana com navegação por dia
- [ ] **CARD-03**: Exibição visual clara dos dias da semana com detalhes ao clicar

### Features Novas — Perfil

- [ ] **PERF-01**: Student visualiza e edita dados do app (foto, nome, preferências de notificação)
- [ ] **PERF-02**: Student visualiza dados acadêmicos (RA, curso, período, campus, notas)
- [ ] **PERF-03**: Tela de perfil integrada à navegação principal

### Features Novas — Grade Curricular

- [ ] **GRAD-01**: Student visualiza grade curricular em formato de calendário semanal
- [ ] **GRAD-02**: Cada aula exibe horário, professor e descrição da matéria
- [ ] **GRAD-03**: Calendário mostra apenas aulas em que o aluno está inscrito

### UI & Polish

- [ ] **UIPOL-01**: Splash screen customizada substitui splash padrão Flutter
- [ ] **UIPOL-02**: Dashboard staff/provider exibe métricas adicionais relevantes
- [ ] **UIPOL-03**: Navegação end-to-end coerente após todas correções aplicadas

## Future Requirements

### Deferred

- **FUTURE-01**: Whisper API — transcrição de áudio
- **FUTURE-02**: GPT-4o Vision — análise de imagens
- **FUTURE-03**: Redis cache para sessões de conversa
- **FUTURE-04**: pg_cron para limpeza automática
- **FUTURE-05**: Sentry / monitoramento externo
- **FUTURE-06**: Offline-first / local caching strategy
- **FUTURE-07**: Templates aprovados WhatsApp Business para mensagens proativas

## Out of Scope

| Feature | Reason |
|---------|--------|
| Google Calendar integration | Simplificado para calendário interno no app |
| Transcrição de áudio (Whisper) | Pós-MVP, mídia recebe rejeição educada |
| Análise de imagens (GPT-4o Vision) | Pós-MVP |
| Real-time chat WebSocket | HTTP polling suficiente para MVP |
| OAuth login | OTP email suficiente para todos os roles |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| STUX-01 | Phase 18 | Pending |
| STUX-02 | Phase 18 | Pending |
| STUX-03 | Phase 18 | Pending |
| STUX-04 | Phase 18 | Pending |
| STUX-05 | Phase 18 | Pending |
| STUX-06 | Phase 18 | Pending |
| STUX-07 | Phase 18 | Pending |
| STUX-08 | Phase 18 | Pending |
| STUX-09 | Phase 18 | Pending |
| STUX-10 | Phase 18 | Pending |
| STUX-11 | Phase 18 | Pending |
| STUX-12 | Phase 18 | Pending |
| STUX-13 | Phase 18 | Pending |
| STUX-14 | Phase 18 | Pending |
| STUX-15 | Phase 18 | Pending |
| SFUX-01 | Phase 19 | Pending |
| SFUX-02 | Phase 19 | Pending |
| SFUX-03 | Phase 19 | Pending |
| SFUX-04 | Phase 19 | Pending |
| SFUX-05 | Phase 19 | Pending |
| SFUX-06 | Phase 19 | Pending |
| SFUX-07 | Phase 19 | Pending |
| SFUX-08 | Phase 19 | Pending |
| SFUX-09 | Phase 19 | Pending |
| SFUX-10 | Phase 19 | Pending |
| SFUX-11 | Phase 19 | Pending |
| SFUX-12 | Phase 19 | Pending |
| SFUX-13 | Phase 19 | Pending |
| SFUX-14 | Phase 19 | Pending |
| SFUX-15 | Phase 19 | Pending |
| SFUX-16 | Phase 19 | Pending |
| SFUX-17 | Phase 19 | Pending |
| SFUX-18 | Phase 19 | Pending |
| SFUX-19 | Phase 19 | Pending |
| SFUX-20 | Phase 19 | Pending |
| SFUX-21 | Phase 19 | Pending |
| SFUX-22 | Phase 19 | Pending |
| SFUX-23 | Phase 19 | Pending |
| SFUX-24 | Phase 19 | Pending |
| SFUX-25 | Phase 19 | Pending |
| LANG-01 | Phase 20 | Complete |
| LANG-02 | Phase 20 | Pending |
| LANG-03 | Phase 20 | Pending |
| LANG-04 | Phase 20 | Pending |
| LANG-05 | Phase 20 | Pending |
| LANG-06 | Phase 20 | Pending |
| LANG-07 | Phase 20 | Pending |
| LANG-08 | Phase 20 | Complete |
| LANG-09 | Phase 20 | Pending |
| LANG-10 | Phase 20 | Pending |
| LANG-11 | Phase 20 | Pending |
| LANG-12 | Phase 20 | Pending |
| LANG-13 | Phase 20 | Pending |
| LANG-14 | Phase 20 | Pending |
| ROLE-01 | Phase 21 | Pending |
| ROLE-02 | Phase 21 | Pending |
| ROLE-03 | Phase 21 | Pending |
| ROLE-04 | Phase 21 | Pending |
| ROLE-05 | Phase 21 | Pending |
| ROLE-06 | Phase 21 | Pending |
| ROLE-07 | Phase 21 | Pending |
| FCM-01 | Phase 22 | Pending |
| FCM-02 | Phase 22 | Pending |
| FCM-03 | Phase 22 | Pending |
| FCM-04 | Phase 22 | Pending |
| FCM-05 | Phase 22 | Pending |
| FCM-06 | Phase 22 | Pending |
| FCM-07 | Phase 22 | Pending |
| FCM-08 | Phase 22 | Pending |
| CARD-01 | Phase 23 | Pending |
| CARD-02 | Phase 23 | Pending |
| CARD-03 | Phase 23 | Pending |
| PERF-01 | Phase 23 | Pending |
| PERF-02 | Phase 23 | Pending |
| PERF-03 | Phase 23 | Pending |
| GRAD-01 | Phase 23 | Pending |
| GRAD-02 | Phase 23 | Pending |
| GRAD-03 | Phase 23 | Pending |
| UIPOL-01 | Phase 24 | Pending |
| UIPOL-02 | Phase 24 | Pending |
| UIPOL-03 | Phase 24 | Pending |

**Coverage:**
- v3.0 requirements: 81 total (corrected from initial 68 estimate)
- Mapped to phases: 81
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-08*
*Last updated: 2026-05-08 — traceability mapped by roadmapper*
