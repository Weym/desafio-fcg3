# Definition of Ready (DoR)

## Proposito

A Definition of Ready (DoR) estabelece os criterios minimos que um item do Product Backlog deve atender **antes** de ser selecionado para uma Sprint. O objetivo e garantir que o time Scrum tenha informacao suficiente para planejar, estimar e executar o trabalho sem bloqueios ou ambiguidades durante a Sprint.

Um item que nao atende a DoR **nao deve** ser puxado para o Sprint Backlog. Isso protege o time de comprometer-se com trabalho mal definido e reduz retrabalho.

> **Relacao com a DoD:** A DoR define quando um item esta pronto para *comecar*. A [Definition of Done](DEFINITION-OF-DONE.md) define quando um item esta pronto para ser considerado *concluido*. Ambas funcionam como contratos de qualidade — uma na entrada, outra na saida.

---

## Criterios de Ready

Um Product Backlog Item (PBI) e considerado **Ready** quando atende a **todos** os criterios abaixo:

### Checklist

- [ ] **1. User Story no formato completo**
  O item segue a estrutura: *"Como [tipo de usuario], quero [acao/funcionalidade], para que [beneficio/valor]."* O formato deve deixar claro quem se beneficia, o que precisa ser feito e por que.

- [ ] **2. Criterios de aceitacao definidos**
  O item possui pelo menos dois criterios de aceitacao escritos no formato Given/When/Then ou em lista objetiva. Os criterios devem ser verificaveis e sem ambiguidade.

- [ ] **3. Dependencias identificadas e resolvidas (ou planejadas)**
  Todas as dependencias tecnicas, de dados, de APIs externas ou de outros times foram mapeadas. Dependencias criticas devem estar resolvidas antes da Sprint; dependencias gerenciaveis devem ter um plano claro.

- [ ] **4. Estimado em Story Points**
  O item foi estimado pelo time de desenvolvimento durante uma sessao de refinamento. A estimativa reflete a complexidade, o esforco e a incerteza envolvidos.

- [ ] **5. Sem bloqueios externos ativos**
  Nao existem impedimentos externos que impecam o inicio do trabalho — como aprovacoes pendentes, acessos nao concedidos, contratos nao assinados ou dependencias de terceiros sem previsao.

- [ ] **6. Discutido e compreendido pelo time (refinamento)**
  O item foi apresentado e discutido em pelo menos uma sessao de refinamento. Todos os membros do time de desenvolvimento entendem o escopo, os limites e o comportamento esperado. Duvidas foram esclarecidas com o Product Owner.

- [ ] **7. Testavel**
  Esta claro como verificar que o item foi implementado corretamente. O time consegue descrever pelo menos um cenario de teste funcional e sabe quais dados ou condicoes sao necessarios para executa-lo.

- [ ] **8. Tamanho adequado para uma Sprint**
  O item e pequeno o suficiente para ser concluido dentro de uma unica Sprint. Se o item for grande demais, deve ser dividido em itens menores antes de ser considerado Ready.

---

## Exemplos: Ready vs. Not Ready

### Exemplo 1 — Consulta de Notas via WhatsApp

| Aspecto | Not Ready | Ready |
|---------|-----------|-------|
| User Story | "Aluno consulta notas pelo WhatsApp" | "Como aluno de Ciencia da Computacao, quero consultar minhas notas do semestre atual enviando uma mensagem no WhatsApp, para que eu possa acompanhar meu desempenho sem acessar o portal academico." |
| Criterios de aceitacao | Nenhum definido | 1) Dado que o aluno esta autenticado, quando envia "minhas notas", entao o chatbot retorna as notas do semestre atual com disciplina e nota. 2) Dado que o aluno nao tem notas lancadas, quando consulta, entao recebe mensagem informando que nao ha notas disponiveis. |
| Dependencias | "Precisa de alguma API" | "Depende do endpoint GET /students/{id}/grades que ja esta implementado na Sprint 1." |
| Estimativa | Nao estimado | 5 Story Points |
| Bloqueios | "Acho que precisa de aprovacao da coordenacao" | Sem bloqueios — acesso a API confirmado, credenciais WhatsApp Business configuradas. |
| Refinamento | Nunca discutido com o time | Discutido no refinamento de 28/04 — time esclareceu formato de resposta e tratamento de erro. |
| Testavel | "Testar se funciona" | "Enviar 'minhas notas' com aluno que tem 3 disciplinas matriculadas e verificar que as 3 notas sao retornadas com nome da disciplina e valor numerico." |
| Tamanho | Historia abrange consulta, historico completo e grafico de desempenho | Escopo limitado a notas do semestre atual, formato texto simples. |

### Exemplo 2 — Matricula em Disciplina

| Aspecto | Not Ready | Ready |
|---------|-----------|-------|
| User Story | "Matricula pelo chatbot" | "Como aluno, quero solicitar matricula em uma disciplina pelo WhatsApp, para que eu possa me matricular sem precisar ir a secretaria." |
| Criterios de aceitacao | "Tem que funcionar" | 1) Dado que o periodo de matricula esta aberto, quando o aluno solicita matricula em uma disciplina, entao o sistema cria um enrollment com status "draft". 2) Dado que o periodo esta fechado, quando o aluno tenta matricular-se, entao recebe mensagem com a data do proximo periodo. |
| Dependencias | Nao mapeadas | "Depende do endpoint POST /enrollments e do MCP tool create_enrollment. Ambos implementados." |
| Estimativa | Nao estimado | 8 Story Points |
| Bloqueios | Regras de pre-requisito nao definidas | Regras de pre-requisito documentadas e validadas com a coordenacao em 25/04. |
| Refinamento | PO mencionou brevemente em reuniao | Discutido em refinamento — time definiu fluxo de confirmacao em duas etapas (draft -> confirmed). |
| Testavel | Vago | "Testar com aluno do 5o semestre matriculando em disciplina do 6o semestre, com e sem pre-requisitos cumpridos." |
| Tamanho | Inclui matricula, cancelamento, confirmacao e historico | Apenas criacao e confirmacao de matricula. Cancelamento e item separado. |

---

## Quando Aplicar

- **Refinamento do Backlog:** O momento principal para avaliar e melhorar a maturidade dos itens. Itens que nao atendem a DoR recebem acoes para atingi-la.
- **Sprint Planning:** Apenas itens que atendem a DoR devem ser considerados para selecao. O Scrum Master deve verificar o checklist antes de o time comprometer-se.
- **Durante a Sprint:** Se um item puxado revelar que nao atendia a DoR de fato (informacao oculta emergiu), o time deve comunicar ao PO imediatamente e decidir se continua, ajusta ou devolve o item ao Backlog.

---

## Responsabilidades

| Papel | Responsabilidade |
|-------|-----------------|
| Product Owner | Garantir que User Story, criterios de aceitacao e prioridade estejam claros. Resolver duvidas de negocio. |
| Time de Desenvolvimento | Estimar, identificar dependencias tecnicas, confirmar que entende o item, validar testabilidade. |
| Scrum Master | Facilitar o refinamento, verificar que a DoR esta sendo respeitada, impedir que itens nao-ready entrem na Sprint. |

---

*Este documento deve ser revisado pelo time a cada Sprint Retrospective para ajustar criterios conforme a maturidade do projeto evolui.*
