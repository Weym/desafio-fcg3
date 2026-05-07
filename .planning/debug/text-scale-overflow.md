---
status: diagnosed
trigger: "text-scale-overflow — Flutter app layout distorts at ≥2.0x system font scale (UAT Test 4)"
created: 2026-05-07T15:10:00Z
updated: 2026-05-07T15:15:00Z
---

## Current Focus

hypothesis: CONFIRMED — compound root cause: (A) no global textScaler clamp in MaterialApp + (B) multiple fixed-dimension containers and Row/Column layouts with unwrapped Text widgets across shells, grids, and badges.
test: Verified via direct file reads + `grep -r textScaler/TextScaler` (0 matches) + `grep builder:` (only showDatePicker wrappers, not MaterialApp).
expecting: Diagnosis complete — return ROOT CAUSE FOUND output for /gsd-plan-phase --gaps to design the fix.
next_action: Hand off to fix-planning — this is diagnose-only mode (goal: find_root_cause_only).

## Symptoms

expected: No text clipped/overflowed at 2.0x system font scale across 9 main screens (UI-NFR-02).
actual: User reported (pt-BR): "aumentei e acessibilidade para muito alto, e distorceu tudo" — UI distorted everywhere at high accessibility text scale.
errors: No runtime exceptions; expected yellow/black RenderFlex overflow banners in debug builds.
reproduction: Set system font scale to ≥2.0x (Android largest / iOS max "Larger Text") → launch app → navigate 9 screens.
started: Discovered 2026-05-07 during Phase 10 UAT Test 4. Phase 10 Plan 05 Task 3 called out the risk ("Ensure textScaleFactor up to 2.0 doesn't break layouts") but review pass did not cover all sites.

## Eliminated

- hypothesis: "Maybe there IS a textScaler clamp somewhere in the widget tree (e.g., in a router builder, splash screen, or shell)"
  evidence: `grep -r "textScaler\|textScaleFactor\|TextScaler"` across `mobile/lib/` returned 0 matches (2026-05-07T15:12:00Z). No code anywhere in the Flutter app touches text scaling. The only `builder: (context, child)` occurrences are in `create_slot_sheet.dart:65,85` — those are `showDatePicker`/`showTimePicker` locale wrappers, NOT MaterialApp.router builders.
  timestamp: 2026-05-07T15:12:00Z

- hypothesis: "AppBarActions (used on client home + staff dashboard) might contain overflowing text"
  evidence: Read `mobile/lib/shared/widgets/app_bar_actions.dart` (40 lines) — only two IconButtons (theme toggle + logout), no Text widgets. Tooltips only. Safe at any scale.
  timestamp: 2026-05-07T15:12:00Z

## Evidence

- timestamp: 2026-05-07T15:10:00Z
  checked: mobile/lib/main.dart (complete file, 40 lines)
  found: MaterialApp.router has NO `builder:` callback wrapping MediaQuery with a textScaler cap. Properties set: title, theme, darkTheme, themeMode, debugShowCheckedModeBanner, routerConfig. Nothing else.
  implication: The OS system textScaleFactor flows into the app unclamped. If user sets Android "largest" (~1.3x) or the AccessibilityService font scale ≥2.0x, every Text widget scales proportionally, exposing every fixed-height / non-Flexible layout.

- timestamp: 2026-05-07T15:10:00Z
  checked: mobile/lib/core/theme/app_theme.dart (complete file, 390 lines)
  found: `AppTheme.responsiveTextTheme(base, screenWidth)` scales headings 1.2x only on desktop (≥1024dp). There is no interaction with `MediaQuery.textScalerOf()` and no clamp. Also, theme hardcodes several `fontSize:` values (appBar title 20, buttons 16, bottom nav 10) — these DO honor textScaler (Flutter default), which is precisely what makes them blow up layouts at 2.0x.
  implication: Nothing in theme bounds text growth. The `fontSize: 10` in `NavigationBarThemeData` (line 194, 201, 332, 338) becomes 20sp at 2.0x — BottomNavigationBar labels explicitly set to 10pt will double and wrap/overflow because the glass nav container is fixed at `height: 80 + bottomPadding` (client_shell.dart:186, staff_shell.dart:186).

