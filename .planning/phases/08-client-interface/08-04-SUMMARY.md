---
phase: 08-client-interface
plan: 04
title: "Chat History Screens"
subsystem: mobile/flutter
tags: [chat, screens, tabs, whatsapp-bubbles, expansion-tile, router]
dependency_graph:
  requires: [08-01]
  provides: [client-chat-list, client-chat-detail, chat-route]
  affects: [08-05]
tech_stack:
  added: []
  patterns: [ConsumerStatefulWidget-TabController, AsyncValue-when, WhatsApp-bubble-layout, ExpansionTile-detail]
key_files:
  created:
    - mobile/lib/features/client/screens/client_chat_screen.dart
    - mobile/lib/features/client/screens/client_chat_detail_screen.dart
  modified:
    - mobile/lib/core/router/app_router.dart
    - mobile/lib/core/router/app_router.g.dart
    - mobile/lib/core/router/route_names.dart
decisions:
  - "Used surfaceContainerHighest (M3) for bot bubble background instead of deprecated surfaceVariant"
  - "Replaced Documents placeholder in same commit since real screen already exists from Plan 03"
  - "Chat detail uses ConsumerStatefulWidget with SingleTickerProviderStateMixin for TabController lifecycle"
metrics:
  duration: "2m54s"
  completed: "2026-05-04T18:23:25Z"
---

# Phase 08 Plan 04: Chat History Screens Summary

**One-liner:** Chat session list with status cards + detail screen with WhatsApp-style message bubbles and expandable action logs via TabBar, routed at /client/chat/:sessionId.

## What Was Built

### Task 1: Chat Session List & Detail Screens

**ClientChatScreen** (`client_chat_screen.dart`):
- `ConsumerWidget` with `ref.watch(chatSessionsProvider)`
- `RefreshIndicator` for pull-to-refresh
- Sessions sorted by `startedAt` descending
- `_SessionCard`: CircleAvatar (colored by status), formatted date, status text (Ativa/Encerrada), message count, status dot (green/grey)
- Navigation: `context.go('/client/chat/${session.id}')`
- Empty state: bot icon + "Nenhuma sessao de chat"

**ClientChatDetailScreen** (`client_chat_detail_screen.dart`):
- `ConsumerStatefulWidget` with `SingleTickerProviderStateMixin` for `TabController`
- AppBar with "Conversa" title and TabBar (Mensagens, Acoes)
- **Messages tab**: `ref.watch(chatMessagesProvider(sessionId))`
  - `_MessageBubble`: user right-aligned (primary color, white text), bot left-aligned (surfaceContainerHighest, onSurface text)
  - Asymmetric border radius (WhatsApp-style tail)
  - 75% max width via `ConstrainedBox`
  - Timestamp below each bubble (HH:mm format)
- **Actions tab**: `ref.watch(actionLogsProvider(sessionId))`
  - `ExpansionTile` per action log with success/error icon
  - Expanded content: JSON-formatted input/output, latency display, retry chip

### Task 2: Router Sub-Route

- Added `clientChatDetail` route name and path (`/client/chat/:sessionId`) to `route_names.dart`
- Replaced Chat `_PlaceholderScreen` with `ClientChatScreen` + nested GoRoute for `:sessionId`
- Replaced Documents `_PlaceholderScreen` with `ClientDocumentsScreen` (already built in Plan 03)
- Added imports for chat and documents screens to `app_router.dart`
- Regenerated `app_router.g.dart` via build_runner (28 outputs, 0 errors)

## Verification Results

- ✅ `flutter analyze lib/features/client/screens/` — No issues found
- ✅ `flutter analyze lib/core/router/` — No issues found
- ✅ `flutter pub run build_runner build --delete-conflicting-outputs` — 28 outputs, 0 errors
- ✅ Chat detail accessible at `/client/chat/{sessionId}` route
- ✅ Messages displayed as right/left bubbles with alignment logic
- ✅ Action logs use ExpansionTile with JSON detail

## Deviations from Plan

None — plan executed exactly as written.

## Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | 72a9a0c | feat(08-04): add chat session list and detail screens with sub-tabs |
| 2 | db2af67 | feat(08-04): add chat detail sub-route and replace placeholders |

## Self-Check: PASSED
