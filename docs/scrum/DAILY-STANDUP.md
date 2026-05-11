# Daily Standup Log — Sprint 3

**Sprint:** 01/05 a 05/05/2026  
**Formato:** Cada membro responde diariamente no grupo:  
1. O que fiz ontem?  
2. O que vou fazer hoje?  
3. Tenho algum bloqueio?  

---

## Dia 1 — 01/05/2026 (Quinta)

### Tech Lead
- **Ontem:** Planejamento da Sprint 2, criacao dos artefatos Scrum
- **Hoje:** Executar Plan 05-10 (RAG threshold fix + MCP UUID fix), iniciar setup do servidor
- **Bloqueio:** Verificar se tenho acesso Docker no servidor do Kenji

### Membro 1 (Frontend Login)
- **Ontem:** —
- **Hoje:** Criar tela de email input + iniciar chamada POST /auth/request-code
- **Bloqueio:** Nenhum

### Membro 2 (Frontend Dashboard)
- **Ontem:** —
- **Hoje:** Criar layout do Dashboard (AppBar + body) + iniciar chamada academic-summary
- **Bloqueio:** Nenhum

### Membro 3 (Knowledge Base)
- **Ontem:** —
- **Hoje:** Escrever matricula.md e faq.md com conteudo realista
- **Bloqueio:** Nenhum (pode comecar sem o fix do RAG)

### Membro 4 (Prompt Engineering)
- **Ontem:** —
- **Hoje:** Revisar system prompt atual + adicionar instrucoes anti-injection
- **Bloqueio:** Precisa do fix do RAG para testar (T-060 do Tech Lead)

### Membro 5 (Scrum + Apresentacao)
- **Ontem:** —
- **Hoje:** Montar Product Backlog e Sprint Backlog em ferramenta visual (Trello/Notion)
- **Bloqueio:** Nenhum

---

## Dia 2 — 02/05/2026 (Sexta)

### Tech Lead
- **Ontem:** Execucao Phase 7+8 iniciada (Flutter scaffold + OTP flow)
- **Hoje:** Continuar Flutter client screens (dashboard, documentos, chat)
- **Bloqueio:** Nenhum

### Membro 1
- **Ontem:** Tela de email input criada + chamada POST /auth/request-code integrada
- **Hoje:** Continuar tela de OTP + tratamento de erros de validacao
- **Bloqueio:** Nenhum

### Membro 2
- **Ontem:** Layout do Dashboard (AppBar + body) iniciado
- **Hoje:** Integrar chamada GET /academic-summary e popular cards
- **Bloqueio:** Nenhum

### Membro 3
- **Ontem:** matricula.md e faq.md com conteudo realista escritos
- **Hoje:** Escrever curriculo.md e documentos.md
- **Bloqueio:** Nenhum

### Membro 4
- **Ontem:** System prompt atual revisado + instrucoes anti-injection rascunhadas
- **Hoje:** Testar prompt injection com exemplos reais; documentar resultados
- **Bloqueio:** Nenhum

### Membro 5
- **Ontem:** Product Backlog e Sprint Backlog replicados no Trello
- **Hoje:** Montar Kanban board visual + atualizar com estado atual das tarefas
- **Bloqueio:** Nenhum

---

## Dia 3 — 03/05/2026 (Sabado)

### Tech Lead
- **Ontem:** Flutter client screens avancados (dashboard, documentos, chat) finalizados
- **Hoje:** Iniciar staff interface (Phase 9) + dark mode
- **Bloqueio:** Nenhum

### Membro 1
- **Ontem:** Tela OTP + validacao de erros concluida
- **Hoje:** Auxiliar Membro 2 na integracao do dashboard com dados reais
- **Bloqueio:** Nenhum

### Membro 2
- **Ontem:** Cards do Dashboard integrados com GET /academic-summary
- **Hoje:** Tela de documentos + tela de matriculas
- **Bloqueio:** Nenhum

### Membro 3
- **Ontem:** curriculo.md e documentos.md escritos; agendamento.md iniciado
- **Hoje:** Finalizar agendamento.md + regulamento.md; rodar ingest.py
- **Bloqueio:** Nenhum

