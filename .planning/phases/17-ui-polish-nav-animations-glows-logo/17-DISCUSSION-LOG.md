# Phase 17: UI Polish — Nav Animations, Glows, Logo - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-10
**Phase:** 17-ui-polish-nav-animations-glows-logo
**Areas discussed:** Bottom Nav Animation Fix, Light Mode Glow Palette, Login Screen Logo

---

## Bottom Nav Animation Fix

| Option | Description | Selected |
| --- | --- | --- |
| StatefulWidget + AnimationController | Converter GlassBottomNav pra StatefulWidget com AnimationController explicito. Mais controle, garante animacao independente do rebuild do parent. | ✓ |
| Manter widgets atuais, garantir persistencia | Manter AnimatedContainer/TweenAnimationBuilder mas investigar e garantir que o widget persiste entre navegacoes. | |
| Voce decide | Agente decide a melhor abordagem apos investigar o root cause exato. | |

**User's choice:** StatefulWidget + AnimationController
**Notes:** Recomendado por ser a solucao mais robusta para garantir animacoes independente do comportamento de rebuild do GoRouter.

---

| Option | Description | Selected |
| --- | --- | --- |
| Manter 5 tabs, Support sem botao no nav | Support acessivel so via dashboard/home shortcut. 5 tabs suficiente. | |
| Adicionar 6o tab pro Support | Adicionar 6o NavItem pro Support pra consistencia com as rotas mapeadas. | ✓ |

**User's choice:** Adicionar 6o tab pro Support
**Notes:** User quer consistencia entre rotas e botoes do nav bar.

---

| Option | Description | Selected |
| --- | --- | --- |
| Mesma spec da Phase 16 | Mesmo easeOutBack + scale 24->28px + glow spread da Phase 16. | |
| Liberdade pra ajustar parametros | Ajustar curva, duracao ou efeito visual baseado no que ficar melhor. | ✓ |

**User's choice:** Liberdade pra ajustar parametros
**Notes:** Agente pode refinar a spec de animacao se encontrar valores mais adequados durante implementacao.

---

| Option | Description | Selected |
| --- | --- | --- |
| headset_mic | Consistente com suporte/ajuda. Ja usado na tela de suporte. | ✓ |
| help_outline | Mais generico. | |
| Voce decide | Agente escolhe. | |

**User's choice:** headset_mic
**Notes:** Icone ja utilizado na tela de suporte existente.

---

## Light Mode Glow Palette

| Option | Description | Selected |
| --- | --- | --- |
| Teal escuro no light mode | Usar versao mais escura/profunda do teal para glow no light mode. Mantem identidade cyber-academic com contraste legivel. | ✓ |
| Sem glow no light mode | Remover glows e glassmorphism no light mode. Cards Material simples. | |
| Cor diferente no light mode | Trocar pra cor totalmente diferente (azul profundo, violeta escuro). | |
| Voce decide | Agente escolhe a melhor abordagem. | |

**User's choice:** Teal escuro no light mode
**Notes:** Manter identidade Cyber-Academic mas com contraste adequado.

---

| Option | Description | Selected |
| --- | --- | --- |
| Adaptar glass pro light (borda cinza + shadow) | GlassCard no light mode usa borda cinza sutil + sombra suave. Mantem blur mas com fill/borda visiveis. | ✓ |
| Material Card simples no light mode | Sem blur, sem overlay. Card padrao Material. | |
| Voce decide | Agente decide. | |

**User's choice:** Adaptar glass pro light (borda cinza + shadow)
**Notes:** Preservar efeito glass com adaptacoes visiveis em fundo claro.

---

| Option | Description | Selected |
| --- | --- | --- |
| Todos os 3 arquivos | Aplicar fix em glass_bottom_nav.dart, glass_card.dart e app_colors.dart. | ✓ |
| So bottom nav + colors | So bottom nav e app_colors. GlassCard ja halves alpha. | |

**User's choice:** Todos os 3 arquivos
**Notes:** Coherencia visual completa em todos os componentes.

---

| Option | Description | Selected |
| --- | --- | --- |
| Criar variantes light de todas as neon colors | lightNeonTeal, lightNeonViolet, lightNeonMagenta em AppColors. | |
| So teal light variant | So neonTeal precisa de variante. | |
| Voce decide | Agente avalia quais cores precisam de variante. | ✓ |

**User's choice:** Voce decide
**Notes:** Agente determina quais neon colors realmente precisam de variantes light baseado no uso real.

---

## Login Screen Logo

| Option | Description | Selected |
| --- | --- | --- |
| Short logo (so alfa) em tamanho grande | Limpo, reconhecivel, sem texto minusculo. | |
| Full logo em tamanho maior (160-200px) | Manter full logo mas aumentar pra legibilidade. | |
| Full logo sem tagline (editar SVG) | Criar SVG novo sem tagline. | |
| Voce decide | Agente decide balanco visual. | |

**User's choice:** (Free text) "Gostaria do logo principal na tela, mas tambem gostaria que o short logo fosse utilizado em outros pontos da aplicacao"
**Notes:** Full logo na login screen, short logo em outros pontos do app.

---

| Option | Description | Selected |
| --- | --- | --- |
| Logo grande (160-200px) | Grande o suficiente pra tagline ficar legivel. | ✓ |
| Logo medio (120-140px) | Alfa + ALPHA CONNECT legiveis, tagline ainda pequena. | |
| Voce decide | Agente escolhe tamanho ideal. | |

**User's choice:** Logo grande (160-200px)
**Notes:** Prioridade e legibilidade completa.

---

| Option | Description | Selected |
| --- | --- | --- |
| AppBar de todas as telas | Short logo na AppBar. | |
| Splash screen | Short logo no splash. | |
| Onde couber (agente identifica) | Qualquer lugar com logo pequeno (< 60px). | ✓ |
| So login screen | Nao usar short logo em outros lugares. | |

**User's choice:** Onde couber (agente identifica)
**Notes:** Agente identifica locais onde short logo e mais adequado.

---

| Option | Description | Selected |
| --- | --- | --- |
| Manter tagline no SVG | Se o SVG tem tagline, exibir. | |
| Remover tagline do full logo | Criar variante sem tagline. | |
| Voce decide | Agente decide. | ✓ |

**User's choice:** Voce decide
**Notes:** Agente avalia se tagline e legivel no tamanho final.

---

| Option | Description | Selected |
| --- | --- | --- |
| Sim, glow sutil no logo | Glow consistente com Cyber-Academic design system. | ✓ |
| Sem glow no logo | Logo limpo, card glass ja tem glow. | |
| Voce decide | Agente decide. | |

**User's choice:** Sim, glow sutil no logo
**Notes:** Login e primeira impressao — deve parecer on-brand com o design system.

---

## Agent's Discretion

- Exact dark teal hex value for light mode glow
- Which neon colors need light variants
- AnimationController implementation details
- Animation parameter refinement
- Logo glow intensity
- showTagline parameter: wire or remove
- Specific short logo locations
- Glass border color in light mode

## Deferred Ideas

None — discussion stayed within phase scope.
