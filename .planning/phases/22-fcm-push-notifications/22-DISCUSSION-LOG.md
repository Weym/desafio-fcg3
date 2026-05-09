# Phase 22: FCM Push Notifications - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-08
**Phase:** 22-fcm-push-notifications
**Areas discussed:** Registro e ciclo de vida do token, Disparo e conteudo das notificacoes, Comportamento foreground vs background, Deep-link e navegacao no tap, Configuracao Firebase, Permissoes e opt-out, Testes e validacao

---

## Registro e Ciclo de Vida do Token

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Imediatamente apos login | Garante que notificacoes funcionam assim que o usuario autentica | ✓ |
| No primeiro acesso a tela que gera notificacoes | Adia o registro ate ser necessario | |

**User's choice:** Imediatamente apos login
**Notes:** —

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Remover do backend (DELETE endpoint) | Evita notificacoes em dispositivos deslogados | ✓ |
| Manter e desativar (soft delete / flag) | Token fica marcado como inativo | |
| Voce decide | Agente escolhe | |

**User's choice:** Remover do backend (DELETE endpoint)
**Notes:** —

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Seguir docs/api.md (PUT /students/{id}/fcm-token) | Mantém consistência com documentacao existente | ✓ |
| POST /auth/fcm-token (mais simples) | Token registrado sem expor student_id na URL | |
| Voce decide | Agente decide | |

**User's choice:** Seguir docs/api.md (PUT /students/{id}/fcm-token)
**Notes:** —

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Sim, todos os dispositivos registrados | Tabela ja suporta (UniqueConstraint student_id+token) | ✓ |
| Apenas o ultimo dispositivo logado | Simplifica envio | |

**User's choice:** Sim, todos os dispositivos registrados
**Notes:** —

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Sim, remover na falha de envio | Ao receber erro 'token not registered', deletar da tabela | ✓ |
| Manter e marcar como invalido | Soft-mark para historico | |
| Voce decide | Agente decide | |

**User's choice:** Sim, remover na falha de envio
**Notes:** —

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Sim, onTokenRefresh listener | Ouve Firebase onTokenRefresh, envia novo token automaticamente | ✓ |
| Apenas no proximo login | Mais simples, janela de perda | |

**User's choice:** Sim, onTokenRefresh listener
**Notes:** —

---

## Disparo e Conteudo das Notificacoes

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Notification service centralizado | Modulo backend/src/features/notifications/ com send_notification() | ✓ |
| Inline nos services existentes | Cada service importa firebase-admin e envia diretamente | |
| Event-driven com background tasks | Emit evento via asyncio, listener centralizado | |

**User's choice:** Notification service centralizado
**Notes:** —

| Option | Description | Selected |
| ------ | ----------- | -------- |
| notification + data | Sistema mostra banner em background, Flutter controla em foreground | ✓ |
| Apenas data message | Flutter tem controle total sobre quando/como exibir | |
| Voce decide | Agente decide | |

**User's choice:** notification + data
**Notes:** —

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Personalizado com dados | Ex: 'Documento pronto: Historico Escolar' | ✓ |
| Texto fixo por tipo | Ex: 'Voce tem um documento pronto' | |
| Voce decide | Agente decide | |

**User's choice:** Personalizado com dados
**Notes:** —

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Sempre enviar, Flutter decide se exibe | Backend sempre dispara, Flutter suprime em foreground | |
| Backend verifica estado antes de enviar | Tracked se usuario esta online na tela de chat | |
| Voce decide | Agente decide | |

**User's choice:** (Free-text) "Nao e necessario haver chat_reply, ja que ele vai interagir em tempo real com o bot."
**Notes:** Evento chat_reply removido da lista. Interacao com bot e real-time.

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Remover action_status tambem | Action status e interno ao fluxo MCP | ✓ |
| Manter action_status | Aluno recebe push quando acao muda de status | |
| Voce decide | Agente avalia | |

**User's choice:** Remover action_status tambem
**Notes:** Ficam 3 eventos: document_ready, enrollment_confirmed, appointment_confirmed

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Background task com asyncio.create_task | Nao bloqueia a response. Padrao do projeto | ✓ |
| Sincrono inline | Mais simples mas adiciona latencia | |
| Voce decide | Agente decide | |

**User's choice:** Background task com asyncio.create_task
**Notes:** —

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Log error e descarta (fire-and-forget) | Notificacao perdida nao e critica | ✓ |
| Retry uma vez | Tentativa extra em caso de erro transitorio | |
| Voce decide | Agente decide | |

**User's choice:** Log error e descarta (fire-and-forget)
**Notes:** —

---

## Comportamento Foreground vs Background

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Banner local (flutter_local_notifications) | Mostra notificacao como se fosse do sistema | |
| Snackbar/Toast in-app | Exibe dentro do app (MaterialBanner ou SnackBar) | ✓ |
| Suprimir (nao mostrar nada) | App aberto, usuario ja ve a mudanca | |
| Voce decide | Agente decide | |

**User's choice:** Snackbar/Toast in-app
**Notes:** —

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Com acao de navegar | Snackbar com botao 'Ver' ou tap que leva a tela relevante | ✓ |
| Apenas informativo | Mostra a informacao e desaparece | |

**User's choice:** Com acao de navegar
**Notes:** —

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Padrao do sistema | Usa som e vibracao default do dispositivo | ✓ |
| Custom sound | Som especifico da app | |
| Silencioso (apenas visual) | Sem som ou vibracao | |

