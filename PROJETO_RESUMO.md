# Resumo do Projeto - Desafio FCG3

## 🌟 Visão Geral
O **Desafio FCG3** é uma plataforma acadêmica inteligente projetada para facilitar a interação entre alunos e serviços universitários. O sistema combina uma API robusta, um chatbot via WhatsApp com Inteligência Artificial e um aplicativo móvel/web moderno.

---

## 🚀 O que o projeto faz?

### 1. Atendimento Inteligente (Chatbot WhatsApp)
- Alunos podem consultar notas, histórico, situação de matrículas e documentos via WhatsApp.
- O chatbot utiliza IA para entender linguagem natural e executar ações reais (via MCP Server).
- Responde com base em uma base de conhecimento (RAG) e dados em tempo real do aluno.

### 2. Gestão Acadêmica (Backend)
- **Matrículas**: Consulta, solicitação, confirmação e cancelamento de disciplinas.
- **Notas e Histórico**: Consulta de desempenho acadêmico e cálculo automático de CRA.
- **Documentos**: Solicitação e gerenciamento de documentos (atestados, históricos, etc.).
- **Agendamentos**: Reserva e cancelamento de horários de atendimento.
- **Cursos e Currículos**: Visualização de grades curriculares e pré-requisitos.

### 3. Interface de Usuário (Mobile & Web)
- **App Aluno**: Dashboard com resumo acadêmico, histórico de chats e gestão de documentos.
- **App Staff/Fornecedor**: Dashboard de gestão, controle de agendamentos e insights gerados pela IA.

---

## 🛠️ Como o projeto funciona? (Arquitetura)

O sistema é baseado em uma arquitetura de microserviços orquestrada via **Docker Compose**, composta por 4 serviços principais:

### 1. Backend API (FastAPI)
O "cérebro" do negócio. Centraliza o banco de dados PostgreSQL e expõe endpoints REST para o App e para o servidor MCP. Gerencia autenticação (OTP/JWT) e regras de negócio acadêmicas.

### 2. AI Service (LangChain)
O "motor" da inteligência. Utiliza um agente **ReAct** (LangChain) que:
- Processa mensagens do WhatsApp.
- Consulta uma base de conhecimento (ingerida via `ingest.py`) usando **RAG** (Retrieval-Augmented Generation) com **PGVector**.
- Decide quais ferramentas usar para responder ao aluno.

### 3. MCP Server (Model Context Protocol)
O "segurança" e "ponte". Atua como um proxy entre a IA e a API do Backend.
- **Segurança**: Injeta automaticamente o `student_id` no contexto da chamada, impedindo que a IA tente acessar dados de outros alunos (proteção contra IDOR).
- **Ferramentas**: Expõe 16 ferramentas específicas para a IA realizar ações no sistema.

### 4. Mobile App (Flutter)
A face do projeto. Um aplicativo multiplataforma (Android, iOS e Web) que consome a API do Backend para oferecer uma experiência visual completa tanto para alunos quanto para a equipe administrativa.

---

## 🧰 Stack Tecnológica
- **Linguagens**: Python 3.12 (Backend/IA), Dart (Mobile).
- **Frameworks**: FastAPI, LangChain, Flutter.
- **IA/LLM**: Suporte a OpenAI, Gemini e **OpenRouter** (provedor padrão).
- **Banco de Dados**: PostgreSQL 16 + PGVector (busca vetorial).
- **Infraestrutura**: Docker & Docker Compose.
- **Comunicação**: WhatsApp Business API, Resend (E-mail OTP), JWT.

---
*Documento gerado automaticamente para visão geral do ecossistema Desafio FCG3.*
