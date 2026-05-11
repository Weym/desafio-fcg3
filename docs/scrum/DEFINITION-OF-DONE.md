# Definition of Done (DoD) — Desafio FCG3

**Projeto:** Plataforma Academica com Chatbot WhatsApp  
**Versao:** 1.0  
**Aprovado em:** 2026-05-01  
**Valido para:** Sprint 1 e Sprint 2  

---

## Objetivo

A Definition of Done (DoD) estabelece os criterios minimos que uma tarefa, user story ou incremento deve cumprir para ser considerada **completa**. Qualquer item que nao atenda a TODOS os criterios aplicaveis permanece como "In Progress" ou "To Review".

---

## DoD por Nivel

### Nivel 1: Tarefa Individual (Task)

Uma tarefa esta **Done** quando:

- [ ] O codigo foi escrito e esta funcional (nao quebra o build)
- [ ] O codigo segue as convencoes do projeto (PEP 8 para Python, flutter_lints para Dart)
- [ ] Nomes de variaveis, funcoes e classes seguem o padrao do projeto (snake_case Python, camelCase Dart)
- [ ] O codigo foi testado manualmente pelo autor (evidencia: screenshot, log ou video curto)
- [ ] Nao introduz regressoes em funcionalidades existentes
- [ ] Nao contem secrets, tokens ou credenciais hardcoded
- [ ] O codigo esta commitado no branch correto com mensagem descritiva

---

### Nivel 2: User Story

Uma User Story esta **Done** quando:

- [ ] Todas as tarefas associadas estao Done (Nivel 1)
- [ ] Todos os criterios de aceitacao da User Story foram verificados
- [ ] O codigo funciona no ambiente Docker local (`docker compose up`)
- [ ] Funcionalidades dependentes continuam operacionais (teste de regressao basico)
- [ ] O endpoint (se aplicavel) retorna os status HTTP corretos (200, 201, 400, 401, 403, 404, 409, 422)
- [ ] O formato de resposta segue o contrato da API (`{"error": {"code": ..., "message": ...}}` para erros)
- [ ] O codigo foi revisado por pelo menos 1 outro membro (code review ou pair)
- [ ] A documentacao relevante foi atualizada (se mudou contrato de API ou comportamento)

---

### Nivel 3: Incremento de Sprint

O incremento da Sprint esta **Done** quando:

- [ ] Todas as User Stories comprometidas na Sprint estao Done (Nivel 2)
- [ ] O sistema pode ser iniciado do zero com `docker compose up` sem erros
- [ ] O fluxo end-to-end principal funciona (WhatsApp -> webhook -> AI -> resposta)
- [ ] O frontend conecta ao backend e exibe dados reais (nao mocks)
- [ ] Nenhum container falha o healthcheck por mais de 60 segundos
- [ ] O Burndown Chart e Kanban Board estao atualizados
- [ ] Uma demo funcional pode ser realizada sem intervencao tecnica

---

## Criterios Especificos por Tipo de Trabalho

### Backend (Python/FastAPI)

| Criterio | Obrigatorio | Descricao |
|----------|-------------|-----------|
| Funcional em Docker | Sim | Roda dentro do container `fastapi-app` sem erro |
| Endpoint documentado | Sim | Request/response body documentados (pelo menos em docstring ou Swagger auto) |
| Validacao de input | Sim | Pydantic schemas validam dados de entrada |
| Auth protegido | Sim | Endpoints protegidos por JWT ou X-Service-Token |
| IDOR prevention | Sim | Aluno so acessa dados proprios; ownership verificada |
| Teste automatizado | Desejavel | Ao menos 1 teste de integracao por endpoint critico |
| Migration incluida | Se aplicavel | Mudanca no schema = migration Alembic |

### Frontend (Flutter/Dart)

| Criterio | Obrigatorio | Descricao |
|----------|-------------|-----------|
| Compila sem erro | Sim | `flutter build` sem erros |
| Conecta ao backend | Sim | Chamadas HTTP reais (nao mock) no ambiente final |
| Loading state | Sim | Usuario ve indicacao de carregamento durante requisicoes |
| Error handling | Sim | Erros nao resultam em tela branca ou crash |
| Responsivo | Desejavel | Layout aceitavel em diferentes tamanhos de tela |
| Lint clean | Sim | Sem warnings do flutter_lints |

### AI/Chatbot (LangChain)

| Criterio | Obrigatorio | Descricao |
|----------|-------------|-----------|
| Responde em PT-BR | Sim | Todas as respostas em portugues brasileiro |
| Tom institucional | Sim | Linguagem formal e educada |
| Usa ferramentas MCP | Sim | Para consultas de dados do aluno, chama MCP tools |
| RAG funcional | Sim | Para perguntas sobre regulamento/politicas, consulta knowledge base |
| Nao expoe student_id | Sim | Nenhuma mensagem ao usuario revela IDs internos |
| Rejeita injection | Sim | Tentativas de "ignore instructions" sao ignoradas |
| Resposta < 30s | Desejavel | Tempo total de resposta (incluindo tool calls) |

### Documentacao/Scrum

| Criterio | Obrigatorio | Descricao |
|----------|-------------|-----------|
| Formatacao correta | Sim | Markdown renderiza corretamente |
| Dados atualizados | Sim | Reflete o estado real do projeto (nao desatualizado) |
| Consistente | Sim | Numeros batem entre Backlog, Sprint e Burndown |
| Rastreavel | Sim | Tarefas linkam para User Stories |

---

## Criterios de Aceitacao da Demo (Dia 06/05)

A demo esta pronta para apresentacao quando:

1. **WhatsApp funciona ao vivo:** Enviar mensagem -> receber resposta em < 30s
2. **Frontend funciona ao vivo:** Login OTP -> ver dashboard com dados reais
3. **Respostas do chatbot sao inteligentes:** Usa RAG para regulamento, MCP tools para dados do aluno
4. **Privacidade demonstravel:** Mostrar que aluno nao acessa dados de outro
5. **Artefatos Scrum completos:** Backlog, Sprint Backlog, DoD, Kanban, Burndown visiveis
6. **Roteiro ensaiado:** Time sabe quem apresenta o que, em que ordem

---

## Excecoes Aceitas (Trade-offs para o prazo)

Dado o prazo de 5 dias, os seguintes trade-offs sao aceitaveis:

| Trade-off | Justificativa |
|-----------|---------------|
| Cobertura de testes automatizados < 80% | Priorizamos funcionalidade visivel sobre cobertura |
| Frontend com apenas 2-3 telas | MVP minimo para demonstracao |
| Sem CI/CD pipeline | Deploy manual no servidor e aceitavel |
| Sem monitoramento (Sentry) | Logs no Docker sao suficientes para o MVP |
| Burndown retroativo | Dados reconstruidos dos commits (aceitavel para Sprint 1) |
| Code review informal | Revisao verbal ou pair programming conta |

---

## Checklist de Entrega Final (05/05 - vespera da apresentacao)

- [ ] `docker compose up` funciona no servidor do Kenji
- [ ] WhatsApp webhook esta conectado e respondendo
- [ ] Frontend Flutter compila e conecta ao backend
- [ ] Knowledge base esta ingerida com documentos realistas
- [ ] System prompt esta hardened contra injection
- [ ] Slides da apresentacao estao prontos
- [ ] Roteiro da demo esta ensaiado
- [ ] Burndown Chart esta gerado
- [ ] Kanban Board esta atualizado (tudo em Done ou justificado)
- [ ] Backup: video da demo gravado caso algo falhe ao vivo