**User's choice:** Padrao do sistema
**Notes:** —

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Suprimir se ja esta na tela relevante | Evita redundancia | ✓ |
| Mostrar snackbar sempre | Garante que usuario perceba a mudanca | |
| Voce decide | Agente decide | |

**User's choice:** Suprimir se ja esta na tela relevante
**Notes:** —

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Sim, refresh automatico | Se esta na tela e notificacao chega, recarrega a lista | ✓ |
| Nao, usuario faz pull-to-refresh | Mais previsivel | |

**User's choice:** Sim, refresh automatico
**Notes:** —

---

## Deep-link e Navegacao no Tap

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Tela de lista com item destacado | document_ready -> Documentos com drawer aberto no documento | ✓ |
| Apenas para a tela da feature | Navega para /documents, /enrollments sem abrir item | |
| Voce decide | Agente decide | |

**User's choice:** Tela de lista com item destacado
**Notes:** —

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Login screen, depois navega ao destino | GoRouter redireciona para login, depois volta | ✓ |
| Login screen sem preservar destino | Login e vai para home | |
| Voce decide | Agente decide | |

**User's choice:** Login screen, depois navega ao destino
**Notes:** —

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Sim, navegar apos cold start | getInitialMessage() detecta notificacao que abriu o app | ✓ |
| Nao, vai para home normal | Cold start sempre vai para home | |

**User's choice:** Sim, navegar apos cold start
**Notes:** —

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Arquivo de config dedicado (notification_routes.dart) | Mapa centralizado tipo -> rota | ✓ |
| Dentro do notification handler | Logica de routing inline | |
| Voce decide | Agente decide | |

**User's choice:** Arquivo de config dedicado (notification_routes.dart)
**Notes:** —

---

## Configuracao Firebase

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Precisa ser criado | Nao existe projeto Firebase ainda | ✓ |
| Ja existe, so integrar | Projeto Firebase ja configurado | |

**User's choice:** Precisa ser criado
**Notes:** —

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Volume mount / env var com path | FCM_CREDENTIALS_PATH ja configurado no docker-compose | ✓ |
| Base64 em env var | Service account JSON encodado em base64 | |
| Voce decide | Agente decide | |

**User's choice:** Volume mount / env var com path
**Notes:** —

| Option | Description | Selected |
| ------ | ----------- | -------- |
| FlutterFire CLI | Gera firebase_options.dart automaticamente | ✓ |
| Configuracao manual | Baixar google-services.json manualmente | |
| Voce decide | Agente decide | |

**User's choice:** FlutterFire CLI
**Notes:** —

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Android + iOS apenas | FCM push funciona nativamente so em mobile | ✓ |
| Android + iOS + Web | PWA/web tambem recebe push | |
| Voce decide | Agente avalia | |

**User's choice:** Android + iOS apenas
**Notes:** —

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Commitar no repo | google-services.json e firebase_options.dart nao contem secrets | ✓ |
| Adicionar ao .gitignore | Cada dev precisa configurar Firebase localmente | |
| Voce decide | Agente decide | |

**User's choice:** Commitar no repo
**Notes:** —

---

## Permissoes e Opt-out do Usuario

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Imediatamente apos primeiro login | Contexto claro, taxa de aceitacao boa | ✓ |
| No primeiro evento que geraria push | Mais contextual mas demora | |
| Tela de onboarding/boas-vindas | Explica beneficios | |

**User's choice:** Imediatamente apos primeiro login
**Notes:** —

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Nao, tudo ou nada nesta fase | MVP: permissao e global. Preferencias em Phase 23 | ✓ |
| Sim, preferencias por tipo | Tela de preferencias com toggles por evento | |
| Voce decide | Agente decide | |

**User's choice:** Nao, tudo ou nada nesta fase
**Notes:** —

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Respeitar e mostrar banner sutil | Nao incomodar. Aviso em perfil | ✓ |
| Pedir novamente apos X dias | Re-prompt periodico | |
| Nunca mais perguntar | Permissao negada e final | |

**User's choice:** Respeitar e mostrar banner sutil, mas nao com link para settings porque nao existe settings.
**Notes:** Nao existe tela de settings no app. Banner apenas informativo.

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Nao registrar se negou | Sem permissao = sem token disponivel | ✓ |
| Registrar mesmo assim | Android token existe mesmo sem permissao | |
| Voce decide | Agente decide | |

**User's choice:** Nao registrar se negou
**Notes:** —

---

## Testes e Validacao

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Mock do firebase-admin no backend | Unit tests com mock do send(). Sem Firebase real em CI | ✓ |
| Firebase Emulator Suite | Emulador local do Firebase | |
| Voce decide | Agente decide | |

**User's choice:** Mock do firebase-admin no backend
**Notes:** —

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Sim, mock com condicao de plataforma | Testes existentes continuam passando. Novos cobrem handler | ✓ |
| Sem mock, so testes manuais em device | Testes unitarios nao cobrem FCM | |
| Voce decide | Agente decide | |

**User's choice:** Sim, mock com condicao de plataforma
**Notes:** —

---

## Agent's Discretion

- Exact snackbar duration and styling
- Notification channel configuration for Android
- Error handling flow when token registration fails
- Internal structure of notification service (class vs functions)

## Deferred Ideas

- Granular notification preferences per event type → Phase 23 (PERF-01)
- Web push notifications → separate infrastructure, own phase
- Notification history/inbox evolution → Phase 18 corrections area
- WhatsApp template messages for proactive notifications → FUTURE-07
