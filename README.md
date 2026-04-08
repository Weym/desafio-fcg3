# Projeto acadêmico - Assistente Inteligente

Plataforma de assistente acadêmico com integração Flutter mobile, backend em TypeScript e serviço de IA em Python.

## Arquitetura do Projeto (Monorepo + VSA)

```
desafio-fcg3/
├── ai_service/       # Serviço de IA (Python) - LangChain + RAG
│   ├── app/          # Código da aplicação
│   │   ├── agents/   # Agentes de IA
│   │   └── rag/      # Lógica de RAG
│   ├── data/         # Dados e vetores
│   └── requirements.txt
│
├── backend/          # API em TypeScript (Vertical Slice Architecture)
│   ├── src/
│   │   ├── features/    # Slices (endpoints, controllers, business logic)
│   │   ├── infrastructure/  # DB, external services
│   │   ├── shared/      # Código reutilizável
│   │   ├── main.ts      # Entry point
│   │   └── routes.ts    # Definição de rotas
│   └── package.json
│
└── mobile/           # Aplicação Flutter
    ├── lib/
    └── pubspec.yaml
```

### Fluxo de Comunicação

```
Mobile (Flutter) → Backend (TypeScript) → AI Service (Python)
                            ↓
                      MongoDB/PostgreSQL
```

## Stack Tecnológico

### AI Service
- **Linguagem**: Python
- **Framework**: LangChain
- **IA**: RAG (Retrieval-Augmented Generation)
- **Vector DB**: Para armazenamento de embeddings

### Backend
- **Linguagem**: TypeScript
- **Framework**: Node.js (Express)
- **Banco de Dados**: MongoDB ou PostgreSQL
- **Arquitetura**: Vertical Slice Architecture (VSA)
- **Hospedagem**: Docker/LXC (deploy)

### Mobile
- **Framework**: Flutter
- **Perfis**: Cliente e Fornecedor/Administrador
- **Notificações**: Firebase Cloud Messaging (FCM)

## Funcionalidades Principais

### AI Service
- Processamento de linguagem natural via LangChain
- Sistema de RAG para recuperação de documentos acadêmicos
- Geração de respostas contextuais

### Backend
- API RESTful para comunicação com o mobile
- Integração com AI Service para assistente acadêmico
- Autenticação e autorização
- Gerenciamento de usuários e dados acadêmicos

### Mobile (Flutter)
- **Perfil Cliente**: Acompanhamento de atividades, histórico, documentos e notificações
- **Perfil Fornecedor**: Dashboard de gestão, controle de atividades acadêmicas

## Estrutura de Pastas (Vertical Slice Architecture)

### AI Service
```
ai_service/
├── app/
│   ├── agents/    # Definição de agentes de IA
│   └── rag/       # Pipeline de RAG
├── data/          # Armazenamento de dados e vetores
└── requirements.txt
```

### Backend (VSA)
```
backend/src/
├── features/           # Cada feature é um "slice" completo
│   └── [feature]/
│       ├── controllers/
│       ├── services/
│       └── routes.ts
├── infrastructure/     # Configurações de DB, serviços externos
├── shared/             # Código reutilizável entre features
├── main.ts             # Entry point
└── routes.ts           # Agregação das rotas
```

### Mobile
```
mobile/
├── lib/               # Código Flutter
└── pubspec.yaml
```

## Como Executar

### AI Service
```bash
cd ai_service
pip install -r requirements.txt
python app/main.py
```

### Backend
```bash
cd backend
npm install
npm run dev
```

### Mobile
```bash
cd mobile
flutter pub get
flutter run
```

### Docker (Monorepo)
```bash
docker-compose up --build
```

## Tech Lead / Responsáveis

- **Backend Developer**: API TypeScript e infraestrutura
- **AI Specialist**: LangChain, RAG e integração com LLM
- **Flutter Developer**: Mobile app (cliente e fornecedor)
- **DevOps**: Docker, deploy e Firebase
