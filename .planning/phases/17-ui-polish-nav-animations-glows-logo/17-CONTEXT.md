# Phase 17: UI Polish — Nav Animations, Glows, Logo - Context

**Gathered:** 2026-05-10
**Status:** Ready for planning

<domain>
## Phase Boundary

Fix three UI regressions/issues discovered after Phase 16 delivery: (1) bottom navbar animations not functioning correctly, (2) glow effect colors in light mode look poor and need retuning, and (3) the logo on the front/login page is at an unreadable size. Additionally, add missing 6th tab (Support) to client navigation. No new features — purely visual bugfix and polish.

</domain>

<decisions>
## Implementation Decisions

### Bottom Nav Animation Fix

- **D-01:** Convert `GlassBottomNav` from `StatelessWidget` to `StatefulWidget` with explicit `AnimationController` to guarantee animation persistence across GoRouter navigation rebuilds. The current `AnimatedContainer` + `TweenAnimationBuilder` approach fails because the widget may be getting reconstructed rather than updated.
- **D-02:** Animation parameters (curve, duration, scale values) have flexibility to be adjusted from the Phase 16 spec (easeOutBack 300ms, icon 24->28px, glow scaling) if the agent finds better values during implementation. The goals are: springy feel on selection, glow that scales with icon, smooth transition.
- **D-03:** Add 6th `NavItem` for Support to `ClientShell` destinations list, using `Icons.headset_mic` as icon. This fixes the 6-route / 5-destination mismatch where `clientSupport` (index 5) had no corresponding nav button.
- **D-04:** `StaffShell` is correctly configured (5 routes, 5 destinations) — no changes needed there.

### Light Mode Glow Palette

- **D-05:** Use a darker/deeper teal variant for glow effects in light mode instead of the Electric Teal `#00E5FF` which has insufficient contrast against light backgrounds. Target: something in the `#0097A7` to `#00838F` range that preserves the Cyber-Academic identity but reads as intentional glow (not rendering artifact).
- **D-06:** Apply light mode glow fix across all 3 affected files: `glass_bottom_nav.dart` (selected item glow), `glass_card.dart` (card neon glow), and `app_colors.dart` (color definitions).
- **D-07:** Adapt glassmorphism for light mode: `GlassCard` and `GlassBottomNav` use dark gray border + subtle shadow instead of white overlay (5% white fill + 12% white border are invisible on white backgrounds). Backdrop blur preserved, but fill and border use colors that are visible in both modes.
- **D-08:** Light mode variants of neon colors — agent decides which of `neonTeal`, `neonViolet`, `neonMagenta` need light variants based on actual usage. At minimum, `neonTeal` needs a light variant since it's the most used.

### Login Screen Logo

- **D-09:** Login screen uses the **full logo** (α mark + "ALPHA CONNECT" text + tagline) at **large size (160-200px)** so all text is readable. The current 80px renders the tagline in sub-pixel — unreadable.
- **D-10:** Short logo (α mark only) used elsewhere in the app wherever logo appears at small size. Agent identifies appropriate locations (e.g., AppBar, splash screen, any context where size < ~60px).
- **D-11:** Tagline handling in the full logo SVG — agent's discretion. If the tagline is still too small even at 160-200px, it can be removed or hidden.
- **D-12:** Add subtle neon glow effect to the logo on the login screen, consistent with the Cyber-Academic design system. The login page is the first impression — should feel on-brand.
- **D-13:** Fix dead `showTagline` parameter in `AlphaConnectLogo` widget — either wire it to actually control tagline visibility or remove it to avoid confusion.

### Agent's Discretion

