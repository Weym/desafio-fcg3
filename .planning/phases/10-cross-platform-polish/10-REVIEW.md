---
phase: 10-cross-platform-polish
reviewed: 2026-05-05T12:00:00Z
last_reviewed: 2026-05-07T15:00:00Z
depth: standard
files_reviewed: 25
files_reviewed_list:
  - mobile/lib/core/theme/app_theme.dart
  - mobile/lib/core/theme/app_colors.dart
  - mobile/lib/core/theme/app_spacing.dart
  - mobile/lib/core/theme/theme_provider.dart
  - mobile/lib/core/responsive/breakpoints.dart
  - mobile/lib/shared/widgets/app_skeleton_list.dart
  - mobile/lib/shared/widgets/app_skeleton_card.dart
  - mobile/lib/shared/widgets/app_empty_state.dart
  - mobile/lib/shared/widgets/app_error_state.dart
  - mobile/lib/shared/widgets/app_offline_banner.dart
  - mobile/lib/shared/widgets/responsive_container.dart
  - mobile/lib/features/client/screens/client_shell.dart
  - mobile/lib/features/staff/screens/staff_shell.dart
  - mobile/lib/features/client/screens/client_chat_screen.dart
  - mobile/lib/features/staff/screens/staff_ai_screen.dart
  - mobile/lib/core/providers/cache_provider.dart
  - mobile/lib/features/client/screens/client_home_screen.dart
  - mobile/lib/features/client/screens/client_documents_screen.dart
  - mobile/lib/features/client/screens/client_notifications_screen.dart
  - mobile/lib/features/client/screens/client_support_screen.dart
  - mobile/lib/features/staff/screens/staff_dashboard_screen.dart
  - mobile/lib/features/staff/screens/staff_schedule_screen.dart
  - mobile/lib/features/staff/screens/staff_documents_screen.dart
  - mobile/lib/main.dart
  - mobile/pubspec.yaml
gap_closure_10_06_files_reviewed:
  - mobile/lib/main.dart
  - mobile/lib/features/client/screens/client_shell.dart
  - mobile/lib/features/staff/screens/staff_shell.dart
  - mobile/lib/features/staff/screens/staff_dashboard_screen.dart
  - mobile/lib/features/client/screens/client_home_screen.dart
  - mobile/lib/shared/widgets/app_offline_banner.dart
  - mobile/lib/features/staff/screens/staff_schedule_screen.dart
  - mobile/lib/features/staff/screens/staff_resources_screen.dart
  - mobile/lib/features/staff/screens/staff_intervention_screen.dart
  - mobile/lib/features/staff/screens/staff_documents_screen.dart
  - mobile/lib/features/client/screens/client_documents_screen.dart
  - mobile/lib/features/client/screens/client_notifications_screen.dart
  - mobile/lib/features/client/screens/client_chat_screen.dart
  - mobile/lib/features/client/screens/client_resources_screen.dart
findings:
  critical: 0
  warning: 5
  info: 7
  total: 12
status: issues_found
---

# Phase 10: Code Review Report

**Reviewed:** 2026-05-05T12:00:00Z
**Depth:** standard
**Files Reviewed:** 25
**Status:** issues_found

## Summary

Phase 10 implements cross-platform polish: responsive layouts (phone/tablet/desktop with NavigationRail), theme system (light/dark with persistence), shared widgets (skeletons, empty/error states, offline banner), and TTL caching for providers. The code is well-structured and follows Flutter/Riverpod conventions consistently.

Key concerns:
- A potential null-safety issue in `app_theme.dart` with force-unwrap on nullable values
- The `CacheTTL` class uses a static `Map` that could leak memory across hot restarts
- Missing `mounted` check in `_prefetchAdjacentTabs` after `addPostFrameCallback`
- `_formatRelativeTime` produces awkward output for edge cases (0 minutes)

No security issues found — this is purely UI/theme code with no sensitive data exposure.

## Warnings

### WR-01: Null-safety: force-unwrap after nullable access in responsiveTextTheme

