# Phase 10: Cross-Platform Polish - Context

**Gathered:** 2026-05-05
**Status:** Ready for planning

<domain>
## Phase Boundary

The Flutter app renders correctly and is usable on smartphones (360dp), tablets (768dp), and web (1280dp+). Navigation adapts to screen size, content layout responds to available width, loading/error/empty states are consistent and polished, data synchronization achieves <2s perceived latency for cached data, and accessibility meets WCAG AA baseline. This phase polishes existing screens from Phase 8 and 9 — no new features or screens.

</domain>

<decisions>
## Implementation Decisions

### Responsive Navigation

- **D-01:** Three-tier adaptive navigation based on screen width breakpoints:
  - Phone (<600dp): BottomNavigationBar (current behavior, unchanged)
  - Tablet (600–1024dp): NavigationRail compact (icons only, ~72dp width)
  - Desktop (>=1024dp): NavigationRail extended (icons + labels, ~180dp width)
- **D-02:** Breakpoints defined as constants in a central file (`lib/core/responsive/breakpoints.dart` or similar).
- **D-03:** Navigation shell (ClientShell, StaffShell) uses LayoutBuilder to switch between BottomNav and NavigationRail based on width.

### Content Layout Strategy

- **D-04:** Hybrid layout approach:
  - Most screens: max-width 720dp container, centered on large screens
  - List+detail screens: master-detail split view on desktop (>=1024dp)
- **D-05:** Master-detail screens (split view on desktop only):
  - Chat (session list | message detail)
  - AI Data/Insights (session list | chat detail)
- **D-06:** All other screens (Dashboard, Documents, Schedule, Notifications, Support) use max-width container.
- **D-07:** Grid adaptation for KPI cards: 2 columns phone, 3 columns tablet, 4 columns desktop.

### Loading States & UX Feedback

- **D-08:** Skeleton/shimmer screens on first data load (when no cached data exists). Replaces current CircularProgressIndicator for initial loads.
- **D-09:** On pull-to-refresh (when cached data visible): LinearProgressIndicator at the top of the screen while data stays visible. No skeleton replacement during refresh.
- **D-10:** Transition from skeleton to real content: instantaneous (no fade animation).
- **D-11:** Shared reusable widgets for all UX states:
  - `AppSkeletonList` / `AppSkeletonCard` — configurable skeleton placeholders
  - `AppEmptyState` — icon + message + optional action button
  - `AppErrorState` — icon + message + retry button
  Located in `lib/shared/widgets/` or `lib/core/widgets/`.

### Data Cache & Synchronization

- **D-12:** Riverpod `keepAlive` + TTL-based invalidation. Cached data valid for 5 minutes across all providers uniformly.
- **D-13:** After TTL expires, next access triggers refetch. During TTL window, data serves from memory instantly.
- **D-14:** Prefetch adjacent tabs in background after initial tab loads. When user navigates to next tab, data is already available (or nearly ready).
- **D-15:** Offline behavior: show cached data in memory (if available) + persistent banner "Sem conexao" at top. Action buttons disabled. No local persistence (SQLite/Hive) — cache is memory-only.

### Dark Mode

- **D-16:** Full dark mode support using Material 3 ColorScheme.fromSeed with `brightness: Brightness.dark`.
- **D-17:** Theme toggle accessible in AppBar or settings area. User choice persisted in SharedPreferences.
- **D-18:** Default follows system OS preference (ThemeMode.system). Manual override takes precedence when set.

### Accessibility (a11y)

- **D-19:** WCAG AA baseline compliance:
  - Contrast ratio: 4.5:1 for text, 3:1 for UI components
  - Minimum touch targets: 48dp
  - Text scales with system `textScaleFactor` up to 2.0x without layout overflow
- **D-20:** No full Semantics labels required (screen reader support deferred). Focus traversal for keyboard/web is agent's discretion.

### Animations & Transitions

- **D-21:** Material 3 default transitions only (shared axis, fade through). No custom hero animations or complex page transitions. GoRouter default animations retained.
- **D-22:** Micro-interactions: Material ripple/splash defaults. No custom animated feedback.

### Spacing & Responsive Typography

