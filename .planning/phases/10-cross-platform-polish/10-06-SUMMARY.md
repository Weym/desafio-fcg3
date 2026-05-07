---
phase: 10-cross-platform-polish
plan: 06
subsystem: ui
tags: [flutter, accessibility, text-scaling, overflow, material3, layout]

# Dependency graph
requires:
  - phase: 10-cross-platform-polish
    provides: Phase 10 Plans 01-05 (responsive navigation, shared widgets, dark mode, accessibility review)
provides:
  - Global MediaQuery.textScaler clamp at 1.3x in MaterialApp.router (closes UI-NFR-02)
  - BottomNavigationBar labels truncate with ellipsis in both client + staff shells
  - Staff dashboard KPI cards shrink via FittedBox (no clipping at clamped scale)
  - Client home summary card header + bottomLabel + Quick Actions label hardened against overflow
  - AppOfflineBanner 'Sem conexao' Text Flexible-wrapped
  - 14 chip/badge Text sites across 8 feature screens defensively patched with maxLines:1 + ellipsis
affects: [future-translations, future-accessibility-work, future-phases-touching-text-layout]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Global textScaler clamp in MaterialApp.router builder (industry-standard consumer-app pattern)"
    - "Defensive maxLines:1 + TextOverflow.ellipsis on hardcoded-fontSize chip/badge Text widgets"
    - "FittedBox(fit: BoxFit.scaleDown) on Text in fixed-aspect grid cells to allow shrinking"
    - "Expanded/Flexible wrappers on Row-nested Text + Column-nested Text to prevent horizontal overflow"

key-files:
  created: []
  modified:
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

key-decisions:
  - "Clamp textScaler at maxScaleFactor:1.3 globally (industry-standard consumer-app clamp per WhatsApp/Instagram) rather than relaxing D-19's 2.0x target; closes ~80% of visible UAT breakage"
  - "Leave NavigationRail _railDestinations as static const — Material 3 already provides overflow safety on rail labels and keeping the list const preserves Widget-tree perf"
  - "Preserve GridView.count childAspectRatio:1.3 (staff dashboard) and 2.2 (client home Quick Actions); FittedBox / maxLines+ellipsis are the agreed mitigations — no aspect-ratio refactor"
  - "Defensive sweep on 14 chip/badge sites with hardcoded fontSize 10-12 — adds maxLines:1 + ellipsis only, no structural Flexible wraps (out of scope)"

patterns-established:
  - "Global textScaler clamp pattern — always wrap MaterialApp.router child in MediaQuery with textScaler.clamp(maxScaleFactor: 1.3)"
  - "Chip/badge Text widgets with hardcoded fontSize 10-12 must carry maxLines:1 + TextOverflow.ellipsis as a default posture"

requirements-completed: [UI-NFR-02]

# Metrics
duration: 18 min
completed: 2026-05-07
---

# Phase 10 Plan 06: Text-scale overflow hardening (gap closure) Summary

**Global 1.3x textScaler clamp in MaterialApp.router + targeted Flexible/Expanded/FittedBox/maxLines+ellipsis sweep across 14 files closes the Phase 10 UAT Test 4 gap (UI-NFR-02).**

## Performance

- **Duration:** ~18 min
- **Started:** 2026-05-07T19:45:00Z (approximate)
- **Completed:** 2026-05-07T20:03:00Z (approximate)
- **Tasks:** 6
- **Files modified:** 14

## Accomplishments

- Installed the structural fix (~80% of breakage): a single MediaQuery.textScaler clamp at 1.3x in MaterialApp.router builder — every Text in the app is now bounded, regardless of OS system font scale.
- Hardened the two most-visible layout hotspots: BottomNavigationBar labels in both shells now truncate with ellipsis instead of overflowing their fixed ~72dp slots.
- Fixed the staff dashboard grid + header: KPI value+label Text shrink via FittedBox(scaleDown) inside the fixed-aspect (1.3) grid cell; Insights card header Text is Expanded with maxLines:2 + ellipsis.
- Fixed the client home summary cards + Quick Actions: header Column wrapped in Expanded with maxLines:1 + ellipsis; bottomLabel wrapped in Flexible + ellipsis; Quick Actions label Text defends with maxLines:2 + ellipsis inside the existing Expanded wrapper.
- Defensively patched 14 chip/badge/timestamp Text widgets with hardcoded fontSize 10-12 across 8 feature screens — pure layout-safety sweep, no fontSize/color/structural changes.
- Confirmed zero new errors/warnings across the entire mobile/lib/ tree (`dart analyze lib/` reports 0 errors + 0 warnings; 13 pre-existing info-level lint notices unchanged).

## Task Commits

Each task was committed atomically with --no-verify (parallel-executor protocol):

