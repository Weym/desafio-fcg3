# Documentacao

## Arquitetura e Design

| Documento | Descricao |
|-----------|-----------|
| [architecture.md](architecture.md) | Visao geral da arquitetura do sistema |
| [api.md](api.md) | Especificacao da API REST (endpoints, auth, erros) |
| [database.md](database.md) | Schema do banco, tabelas, relacoes |
| [mcp.md](mcp.md) | MCP Server — tool schemas, seguranca, logging |
| [chatbot.md](chatbot.md) | Fluxo do chatbot WhatsApp e integracao com LangChain |
| [app.md](app.md) | App Flutter — telas, navegacao, estado |

## Operacao e Deploy

| Documento | Descricao |
|-----------|-----------|
| [deploy.md](deploy.md) | Guia completo de deploy bare-metal (setup inicial + atualizacoes) |
| [ssh-setup.md](ssh-setup.md) | Configuracao SSH, deploy keys, transferencia de arquivos |
| [cicd-pipeline-plan.md](cicd-pipeline-plan.md) | Plano de implementacao do CI/CD com GitHub Actions |
| [adr-cicd-approach.md](adr-cicd-approach.md) | ADR: por que self-hosted runner foi escolhido sobre webhook |

## Historico

| Documento | Descricao |
|-----------|-----------|
| [changelog_docs.md](changelog_docs.md) | Changelog de alteracoes na documentacao |

## Scripts

Os scripts operacionais vivem em `../scripts/`:

| Script | Uso |
|--------|-----|
| `scripts/deploy.sh` | Deploy manual — menu interativo (setup + manutencao) |
| `scripts/ci-deploy.sh` | Deploy automatizado — chamado pelo GitHub Actions (nao interativo) |
