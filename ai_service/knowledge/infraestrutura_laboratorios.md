## Normas de Uso da Infraestrutura de Laboratórios

Este documento regulamenta o uso dos laboratórios de informática, servidores institucionais e recursos em nuvem disponibilizados aos alunos do curso de Ciência da Computação do Instituto Federal de Tecnologia. O uso destes recursos é estritamente acadêmico, sendo vedada a utilização para fins comerciais ou de mineração de criptomoedas.

### Acesso aos Laboratórios Físicos

O Instituto Federal de Tecnologia possui seis laboratórios de ensino e dois laboratórios de pesquisa. O acesso aos laboratórios de ensino é livre para alunos regularmente matriculados durante o horário de funcionamento do campus (das 07h às 22h30), desde que não haja aula ocorrendo no local. 

Para acesso aos laboratórios de pesquisa, o aluno deve possuir vínculo formal com um projeto de Iniciação Científica (PIBIC) ou de Extensão. O acesso aos finais de semana e feriados requer solicitação formal do professor orientador com 48 horas de antecedência via sistema de chamados da Diretoria de TI (DTI).

### Ambiente de Desenvolvimento Padrão

Os computadores dos laboratórios possuem sistema operacional dual-boot (Windows 11 e Ubuntu 22.04 LTS). Para garantir a reprodutibilidade dos ambientes de teste e desenvolvimento, a instituição adota e exige o uso de conteinerização. 

É obrigatório o uso de Docker e Docker Compose para orquestração de serviços locais, especialmente para instanciar bancos de dados como PostgreSQL, que é o SGBD padrão adotado nas disciplinas de Banco de Dados I e II. A DTI não realiza a instalação de SGBDs diretamente no host dos laboratórios. 

Nas disciplinas de desenvolvimento web e engenharia de software, o ecossistema padrão homologado para desenvolvimento front-end e back-end é o Node.js com TypeScript. O aluno pode instalar dependências localmente via npm ou yarn, mas as pastas de projeto devem ser salvas no drive de rede mapeado (Drive Z:), pois as máquinas sofrem formatação lógica e congelamento (Deep Freeze) a cada reinicialização.

### Acesso a APIs e Recursos de Inteligência Artificial

Alunos matriculados a partir do 5º semestre (disciplinas de Inteligência Artificial e Processamento de Linguagem Natural) têm direito a credenciais de API para acesso a modelos de linguagem e ferramentas de IA generativa. 

A instituição fornece chaves do OpenRouter para projetos acadêmicos e trabalhos de conclusão de curso. O aluno é inteiramente responsável pelo monitoramento de seu consumo de tokens. O monitoramento deve ser feito através do dashboard local disponibilizado na intranet ou via scripts PowerShell fornecidos pela monitoria da disciplina. O limite institucional é de 500 mil tokens por aluno/semestre. Caso o limite seja excedido, a chave é revogada automaticamente e o aluno deverá justificar a necessidade de expansão de cota junto à coordenação.