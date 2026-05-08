---
name: Cyber-Academic Intelligence System
colors:
  surface: '#111317'
  surface-dim: '#111317'
  surface-bright: '#37393e'
  surface-container-lowest: '#0c0e12'
  surface-container-low: '#1a1c20'
  surface-container: '#1e2024'
  surface-container-high: '#282a2e'
  surface-container-highest: '#333539'
  on-surface: '#e2e2e8'
  on-surface-variant: '#bac9cc'
  inverse-surface: '#e2e2e8'
  inverse-on-surface: '#2f3035'
  outline: '#849396'
  outline-variant: '#3b494c'
  surface-tint: '#00daf3'
  primary: '#c3f5ff'
  on-primary: '#00363d'
  primary-container: '#00e5ff'
  on-primary-container: '#00626e'
  inverse-primary: '#006875'
  secondary: '#dcb8ff'
  on-secondary: '#480081'
  secondary-container: '#7701d0'
  on-secondary-container: '#dcb7ff'
  tertiary: '#ffe7eb'
  on-tertiary: '#66002c'
  tertiary-container: '#ffc0cd'
  on-tertiary-container: '#b10053'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#9cf0ff'
  primary-fixed-dim: '#00daf3'
  on-primary-fixed: '#001f24'
  on-primary-fixed-variant: '#004f58'
  secondary-fixed: '#efdbff'
  secondary-fixed-dim: '#dcb8ff'
  on-secondary-fixed: '#2c0051'
  on-secondary-fixed-variant: '#6700b5'
  tertiary-fixed: '#ffd9e0'
  tertiary-fixed-dim: '#ffb1c3'
  on-tertiary-fixed: '#3f0019'
  on-tertiary-fixed-variant: '#8f0041'
  background: '#111317'
  on-background: '#e2e2e8'
  surface-variant: '#333539'
typography:
  display-xl:
    fontFamily: Montserrat
    fontSize: 64px
    fontWeight: '900'
    lineHeight: '1.1'
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Montserrat
    fontSize: 32px
    fontWeight: '800'
    lineHeight: '1.2'
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Montserrat
    fontSize: 24px
    fontWeight: '700'
    lineHeight: '1.3'
  body-lg:
    fontFamily: Montserrat
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.6'
  body-md:
    fontFamily: Montserrat
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.5'
  label-bold:
    fontFamily: Montserrat
    fontSize: 12px
    fontWeight: '700'
    lineHeight: '1.0'
    letterSpacing: 0.1em
  ai-mono:
    fontFamily: jetbrainsMono
    fontSize: 14px
    fontWeight: '400'
    lineHeight: '1.5'
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 24px
  lg: 48px
  xl: 80px
  gutter: 24px
  margin: 40px
---

## Brand & Style
This design system defines a "cyber-academic" aesthetic: a fusion of rigorous data density and high-energy futuristic visuals. The personality is intellectual, rebellious, and authoritative, designed to make academic research feel like navigating a high-performance command center. 

The visual direction utilizes **Glassmorphism** as its core structural element, layered over a deep obsidian environment. It avoids the flat, muted tones of traditional enterprise software in favor of high-vibrancy accents and glowing surfaces. The result is an interface that feels alive—reacting to user inquiry with neon-lit precision and atmospheric depth.

## Colors
The palette is anchored by **Deep Obsidian**, providing a bottomless canvas that allows the high-chroma accents to pop. 

- **Electric Teal (#00E5FF)** is the primary functional accent, used for navigation, primary actions, and success states. 
- **Cyber Violet (#8A2BE2)** is reserved exclusively for AI-driven insights, generative summaries, and "intelligence" moments, creating a clear visual distinction between human-input data and machine-generated thought.
- **Tertiary Magenta (#FF007A)** is used sparingly for critical alerts or high-priority notifications to break the cool-tone dominance.
- Glass surfaces use a semi-transparent white with low opacity, ensuring the background remains visible while providing enough contrast for readability.

## Typography
The typographic strategy relies on extreme weight contrast to establish hierarchy. Headlines are rendered in **Montserrat Black (900)** or **ExtraBold (800)** to command attention, while body text remains in **Regular (400)** or **Light (300)** for optimal legibility against dark backgrounds.

A secondary monospaced font, **JetBrains Mono**, is introduced for technical data strings, citations, and AI "thinking" logs, reinforcing the academic and technical nature of the design system. All labels use high-tracking (letter spacing) and uppercase styling to create a "heads-up display" (HUD) feel.

## Layout & Spacing
The design system employs a **12-column fluid grid** with generous margins to prevent the UI from feeling cluttered. Content is organized into modular "glass" units that can span multiple columns. 

A strict 8px base unit governs all padding and margins. In complex data views, a "Compact" mode is available which reduces the base unit to 4px, but the standard "Vibrant" mode prioritizes whitespace to enhance the glowing, ethereal quality of the components.

## Elevation & Depth
Elevation is communicated through **translucency and blur** rather than traditional drop shadows. 

1.  **Background:** The base Obsidian layer.
2.  **Layer 1 (Standard Cards):** Background blur (20px), 5% white fill, 1px white border at 12% opacity.
3.  **Layer 2 (Modals/Popovers):** Background blur (40px), 8% white fill, and a subtle outer glow using the primary accent color (Teal) with a 20px spread at 10% opacity.
4.  **AI Insights:** These cards feature a "Cyber Violet" inner glow (inset) to distinguish them from standard system data.

The "glow" effect is key: interactive elements should feel as though they are emitting light onto the obsidian floor beneath them.

## Shapes
All primary containers, cards, and input fields utilize a **1rem (16px) corner radius**. This softness balances the aggressive "cyber" colors, making the system feel sophisticated and approachable. 

Buttons and tags use a "Pill-shaped" (Full Round) style to differentiate them from the structural card containers. Small interactive icons and checkboxes use a reduced radius of 4px to maintain precision.

## Components
- **Buttons:** Primary buttons are solid Electric Teal with black text for maximum contrast. Secondary buttons are "ghost" style with a teal border and a subtle hover glow.
- **AI Insight Cards:** These feature a gradient border transitioning from Cyber Violet to transparent. They include a small "Spark" icon in the top right to denote AI origin.
- **Glass Cards:** Every card must have a `backdrop-filter: blur(20px)` and a thin, high-contrast top-border to catch the "light."
- **Input Fields:** Deep black fill (darker than the obsidian background) with a 1px teal bottom border that expands on focus.
- **Data Visualizations:** Graphs and charts use glowing neon lines. Avoid solid fills; use gradients that bleed into transparency to maintain the "light-based" aesthetic.
- **Tabs:** Underline-style indicators using the Cyber Violet accent for AI-filtered views and Electric Teal for standard views.