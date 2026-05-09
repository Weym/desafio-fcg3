# Phase 10: Cross-Platform Polish - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-05
**Phase:** 10-cross-platform-polish
**Areas discussed:** Navegacao responsiva, Layout em telas grandes, Estrategia de loading/feedback, Cache e sincronizacao de dados, Dark mode, Acessibilidade, Animacoes e transicoes, Espacamento e tipografia responsiva

---

## Navegacao Responsiva

| Option | Description | Selected |
| ------ | ----------- | -------- |
| NavigationRail no tablet/web | NavigationRail vertical na esquerda quando largura >= 768dp. Padrao Material 3. | ✓ |
| BottomNav sempre | Manter BottomNavigationBar em todas as plataformas. | |
| Sidebar web + Rail tablet + Bottom phone | Tres variantes de navegacao por breakpoint. | |

**User's choice:** NavigationRail no tablet/web (Recommended)
**Notes:** N/A

---

### Rail Style

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Compact (icones apenas) | Apenas icones no rail, ~72dp largura. Labels em tooltip. | ✓ |
| Extended (icones + labels) | Icones + labels visiveis, ~180dp. | |
| Collapsible | Compact que expande ao hover/click. | |

**User's choice:** Compact (icones apenas) (Recommended)

---

### Breakpoints

| Option | Description | Selected |
| ------ | ----------- | -------- |
| 2 breakpoints: 768dp | Simples: phone vs tablet/web. | |
| 3 breakpoints: 600, 1024 | <600dp phone, 600-1024dp tablet, >=1024dp desktop. | ✓ |
| Material 3 canonical (600, 840) | Compact/medium/expanded. | |

**User's choice:** 3 breakpoints: 600, 1024

---

### Desktop Navigation

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Rail compact em ambos | Mesmo rail compact para tablet e desktop. | |
| Compact no tablet, Extended no desktop | Tablet = icons only, Desktop = icons + labels. | ✓ |
| You decide | Agent discretion. | |

**User's choice:** Compact no tablet, Extended no desktop

---

## Layout em Telas Grandes

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Max-width centralizado | Conteudo limitado a ~720dp, centralizado. | |
| Master-detail (split view) | Lista na esquerda, detalhe na direita em >=1024dp. | |
| Hibrido: max-width + master-detail | Max-width para simple screens, master-detail para list+detail. | ✓ |

**User's choice:** Hibrido: max-width + master-detail (Recommended)

---

### Master-detail Screens

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Chat (sessoes \| mensagens) | Chat list + message detail side-by-side. | ✓ |
| Documentos (lista \| detalhe) | Document list + detail side-by-side. | |
| Agenda (lista \| detalhe) | Appointments list + detail. | |
| IA dados (sessoes \| detalhe) | AI sessions + chat detail. | ✓ |

**User's choice:** Chat and IA dados selected. Documents and Agenda use max-width.

---

### Grid/Content Width

| Option | Description | Selected |
| ------ | ----------- | -------- |
| 720dp max + grid adaptativo | 720dp max, grid KPIs: 2/3/4 columns by breakpoint. | ✓ |
| 900dp max + grid adaptativo | 900dp max-width. | |
| You decide | Agent discretion. | |

**User's choice:** 720dp max + grid adaptativo (Recommended)

---

## Estrategia de Loading/Feedback

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Skeleton/shimmer screens | Skeleton placeholders on first load. Best perceived performance. | ✓ |
| Spinner melhorado + transicoes | Keep spinner with better context and fade transitions. | |
| Mostrar dados do cache + refresh indicator | Stale-while-revalidate visual approach. | |

**User's choice:** Skeleton/shimmer screens (Recommended)

---

### UX Unification

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Widgets compartilhados | AppSkeleton, AppEmptyState, AppErrorState shared components. | ✓ |
| Padronizar inline sem extrair | Match visuals per-screen without extraction. | |
| You decide | Agent discretion. | |

**User's choice:** Widgets compartilhados (Recommended)

---

### Shimmer Scope

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Skeleton no primeiro load, linear no refresh | Skeleton first time, linear bar during refresh with data visible. | ✓ |
| Skeleton em todo carregamento | Always skeleton, even on refresh. | |
| You decide | Agent discretion. | |