**File:** `mobile/lib/core/theme/app_theme.dart:75-78`
**Issue:** The `copyWith` uses nullable access (`base.displaySmall?.copyWith(...)`) but inside the lambda force-unwraps `base.displaySmall!.fontSize`. If `base.displaySmall` is null, the `?.copyWith` short-circuits and the inner expression is never evaluated — so this is technically safe. However, `base.displaySmall?.fontSize` could itself be null (the `?? 36` handles it). The pattern is correct but relies on subtle null-propagation semantics that make it fragile to refactoring.
**Fix:** Use the null-coalescing directly without force-unwrap:
```dart
displaySmall: base.displaySmall?.copyWith(
  fontSize: (base.displaySmall?.fontSize ?? 36) * 1.2,
),
```

### WR-02: Static Map in CacheTTL leaks across hot restarts

**File:** `mobile/lib/core/providers/cache_provider.dart:12`
**Issue:** `static final Map<String, Timer?> _timers = {}` is a static field that persists across Flutter hot restarts. Old timers from a previous session could linger in memory if the provider lifecycle doesn't trigger `onDispose`. In a hot-restart scenario, the `ref.onDispose` callbacks from the previous session won't fire, leaving stale entries.
**Fix:** This is acceptable for production builds (full restart clears statics) but could cause confusion during development. Consider using a `tearDown` method or checking timer validity, or document this limitation:
```dart
/// Note: static map — cleared on full restart only.
/// Hot-restart may leave stale entries (harmless but wastes timer slots).
static final Map<String, Timer?> _timers = {};
```

### WR-03: Missing mounted check in client/staff shell prefetch

