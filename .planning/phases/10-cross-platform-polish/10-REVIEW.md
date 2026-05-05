---
phase: 10-cross-platform-polish
reviewed: 2026-05-05T12:00:00Z
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
findings:
  critical: 0
  warning: 5
  info: 5
  total: 10
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

_Reviewed: 2026-05-05T12:00:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
