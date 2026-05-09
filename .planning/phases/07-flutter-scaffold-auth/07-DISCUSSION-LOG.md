# Phase 7: Flutter Scaffold & Auth - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-04
**Phase:** 07-flutter-scaffold-auth
**Areas discussed:** Gerenciamento de estado, Navegacao e roteamento, Fluxo de autenticacao UX, Estrutura de projeto e camadas

---

## Gerenciamento de Estado

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Riverpod | Geracao de codigo, tipagem forte, auto-dispose, escopo granular. Curva de aprendizado maior, mas escalabilidade e testabilidade superiores. | ✓ |
| Provider | Padrao oficial do Flutter, simples, sem geracao de codigo. Pode ficar verboso com muitos providers aninhados. | |
| Bloc / Cubit | Separacao rigida de eventos/estados, mais boilerplate. | |

**User's choice:** Riverpod (Recomendado)
**Notes:** None

| Option | Description | Selected |
| ------ | ----------- | -------- |
| riverpod_generator | Usa @riverpod annotation + build_runner para gerar providers automaticamente. Menos boilerplate. | ✓ |
| Riverpod manual | Define providers manualmente. Mais controle explicito, sem dependencia de build_runner. | |

**User's choice:** riverpod_generator (Recomendado)
**Notes:** None

---

## Navegacao e Roteamento

| Option | Description | Selected |
| ------ | ----------- | -------- |
| GoRouter | Pacote oficial recomendado pelo Flutter team. Suporta guards, redirects, deep links, shell routes. | ✓ |
| auto_route | Gera rotas via anotacoes. Type-safe, suporta guards e nested navigation. Requer build_runner. | |
| Navigator 2.0 puro | API nativa do Flutter, sem dependencia extra. Mais verboso, guards manuais. | |

**User's choice:** GoRouter (Recomendado)
**Notes:** None

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Bottom navigation bar | BottomNavigationBar com ShellRoute do GoRouter. Padrao mobile mais comum. | ✓ |
| Drawer / sidebar | Drawer lateral (hamburger menu). Bom para muitas opcoes, mas esconde navegacao primaria. | |

**User's choice:** Bottom navigation bar (Recomendado)
**Notes:** None

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Redirect no GoRouter + Riverpod auth state | GoRouter redirect integrado com Riverpod authProvider. Role-based blocking. | ✓ |
| Guard middleware customizado | Middleware customizado que intercepta antes de navegar. | |

**User's choice:** Redirect no GoRouter + Riverpod auth state (Recomendado)
**Notes:** None

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Tabs separados por role | Home, Chat, Documentos, Notificacoes, Suporte (5 client) / Dashboard, Agenda, IA, Documentos (4 staff) | ✓ |
| Tabs reduzidos + menu secundario | 3-4 tabs mais usados na barra, demais em submenu. | |

**User's choice:** Tabs separados por role (Recomendado)
**Notes:** None

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Splash + verificacao de token | Splash nativo + tela intermediaria Flutter que verifica JWT e redireciona. | ✓ |
| Sem splash | GoRouter redirect faz tudo automaticamente no primeiro build. | |

**User's choice:** Splash + verificacao de token (Recomendado)
**Notes:** None

---

## Fluxo de Autenticacao UX

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Tela unica com 2 etapas | Duas etapas na mesma tela: email, depois codigo OTP. Transicao suave. | ✓ |
| Duas telas separadas | Tela 1: email. Tela 2: OTP. Navegacao push entre elas. | |
| Stepper / wizard | Stepper visual (passo 1/2). Mostra progresso explicito. | |

**User's choice:** Tela unica com 2 etapas (Recomendado)
**Notes:** None

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Pin code fields (6 caixas separadas) | 6 campos individuais estilo PIN, com foco automatico entre campos. | |
| Campo unico numerico | Um unico TextField numerico com 6 digitos. Mais simples. | ✓ |

**User's choice:** Campo unico numerico
**Notes:** User chose the simpler approach over the recommended pin-code style.

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Snackbar | Snackbar na parte inferior com mensagem especifica. Desaparece apos 4s. | ✓ |
| Texto inline abaixo do campo | Texto vermelho inline abaixo do campo com o erro. | |
| Dialog modal | Dialog modal com mensagem de erro. | |

**User's choice:** Snackbar (Recomendado)
**Notes:** None

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Reenviar com countdown 60s | Botao com countdown de 60s antes de habilitar. Alinha com rate limit backend. | ✓ |
| Reenviar sem cooldown | Botao sempre ativo, rely no rate limit do backend. | |

**User's choice:** Reenviar com countdown 60s (Recomendado)
**Notes:** None

---

## Estrutura de Projeto e Camadas

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Feature-first | Cada feature tem sua pasta com model, service, provider, screen. Escala melhor. | ✓ |
| Layer-first | Pastas por tipo: models/, services/, screens/. Mais simples no inicio. | |
| Hibrido | core/ e shared/ por camada, features feature-first. | |

**User's choice:** Feature-first (Recomendado)
**Notes:** None

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Dio | Interceptors nativos, cancelamento, type-safe. Padrao de facto no Flutter. | ✓ |
| http (package:http) | Pacote oficial, mais leve. Sem interceptors nativos. | |
| Retrofit / chopper | Gera codigo type-safe do OpenAPI. | |

**User's choice:** Dio (Recomendado)
**Notes:** None

| Option | Description | Selected |
| ------ | ----------- | -------- |
| json_serializable | Anotacoes @JsonSerializable + build_runner. fromJson/toJson gerados. | ✓ |
| Manual | Conversao manual de Map<String, dynamic>. | |
| Freezed + json_serializable | Classes imutaveis com copyWith, ==, hashCode e JSON. | |

**User's choice:** json_serializable (Recomendado)
**Notes:** build_runner already required by riverpod_generator.

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Tema customizado Material 3 | Cores, tipografia e componentes em lib/core/theme/. | ✓ |
| Material 3 seed theme | ColorScheme.fromSeed com seed color. Rapido mas generico. | |

**User's choice:** Tema customizado Material 3 (Recomendado)
**Notes:** None

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Configuracao por ambiente | Arquivo .env ou .dart com constantes por ambiente. Via --dart-define ou envied. | ✓ |
| Hardcoded com kDebugMode | Base URL hardcoded com flag de debug. | |

**User's choice:** Configuracao por ambiente (Recomendado)
**Notes:** None

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Service + Riverpod provider | Service classes por feature usando Dio. Provider expoe o service. | ✓ |
| Repository + interface abstrata | Repository pattern com interface. Mais desacoplado, mais boilerplate. | |

**User's choice:** Service + Riverpod provider (Recomendado)
**Notes:** None

---

## Agent's Discretion

- Dark mode support (include or defer)
- Exact Material 3 color palette and seed color choice
- `--dart-define` vs `envied` for environment config
- Pin input widget library choice
- Loading skeleton/shimmer design during splash
- Exact Dio interceptor implementation details
- Whether to use `flutter_native_splash` package

## Deferred Ideas

None — discussion stayed within phase scope.
