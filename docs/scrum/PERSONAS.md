# Personas e Jornadas de Usuario

## Proposito

Este documento define as personas primarias da plataforma academica com chatbot WhatsApp do curso de Ciencia da Computacao. Cada persona inclui perfil demografico, objetivos, dores e uma jornada de usuario detalhada. As personas orientam decisoes de design, priorizacao do backlog e criterios de aceitacao.

---

## Persona 1: Aluno de Ciencia da Computacao

### Perfil

- **Nome:** Lucas Ferreira dos Santos
- **Idade:** 22 anos
- **Semestre:** 6o semestre
- **Curso:** Bacharelado em Ciencia da Computacao
- **Localizacao:** Belo Horizonte, MG

### Sobre

Lucas e um aluno que trabalha meio periodo como estagiario de desenvolvimento em uma startup. Sua rotina e corrida: aulas pela manha, estagio a tarde e estudo a noite. Ele usa o celular para quase tudo — desde ler documentacao tecnica ate pedir comida. E familiarizado com APIs, terminais e ferramentas de desenvolvimento, mas tem pouca paciencia para sistemas academicos lentos ou burocraticos. Prefere resolver tudo pelo celular, de preferencia sem precisar abrir um portal web separado.

### Objetivos

- Consultar notas e situacao academica de forma rapida, sem navegar por menus complexos
- Realizar matricula em disciplinas sem precisar ir presencialmente a secretaria
- Receber notificacoes em tempo real sobre documentos prontos, confirmacoes de matricula e prazos
- Ter um canal unico (WhatsApp) para resolver questoes academicas simples

### Dores

1. **Portal academico lento e confuso:** O sistema atual exige muitos cliques para encontrar informacoes basicas. A interface nao e responsiva e funciona mal no celular.
2. **Falta de visibilidade sobre prazos:** Lucas ja perdeu prazo de matricula porque nao recebeu notificacao. As informacoes ficam espalhadas entre e-mail institucional, mural fisico e portal.
3. **Dependencia da secretaria para acoes simples:** Solicitar um historico escolar ou verificar pre-requisitos exige ida presencial ou e-mail com resposta demorada (2-5 dias uteis).
4. **Incerteza sobre status de solicitacoes:** Apos solicitar um documento ou matricula, nao ha como acompanhar o andamento sem ligar ou ir pessoalmente.

### Frase Caracteristica

> "Eu so quero saber minhas notas e me matricular nas materias do proximo semestre. Nao devia precisar de 15 minutos e 10 cliques pra isso."

---

### Jornada de Usuario: Consultar Notas e Matricular-se via WhatsApp

**Contexto:** Lucas quer verificar suas notas do semestre atual e, se estiver tudo certo, ja se matricular nas disciplinas do proximo semestre. E periodo de matricula e ele esta no onibus voltando do estagio.

| Etapa | Acao | Canal | Sentimento |
|-------|------|-------|------------|
| 1. Inicio da conversa | Lucas abre o WhatsApp e envia "oi" para o numero do chatbot academico. O bot responde com saudacao e opcoes disponiveis. | WhatsApp | Neutro — espera que funcione |
| 2. Autenticacao | O chatbot solicita verificacao. Lucas informa seu e-mail institucional e recebe um codigo OTP por e-mail. Digita o codigo no WhatsApp. | WhatsApp + E-mail | Leve impaciencia — quer que seja rapido |
| 3. Consulta de notas | Lucas envia "quero ver minhas notas". O chatbot retorna uma lista com disciplina, nota e situacao (aprovado/reprovado/em andamento) do semestre atual. | WhatsApp | Satisfacao — informacao clara e imediata |
| 4. Verificacao de disciplinas disponiveis | Lucas pergunta "quais materias posso me matricular no proximo semestre?". O chatbot consulta grade curricular, pre-requisitos cumpridos e disciplinas ofertadas, retornando uma lista filtrada. | WhatsApp | Surpresa positiva — nao precisou verificar pre-requisitos manualmente |
| 5. Solicitacao de matricula | Lucas envia "quero me matricular em Banco de Dados II e Engenharia de Software". O chatbot cria dois enrollments com status "draft" e pede confirmacao. | WhatsApp | Atencao — quer ter certeza que esta correto |
| 6. Confirmacao e feedback | Lucas confirma. O chatbot altera o status para "confirmed" e envia resumo com disciplinas, horarios e professor. Lucas recebe notificacao push no celular confirmando a matricula. | WhatsApp + Push (FCM) | Satisfacao — resolveu tudo em 5 minutos no onibus |

---

## Persona 2: Secretaria Academica (Staff)

### Perfil

- **Nome:** Carla Regina de Souza
- **Idade:** 41 anos
- **Cargo:** Secretaria Academica do Departamento de Ciencia da Computacao
- **Localizacao:** Belo Horizonte, MG

### Sobre