### Membro 4
- **Ontem:** Testes de prompt injection documentados; 0 bypasses encontrados
- **Hoje:** Testar edge cases (mensagens longas, idioma errado, pedidos de dados de outros alunos)
- **Bloqueio:** Nenhum

### Membro 5
- **Ontem:** Kanban board visual montado no Trello com estado atual
- **Hoje:** Preparar estrutura dos slides de apresentacao; rascunhar roteiro da demo
- **Bloqueio:** Nenhum

---

## Dia 4 — 04/05/2026 (Domingo)

### Tech Lead
- **Ontem:** Phase 8 (staff interface) + Phase 9 (dark mode + cross-platform polish) concluidas
- **Hoje:** Phase 10 (Docker integration) + Phase 12 (integracao final e testes)
- **Bloqueio:** Nenhum

### Membro 1
- **Ontem:** Suporte na integracao do dashboard; revisao das telas de auth
- **Hoje:** Testar fluxo completo de login OTP no dispositivo fisico
- **Bloqueio:** Nenhum

### Membro 2
- **Ontem:** Telas de documentos e matriculas finalizadas
- **Hoje:** Integrar tela de chat com o endpoint WhatsApp; testes de usabilidade
- **Bloqueio:** Nenhum

### Membro 3
- **Ontem:** ingest.py rodado com sucesso; 6 categorias indexadas no pgvector
- **Hoje:** Verificar qualidade das buscas RAG; ajustar chunks se necessario
- **Bloqueio:** Nenhum

### Membro 4
- **Ontem:** Guardrails validados; relatorio de seguranca rascunhado
- **Hoje:** Ensaiar demo com perguntas seguras; preparar slide de guardrails
- **Bloqueio:** Nenhum

### Membro 5
- **Ontem:** Slides de apresentacao rascunhados (10 slides)
- **Hoje:** Revisar slides com Tech Lead; gravar video backup da demo (plano B)
- **Bloqueio:** Nenhum

---

## Dia 5 — 05/05/2026 (Segunda)

### Tech Lead
- **Ontem:** Phase 10 (Docker) + Phase 12 (integracao final) concluidas; stack testado end-to-end
- **Hoje:** Revisao final dos artefatos Scrum; disponivel para suporte durante apresentacao
- **Bloqueio:** Nenhum

### Membro 1
- **Ontem:** Fluxo de login OTP testado no dispositivo; bugs menores corrigidos
- **Hoje:** Preparar para apresentacao amanha; revisar slides
- **Bloqueio:** Nenhum

### Membro 2
- **Ontem:** Integracao de chat concluida; testes de usabilidade feitos
- **Hoje:** Preparar para apresentacao amanha; ensaiar demo
- **Bloqueio:** Nenhum

### Membro 3
- **Ontem:** Chunks RAG verificados; qualidade de busca satisfatoria
- **Hoje:** Preparar para apresentacao amanha; disponivel para suporte tecnico
- **Bloqueio:** Nenhum

### Membro 4
- **Ontem:** Video backup da demo gravado; slides de guardrails revisados
- **Hoje:** Ultima revisao dos slides; ensaio geral com o time
- **Bloqueio:** Nenhum

### Membro 5
- **Ontem:** Slides finalizados e revisados com Tech Lead
- **Hoje:** Imprimir PDF dos artefatos; confirmar projetor e resolucao para amanha
- **Bloqueio:** Nenhum

---

## Resumo de Impedimentos

| Data | Membro | Impedimento | Resolvido? | Acao |
|------|--------|-------------|------------|------|
| 01/05 | Tech Lead | Acesso Docker no servidor do Kenji incerto | Sim | Confirmado acesso; `docker compose up` funcional remotamente |
| 01/05 | Membro 4 | Dependencia do fix do RAG para testar guardrails (T-060) | Sim | Tech Lead entregou fix RAG threshold 0.45 no dia 01/05 |
| 02/05 | Backend | Credenciais postgres com drift entre ambientes | Sim | Padronizadas via `.env` e documentadas em `docker-compose.yml` |
| 03/05 | RAG | Threshold 0.45 ainda retornando chunks irrelevantes em alguns casos | Sim | Ajustado para 0.40 apos testes; qualidade de busca validada |
| 04/05 | MCP | UUID de student_id vazando em logs de tool calls | Sim | Corrigido — student_id removido de input_params no log |