- **D-23:** Central spacing tokens file with constants: xs=4, sm=8, md=16, lg=24, xl=32 (dp).
- **D-24:** Adaptive typography by breakpoint:
  - Headings (displayLarge, headlineMedium) scale ~20% larger on desktop (>=1024dp)
  - Body text maintains same size; line-height increases on wider screens for readability
  - Phone and tablet use standard Material 3 TextTheme sizes
- **D-25:** All spacing and typography definitions centralized in `lib/core/theme/` alongside existing `app_theme.dart`.

### Agent's Discretion

- Exact shimmer animation style/color (gray placeholder, pulsing opacity, etc.)
- Split ratio for master-detail (50/50, 40/60, etc.)
- Exact AppBar location of dark mode toggle icon
- Specific spacing values per screen (using the token system)
- RepaintBoundary placement for performance optimization
- Whether to extract breakpoint-aware wrapper as a utility widget
- Pagination for very long lists (optional optimization)

</decisions>

<canonical_refs>

## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Flutter Architecture (Foundation)

- `.planning/phases/07-flutter-scaffold-auth/07-CONTEXT.md` — Riverpod, GoRouter, ShellRoute, feature-first folders, Dio, json_serializable. All foundation decisions.
- `docs/app.md` — Flutter app features spec with screen descriptions and API integration patterns.

### Current Screen Implementations (to be polished)

- `.planning/phases/08-client-interface/08-CONTEXT.md` — Client screen decisions: dashboard cards, chat bubbles, document filters, notifications derived, support static.
- `.planning/phases/09-staff-interface/09-CONTEXT.md` — Staff screen decisions: KPI grid, schedule management, AI insights, document management.

### API Contract

- `docs/api.md` — All REST endpoints consumed by the app. Needed to understand data shapes for skeleton placeholders and caching logic.

### Architecture

- `docs/architecture.md` — System topology, how Flutter connects to services at :8000.

</canonical_refs>

<code_context>

## Existing Code Insights

### Reusable Assets

- **ClientShell/StaffShell** (`mobile/lib/features/client/screens/client_shell.dart`, `staff_shell.dart`): Current BottomNavigationBar shells — must be refactored to adaptive navigation.
- **AppTheme** (`mobile/lib/core/theme/app_theme.dart`): Material 3 theme, 33 lines — needs dark variant and responsive typography additions.
- **AppColors** (`mobile/lib/core/theme/app_colors.dart`): Static color constants — needs review for WCAG AA contrast on both light and dark.
- **DioClient** (`mobile/lib/core/network/dio_client.dart`): HTTP client — integration point for offline detection and error handling.
- **All screen files** (~18 screens): Each has ad-hoc loading/error/empty states that will be replaced with shared widgets.

### Established Patterns

- **Riverpod AsyncValue.when**: All screens use `when(loading: ..., error: ..., data: ...)` — skeleton/error/empty widgets plug into this pattern directly.
- **RefreshIndicator + ref.invalidate()**: Pull-to-refresh pattern on all list screens — needs LinearProgressIndicator overlay added.
- **keepAlive providers**: Service providers already use keepAlive — TTL logic layers on top of existing infrastructure.
- **MediaQuery.viewInsets**: Used in 4 bottom sheets for keyboard handling — pattern exists.

### Integration Points

- **Navigation shells**: ClientShell and StaffShell are the primary targets for responsive nav refactoring.
- **Every screen file**: Will import shared widgets (AppSkeleton, AppEmptyState, AppErrorState).
- **app_theme.dart**: Central point for dark mode, responsive typography, and spacing tokens.
- **pubspec.yaml**: Will need `shimmer` or `skeletonizer` package added.

</code_context>

<specifics>
## Specific Ideas

- Navigation transitions between BottomNav and NavigationRail should be seamless — same destinations, same routes, just different shell widget.
- Master-detail for Chat and AI means the session list stays visible while reading messages — no "back" navigation needed on desktop.
- Skeleton screens should mirror the actual screen layout (card shapes, list items) — not generic placeholders.
- The 5-minute TTL is uniform to keep implementation simple; prefetch makes the cache feel faster by pre-warming adjacent tabs.
- Dark mode uses Material 3's `ColorScheme.fromSeed` dark variant — consistent with existing light theme seed color.
- Offline banner should be non-intrusive — thin strip at the top, not a full-screen blocker.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

_Phase: 10-cross-platform-polish_
_Context gathered: 2026-05-05_
