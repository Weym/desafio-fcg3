---
status: diagnosed
phase: 10-cross-platform-polish
source: [10-VERIFICATION.md]
started: 2026-05-05T15:10:00Z
updated: 2026-05-07T15:15:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Multi-Viewport Rendering

expected: All screens render correctly: BottomNav on phone, NavigationRail compact on tablet, NavigationRail extended + master-detail on desktop
result: pass

### 2. Dark Mode Visual Quality

expected: Pressing the toggle in AppBar switches between light/dark theme; closing and reopening app retains the choice
result: pass

### 3. Shimmer Animation Quality

expected: Shimmer animation displays placeholder shapes matching layout, then transitions instantly to content
result: pass

### 4. Text Scaling (2.0x)

expected: No text is clipped or overflows container at 2.0x system font scale
result: issue
reported: "aumentei e acessibilidade para muito alto, e distorceu tudo"
severity: major

## Summary

total: 4
passed: 3
issues: 1
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "No text is clipped or overflows container at 2.0x system font scale"
  status: failed
  reason: "User reported: aumentei e acessibilidade para muito alto, e distorceu tudo"
  severity: major
  test: 4
  root_cause: "Compound defect — (A) No global TextScaler clamp in MaterialApp.router builder (mobile/lib/main.dart:31-38) — grep confirms zero textScaler/TextScaleFactor references anywhere in mobile/lib/. OS system font scale flows through unbounded; at ≥2.0x every Text doubles with no safety net. (B) Fixed-dimension containers with unwrapped Text in navigation shells and dashboard grids clip at 2.0x."
  artifacts:
    - path: "mobile/lib/main.dart"
      issue: "MaterialApp.router has no builder: callback that wraps child in MediaQuery with clamped textScaler — enables unbounded OS scaling"
    - path: "mobile/lib/features/client/screens/client_shell.dart"
      issue: "Lines 186 + 241-252: fixed 80dp bottom nav with Text(fontSize: 10, label) lacking maxLines/overflow/Flexible — 5 labels overflow at 2.0x"
    - path: "mobile/lib/features/staff/screens/staff_shell.dart"
      issue: "Same pattern — 5 labels including 'Intervenção', 'Documentos' overflow bottom-nav slots at 2.0x"
    - path: "mobile/lib/features/staff/screens/staff_dashboard_screen.dart"
      issue: "Line 93 GridView.count childAspectRatio:1.3 clips KPI value+label at 2.0x; lines 144-160 'Insights de Eficiência IA' title Row has Text without Flexible → horizontal overflow; _KpiCard Column at 314-329 fixed height; _EnrollmentBanner 'Ativo' badge Text not Flexible (263-270)"
    - path: "mobile/lib/features/client/screens/client_home_screen.dart"
      issue: "Line 265 Quick Actions childAspectRatio:2.2 too tight for 2-line labels at 2.0x; _SummaryGlassCard title/subtitle Column in Row without Expanded (328-357); bottomLabel Text not Flexible (373-378)"
    - path: "mobile/lib/shared/widgets/app_offline_banner.dart"
      issue: "Lines 50-61 Row[Icon + Text('Sem conexao')] with Text not Flexible — low risk today but fragile pattern"
  missing:
    - "Global MaterialApp builder with MediaQuery textScaler clamp at maxScaleFactor 1.3 (resolves ~80% of breakage)"
    - "maxLines:1 + overflow:TextOverflow.ellipsis on BottomNavigationBar label Text widgets in both shells"
    - "FittedBox(fit: BoxFit.scaleDown) or Wrap layout for GridView KPI cards on staff dashboard + client home"
    - "Expanded/Flexible wrappers on staff dashboard 'Insights' header Row and client home summary card title Columns"
    - "Defensive maxLines+ellipsis sweep on chip/badge sites with hardcoded fontSize 10-12"
  debug_session: ".planning/debug/text-scale-overflow.md"
