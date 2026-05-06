# Phase 14: Human Intervention - Context

**Gathered:** 2026-05-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Implementar sistema de intervenção humana: o bot pode escalar conversas para atendimento humano, o gestor vê lista de chats pendentes e pode assumir uma conversa, respondendo diretamente ao aluno via WhatsApp. Sem transferência entre staff (D simples: um gestor assume e resolve).

A funcionalidade requer mudanças no backend (novo status de sessão, endpoint de envio de mensagem, trigger de escalação no AI), no frontend staff (nova tela "Intervenção"), e no fluxo do chatbot (detecção de necessidade de humano).

</domain>

<decisions>
## Implementation Decisions

### Status e Escalação

- **D-01:** Adicionar status `'human_needed'` e `'human_active'` ao CHECK constraint de `chat_sessions.status`. Fluxo: `active` → `human_needed` (bot escala) → `human_active` (gestor assume) → `closed` (resolvido).
- **D-02:** Adicionar campo `assigned_staff_id` (UUID, FK → staff.id, nullable) à tabela `chat_sessions` para rastrear quem assumiu.
- **D-03:** Status simples: Pendente (`human_needed`) → Em atendimento (`human_active`) → Resolvido (`closed`). 3 status conforme discutido.
- **D-04:** Sem transferência entre staff. Quem assume é responsável até resolver.

### Triggers de Escalação

- **D-05:** O bot escala automaticamente quando: (a) responde "procurar a secretaria" ou (b) aluno digita palavras-chave como "atendente", "humano", "pessoa", "secretaria".
- **D-06:** Quando escalado, o bot envia mensagem ao aluno: "Vou transferir você para um atendente. Aguarde um momento." e muda status da sessão para `human_needed`.
- **D-07:** Enquanto sessão está em `human_needed` ou `human_active`, o AI service NÃO processa novas mensagens do aluno — elas são salvas no DB mas não invocam o agente.

### Endpoint de Resposta do Staff

- **D-08:** Criar endpoint `POST /chat-sessions/{id}/reply` — staff envia mensagem de texto, que é salva como `role='assistant'` no DB e enviada via WhatsApp API ao aluno.
- **D-09:** O endpoint valida: sessão existe, está em `human_active`, `assigned_staff_id == current_user.id`.
- **D-10:** Mensagem do aluno durante `human_active` é salva normalmente (role='user') mas NÃO aciona o AI.

### Frontend Staff — Tela "Intervenção"

- **D-11:** Nova tela "Intervenção" no staff shell (substituir ou adicionar como sub-rota do AI/Insights).
- **D-12:** Lista de sessões com status `human_needed` (pendentes) e `human_active` (em atendimento pelo staff logado).
- **D-13:** Card mostra: nome do aluno, RA (registration number), motivo do alerta (última mensagem do bot antes da escalação), status, tempo desde escalação.
- **D-14:** Botão "Assumir Conversa" — muda status para `human_active`, atribui `assigned_staff_id`.
- **D-15:** Ao assumir, abre tela de chat com histórico completo + campo de resposta. Staff digita e envia via endpoint `POST /chat-sessions/{id}/reply`.
- **D-16:** Botão "Resolver" — muda status para `closed`, sessão sai da lista de intervenção.

### Agent's Discretion

- Palavras-chave exatas para trigger de escalação (pode expandir lista)
- Design da detecção no AI service (pode ser pós-processamento da resposta do agente)
- Como exibir mensagens humanas vs bot no histórico (pode usar mesmo role='assistant' ou criar role='human')

</decisions>

<canonical_refs>

## Canonical References

### Backend Chat System
- `backend/src/features/chat/models.py` — ChatSession, ChatMessage models (status CHECK, roles)
- `backend/src/features/chat/service.py` — Read-only chat service (list, messages, logs)
- `backend/src/features/chat/router.py` — GET endpoints para sessões/mensagens
- `backend/src/features/chat/schemas.py` — Response schemas

### WhatsApp Integration
- `backend/src/features/webhook/router.py` — Webhook handler (message flow)
- `backend/src/features/webhook/service.py` — Session management, verification, media handling
- `backend/src/features/webhook/background.py` — Async AI processing, WhatsApp response sending
- `backend/src/infrastructure/whatsapp_client.py` — WhatsAppClient.send_text_message()

### AI Service
- `ai_service/main.py` — POST /chat endpoint
- `ai_service/agent.py` — Agent invocation, fallback handling
- `ai_service/prompts/system_prompt.txt` — System prompt (regra 6: "oriente a procurar secretaria")

### Frontend Reference
- `alpha-connect/src/App.tsx` lines 813-850 — ManagerChatsInterventionScreen (UI prototype)
- `mobile/lib/features/staff/screens/staff_ai_screen.dart` — Current AI/chat screen
- `mobile/lib/features/staff/screens/staff_shell.dart` — Staff navigation

### Documentation
- `docs/chatbot.md` — Chatbot architecture, intent table, error handling
- `docs/database.md` — chat_sessions, chat_messages schema

</canonical_refs>

<code_context>

## Existing Code Insights

### Reusable Assets

- `WhatsAppClient.send_text_message(to, body)` — já envia mensagens via API do WhatsApp
- `webhook/service.py save_message()` — salva mensagens no DB com dedup
- `webhook/background.py process_verified_message()` — padrão de processamento async
- Chat read endpoints já existem (list sessions, get messages, get logs)
- Staff AI screen já mostra sessões de chat com histórico

### Established Patterns

- Async background processing via `asyncio.create_task`
- Session locking via `asyncio.Lock` per session (prevent concurrent processing)
- IDOR protection: student sees only own sessions, staff sees all
- WhatsApp client with retry (1 retry on failure)

### Integration Points

- `webhook/background.py` — precisa checar status antes de invocar AI (skip se human_needed/human_active)
- `chat_sessions.status` CHECK constraint — precisa expandir para 4 valores
- Staff shell — nova tab ou sub-rota para Intervenção
- AI service `/chat` — pode retornar flag de escalação ou detectar no webhook

</code_context>

<specifics>
## Specific Ideas

- UI segue o padrão do alpha-connect: cards com nome, RA, motivo, badge de status, botão "Assumir Conversa"
- Quando o gestor assume, a tela de chat deve parecer um mensageiro (mensagens do aluno à esquerda, respostas do staff à direita)
- O campo de resposta fica fixo no fundo da tela (padrão chat input)
- Badge "PENDENTE" em amber/warning, "EM ATENDIMENTO" em primary/blue

</specifics>

<deferred>
## Deferred Ideas

- Transferência de conversa entre staff members
- Devolver conversa ao bot após resolução humana
- Notificação push para staff quando nova intervenção necessária
- Métricas de tempo de resposta humana
- Histórico de intervenções passadas com filtros

</deferred>

---

_Phase: 14-human-intervention_
_Context gathered: 2026-05-06_
