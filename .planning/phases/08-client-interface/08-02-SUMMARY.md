---
phase: 08-client-interface
plan: 02
title: "Client Dashboard & Support Screens"
subsystem: mobile/flutter
tags: [dashboard, support, providers, url-launcher, navigation]
dependency_graph:
  requires: [08-01]
  provides: [client-dashboard, client-support]
  affects: [08-03, 08-04, 08-05]
tech_stack:
  added: [url_launcher]
  patterns: [ConsumerWidget-ref.watch, AsyncValue.when, RefreshIndicator-invalidation]
key_files:
  created:
    - mobile/lib/features/client/screens/client_support_screen.dart
  modified:
    - mobile/lib/features/client/screens/client_home_screen.dart
    - mobile/lib/core/router/app_router.dart
    - mobile/pubspec.yaml
decisions:
  - "Used manual date formatting helper instead of adding intl package dependency"
  - "url_launcher ^6.3.1 added for support screen external app actions"
  - "Router updated to wire ClientSupportScreen replacing placeholder"
metrics:
  duration: "3m31s"
  completed: "2026-05-04T18:12:55Z"
---

# Phase 08 Plan 02: Client Dashboard & Support Screens Summary

**One-liner:** Full dashboard with 3 provider-driven summary cards (chat, appointments, documents) plus static support/contact screen with url_launcher email/phone/WhatsApp actions.

## What Was Built

### Task 1: Client Dashboard (Home) with 3 Summary Cards

Replaced the placeholder `ClientHomeScreen` with a full dashboard implementing D-01 through D-05:

| Card | Icon | Data Source | Navigation |
|------|------|-------------|------------|
| Ultima atividade do bot | `smart_toy_outlined` | chatSessionsProvider → latest startedAt | `/client/chat` |
| Proximo agendamento | `calendar_today_outlined` | appointmentsProvider → first isUpcoming | `/client/notifications` |
| Status de documentos | `description_outlined` | documentsProvider → pending/ready counts | `/client/documents` |

**Key patterns:**
- `ConsumerWidget` with `ref.watch` on all 3 providers
- `AsyncValue.when()` for loading/error/data states per card
- `RefreshIndicator` with provider invalidation + `Future.wait` for parallel reload
- `_DashboardCard` reusable private widget with InkWell, rounded borders, icon container

### Task 2: Support & Contact Screen (Static)

Created `ClientSupportScreen` implementing D-18 and D-19:

| Contact Method | Action | URL Pattern |
|----------------|--------|-------------|
| Email | `launchUrl` | `mailto:suporte@universidade.edu` |
| Phone | `launchUrl` | `tel:+5521999999999` |
| WhatsApp | `launchUrl(externalApplication)` | `https://wa.me/5521999999999` |

- All contact data hardcoded as file-level constants (no API dependency)
- Office hours displayed with clock icon
- Card/ListTile pattern for consistent visual style
- `url_launcher` package added to pubspec.yaml

## Verification Results

- ✅ `flutter analyze lib/features/client/screens/` — No issues found
- ✅ `flutter analyze lib/core/router/app_router.dart` — No issues found
- ✅ Dashboard contains `RefreshIndicator`, `ref.watch(chatSessionsProvider)`, `ref.watch(documentsProvider)`, `ref.watch(appointmentsProvider)`
- ✅ Dashboard contains `context.go(RoutePaths.clientChat)`, `context.go(RoutePaths.clientDocuments)`
- ✅ Support screen contains `class ClientSupportScreen extends StatelessWidget`
- ✅ Support screen contains `suporte@universidade.edu`, `launchUrl`, `Suporte`

## Deviations from Plan

None — plan executed exactly as written.

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | 3953f9c | feat(08-02): implement client dashboard with 3 summary cards |
| 2 | b0a17d0 | feat(08-02): add support & contact screen with url_launcher actions |

## Self-Check: PASSED