Carla trabalha na secretaria academica ha 12 anos. Ela e responsavel por gerenciar matriculas, emitir documentos (historicos, declaracoes, atestados), atender alunos presencialmente e por e-mail, e manter registros atualizados no sistema da universidade. Usa computador o dia inteiro, domina planilhas e o sistema academico legado, mas nao tem formacao tecnica. Seu dia e dividido entre atendimento ao aluno (fila presencial e e-mails) e tarefas administrativas. Nos periodos de matricula e final de semestre, a demanda triplica.

### Objetivos

- Reduzir o volume de atendimentos presenciais e por e-mail para questoes simples (consulta de notas, status de documentos)
- Ter visibilidade centralizada sobre solicitacoes de documentos e seus status
- Acompanhar matriculas em andamento e intervir quando necessario (conflitos de horario, pre-requisitos)
- Gerar relatorios rapidos sobre situacao de turmas e alunos

### Dores

1. **Volume repetitivo de atendimentos:** Cerca de 60% das perguntas que recebe sao consultas simples ("minha matricula foi confirmada?", "meu historico esta pronto?") que poderiam ser automatizadas.
2. **Sistema legado fragmentado:** O sistema atual exige que Carla acesse modulos diferentes para matriculas, documentos e dados do aluno. Nao ha dashboard unificado.
3. **Falta de rastreabilidade:** Quando um aluno pergunta sobre uma solicitacao, Carla precisa buscar manualmente em e-mails e planilhas. Nao ha log centralizado de acoes.
4. **Picos de demanda sem suporte:** Em periodo de matricula, a fila presencial cresce e o e-mail acumula. Nao ha triagem automatica — tudo depende dela e de um colega.

### Frase Caracteristica

> "Se os alunos conseguissem ver o status do documento deles sem me ligar, eu ia finalmente ter tempo pra organizar os processos que estao parados ha meses."

---

### Jornada de Usuario: Gerenciar Solicitacoes de Documentos pelo Dashboard

**Contexto:** E segunda-feira de manha. Carla chega e precisa processar as solicitacoes de documentos que chegaram no fim de semana (via chatbot e portal). Ela quer priorizar historicos escolares porque tem prazo de entrega ate quarta.

| Etapa | Acao | Canal | Sentimento |
|-------|------|-------|------------|
| 1. Acesso ao dashboard | Carla abre o navegador e acessa o painel administrativo. Faz login com suas credenciais de staff. A tela inicial mostra um resumo: 14 solicitacoes pendentes, 3 documentos prontos para entrega, 2 alertas de matricula com conflito. | Dashboard Web | Foco — quer resolver rapido |
| 2. Filtro de solicitacoes | Carla filtra solicitacoes por tipo "Historico Escolar" e status "requested". Aparecem 6 solicitacoes. Ela ordena por data de solicitacao (mais antiga primeiro). | Dashboard Web | Controle — consegue priorizar |
| 3. Processamento do documento | Carla seleciona a primeira solicitacao, verifica os dados do aluno (nome, matricula, disciplinas cursadas). Clica em "Gerar Historico". O sistema compila os dados e gera o PDF. Carla revisa e altera o status para "ready". | Dashboard Web | Rotina — processo conhecido |
| 4. Notificacao ao aluno | Ao marcar como "ready", o sistema dispara automaticamente uma notificacao push (FCM) e uma mensagem no WhatsApp informando o aluno que o documento esta disponivel para retirada ou download. | Dashboard Web + WhatsApp + Push | Alivio — nao precisa enviar e-mail manual |
| 5. Tratamento de excecao | Na terceira solicitacao, Carla percebe que o aluno tem uma pendencia financeira que impede a emissao. Ela adiciona uma observacao ao registro e altera o status para "blocked". O aluno recebe notificacao informando a pendencia. | Dashboard Web | Frustacao leve — queria resolver tudo de uma vez |
| 6. Revisao final | Carla volta ao dashboard, verifica que processou 5 de 6 historicos (1 bloqueado). Confere os alertas de matricula com conflito e agenda para resolver apos o almoco. Fecha o painel satisfeita com o progresso da manha. | Dashboard Web | Satisfacao — visibilidade clara do que falta |

---

## Mapa de Relacionamento entre Personas

| Interacao | Descricao |
|-----------|-----------|
| Aluno solicita -> Sistema processa -> Staff valida | Solicitacoes de documentos passam pelo chatbot, sao registradas automaticamente e aparecem no dashboard da secretaria. |
| Staff atualiza status -> Sistema notifica -> Aluno recebe | Quando Carla altera o status de um documento ou matricula, Lucas recebe notificacao automatica no WhatsApp e/ou push. |
| Aluno pergunta ao chatbot -> Chatbot responde via API | Consultas simples (notas, status) sao resolvidas pelo chatbot sem envolvimento da secretaria. |
| Chatbot nao consegue resolver -> Staff intervem | Questoes complexas ou excecoes sao escaladas para atendimento humano via dashboard. |

---

*Este documento deve ser atualizado conforme pesquisas com usuarios reais forem conduzidas. As personas atuais sao baseadas em analise de dominio e requisitos do projeto.*