- Exact dark teal hex value for light mode glow (within the #0097A7-#00838F range or similar)
- Whether neonViolet and neonMagenta need light variants (based on where they're used)
- AnimationController implementation details (single vs multiple controllers, Ticker mixin)
- Whether to refine easeOutBack parameters or switch to a similar springy curve
- Exact logo glow intensity and spread on the login screen
- showTagline: wire it to work or remove it entirely
- Specific locations where short logo replaces full logo throughout the app
- Glass border color in light mode (gray tone selection)

</decisions>

<canonical_refs>

## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Bottom Nav & Animations
- `mobile/lib/shared/widgets/glass_bottom_nav.dart` — Current GlassBottomNav implementation (StatelessWidget, AnimatedContainer, TweenAnimationBuilder). Lines 74-76: animation config, lines 81-94: glow decoration.
- `mobile/lib/core/theme/app_animations.dart` — Centralized animation constants (nav bar: 300ms, easeOutBack, icon 24/28, glow spread 4.0/blur 16.0).
- `mobile/lib/features/client/screens/client_shell.dart` — Client navigation shell, 6 routes mapped but only 5 NavItems. Lines 37-45: _currentIndex, lines 64-70: _destinations.
- `mobile/lib/features/staff/screens/staff_shell.dart` — Staff navigation shell, 5 routes / 5 destinations (correct).

### Glow & Theme
- `mobile/lib/core/theme/app_colors.dart` — Color definitions. Lines 9-40: light colors, lines 42-73: dark colors, lines 75-78: neon glow colors. Note: primary == darkPrimary == neonTeal == #00E5FF.
- `mobile/lib/core/theme/app_theme.dart` — Full ThemeData for light and dark modes (424 lines).
- `mobile/lib/shared/widgets/glass_card.dart` — GlassCard widget with glow. Line 67: light mode glow halved. Lines 60+: glassmorphism fill/border (white overlay, invisible on white).

### Logo
- `mobile/lib/features/auth/screens/login_screen.dart` — Login screen. Line 255-256: `AlphaConnectLogo(size: 80)` invocation.
- `mobile/lib/shared/widgets/alpha_connect_logo.dart` — Logo widget (65 lines). Lines 42-44: brightness detection, lines 46-55: SVG asset paths (4 variants: full/short x light/dark). showTagline param declared but unused.
- SVG assets in `mobile/assets/logos/` — full_logo_light.svg, full_logo_dark.svg, short_logo_light.svg, short_logo_dark.svg

### Design System Context
- `.planning/phases/10-cross-platform-polish/10-CONTEXT.md` — D-16/17/18: dark mode support decisions.
- STATE.md accumulated decisions — Phase 15 (Cyber-Academic design tokens), Phase 15.2 (SVG logos), Phase 16 (animation specs).

</canonical_refs>

<code_context>

## Existing Code Insights

### Reusable Assets

- **GlassBottomNav** (`shared/widgets/glass_bottom_nav.dart`): Central widget to refactor — currently StatelessWidget, needs StatefulWidget conversion. 139 lines.
- **GlassCard** (`shared/widgets/glass_card.dart`): Needs light mode glow/border adaptation. Already has `isDark` check and `elevation` parameter with 3 glow levels.
- **AlphaConnectLogo** (`shared/widgets/alpha_connect_logo.dart`): 65 lines, 4 SVG variants, brightness-aware. Needs size/tagline fixes.
- **AppAnimations** (`core/theme/app_animations.dart`): Pure constants class, 54 lines. Well-structured for nav animation values.
- **AppColors** (`core/theme/app_colors.dart`): 79 lines, needs light neon color variants added.
- **ThemeProvider** (`core/theme/theme_provider.dart`): Riverpod notifier with SharedPreferences — handles light/dark switching.

### Established Patterns

- **Brightness branching**: GlassCard (line 67) and GlassBottomNav (line 57) already check `isDark` for some properties — extend this pattern to glow colors.
- **AppColors static constants**: All colors defined as static const — add new light-mode neon variants following same pattern.
- **SVG asset variants**: 4 SVG files (full/short x light/dark) already exist with brightness-based selection in AlphaConnectLogo.
- **AnimatedEntrance**: Existing animation widget from Phase 16 (StaggeredAnimationBuilder pattern) — but not directly relevant to nav animation fix.

### Integration Points

- **ClientShell**: Needs 6th NavItem + passes `currentIndex` to GlassBottomNav.
- **GlassBottomNav**: Used by both ClientShell and StaffShell — changes affect both.
- **AppColors**: Imported across the entire app — new light variants must not break existing dark usage.
- **Login screen**: Single point of change for logo size and glow.

</code_context>

<specifics>
## Specific Ideas

- User wants the full logo (α + ALPHA CONNECT text) prominently on the login screen — first impression matters.
- Short logo (α mark only) should appear wherever the logo is used at small sizes throughout the app — agent identifies the spots.
- Logo on login should have glow effect to match the Cyber-Academic aesthetic.
- Light mode should still feel "cyber-academic" but with readable contrast — not just a dimmed version of dark mode neon.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

_Phase: 17-ui-polish-nav-animations-glows-logo_
_Context gathered: 2026-05-10_