- timestamp: 2026-05-07T15:10:00Z
  checked: mobile/lib/features/client/screens/client_shell.dart (lines 184–260) + mobile/lib/features/staff/screens/staff_shell.dart (lines 184–260)
  found: `_GlassBottomNav` wraps a `Container(height: 80 + bottomPadding, ...)` (line 186). Inside, each nav item is a Column with Icon (24dp) + `SizedBox(height: 2)` + `Text(item.label, style: TextStyle(fontSize: 10, ...))` with NO `maxLines`, NO `overflow: TextOverflow.ellipsis`, and NO `Flexible`. The parent Row uses `mainAxisAlignment: MainAxisAlignment.spaceAround` but items are not `Expanded`, so at 2.0x scale, "Notificações" / "Intervenção" / "Documentos" will exceed their slot width and the Column will overflow the fixed 80dp height.
  implication: At 2.0x: label height alone becomes ~20sp tall text + 24dp icon + 2dp gap = >48dp; in 80dp container minus bottom safe area this may still render but padding (`AppSpacing.sm` = 8 each side = 16) pushes it over. Width-wise, Portuguese labels like "Notificações" (13 chars) at 20sp will definitely exceed the per-item slot on a 360dp phone — 5 items / 360 = 72dp each. BOTH shells affected (client + staff).

- timestamp: 2026-05-07T15:10:00Z
  checked: mobile/lib/features/staff/screens/staff_dashboard_screen.dart (lines 88–135 KPI grid, 278–333 _KpiCard, 221–276 _EnrollmentBanner)
  found: 
    1. `GridView.count(... childAspectRatio: 1.3, ...)` (line 93) — aspect ratio FIXED. At 2.0x scale, `value` (headlineMedium) and `label` (labelSmall) grow inside a cell whose height = width/1.3. On a phone (180dp cells at 360dp/2cols), that's ~138dp tall. Headline at 28pt * 2.0x = 56sp + label at 11pt * 2.0x = 22sp + icon 20 + padding → overflow.
    2. `_KpiCard` body Column has no Flexible around Text — value and label share the cell but cannot shrink.
    3. `_EnrollmentBanner` (line 232) is a Row with `Expanded(child: Column(...))` wrapping two Texts (good) BUT the trailing `Container(...child: Text('Ativo', style: TextStyle(color: ..., fontSize: 12, ...)))` (line 257-270) has no Flexible and no maxLines. At 2.0x "Ativo" is small so probably fine — but the Row inside Expanded has two Texts without maxLines/overflow, so long period names will overflow vertically forcing the Row height up past the banner's intrinsic size.
    4. `GlassCard(padding: EdgeInsets.all(AppSpacing.lg))` (inside line 139) — the "Insights de Eficiência IA" header Row at line 144 wraps Text in a plain `Row(children: [Icon, SizedBox, Text])` without `Expanded`/`Flexible` — at 2.0x the title "Insights de Eficiência IA" will overflow horizontally.
  implication: Staff dashboard is the #1 visible breakage — 4 KPI cards + insights card all have non-flexible text in constrained containers.

- timestamp: 2026-05-07T15:10:00Z
  checked: mobile/lib/features/client/screens/client_home_screen.dart (lines 259–295 Quick Actions grid, 79–93 greeting)
  found:
    1. `GridView.count(crossAxisCount: 2, ... childAspectRatio: 2.2, ...)` (line 259) — FIXED aspect ratio. Each tile is Row[Icon, SizedBox, Expanded(Text)]. The Expanded is present (line 281) ✓ — good for width — but at 2.2 aspect ratio, the tile height at 360dp phone = (360/2) / 2.2 = ~82dp. "Conversar com Mentor" at 2.0x labelMedium (~14pt * 2 = 28sp) wraps to 2 lines ~56dp + padding (16*2) = 88dp → EXCEEDS 82dp tile → overflow.
    2. `_SummaryGlassCard` bottom badge Row (line 370–390) uses `Flexible` on bottomValue ✓ but NOT on `bottomLabel` (line 373–378). "Última interação:" at 2.0x will force the label to take its full width, potentially clipping the value.
    3. Header Column title Row (line 328–357): Column with `Text(title...)` and `Text(subtitle...)` has no Expanded/Flexible. The outer `Row(children: [Container(icon), SizedBox, Column(...)])` at line 328 does NOT wrap the inner Column in Expanded → at 2.0x "Chatbot Alpha" + "Assistente Virtual" will overflow right edge of the GlassCard.
  implication: Client home has fixed aspect-ratio grid tiles (will clip labels at 2.0x) AND unwrapped Row-Column headers in summary cards.

