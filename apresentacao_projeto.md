# Roteiro de Apresentação: Projeto Desafio FCG3

Este documento consolida os detalhes técnicos e de negócio do projeto para subsidiar a criação de uma apresentação em PowerPoint.

---

## 1. Visão Geral (The Big Picture)
*   **Nome do Projeto:** Desafio FCG3 — Ecossistema Acadêmico Inteligente.
*   **Conceito:** Uma plataforma 360º que une **Inteligência Artificial Generativa**, **Comunicação Omnichannel (WhatsApp)** e **Gestão Acadêmica (Web/Mobile)**.
*   **Público-alvo:** Alunos do curso de Ciência da Computação e equipe administrativa (Secretaria/Coordenação).
*   **Valor Central:** Transformar a burocracia acadêmica em conversas naturais, permitindo que o aluno resolva sua vida acadêmica em segundos via WhatsApp.

---

## 2. O Problema e a Oportunidade
*   **Fricção Administrativa:** Sistemas acadêmicos tradicionais são complexos, lentos e muitas vezes exigem suporte humano para tarefas simples.
*   **Barreira de Acesso:** Alunos preferem interfaces de chat (WhatsApp) à navegação em portais densos.
*   **Oportunidade:** Utilizar Agentes de IA (LLMs) para atuar como uma "Secretaria Digital" que não apenas informa, mas **executa** ações de forma segura.

---

## 3. Funcionalidades do Ecossistema

### 🤖 Chatbot WhatsApp (O Front-End de Conversa)
*   **Consultas em Tempo Real:** Notas, histórico acadêmico, cálculo de CRA e pré-requisitos.
*   **Ações Transacionais:** Solicitação de matrículas, agendamento de atendimentos e emissão de documentos.
*   **IA Contextual (RAG):** O bot responde dúvidas sobre o curso (currículo, normas) baseando-se em documentos reais injetados via busca vetorial.

### 📱 App Flutter (O Front-End de Gestão)
*   **Perfil Aluno:** Dashboard de progresso, mural de documentos recebidos, histórico de conversas com o bot e central de notificações.
*   **Perfil Staff (CRM):** Gestão de agenda, análise de KPIs agregados e envio de documentos para alunos.

---

## 4. Arquitetura Técnica (A "Engrenagem")
O projeto utiliza uma arquitetura de micro-serviços orquestrada via Docker:

*   **Backend (FastAPI):** Centraliza a lógica de negócio, autenticação JWT e segurança.
*   **AI Service (LangChain):** Agente ReAct que decide quais ferramentas usar para responder ao usuário.
*   **MCP Server (Model Context Protocol):** Camada de isolamento que permite à IA interagir com o banco de dados sem nunca expor vulnerabilidades de acesso direto (Prevenção de IDOR).
*   **Database:** PostgreSQL 16 com extensão **PGVector** para busca semântica (RAG).

---

## 5. Diferenciais e Inovações
*   **Segurança por Design:** Uso de Injeção de Contexto no MCP. A IA nunca sabe o ID do aluno; o sistema injeta o ID de quem está logado automaticamente.
*   **Processamento Assíncrono:** Webhooks do WhatsApp respondem "200 OK" instantaneamente, processando a IA em background para garantir estabilidade.
*   **Sincronização em Tempo Real:** Integração com **Firebase (FCM)** para que, quando o bot terminar uma ação no WhatsApp, o App receba uma notificação push em < 2s.
*   **Agnosticismo de Provedor:** Arquitetura pronta para alternar entre OpenAI (GPT) e Google (Gemini) via variáveis de ambiente.

---

## 6. Stack Tecnológica
| Camada | Tecnologia Dominante |
| :--- | :--- |
| **Linguagem Principal** | Python 3.12 (Backend/IA) & Dart (Frontend) |
| **Framework Web** | FastAPI |
| **Mobile/Web** | Flutter (Multiplataforma) |
| **Orquestração de IA** | LangChain & MCP Protocol |
| **Persistência** | PostgreSQL + PGVector + Alembic |
| **Infraestrutura** | Docker & Docker Compose |
| **Comunicação** | WhatsApp Cloud API & Firebase (FCM) |

---

## 7. Status do Projeto e Resultados
*   **Milestone 1 (Concluído):** Infraestrutura, Banco de Dados, IA treinada com RAG e Integração WhatsApp.
*   **Milestone 2 (Concluído):** Aplicativo Flutter funcional para ambos os perfis (Aluno/Staff).
*   **Métricas de Sucesso:** 16 ferramentas de automação acadêmica implementadas e validadas; Webhook otimizado para respostas rápidas.

---

### 💡 Sugestões para os Slides do PowerPoint:
1.  **Slide de Arquitetura:** Use o diagrama C4 (Container) que está em `docs/architecture.md`. Ele visualiza perfeitamente a integração entre os serviços.
2.  **Slide de Demo:** Coloque prints lado a lado: Uma conversa no WhatsApp pedindo um documento e o App Flutter mostrando o documento aparecendo no mural.
3.  **Slide de Segurança:** Destaque o "MCP Server" como o guardião dos dados, explicando que a IA é "impedida" de ver dados que não pertencem ao usuário atual.
