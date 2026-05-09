# Phase 6: WhatsApp Webhook & Integration - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md -- this log preserves the alternatives considered.

**Date:** 2026-04-23
**Phase:** 06-whatsapp-webhook-integration
**Areas discussed:** Verificacao de identidade WhatsApp, Falha no background task & UX, Ciclo de vida da chat session, Organizacao do test suite

---

## Verificacao de Identidade WhatsApp

| Option | Description | Selected |
|--------|-------------|----------|
| Inferir do historico | Ler ultimas mensagens de chat_messages para descobrir estado. Fragil mas sem mudanca de schema. | |
| Adicionar coluna verification_state | Enum (unverified, awaiting_email, awaiting_code, verified) no chat_sessions. Mais robusto. | X |
| Voce decide | Agente decide | |

**User's choice:** Adicionar coluna verification_state
**Notes:** Resolve o gap do schema identificado no SUMMARY.md de forma limpa.

---

| Option | Description | Selected |
|--------|-------------|----------|
| No webhook handler | Verificacao pre-agent, aluno nao verificado nunca chega ao LangChain. Mais seguro e rapido. | X |
| No AI Service | Agente LangChain gerencia verificacao como parte da conversa. | |
| Voce decide | Agente decide | |

**User's choice:** No webhook handler (FastAPI)
**Notes:** Fluxo mecanico nao precisa de LLM.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Mensagem generica amigavel | "Nao encontrei cadastro..." Nao cria chat_session para desconhecidos. | X |
| Criar sessao sem aluno | Cria chat_session com student_id=null, tenta verificar via email. | |
| Voce decide | Agente decide | |

**User's choice:** Mensagem generica amigavel
**Notes:** Telefone deve estar pre-registrado em students.phone.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Normalizacao simples | Formato internacional sem + (5521999999999). Comparacao direta. | X |
| Comparacao exata | Confia que students.phone ja tem formato correto. | |
| Voce decide | Agente decide | |

**User's choice:** Normalizacao simples

---

**Sessao verificada expira?**
**User's choice:** "QUEM FAZ ISSO EH O AUTH. ESQUEÇA ISSO JOVEM. foi definido que seria o jwt de 1h e refresh token de uma semana."
**Notes:** Expiracao segue ciclo de vida do JWT/refresh token do Phase 2. Nao e decisao do Phase 6.

---

## Falha no Background Task & UX

| Option | Description | Selected |
|--------|-------------|----------|
| Mensagem de fallback automatica | done_callback detecta excecao, envia fallback ao aluno. | |
| Apenas log, sem resposta | Loga excecao, aluno fica sem resposta. | |
| Retry uma vez, depois fallback | Tenta AI service de novo. Se falhar, envia fallback. | X |

**User's choice:** Retry uma vez, depois fallback

---

| Option | Description | Selected |
|--------|-------------|----------|
| Retry simples + log | Uma retentativa no POST ao Graph API. Se falhar, loga. Mensagem salva em chat_messages. | X |
| Apenas log, sem retry | Se POST falhar, loga e segue. | |
| Voce decide | Agente decide | |

**User's choice:** Retry simples + log

---

| Option | Description | Selected |
|--------|-------------|----------|
| Sim, modulo dedicado | whatsapp_client.py em infrastructure/ com metodos encapsulados. httpx.AsyncClient singleton. | X |
| Inline no webhook handler | Chamadas httpx direto no handler. | |
| Voce decide | Agente decide | |

**User's choice:** Sim, modulo dedicado

---

| Option | Description | Selected |
|--------|-------------|----------|
| Lock por sessao | asyncio.Lock por chat_session_id. Mensagens sequenciais do mesmo aluno. | X |
| Sem protecao no MVP | Aceita race condition. | |
| Voce decide | Agente decide | |

**User's choice:** Lock por sessao

---

## Ciclo de Vida da Chat Session

| Option | Description | Selected |
|--------|-------------|----------|
| Reutiliza sessao ativa | Uma sessao por telefone enquanto ativa. Mensagens novas na mesma sessao. | X |
| Nova sessao a cada dia | Nova sessao apos 24h+ de inatividade. | |
| Voce decide | Agente decide | |

**User's choice:** Reutiliza sessao ativa

---

**Como fechar sessao?**
**User's choice:** "ambas as opcoes 2 e 3. A sessao encerra automaticamente e o aluno pode optar por encerrar manualmente"
**Notes:** Auto-close por inatividade (24h) + aluno pode digitar "sair"/"encerrar".

---

| Option | Description | Selected |
|--------|-------------|----------|
| 24 horas | Sessao fecha apos 24h sem mensagem. | X |
| 48 horas | Mais flexivel. | |
| 1 hora | Sessao curta. | |

**User's choice:** 24 horas

---

**Mecanismo de auto-close:**
**User's choice:** pg_cron (mesmo sendo listado como pos-MVP)
**Notes:** Usuario questionou se pg_cron tem desvantagens. Apos explicacao (Docker image customizada, complexidade adicional, overkill para o caso), optou por pg_cron mesmo assim. Override explicito do constraint original de PROJECT.md.

---

## Organizacao do Test Suite

| Option | Description | Selected |
|--------|-------------|----------|
| Tudo na Phase 6 | Escrever TEST-01 a TEST-05 de uma vez na Phase 6. | |
| Cada phase escreve seus testes | Phase 2: TEST-01, Phase 3: TEST-02/03, Phase 6: TEST-04/05. | X |
| Voce decide | Agente decide | |

**User's choice:** Cada phase escreve seus testes

---

| Option | Description | Selected |
|--------|-------------|----------|
| Phase 4 (MCP Server) | TEST-05 valida X-Service-Token do ponto de vista do MCP. | |
| Phase 6 (integracao) | Manter TEST-05 como teste de integracao E2E na Phase 6. | X |
| Phase 2 (auth middleware) | Middleware vive no Phase 2, testar la. | |

**User's choice:** Phase 6 (junto com outros integracao)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Phase 1 (Infra & Schema) | Cria infra base de testes junto com infra do projeto. | X |
| Phase 2 (junto com auth) | Phase 2 cria infra de testes quando precisa deles. | |
| Voce decide | Agente decide | |

**User's choice:** Phase 1 (Infra & Schema)

---

| Option | Description | Selected |
|--------|-------------|----------|
| Testes especificados + unitarios chave | TEST-04/05 + unitarios para pontos criticos. | |
| Apenas TEST-04 e TEST-05 | Minimo viavel dos requisitos. | |
| Cobertura completa | Testes para TODOS os endpoints e servicos do Phase 6. | X |

**User's choice:** Cobertura completa

---

| Option | Description | Selected |
|--------|-------------|----------|
| Mock httpx | Mockar httpx.AsyncClient para WhatsApp e AI Service. | X |
| Test containers para AI service | Subir AI service em container de teste. | |
| Voce decide | Agente decide | |

**User's choice:** Mock httpx

---

## Agent's Discretion

- Exact verification state machine transition enforcement
- Background task retry timing (immediate vs short delay)
- asyncio.Lock storage mechanism
- pg_cron schedule interval
- Chat visibility endpoint pagination details
- WhatsApp client connection pool sizing
- "sair"/"encerrar" keyword detection approach

## Deferred Ideas

- Whisper API for audio transcription (post-MVP)
- GPT-4o Vision for image analysis (post-MVP)
- Redis cache for conversation sessions (post-MVP)
- FCM push notifications for chat_reply events (out of scope this cycle)
