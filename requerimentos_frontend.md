# Documento de Requisitos do Frontend

## 1. Visão Geral do Sistema
O aplicativo tem como objetivo fornecer uma interface de acesso e gestão (Frontend Mobile/Web) para um sistema integrado a um bot de WhatsApp. A plataforma serve como um portal para visualização e acompanhamento de agendamentos, solicitações e dados processados por IA.

## 2. Tecnologias e Arquitetura
- **Framework Principal:** Flutter (Cross-platform para Mobile e Web).
- **Integração:** Consumo de APIs para comunicação com o backend e o chatbot do WhatsApp.
- **Arquitetura de Navegação:** Navegação baseada em perfis de usuário, garantindo interfaces dedicadas para o Cliente e para o Fornecedor.

## 3. Perfis de Usuário
O sistema possui dois perfis principais de acesso:
1. **Cliente:** Usuário final que realiza interações primárias pelo WhatsApp e utiliza o aplicativo para acompanhamento passivo e solicitações.
2. **Fornecedor (Gestor):** Responsável pela prestação do serviço, gestão da agenda e administração da plataforma.

## 4. Requisitos Funcionais

### 4.1. Perfil: Cliente
O foco principal do aplicativo para o cliente é a visualização e acompanhamento de ações iniciadas no chatbot.

* **[RF-C01] Tela Home (Dashboard do Cliente):** Visualização de resumo das ações e agendamentos realizados recentemente através do chatbot no WhatsApp.
* **[RF-C02] Histórico de Chats/Atendimentos:** Consulta ao histórico de interações e status das solicitações abertas.
* **[RF-C03] Solicitações de Documentos:** Interface para solicitar o envio ou emissão de novos documentos.
* **[RF-C04] Mural de Documentos:** Repositório para visualização, download e gerenciamento de documentos emitidos ou recebidos.
* **[RF-C05] Central de Notificações e Avisos:** Histórico e recebimento de alertas importantes, lembretes de agendamento e atualizações de status.
* **[RF-C06] Suporte e Contato:** Canal direto para o cliente entrar em contato com o suporte técnico ou administrativo.

### 4.2. Perfil: Fornecedor
O foco para o fornecedor é a gestão, controle e análise de dados.

* **[RF-F01] Dashboard de Gestão:** Painel administrativo com métricas e visões gerais sobre o negócio, atendimentos e interações do bot.
* **[RF-F02] Controle de Agenda:** Interface para gerenciar, aprovar, reagendar ou cancelar compromissos gerados via WhatsApp.
* **[RF-F03] Interação com Dados de IA:** Visualização estruturada das informações, resumos e insights extraídos pela Inteligência Artificial a partir das conversas dos clientes.
* **[RF-F04] Gestão de Documentos:** Interface para enviar documentos para o mural dos clientes e gerenciar as solicitações de documentos pendentes.

## 5. Requisitos Não Funcionais
* **[RNF-01] Usabilidade:** A interface deve ser intuitiva, priorizando clareza para o cliente.
* **[RNF-02] Responsividade:** A aplicação desenvolvida em Flutter deve se adaptar fluidamente a diferentes tamanhos de tela (Smartphones, Tablets e Web).
* **[RNF-03] Segurança:** Autenticação com separação rigorosa de permissões e rotas entre Cliente e Fornecedor.
* **[RNF-04] Performance:** A sincronização dos dados provenientes do WhatsApp e processados pela IA deve ocorrer de maneira eficiente para garantir que o usuário tenha informações atualizadas na interface.