**User's choice:** Skeleton no primeiro load, linear no refresh (Recommended)

---

### Transition

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Fade-in animado | Fade opacity ~300ms when data arrives. | |
| Troca instantanea | Immediate swap from skeleton to content. | ✓ |
| You decide | Agent discretion. | |

**User's choice:** Troca instantanea

---

## Cache e Sincronizacao de Dados

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Riverpod keepAlive + TTL | Timer-based invalidation on existing keepAlive providers. | ✓ |
| Stale-while-revalidate | Show cached, refetch in background, update on arrival. | |
| Persistencia local (SQLite/Hive) | Local DB persistence, zero-latency for visited data. | |
| You decide | Agent discretion. | |

**User's choice:** Riverpod keepAlive + TTL (Recommended)

---

### TTL Config

| Option | Description | Selected |
| ------ | ----------- | -------- |
| 5 min para todos | Uniform 5-minute TTL. | ✓ |
| TTL por tipo de dado | Differentiated: Dashboard 2min, Lists 5min, Details 10min. | |
| You decide | Agent discretion. | |

**User's choice:** 5 min para todos (Recommended)

---

### Prefetch

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Prefetch tabs adjacentes | Pre-load adjacent tabs in background after mount. | ✓ |
| Lazy load apenas | Each tab loads only on access. | |
| You decide | Agent discretion. | |

**User's choice:** Prefetch tabs adjacentes (Recommended)

---

### Offline Behavior

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Dados em memoria + banner offline | Show cached data + "Sem conexao" banner, disable actions. | ✓ |
| Erro padrao sem tratamento offline | Standard Dio error display. | |
| You decide | Agent discretion. | |

**User's choice:** Dados em memoria + banner offline (Recommended)

---

## Dark Mode

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Dark mode completo | Full dark mode, ThemeMode.system + manual toggle. | ✓ |
| Apenas light mode | Focus on contrast in light theme only. | |
| Dark mode via system settings apenas | Infra ready but no visible toggle. | |

**User's choice:** Dark mode completo (Recommended)

---

### Theme Toggle

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Toggle no AppBar/settings | Icon in AppBar, persists in SharedPreferences. | ✓ |
| Apenas system (sem toggle) | Follow OS setting only. | |
| You decide | Agent discretion. | |

**User's choice:** Toggle no AppBar/settings

---

## Acessibilidade (a11y)

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Baseline: contraste + targets + font | WCAG AA contrast, 48dp targets, textScaleFactor up to 2.0x. | ✓ |
| Baseline + Semantics/focus (completo) | Plus screen reader labels, focus traversal. | |
| Minimo: contraste + targets | Without font scaling. | |

**User's choice:** Baseline: contraste + targets + font (Recommended)

---

## Animacoes e Transicoes

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Material 3 defaults | Standard shared axis, fade through. No custom animations. | ✓ |
| Transicoes customizadas | Custom slide, fade, hero animations. | |
| You decide | Agent discretion. | |

**User's choice:** Material 3 defaults (Recommended)

---

## Espacamento e Tipografia Responsiva

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Tokens de spacing + Material TextTheme | Spacing constants, no responsive typography. | |
| Tokens + tipografia adaptativa por breakpoint | Spacing + headings scale ~20% on desktop, line-height adapts. | ✓ |
| You decide | Agent discretion. | |

**User's choice:** Tokens + tipografia adaptativa por breakpoint

---

### Typography Adaptation

| Option | Description | Selected |
| ------ | ----------- | -------- |
| Headings maiores + line-height adaptado | Headings +20% desktop, body line-height increases. | ✓ |
| Escala proporcional inteira | Full TextTheme scales +10% tablet, +20% desktop. | |
| You decide | Agent discretion. | |

**User's choice:** Headings maiores + line-height adaptado (Recommended)

---

## Agent's Discretion

- Exact shimmer animation style
- Master-detail split ratio
- AppBar toggle icon placement
- Specific spacing per screen
- RepaintBoundary optimization
- Pagination for long lists

## Deferred Ideas

None — all discussion stayed within phase scope.
