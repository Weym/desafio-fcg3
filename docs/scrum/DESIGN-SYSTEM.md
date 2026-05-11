# Design System — Plataforma Academica

**Versao:** 1.1  
**Tom Visual:** Vibrante/Startup (Vercel, Stripe, Linear)  
**Uso:** HTML/CSS para PDF (weasyprint) + Slides (Marp)  
**Ultima atualizacao:** 2026-05-04  

---

## Quick Reference

| Token | Valor |
|-------|-------|
| Primary | `#6C3FE0` (Vivid Purple) |
| Secondary | `#00C9A7` (Teal) |
| Accent | `#FF6B6B` (Coral) |
| Success | `#10B981` (Emerald) |
| Warning | `#F59E0B` (Amber) |
| Danger | `#EF4444` (Red) |
| Heading Font | `Inter` (700, 800) |
| Body Font | `Inter` (400, 500) |
| Base Spacing | `8px` |
| Border Radius | `8px` (default) |
| Page | A4 (210mm x 297mm) |

---

## 1. Paleta de Cores

### Cores Principais

| Nome | Hex | RGB | Uso |
|------|-----|-----|-----|
| **Primary** | `#6C3FE0` | 108, 63, 224 | CTAs, headers, links, accent principal |
| **Primary Light** | `#8B5CF6` | 139, 92, 246 | Hover states, fundos suaves |
| **Primary Dark** | `#5022C3` | 80, 34, 195 | Active states, texto sobre fundo claro |
| **Secondary** | `#00C9A7` | 0, 201, 167 | Complementar, graficos secundarios |
| **Secondary Light** | `#34D399` | 52, 211, 153 | Badges, fundos |
| **Accent** | `#FF6B6B` | 255, 107, 107 | Destaques, alertas importantes |

### Cores Semanticas (Status)

| Status | Hex | Background | Uso |
|--------|-----|-----------|-----|
| **Done** | `#10B981` | `#ECFDF5` | Tarefas concluidas |
| **In Progress** | `#F59E0B` | `#FFFBEB` | Tarefas em andamento |
| **To Do** | `#6B7280` | `#F9FAFB` | Tarefas pendentes |
| **Blocked** | `#EF4444` | `#FEF2F2` | Tarefas bloqueadas |
| **Cancelled** | `#9CA3AF` | `#F3F4F6` | Tarefas canceladas |

### Cores Neutras

| Nome | Hex | Uso |
|------|-----|-----|
| **White** | `#FFFFFF` | Fundo pagina |
| **Gray 50** | `#F9FAFB` | Fundo cards, sections |
| **Gray 100** | `#F3F4F6` | Fundo alternado em tabelas |
| **Gray 200** | `#E5E7EB` | Bordas |
| **Gray 300** | `#D1D5DB` | Bordas ativas |
| **Gray 500** | `#6B7280` | Texto secundario |
| **Gray 700** | `#374151` | Texto body |
| **Gray 900** | `#111827` | Texto heading, high emphasis |

### Gradientes

```css
/* Gradiente principal — headers, hero sections */
--gradient-primary: linear-gradient(135deg, #6C3FE0 0%, #00C9A7 100%);

/* Gradiente sutil — fundos de secao */
--gradient-subtle: linear-gradient(180deg, #F9FAFB 0%, #FFFFFF 100%);

/* Gradiente header de pagina */
--gradient-header: linear-gradient(135deg, #6C3FE0 0%, #8B5CF6 50%, #00C9A7 100%);

/* Gradiente para barras de progresso */
--gradient-progress: linear-gradient(90deg, #6C3FE0 0%, #00C9A7 100%);
```

---

## 2. Tipografia

### Familia

| Tipo | Fonte | Fallback | Google Fonts |
|------|-------|----------|------|
| Heading | Inter | -apple-system, sans-serif | `Inter:wght@700;800` |
| Body | Inter | -apple-system, sans-serif | `Inter:wght@400;500;600` |
| Mono | JetBrains Mono | monospace | `JetBrains+Mono:wght@400` |

### Escala Tipografica