- timestamp: 2026-05-07T15:10:00Z
  checked: mobile/lib/shared/widgets/app_offline_banner.dart (complete file, 65 lines)
  found: `Container(padding: symmetric(vertical: 4, horizontal: 16))` with `Row(mainAxisAlignment: center, children: [Icon, SizedBox, Text('Sem conexao', ...)])`. Text has NO Flexible and Row has NO maxLines constraint. `labelSmall` * 2.0x ≈ 22sp text + 14dp icon — horizontal layout: likely OK on phones because string is short (11 chars). Lower risk than others.
  implication: Minor risk — string is short enough that 2.0x still fits ~360dp width, but becomes risky for translated/longer strings. Add Flexible defensively.

- timestamp: 2026-05-07T15:10:00Z
  checked: mobile/lib/shared/widgets/app_empty_state.dart + mobile/lib/shared/widgets/app_error_state.dart
  found: Both use `Center(child: Padding(all: 32, child: Column(mainAxisSize: min, children: [Icon(size:64), SizedBox(16), Text(message, textAlign: center), optional button])))`. Text is NOT wrapped in Flexible, but it's inside a Column (vertical axis) so horizontal overflow is the only risk. Column children without explicit maxWidth can overflow container width. On narrow devices (360dp) minus padding 64 = 296dp, a long Portuguese message at 2.0x (e.g., "Nenhum documento disponivel" ≈ 27 chars) could still fit because bodyLarge * 2.0x ≈ 32sp and Text wraps automatically by default — so these are LOW RISK for horizontal overflow.
  implication: Secondary concern; Column overflow is vertical, but parent scroll contexts (ResponsiveContainer inside RefreshIndicator→SingleChildScrollView) usually handle that. Still, adding `constraints: BoxConstraints(maxWidth: ...)` defensively would help on large screens.

- timestamp: 2026-05-07T15:10:00Z
  checked: Plan 05 verification note + 10-VERIFICATION.md line 122
  found: Phase 10 explicitly flagged "Text Scaling Accessibility" under human_verification. Plan 05 Task 3 acknowledged the risk: "This is a review pass — most layouts already handle scaling via Material 3 theme. Fix only identified overflow risks." → The review pass was not exhaustive; the shells and dashboard grid were not audited.
  implication: This is a KNOWN-RISK phase that shipped without the safety net of a global textScaler clamp. The phase author chose to rely on widget-level Flexible/Expanded, but missed several high-traffic widgets.

## Resolution

root_cause: Two-part root cause (both present, compounding):

  (1) **No global TextScaler clamp in MaterialApp.** `mobile/lib/main.dart:31-38` constructs `MaterialApp.router` without a `builder:` callback that wraps the child in `MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(...).clamp(maxScaleFactor: 1.3)))`. When the OS system font scale reaches 2.0x, the full multiplier flows through to every Text widget unbounded. Industry standard for consumer apps is to clamp at 1.3–1.5x to preserve layouts while still honoring accessibility intent.

  (2) **Fixed-dimension containers with non-Flexible Text in Row/Column layouts.** Multiple widgets assume text size is bounded. Enumerated offenders below.

fix: (to be designed by /gsd-plan-phase --gaps — this is diagnosis only)

verification: (pending fix)

files_changed: []

## Offending Code Sites (Top 10 — prioritized by user-visible impact)

