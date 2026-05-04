# Phase 8: Client Interface - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-04
**Phase:** 08-client-interface
**Areas discussed:** Dashboard, Chat History, Documentos, Notificacoes & Suporte

---

## Dashboard — conteudo e fontes de dados

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Cards de resumo com links rapidos | Cards resumidos: ultima acao do bot, proximo agendamento, docs pendentes, CRA atual. Cada card leva a tela correspondente. | ✓ |
| Feed de atividade recente | Lista cronologica das ultimas 5-10 atividades sem cards separados | |
| Hub de navegacao simples | Apenas saudacao + grade de atalhos sem dados dinamicos | |

**User's choice:** Cards de resumo com links rapidos
**Notes:** Recomendado — combina visao rapida com navegacao direta.

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Multiplos endpoints (frontend agrega) | Combinar dados de varios endpoints no frontend, cada provider busca seu pedaco | ✓ |
| Endpoint unico se existir | Se backend tiver /students/{id}/summary usar, senao multiplos | |
| Novo endpoint consolidado | Criar BFF endpoint (exigiria backend change — out of scope) | |

**User's choice:** Multiplos endpoints (frontend agrega)
**Notes:** Backend nao tem endpoint consolidado; frontend agrega de chat-sessions, appointments, documents.

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Resumo academico (CRA) | Card com CRA e disciplinas cursadas/restantes | |
| Ultima atividade do bot | Card com ultima sessao + ultima acao do bot | ✓ |
| Proximo agendamento | Card com proximo agendamento e data | ✓ |
| Status de documentos | Card com contagem por status (pendentes/prontos) | ✓ |

**User's choice:** Ultima atividade do bot, Proximo agendamento, Status de documentos (3 cards, sem CRA)

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Saudacao + coluna de cards | "Ola, {nome}!" no topo + cards abaixo em coluna scrollavel | ✓ |
| Grid 2x2 compacto | AppBar com nome + grid de cards | |
| Voce decide | Agente decide layout visual | |

**User's choice:** Saudacao + coluna de cards

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Pull-to-refresh | Puxar para baixo recarrega todos os cards | ✓ |
| Botao manual | Botao 'atualizar' no AppBar | |
| Auto-refresh periodico | Refresh a cada 60s enquanto visivel | |

**User's choice:** Pull-to-refresh

---

## Chat History — estrutura e navegacao

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Unificado — action logs inline | Tela de chat mostra mensagens E acoes inline. Sem tela separada de tracker. | |
| Sub-abas dentro da sessao | Tab 'Chat' abre lista de sessoes. Dentro, 2 sub-abas: 'Mensagens' e 'Acoes'. | ✓ |
| Separado — tracker como tela adicional | Chat so mensagens. Tracker como tela separada. | |

**User's choice:** Sub-abas dentro da sessao
**Notes:** Mantém conceitos separados mas dentro do mesmo contexto de sessao.

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Cards com preview | Cards: data, status, preview ultima msg, numero de mensagens. Tap abre detalhe. | ✓ |
| Lista compacta | Itens compactos: data + status + icone, sem preview | |
| Voce decide | Agente decide formato | |

**User's choice:** Cards com preview

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Bubbles estilo WhatsApp | Bubble chat classico: user a direita (primaria), bot a esquerda (cinza). Timestamps discretos. | ✓ |
| Lista simples | Lista plana com prefixo 'Voce:' / 'Bot:' | |
| Voce decide | Agente decide estilo | |

**User's choice:** Bubbles estilo WhatsApp

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Lista com expandir para detalhe | Lista: tool name, status, data/hora. Tap expande para ver input/output. | ✓ |
| Timeline visual | Timeline vertical com icones por status | |
| Voce decide | Agente decide formato | |

**User's choice:** Lista com expandir para detalhe

---

## Documentos — board + solicitacao

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Tela unica + acao de solicitar | Tab 'Documentos' mostra lista. FAB ou botao no AppBar abre formulario. | ✓ |
| Sub-abas: board e solicitacao | 2 sub-abas: 'Meus Documentos' e 'Nova Solicitacao' | |
| Rotas separadas com navegacao interna | /client/documents (board) e /client/documents/new (formulario) | |

**User's choice:** Tela unica + acao de solicitar

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Cards com chip de status | Cards: tipo, data, chip colorido (amarelo=processando, verde=pronto, cinza=entregue) | ✓ |
| Lista com icone de status | Lista simples com icone a esquerda | |
| Voce decide | Agente decide apresentacao | |

**User's choice:** Cards com chip de status

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Bottom sheet com formulario | Bottom sheet: tipo (dropdown) + observacao opcional + botao 'Solicitar' | ✓ |
| Tela fullscreen separada | Navegacao para nova tela com formulario detalhado | |
| Dialog modal | Dialog centralizado | |

**User's choice:** Bottom sheet com formulario

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Sem filtro — lista cronologica | Todos os docs, ordenados por data | |
| Filtro por status | Chips: 'Todos', 'Pendentes', 'Prontos'. Usuario filtra. | ✓ |
| Voce decide | Agente decide | |

**User's choice:** Filtro por status

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Botao download no card | Botao 'Download' visivel no card quando status ready/delivered | ✓ |
| Download so na tela de detalhe | Tap abre detalhe, download la dentro | |
| Voce decide | Agente decide | |

**User's choice:** Botao download no card

---

## Notificacoes & Suporte — fontes de dados

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Placeholder funcional | Empty state com texto explicando integracao futura | |
| Derivar de dados existentes | Simular notificacoes de docs alterados + agendamentos + erros | ✓ |
| Notificacoes locais apenas | In-app events sem persistencia | |

**User's choice:** Derivar de dados existentes (sem backend novo)

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Documentos com status alterado | Docs recentemente alterados (status 'ready') | ✓ |
| Lembretes de agendamento | Agendamentos proximos (48h) | ✓ |
| Alertas de falha do bot | Acoes com erro relevante para o usuario | ✓ |

**User's choice:** Todas as 3 fontes
**Notes:** User specified "relevant errors for the users, like failing to retrieve a document" — not all bot errors, only user-impacting ones.

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Info de contato + botoes de acao | Email, telefone, horario. Botoes para abrir email client e WhatsApp. | ✓ |
| Formulario de contato | Assunto + mensagem via POST (exige backend) | |
| FAQ + contato | Perguntas frequentes + info contato | |
| Voce decide | Agente decide conteudo | |

**User's choice:** Info de contato + botoes de acao

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Lista com icones por tipo | Cronologica, icones coloridos por tipo (doc=verde, relogio=azul, alerta=vermelho). Sem lido/nao-lido. | ✓ |
| Lista com indicador lido/nao-lido | Igual + dot azul para nao-lido (estado local) | |
| Cards agrupados por data | Agrupados: Hoje, Ontem, Esta semana | |

**User's choice:** Lista com icones por tipo (sem indicador lido/nao-lido)

---

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Dados estaticos no app | Info hardcoded (email, telefone, horario) | ✓ |
| Dados dinamicos via API | Buscar de endpoint (exige backend) | |

**User's choice:** Dados estaticos no app

---

## Agent's Discretion

- Card widget dimensions and spacing
- Pull-to-refresh implementation details
- Chat bubble styling details
- Expandable tile implementation for action logs
- Document type options for request dropdown
- Notification derivation logic (time windows, thresholds)
- Support screen visual layout
- Loading skeletons per screen
- Empty state designs
- Error display pattern

## Deferred Ideas

None — discussion stayed within phase scope.