| Token | Tamanho | Peso | Line Height | Uso |
|-------|---------|------|-------------|-----|
| `--text-display` | 2.5rem (40px) | 800 | 1.1 | Titulo principal do documento |
| `--text-h1` | 2rem (32px) | 700 | 1.2 | Titulos de secao (Epico, Sprint) |
| `--text-h2` | 1.5rem (24px) | 700 | 1.3 | Subtitulos (Planning, Review) |
| `--text-h3` | 1.25rem (20px) | 600 | 1.4 | Titulos de card, coluna |
| `--text-h4` | 1rem (16px) | 600 | 1.4 | Labels, categorias |
| `--text-body` | 0.9375rem (15px) | 400 | 1.6 | Corpo de texto |
| `--text-small` | 0.8125rem (13px) | 400 | 1.5 | Notas, metadata |
| `--text-caption` | 0.75rem (12px) | 500 | 1.4 | Badges, tags, timestamps |
| `--text-metric` | 3rem (48px) | 800 | 1.0 | Numeros grandes (KPIs) |

### CSS

```css
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400&display=swap');

body {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
  font-size: 0.9375rem;
  font-weight: 400;
  line-height: 1.6;
  color: #374151;
  -webkit-font-smoothing: antialiased;
}

h1, h2, h3, h4 {
  font-family: 'Inter', sans-serif;
  color: #111827;
  margin-top: 0;
}

h1 { font-size: 2rem; font-weight: 700; line-height: 1.2; }
h2 { font-size: 1.5rem; font-weight: 700; line-height: 1.3; }
h3 { font-size: 1.25rem; font-weight: 600; line-height: 1.4; }
h4 { font-size: 1rem; font-weight: 600; line-height: 1.4; }

code, .mono {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.85em;
}
```

---

## 3. Espacamento

### Escala (base 8px)

| Token | Valor | Uso |
|-------|-------|-----|
| `--space-xs` | 4px | Padding interno de badges |
| `--space-sm` | 8px | Gap entre elementos proximos |
| `--space-md` | 16px | Padding interno de cards |
| `--space-lg` | 24px | Gap entre cards, secoes |
| `--space-xl` | 32px | Margem entre secoes |
| `--space-2xl` | 48px | Separacao de blocos grandes |
| `--space-3xl` | 64px | Margem header/footer de pagina |

### Regras

- Padding interno de componentes: `--space-md` (16px)
- Gap entre cards no mesmo grupo: `--space-sm` (8px)
- Margem entre secoes: `--space-xl` (32px)
- Margem de pagina (PDF): `20mm` todos os lados

---

## 4. Bordas e Raio

### Border Radius

| Token | Valor | Uso |
|-------|-------|-----|
| `--radius-sm` | 4px | Badges, tags |
| `--radius-md` | 8px | Cards, inputs |
| `--radius-lg` | 12px | Containers, modais |
| `--radius-xl` | 16px | Secoes destacadas |
| `--radius-pill` | 999px | Pills, status dots |

### Borders

```css
--border-default: 1px solid #E5E7EB;
--border-active: 1px solid #D1D5DB;
--border-primary: 2px solid #6C3FE0;
--border-success: 2px solid #10B981;
--border-warning: 2px solid #F59E0B;
--border-danger: 2px solid #EF4444;
```

---

## 5. Sombras (Elevacao)

| Token | Valor CSS | Uso |
|-------|-----------|-----|
| `--shadow-sm` | `0 1px 2px rgba(0,0,0,0.05)` | Cards em repouso |
| `--shadow-md` | `0 4px 6px -1px rgba(0,0,0,0.1), 0 2px 4px -2px rgba(0,0,0,0.1)` | Cards elevados, hover |
| `--shadow-lg` | `0 10px 15px -3px rgba(0,0,0,0.1), 0 4px 6px -4px rgba(0,0,0,0.1)` | Modais, popups |
| `--shadow-glow` | `0 0 20px rgba(108,63,224,0.15)` | Destaque primary |

---

## 6. Componentes

### 6.1 Card (Backlog Item / Task)