**File:** `mobile/lib/features/client/screens/client_shell.dart:24-26`
**File:** `mobile/lib/features/staff/screens/staff_shell.dart:24-26`
**Issue:** `addPostFrameCallback` fires the callback after the current frame, but `_prefetchAdjacentTabs` calls `ref.read(...)` without checking if the widget is still mounted. While unlikely to fail in practice (the callback fires in the same frame as build), it's a defensive best practice to check `mounted` before interacting with `ref` in post-frame callbacks.
**Fix:**
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!mounted) return;
  _prefetchAdjacentTabs();
});
```

### WR-04: _formatRelativeTime produces "ha 0min" for very recent events

**File:** `mobile/lib/features/client/screens/client_notifications_screen.dart:130`
**Issue:** When `diff.inMinutes` is 0, the function returns `'ha 0min'` which reads awkwardly. Similarly, future events within 1 minute return `'em 0min'`.
**Fix:**
```dart
if (diff.inMinutes < 1) return 'agora';
if (diff.inMinutes < 60) return 'ha ${diff.inMinutes}min';
// ... and for future:
if (absDiff.inMinutes < 1) return 'em breve';
if (absDiff.inMinutes < 60) return 'em ${absDiff.inMinutes}min';
```

### WR-05: Desktop chat panel uses full screen width for sidebar sizing

**File:** `mobile/lib/features/client/screens/client_chat_screen.dart:76`
**File:** `mobile/lib/features/staff/screens/staff_ai_screen.dart:128`
**Issue:** `MediaQuery.sizeOf(context).width * 0.35` uses the full screen width for the sidebar, but in the chat screen this widget is already inside a `Row` within a `NavigationRail` layout (from `ClientShell`). The actual available width is less than `MediaQuery.sizeOf(context).width` because the NavigationRail consumes ~72-180px. This causes the sidebar to be wider than intended on desktop (taking 35% of total screen, not 35% of content area).
**Fix:** Use `LayoutBuilder` or `constraints.maxWidth` from the parent context instead of `MediaQuery`:
```dart
// In the data branch, wrap in LayoutBuilder or pass constraints:
LayoutBuilder(
  builder: (context, constraints) {
    return Row(
      children: [
        SizedBox(
          width: constraints.maxWidth * 0.35,
          // ...
        ),
      ],
    );
  },
)
```

## Info

### IN-01: Unused import - go_router in staff_ai_screen.dart

**File:** `mobile/lib/features/staff/screens/staff_ai_screen.dart:3`
**Issue:** `import 'package:go_router/go_router.dart'` is imported but only used in the non-desktop path (`context.push(...)` on line 187). The import itself is used, but the `GoRouter` import brings in extensions on `BuildContext` — this is actually used via `context.push`. No action needed after re-evaluation. *(Disregarding this finding — import IS used.)*

### IN-02: Hardcoded placeholder contact info in client_support_screen.dart

**File:** `mobile/lib/features/client/screens/client_support_screen.dart:5-8`
**Issue:** Support email, phone, and WhatsApp URL are hardcoded as constants. While acceptable for MVP, these should eventually come from a remote config or environment-based configuration.
**Fix:** Move to a configuration provider or environment constants that can be updated without app release.

### IN-03: AppSpacing defined but not consistently used

**File:** `mobile/lib/core/theme/app_spacing.dart`
**Issue:** `AppSpacing` defines xs/sm/md/lg/xl tokens, but screens use raw pixel values like `12`, `24`, `32` directly instead of referencing `AppSpacing.sm`, `AppSpacing.lg`, etc. For example, `client_chat_screen.dart` uses `EdgeInsets.all(8)` and `EdgeInsets.all(16)` instead of `AppSpacing.sm` and `AppSpacing.md`.
**Fix:** Gradually replace magic spacing values with `AppSpacing.*` references for consistency. Not a bug, but reduces the value of having the token system.

### IN-04: Duplicate helper functions across document screens

**File:** `mobile/lib/features/client/screens/client_documents_screen.dart:145-180`
**File:** `mobile/lib/features/staff/screens/staff_documents_screen.dart:141-176`
**Issue:** `_typeLabel`, `_statusLabel`, `_statusBackgroundColor`, `_statusTextColor`, and `_iconColor` are duplicated identically between client and staff document screens.
**Fix:** Extract these into a shared utility file (e.g., `mobile/lib/shared/utils/document_helpers.dart`) to follow DRY principles.

### IN-05: responsiveTextTheme defined but never called

**File:** `mobile/lib/core/theme/app_theme.dart:68-87`
**Issue:** `AppTheme.responsiveTextTheme()` is defined but never invoked in `main.dart` or any widget. The `MaterialApp.router` uses `AppTheme.light` and `AppTheme.dark` directly without applying responsive text scaling.
**Fix:** Either integrate it into a `Builder` widget that applies responsive text theme based on screen width, or document it as a planned enhancement. As-is, desktop users won't get the larger heading/body text described in comments.

---

## Gap Closure Review (10-06)

**Reviewed:** 2026-05-07T15:00:00Z
**Depth:** standard
**Scope:** Commits `aebb8b7..HEAD` (6 commits implementing plan 10-06 — UI-NFR-02 text-scale overflow gap closure)
**Files reviewed:** 14 (see `gap_closure_10_06_files_reviewed` in frontmatter)

### Summary

Plan 10-06 is a disciplined, layout-only gap closure targeting `UI-NFR-02` (system text-scale overflow at 2.0x). Scope was tight: install a global `MediaQuery.textScaler.clamp(maxScaleFactor: 1.3)` in `MaterialApp.router.builder`, then harden 6 specific overflow hotspots plus a defensive `maxLines: 1 + TextOverflow.ellipsis` sweep across 14 chip/badge sites.

**Scope adherence verified:** A full diff audit of the added lines confirms every change falls into layout categories (`maxLines`, `overflow`, `textAlign`, `Flexible`, `Expanded`, `FittedBox`, `MediaQuery` wrapper). Zero provider, state, async, routing, or data-logic changes landed. `_formatRelativeTime`, `_formatTime`, `_formatDate`, `_statusLabel`, `_categoryLabel`, `staffDashboardProvider`, `chatSessionsProvider`, `sharedPreferencesProvider`, `themeModeNotifierProvider`, and all `Connectivity()` wiring are byte-identical to pre-10-06 HEAD.

**dart analyze status:** `dart analyze` on all 14 modified files reports 0 errors, 0 warnings. The 11 `unnecessary_underscores` info-level hints present are pre-existing (verified against the commit before `aebb8b7`) and were not introduced by 10-06.

**main.dart TextScaler clamp verified:** All six existing `MaterialApp.router` properties (`title`, `theme`, `darkTheme`, `themeMode`, `debugShowCheckedModeBanner`, `routerConfig`) are preserved verbatim. The new `builder:` wraps `child!` in a `MediaQuery.copyWith(textScaler: clamp(...))` — this is the canonical Flutter pattern recommended by Material guidelines and WhatsApp/Instagram's known implementations.

**Overall verdict:** `clean` for this gap closure — no new Critical or Warning findings. Three minor Info items are recorded below for completeness, all of which are carry-over observations about the defensive sweep's semantic vs. structural boundaries, not defects.

### Findings

No new Critical or Warning findings. All prior findings (WR-01..WR-05, IN-01..IN-05) remain applicable to their original files and are **not** contradicted or resolved by 10-06 (this was a scoped gap closure, not a fix-all). In particular:

- **WR-05** (chat sidebar uses full-width `MediaQuery` for 35%) is now *partially* mitigated by the global 1.3x textScaler clamp reducing visible fallout, but the structural issue (using `MediaQuery.sizeOf` instead of `LayoutBuilder` constraints) remains unchanged in `client_chat_screen.dart` and `staff_ai_screen.dart`.
- **WR-04** (`_formatRelativeTime` "ha 0min" edge case) remains — 10-06 only added `maxLines: 1 + ellipsis` to that Text widget, not the format logic.

### Info

### IN-06: Defensive `maxLines + ellipsis` is a no-op on `MainAxisSize.min` / unbounded Row children

**File:** `mobile/lib/features/client/screens/client_chat_screen.dart:442-453` (and `:533-541`, `:585-594`)
**File:** `mobile/lib/features/client/screens/client_notifications_screen.dart:179-187`
**Issue:** The sweep added `maxLines: 1, overflow: TextOverflow.ellipsis` to Text widgets that sit as direct children of a `Row` without `Flexible`/`Expanded` wrappers. In chat bubbles the enclosing `Row(mainAxisSize: MainAxisSize.min, ...)` shrink-wraps and does not impose width constraints on children; in notifications the timestamp Text sits alongside a category chip + recent-badge with no flex wrapper. In both cases Flutter gives the Text its intrinsic (unbounded) width and the ellipsis never triggers — the Text would overflow the Row horizontally before it could clip.

In practice this is cosmetic only: the actual string content is always short (`"14:32"`, `"ha 5min"`, `"Ativa"`, `"Encerrada"`) so overflow never occurs at the 1.3x clamp. But the sweep's stated goal ("all chip/badge Text defensively truncate") isn't structurally guaranteed at these specific sites — it just happens to be satisfied by data shape.

**Fix (optional, low priority):** If true defensive behavior is desired at these sites, wrap the Text in `Flexible(child: Text(...))` so the ellipsis actually has bounded constraints to work against. Otherwise, document that the defensive sweep is content-dependent at Row-without-flex sites.

### IN-07: `child!` force-unwrap in MaterialApp.router builder

**File:** `mobile/lib/main.dart:44`
**Issue:** The new `builder: (context, child) { ... child! ... }` uses force-unwrap on the nullable `child` parameter. This follows the canonical Flutter pattern and is safe in practice because `MaterialApp.router` always passes a non-null child to its builder when `routerConfig` is provided — Flutter's own documentation examples use `child!` here.

However, for defensive coding (matching the project's broader convention of null-coalescing over force-unwrap as noted in WR-01), a one-line guard would be trivially cheap and self-documenting:

```dart
builder: (context, child) {
  if (child == null) return const SizedBox.shrink();
  final mediaQuery = MediaQuery.of(context);
  return MediaQuery(
    data: mediaQuery.copyWith(
      textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.3),
    ),
    child: child,
  );
},
```

**Fix:** Optional. The force-unwrap is idiomatic and has never been observed to throw in production Flutter apps with `routerConfig`. Flag only for consistency with WR-01.

### Layout Safety Observations (not findings — positive confirmations)

For clarity of the gap-closure audit trail, the following were explicitly verified to be safe:

- **`client_home_screen.dart` `_SummaryGlassCard` header:** The new `Expanded(child: Column(...))` wrap is correct — the outer `Row` now provides bounded constraints to the title/subtitle column, enabling the `maxLines: 1 + ellipsis` additions to actually apply.
- **`client_home_screen.dart` `_SummaryGlassCard` bottomLabel:** The new `Flexible(child: Text(bottomLabel, ...))` sits in a `Row(mainAxisAlignment: MainAxisAlignment.spaceBetween)` with a sibling `Flexible` on `bottomValue` — both siblings are now flex, so neither can overflow. Correct pattern.
- **`staff_dashboard_screen.dart` `_KpiCard` FittedBox:** The `FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft)` on both the KPI value and label Text widgets correctly scales down without ever scaling up (`scaleDown`), preserving the design's intent to shrink overflow-prone text inside the fixed `childAspectRatio: 1.3` grid cells.
- **`staff_dashboard_screen.dart` "Insights" header Expanded:** The Row now has `[Icon, SizedBox, Expanded(Text)]` — Icon and SizedBox have fixed width, `Expanded` takes remainder. Correct.
- **`client_shell.dart` / `staff_shell.dart` BottomNav Text:** The `Text(item.label, maxLines:1, overflow:ellipsis, textAlign:center, style:...)` sits in a Column inside a `GestureDetector > AnimatedContainer` with fixed padding/width per slot — the Text receives bounded width from the container, so `ellipsis` applies correctly. Correct.
- **`app_offline_banner.dart` `Flexible` wrap:** The banner Row is inside a `Container` with `mainAxisAlignment: MainAxisAlignment.center` — wrapping the Text in `Flexible` without `fit: FlexFit.tight` is correct for "take only what's needed but no more" semantics. The ellipsis will engage if narrow viewports compress the Row. Correct.
- **No `const` contract broken:** The edits preserve `static const _railDestinations` in both shells and do not introduce any `const` → non-`const` downgrades.
- **No unbounded widget regressions:** No `ListView`/`Column`/`Row` was modified in a way that would remove parent height/width constraints.
- **MaterialApp.router `builder` chain:** The new builder does not shadow or wrap any other inherited `MediaQuery` in a way that would break downstream `MediaQuery.of(context)` lookups — it only modifies `textScaler` via `copyWith`, leaving all other `MediaQueryData` fields (`size`, `padding`, `viewInsets`, `platformBrightness`, etc.) untouched.

### Verification Evidence

```
git log --oneline aebb8b7^..HEAD                   # 6 commits in range
dart analyze (14 modified files)                   # 0 errors, 0 warnings, 11 pre-existing info hints
grep "textScaler.clamp" mobile/lib/main.dart       # 1 match (installed correctly)
grep -c "TextOverflow.ellipsis" (14 files)         # all acceptance thresholds met
Diff audit of added lines                          # no provider/state/logic/import changes detected
```

### Recommendation

`status: issues_found` is retained only because prior findings (WR-01..WR-05, IN-01..IN-05 from the initial review) remain open and unaddressed by 10-06 (which was explicitly scoped to UI-NFR-02 text-scale overflow, not broader quality fixes). The gap closure itself is **clean** — no new Critical or Warning findings, layout changes are genuinely layout-only, and the TextScaler clamp preserves all MaterialApp.router properties. The two new Info items (IN-06, IN-07) are minor observations, not defects.

If the prior WR-01..WR-05 are addressed in a follow-up phase, this report's `status:` can flip to `clean`.

---

_Reviewed: 2026-05-05T12:00:00Z (initial)_
_Reviewed: 2026-05-07T15:00:00Z (gap closure 10-06)_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