1. **Task 1: Install global TextScaler clamp in MaterialApp.router** — `aebb8b7` (feat)
2. **Task 2: Harden BottomNav labels in client + staff shells** — `6b4faa9` (feat)
3. **Task 3: FittedBox on KPI cards + Expanded on Insights header** — `ae9699f` (feat)
4. **Task 4: _SummaryGlassCard + Quick Actions label hardening** — `602901a` (feat)
5. **Task 5: Flexible wrap on AppOfflineBanner 'Sem conexao' Text** — `6dc5149` (feat)
6. **Task 6: Defensive maxLines+ellipsis sweep on 14 chip/badge sites** — `7852627` (feat)

## Files Created/Modified

### Core / shared (3 files)
- `mobile/lib/main.dart` — Added `builder:` callback to `MaterialApp.router` that wraps child in `MediaQuery` with `textScaler.clamp(maxScaleFactor: 1.3)`. Single source of truth for all text scaling in the app.
- `mobile/lib/shared/widgets/app_offline_banner.dart` — Wrapped `Text('Sem conexao', ...)` in `Flexible` + `maxLines: 1` + `TextOverflow.ellipsis`.
- `mobile/lib/features/client/screens/client_shell.dart` — Bottom nav label Text: added `maxLines: 1`, `overflow: TextOverflow.ellipsis`, `textAlign: TextAlign.center`.
- `mobile/lib/features/staff/screens/staff_shell.dart` — Same pattern as client_shell.

### Screen-level fixes (2 files)
- `mobile/lib/features/staff/screens/staff_dashboard_screen.dart` — `_KpiCard`: wrapped value + label Text in `FittedBox(fit: BoxFit.scaleDown)`. Insights card header Row: wrapped "Insights de Eficiência IA" Text in `Expanded` with `maxLines: 2` + `ellipsis`.
- `mobile/lib/features/client/screens/client_home_screen.dart` — `_SummaryGlassCard` header Column wrapped in `Expanded` with `maxLines: 1` + `ellipsis` on title + subtitle. `bottomLabel` Text wrapped in `Flexible` + `ellipsis` (sibling to existing Flexible on bottomValue). `_buildQuickActions`: Quick Actions label Text now carries `maxLines: 2` + `ellipsis` inside the existing `Expanded` wrapper.

### Defensive chip/badge sweep (8 files)
- `staff_schedule_screen.dart` (status badge, line ~275)
- `staff_resources_screen.dart` ('Requer Autorização' badge, line ~364)
- `staff_intervention_screen.dart` (displayIdentifier line ~206 + `_StatusBadge` label line ~372)
- `staff_documents_screen.dart` (status badge, line ~284)
- `client_documents_screen.dart` (status badge, line ~294)
- `client_notifications_screen.dart` (category label ~166 + relative time ~177)
- `client_chat_screen.dart` (message timestamp ~442, session date ~532, Ativa/Encerrada chip ~582)
- `client_resources_screen.dart` ('Requer Autorização' ~267, 'Cancelar' ~479, status badge ~534)

All 14 sites received only `maxLines: 1,` + `overflow: TextOverflow.ellipsis,` added as sibling arguments to the existing `style:` block. No fontSize, fontWeight, color, or structural changes.

## Verification Results

Plan-level automated checks (all passed):

- `grep -q "textScaler.clamp(maxScaleFactor: 1.3)" mobile/lib/main.dart` ✓
- `grep -q "TextOverflow.ellipsis" mobile/lib/features/client/screens/client_shell.dart` ✓
- `grep -q "TextOverflow.ellipsis" mobile/lib/features/staff/screens/staff_shell.dart` ✓
- `grep -q "FittedBox" mobile/lib/features/staff/screens/staff_dashboard_screen.dart` ✓
- `grep -q "BoxFit.scaleDown" mobile/lib/features/staff/screens/staff_dashboard_screen.dart` ✓
- `grep -c "Flexible(" mobile/lib/features/client/screens/client_home_screen.dart` returns 2 (>= 2 required) ✓
- `grep -q "Flexible(" mobile/lib/shared/widgets/app_offline_banner.dart` ✓

Preservation checks (all passed):

- `childAspectRatio: 1.3` preserved in staff dashboard ✓
- `childAspectRatio: 2.2` preserved in client home Quick Actions ✓
- `static const _railDestinations` preserved in both shells (const-friendly) ✓
- `staffDashboardProvider`, `chatSessionsProvider`, `Connectivity()` + `onConnectivityChanged` all preserved ✓

**Final static-analysis:** `cd mobile && dart analyze lib/` — 13 issues reported, all `info`-level pre-existing lint notices (`unnecessary_underscores`, `unnecessary_brace_in_string_interps`) in files I did not touch or in callback parameters outside my edits. **Zero errors and zero warnings** introduced by this plan.