```css
.card {
  background: #FFFFFF;
  border: 1px solid #E5E7EB;
  border-radius: 8px;
  padding: 16px;
  box-shadow: 0 1px 2px rgba(0,0,0,0.05);
  transition: box-shadow 0.2s;
}

.card:hover {
  box-shadow: 0 4px 6px -1px rgba(0,0,0,0.1);
}

/* Variante: borda lateral colorida por status */
.card--done { border-left: 4px solid #10B981; }
.card--in-progress { border-left: 4px solid #F59E0B; }
.card--todo { border-left: 4px solid #6B7280; }
.card--blocked { border-left: 4px solid #EF4444; }

/* Variante: card de epico (mais destaque) */
.card--epic {
  background: linear-gradient(135deg, #F9FAFB 0%, #FFFFFF 100%);
  border: 1px solid #8B5CF6;
  border-left: 4px solid #6C3FE0;
}

.card__title {
  font-size: 1rem;
  font-weight: 600;
  color: #111827;
  margin: 0 0 8px 0;
}

.card__meta {
  font-size: 0.8125rem;
  color: #6B7280;
}

.card__id {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.75rem;
  color: #6C3FE0;
  font-weight: 500;
}
```

---

### 6.2 Badge / Tag

```css
.badge {
  display: inline-flex;
  align-items: center;
  padding: 2px 8px;
  font-size: 0.75rem;
  font-weight: 500;
  border-radius: 999px;
  line-height: 1.4;
  text-transform: uppercase;
  letter-spacing: 0.025em;
}

/* Status */
.badge--done { background: #ECFDF5; color: #065F46; }
.badge--in-progress { background: #FFFBEB; color: #92400E; }
.badge--todo { background: #F9FAFB; color: #374151; border: 1px solid #E5E7EB; }
.badge--blocked { background: #FEF2F2; color: #991B1B; }

/* Prioridade */
.badge--high { background: #FEF2F2; color: #991B1B; }
.badge--medium { background: #FFFBEB; color: #92400E; }
.badge--low { background: #F0FDF4; color: #166534; }

/* Story Points */
.badge--sp {
  background: #EDE9FE;
  color: #5B21B6;
  font-family: 'JetBrains Mono', monospace;
  font-weight: 600;
  min-width: 24px;
  text-align: center;
}

/* Epico */
.badge--epic {
  background: linear-gradient(135deg, #6C3FE0, #8B5CF6);
  color: #FFFFFF;
  font-weight: 600;
}
```

---

### 6.3 Progress Bar

```css
.progress {
  width: 100%;
  height: 8px;
  background: #F3F4F6;
  border-radius: 999px;
  overflow: hidden;
}

.progress__fill {
  height: 100%;
  border-radius: 999px;
  background: linear-gradient(90deg, #6C3FE0 0%, #00C9A7 100%);
  transition: width 0.3s ease;
}

/* Variante: barra grossa para destaque */
.progress--lg {
  height: 12px;
}

/* Variante: com label */
.progress-labeled {
  display: flex;
  align-items: center;
  gap: 12px;
}

.progress-labeled__value {
  font-size: 0.875rem;
  font-weight: 700;
  color: #6C3FE0;
  min-width: 40px;
}
```

---

### 6.4 Tabela Estilizada

```css
.table {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.8125rem;
}

.table thead {
  background: #F9FAFB;
  border-bottom: 2px solid #E5E7EB;
}

.table th {
  padding: 12px 16px;
  text-align: left;
  font-weight: 600;
  color: #374151;
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.table td {
  padding: 12px 16px;
  border-bottom: 1px solid #F3F4F6;
  color: #374151;
}

.table tbody tr:hover {
  background: #F9FAFB;
}

/* Variante: tabela compacta */
.table--compact th,
.table--compact td {
  padding: 8px 12px;
}

/* Variante: coluna numerica alinhada a direita */
.table td.numeric {
  text-align: right;
  font-family: 'JetBrains Mono', monospace;
  font-weight: 500;
}
```

---

### 6.5 Kanban Column