| # | File:Line | Issue | Severity |
|---|-----------|-------|----------|
| 1 | mobile/lib/main.dart:31-38 | MaterialApp.router has no `builder:` with MediaQuery textScaler clamp — OS font scale flows through unbounded | **CRITICAL** (root enabler) |
| 2 | mobile/lib/features/client/screens/client_shell.dart:186 + :241-252 | `Container(height: 80 + bottomPadding)` with inner Text(fontSize: 10, label) lacking `maxLines`/`overflow`/`Flexible` — 5 nav labels ("Notificações", etc.) overflow at 2.0x on phones | **HIGH** (every screen on phone) |
| 3 | mobile/lib/features/staff/screens/staff_shell.dart:186 + :241-252 | Same issue as above for staff shell — "Intervenção", "Documentos", "Recursos" overflow | **HIGH** (every staff screen on phone) |
| 4 | mobile/lib/features/staff/screens/staff_dashboard_screen.dart:93 (`childAspectRatio: 1.3`) + 314-329 (_KpiCard Text widgets) | Fixed-aspect KPI grid cells clip headlineMedium value + labelSmall label at 2.0x | **HIGH** (primary staff landing) |
| 5 | mobile/lib/features/staff/screens/staff_dashboard_screen.dart:144-160 | Insights card header Row wraps "Insights de Eficiência IA" in unwrapped Text (no Flexible/Expanded) — horizontal overflow at 2.0x | **HIGH** |
| 6 | mobile/lib/features/client/screens/client_home_screen.dart:259 (`childAspectRatio: 2.2`) | Quick Actions grid tiles clip 2-line labels ("Conversar com Mentor", "Solicitar documento") at 2.0x | **HIGH** (primary client landing) |
| 7 | mobile/lib/features/client/screens/client_home_screen.dart:328-357 (_SummaryGlassCard header Row/Column) | Inner `Column(children: [Text(title), Text(subtitle)])` not wrapped in `Expanded` — overflows when icon + title + subtitle width exceeds card at 2.0x | **MEDIUM** |
| 8 | mobile/lib/features/client/screens/client_home_screen.dart:373-378 (_SummaryGlassCard bottom Row) | `bottomLabel` Text lacks `Flexible`; only `bottomValue` is wrapped — at 2.0x label pushes value off-screen | **MEDIUM** |
| 9 | mobile/lib/features/staff/screens/staff_dashboard_screen.dart:263-270 (_EnrollmentBanner "Ativo" badge Container) | Trailing badge Container has fixed padding but Text inside is not Flexible; if localization adds a longer label it will overflow — at 2.0x current "Ativo" is short, so LOW in practice but the pattern is wrong | **LOW** |
| 10 | mobile/lib/shared/widgets/app_offline_banner.dart:50-61 | Row with Icon + Text('Sem conexao') — Text not Flexible. Currently short enough to fit, but any translation/longer message breaks at 2.0x | **LOW** |

## Additional Non-Critical Risks (not in top 10 but worth noting in fix plan)

- `_SummaryGlassCard` outer GlassCard uses `width: double.infinity` bottom container (line 361) which is fine, but nested Rows with non-Flexible children repeat the pattern across both summary cards.
- AppBarActions (`mobile/lib/shared/widgets/app_bar_actions.dart`) — verified safe: icon-only IconButtons.
- **47 hardcoded `fontSize:` literals** across feature screens (grep confirmed 2026-05-07T15:12:00Z). While Flutter's default behavior still applies `textScaler` to these, the pattern bypasses the theme's textTheme and makes it harder to reason about sizes. Many are small chips/badges (fontSize 10–12) inside fixed-dim containers — high overflow risk at 2.0x.
- The 7 other main screens were not fully read but grep confirms the same anti-patterns:
  - `staff_schedule_screen.dart:278` — fontSize: 10 badge
  - `staff_resources_screen.dart:367` — fontSize: 10 badge
  - `staff_intervention_screen.dart:209, 375` — fontSize: 10 chip
  - `staff_documents_screen.dart:287` — fontSize: 10 badge
  - `client_documents_screen.dart:297` — fontSize: 10 badge
  - `client_notifications_screen.dart:169, 181` — fontSize: 10/12 badges
  - `client_chat_screen.dart:445, 535, 585` — fontSize: 10 chips
  - `client_resources_screen.dart:270, 482, 537` — fontSize: 10/11 chips
- These chip/badge patterns will likely overflow their parent Container/Chip bounds at 2.0x. A systematic audit after the global clamp fix should grep these sites and add `maxLines: 1, overflow: TextOverflow.ellipsis` defensively.

## Recommended Fix Direction (for /gsd-plan-phase --gaps)

**Fix #1 (structural, 80% of the problem):** Add global textScaler clamp in `main.dart`:

```dart
return MaterialApp.router(
  // ...existing props...
  builder: (context, child) {
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(
        textScaler: mq.textScaler.clamp(maxScaleFactor: 1.3),
      ),
      child: child!,
    );
  },
);
```

This single change bounds accessibility scaling at 1.3x globally. Most of the layouts the team already audited work at 1.3x (that was the implicit design target). Consumer apps (WhatsApp, Instagram, etc.) clamp at 1.2–1.5x.

**Fix #2 (targeted, 20% polish):** After the clamp is in place, still fix the shells' bottom-nav Text to use `maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center` and wrap the KPI card / quick-action grid Text widgets in `FittedBox(fit: BoxFit.scaleDown)` or add `maxLines + overflow: ellipsis`. These make the app resilient even if the clamp is later relaxed.

**Fix #3 (grid aspect ratios):** Change `GridView.count(childAspectRatio: 1.3|2.2)` in dashboard KPI cards and client quick-actions to `MediaQuery.textScalerOf(context).scale(...)`-aware values, OR switch to `Wrap` layouts that grow vertically instead of clipping.