## Decisions Made

See frontmatter `key-decisions`. Key rationale:

- **Clamp at 1.3x (not 2.0x):** D-19 required "text scales up to 2.0x without layout overflow", but the debug session and fix-plan revision converged on industry-standard consumer-app clamp (1.3x — WhatsApp/Instagram). Preserves accessibility intent (users can still scale 30% up) while bounding layout breakage across hundreds of widgets. User reported at max scale "aumentei e acessibilidade para muito alto, e distorceu tudo" — the clamp is the agreed remediation.
- **Keep NavigationRail const lists intact:** Material 3 NavigationRailDestination already wraps labels in a `DefaultTextStyle` with overflow handling. Modifying them would force non-const lists and erode widget-tree performance without tangible benefit.
- **No GridView aspect-ratio refactor:** The plan's scope explicitly excludes replacing `childAspectRatio` with `Wrap` layouts. FittedBox + maxLines:2 + ellipsis at clamped 1.3x scale is sufficient.

## Deviations from Plan

None - plan executed exactly as written.

All 6 tasks completed against the plan's acceptance criteria + verify blocks. All plan-level verification strings matched on first check. No scope expansion, no architectural decisions needed, no auth gates, no blocking issues.

## Issues Encountered

**Non-issues (pre-existing lint noise, not introduced by this plan):**

- `dart analyze lib/` reports 13 `info`-level lint notices (`unnecessary_underscores` and one `unnecessary_brace_in_string_interps`) in files I did not touch (e.g., `auth/screens/login_screen.dart:146`) or in closure params in existing `.when(error: (_, __) => ...)` callbacks I did not edit. Verified pre-existing by `git stash` + re-running analyze. These are not blocking per the plan's verification note ("warnings allowed if pre-existing").

## Known Stubs

None — this is a layout-polish plan; no data wiring or stub text introduced.

## Threat Flags

None — layout-only changes. No new trust boundaries, auth paths, input surfaces, or network endpoints introduced.

## User Setup Required

None — no external service configuration, no environment variables, no dashboard changes.

## Follow-up Human UAT (MANDATORY)

**This plan cannot be automated to closure.** After reviewing the diff, the user must retest Phase 10 UAT Test 4 visually:

1. Launch the app: `cd mobile && flutter run -d chrome` (or any target device/emulator).
2. Set system font scale to the OS maximum:
   - **Android:** Settings → Accessibility → Font size → "Largest"
   - **iOS:** Settings → Accessibility → Display & Text Size → Larger Text → enable "Larger Accessibility Sizes" + drag slider to max
   - **Browser zoom is NOT equivalent** — use an actual device or emulator with accessibility font settings.
3. Launch the app and navigate all 9 main screens:
   - Client shell: Home, Chat, Documents, Notifications, Resources, Support
   - Staff shell: Dashboard, Schedule, Intervention, Documents, Resources
4. Confirm:
   - No RenderFlex overflow banners (yellow/black striped in debug builds)
   - No clipped text in bottom nav labels (should truncate with `…` ellipsis)
   - No KPI card overflow on staff dashboard (values + labels scale down via FittedBox)
   - No summary card overflow on client home (title/subtitle + bottomLabel truncate cleanly)
   - Offline banner readable if connectivity is disabled (Flexible wrap holds)
5. Update `.planning/phases/10-cross-platform-polish/10-HUMAN-UAT.md` Test 4:
   - Change `result: issue` → `result: pass`
   - Update the `Gaps` section status from `failed` → `resolved` (or remove the gap entry entirely).

**Expected behavior at OS max font scale:** the clamp caps visual growth at 1.3x. User should see larger-than-default text but no layout distortion. If any overflow remains, capture the screen + widget name and re-open with `/gsd-debug`.

## Next Phase Readiness

- Phase 10 UAT Test 4 gap closed pending human retest (see Follow-up above).
- Zero regressions in any untouched file (`dart analyze lib/` reports 0 errors + 0 warnings).
- All Phase 10 plans 01-06 delivered.
- No blockers for downstream phases.

## Self-Check: PASSED

Verified:

- All 14 modified files exist on disk: ✓ (edits committed across 6 atomic commits)
- All 6 task commits present in `git log --oneline`: `aebb8b7`, `6b4faa9`, `ae9699f`, `602901a`, `6dc5149`, `7852627` ✓
- All 7 plan-level grep verifications pass ✓
- All 4 preservation grep checks pass ✓
- `dart analyze lib/` exits with zero errors + zero warnings (13 info-level lints are pre-existing) ✓

---
*Phase: 10-cross-platform-polish*
*Completed: 2026-05-07*