```css
.kanban {
  display: flex;
  gap: 16px;
  overflow-x: auto;
}

.kanban-column {
  flex: 1;
  min-width: 200px;
  background: #F9FAFB;
  border-radius: 12px;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.kanban-column__header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-bottom: 12px;
  border-bottom: 2px solid transparent;
  margin-bottom: 8px;
}

.kanban-column__title {
  font-size: 0.875rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.kanban-column__count {
  font-size: 0.75rem;
  font-weight: 600;
  background: #E5E7EB;
  padding: 2px 8px;
  border-radius: 999px;
}

/* Cores por coluna */
.kanban-column--todo .kanban-column__header { border-color: #6B7280; }
.kanban-column--progress .kanban-column__header { border-color: #F59E0B; }
.kanban-column--review .kanban-column__header { border-color: #8B5CF6; }
.kanban-column--done .kanban-column__header { border-color: #10B981; }
.kanban-column--blocked .kanban-column__header { border-color: #EF4444; }
```

---

### 6.6 Metric Box (KPI)

```css
.metric-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
  gap: 16px;
}

.metric-box {
  background: #FFFFFF;
  border: 1px solid #E5E7EB;
  border-radius: 12px;
  padding: 20px;
  text-align: center;
}

.metric-box__value {
  font-size: 3rem;
  font-weight: 800;
  line-height: 1;
  background: linear-gradient(135deg, #6C3FE0, #00C9A7);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.metric-box__label {
  font-size: 0.75rem;
  font-weight: 500;
  color: #6B7280;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-top: 8px;
}

/* Variante: com tendencia */
.metric-box__trend {
  font-size: 0.75rem;
  font-weight: 600;
  margin-top: 4px;
}

.metric-box__trend--up { color: #10B981; }
.metric-box__trend--down { color: #EF4444; }
```

---

### 6.7 Chart Container (Burndown)

```css
.chart-container {
  background: #FFFFFF;
  border: 1px solid #E5E7EB;
  border-radius: 12px;
  padding: 24px;
}

.chart-container__title {
  font-size: 1.25rem;
  font-weight: 700;
  color: #111827;
  margin-bottom: 4px;
}

.chart-container__subtitle {
  font-size: 0.8125rem;
  color: #6B7280;
  margin-bottom: 24px;
}
```

---

### 6.7.1 Paleta de Graficos (Colorblind-Safe)

> Baseada em Wong (2011) — distinguivel em protanopia, deuteranopia e tritanopia.
> Cada linha se diferencia por **cor + forma** (tracejado, espessura, pontos).

| Funcao | Hex | Nome | Forma |
|--------|-----|------|-------|
| **Tasks remaining (real)** | `#0072B2` | Blue | Solido, 2.5px |
| **SP remaining** | `#E69F00` | Orange/Amber | Solido, 2px |
| **Ideal line** | `#009E73` | Green | Tracejado 6-4, 2px |
| **Projected line** | `#CC79A7` | Pink/Magenta | Tracejado 4-3, 2.5px |
| **Done (burnup)** | `#009E73` | Green | Solido, 2.5px |
| **Scope (burnup)** | `#E69F00` | Orange/Amber | Tracejado 8-4, 2px |
| **Scope markers (+N)** | `#D55E00` | Red-Orange | Bold text, 9px |
| **Stat values** | `#0072B2` | Blue | Bold, 24px |

#### CSS dos graficos

```css
/* Linhas */
.line-real    { stroke: #0072B2; stroke-width: 2.5; }         /* azul escuro, solido */
.line-sp      { stroke: #E69F00; stroke-width: 2; }           /* laranja, solido */
.line-ideal   { stroke: #009E73; stroke-dasharray: 6 4; }     /* verde, tracejado */
.line-projected { stroke: #CC79A7; stroke-dasharray: 4 3; }   /* rosa, tracejado */
.line-done    { stroke: #009E73; stroke-width: 2.5; }         /* verde, solido */
.line-scope   { stroke: #E69F00; stroke-dasharray: 8 4; }     /* laranja, tracejado */

/* Pontos */
.dot-real     { fill: #0072B2; }
.dot-sp       { fill: #E69F00; }
.dot-ideal    { fill: #009E73; }
.dot-projected { fill: #CC79A7; }
.dot-done     { fill: #009E73; }
.dot-scope    { fill: #E69F00; }

/* Areas (gradiente vertical com transparencia) */
.area-real    { fill: #0072B2; opacity: 0.15; }
.area-done    { fill: #009E73; opacity: 0.12; }

/* Eixo Y direito (SP) */
.y-axis-sp    { stroke: #E69F00; stroke-dasharray: 3 2; }
.y-label-sp   { fill: #E69F00; }

/* Scope change markers */
.scope-marker { fill: #D55E00; font-weight: 700; }
```

