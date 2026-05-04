---
phase: 08-client-interface
plan: 05
title: "Notifications Screen & Final Router Wiring"
subsystem: mobile/flutter
tags: [notifications, derived-data, router, final-integration]
dependency_graph:
  requires: [08-01, 08-02, 08-03, 08-04]
  provides: [client-notifications-screen, complete-client-routing]
  affects: []
tech_stack:
  added: []
  patterns: [derived-provider-aggregation, time-bounded-notifications, relative-time-formatting]
key_files:
  created:
    - mobile/lib/features/client/providers/notification_provider.dart
    - mobile/lib/features/client/providers/notification_provider.g.dart
    - mobile/lib/features/client/screens/client_notifications_screen.dart
  modified:
    - mobile/lib/core/router/app_router.dart
    - mobile/lib/core/router/app_router.g.dart
decisions:
  - "Removed unused model imports in notification_provider.dart (models accessed indirectly via provider generics)"
  - "_PlaceholderScreen class retained only for staff routes (Phase 9) — not removed entirely"
  - "Relative time helper handles both past and future timestamps for appointment reminders"
metrics:
  duration: "3m12s"
  completed: "2026-05-04T18:29:36Z"
---

# Phase 08 Plan 05: Notifications Screen & Final Router Wiring Summary

**One-liner:** Derived notifications provider aggregating document status changes (7d) and upcoming appointments (48h) with time-bounded queries, plus final router wiring replacing all client placeholders with real screens.

## What Was Built

### Task 1: Derived Notifications Provider & Screen

**notification_provider.dart:**
- `NotificationType` enum with 3 values: `documentStatus`, `appointmentReminder`, `errorAlert`
- `DerivedNotification` class with id, type, title, subtitle, timestamp, icon, color
- `derivedNotificationsProvider` (@riverpod) that:
  - Watches `documentsProvider.future` and `appointmentsProvider.future`
  - Derives notifications from documents with `completedAt` within 7 days or `processing` status
  - Derives notifications from appointments within 48 hours (future, scheduled)
  - Sorts by timestamp descending (most recent first)
  - Time-bounded queries prevent unbounded list growth (T-08-10 mitigation)

**client_notifications_screen.dart:**
- `ConsumerWidget` with `ref.watch(derivedNotificationsProvider)`
- `RefreshIndicator` invalidates both source providers
- Empty state: `Icons.notifications_off_outlined` + "Sem notificacoes no momento"
- Error state: Error icon + "Erro ao carregar notificacoes" + retry button
- Data state: `ListView.builder` with `_NotificationItem` tiles
- `_NotificationItem`: CircleAvatar (icon + color), bold title, subtitle, relative time trailing
- `_formatRelativeTime`: handles both past ("ha 2h") and future ("em 1d") timestamps

### Task 2: Final Router Wiring

| Route | Before | After |
|-------|--------|-------|
| `/client` (Home) | ClientHomeScreen | ClientHomeScreen (unchanged) |
| `/client/chat` | ClientChatScreen | ClientChatScreen (unchanged) |
| `/client/documents` | ClientDocumentsScreen | ClientDocumentsScreen (unchanged) |
| `/client/notifications` | _PlaceholderScreen | **ClientNotificationsScreen** |
| `/client/support` | ClientSupportScreen | ClientSupportScreen (unchanged) |

- Added `import '../../features/client/screens/client_notifications_screen.dart'`
- `_PlaceholderScreen` class retained only for staff routes (Phase 9)
- All 5 client tabs now render real, functional screen widgets

## Verification Results

- ✅ `flutter pub run build_runner build --delete-conflicting-outputs` — 30 outputs, 0 errors
- ✅ `flutter analyze lib/` — **No issues found** (full app)
- ✅ notification_provider.dart contains `enum NotificationType { documentStatus, appointmentReminder, errorAlert }`
- ✅ notification_provider.dart contains `class DerivedNotification`
- ✅ notification_provider.dart contains `ref.watch(documentsProvider.future)`
- ✅ notification_provider.dart contains `ref.watch(appointmentsProvider.future)`
- ✅ notification_provider.dart contains `inHours <= 48` and `inDays <= 7`
- ✅ client_notifications_screen.dart contains `ref.watch(derivedNotificationsProvider)`
- ✅ client_notifications_screen.dart contains `_formatRelativeTime`
- ✅ client_notifications_screen.dart contains `Icons.description` and `Icons.access_time`
- ✅ notification_provider.g.dart generated successfully
- ✅ app_router.dart contains `ClientNotificationsScreen()` in notifications route
- ✅ No `_PlaceholderScreen` references for any client route

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed unused model imports**

- **Found during:** Task 1
- **Issue:** `document_model.dart` and `appointment_model.dart` imports triggered `unused_import` warnings — models are accessed indirectly through provider return types
- **Fix:** Removed both unused imports
- **Files modified:** `mobile/lib/features/client/providers/notification_provider.dart`
- **Commit:** 5e1c282

## Threat Mitigations Applied

| Threat ID | Mitigation |
|-----------|-----------|
| T-08-10 (DoS via unbounded list) | Time-bounded queries: 7 days for documents, 48 hours for appointments — prevents unbounded notification list growth |

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | 5e1c282 | feat(08-05): add derived notifications provider and screen |
| 2 | 9ede14b | feat(08-05): wire ClientNotificationsScreen replacing last client placeholder |

## Self-Check: PASSED