#### Principios de Acessibilidade

1. **Nunca diferenciar apenas por matiz** — cada linha usa combinacao de cor + dash pattern
2. **Contraste minimo 3:1** contra fundo branco em todas as cores
3. **Redundancia visual** — dots reforçam onde a linha esta, labels numericos em cada ponto
4. **Eixos duais** — left axis (azul) e right axis (laranja) com labels de cor correspondente
5. **Testado com** simuladores de deuteranopia, protanopia e tritanopia

#### Como testar

- Chrome DevTools > Rendering > Emulate vision deficiencies
- Ou usar [Coblis](https://www.color-blindness.com/coblis-color-blindness-simulator/)

---

### 6.8 Section Header

```css
.section-header {
  margin-bottom: 24px;
  padding-bottom: 12px;
  border-bottom: 3px solid transparent;
  border-image: linear-gradient(90deg, #6C3FE0 0%, #00C9A7 100%) 1;
}

.section-header__title {
  font-size: 1.5rem;
  font-weight: 700;
  color: #111827;
  margin: 0;
}

.section-header__subtitle {
  font-size: 0.875rem;
  color: #6B7280;
  margin-top: 4px;
}

/* Variante: com badge de status */
.section-header__badge {
  display: inline-flex;
  margin-left: 12px;
  vertical-align: middle;
}
```

---

### 6.9 Page Layout (A4 PDF)

```css
@page {
  size: A4;
  margin: 20mm;
}

.page {
  width: 210mm;
  min-height: 297mm;
  padding: 20mm;
  background: #FFFFFF;
  font-family: 'Inter', sans-serif;
}

/* Capa */
.page-cover {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  min-height: 257mm; /* 297 - 40 margin */
  text-align: center;
  background: linear-gradient(135deg, #6C3FE0 0%, #8B5CF6 50%, #00C9A7 100%);
  color: #FFFFFF;
  margin: -20mm;
  padding: 40mm;
}

.page-cover__title {
  font-size: 3rem;
  font-weight: 800;
  line-height: 1.1;
  margin-bottom: 16px;
}

.page-cover__subtitle {
  font-size: 1.25rem;
  font-weight: 400;
  opacity: 0.9;
}

.page-cover__meta {
  font-size: 0.875rem;
  opacity: 0.7;
  margin-top: 32px;
}

/* Header de pagina recorrente */
.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-bottom: 12px;
  border-bottom: 1px solid #E5E7EB;
  margin-bottom: 24px;
  font-size: 0.75rem;
  color: #6B7280;
}

/* Footer de pagina */
.page-footer {
  position: fixed;
  bottom: 20mm;
  left: 20mm;
  right: 20mm;
  font-size: 0.6875rem;
  color: #9CA3AF;
  display: flex;
  justify-content: space-between;
  border-top: 1px solid #F3F4F6;
  padding-top: 8px;
}

/* Page breaks */
.page-break { page-break-before: always; }
.no-break { page-break-inside: avoid; }
```

---

## 7. CSS Custom Properties (Root)

```css
:root {
  /* Cores */
  --color-primary: #6C3FE0;
  --color-primary-light: #8B5CF6;
  --color-primary-dark: #5022C3;
  --color-secondary: #00C9A7;
  --color-secondary-light: #34D399;
  --color-accent: #FF6B6B;

  --color-success: #10B981;
  --color-success-bg: #ECFDF5;
  --color-warning: #F59E0B;
  --color-warning-bg: #FFFBEB;
  --color-danger: #EF4444;
  --color-danger-bg: #FEF2F2;

  --color-neutral-0: #FFFFFF;
  --color-neutral-50: #F9FAFB;
  --color-neutral-100: #F3F4F6;
  --color-neutral-200: #E5E7EB;
  --color-neutral-300: #D1D5DB;
  --color-neutral-500: #6B7280;
  --color-neutral-700: #374151;
  --color-neutral-900: #111827;

  /* Gradientes */
  --gradient-primary: linear-gradient(135deg, #6C3FE0 0%, #00C9A7 100%);
  --gradient-subtle: linear-gradient(180deg, #F9FAFB 0%, #FFFFFF 100%);
  --gradient-header: linear-gradient(135deg, #6C3FE0 0%, #8B5CF6 50%, #00C9A7 100%);
  --gradient-progress: linear-gradient(90deg, #6C3FE0 0%, #00C9A7 100%);

  /* Tipografia */
  --font-heading: 'Inter', -apple-system, sans-serif;
  --font-body: 'Inter', -apple-system, sans-serif;
  --font-mono: 'JetBrains Mono', monospace;

  --text-display: 2.5rem;
  --text-h1: 2rem;
  --text-h2: 1.5rem;
  --text-h3: 1.25rem;
  --text-h4: 1rem;
  --text-body: 0.9375rem;
  --text-small: 0.8125rem;
  --text-caption: 0.75rem;
  --text-metric: 3rem;

  /* Espacamento */
  --space-xs: 4px;
  --space-sm: 8px;
  --space-md: 16px;
  --space-lg: 24px;
  --space-xl: 32px;
  --space-2xl: 48px;
  --space-3xl: 64px;

  /* Bordas */
  --radius-sm: 4px;
  --radius-md: 8px;
  --radius-lg: 12px;
  --radius-xl: 16px;
  --radius-pill: 999px;

  --border-default: 1px solid #E5E7EB;
  --border-primary: 2px solid #6C3FE0;

  /* Sombras */
  --shadow-sm: 0 1px 2px rgba(0,0,0,0.05);
  --shadow-md: 0 4px 6px -1px rgba(0,0,0,0.1), 0 2px 4px -2px rgba(0,0,0,0.1);
  --shadow-lg: 0 10px 15px -3px rgba(0,0,0,0.1), 0 4px 6px -4px rgba(0,0,0,0.1);
  --shadow-glow: 0 0 20px rgba(108,63,224,0.15);
}
```

---

## 8. Print / PDF Rules

```css
@media print {
  body {
    font-size: 10pt;
    line-height: 1.5;
    color: #111827;
  }

  /* Nao quebrar componentes no meio */
  .card, .metric-box, .table, .chart-container, .kanban-column {
    page-break-inside: avoid;
  }

  /* Forcar quebra antes de secoes */
  .section-header {
    page-break-before: always;
  }

  .section-header:first-of-type {
    page-break-before: avoid;
  }

  /* Remover sombras (economiza tinta) */
  .card, .metric-box {
    box-shadow: none;
    border: 1px solid #D1D5DB;
  }

  /* Gradientes em texto nao imprimem — usar cor solida */
  .metric-box__value {
    background: none;
    -webkit-text-fill-color: #6C3FE0;
    color: #6C3FE0;
  }

  /* Ajuste de fonte para impressao */
  h1 { font-size: 18pt; }
  h2 { font-size: 14pt; }
  h3 { font-size: 12pt; }
  .table { font-size: 8pt; }
  .badge { font-size: 7pt; }

  /* Forcar cores de fundo impressas */
  * {
    -webkit-print-color-adjust: exact !important;
    print-color-adjust: exact !important;
  }
}
```

---

## 9. Marp / Slides

### Tema Marp

```yaml
---
marp: true
theme: uncover
class: invert
style: |
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;700;800&display=swap');
  section {
    font-family: 'Inter', sans-serif;
    background: #FFFFFF;
    color: #111827;
  }
  section.lead {
    background: linear-gradient(135deg, #6C3FE0 0%, #8B5CF6 50%, #00C9A7 100%);
    color: #FFFFFF;
  }
  h1 { color: #6C3FE0; font-weight: 800; }
  h2 { color: #374151; font-weight: 700; }
  strong { color: #6C3FE0; }
  code { background: #F3F4F6; padding: 2px 6px; border-radius: 4px; }
---
```

### Regras para Slides

| Elemento | No PDF (A4) | No Slide (16:9) |
|----------|-------------|-----------------|
| Body font | 15px | 24px |
| H1 | 32px | 48px |
| H2 | 24px | 36px |
| Table font | 13px | 20px |
| Metric value | 48px | 72px |
| Max items por slide | — | 5-7 itens |
| Charts | Detalhados | Simplificados |

### Estrutura dos Slides (10-15 min)

| # | Slide | Tipo | Tempo |
|---|-------|------|-------|
| 1 | Capa (titulo + equipe) | lead | 30s |
| 2 | O Projeto (1 frase + diagrama) | content | 1 min |
| 3 | Metodologia Scrum (como aplicamos) | content | 1.5 min |
| 4 | Product Backlog (visual com epicos) | visual | 2 min |
| 5 | Sprint 1 — Sub-sprints + resultados | content | 2 min |
| 6 | Burndown Chart Sprint 1 (grafico) | visual | 1.5 min |
| 7 | Sprint 2 — Planning + Kanban | visual | 2 min |
| 8 | Burndown Sprint 2 (projecao) | visual | 1 min |
| 9 | DoD + Retrospectiva (licoes) | content | 1.5 min |
| 10 | Encerramento + perguntas | lead | 1 min |

---

## 10. Exemplos de Composicao

### Layout: Pagina de Burndown

```
+------------------------------------------+
| [Page Header: Plataforma Academica | p.3] |
+------------------------------------------+
|                                          |
| [Section Header: Burndown Chart]         |
| Sprint 1 — 15/04 a 30/04                |
|                                          |
| +--------------------------------------+ |
| | [Metric Grid: 4 boxes]               | |
| | 193 SP | 59 Tasks | 16 dias | 100%  | |
| +--------------------------------------+ |
|                                          |
| +--------------------------------------+ |
| | [Chart Container]                    | |
| |                                      | |
| |   [SVG Burndown: ideal + real]       | |
| |                                      | |
| |   [Legend: Real / Ideal / Projected] | |
| +--------------------------------------+ |
|                                          |
| +--------------------------------------+ |
| | [Table: dados diarios]               | |
| +--------------------------------------+ |
|                                          |
+------------------------------------------+
| [Page Footer: Sprint 1 | 2026]          |
+------------------------------------------+
```

### Layout: Pagina de Kanban

```
+------------------------------------------+
| [Page Header]                            |
+------------------------------------------+
|                                          |
| [Section Header: Kanban Board]           |
| Sprint 2 — Estado em 05/05              |
|                                          |
| +------+------+------+------+------+    |
| | TODO | PROG | REVW | DONE | BLKD |    |
| |      |      |      |      |      |    |
| |[card]|[card]|[card]|[card]|      |    |
| |[card]|[card]|      |[card]|      |    |
| |[card]|      |      |[card]|      |    |
| |      |      |      |[card]|      |    |
| +------+------+------+------+------+    |
|                                          |
| [Metric Grid: WIP | Lead Time | Done%]  |
|                                          |
+------------------------------------------+
```

---

## Uso nos Templates Jinja2

Cada template HTML deve incluir no `<head>`:

```html
<head>
  <meta charset="utf-8">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400&display=swap" rel="stylesheet">
  <style>
    /* Colar o bloco :root completo da secao 7 */
    /* Colar os componentes necessarios da secao 6 */
    /* Colar regras de print da secao 8 */
  </style>
</head>
```

Dados vem do `data.json` via variavel Jinja2:

```html
{% for story in backlog.stories %}
<div class="card card--{{ story.status }}">
  <span class="card__id">{{ story.id }}</span>
  <h4 class="card__title">{{ story.title }}</h4>
  <div class="card__meta">
    <span class="badge badge--{{ story.priority }}">{{ story.priority }}</span>
    <span class="badge badge--sp">{{ story.sp }} SP</span>
  </div>
</div>
{% endfor %}
```
